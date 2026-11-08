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
    var zoomIn = 0;
    var zoomOut = 0;
    var defaultView = 0;
    await tester.pumpWidget(MaterialApp(home: Scaffold(
      body: SizedBox(height: 360, width: 320,
        child: Solar3dCameraControls(
          yaw: .6, pitch: .8, zoom: 1,
          onHeading: headings.add,
          onPitchStep: pitches.add,
          onDefaultPerspective: () => defaultView++,
          onZoomIn: () => zoomIn++,
          onZoomOut: () => zoomOut++,
        ),
      ),
    )));
    await tester.tap(find.byTooltip('Orientar vista para Norte'));
    await tester.tap(find.byTooltip('Orientar vista para Oeste'));
    await tester.tap(find.byTooltip('Orientar vista para Leste'));
    await tester.tap(find.byTooltip('Orientar vista para Sul'));
    await tester.tap(find.byTooltip('Elevar câmera para vista superior'));
    await tester.tap(find.byTooltip('Baixar câmera para perspectiva lateral'));
    await tester.tap(find.byTooltip('Restaurar câmera 3D em perspectiva'));
    await tester.tap(find.byTooltip('Aproximar cena'));
    await tester.tap(find.byTooltip('Afastar cena'));
    expect(headings, [0, math.pi / 2, -math.pi / 2, math.pi]);
    expect(pitches, [.16, -.16]);
    expect(defaultView, 1);
    expect(zoomIn, 1);
    expect(zoomOut, 1);
  });
}
