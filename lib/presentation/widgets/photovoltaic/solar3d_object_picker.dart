import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../domain/solar3d/solar3d_geometric_shading.dart';
import 'solar3d_scene_painter.dart';

/// Pick the same 3D faces which are rendered, not just the object's top.
///
/// Mobile touches have a small tolerance around projected silhouettes.
/// Exact overlaps prefer objects drawn later (nearest to the camera).
class Solar3dObjectPicker {
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
    // Exact selection uses depth interpolated at the finger location
    // on each face. A raised panel is picked over an obstacle top if
    // its projected face is actually in front from this camera angle.
    final faces = view.facesFarToNear(
      scene.objects.where((o) => !hiddenIds.contains(o.id)),
    );
    Solar3dObject? exact;
    var nearestDepth = -double.infinity;
    for (final surface in faces) {
      final candidateDepth = surface.depthAt(at);
      if (candidateDepth != null && candidateDepth > nearestDepth) {
        exact = surface.object;
        nearestDepth = candidateDepth;
      }
    }
    if (exact != null) return exact;
    // Finger tolerance is applied ONLY after exact-hit testing. Prefer
    // closest visible silhouette, with camera depth breaking ties.
    Solar3dObject? nearest;
    var shortest = touchSlop;
    nearestDepth = -double.infinity;
    for (final surface in faces) {
      final proximity = _distanceToPolygon(at, surface.corners);
      if (proximity < shortest - .01 ||
          ((proximity - shortest).abs() <= .01 &&
            surface.averageDepth > nearestDepth)) {
        shortest = proximity;
        nearestDepth = surface.averageDepth;
        nearest = surface.object;
      }
    }
    return nearest;
  }
}
