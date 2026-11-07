import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../../../domain/solar3d/solar3d_geometric_shading.dart';

/// Cross-platform volumetric scene preview (Flutter CustomPainter).
/// 3D world: X east, Y up, Z north. No projected geometry enters physics.
class Solar3dProjection {
  final Size size;
  final Solar3dScene scene;
  final double yaw;
  final double pitch;
  final double zoom;

  late final Solar3dVector origin;
  late final double scale;

  Solar3dProjection({
    required this.size, required this.scene,
    required this.yaw, required this.pitch, required this.zoom,
  }) {
    final objects = scene.objects;
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
    final up = y * math.cos(pitch) - forward * math.sin(pitch);
    return Offset(size.width / 2 + right * scale,
        size.height / 2 - up * scale);
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
  final Set<String> hiddenIds;
  final Set<String> excludedIds;
  final String? selectedId;
  final double yaw, pitch, zoom;
  final Map<String, double?> directShadeByPanel;

  Solar3dScenePainter({
    required this.scene, required this.hiddenIds,
    required this.excludedIds, required this.selectedId,
    required this.yaw, required this.pitch, required this.zoom,
    required this.directShadeByPanel,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()..color = const Color(0xff10222d);
    canvas.drawRect(Offset.zero & size, bg);
    final view = Solar3dProjection(
      size: size, scene: scene, yaw: yaw, pitch: pitch, zoom: zoom);

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
      final selectedColor = excluded ? const Color(0xff64707a) : base;
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
        final label = isPanel ? 'MPPT ${object.mpptIndex}' : object.id;
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
      old.yaw != yaw || old.pitch != pitch || old.zoom != zoom ||
      old.directShadeByPanel != directShadeByPanel;
}
