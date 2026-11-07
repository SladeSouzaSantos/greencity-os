import 'dart:math' as math;

import '../entities/solar_system.dart';
import 'solar3d_geometric_shading.dart';
import 'solar3d_plan_factory.dart';

/// Explicit, session-scoped optical shading estimate from the local 3D scene.
///
/// Each per-panel loss is derived from meteorological POA *direct-beam* ray
/// masking. Ratios are weighted by the installed module's nameplate power and
/// reference POA, then applied ONCE per MPPT to the existing HSP-based
/// production estimate. This is not a calibrated string I-V/MPPT model.
class Solar3dOpticalCorrection {
  final int weatherYearUtc;
  final String designSignature;
  final int panelCount;
  final Map<String, Map<int, List<double>>> retentionBySystemMppt;

  const Solar3dOpticalCorrection._({
    required this.weatherYearUtc,
    required this.designSignature,
    required this.panelCount,
    required this.retentionBySystemMppt,
  });

  /// Invalidate the estimate when a module, inverter, MPPT or reference HSP
  /// changes. Layout changes within the 3D editor clear monthly results.
  static String signatureFor(List<SolarSystem> systems) => systems.map((sys) {
    final parts = <String>[
      sys.id, sys.inverter.manufacturer, sys.inverter.modelName,
      sys.inverter.mpptCount.toString(),
    ];
    for (final array in sys.arrays) {
      final scenario = array.solarScenario;
      parts.addAll([
        scenario.id, array.mpptIndex.toString(),
        scenario.quantityPvModule.toString(),
        scenario.module.manufacturer, scenario.module.modelName,
        scenario.module.powerWp.toString(),
        scenario.module.length.toString(),
        scenario.module.width.toString(),
        scenario.inclination.toString(),
        scenario.azimuth.toString(),
        scenario.obstacle == null ? 'without-legacy-obstacle' : 'legacy-obstacle',
        ...?array.solarScenarioResult?.monthlyHspReal
            .map((v) => v.toStringAsFixed(9)),
      ]);
    }
    return parts.join('|');
  }).join('||');

  bool isValidFor(List<SolarSystem> systems) =>
      designSignature == signatureFor(systems);

  double retention(String systemId, int mpptIndex, int monthIndex) {
    if (monthIndex < 0 || monthIndex > 11) {
      throw RangeError.range(monthIndex, 0, 11, 'monthIndex');
    }
    final values = retentionBySystemMppt[systemId]?[mpptIndex];
    if (values == null || values.length != 12) {
      throw StateError('MPPT não tem correção óptica para todos os meses');
    }
    return values[monthIndex];
  }

  static Solar3dOpticalCorrection fromAnalysis({
    required List<SolarSystem> systems,
    required Solar3dScene scene,
    required Map<int, List<PanelMonthlyIrradianceLoss>> monthly,
    required int yearUtc,
    Set<String> excludedPanelIds = const {},
  }) {
    if (yearUtc < 2000 || yearUtc > 2100) {
      throw const FormatException('Ano meteorológico não suportado');
    }
    if (systems.isEmpty || systems.every((sys) => sys.arrays.isEmpty)) {
      throw const FormatException('Não há arranjos solares neste projeto');
    }
    scene.validate();
    final base = Solar3dPlanFactory.fromSystems(systems);
    final expected = <String, ({Solar3dObject panel, String systemId,
        int mpptIndex, double powerWp})>{};
    for (final sys in systems) {
      for (var arrIndex = 0; arrIndex < sys.arrays.length; arrIndex++) {
        final array = sys.arrays[arrIndex];
        final result = array.solarScenarioResult;
        if (result == null || result.monthlyHspReal.length != 12) {
          throw const FormatException(
            'Calcule o HSP convencional de todos os arranjos antes de aplicar');
        }
        if (array.solarScenario.obstacle != null) {
          throw const FormatException(
            'Remova o obstáculo legado do HSP: aplicar o 3D duplicaria as perdas');
        }
        final rawLoss = result.shadowLossPercentage
            .replaceAll('%', '').trim().replaceAll(',', '.');
        final parsedLoss = double.tryParse(rawLoss);
        if (parsedLoss == null || !parsedLoss.isFinite || parsedLoss.abs() > .001) {
          throw const FormatException(
            'A base HSP já possui perda por sombreamento ou valor não '
            'verificável. Use a base HSP sem obstáculos.');
        }
        if (array.mpptIndex < 1 || array.mpptIndex > sys.inverter.mpptCount) {
          throw const FormatException('MPPT inválido no projeto atual');
        }
        for (var i = 0; i < array.solarScenario.quantityPvModule; i++) {
          final id = '${sys.id}/${arrIndex + 1}/${i + 1}';
          final panel = base.objects.firstWhere((o) => o.id == id);
          expected[id] = (
            panel: panel, systemId: sys.id,
            mpptIndex: array.mpptIndex,
            powerWp: array.solarScenario.module.powerWp.toDouble(),
          );
        }
      }
    }
    final present = {
      for (final panel in scene.objects
          .where((o) => o.kind == Solar3dObjectKind.panel))
        panel.id: panel,
    };
    if (present.length != expected.length ||
        !present.keys.toSet().containsAll(expected.keys) ||
        expected.keys.any(excludedPanelIds.contains)) {
      throw const FormatException(
        'A análise precisa incluir exatamente todas as placas do projeto. '
        'Reative as placas ignoradas antes de aplicar.');
    }
    for (final entry in expected.entries) {
      final panel = present[entry.key]!;
      final basePanel = entry.value.panel;
      final azimuthDelta =
          (panel.azimuthDegrees - basePanel.azimuthDegrees).abs() % 360;
      if (panel.mpptIndex != entry.value.mpptIndex ||
          panel.moduleModel != basePanel.moduleModel ||
          (panel.width - basePanel.width).abs() > 1e-8 ||
          (panel.depth - basePanel.depth).abs() > 1e-8 ||
          (panel.tiltDegrees - basePanel.tiltDegrees).abs() > 1e-6 ||
          math.min(azimuthDelta, 360 - azimuthDelta) > 1e-6) {
        throw FormatException(
          'Placa ${entry.key}: módulo, MPPT ou orientação diferentes '
          'do projeto elétrico. Atualize o cadastro e recalcule o HSP.');
      }
      final tilt = panel.tiltDegrees * math.pi / 180;
      final lowest = panel.center.y -
          panel.depth / 2 * math.sin(tilt) -
          panel.height / 2 * math.cos(tilt);
      if (lowest < -1e-4) {
        throw FormatException(
          'Placa ${entry.key} atravessa o plano do terreno');
      }
    }
    if (monthly.length != 12 ||
        !List.generate(12, (i) => i + 1).every(monthly.containsKey)) {
      throw const FormatException(
        'Calcule os 12 meses completos do mesmo cenário 3D para aplicar');
    }
    final sums = <String, Map<int, List<double>>>{};
    final denominators = <String, Map<int, List<double>>>{};
    for (var month = 1; month <= 12; month++) {
      final rows = monthly[month]!;
      final seen = <String>{};
      for (final row in rows) {
        final data = expected[row.panelId];
        if (data == null || !seen.add(row.panelId) ||
            row.monthUtc != month || row.mpptIndex != data.mpptIndex ||
            !row.referenceHsp.isFinite || !row.correctedHsp.isFinite ||
            row.referenceHsp <= 0 ||
            row.correctedHsp < -1e-8 ||
            row.correctedHsp > row.referenceHsp + 1e-6) {
          throw const FormatException(
            'Resultado óptico mensal inválido, duplicado ou incompatível');
        }
        final sys = data.systemId;
        final mppt = data.mpptIndex;
        final numerators = sums.putIfAbsent(sys, () => {})
            .putIfAbsent(mppt, () => List<double>.filled(12, 0));
        final totalReferences = denominators.putIfAbsent(sys, () => {})
            .putIfAbsent(mppt, () => List<double>.filled(12, 0));
        numerators[month - 1] += data.powerWp * row.correctedHsp;
        totalReferences[month - 1] += data.powerWp * row.referenceHsp;
      }
      if (seen.length != expected.length) {
        throw FormatException(
          'Mês $month não possui resultados para todas as placas');
      }
    }
    final ratios = <String, Map<int, List<double>>>{};
    for (final group in sums.entries) {
      final mpptRatios = <int, List<double>>{};
      for (final entry in group.value.entries) {
        final weights = denominators[group.key]![entry.key]!;
        final values = List<double>.generate(12, (i) {
          if (weights[i] <= 0) {
            throw const FormatException('Recurso solar de referência nulo');
          }
          return (entry.value[i] / weights[i]).clamp(0.0, 1.0).toDouble();
        }, growable: false);
        mpptRatios[entry.key] = List.unmodifiable(values);
      }
      ratios[group.key] = Map.unmodifiable(mpptRatios);
    }
    return Solar3dOpticalCorrection._(
      weatherYearUtc: yearUtc,
      designSignature: signatureFor(systems),
      panelCount: expected.length,
      retentionBySystemMppt: Map.unmodifiable(ratios),
    );
  }
}
