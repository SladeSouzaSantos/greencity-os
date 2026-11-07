import 'package:flutter_test/flutter_test.dart';
import 'package:greencity_os/domain/solar3d/solar3d_scene_document.dart';
import 'package:greencity_os/domain/solar3d/solar3d_geometric_shading.dart';

void main() {
  const base = Solar3dObject(
    id: 'sys/1/1', kind: Solar3dObjectKind.panel,
    center: Solar3dVector(1, 1, 2), width: 1,
    depth: 2, height: .05, mpptIndex: 1, moduleModel: 'A/B',
  );

  test('JSON roundtrip preserves geometry and exclusion independent of hiding', () {
    final document = Solar3dSceneDocument(
      scene: const Solar3dScene([base]),
      hiddenIds: {'sys/1/1'},
    );
    final restored = Solar3dSceneDocument.decode(document.encode());
    expect(restored.scene.objects.single.center.z, 2);
    expect(restored.hiddenIds, {'sys/1/1'});
    expect(restored.excludedIds, isEmpty);
    expect(restored.scene.objects.single.mpptIndex, 1);
  });

  test('Reconciles saved scene without resurrecting removed Isar panels', () {
    final saved = Solar3dSceneDocument(scene: Solar3dScene([
      base.copyWith(center: const Solar3dVector(7, 1, 8), mpptIndex: 2),
      const Solar3dObject(
        id: 'old-panel', kind: Solar3dObjectKind.panel,
        center: Solar3dVector(0, 1, 1), width: 1, depth: 2,
        height: .05, mpptIndex: 1, moduleModel: 'A/B',
      ),
      const Solar3dObject(
        id: 'chimney', kind: Solar3dObjectKind.obstacle,
        center: Solar3dVector(1, 2, 2), width: 1, depth: 1, height: 2,
      ),
    ]));
    final result = saved.reconciledWith(const Solar3dScene([base]));
    expect(result.scene.objects.length, 2);
    expect(result.scene.objects.first.center.x, 7);
    expect(result.scene.objects.first.mpptIndex, 2);
    expect(result.scene.objects.last.id, 'chimney');
  });

  test('Rejects corrupted coordinates and unknown scene format', () {
    expect(() => Solar3dSceneDocument.decode('{"schema_version":9}'), throwsFormatException);
    final doc = Solar3dSceneDocument(scene: const Solar3dScene([base]));
    final altered = doc.encode().replaceFirst('"width":1.0', '"width":-1.0');
    expect(() => Solar3dSceneDocument.decode(altered), throwsFormatException);
  });
}
