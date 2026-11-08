import 'package:flutter/material.dart';
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
import 'package:greencity_os/presentation/pages/photovoltaic/solar3d_editor_page.dart';

void main() {
  testWidgets(
    '3 microinverters: selecting MPPTs and folding 3D sections does not '
    'duplicate scrollable GlobalKeys',
    (tester) async {
      tester.view.physicalSize = const Size(460, 880);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final module = PvModule(
        manufacturer: 'TEST', modelName: '500 W',
        cellTechnology: CellTechnology.topcon, powerWp: 500,
        efficiency: 20, length: 2000, width: 1000, weight: 25,
        vOc: 49, iSc: 13, vMp: 41, iMp: 12,
        tempCoefVoc: -.3, tempCoefIsc: .04,
        tempCoefPmax: -.3, isBifacial: false,
      );
      final inverter = Inverter(
        manufacturer: 'TEST', modelName: 'MI-2MPPT',
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
      final systems = [
        for (var i = 1; i <= 3; i++)
          SolarSystem(
            id: 'MI-$i', name: 'Micro $i', inverter: inverter,
            arrays: [
              SolarArray(
                mpptIndex: 1,
                solarScenario: SolarScenario(
                  id: 'A-$i', city: 'Natal', state: 'RN',
                  inclination: 15, azimuth: 0,
                  distanceToGround: 1,
                  module: module, quantityPvModule: 4,
                ),
                solarScenarioResult: SolarScenarioResult(
                  id: 'A-$i', averageHspReal: 5,
                  monthlyHspReal: List.filled(12, 5),
                  averageHspReference: 5,
                  monthlyHspReference: List.filled(12, 5),
                  shadowLossPercentage: '0.0%',
                ),
              ),
            ],
          ),
      ];
      final project = SolarProject(
        clientName: 'UI REGRESSION', city: 'Natal', state: 'RN',
        latitude: -5.8125, longitude: -35.1875,
        monthlyConsumption: 500, systems: systems,
      );

      await tester.pumpWidget(MaterialApp(
        home: Solar3dEditorPage(project: project, systems: systems),
      ));
      await tester.pumpAndSettle();

      // Scroll PROGRAMMATICALLY: the 3D canvas deliberately takes
      // priority over vertical drag gestures inside its bounds. The
      // default scrollUntilVisible drags at viewport center, often on
      // top of the canvas, and cannot reach lazily built sections.
      Future<void> reveal(Finder target) async {
        final outer = tester.state<ScrollableState>(
            find.byType(Scrollable).first);
        for (var i = 0; target.evaluate().isEmpty && i < 80; i++) {
          final next = (outer.position.pixels + 240).clamp(
              outer.position.minScrollExtent,
              outer.position.maxScrollExtent).toDouble();
          outer.position.jumpTo(next);
          await tester.pump();
        }
        expect(target, findsOneWidget);
        await tester.ensureVisible(target);
        await tester.pumpAndSettle();
      }

      final objectsHeader = find.text('Objetos, posições e MPPTs');
      await reveal(objectsHeader);
      await tester.tap(objectsHeader);
      await tester.pumpAndSettle();

      Future<void> chooseMppt2(String id) async {
        final selector = find.byKey(ValueKey('solar3d-mppt-$id'));
        await tester.ensureVisible(selector);
        await tester.tap(selector);
        await tester.pumpAndSettle();
        await tester.tap(find.textContaining('MPPT 2 ·').last);
        await tester.pumpAndSettle();
        expect(tester.widget<DropdownButton<int>>(selector).value, 2);
        expect(tester.takeException(), isNull);
      }

      await chooseMppt2('MI-1/1/1');
      // Select a panel from a DIFFERENT inverter.
      final other = find.byWidgetPredicate((widget) {
        if (widget is! InputChip) return false;
        final label = widget.label;
        return label is Text &&
            (label.data ?? '').contains('Inversor 2');
      });
      expect(other, findsWidgets);
      await tester.ensureVisible(other.first);
      await tester.tap(other.first);
      await tester.pumpAndSettle();
      await chooseMppt2('MI-2/1/1');

      await tester.ensureVisible(objectsHeader);
      await tester.tap(objectsHeader); // unmount MPPT controls
      await tester.pumpAndSettle();
      final hspHeader = find.text('Calcular perdas ópticas · 12 meses');
      await reveal(hspHeader);
      await tester.tap(hspHeader); // mount an endpoint editor and year dropdown
      await tester.pumpAndSettle();
      expect(find.text('Mais recente completo (automático)'),
          findsOneWidget);
      await tester.ensureVisible(objectsHeader);
      await tester.tap(objectsHeader);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      // No physical array rewiring: the 3D MPPT labels are study-only.
      for (final system in systems) {
        expect(system.arrays.single.mpptIndex, 1);
      }
    },
  );
}
