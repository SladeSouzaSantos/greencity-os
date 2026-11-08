import 'dart:math' as math;

/// Five-parameter single-diode calibration with explicit source.
/// STC Voc/Isc/Vmp/Imp alone do NOT identify these five parameters.
/// No automatic parameter fitting from four nameplate points is allowed.
class Solar3dDiodeCalibration {
  final String moduleModel, source;
  final int seriesCells;
  final double ilRefA, ioRefA, rsOhm, rshRefOhm, aRefV, alphaScAperC;
  final double bandGapEv;
  final bool independentlyVerified;

  const Solar3dDiodeCalibration({
    required this.moduleModel, required this.source,
    required this.seriesCells, required this.ilRefA, required this.ioRefA,
    required this.rsOhm, required this.rshRefOhm, required this.aRefV,
    required this.alphaScAperC, this.bandGapEv = 1.121,
    this.independentlyVerified = false,
  });

  Map<String, Object?> toJson() => {
    'schema_version': 1,
    'module_model': moduleModel,
    'source': source,
    'series_cells': seriesCells,
    'il_ref_a': ilRefA,
    'io_ref_a': ioRefA,
    'rs_ohm': rsOhm,
    'rsh_ref_ohm': rshRefOhm,
    'a_ref_v': aRefV,
    'alpha_sc_a_per_c': alphaScAperC,
    'band_gap_ev': bandGapEv,
    // Never serialize the claim of independent verification; that requires
    // external benchmark evidence and approval outside this editor.
  };

  static Solar3dDiodeCalibration fromJson(Map<String, dynamic> json) {
    double requiredNumber(String name) {
      final v = json[name];
      if (v is! num || !v.isFinite) {
        throw FormatException('Parâmetro I-V ausente: $name');
      }
      return v.toDouble();
    }
    if (json['schema_version'] != 1 ||
        json['module_model'] is! String ||
        json['source'] is! String ||
        json['series_cells'] is! int) {
      throw const FormatException('Registro I-V incompatível');
    }
    final model = Solar3dDiodeCalibration(
      moduleModel: json['module_model'] as String,
      source: json['source'] as String,
      seriesCells: json['series_cells'] as int,
      ilRefA: requiredNumber('il_ref_a'),
      ioRefA: requiredNumber('io_ref_a'),
      rsOhm: requiredNumber('rs_ohm'),
      rshRefOhm: requiredNumber('rsh_ref_ohm'),
      aRefV: requiredNumber('a_ref_v'),
      alphaScAperC: requiredNumber('alpha_sc_a_per_c'),
      bandGapEv: requiredNumber('band_gap_ev'),
    );
    model.validate();
    return model;
  }

  void validate() {
    if (moduleModel.trim().isEmpty || source.trim().isEmpty ||
        seriesCells < 1 || seriesCells > 300 ||
        [ilRefA, ioRefA, rshRefOhm, aRefV, bandGapEv]
            .any((v) => !v.isFinite || v <= 0) ||
        !rsOhm.isFinite || rsOhm < 0 ||
        !alphaScAperC.isFinite || alphaScAperC.abs() > 1 ||
        ilRefA > 100 || ioRefA >= 1 || rshRefOhm > 1e12 ||
        aRefV > 40 || bandGapEv > 3) {
      throw const FormatException('Parâmetros I-V inválidos ou sem fonte');
    }
  }

  /// A De Soto-like transform for crystalline silicon, in SI units.
  /// Does not imply laboratory calibration or electrical certification.
  Solar3dDiodeState at(double irradianceWm2, double cellTemperatureC) {
    validate();
    if (!irradianceWm2.isFinite || irradianceWm2 < 0 ||
        irradianceWm2 > 2000 || !cellTemperatureC.isFinite ||
        cellTemperatureC < -70 || cellTemperatureC > 130) {
      throw const FormatException('Irradiância ou temperatura inválida');
    }
    const refK = 298.15;
    final tK = cellTemperatureC + 273.15;
    final ratio = tK / refK;
    final il = math.max(0.0, irradianceWm2 / 1000 *
        (ilRefA + alphaScAperC * (cellTemperatureC - 25)));
    final io = ioRefA * math.pow(ratio, 3).toDouble() *
        math.exp(bandGapEv * seriesCells / aRefV * (1 - refK / tK));
    final s = Solar3dDiodeState(
      ilA: il, ioA: io, rsOhm: rsOhm,
      rshOhm: rshRefOhm * (1000 / math.max(irradianceWm2, 1)),
      aV: aRefV * ratio,
    );
    s.validate();
    return s;
  }
}

class Solar3dIvPoint {
  final double voltageV, currentA;
  const Solar3dIvPoint(this.voltageV, this.currentA);
  double get powerW => voltageV * currentA;
}

/// A numerical monotone first-quadrant solution of the single diode eq.
class Solar3dDiodeState {
  final double ilA, ioA, rsOhm, rshOhm, aV;
  const Solar3dDiodeState({
    required this.ilA, required this.ioA,
    required this.rsOhm, required this.rshOhm, required this.aV,
  });
  void validate() {
    if (![ilA, ioA, rsOhm, rshOhm, aV].every((v) => v.isFinite) ||
        ilA < 0 || ioA <= 0 || rsOhm < 0 || rshOhm <= 0 || aV <= 0) {
      throw const FormatException('Estado do diodo inválido');
    }
  }

  double _balance(double v, double i) {
    final vd = v + i * rsOhm;
    final arg = vd / aV;
    final diode = arg > 700
        ? double.infinity : ioA * (math.exp(arg) - 1);
    return ilA - diode - vd / rshOhm - i;
  }

  double get openCircuitVoltage {
    if (ilA <= 0) return 0;
    var low = 0.0, high = aV * math.log(1 + ilA / ioA);
    for (var k = 0; k < 65; k++) {
      final mid = (low + high) / 2;
      if (_balance(mid, 0) > 0) { low = mid; } else { high = mid; }
    }
    return (low + high) / 2;
  }

  double get shortCircuitCurrent => currentAtVoltage(0);

  double currentAtVoltage(double voltage) {
    if (!voltage.isFinite || voltage < 0) {
      throw const FormatException('Tensão negativa no ramo I-V');
    }
    if (ilA == 0 || voltage >= openCircuitVoltage) return 0;
    var low = 0.0, high = ilA;
    for (var k = 0; k < 55; k++) {
      final mid = (low + high) / 2;
      if (_balance(voltage, mid) > 0) { low = mid; } else { high = mid; }
    }
    return (low + high) / 2;
  }

  /// null means reverse bias would be needed and is NOT modeled here.
  double? voltageAtCurrent(double current) {
    if (!current.isFinite || current < 0) {
      throw const FormatException('Corrente I-V inválida');
    }
    if (ilA == 0) return current == 0 ? 0 : null;
    if (current == 0) return openCircuitVoltage;
    if (current > shortCircuitCurrent + 1e-8) return null;
    var low = 0.0, high = openCircuitVoltage;
    for (var k = 0; k < 55; k++) {
      final mid = (low + high) / 2;
      if (_balance(mid, current) > 0) { low = mid; } else { high = mid; }
    }
    return (low + high) / 2;
  }

  Solar3dIvPoint pointAtVoltage(double voltage) =>
      Solar3dIvPoint(voltage, currentAtVoltage(voltage));

  Solar3dIvPoint maximumPowerPoint({int steps = 160}) {
    if (steps < 32 || steps > 2048) {
      throw const FormatException('Resolução I-V inválida');
    }
    final voc = openCircuitVoltage;
    var best = const Solar3dIvPoint(0, 0);
    for (var k = 0; k <= steps; k++) {
      final point = pointAtVoltage(voc * k / steps);
      if (point.powerW > best.powerW) best = point;
    }
    var lo = math.max(0, best.voltageV - voc / steps);
    var hi = math.min(voc, best.voltageV + voc / steps);
    for (var k = 0; k < 36; k++) {
      final a = lo + (hi - lo) / 3;
      final b = hi - (hi - lo) / 3;
      if (pointAtVoltage(a).powerW < pointAtVoltage(b).powerW) {
        lo = a;
      } else {
        hi = b;
      }
    }
    final refined = pointAtVoltage((lo + hi) / 2);
    return refined.powerW > best.powerW ? refined : best;
  }
}
