import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greencity_os/domain/solar3d/electrical/solar3d_single_diode.dart';
import 'package:greencity_os/presentation/widgets/photovoltaic/solar3d_calibration_dialog.dart';

void main() {
  testWidgets('manual verified-origin parameter form refuses missing source',
      (tester) async {
    Solar3dDiodeCalibration? recorded;
    await tester.pumpWidget(MaterialApp(home: Scaffold(
      body: Builder(builder: (context) => TextButton(
        onPressed: () async {
          recorded = await showDialog<Solar3dDiodeCalibration>(
            context: context,
            builder: (_) => const Solar3dCalibrationDialog(
                moduleModel: 'TEST / 500W'),
          );
        },
        child: const Text('Abrir'),
      )),
    )));
    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Salvar parâmetros de estudo'));
    await tester.pumpAndSettle();
    expect(recorded, isNull);
    expect(find.text('Fonte / arquivo / versão de calibração'), findsOneWidget);
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
