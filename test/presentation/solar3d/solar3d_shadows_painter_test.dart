import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greencity_os/domain/solar3d/solar3d_geometric_shading.dart';
import 'package:greencity_os/presentation/widgets/photovoltaic/solar3d_scene_painter.dart';

void main() {
  const panel = Solar3dObject(
    id: 'M01', kind: Solar3dObjectKind.panel,
    center: Solar3dVector(0, 1, 0),
    width: 1.2, depth: 2.2, height: .04, mpptIndex: 1,
  );
  const building = Solar3dObject(
    id: 'building', kind: Solar3dObjectKind.obstacle,
    center: Solar3dVector(3, 1.7, 2),
    width: 2, depth: 2, height: 3.4,
  );
  const scene = Solar3dScene([panel, building]);
  final view = Solar3dProjection(
    scene: scene, size: const Size(450, 350),
    yaw: .4, pitch: 1, zoom: 1,
  );

  test('Sombra no terreno desloca para Oeste com sol no Leste', () {
    final morning = Solar3dScenePainter.groundShadowFootprint(
      object: building, view: view,
      sunAzimuthDegrees: 90, sunElevationDegrees: 35);
    final afternoon = Solar3dScenePainter.groundShadowFootprint(
      object: building, view: view,
      sunAzimuthDegrees: 270, sunElevationDegrees: 35);
    expect(morning.length, greaterThanOrEqualTo(3));
    expect(afternoon.length, greaterThanOrEqualTo(3));
    final minMorningX = morning.map((p) => p.dx).reduce(
      (a,b) => a < b ? a : b);
    final maxAfternoonX = afternoon.map((p) => p.dx).reduce(
      (a,b) => a > b ? a : b);
    expect(minMorningX, lessThan(building.center.x - building.width/2));
    expect(maxAfternoonX, greaterThan(building.center.x + building.width/2));
  });

  test('À noite não se projeta sombra solar direta', () {
    expect(Solar3dScenePainter.groundShadowFootprint(
      object: building, view: view,
      sunAzimuthDegrees: 90, sunElevationDegrees: -10), isEmpty);
  });

  test('Módulos também projetam suas sombras a partir do centro', () {
    final footprint = Solar3dScenePainter.groundShadowFootprint(
      object: panel, view: view,
      sunAzimuthDegrees: 90, sunElevationDegrees: 35);
    expect(footprint.length, greaterThanOrEqualTo(3));
    expect(footprint.map((point) => point.dx).reduce(
      (a,b) => a < b ? a : b), lessThan(0));
  });
}
