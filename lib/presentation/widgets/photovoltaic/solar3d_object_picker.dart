import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../domain/solar3d/solar3d_geometric_shading.dart';
import 'solar3d_scene_painter.dart';

/// Pick the same 3D faces which are rendered, not just the object's top.
///
/// Mobile touches have a small tolerance around projected silhouettes.
/// Exact overlaps prefer objects drawn later (nearest to the camera).
class Solar3dObjectPicker {
  static List<List<Offset>> _faces(
      Solar3dObject object, Solar3dProjection view) {
    final top = view.face(object, object.height / 2);
    if (object.kind == Solar3dObjectKind.panel) return [top];
    final bottom = view.face(object, -object.height / 2);
    return [
      top, bottom,
      for (var i = 0; i < 4; i++)
        [bottom[i], bottom[(i + 1) % 4],
         top[(i + 1) % 4], top[i]],
    ];
  }

  static double _distanceToSegment(Offset point, Offset a, Offset b) {
    final edge = b - a;
    final norm = edge.dx * edge.dx + edge.dy * edge.dy;
    if (norm < 1e-9) return (point - a).distance;
    final delta = point - a;
    final t = ((delta.dx * edge.dx + delta.dy * edge.dy) / norm)
        .clamp(0.0, 1.0);
    return (point - (a + edge * t)).distance;
  }

  static double _distanceToPolygon(Offset at, List<Offset> polygon) {
    final path = Path()..addPolygon(polygon, true);
    if (path.contains(at)) return 0;
    var shortest = double.infinity;
    for (var i = 0; i < polygon.length; i++) {
      shortest = math.min(shortest, _distanceToSegment(
        at, polygon[i], polygon[(i + 1) % polygon.length]));
    }
    return shortest;
  }

  static Solar3dObject? pick({
    required Offset at,
    required Solar3dProjection view,
    required Solar3dScene scene,
    Set<String> hiddenIds = const {},
    double touchSlop = 18,
  }) {
    final visible = scene.objects
        .where((o) => !hiddenIds.contains(o.id)).toList()
      // Painter draws far-to-near (descending depth); inspect in
      // reverse so an overlapping foreground face wins.
      ..sort((a, b) => view.depth(a.center).compareTo(view.depth(b.center)));
    for (final object in visible) {
      if (_faces(object, view).any((face) =>
          _distanceToPolygon(at, face) <= 1e-6)) {
        return object;
      }
    }
    Solar3dObject? nearest;
    var shortest = touchSlop;
    for (final object in visible) {
      final proximity = _faces(object, view)
          .map((face) => _distanceToPolygon(at, face))
          .reduce(math.min);
      if (proximity < shortest) {
        shortest = proximity;
        nearest = object;
      }
    }
    return nearest;
  }
}
