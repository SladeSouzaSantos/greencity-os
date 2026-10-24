import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greencity_os/domain/services/hsp_input_validator.dart';
import 'package:greencity_os/presentation/widgets/photovoltaic/project/add_scenario_modal.dart';

void main() {
  testWidgets('Novo dimensionamento inicia altura do centro do módulo em 0.15 m',
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

    final heightField = tester.widget<TextFormField>(
      find.byWidgetPredicate(
        (widget) => widget is TextFormField &&
            widget.decoration?.labelText == 'Altura do centro do módulo (m)',
      ),
    );

    expect(heightField.controller?.text, '0.15');
    expect(HspInputValidator.parseNumber(heightField.controller?.text), 0.15);
    expect(HspInputValidator.validateModuleCenterHeight(
      heightField.controller?.text,
    ), isNull);
  });
}
