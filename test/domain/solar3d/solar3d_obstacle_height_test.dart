import 'package:flutter_test/flutter_test.dart';
import 'package:greencity_os/domain/solar3d/solar3d_geometric_shading.dart';
import 'package:greencity_os/domain/solar3d/solar3d_obstacle_height.dart';
import 'package:greencity_os/domain/solar3d/solar3d_scene_document.dart';

void main() {
  const obstacle = Solar3dObject(
    id: 'wall', kind: Solar3dObjectKind.obstacle,
    center: Solar3dVector(-6, 1.5, 0),
    width: 1.6, depth: 3, height: 3,
  );
  const panel = Solar3dObject(
    id: 'm/1/1', kind: Solar3dObjectKind.panel,
    center: Solar3dVector(-4, 1, 0),
    width: 1, depth: 2, height: .045, mpptIndex: 1,
  );

  test('base zero touches ground and obstacle top remains at 3 m', () {
    final o = Solar3dObstacleHeight.withBase(obstacle, 0);
    expect(o.center.y, 1.5);
    expect(Solar3dObstacleHeight.baseOf(o), 0);
    expect(Solar3dObstacleHeight.topOf(o), 3);
    expect(o.center.x, -6);
    expect(o.center.z, 0);
  });

  test('base 2 m and obstacle 3 m means center 3.5 m, top 5 m', () {
    final o = Solar3dObstacleHeight.withBase(obstacle, 2);
    expect(o.center.y, 3.5);
    expect(Solar3dObstacleHeight.baseOf(o), 2);
    expect(Solar3dObstacleHeight.topOf(o), 5);
    expect(o.height, 3);
  });

  test('changing obstacle height anchors base and does not move X/Z', () {
    final raised = Solar3dObstacleHeight.withBase(obstacle, 2);
    final taller = Solar3dObstacleHeight.withHeight(raised, 5);
    expect(Solar3dObstacleHeight.baseOf(taller), 2);
    expect(Solar3dObstacleHeight.topOf(taller), 7);
    expect(taller.center.y, 4.5);
    expect(taller.center.x, raised.center.x);
    expect(taller.center.z, raised.center.z);
    expect(taller.width, raised.width);
  });

  test('negative base, invalid height and excessive elevation rejected', () {
    expect(() => Solar3dObstacleHeight.withBase(obstacle, -.01),
        throwsFormatException);
    expect(() => Solar3dObstacleHeight.withBase(obstacle, double.nan),
        throwsFormatException);
    expect(() => Solar3dObstacleHeight.withBase(obstacle, 500),
        throwsFormatException);
    expect(() => Solar3dObstacleHeight.withHeight(obstacle, 0),
        throwsFormatException);
    expect(() => Solar3dObstacleHeight.baseOf(panel),
        throwsFormatException);
  });

  test('building uses same base convention', () {
    const building = Solar3dObject(
      id: 'house', kind: Solar3dObjectKind.building,
      center: Solar3dVector(0, 2, 0),
      width: 2, depth: 2, height: 4,
    );
    expect(Solar3dObstacleHeight.baseOf(building), 0);
    expect(Solar3dObstacleHeight.withBase(building, 1).center.y, 3);
  });

  test('persisted JSON v1 retains center and raycasting geometry', () {
    final oldScene = Solar3dScene([panel, obstacle]);
    final shade = Solar3dGeometricShading.blockedFraction(
      panel: panel, scene: oldScene,
      sunAzimuthDegrees: 270, sunElevationDegrees: 30,
      rows: 12, columns: 8);
    final encoded = Solar3dSceneDocument(scene: oldScene).encode();
    final saved = Solar3dSceneDocument.decode(encoded);
    expect(saved.toJson()['schema_version'], 1);
    expect(saved.scene.objects.last.center.y, 1.5);
    expect(Solar3dObstacleHeight.baseOf(saved.scene.objects.last), 0);
    final after = Solar3dGeometricShading.blockedFraction(
      panel: saved.scene.objects.first, scene: saved.scene,
      sunAzimuthDegrees: 270, sunElevationDegrees: 30,
      rows: 12, columns: 8);
    expect(after, shade);
    expect(after, greaterThan(.5));
  });

  test('legacy center zero remains untouched until explicitly grounded', () {
    final legacy = obstacle.copyWith(
        center: const Solar3dVector(-6, 0, 0));
    final persisted = Solar3dSceneDocument.decode(
        Solar3dSceneDocument(
            scene: Solar3dScene([panel, legacy])).encode());
    final old = persisted.scene.objects.last;
    expect(old.center.y, 0);
    expect(Solar3dObstacleHeight.baseOf(old), -1.5);
    final resized = Solar3dObstacleHeight.withHeight(old, 4);
    expect(Solar3dObstacleHeight.baseOf(resized), -1.5);
    final corrected = Solar3dObstacleHeight.withBase(old, 0);
    expect(corrected.center.y, 1.5);
    expect(Solar3dObstacleHeight.baseOf(corrected), 0);
  });
}
