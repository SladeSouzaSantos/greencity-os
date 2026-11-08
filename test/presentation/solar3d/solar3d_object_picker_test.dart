import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greencity_os/domain/solar3d/solar3d_geometric_shading.dart';
import 'package:greencity_os/presentation/widgets/photovoltaic/solar3d_object_picker.dart';
import 'package:greencity_os/presentation/widgets/photovoltaic/solar3d_scene_painter.dart';

void main() {
  const obstacle = Solar3dObject(
    id: 'box', kind: Solar3dObjectKind.obstacle,
    center: Solar3dVector(0, 2, 0),
    width: 2, depth: 3, height: 4,
  );
  const panel = Solar3dObject(
    id: 'panel', kind: Solar3dObjectKind.panel,
    center: Solar3dVector(5, 1, 1),
    width: 1.2, depth: 2.1, height: .04,
  );
  final scene = Solar3dScene([obstacle, panel]);

  test('obstacle can be selected from a side, not just its top face', () {
    final view = Solar3dProjection(
      scene: scene, size: const Size(600, 400),
      yaw: .65, pitch: .65, zoom: 1.4,
    );
    final top = view.face(obstacle, obstacle.height / 2);
    final bottom = view.face(obstacle, -obstacle.height / 2);
    final sideMid = (top[0] + top[1] + bottom[0] + bottom[1]) / 4;
    expect(Solar3dObjectPicker.pick(
      at: sideMid, view: view, scene: scene,
    )?.id, 'box');
  });

  test('small panel accepts an 18 px tap tolerance outside its face', () {
    final view = Solar3dProjection(
      scene: scene, size: const Size(600, 400),
      yaw: 0, pitch: 1.1, zoom: .65,
    );
    final face = view.face(panel, panel.height / 2);
    final center = face.reduce((a, b) => a + b) / 4;
    expect(Solar3dObjectPicker.pick(
      at: center, view: view, scene: scene,
    )?.id, 'panel');
    expect(Solar3dObjectPicker.pick(
      at: center + const Offset(9, 0), view: view, scene: scene,
    )?.id, 'panel');
    expect(Solar3dObjectPicker.pick(
      at: const Offset(20, 370), view: view, scene: scene,
    ), isNull);
  });

  test('Top view picks panel ABOVE 5m obstacle and obstacle ABOVE panel', () {
    const wall = Solar3dObject(
      id: 'wall', kind: Solar3dObjectKind.obstacle,
      center: Solar3dVector(0, 2.5, 0),
      width: 3, depth: 3, height: 5,
    );
    const higher = Solar3dObject(
      id: 'panel-above', kind: Solar3dObjectKind.panel,
      center: Solar3dVector(0, 5.525, 0),
      width: 1.2, depth: 2.1, height: .05, mpptIndex: 1,
    );
    final aboveScene = Solar3dScene([higher, wall]);
    final aboveView = Solar3dProjection(
      scene: aboveScene, size: const Size(600, 400),
      yaw: 0, pitch: math.pi / 2, zoom: 1,
    );
    expect(Solar3dObjectPicker.pick(
      at: aboveView.project(higher.center),
      view: aboveView, scene: aboveScene,
    )?.id, 'panel-above');

    final lower = higher.copyWith(
        center: const Solar3dVector(0, 4.525, 0));
    final belowScene = Solar3dScene([wall, lower]);
    final belowView = Solar3dProjection(
      scene: belowScene, size: const Size(600, 400),
      yaw: 0, pitch: math.pi / 2, zoom: 1,
    );
    expect(Solar3dObjectPicker.pick(
      at: belowView.project(lower.center),
      view: belowView, scene: belowScene,
    )?.id, 'wall');
  });

  test('hidden objects are not touch targets', () {
    final view = Solar3dProjection(
      scene: scene, size: const Size(600, 400),
      yaw: 0, pitch: 1.0, zoom: 1,
    );
    final at = view.project(obstacle.center);
    expect(Solar3dObjectPicker.pick(
      at: at, view: view, scene: scene, hiddenIds: {'box'},
    )?.id, isNot('box'));
  });
}
