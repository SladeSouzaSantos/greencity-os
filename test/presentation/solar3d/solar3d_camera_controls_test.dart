import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greencity_os/presentation/widgets/photovoltaic/solar3d_camera_controls.dart';

void main() {
  test('cardinal headings are horizontal rotations of a 3D camera', () {
    expect(Solar3dCameraControls.heading('N'), 0);
    expect(Solar3dCameraControls.heading('L'), -math.pi / 2);
    expect(Solar3dCameraControls.heading('O'), math.pi / 2);
    expect(Solar3dCameraControls.heading('S'), math.pi);
    expect(() => Solar3dCameraControls.heading('X'), throwsArgumentError);
  });

  testWidgets('all camera controls are independent of the object canvas',
      (tester) async {
    final headings = <double>[];
    final pitches = <double>[];
    final yaws = <double>[];
    final pans = <Offset>[];
    var panReset = 0;
    var zoomIn = 0;
    var zoomOut = 0;
    var defaultView = 0;
    var topView = 0;
    await tester.pumpWidget(MaterialApp(home: Scaffold(
      body: SizedBox(height: 440, width: 340,
        child: Solar3dCameraControls(
          yaw: .6, pitch: .8, zoom: 1,
          onHeading: headings.add,
          onPitchStep: pitches.add,
          onYawStep: yaws.add,
          onPanStep: pans.add,
          onResetPan: () => panReset++,
          onDefaultPerspective: () => defaultView++,
          onTopView: () => topView++,
          onZoomIn: () => zoomIn++,
          onZoomOut: () => zoomOut++,
        ),
      ),
    )));
    await tester.tap(find.byTooltip('Vista superior N para cima'));
    await tester.tap(find.byTooltip('Orientar vista para Norte'));
    await tester.tap(find.byTooltip('Orientar vista para Oeste'));
    await tester.tap(find.byTooltip('Orientar vista para Leste'));
    await tester.tap(find.byTooltip('Orientar vista para Sul'));
    await tester.tap(find.byTooltip('Elevar câmera para vista superior'));
    await tester.tap(find.byTooltip('Baixar câmera para perspectiva lateral'));
    await tester.tap(find.byTooltip('Girar câmera para esquerda'));
    await tester.tap(find.byTooltip('Girar câmera para direita'));
    await tester.tap(find.byTooltip('Deslocar vista para cima'));
    await tester.tap(find.byTooltip('Deslocar vista para esquerda'));
    await tester.tap(find.byTooltip('Centralizar deslocamento da vista'));
    await tester.tap(find.byTooltip('Deslocar vista para direita'));
    await tester.tap(find.byTooltip('Deslocar vista para baixo'));
    await tester.tap(find.byTooltip('Restaurar câmera 3D em perspectiva'));
    await tester.tap(find.byTooltip('Aproximar cena'));
    await tester.tap(find.byTooltip('Afastar cena'));
    expect(headings, [0, math.pi / 2, -math.pi / 2, math.pi]);
    expect(pitches, [.16, -.16]);
    expect(yaws, [-.18, .18]);
    expect(pans, [
      const Offset(0, 32),
      const Offset(32, 0),
      const Offset(-32, 0),
      const Offset(0, -32),
    ]);
    expect(panReset, 1);
    expect(defaultView, 1);
    expect(topView, 1);
    expect(zoomIn, 1);
    expect(zoomOut, 1);
  });
}
