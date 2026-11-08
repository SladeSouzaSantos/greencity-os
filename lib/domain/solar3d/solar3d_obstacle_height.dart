import 'solar3d_geometric_shading.dart';

/// The user's Y coordinate for a box-shaped obstacle is its BASE elevation.
/// The 3D ray tracer and the v1 JSON file still store the geometric CENTER.
/// This class is deliberately UI-facing: older stored scenes are not migrated.
class Solar3dObstacleHeight {
  static void _check(Solar3dObject o) {
    if (o.kind == Solar3dObjectKind.panel) {
      throw const FormatException('Altura da base aplica-se a obstáculos');
    }
  }

  static double baseOf(Solar3dObject o) {
    _check(o);
    return o.center.y - o.height / 2;
  }

  static double topOf(Solar3dObject o) {
    _check(o);
    return o.center.y + o.height / 2;
  }

  static double centerFromBase({
    required double baseMeters,
    required double heightMeters,
  }) {
    if (!baseMeters.isFinite || !heightMeters.isFinite ||
        baseMeters < 0 || baseMeters > 500 ||
        heightMeters <= 0 || heightMeters > 1000) {
      throw const FormatException(
          'Base deve ficar entre 0 e 500 m; altura deve ser positiva');
    }
    final center = baseMeters + heightMeters / 2;
    if (center > 500) {
      throw const FormatException('Centro do obstáculo excede 500 m');
    }
    return center;
  }

  /// Change the base without changing the obstacle height or X/Z.
  static Solar3dObject withBase(Solar3dObject o, double baseMeters) {
    _check(o);
    return o.copyWith(center: Solar3dVector(
      o.center.x,
      centerFromBase(baseMeters: baseMeters, heightMeters: o.height),
      o.center.z,
    ));
  }

  /// Change total height keeping the current base anchored.
  /// For legacy scenes with a negative base, preserve it rather than
  /// silently shifting the user's geometry.
  static Solar3dObject withHeight(Solar3dObject o, double heightMeters) {
    _check(o);
    if (!heightMeters.isFinite || heightMeters <= 0 ||
        heightMeters > 1000) {
      throw const FormatException('Altura total do obstáculo inválida');
    }
    final y = baseOf(o) + heightMeters / 2;
    if (!y.isFinite || y < -500 || y > 500) {
      throw const FormatException('Centro do obstáculo fora dos limites');
    }
    return o.copyWith(
      height: heightMeters,
      center: Solar3dVector(o.center.x, y, o.center.z),
    );
  }
}
