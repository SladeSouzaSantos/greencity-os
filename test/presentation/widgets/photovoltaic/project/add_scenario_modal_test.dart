import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greencity_os/domain/services/hsp_input_validator.dart';
import 'package:greencity_os/domain/entities/pv_module.dart';
import 'package:greencity_os/domain/entities/solar_scenario.dart';
import 'package:greencity_os/domain/enums/cell_technology.dart';
import 'package:greencity_os/domain/solar3d/solar3d_panel_height.dart';
import 'package:greencity_os/presentation/widgets/photovoltaic/project/add_scenario_modal.dart';

void main() {
  testWidgets('Novo dimensionamento inicia altura da borda inferior em 0.15 m',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: AddScenarioModal(
          city: 'Natal',
          state: 'RN',
          availableModules: const [],
          manufacturers: const [],
          currentScenarioCount: 0,
          defaultLatitude: -5.8,
          onScenariosAdded: (_) {},
        ),
      ),
    ));

    final heightField = tester.widget<TextField>(
      find.byWidgetPredicate(
        (widget) => widget is TextField &&
            widget.decoration?.labelText == 'Altura da borda inferior ao solo (m)',
      ),
    );

    expect(heightField.controller?.text, '0.15');
    expect(HspInputValidator.parseNumber(heightField.controller?.text), 0.15);
    expect(HspInputValidator.validateModuleLowerEdgeHeight(
      heightField.controller?.text,
    ), isNull);
    // Obstacle capture is exclusively in Solar3D. This form must always
    // produce obstacle-free HSP scenario input.
    expect(find.byType(SwitchListTile), findsNothing);
    expect(find.text('Simular Sombreamento Individual?'), findsNothing);
    expect(find.textContaining('Adicione e posicione obstáculos'),
      findsOneWidget);
  });

  testWidgets('Cadastro envia altura do centro à API após receber borda inferior',
      (tester) async {
    final module = PvModule(
      manufacturer: 'TEST', modelName: 'T-500',
      cellTechnology: CellTechnology.topcon, powerWp: 500,
      efficiency: 20, length: 2000, width: 1000, weight: 25,
      vOc: 49, iSc: 13, vMp: 41, iMp: 12,
      tempCoefVoc: -.3, tempCoefIsc: .045,
      tempCoefPmax: -.3, isBifacial: false,
    );
    List<SolarScenario>? added;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: AddScenarioModal(
        city: 'Natal', state: 'RN',
        availableModules: [module],
        manufacturers: const ['TEST'],
        initialManufacturer: 'TEST',
        initialModule: module,
        currentScenarioCount: 0,
        defaultLatitude: -20,
        onScenariosAdded: (scenarios) => added = scenarios,
      )),
    ));
    final h = find.byWidgetPredicate((widget) =>
        widget is TextField &&
        widget.decoration?.labelText ==
            'Altura da borda inferior ao solo (m)');
    expect(h, findsOneWidget);
    expect(find.textContaining('Meça verticalmente'), findsOneWidget);
    await tester.ensureVisible(find.text('Adicionar'));
    await tester.tap(find.text('Adicionar'));
    await tester.pump();
    expect(added, isNotNull);
    expect(added!.length, 1);
    final expectedCenter = Solar3dPanelHeight.centerFromLowerEdge(
      lowerEdgeMeters: .15,
      depthMeters: 2,
      tiltDegrees: 20,
    );
    expect(added!.single.distanceToGround, closeTo(expectedCenter, 1e-10));
    expect(added!.single.obstacle, isNull);
  });
}
