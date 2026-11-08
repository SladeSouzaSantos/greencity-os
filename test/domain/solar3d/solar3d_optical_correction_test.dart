import 'dart:io';

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
import 'package:greencity_os/domain/solar3d/solar3d_electrical_audit.dart';
import 'package:greencity_os/domain/solar3d/solar3d_plan_factory.dart';
import 'package:greencity_os/data/datasources/solar3d_scene_storage.dart';
import 'package:greencity_os/domain/solar3d/solar3d_scene_document.dart';

void main() {
  List<SolarSystem> systems({
    double moduleImpA = 12,
    double moduleIscA = 13,
    double operatingLimitA = 20,
    double shortCircuitLimitA = 30,
  }) {
    final module = PvModule(
      manufacturer: 'TEST', modelName: '500 W',
      cellTechnology: CellTechnology.topcon, powerWp: 500,
      efficiency: 20, length: 2000, width: 1000, weight: 25,
      vOc: 49, iSc: moduleIscA, vMp: 41, iMp: moduleImpA,
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
      maxInputCurrentPerMppt: operatingLimitA,
      maxShortCircuitCurrent: shortCircuitLimitA,
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

  test('Correção 3D confirmada sobrevive à reabertura sem recalcular HSP',
      () async {
    final dir = await Directory.systemTemp.createTemp('greencity-3d-optical-');
    addTearDown(() async {
      if (await dir.exists()) await dir.delete(recursive: true);
    });
    final list = systems();
    final scene = Solar3dPlanFactory.fromSystems(list);
    final doc = Solar3dSceneDocument(scene: scene);
    final calculated = make(list, yearResults(list));
    final store = Solar3dSceneStorage('optical-project', rootDirectory: dir);
    await store.save(doc);
    await store.saveAppliedCorrection(scene: doc, correction: calculated);

    final reopened = Solar3dSceneStorage(
        'optical-project', rootDirectory: dir);
    final restored = await reopened.loadAppliedCorrection(systems: list);
    expect(restored, isNotNull);
    expect(restored!.weatherYearUtc, 2024);
    expect(restored.panelCount, 4);
    expect(restored.designSignature, calculated.designSignature);
    for (final system in calculated.retentionBySystemMppt.entries) {
      for (final mppt in system.value.keys) {
        for (var month = 0; month < 12; month++) {
          expect(restored.retention(system.key, mppt, month),
              calculated.retention(system.key, mppt, month));
        }
      }
    }
    final project = SolarProject(
      clientName: 'C', city: 'Natal', state: 'RN',
      latitude: -5.8, longitude: -35.2,
      monthlyConsumption: 500, systems: list,
    )..opticalCorrection = restored;
    expect(project.hasAppliedOpticalCorrection, true);
    expect(project.totalMonthlyGeneration[0],
        lessThan(project.baselineMonthlyGeneration[0]));
    // Merely reopening/saving an unchanged scene preserves the factors.
    await reopened.save(doc);
    expect((await reopened.loadAppliedCorrection(systems: list))
        ?.retention('SYS', 1, 0), closeTo(.75, 1e-12));
  });

  test('Alteração de geometria, MPPT ou projeto invalida perda persistida',
      () async {
    final dir = await Directory.systemTemp.createTemp('greencity-3d-optical-');
    addTearDown(() async {
      if (await dir.exists()) await dir.delete(recursive: true);
    });
    final list = systems();
    final scene = Solar3dPlanFactory.fromSystems(list);
    final original = Solar3dSceneDocument(scene: scene);
    final correction = make(list, yearResults(list));
    final store = Solar3dSceneStorage('mismatch', rootDirectory: dir);
    await store.save(original);
    await store.saveAppliedCorrection(scene: original, correction: correction);

    final moved = Solar3dSceneDocument(scene: Solar3dScene(
      scene.objects.map((p) => p.id == 'SYS/1/1'
          ? p.copyWith(center: const Solar3dVector(10, 1, 0)) : p)
          .toList()));
    await store.save(moved);
    expect(await store.loadAppliedCorrection(systems: list), isNull);

    await store.save(original);
    await store.saveAppliedCorrection(scene: original, correction: correction);
    list.first.arrays.first.mpptIndex = 2;
    expect(await store.loadAppliedCorrection(systems: list), isNull);

    await store.clearAppliedCorrection();
    expect(await store.loadAppliedCorrection(systems: list), isNull);
    expect(await store.load(), isNotNull);
    await store.clear();
    expect(await store.load(), isNull);
  });

  test('Versões/correções adulteradas falham com segurança', () {
    final corrected = make(systems(), yearResults(systems()));
    final json = corrected.toJson();
    expect(Solar3dOpticalCorrection.fromJson(json)
        .retention('SYS', 1, 0), closeTo(.75, 1e-12));
    expect(() => Solar3dOpticalCorrection.fromJson({
      ...json, 'schema_version': 999,
    }), throwsFormatException);
    final broken = Map<String, dynamic>.from(json);
    final groups = Map<String, dynamic>.from(broken['groups'] as Map);
    final sys = Map<String, dynamic>.from(groups['SYS'] as Map);
    final mppt = Map<String, dynamic>.from(sys['1'] as Map);
    mppt['retention_monthly'] = List.filled(11, .9);
    sys['1'] = mppt;
    groups['SYS'] = sys;
    broken['groups'] = groups;
    expect(() => Solar3dOpticalCorrection.fromJson(broken),
        throwsFormatException);
  });

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

  test('Quatro placas cadastradas juntas admitem divisão 3+1 em MPPTs', () {
    final template = systems().first;
    final baseScenario = template.arrays.first.solarScenario;
    final array = SolarArray(
      mpptIndex: 1,
      solarScenario: SolarScenario(
        id: 'QUATRO', city: 'Natal', state: 'RN',
        inclination: baseScenario.inclination,
        azimuth: baseScenario.azimuth,
        distanceToGround: baseScenario.distanceToGround,
        module: baseScenario.module,
        quantityPvModule: 4,
      ),
      solarScenarioResult: SolarScenarioResult(
        id: 'QUATRO', averageHspReal: 5,
        monthlyHspReal: List.filled(12, 5),
        averageHspReference: 5,
        monthlyHspReference: List.filled(12, 5),
        shadowLossPercentage: '0.0%',
      ),
    );
    final list = [SolarSystem(
      id: 'QUATRO-SYS', name: 'Inversor único',
      inverter: template.inverter, arrays: [array],
    )];
    final scene = Solar3dPlanFactory.fromSystems(list);
    expect(scene.objects.length, 4);
    final remapped = Solar3dScene(scene.objects.map((o) =>
      o.id == 'QUATRO-SYS/1/4' ? o.copyWith(mpptIndex: 2) : o).toList());
    final monthly = {
      for (var month = 1; month <= 12; month++)
        month: remapped.objects.map((o) =>
          PanelMonthlyIrradianceLoss(
            panelId: o.id, mpptIndex: o.mpptIndex!,
            stringId: null, monthUtc: month,
            referenceHsp: 5, correctedHsp: o.mpptIndex == 2 ? 4 : 5,
            directLossKwhM2: 0, shadeLossPercent: o.mpptIndex == 2 ? 20 : 0,
          )).toList(),
    };
    final optical = Solar3dOpticalCorrection.fromAnalysis(
      systems: list, scene: remapped, monthly: monthly, yearUtc: 2023);
    expect(optical.groupsBySystemMppt['QUATRO-SYS']![1]!.moduleCount, 3);
    expect(optical.groupsBySystemMppt['QUATRO-SYS']![2]!.moduleCount, 1);
    expect(optical.groupsBySystemMppt['QUATRO-SYS']![1]!.powerWp, 1500);
    expect(optical.groupsBySystemMppt['QUATRO-SYS']![2]!.powerWp, 500);
    expect(array.mpptIndex, 1); // Physical wiring unchanged.
  });

  test('Três microinversores: quatro placas por arranjo e MPPTs isolados',
      () {
    final sample = systems().single;
    final module = sample.arrays.first.solarScenario.module;
    final microinverter = Inverter(
      manufacturer: 'MICRO', modelName: 'MI-2MPPT',
      inverterType: InverterType.microInverter, isHybrid: false,
      nominalPowerKw: 2, maxInputPowerKw: 2.5,
      maxEfficiency: .97, euroEfficiency: .96, mpptCount: 2,
      maxInputVoltage: 100, nominalVoltageDc: 50,
      startVoltage: 20, minMpptVoltage: 20, maxMpptVoltage: 90,
      maxInputCurrentPerMppt: 20, maxShortCircuitCurrent: 30,
      gridConnection: GridConnection.monophasic, maxOutputCurrent: 15,
      nominalVoltageAc: 220, dimensions: '', weight: 5,
      minOperatingTemp: -20, maxOperatingTemp: 60,
      protectionDegree: 'IP67',
    );
    final three = [
      for (var i = 1; i <= 3; i++)
        SolarSystem(
          id: 'MICRO-$i',
          name: 'Microinversor $i',
          inverter: microinverter,
          arrays: [
            SolarArray(
              mpptIndex: 1,
              solarScenario: SolarScenario(
                id: 'A-MI-$i', city: 'Natal', state: 'RN',
                inclination: 15, azimuth: 0,
                distanceToGround: 1,
                module: module, quantityPvModule: 4,
              ),
              solarScenarioResult: SolarScenarioResult(
                id: 'A-MI-$i', averageHspReal: 5,
                monthlyHspReal: List.filled(12, 5),
                averageHspReference: 5,
                monthlyHspReference: List.filled(12, 5),
                shadowLossPercentage: '0.0%',
              ),
            ),
          ],
        ),
    ];
    final original = Solar3dPlanFactory.fromSystems(three);
    expect(original.objects.length, 12);
    expect(original.objects.every((p) => p.mpptIndex == 1), true);

    // Reassign panels ONLY inside their own inverter in the 3D study.
    final edited = Solar3dScene(original.objects.map((panel) {
      final selectedOtherTracker =
          panel.id == 'MICRO-1/1/1' ||
          panel.id == 'MICRO-2/1/1' ||
          panel.id == 'MICRO-2/1/2';
      return selectedOtherTracker
          ? panel.copyWith(mpptIndex: 2) : panel;
    }).toList());
    final monthly = {
      for (var m = 1; m <= 12; m++)
        m: edited.objects.map((p) {
          final factor = p.id == 'MICRO-1/1/1' ? .5 :
              p.id == 'MICRO-2/1/2' ? .8 : 1.0;
          return PanelMonthlyIrradianceLoss(
            panelId: p.id, mpptIndex: p.mpptIndex!,
            stringId: null, monthUtc: m,
            referenceHsp: 5, correctedHsp: 5 * factor,
            directLossKwhM2: 0,
            shadeLossPercent: (1 - factor) * 100,
          );
        }).toList(),
    };

    final correction = Solar3dOpticalCorrection.fromAnalysis(
      systems: three, scene: edited, monthly: monthly, yearUtc: 2024,
    );
    expect(correction.panelCount, 12);
    expect(correction.groupsBySystemMppt.keys.toSet(),
        {'MICRO-1', 'MICRO-2', 'MICRO-3'});
    expect(correction.groupsBySystemMppt['MICRO-1']![1]!.moduleCount, 3);
    expect(correction.groupsBySystemMppt['MICRO-1']![2]!.moduleCount, 1);
    expect(correction.groupsBySystemMppt['MICRO-2']![1]!.moduleCount, 2);
    expect(correction.groupsBySystemMppt['MICRO-2']![2]!.moduleCount, 2);
    expect(correction.groupsBySystemMppt['MICRO-3']![1]!.moduleCount, 4);
    expect(correction.groupsBySystemMppt['MICRO-3']!.containsKey(2), false);
    expect(correction.retention('MICRO-1', 2, 0), closeTo(.5, 1e-9));
    expect(correction.retention('MICRO-2', 2, 0), closeTo(.9, 1e-9));
    expect(correction.retention('MICRO-3', 1, 0), 1);
    for (final inverter in three) {
      expect(inverter.arrays.single.mpptIndex, 1);
    }
    // This verifies grouping only. Actual electrical compatibility of
    // microinverter channels/strings still depends on device specifications.
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

  test('Auditoria elétrica: MPPT subdimensionado não é geração válida', () {
    final list = systems();
    final base = Solar3dPlanFactory.fromSystems(list);
    final scene = Solar3dScene(base.objects.map((panel) {
      // MPPT 1 has two 1-module parallel strings: 41 V < 50 V,
      // and 24 A > the 20 A usable MPPT limit (warning); MPPT 2 is valid.
      final string = panel.id == 'SYS/1/1' ? 'S1' :
          panel.id == 'SYS/1/2' ? 'S2' : 'S3';
      return panel.copyWith(stringId: string);
    }).toList());
    final report = Solar3dElectricalAudit.inspect(
      systems: list, scene: scene, minimumAmbientC: -10);
    expect(report.topologyComplete, true);
    expect(report.hasBlockers, true);
    expect(report.trackers.length, 2);
    expect(report.findings.any((f) =>
      f.code == 'MPPT_UNDERVOLTAGE'), true);
    expect(report.findings.any((f) =>
      f.code == 'MPPT_CURRENT_LIMIT' &&
      f.severity == Solar3dElectricalSeverity.warning), true);
    expect(report.findings.any((f) =>
      f.code == 'COLD_VOC_UNAVAILABLE'), false);
    final first = report.trackers.firstWhere((t) => t.mpptIndex == 1);
    expect(first.parallelImpStcA, 24);
    expect(first.parallelIscStcA, 26);
  });

  test('Solplanet 16 A operacional / 22,5 A Isc: alerta sem bloqueio', () {
    final list = systems(
      moduleImpA: 17.57, moduleIscA: 18.6,
      operatingLimitA: 16, shortCircuitLimitA: 22.5,
    );
    final base = Solar3dPlanFactory.fromSystems(list);
    final scene = Solar3dScene(base.objects.map((p) =>
        p.copyWith(stringId: p.mpptIndex == 1 ? 'S1' : 'S2'))
      .toList());
    final report = Solar3dElectricalAudit.inspect(
      systems: list, scene: scene, minimumAmbientC: -5);
    expect(report.topologyComplete, true);
    expect(report.hasBlockers, false);
    expect(report.hasWarnings, true);
    expect(report.findings.where((f) =>
        f.code == 'MPPT_CURRENT_LIMIT' &&
        f.severity == Solar3dElectricalSeverity.warning).length, 2);
    expect(report.findings.any((f) =>
        f.code == 'MPPT_SHORT_CIRCUIT'), false);
    for (final mppt in report.trackers) {
      expect(mppt.parallelImpStcA, closeTo(17.57, 1e-8));
      expect(mppt.parallelIscStcA, closeTo(18.6, 1e-8));
      expect(mppt.operatingCurrentLimitA, 16);
      expect(mppt.shortCircuitCurrentLimitA, 22.5);
    }
    expect(report.electricallyCalibrated, false);
  });

  test('Isc acima de 22,5 A continua bloqueando com Imp dentro de 16 A', () {
    final list = systems(
      moduleImpA: 15, moduleIscA: 23,
      operatingLimitA: 16, shortCircuitLimitA: 22.5,
    );
    final base = Solar3dPlanFactory.fromSystems(list);
    final scene = Solar3dScene(base.objects.map((p) =>
        p.copyWith(stringId: p.mpptIndex == 1 ? 'S1' : 'S2'))
      .toList());
    final report = Solar3dElectricalAudit.inspect(
      systems: list, scene: scene, minimumAmbientC: -5);
    expect(report.topologyComplete, true);
    expect(report.hasBlockers, true);
    expect(report.findings.where((f) =>
        f.code == 'MPPT_SHORT_CIRCUIT' &&
        f.severity == Solar3dElectricalSeverity.blocking).length, 2);
    expect(report.findings.any((f) =>
        f.code == 'MPPT_CURRENT_LIMIT'), false);
  });

  test('Auditoria elétrica não confunde string S1 de outro inversor', () {
    final first = systems().first;
    final second = SolarSystem(
      id: 'SYS-OTHER', name: 'Inversor 2', inverter: first.inverter,
      arrays: [first.arrays.first],
    );
    final list = [first, second];
    final base = Solar3dPlanFactory.fromSystems(list);
    final scene = Solar3dScene(base.objects.map((panel) =>
      panel.copyWith(stringId: panel.mpptIndex == 1 ? 'S1' : 'S2'))
        .toList());
    final report = Solar3dElectricalAudit.inspect(
      systems: list, scene: scene, minimumAmbientC: -5);
    expect(report.topologyComplete, true);
    expect(report.findings.any((f) =>
      f.code == 'STRING_CROSSES_MPPTS'), false);
    expect(report.trackers.where((t) => t.mpptIndex == 1).length, 2);
    expect(report.trackers.map((t) => t.inverterId).toSet(),
      {'SYS', 'SYS-OTHER'});
    expect(report.trackers
        .where((t) => t.inverterId == 'SYS-OTHER')
        .single.strings.single.moduleCount, 2);
  });

  test('Auditoria detecta string atravessando dois MPPTs', () {
    final list = systems();
    final base = Solar3dPlanFactory.fromSystems(list);
    final scene = Solar3dScene(base.objects.map((panel) =>
      panel.copyWith(stringId: 'SAME')).toList());
    final report = Solar3dElectricalAudit.inspect(
      systems: list, scene: scene, minimumAmbientC: -5);
    expect(report.findings.any((f) =>
      f.code == 'STRING_CROSSES_MPPTS'), true);
  });

  test('Sem IDs de string, não finge conhecer circuito elétrico', () {
    final list = systems();
    final report = Solar3dElectricalAudit.inspect(
      systems: list,
      scene: Solar3dPlanFactory.fromSystems(list));
    expect(report.assignedPanels, 0);
    expect(report.topologyComplete, false);
    expect(report.trackers, isEmpty);
    expect(report.electricallyCalibrated, false);
    expect(report.findings.any((f) =>
      f.code == 'COLD_VOC_UNAVAILABLE'), true);
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
