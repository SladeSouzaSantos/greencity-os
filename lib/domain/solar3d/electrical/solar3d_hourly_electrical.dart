import 'dart:math' as math;

import 'solar3d_circuit_solver.dart';

/// A manufacturer/measured inverter efficiency curve. The nominal peak
/// efficiency is NOT a substitute for a power/load-dependent curve.
class Solar3dEfficiencyPoint {
  final double dcLoadRatio, efficiency;
  const Solar3dEfficiencyPoint(this.dcLoadRatio, this.efficiency);
}

class Solar3dInverterElectricalSpec {
  final String inverterId, provenance;
  final double nominalAcW, maxDcW, startupDcW, nominalAcVoltageV;
  final double dcResistanceOhm, acResistanceOhm;
  final int acPhases;
  final List<Solar3dEfficiencyPoint> efficiencyCurve;
  final bool independentlyVerified;

  const Solar3dInverterElectricalSpec({
    required this.inverterId, required this.provenance,
    required this.nominalAcW, required this.maxDcW,
    required this.startupDcW, required this.nominalAcVoltageV,
    required this.dcResistanceOhm, required this.acResistanceOhm,
    required this.acPhases, required this.efficiencyCurve,
    this.independentlyVerified = false,
  });

  void validate() {
    if (inverterId.isEmpty || provenance.trim().isEmpty ||
        acPhases != 1 && acPhases != 3 ||
        [nominalAcW, maxDcW, nominalAcVoltageV]
            .any((v) => !v.isFinite || v <= 0) ||
        !startupDcW.isFinite || startupDcW < 0 ||
        !dcResistanceOhm.isFinite || dcResistanceOhm < 0 ||
        !acResistanceOhm.isFinite || acResistanceOhm < 0 ||
        efficiencyCurve.length < 2 ||
        efficiencyCurve.first.dcLoadRatio != 0 ||
        efficiencyCurve.last.dcLoadRatio < 1) {
      throw const FormatException('Curva de inversor/condutores incompleta');
    }
    var previous = -1.0;
    for (final p in efficiencyCurve) {
      if (!p.dcLoadRatio.isFinite || !p.efficiency.isFinite ||
          p.dcLoadRatio <= previous || p.dcLoadRatio > 3 ||
          p.efficiency < 0 || p.efficiency > 1) {
        throw const FormatException('Curva de eficiência inválida');
      }
      previous = p.dcLoadRatio;
    }
  }

  double efficiencyForDc(double dcPowerW) {
    validate();
    final ratio = dcPowerW / nominalAcW;
    if (ratio <= 0) return efficiencyCurve.first.efficiency;
    for (var k = 1; k < efficiencyCurve.length; k++) {
      final a = efficiencyCurve[k - 1], b = efficiencyCurve[k];
      if (ratio <= b.dcLoadRatio) {
        final t = (ratio - a.dcLoadRatio) /
            (b.dcLoadRatio - a.dcLoadRatio);
        return a.efficiency + t * (b.efficiency - a.efficiency);
      }
    }
    return efficiencyCurve.last.efficiency;
  }

  /// Estimate one hour at specified DC MPPT operating points.
  /// DC conductor resistances and AC line resistances are explicit inputs,
  /// not arbitrary default "loss percentages". Still non-certified.
  Solar3dInverterHour convert(List<Solar3dMpptElectricalResult> trackers) {
    validate();
    var rawDc = 0.0, dcCableLoss = 0.0;
    for (final result in trackers) {
      rawDc += result.dcPowerW;
      dcCableLoss += result.mpp.currentA * result.mpp.currentA *
          dcResistanceOhm;
    }
    final afterCable = math.max(0, rawDc - dcCableLoss).toDouble();
    final dcUsed = math.min(afterCable, maxDcW).toDouble();
    var ac = dcUsed < startupDcW ? 0.0 :
        math.min(nominalAcW, dcUsed * efficiencyForDc(dcUsed)).toDouble();
    // AC cable loss uses actual output RMS line current, not DC current.
    final divisor = (acPhases == 3 ? math.sqrt(3) : 1.0) *
        nominalAcVoltageV;
    final acCurrent = ac / divisor;
    final acLoss = acCurrent * acCurrent * acResistanceOhm;
    ac = math.max(0, ac - acLoss).toDouble();
    return Solar3dInverterHour(
      rawDcW: rawDc, dcCableLossW: dcCableLoss,
      inverterInputW: dcUsed,
      acBeforeCableW: ac + acLoss,
      acAfterCableW: ac,
      acCableLossW: acLoss,
      dcClippingW: math.max(0, afterCable - maxDcW).toDouble(),
    );
  }
}

class Solar3dInverterHour {
  final double rawDcW, dcCableLossW, inverterInputW;
  final double acBeforeCableW, acAfterCableW, acCableLossW;
  final double dcClippingW;

  const Solar3dInverterHour({
    required this.rawDcW, required this.dcCableLossW,
    required this.inverterInputW, required this.acBeforeCableW,
    required this.acAfterCableW, required this.acCableLossW,
    required this.dcClippingW,
  });
}

/// Identical UTC weather/duration for no-obstacle and shaded physical
/// circuits. Caller MUST construct those circuits from the SAME raw POA;
/// NEVER feed Solar3dOpticalCorrection-adjusted HSP to this engine.
class Solar3dElectricalHourInput {
  final DateTime startUtc;
  final String weatherSource;
  final Map<String, List<Solar3dPhysicalMppt>> referenceByInverter;
  final Map<String, List<Solar3dPhysicalMppt>> shadedByInverter;

  const Solar3dElectricalHourInput({
    required this.startUtc, required this.weatherSource,
    required this.referenceByInverter, required this.shadedByInverter,
  });
}

class Solar3dElectricalHourComparison {
  final DateTime startUtc;
  final double referenceDcWh, shadedDcWh;
  final double referenceAcWh, shadedAcWh;
  final double referenceCableLossWh, shadedCableLossWh;

  const Solar3dElectricalHourComparison({
    required this.startUtc,
    required this.referenceDcWh, required this.shadedDcWh,
    required this.referenceAcWh, required this.shadedAcWh,
    required this.referenceCableLossWh, required this.shadedCableLossWh,
  });
  double get opticalAndElectricalDeltaWh => referenceAcWh - shadedAcWh;
}

/// Experimental aggregate. A complete year requires 8760/8784 CONTIGUOUS
/// UTC hours and a separate worker to avoid blocking a Flutter UI thread.
class Solar3dElectricalWindowReport {
  final List<Solar3dElectricalHourComparison> hours;
  final List<double> referenceAcWhMonthly, shadedAcWhMonthly;
  final bool completeUtcYear;
  final bool electricallyCalibrated;

  const Solar3dElectricalWindowReport({
    required this.hours, required this.referenceAcWhMonthly,
    required this.shadedAcWhMonthly, required this.completeUtcYear,
    this.electricallyCalibrated = false,
  });

  double get referenceAcWh => hours.fold(0, (v, h) => v + h.referenceAcWh);
  double get shadedAcWh => hours.fold(0, (v, h) => v + h.shadedAcWh);

  /// No annual energy is exposed for an incomplete hour window.
  double? get annualReferenceAcKwh =>
      completeUtcYear ? referenceAcWh / 1000 : null;
  double? get annualShadedAcKwh =>
      completeUtcYear ? shadedAcWh / 1000 : null;
}

class Solar3dElectricalWindowSimulator {
  /// Restricted to short windows in synchronous mode. Full-year runs
  /// require a background isolate/worker, traceable inputs and benchmarks.
  static Solar3dElectricalWindowReport calculate({
    required List<Solar3dElectricalHourInput> hours,
    required Map<String, Solar3dInverterElectricalSpec> inverters,
    int maxSynchronousHours = 24,
    int curveSamples = 96,
  }) {
    if (hours.isEmpty || hours.length > maxSynchronousHours ||
        maxSynchronousHours < 1 || maxSynchronousHours > 744 ||
        inverters.isEmpty) {
      throw const FormatException('Janela excede o limite síncrono');
    }
    final report = <Solar3dElectricalHourComparison>[];
    final baseMonths = List<double>.filled(12, 0);
    final shadeMonths = List<double>.filled(12, 0);
    final source = hours.first.weatherSource;
    for (var hourIndex = 0; hourIndex < hours.length; hourIndex++) {
      final hour = hours[hourIndex];
      if (!hour.startUtc.isUtc || hour.weatherSource.isEmpty ||
          hour.weatherSource != source ||
          (hourIndex > 0 &&
              hour.startUtc.difference(hours[hourIndex - 1].startUtc)
                  != const Duration(hours: 1)) ||
          hour.referenceByInverter.keys.toSet().length != inverters.length ||
          !hour.referenceByInverter.keys.toSet()
              .containsAll(inverters.keys) ||
          !hour.shadedByInverter.keys.toSet()
              .containsAll(inverters.keys) ||
          hour.shadedByInverter.length != inverters.length) {
        throw const FormatException('Clima horário ou circuito divergente');
      }
      var rawReference = 0.0, rawShaded = 0.0;
      var acReference = 0.0, acShaded = 0.0;
      var cablesReference = 0.0, cablesShaded = 0.0;
      for (final inverter in inverters.entries) {
        final orig = hour.referenceByInverter[inverter.key]!;
        final shaded = hour.shadedByInverter[inverter.key]!;
        final keysBase = orig.map((m) => m.mpptIndex).toSet();
        final keysShade = shaded.map((m) => m.mpptIndex).toSet();
        if (orig.isEmpty || keysBase.length != orig.length ||
            shaded.length != orig.length ||
            !keysBase.containsAll(keysShade) ||
            orig.any((x) => x.inverterId != inverter.key) ||
            shaded.any((x) => x.inverterId != inverter.key)) {
          throw const FormatException('Topologia horária MPPT divergente');
        }
        final resultsBase = orig
            .map((m) => m.globalMaximum(samples: curveSamples)).toList();
        final resultsShaded = shaded
            .map((m) => m.globalMaximum(samples: curveSamples)).toList();
        final convertedBase = inverter.value.convert(resultsBase);
        final convertedShade = inverter.value.convert(resultsShaded);
        rawReference += convertedBase.rawDcW;
        rawShaded += convertedShade.rawDcW;
        acReference += convertedBase.acAfterCableW;
        acShaded += convertedShade.acAfterCableW;
        cablesReference += convertedBase.dcCableLossW +
            convertedBase.acCableLossW;
        cablesShaded += convertedShade.dcCableLossW +
            convertedShade.acCableLossW;
      }
      report.add(Solar3dElectricalHourComparison(
        startUtc: hour.startUtc,
        referenceDcWh: rawReference, shadedDcWh: rawShaded,
        referenceAcWh: acReference, shadedAcWh: acShaded,
        referenceCableLossWh: cablesReference,
        shadedCableLossWh: cablesShaded,
      ));
      baseMonths[hour.startUtc.month - 1] += acReference;
      shadeMonths[hour.startUtc.month - 1] += acShaded;
    }
    final year = hours.first.startUtc.year;
    final expected = DateTime.utc(year + 1)
        .difference(DateTime.utc(year)).inHours;
    final complete = hours.length == expected &&
        hours.first.startUtc == DateTime.utc(year) &&
        hours.last.startUtc == DateTime.utc(year, 12, 31, 23);
    return Solar3dElectricalWindowReport(
      hours: List.unmodifiable(report),
      referenceAcWhMonthly: List.unmodifiable(baseMonths),
      shadedAcWhMonthly: List.unmodifiable(shadeMonths),
      completeUtcYear: complete,
    );
  }
}
