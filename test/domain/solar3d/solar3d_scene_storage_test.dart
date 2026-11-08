import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:greencity_os/data/datasources/solar3d_scene_storage.dart';
import 'package:greencity_os/domain/solar3d/solar3d_geometric_shading.dart';
import 'package:greencity_os/domain/solar3d/solar3d_scene_document.dart';

void main() {
  const doc = Solar3dSceneDocument(
    scene: Solar3dScene([
      Solar3dObject(
        id: 'inverter1/1/1', kind: Solar3dObjectKind.panel,
        center: Solar3dVector(0, 1, 0),
        width: 1, depth: 2, height: .04, mpptIndex: 1,
        stringId: 'S1', moduleModel: 'TEST-500',
      ),
    ]),
  );

  test('Salvar, abrir e resetar cena afeta somente projeto escolhido',
      () async {
    final dir = await Directory.systemTemp.createTemp('greencity-solar3d-');
    addTearDown(() async {
      if (await dir.exists()) await dir.delete(recursive: true);
    });
    final first = Solar3dSceneStorage('project-a', rootDirectory: dir);
    final second = Solar3dSceneStorage('project-b', rootDirectory: dir);
    expect(await first.load(), isNull);
    expect(await second.load(), isNull);
    await first.save(doc);
    await second.save(doc);
    final restored = await first.load();
    expect(restored, isNotNull);
    expect(restored!.scene.objects.single.stringId, 'S1');
    expect(restored.scene.objects.single.mpptIndex, 1);
    await first.clear();
    expect(await first.load(), isNull);
    expect(await second.load(), isNotNull);
    // Repeated resets must be idempotent.
    await first.clear();
    expect(await second.load(), isNotNull);
  });

  test('Cenas com conteúdo diferente não sobrescrevem outra chave', () async {
    final dir = await Directory.systemTemp.createTemp('greencity-solar3d-');
    addTearDown(() async {
      if (await dir.exists()) await dir.delete(recursive: true);
    });
    final first = Solar3dSceneStorage('inverter-one', rootDirectory: dir);
    final second = Solar3dSceneStorage('inverter-two', rootDirectory: dir);
    await first.save(doc);
    const edited = Solar3dSceneDocument(scene: Solar3dScene([
      Solar3dObject(
        id: 'inverter1/1/1', kind: Solar3dObjectKind.panel,
        center: Solar3dVector(10, 1, -2),
        width: 1, depth: 2, height: .04, mpptIndex: 2,
        stringId: 'S2', moduleModel: 'TEST-500',
      ),
    ]));
    await second.save(edited);
    expect((await first.load())!.scene.objects.single.center.x, 0);
    expect((await first.load())!.scene.objects.single.mpptIndex, 1);
    expect((await second.load())!.scene.objects.single.center.x, 10);
    expect((await second.load())!.scene.objects.single.mpptIndex, 2);
  });
}
