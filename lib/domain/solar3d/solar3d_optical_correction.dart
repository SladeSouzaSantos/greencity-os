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
/// Provisional MPPT grouping of PHYSICAL MODULES in the 3D study.
/// This does not certify string wiring, minimum start-up voltages or bypass.
class Solar3dMpptOpticalGroup {
  final double powerWp;
  final List<double> baselineMonthlyHsp;
  final List<double> retentionMonthly;

  const Solar3dMpptOpticalGroup({
    required this.powerWp,
    required this.baselineMonthlyHsp,
    required this.retentionMonthly,
  });
}

class Solar3dOpticalCorrection {
  final int weatherYearUtc;
  final String designSignature;
  final int panelCount;
  final Map<String, Map<int, List<double>>> retentionBySystemMppt;
  /// MPPT keys are scoped UNDER the inverter/system ID, never global.
  final Map<String, Map<int, Solar3dMpptOpticalGroup>> groupsBySystemMppt;

  const Solar3dOpticalCorrection._({
    required this.weatherYearUtc,
    required this.designSignature,
    required this.panelCount,
    required this.retentionBySystemMppt,
    required this.groupsBySystemMppt,
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
    final expected = <String, ({
      Solar3dObject panel, String systemId, int maxMpptIndex,
      double powerWp, List<double> monthlyBaseHsp,
    })>{};
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
            maxMpptIndex: sys.inverter.mpptCount,
            powerWp: array.solarScenario.module.powerWp.toDouble(),
            monthlyBaseHsp: result.monthlyHspReal,
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
      // A panel can be reassigned to ANY EXISTING tracker of its
      // OWN inverter. Different inverters may both have 'MPPT 1':
      // systemId keeps these distinct. Never mutate SolarArray wiring.
      if (panel.mpptIndex == null || panel.mpptIndex! < 1 ||
          panel.mpptIndex! > entry.value.maxMpptIndex) {
        throw FormatException('MPPT inexistente no inversor da placa ${entry.key}');
      }
      if (panel.moduleModel != basePanel.moduleModel ||
          (panel.width - basePanel.width).abs() > 1e-8 ||
          (panel.depth - basePanel.depth).abs() > 1e-8 ||
          (panel.tiltDegrees - basePanel.tiltDegrees).abs() > 1e-6 ||
          math.min(azimuthDelta, 360 - azimuthDelta) > 1e-6) {
        throw FormatException(
          'Placa ${entry.key}: módulo ou orientação diferentes '
          'do HSP de referência. Refaça o HSP com esses parâmetros.');
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
    final powers = <String, Map<int, double>>{};
    final baseHsp = <String, Map<int, List<double>>>{};
    for (var month = 1; month <= 12; month++) {
      final rows = monthly[month]!;
      final seen = <String>{};
      for (final row in rows) {
        final data = expected[row.panelId];
        final panel = present[row.panelId];
        if (data == null || panel == null || !seen.add(row.panelId) ||
            row.monthUtc != month || row.mpptIndex != panel.mpptIndex ||
            !row.referenceHsp.isFinite || !row.correctedHsp.isFinite ||
            row.referenceHsp <= 0 ||
            row.correctedHsp < -1e-8 ||
            row.correctedHsp > row.referenceHsp + 1e-6) {
          throw const FormatException(
            'Resultado óptico mensal inválido, duplicado ou incompatível');
        }
        final sys = data.systemId;
        final mppt = panel.mpptIndex!;
        if (month == 1) {
          powers.putIfAbsent(sys, () => {})[mppt] =
              (powers[sys]?[mppt] ?? 0) + data.powerWp;
          baseHsp.putIfAbsent(sys, () => {})
              .putIfAbsent(mppt, () => List<double>.filled(12, double.infinity));
        }
        final baseline = data.monthlyBaseHsp[month - 1];
        if (!baseline.isFinite || baseline < 0) {
          throw const FormatException('HSP de referência por array inválido');
        }
        final currentMin = baseHsp[sys]![mppt]![month - 1];
        if (baseline < currentMin) baseHsp[sys]![mppt]![month - 1] = baseline;
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
    final projectedGroups = <String, Map<int, Solar3dMpptOpticalGroup>>{};
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
      projectedGroups[group.key] = Map.unmodifiable({
        for (final entry in mpptRatios.entries)
          entry.key: Solar3dMpptOpticalGroup(
            powerWp: powers[group.key]![entry.key]!,
            baselineMonthlyHsp: List.unmodifiable(
              baseHsp[group.key]![entry.key]!),
            retentionMonthly: entry.value,
          ),
      });
    }
    return Solar3dOpticalCorrection._(
      weatherYearUtc: yearUtc,
      designSignature: signatureFor(systems),
      panelCount: expected.length,
      retentionBySystemMppt: Map.unmodifiable(ratios),
      groupsBySystemMppt: Map.unmodifiable(projectedGroups),
    );
  }
}
