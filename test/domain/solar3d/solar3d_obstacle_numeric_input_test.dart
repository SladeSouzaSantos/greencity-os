import 'package:flutter_test/flutter_test.dart';
import 'package:greencity_os/domain/solar3d/solar3d_geometric_shading.dart';
import 'package:greencity_os/domain/solar3d/solar3d_obstacle_height.dart';
import 'package:greencity_os/domain/solar3d/solar3d_obstacle_numeric_input.dart';
import 'package:greencity_os/domain/solar3d/solar3d_scene_document.dart';

void main() {
  const obstacle = Solar3dObject(
    id: 'obstacle-4', kind: Solar3dObjectKind.obstacle,
    center: Solar3dVector(4, 1.5, 2),
    width: 2, depth: 2, height: 3,
  );

  Solar3dObject apply({
    String east = '4',
    String north = '2',
    String base = '0',
    String width = '2',
    String depth = '2',
    String height = '3',
    String azimuth = '0',
  }) => Solar3dObstacleNumericInput.apply(
    obstacle: obstacle, east: east, north: north, base: base,
    width: width, depth: depth, height: height, azimuth: azimuth,
  );

  test('accepts comma decimals and preserves base when height changes', () {
    final edited = apply(
      east: '-12,5', north: '15.25', base: '0',
      width: '5,75', depth: '7.2', height: '8,5',
      azimuth: '185,5',
    );
    expect(edited.id, obstacle.id);
    expect(edited.kind, obstacle.kind);
    expect(edited.center.x, -12.5);
    expect(edited.center.z, 15.25);
    expect(edited.center.y, 4.25);
    expect(Solar3dObstacleHeight.baseOf(edited), 0);
    expect(Solar3dObstacleHeight.topOf(edited), 8.5);
    expect(edited.width, 5.75);
    expect(edited.depth, 7.2);
    expect(edited.height, 8.5);
    expect(edited.azimuthDegrees, 185.5);
    expect(obstacle.height, 3); // immutable original
    final roundTrip = Solar3dSceneDocument.decode(
      Solar3dSceneDocument(
        scene: Solar3dScene([
          const Solar3dObject(
            id: 'p', kind: Solar3dObjectKind.panel,
            center: Solar3dVector(0, 1, 0),
            width: 1, depth: 2, height: .05, mpptIndex: 1,
          ),
          edited,
        ]),
      ).encode(),
    );
    expect(roundTrip.scene.objects.last.center.y, 4.25);
    expect(roundTrip.scene.objects.last.azimuthDegrees, 185.5);
  });

  test('raised base 2m and 6m height stores centre at 5m', () {
    final edited = apply(base: '2', height: '6');
    expect(edited.center.y, 5);
    expect(Solar3dObstacleHeight.baseOf(edited), 2);
    expect(Solar3dObstacleHeight.topOf(edited), 8);
  });

  test('rejects missing/nonfinite, negatives, out-of-range and bad centre', () {
    expect(() => apply(width: '0'), throwsFormatException);
    expect(() => apply(depth: '-1'), throwsFormatException);
    expect(() => apply(height: 'NaN'), throwsFormatException);
    expect(() => apply(base: '-1'), throwsFormatException);
    expect(() => apply(north: '501'), throwsFormatException);
    expect(() => apply(azimuth: '361'), throwsFormatException);
    expect(() => apply(base: '499', height: '4'),
        throwsFormatException);
    expect(() => apply(east: 'não é número'), throwsFormatException);
    expect(obstacle.width, 2); // no partial update
  });

  test('accepts azimuth 360 as equivalent to 0', () {
    final edited = apply(azimuth: '360');
    expect(edited.azimuthDegrees, 0);
  });
}
