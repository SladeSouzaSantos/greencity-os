import 'dart:math' as math;

import '../entities/pv_module.dart';
import '../enums/module_orientation.dart';
import 'solar3d_geometric_shading.dart';

/// The public height is the VERTICAL clearance from ground to the lowest
/// physical edge of a tilted PV module (including the panel thickness).
///
/// SolarScenario.distanceToGround and the HSP API v2 field
/// distancia_centro_modulo_chao still refer to the module CENTRE.
/// Conversion occurs in the UI; do not change the API contract.
class Solar3dPanelHeight {
  static const double nominalThicknessMeters = .045;

  static double panelDepthMeters(
      PvModule module, ModuleOrientation orientation) {
    final raw = orientation == ModuleOrientation.portrait
        ? module.length : module.width;
    final meters = raw > 100 ? raw / 1000 : raw;
    if (!meters.isFinite || meters <= 0 || meters > 6) {
      throw const FormatException('Comprimento físico do módulo inválido');
    }
    return meters;
  }

  static double verticalHalfExtent({
    required double depthMeters,
    required double tiltDegrees,
    double thicknessMeters = nominalThicknessMeters,
  }) {
    if (![depthMeters, tiltDegrees, thicknessMeters]
            .every((v) => v.isFinite) ||
        depthMeters <= 0 || thicknessMeters <= 0 ||
        tiltDegrees < 0 || tiltDegrees > 90) {
      throw const FormatException('Geometria da placa inválida para altura');
    }
    final angle = tiltDegrees * math.pi / 180;
    return depthMeters / 2 * math.sin(angle) +
        thicknessMeters / 2 * math.cos(angle);
  }

  static double centerFromLowerEdge({
    required double lowerEdgeMeters,
    required double depthMeters,
    required double tiltDegrees,
    double thicknessMeters = nominalThicknessMeters,
  }) {
    if (!lowerEdgeMeters.isFinite || lowerEdgeMeters < 0 ||
        lowerEdgeMeters > 500) {
      throw const FormatException(
        'Altura vertical da borda inferior deve ficar entre 0 e 500 m');
    }
    final center = lowerEdgeMeters + verticalHalfExtent(
      depthMeters: depthMeters,
      tiltDegrees: tiltDegrees,
      thicknessMeters: thicknessMeters,
    );
    if (center > 500) {
      throw const FormatException(
        'Altura do centro resultante excede o limite de 500 m');
    }
    return center;
  }

  static double lowerEdgeOf(Solar3dObject panel) {
    if (panel.kind != Solar3dObjectKind.panel) {
      throw const FormatException(
        'A altura da borda inferior se aplica apenas a placas');
    }
    return panel.center.y - verticalHalfExtent(
      depthMeters: panel.depth,
      tiltDegrees: panel.tiltDegrees,
      thicknessMeters: panel.height,
    );
  }

  /// Preserves the lowest-edge clearance when tilt changes.
  static Solar3dObject withLowerEdge(
      Solar3dObject panel, double lowerEdgeMeters, {
      double? tiltDegrees,
  }) {
    if (panel.kind != Solar3dObjectKind.panel) {
      throw const FormatException('Objeto não é placa');
    }
    final tilt = tiltDegrees ?? panel.tiltDegrees;
    return panel.copyWith(
      tiltDegrees: tilt,
      center: Solar3dVector(
        panel.center.x,
        centerFromLowerEdge(
          lowerEdgeMeters: lowerEdgeMeters,
          depthMeters: panel.depth,
          tiltDegrees: tilt,
          thicknessMeters: panel.height,
        ),
        panel.center.z,
      ),
    );
  }
}
