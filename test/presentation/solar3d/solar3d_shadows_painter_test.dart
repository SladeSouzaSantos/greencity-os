import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greencity_os/domain/solar3d/solar3d_geometric_shading.dart';
import 'package:greencity_os/presentation/widgets/photovoltaic/solar3d_scene_painter.dart';

void main() {
  const scene = Solar3dScene([
    Solar3dObject(
      id: 'M01', kind: Solar3dObjectKind.panel,
      center: Solar3dVector(0, 1, 0),
      width: 1.2, depth: 2.2, height: .04, mpptIndex: 1,
    ),
    Solar3dObject(
      id: 'building', kind: Solar3dObjectKind.obstacle,
      center: Solar3dVector(3, 1.7, 2.0),
      width: 2, depth: 2, height: 3.4,
    ),
  ]);

  Future<Uint8List> render(double azimuth, double elevation) async {
    const width = 450, height = 350;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final painter = Solar3dScenePainter(
      scene: scene, frameScene: scene,
      hiddenIds: const {}, excludedIds: const {},
      selectedId: 'M01', yaw: .4, pitch: 1.0, zoom: 1,
      directShadeByPanel: const {'M01': 0},
      sunAzimuthDegrees: azimuth,
      sunElevationDegrees: elevation,
    );
    painter.paint(canvas, const Size(450, 350));
    final image = await recorder.endRecording().toImage(width, height);
    final pixels = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    image.dispose();
    if (pixels == null) throw StateError('Canvas sem imagem');
    return pixels.buffer.asUint8List();
  }

  testWidgets('Sombras no solo mudam com a direção do Sol', (tester) async {
    final morning = await render(90, 35);
    final afternoon = await render(270, 35);
    var differences = 0;
    for (var i = 0; i < morning.length; i += 4) {
      if (morning[i] != afternoon[i] ||
          morning[i + 1] != afternoon[i + 1] ||
          morning[i + 2] != afternoon[i + 2]) {
        differences++;
      }
    }
    expect(differences, greaterThan(150));
  });

  testWidgets('À noite desaparece projeção solar direta', (tester) async {
    final day = await render(90, 35);
    final night = await render(90, -10);
    expect(night.length, day.length);
    expect(day, isNot(equals(night)));
  });
}
