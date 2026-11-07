import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../../../domain/solar3d/solar3d_geometric_shading.dart';

/// Cross-platform volumetric scene preview (Flutter CustomPainter).
/// 3D world: X east, Y up, Z north. No projected geometry enters physics.
class Solar3dProjection {
  final Size size;
  final Solar3dScene scene;
  final Solar3dScene? frameScene;
  final double yaw;
  final double pitch;
  final double zoom;

  late final Solar3dVector origin;
  late final double scale;

  Solar3dProjection({
    required this.size, required this.scene, this.frameScene,
    required this.yaw, required this.pitch, required this.zoom,
  }) {
    // Keep the camera frame fixed while dragging objects; otherwise
    // the scene recenters on every frame and the item appears to resist.
    final objects = (frameScene ?? scene).objects;
    final minX = objects.map((o) => o.center.x - o.width / 2)
        .reduce(math.min);
    final maxX = objects.map((o) => o.center.x + o.width / 2)
        .reduce(math.max);
    final minZ = objects.map((o) => o.center.z - o.depth / 2)
        .reduce(math.min);
    final maxZ = objects.map((o) => o.center.z + o.depth / 2)
        .reduce(math.max);
    final minY = 0.0;
    final maxY = objects.map((o) => o.center.y + o.height / 2)
        .reduce(math.max);
    origin = Solar3dVector((minX + maxX) / 2,
        (minY + maxY) / 2, (minZ + maxZ) / 2);
    final radius = math.max(3.0,
        math.sqrt(math.pow(maxX - minX, 2) +
            math.pow(maxZ - minZ, 2) +
            math.pow(maxY - minY, 2)).toDouble());
    scale = zoom * math.min(size.width, size.height) / (radius * 1.8);
  }

  Offset project(Solar3dVector point) {
    final x = point.x - origin.x;
    final y = point.y - origin.y;
    final z = point.z - origin.z;
    final right = x * math.cos(yaw) + z * math.sin(yaw);
    final forward = -x * math.sin(yaw) + z * math.cos(yaw);
    // North projects upwards and East projects right at yaw=0.
    final up = y * math.cos(pitch) + forward * math.sin(pitch);
    return Offset(size.width / 2 + right * scale,
        size.height / 2 - up * scale);
  }

  /// Inverse of [project] restricted to a horizontal plane at [elevation].
  /// Screen dragging therefore moves East/North without changing height,
  /// regardless of camera rotation or tilt. The view must be held fixed
  /// for the duration of a gesture.
  Solar3dVector pointOnHorizontalPlane(Offset screen, double elevation) {
    if (math.sin(pitch).abs() < 1e-6) {
      throw StateError('Camera parallel to ground; cannot drag on plane');
    }
    final right = (screen.dx - size.width / 2) / scale;
    final up = (size.height / 2 - screen.dy) / scale;
    final forward = (up - (elevation - origin.y) * math.cos(pitch)) /
        math.sin(pitch);
    final east = right * math.cos(yaw) - forward * math.sin(yaw);
    final north = right * math.sin(yaw) + forward * math.cos(yaw);
    return Solar3dVector(origin.x + east, elevation, origin.z + north);
  }

  double depth(Solar3dVector point) {
    final x = point.x - origin.x;
    final y = point.y - origin.y;
    final z = point.z - origin.z;
    return (-x * math.sin(yaw) + z * math.cos(yaw)) * math.cos(pitch) +
        y * math.sin(pitch);
  }

  /// Consistent with the geometry raycast basis Ry(azimuth) Rx(tilt).
  Solar3dVector transform(Solar3dObject object, Solar3dVector point) {
    final a = object.azimuthDegrees * math.pi / 180;
    final b = (object.kind == Solar3dObjectKind.panel
        ? object.tiltDegrees : 0.0) * math.pi / 180;
    final ca = math.cos(a), sa = math.sin(a);
    final cb = math.cos(b), sb = math.sin(b);
    return object.center + Solar3dVector(
      ca*point.x + sa*sb*point.y + sa*cb*point.z,
      cb*point.y - sb*point.z,
      -sa*point.x + ca*sb*point.y + ca*cb*point.z,
    );
  }

  List<Offset> face(Solar3dObject object, double y) {
    final halfX = object.width / 2, halfZ = object.depth / 2;
    return [
      Solar3dVector(-halfX,y,-halfZ),
      Solar3dVector(halfX,y,-halfZ),
      Solar3dVector(halfX,y,halfZ),
      Solar3dVector(-halfX,y,halfZ),
    ].map((p) => project(transform(object,p))).toList();
  }
}

class Solar3dScenePainter extends CustomPainter {
  final Solar3dScene scene;
  final Solar3dScene? frameScene;
  final Set<String> hiddenIds;
  final Set<String> excludedIds;
  final String? selectedId;
  final double yaw, pitch, zoom;
  final double sunAzimuthDegrees, sunElevationDegrees;
  final Map<String, double?> directShadeByPanel;

  Solar3dScenePainter({
    required this.scene, this.frameScene, required this.hiddenIds,
    required this.excludedIds, required this.selectedId,
    required this.yaw, required this.pitch, required this.zoom,
    required this.sunAzimuthDegrees, required this.sunElevationDegrees,
    required this.directShadeByPanel,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final isDaylight = sunElevationDegrees > 0;
    final bg = Paint()..color = isDaylight
        ? const Color(0xff142a35) : const Color(0xff0b1724);
    canvas.drawRect(Offset.zero & size, bg);
    final view = Solar3dProjection(
      size: size, scene: scene, frameScene: frameScene,
      yaw: yaw, pitch: pitch, zoom: zoom);

    // Ground grid with real metre spacing; visual only.
    final grid = Paint()
      ..color = const Color(0xff28404b)
      ..strokeWidth = 0.7
      ..style = PaintingStyle.stroke;
    for (var n = -30; n <= 30; n += 2) {
      final a = view.project(Solar3dVector(n.toDouble(),0,-30));
      final b = view.project(Solar3dVector(n.toDouble(),0,30));
      final c = view.project(Solar3dVector(-30,0,n.toDouble()));
      final d = view.project(Solar3dVector(30,0,n.toDouble()));
      canvas.drawLine(a, b, grid);
      canvas.drawLine(c, d, grid);
    }

    // Ground shadows use the actual objects and geographic sun vector.
    // Hidden objects still cast shadows; excluded objects do not.
    _paintCastShadows(canvas, view);

    final visible = scene.objects.where((o) =>
        !hiddenIds.contains(o.id)).toList()
      ..sort((a,b) => view.depth(b.center).compareTo(view.depth(a.center)));
    for (final object in visible) {
      final selected = object.id == selectedId;
      final excluded = excludedIds.contains(object.id);
      final isPanel = object.kind == Solar3dObjectKind.panel;
      final index = object.mpptIndex ?? 0;
      final colors = [
        const Color(0xff21a0ba), const Color(0xffa880db),
        const Color(0xffd99554), const Color(0xff78bd71),
      ];
      final base = isPanel
          ? colors[(index > 0 ? index - 1 : 0) % colors.length]
          : const Color(0xff687989);
      final selectedColor = excluded ? const Color(0xff64707a)
          : isDaylight ? base : Color.lerp(base, Colors.black, .55)!;
      if (!isPanel) {
        final front = view.face(object, -object.height / 2);
        final top = view.face(object, object.height / 2);
        _fill(canvas, front, selectedColor.withValues(alpha: .65), selected);
        _fill(canvas, top, selectedColor.withValues(alpha: .85), selected);
        for (var i = 0; i < 4; i++) {
          canvas.drawLine(front[i], top[i], Paint()
            ..color=const Color(0xffd6e7eb).withValues(alpha:.4)
            ..strokeWidth=1);
        }
      } else {
        final face = view.face(object, object.height / 2);
        final shade = directShadeByPanel[object.id];
        final color = shade == null
            ? selectedColor
            : Color.lerp(selectedColor, const Color(0xff61485a), shade)!;
        _fill(canvas, face, color.withValues(alpha: excluded ? .3 : .95),
            selected);
        canvas.drawLine(face[0],face[2], Paint()
            ..color = const Color(0xffe4efff).withValues(alpha:.16)
            ..strokeWidth=0.5);
      }
      if (selected || isPanel) {
        final blocked = directShadeByPanel[object.id];
        final label = isPanel
            ? 'MPPT ${object.mpptIndex}${blocked != null && blocked > 0 ? " · ${(blocked * 100).round()}% sombra" : ""}'
            : object.id;
        final layout = TextPainter(
          text: TextSpan(text: label, style: TextStyle(
            fontSize: selected ? 12 : 9,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            color: selected ? Colors.white : const Color(0xffc9e5eb),
          )), textDirection: TextDirection.ltr,
        )..layout();
        final anchor = view.project(object.center);
        layout.paint(canvas, anchor.translate(-layout.width/2, -layout.height/2));
      }
    }
    final title = TextPainter(
      text: const TextSpan(text: 'CENA 3D · VISTA DE PROJETO (NÃO É FOTO)',
        style: TextStyle(fontSize: 11,color:Color(0xffa7c6d2))),
      textDirection: TextDirection.ltr,
    )..layout();
    title.paint(canvas, const Offset(10,10));
    final sunText = TextPainter(
      text: TextSpan(
        text: isDaylight ? 'SOMBRA DIRETA · ESTIMATIVA GEOMÉTRICA'
            : 'NOITE · SEM IRRADIÂNCIA SOLAR DIRETA',
        style: const TextStyle(fontSize: 10, color: Color(0xffbfccda)),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    sunText.paint(canvas, const Offset(10,28));
    _paintCompass(canvas, size, view);
  }

  /// Project opaque 3D boxes/panels onto the real ground plane (Y=0).
  /// These footprints are visual approximations of direct-beam shadows:
  /// partial shade ON a panel is evaluated separately by ray casting.
  void _paintCastShadows(Canvas canvas, Solar3dProjection view) {
    if (sunElevationDegrees <= 1) return;
    final shadowPaint = Paint()
      ..color = const Color(0xff02070b).withValues(alpha: .65)
      ..style = PaintingStyle.fill;
    for (final object in scene.objects) {
      if (excludedIds.contains(object.id)) continue;
      final hull = groundShadowFootprint(
        object: object,
        view: view,
        sunAzimuthDegrees: sunAzimuthDegrees,
        sunElevationDegrees: sunElevationDegrees,
      );
      if (hull.length < 3) continue;
      final points = hull.map((p) => view.project(
        Solar3dVector(p.dx, 0, p.dy))).toList();
      canvas.drawPath(Path()..addPolygon(points, true), shadowPaint);
    }
  }

  /// Returns a convex ground footprint in metric X/Z coordinates, independent
  /// of canvas/rasterization. This is deliberately testable without a GPU.
  static List<Offset> groundShadowFootprint({
    required Solar3dObject object,
    required Solar3dProjection view,
    required double sunAzimuthDegrees,
    required double sunElevationDegrees,
  }) {
    if (sunElevationDegrees <= 1) return const [];
    final azi = sunAzimuthDegrees * math.pi / 180;
    final ele = sunElevationDegrees * math.pi / 180;
    final sunEast = math.sin(azi) * math.cos(ele);
    final sunNorth = math.cos(azi) * math.cos(ele);
    final sunUp = math.sin(ele);
    final ground = <Offset>[];
    for (final dx in [-1.0, 1.0]) {
      for (final dy in [-1.0, 1.0]) {
        for (final dz in [-1.0, 1.0]) {
          final world = view.transform(object, Solar3dVector(
            dx * object.width / 2,
            dy * object.height / 2,
            dz * object.depth / 2,
          ));
          final distance = (math.max(0, world.y) / sunUp).clamp(0, 120);
          ground.add(Offset(world.x, world.z));
          ground.add(Offset(
            world.x - sunEast * distance,
            world.z - sunNorth * distance,
          ));
        }
      }
    }
    return _convexHull(ground);
  }

  /// Convex hull in the terrain X/Z coordinates. Sorting is deterministic
  /// so that the polygons do not self-intersect under camera rotation.
  static List<Offset> _convexHull(List<Offset> points) {
    if (points.length < 3) return points;
    final sorted = [...points]..sort((a,b) {
      final first = a.dx.compareTo(b.dx);
      return first != 0 ? first : a.dy.compareTo(b.dy);
    });
    double cross(Offset a, Offset b, Offset c) =>
        (b.dx - a.dx) * (c.dy - a.dy) -
        (b.dy - a.dy) * (c.dx - a.dx);
    final lower = <Offset>[];
    for (final p in sorted) {
      while (lower.length >= 2 &&
          cross(lower[lower.length - 2], lower.last, p) <= 0) {
        lower.removeLast();
      }
      lower.add(p);
    }
    final upper = <Offset>[];
    for (final p in sorted.reversed) {
      while (upper.length >= 2 &&
          cross(upper[upper.length - 2], upper.last, p) <= 0) {
        upper.removeLast();
      }
      upper.add(p);
    }
    return [...lower.take(lower.length - 1),
        ...upper.take(upper.length - 1)];
  }

  void _paintCompass(Canvas canvas, Size size, Solar3dProjection view) {
    // Geographic headings are projected using the SAME camera transform
    // as the panels. This is a true world-locked compass, not screen North.
    const radius = 43.0;
    final c = Offset(math.max(radius + 8, size.width - radius - 12),
        radius + 16);
    canvas.drawCircle(c, radius + 7, Paint()
      ..color = const Color(0xff10222d).withValues(alpha: .92));
    canvas.drawCircle(c, radius, Paint()
      ..color = const Color(0xff93b0c4)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke);
    final pivot = view.project(view.origin);
    final headings = <(String, Solar3dVector, Color)>[
      ('N', const Solar3dVector(0, 0, 1), const Color(0xffffaa68)),
      ('S', const Solar3dVector(0, 0, -1), const Color(0xffbfced7)),
      ('L', const Solar3dVector(1, 0, 0), const Color(0xffbfced7)),
      ('O', const Solar3dVector(-1, 0, 0), const Color(0xffbfced7)),
    ];
    for (final entry in headings) {
      final point = view.project(view.origin + entry.$2);
      final offset = point - pivot;
      if (offset.distance < .001) continue;
      final direction = offset / offset.distance;
      final tip = c + direction * 28;
      canvas.drawLine(c, c + direction * 19, Paint()
        ..color = entry.$3
        ..strokeWidth = entry.$1 == 'N' ? 2.7 : 1.4);
      final label = TextPainter(
        text: TextSpan(text: entry.$1, style: TextStyle(
          fontSize: 12, fontWeight: FontWeight.bold, color: entry.$3)),
        textDirection: TextDirection.ltr,
      )..layout();
      label.paint(canvas,
        tip.translate(-label.width / 2, -label.height / 2));
    }
    canvas.drawCircle(c, 3, Paint()..color = const Color(0xffffffff));
  }

  void _fill(Canvas canvas, List<Offset> corners, Color color, bool selected) {
    final path = Path()..moveTo(corners.first.dx,corners.first.dy);
    for (var i=1;i<corners.length;i++) {
      path.lineTo(corners[i].dx,corners[i].dy);
    }
    path.close();
    canvas.drawPath(path, Paint()..color=color);
    canvas.drawPath(path, Paint()..style=PaintingStyle.stroke
      ..strokeWidth=selected?2.8:1
      ..color=selected?const Color(0xffffd083):const Color(0xffb2d2db));
  }

  @override
  bool shouldRepaint(covariant Solar3dScenePainter old) =>
      old.scene != scene || old.hiddenIds != hiddenIds ||
      old.excludedIds != excludedIds || old.selectedId != selectedId ||
      old.frameScene != frameScene ||
      old.yaw != yaw || old.pitch != pitch || old.zoom != zoom ||
      old.directShadeByPanel != directShadeByPanel ||
      old.sunAzimuthDegrees != sunAzimuthDegrees ||
      old.sunElevationDegrees != sunElevationDegrees;
}
