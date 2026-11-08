import 'package:flutter_test/flutter_test.dart';
import 'package:greencity_os/domain/solar3d/solar3d_geometric_shading.dart';
import 'package:greencity_os/domain/solar3d/solar3d_bulk_move.dart';
import 'package:greencity_os/domain/solar3d/solar3d_panel_height.dart';
import 'package:greencity_os/domain/solar3d/solar3d_obstacle_height.dart';

void main() {
  const panelA = Solar3dObject(
    id: 'INV1/1/1', kind: Solar3dObjectKind.panel,
    center: Solar3dVector(0, 1.25, 2),
    width: 1.2, depth: 2.1, height: .045,
    tiltDegrees: 20, mpptIndex: 1, stringId: 'S1',
  );
  const panelB = Solar3dObject(
    id: 'INV2/1/1', kind: Solar3dObjectKind.panel,
    center: Solar3dVector(2, 2.25, 4),
    width: 1.2, depth: 2.1, height: .045,
    tiltDegrees: 20, mpptIndex: 2, stringId: 'S2',
  );
  const box = Solar3dObject(
    id: 'obstacle', kind: Solar3dObjectKind.obstacle,
    center: Solar3dVector(3, 2.5, 6),
    width: 2, depth: 3, height: 5,
  );
  final base = Solar3dScene([panelA, panelB, box]);

  test('arrasto do grupo preserva separações e todas conexões MPPT', () {
    final result = Solar3dBulkMove.apply(
      scene: base, selectedIds: {'INV1/1/1', 'INV2/1/1', 'obstacle'},
      east: 4.5, north: -3,
    );
    expect(result.objects.map((o) => o.center.x).toList(),
        [4.5, 6.5, 7.5]);
    expect(result.objects.map((o) => o.center.z).toList(),
        [-1, 1, 3]);
    expect(result.objects[0].center.y, panelA.center.y);
    expect(result.objects[1].center.y, panelB.center.y);
    expect(result.objects[2].center.y, box.center.y);
    expect(result.objects[0].stringId, 'S1');
    expect(result.objects[1].stringId, 'S2');
    expect(result.objects[0].mpptIndex, 1);
    expect(result.objects[1].mpptIndex, 2);
    expect(base.objects[0].center.x, 0);
    expect(base.objects[2].center.z, 6);
  });

  test('elevação relativa mantém os desníveis com placa inclinada', () {
    final result = Solar3dBulkMove.apply(
      scene: base, selectedIds: {'INV1/1/1', 'INV2/1/1', 'obstacle'},
      elevation: 1.5,
    );
    for (var index = 0; index < 2; index++) {
      expect(Solar3dPanelHeight.lowerEdgeOf(result.objects[index]),
          closeTo(Solar3dPanelHeight.lowerEdgeOf(base.objects[index])
              + 1.5, 1e-9));
    }
    expect(Solar3dObstacleHeight.baseOf(result.objects.last),
        closeTo(1.5, 1e-9));
  });

  test('altura comum ancora borda inferior ou base em 5.5 m', () {
    final result = Solar3dBulkMove.apply(
      scene: base, selectedIds: {'INV1/1/1', 'INV2/1/1', 'obstacle'},
      east: -1, commonHeight: 5.5,
    );
    expect(Solar3dPanelHeight.lowerEdgeOf(result.objects[0]),
        closeTo(5.5, 1e-9));
    expect(Solar3dPanelHeight.lowerEdgeOf(result.objects[1]),
        closeTo(5.5, 1e-9));
    expect(Solar3dObstacleHeight.baseOf(result.objects[2]),
        closeTo(5.5, 1e-9));
    expect(Solar3dObstacleHeight.topOf(result.objects[2]), 10.5);
    expect(result.objects[1].center.x, 1);
  });

  test('pode misturar tipos, escolher um só e deixar outros intocados', () {
    final result = Solar3dBulkMove.apply(
      scene: base, selectedIds: {'INV2/1/1', 'obstacle'},
      east: 1, north: 1,
    );
    expect(identical(result.objects.first, panelA), isTrue);
    expect(result.objects[1].center.x, 3);
    expect(result.objects[2].center.z, 7);
  });

  test('confirmar valores iguais não altera a cena nem sua identidade', () {
    final unchanged = Solar3dBulkMove.apply(
      scene: base,
      selectedIds: {'INV1/1/1', 'obstacle'},
    );
    expect(identical(unchanged, base), isTrue);
    final sameHeight = Solar3dBulkMove.apply(
      scene: base,
      selectedIds: {'obstacle'},
      commonHeight: 0,
    );
    expect(identical(sameHeight, base), isTrue);
  });

  test('movimento atômico recusa sair do solo ou dos limites X/Z', () {
    expect(() => Solar3dBulkMove.apply(
      scene: base, selectedIds: {'INV1/1/1', 'obstacle'},
      elevation: -1,
    ), throwsFormatException);
    expect(() => Solar3dBulkMove.apply(
      scene: base, selectedIds: {'INV1/1/1', 'obstacle'},
      east: 500,
    ), throwsFormatException);
    expect(() => Solar3dBulkMove.apply(
      scene: base, selectedIds: {'INV1/1/1', 'obstacle'},
      commonHeight: 500,
    ), throwsFormatException);
    expect(() => Solar3dBulkMove.apply(
      scene: base, selectedIds: {'missing'},
    ), throwsFormatException);
    expect(() => Solar3dBulkMove.apply(
      scene: base, selectedIds: {},
    ), throwsFormatException);
    expect(() => Solar3dBulkMove.apply(
      scene: base, selectedIds: {'INV1/1/1'},
      east: double.nan,
    ), throwsFormatException);
    expect(base.objects.last.center.y, 2.5);
  });
}
