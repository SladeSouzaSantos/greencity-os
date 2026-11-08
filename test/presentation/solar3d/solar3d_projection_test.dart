import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greencity_os/domain/solar3d/solar3d_geometric_shading.dart';
import 'package:greencity_os/presentation/widgets/photovoltaic/solar3d_scene_painter.dart';

void main() {
  const panel = Solar3dObject(
    id: 'M01', kind: Solar3dObjectKind.panel,
    center: Solar3dVector(0, 1.2, 0),
    width: 1.1, depth: 2, height: .05, mpptIndex: 1,
  );
  const initial = Solar3dScene([panel]);

  test('Inverter a projeção reproduz X/Z mantendo a altura Y', () {
    const sample = Solar3dVector(2.35, 1.28, -4.72);
    for (final yaw in [0.0, 0.65, -1.4, math.pi / 2]) {
      for (final pitch in [0.25, 0.8, math.pi / 2]) {
        final projection = Solar3dProjection(
          scene: initial, size: const Size(900, 550),
          yaw: yaw, pitch: pitch, zoom: 1.2,
        );
        final screen = projection.project(sample);
        final back = projection.pointOnHorizontalPlane(screen, sample.y);
        expect(back.x, closeTo(sample.x, 1e-9));
        expect(back.y, closeTo(sample.y, 1e-9));
        expect(back.z, closeTo(sample.z, 1e-9));
      }
    }
  });

  test('Norte aparece acima e Leste à direita na vista superior', () {
    final view = Solar3dProjection(
      size: const Size(480, 360), scene: initial,
      yaw: 0, pitch: math.pi/2, zoom: 1,
    );
    final pivot = view.project(const Solar3dVector(0,0,0));
    final north = view.project(const Solar3dVector(0,0,1));
    final east = view.project(const Solar3dVector(1,0,0));
    expect(north.dy, lessThan(pivot.dy));
    expect(east.dx, greaterThan(pivot.dx));
    // Pointer moves right/up: world X east and Z north, not elevation Y.
    final at = view.pointOnHorizontalPlane(pivot + const Offset(40,-40), 0);
    expect(at.x, greaterThan(0));
    expect(at.z, greaterThan(0));
    expect(at.y, 0);
  });

  test('Referência da câmera não se altera quando placa é arrastada', () {
    final moved = Solar3dScene([
      panel.copyWith(center: const Solar3dVector(14,1.2,7)),
    ]);
    final before = Solar3dProjection(
      scene: initial, size: const Size(600,400),
      yaw: 0.5, pitch: 0.8, zoom: 1,
    );
    final after = Solar3dProjection(
      scene: moved, frameScene: initial, size: const Size(600,400),
      yaw: 0.5, pitch: 0.8, zoom: 1,
    );
    const anchor = Solar3dVector(0,0,0);
    expect(after.project(anchor).dx, closeTo(before.project(anchor).dx, 1e-10));
    expect(after.project(anchor).dy, closeTo(before.project(anchor).dy, 1e-10));
    expect(after.scale, before.scale);
  });

  test('Pan da câmera preserva a inversão entre tela e plano horizontal', () {
    const pan = Offset(62, -38);
    const sample = Solar3dVector(1.5, 1.2, -3.0);
    final shifted = Solar3dProjection(
      scene: initial, size: const Size(600, 420),
      yaw: .65, pitch: .8, zoom: 1.3,
      cameraPan: pan,
    );
    final normal = Solar3dProjection(
      scene: initial, size: const Size(600, 420),
      yaw: .65, pitch: .8, zoom: 1.3,
    );
    expect(shifted.project(sample), normal.project(sample) + pan);
    final recovered = shifted.pointOnHorizontalPlane(
      shifted.project(sample), sample.y);
    expect(recovered.x, closeTo(sample.x, 1e-9));
    expect(recovered.y, closeTo(sample.y, 1e-9));
    expect(recovered.z, closeTo(sample.z, 1e-9));
  });

  test('Arrasto em perspectiva não altera eixo Y', () {
    final camera = Solar3dProjection(
      scene: initial, size: const Size(520,480),
      yaw: 0.7, pitch: 0.9, zoom: 1,
    );
    const start = Solar3dVector(1.2,1.3,-2.1);
    final down = camera.project(start);
    final location = camera.pointOnHorizontalPlane(
      down + const Offset(70,40), start.y);
    expect(location.y, start.y);
    expect((location.x - start.x).abs(), greaterThan(1e-2));
    expect((location.z - start.z).abs(), greaterThan(1e-2));
  });
}
