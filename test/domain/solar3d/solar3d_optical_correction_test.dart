import 'package:flutter_test/flutter_test.dart';
import 'package:greencity_os/domain/entities/inverter.dart';
import 'package:greencity_os/domain/entities/pv_module.dart';
import 'package:greencity_os/domain/entities/solar_array.dart';
import 'package:greencity_os/domain/entities/solar_project.dart';
import 'package:greencity_os/domain/entities/solar_scenario.dart';
import 'package:greencity_os/domain/entities/solar_scenario_result.dart';
import 'package:greencity_os/domain/entities/solar_system.dart';
import 'package:greencity_os/domain/enums/cell_technology.dart';
import 'package:greencity_os/domain/enums/inverter_type.dart';
import 'package:greencity_os/domain/enums/grid_connection.dart';
import 'package:greencity_os/domain/solar3d/solar3d_geometric_shading.dart';
import 'package:greencity_os/domain/solar3d/solar3d_optical_correction.dart';
import 'package:greencity_os/domain/solar3d/solar3d_plan_factory.dart';

void main() {
  List<SolarSystem> systems() {
    final module = PvModule(
      manufacturer: 'TEST', modelName: '500 W',
      cellTechnology: CellTechnology.topcon, powerWp: 500,
      efficiency: 20, length: 2000, width: 1000, weight: 25,
      vOc: 49, iSc: 13, vMp: 41, iMp: 12,
      tempCoefVoc: -.3, tempCoefIsc: .04,
      tempCoefPmax: -.3, isBifacial: false,
    );
    final inverter = Inverter(
      manufacturer: 'TEST', modelName: '2-MPPT',
      inverterType: InverterType.string, isHybrid: false,
      nominalPowerKw: 5, maxInputPowerKw: 10, maxEfficiency: .98,
      euroEfficiency: .97, mpptCount: 2,
      maxInputVoltage: 600, nominalVoltageDc: 380,
      startVoltage: 40, minMpptVoltage: 50, maxMpptVoltage: 550,
      maxInputCurrentPerMppt: 20, maxShortCircuitCurrent: 30,
      gridConnection: GridConnection.monophasic, maxOutputCurrent: 30,
      nominalVoltageAc: 220, dimensions: '', weight: 12,
      minOperatingTemp: -20, maxOperatingTemp: 60,
      protectionDegree: 'IP65',
    );
    final arrays = List<SolarArray>.generate(2, (i) {
      final id = 'A${i + 1}';
      return SolarArray(
        mpptIndex: i + 1,
        solarScenario: SolarScenario(
          id: id, city: 'Natal', state: 'RN',
          inclination: 15, azimuth: 0,
          distanceToGround: 1,
          module: module, quantityPvModule: 2,
        ),
        solarScenarioResult: SolarScenarioResult(
          id: id, averageHspReal: 5,
          monthlyHspReal: List.filled(12, 5),
          averageHspReference: 5,
          monthlyHspReference: List.filled(12, 5),
          shadowLossPercentage: '0.0%',
        ),
      );
    });
    return [SolarSystem(
      id: 'SYS', name: 'Sistema', inverter: inverter, arrays: arrays)];
  }

  Map<int,List<PanelMonthlyIrradianceLoss>> yearResults(
      List<SolarSystem> systems) {
    final panels = Solar3dPlanFactory.fromSystems(systems).objects;
    return {
      for (var m = 1; m <= 12; m++)
        m: panels.map((panel) {
          // Different shade per physical module, not a single scalar
          // copied across strings or MPPTs.
          final retention = panel.id.endsWith('/1/1') ? .5 : 1.0;
          return PanelMonthlyIrradianceLoss(
            panelId: panel.id,
            mpptIndex: panel.mpptIndex!,
            stringId: null, monthUtc: m,
            referenceHsp: 5, correctedHsp: 5 * retention,
            directLossKwhM2: 0, shadeLossPercent: 100 * (1 - retention),
          );
        }).toList(),
    };
  }

  Solar3dOpticalCorrection make(
      List<SolarSystem> list,
      Map<int,List<PanelMonthlyIrradianceLoss>> samples) =>
      Solar3dOpticalCorrection.fromAnalysis(
        systems: list, scene: Solar3dPlanFactory.fromSystems(list),
        monthly: samples, yearUtc: 2024,
      );

  test('Uma só correção óptica por MPPT, média ponderada de placas', () {
    final list = systems();
    final correction = make(list, yearResults(list));
    // MPPT1: one panel loses 50% of POA, one loses 0%. Combined
    // optical retention is 75%. MPPT2 is unshaded (100%).
    expect(correction.panelCount, 4);
    expect(correction.retention('SYS', 1, 0), closeTo(.75, 1e-12));
    expect(correction.retention('SYS', 2, 0), 1);
    final project = SolarProject(
      clientName: 'TESTE', city: 'Natal', state: 'RN',
      latitude: -5.8, longitude: -35.2,
      monthlyConsumption: 650, systems: list,
    );
    final baseline = project.baselineMonthlyGeneration;
    expect(project.totalMonthlyGeneration, baseline);
    project.opticalCorrection = correction;
    expect(project.hasAppliedOpticalCorrection, isTrue);
    // No double application of a 50% shade to all modules: the
    // second MPPT must retain all of its resource.
    expect(project.totalMonthlyGeneration[0],
      lessThan(project.baselineMonthlyGeneration[0]));
    expect(project.totalMonthlyGeneration[0],
      greaterThan(project.baselineMonthlyGeneration[0] * .8));
    expect(project.totalAverageAnnualGeneration,
      lessThan(project.baselineAverageAnnualGeneration));
    project.opticalCorrection = null;
    expect(project.totalMonthlyGeneration, baseline);
  });

  test('Rejeita ano parcial e módulo não calculado', () {
    final list = systems();
    final monthly = yearResults(list);
    monthly.remove(4);
    expect(() => make(list, monthly), throwsFormatException);
    final full = yearResults(list);
    full[2]!.removeAt(0);
    expect(() => make(list, full), throwsFormatException);
  });

  test('Impede sombra já aplicada pelo HSP legado', () {
    final list = systems();
    list.first.arrays.first.solarScenarioResult = SolarScenarioResult(
      id: 'A1', averageHspReal: 4.5,
      monthlyHspReal: List.filled(12, 4.5),
      averageHspReference: 5,
      monthlyHspReference: List.filled(12, 5),
      shadowLossPercentage: '10%',
    );
    expect(() => make(list, yearResults(list)), throwsFormatException);
  });

  test('Troca apenas uma placa de MPPT no 3D sem alterar SolarArray', () {
    final list = systems();
    final originalArrayMppt = list.first.arrays.first.mpptIndex;
    final base = Solar3dPlanFactory.fromSystems(list);
    final changed = Solar3dScene(base.objects.map((p) =>
      p.id == 'SYS/1/1' ? p.copyWith(mpptIndex: 2) : p).toList());
    final data = {
      for (var month = 1; month <= 12; month++)
        month: changed.objects.map((panel) {
          final ratio = panel.id == 'SYS/1/1' ? .5 : 1.0;
          return PanelMonthlyIrradianceLoss(
            panelId: panel.id, mpptIndex: panel.mpptIndex!,
            stringId: null, monthUtc: month,
            referenceHsp: 5, correctedHsp: 5 * ratio,
            directLossKwhM2: 0,
            shadeLossPercent: (1-ratio)*100,
          );
        }).toList(),
    };
    final correction = Solar3dOpticalCorrection.fromAnalysis(
      systems: list, scene: changed, monthly: data, yearUtc: 2024);
    expect(list.first.arrays.first.mpptIndex, originalArrayMppt);
    expect(correction.groupsBySystemMppt['SYS']![1]!.moduleCount, 1);
    expect(correction.groupsBySystemMppt['SYS']![2]!.moduleCount, 3);
    expect(correction.groupsBySystemMppt['SYS']![1]!.powerWp, 500);
    expect(correction.groupsBySystemMppt['SYS']![2]!.powerWp, 1500);
    expect(correction.retention('SYS', 1, 0), 1);
    expect(correction.retention('SYS', 2, 0), closeTo(5 / 6, 1e-12));
    final project = SolarProject(
      clientName: 'A', city: 'Natal', state: 'RN',
      latitude: -5.8, longitude: -35.2,
      monthlyConsumption: 500, systems: list,
    )..opticalCorrection = correction;
    expect(project.totalMonthlyGeneration[0],
      lessThan(project.baselineMonthlyGeneration[0]));
    // Electrical configuration remains original; the 3D distribution
    // is a PRELIMINARY optically adjusted yield, not verified wiring.
    expect(list.first.arrays.first.mpptIndex, 1);
  });

  test('Dois inversores com MPPT 1 ficam isolados no modelo e na geração', () {
    final one = systems().first;
    final two = SolarSystem(
      id: 'SYS2', name: 'Inversor 2', inverter: one.inverter,
      arrays: [
        SolarArray(
          solarScenario: one.arrays.first.solarScenario,
          solarScenarioResult: one.arrays.first.solarScenarioResult,
          mpptIndex: 1,
        ),
      ],
    );
    final list = [one, two];
    final scene = Solar3dPlanFactory.fromSystems(list);
    final data = {
      for (var month = 1; month <= 12; month++)
        month: scene.objects.map((panel) {
          final factor = panel.id == 'SYS/1/1' ? .5 : 1.0;
          return PanelMonthlyIrradianceLoss(
            panelId: panel.id, mpptIndex: panel.mpptIndex!,
            stringId: null, monthUtc: month,
            referenceHsp: 5, correctedHsp: 5*factor,
            directLossKwhM2: 0, shadeLossPercent: (1-factor)*100,
          );
        }).toList(),
    };
    final optical = Solar3dOpticalCorrection.fromAnalysis(
      systems:list, scene:scene, monthly:data, yearUtc:2024);
    expect(optical.retention('SYS', 1, 0), closeTo(.75, 1e-12));
    expect(optical.retention('SYS2', 1, 0), 1);
    final baseSecond = two.calculateSystemGenerationForMonth(0, null);
    final correctedSecond = two.calculateSystemGenerationForMonth(
      0, null,
      opticalMpptGroups: optical.groupsBySystemMppt['SYS2']);
    expect(correctedSecond, baseSecond);
  });

  test('Não permite MPPT acima do número real desse inversor', () {
    final list = systems();
    final base = Solar3dPlanFactory.fromSystems(list);
    final invalid = Solar3dScene(base.objects.map((p) =>
      p.id == 'SYS/1/1' ? p.copyWith(mpptIndex: 3) : p).toList());
    expect(() => Solar3dOpticalCorrection.fromAnalysis(
      systems: list, scene: invalid,
      monthly: yearResults(list), yearUtc: 2024,
    ), throwsFormatException);
  });

  test('Rejeita placa omitida e expira quando altera arranjo', () {
    final list = systems();
    final results = yearResults(list);
    expect(() => Solar3dOpticalCorrection.fromAnalysis(
      systems:list, scene:Solar3dPlanFactory.fromSystems(list),
      monthly:results, yearUtc:2024,
      excludedPanelIds:{'SYS/1/1'},
    ), throwsFormatException);
    final correction = make(list, results);
    list.first.arrays.first.mpptIndex = 2;
    expect(correction.isValidFor(list), isFalse);
    final project = SolarProject(
      clientName:'TESTE', city:'Natal',state:'RN',
      latitude:-5.8,longitude:-35.2,
      monthlyConsumption:500, systems:list,
    )..opticalCorrection = correction;
    expect(project.hasAppliedOpticalCorrection, isFalse);
    expect(project.totalMonthlyGeneration, project.baselineMonthlyGeneration);
  });
}
