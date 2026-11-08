import 'dart:math' as math;

import 'solar3d_single_diode.dart';

/// Electrical substrings must be declared from actual topology.
/// Bypass is permitted only for documented physical substrings.
class Solar3dPhysicalSubstring {
  final String id;
  final Solar3dDiodeState diode;
  final double? bypassDropV;
  final bool topologyVerified;

  const Solar3dPhysicalSubstring({
    required this.id, required this.diode,
    this.bypassDropV, this.topologyVerified = false,
  });

  void validate() {
    if (id.isEmpty) throw const FormatException('Substring sem ID');
    diode.validate();
    if (bypassDropV != null && (!topologyVerified ||
        !bypassDropV!.isFinite ||
        bypassDropV! <= 0 || bypassDropV! > 3)) {
      throw const FormatException(
          'Bypass exige topologia real e queda de diodo verificada');
    }
  }

  double? voltageAtCurrent(double current) =>
      diode.voltageAtCurrent(current) ?? (bypassDropV == null
          ? null : -bypassDropV!);
}

/// One physical PV module, with explicit series-connected substrings.
/// A single unsplit diode is valid for UNIFORM-irradiance investigations.
class Solar3dPhysicalModule {
  final String panelId;
  final List<Solar3dPhysicalSubstring> substrings;

  const Solar3dPhysicalModule({
    required this.panelId, required this.substrings,
  });

  void validate() {
    if (panelId.isEmpty || substrings.isEmpty || substrings.length > 12) {
      throw const FormatException('Módulo sem topologia física');
    }
    final ids = <String>{};
    for (final substring in substrings) {
      substring.validate();
      if (!ids.add(substring.id)) {
        throw const FormatException('Substring física duplicada');
      }
    }
    if (substrings.length > 1 &&
        substrings.any((s) =>
          !s.topologyVerified || s.bypassDropV == null)) {
      throw const FormatException(
          'Módulo com múltiplas substrings exige topologia e bypass reais');
    }
  }

  double? voltageAtCurrent(double current) {
    var voltage = 0.0;
    for (final substring in substrings) {
      final component = substring.voltageAtCurrent(current);
      if (component == null) return null;
      voltage += component;
    }
    return voltage;
  }

  double get openCircuitVoltage => substrings.fold(
      0, (sum, s) => sum + s.diode.openCircuitVoltage);

  /// Physical source current budget. With bypass a stronger substring can
  /// carry current while a weaker substring is bypassed; never sum series I.
  double get currentSearchUpperA {
    final sources = substrings.map((s) => s.diode.shortCircuitCurrent).toList();
    final unbypassed = substrings.where((s) => s.bypassDropV == null).toList();
    if (unbypassed.isNotEmpty) {
      return unbypassed.map((s) => s.diode.shortCircuitCurrent).reduce(math.min);
    }
    return sources.reduce(math.max) * 1.05;
  }
}

/// Modules in SERIES (same current). No fictitious "individual" kWh
/// is attributed to each module of a real series string.
class Solar3dPhysicalString {
  final String stringId;
  final List<Solar3dPhysicalModule> modules;

  const Solar3dPhysicalString({required this.stringId, required this.modules});

  void validate() {
    if (stringId.trim().isEmpty || modules.isEmpty || modules.length > 100) {
      throw const FormatException('String sem módulos ou ID');
    }
    final ids = <String>{};
    for (final module in modules) {
      module.validate();
      if (!ids.add(module.panelId)) {
        throw const FormatException('Placa repetida na string elétrica');
      }
    }
  }

  double get openCircuitVoltage =>
      modules.fold(0, (sum, m) => sum + m.openCircuitVoltage);

  double get currentSearchUpperA {
    // An already-bypassed weak module is NOT a current bottleneck.
    // Only substrings WITHOUT a bypass diode limit series current;
    // otherwise a stronger illuminated substring may supply current
    // through the bypassed weaker one.
    final sourceCurrents = <double>[];
    final withoutBypass = <double>[];
    for (final module in modules) {
      for (final substring in module.substrings) {
        final isc = substring.diode.shortCircuitCurrent;
        sourceCurrents.add(isc);
        if (substring.bypassDropV == null) withoutBypass.add(isc);
      }
    }
    if (withoutBypass.isNotEmpty) return withoutBypass.reduce(math.min);
    return sourceCurrents.reduce(math.max) * 1.05;
  }

  double? voltageAtCurrent(double current) {
    if (current < 0 || !current.isFinite) {
      throw const FormatException('Corrente da string inválida');
    }
    if (current > currentSearchUpperA + 1e-7) return null;
    var voltage = 0.0;
    for (final module in modules) {
      final v = module.voltageAtCurrent(current);
      if (v == null) return null;
      voltage += v;
    }
    return voltage;
  }

  double currentAtVoltage(double voltage) {
    if (!voltage.isFinite || voltage < 0) {
      throw const FormatException('Tensão de string inválida');
    }
    if (voltage >= openCircuitVoltage) return 0;
    final upper = currentSearchUpperA;
    if (upper == 0) return 0;
    var lo = 0.0, hi = upper;
    for (var k = 0; k < 42; k++) {
      final mid = (lo + hi) / 2;
      final v = voltageAtCurrent(mid);
      if (v == null || v < voltage) {
        hi = mid;
      } else {
        lo = mid;
      }
    }
    return (lo + hi) / 2;
  }

  double get shortCircuitCurrent => currentAtVoltage(0);
}

/// Several strings in PARALLEL at one common MPPT voltage. MPPT 1 of
/// two different inverters must be represented by DIFFERENT instances.
class Solar3dPhysicalMppt {
  final String inverterId;
  final int mpptIndex;
  final List<Solar3dPhysicalString> strings;
  final double voltageMinV, voltageMaxV, startVoltageV;
  final double operatingCurrentLimitA, shortCircuitCurrentLimitA;

  const Solar3dPhysicalMppt({
    required this.inverterId, required this.mpptIndex,
    required this.strings, required this.voltageMinV,
    required this.voltageMaxV, required this.startVoltageV,
    required this.operatingCurrentLimitA,
    required this.shortCircuitCurrentLimitA,
  });

  void validate() {
    if (inverterId.trim().isEmpty || mpptIndex < 1 ||
        strings.isEmpty || strings.length > 64 ||
        [voltageMinV, voltageMaxV, startVoltageV, operatingCurrentLimitA,
         shortCircuitCurrentLimitA].any((x) => !x.isFinite || x <= 0) ||
        voltageMaxV <= voltageMinV ||
        operatingCurrentLimitA > shortCircuitCurrentLimitA * 1.5) {
      throw const FormatException('MPPT sem limites válidos');
    }
    final names = <String>{}, panels = <String>{};
    for (final string in strings) {
      string.validate();
      if (!names.add(string.stringId)) {
        throw const FormatException('ID de string duplicado no MPPT');
      }
      for (final module in string.modules) {
        if (!panels.add(module.panelId)) {
          throw const FormatException('Placa em duas strings do MPPT');
        }
      }
    }
  }

  double currentAtVoltage(double voltage) =>
      strings.fold<double>(0, (sum, string) =>
          sum + string.currentAtVoltage(voltage));

  double get shortCircuitCurrent => currentAtVoltage(0);

  /// Operating current is a CLIPPING limit, while Isc is an absolute
  /// compatibility constraint. Never silently treat both as identical.
  Solar3dMpptElectricalResult globalMaximum({
    int samples = 256,
  }) {
    validate();
    if (samples < 64 || samples > 1024) {
      throw const FormatException('Amostragem MPPT inválida');
    }
    final isc = shortCircuitCurrent;
    if (isc > shortCircuitCurrentLimitA + 1e-6) {
      throw const FormatException('Isc excede limite absoluto do MPPT');
    }
    final voc = strings.map((s) => s.openCircuitVoltage).reduce(math.max);
    final minV = math.max(startVoltageV, voltageMinV);
    final maxV = math.min(voc, voltageMaxV);
    if (maxV <= minV) {
      return Solar3dMpptElectricalResult(
        mpp: const Solar3dIvPoint(0, 0), uncurtailedPowerW: 0,
        currentClipped: false, iscA: isc,
      );
    }
    Solar3dIvPoint point(double v, {bool clip = true}) =>
        Solar3dIvPoint(v, clip
            ? math.min(operatingCurrentLimitA, currentAtVoltage(v))
            : currentAtVoltage(v));
    var best = const Solar3dIvPoint(0, 0), ideal = 0.0;
    for (var i = 0; i <= samples; i++) {
      final v = minV + (maxV - minV) * i / samples;
      final measured = point(v);
      if (measured.powerW > best.powerW) best = measured;
      ideal = math.max(ideal, point(v, clip: false).powerW);
    }
    // Search all local peaks on the grid before refining the best region.
    // A shaded/bypassed array may exhibit MULTIPLE distinct MPP peaks.
    final increment = (maxV - minV) / samples;
    var lo = math.max(minV, best.voltageV - increment);
    var hi = math.min(maxV, best.voltageV + increment);
    for (var i = 0; i < 24; i++) {
      final a = lo + (hi - lo) / 3;
      final b = hi - (hi - lo) / 3;
      if (point(a).powerW < point(b).powerW) {
        lo = a;
      } else {
        hi = b;
      }
    }
    final precise = point((lo + hi) / 2);
    if (precise.powerW > best.powerW) best = precise;
    final currentLimited = ideal > best.powerW * (1 + 1e-4);
    return Solar3dMpptElectricalResult(
      mpp: best, uncurtailedPowerW: ideal,
      currentClipped: currentLimited, iscA: isc,
    );
  }
}

class Solar3dMpptElectricalResult {
  final Solar3dIvPoint mpp;
  final double uncurtailedPowerW;
  final bool currentClipped;
  final double iscA;

  const Solar3dMpptElectricalResult({
    required this.mpp, required this.uncurtailedPowerW,
    required this.currentClipped, required this.iscA,
  });
  double get dcPowerW => mpp.powerW;
}
