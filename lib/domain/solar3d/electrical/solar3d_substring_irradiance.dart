import 'dart:math' as math;

import '../solar3d_geometric_shading.dart';
import '../solar_resource_hour.dart';
import 'solar3d_circuit_solver.dart';
import 'solar3d_single_diode.dart';

/// Physical mapping of an actual manufacturer-documented substring to
/// SAMPLE CELLS on the front face of a specific installed module.
/// No default three-diode/half-cut topology; inputs must be explicit.
class Solar3dSubstringFootprint {
  final String substringId;
  final List<int> sampleCells;
  final Solar3dDiodeCalibration calibration;
  final bool topologyVerified;
  final double? bypassDropV;

  const Solar3dSubstringFootprint({
    required this.substringId,
    required this.sampleCells,
    required this.calibration,
    this.topologyVerified = false,
    this.bypassDropV,
  });
}

class Solar3dPhysicalFaceMap {
  final String panelId;
  final int rows, columns;
  final List<Solar3dSubstringFootprint> substrings;

  const Solar3dPhysicalFaceMap({
    required this.panelId, required this.rows,
    required this.columns, required this.substrings,
  });

  void validate() {
    if (panelId.isEmpty || rows < 2 || rows > 24 ||
        columns < 2 || columns > 24 ||
        substrings.isEmpty || substrings.length > 12) {
      throw const FormatException('Mapa físico de substrings inválido');
    }
    final allCells = <int>{};
    final ids = <String>{};
    for (final part in substrings) {
      part.calibration.validate();
      if (part.substringId.isEmpty ||
          !ids.add(part.substringId) ||
          part.sampleCells.isEmpty ||
          part.sampleCells.toSet().length != part.sampleCells.length ||
          part.sampleCells.any((i) => i < 0 || i >= rows * columns) ||
          !allCells.addAllWithCheck(part.sampleCells)) {
        throw const FormatException('Células físicas repetidas/inválidas');
      }
      if (substrings.length > 1 &&
          (!part.topologyVerified || part.bypassDropV == null)) {
        throw const FormatException(
            'Divisão real das substrings e bypass não documentados');
      }
    }
    if (allCells.length != rows * columns) {
      throw const FormatException(
          'Todas as amostras ópticas devem ter substring conhecida');
    }
  }

  /// Convert the exact same HSP POA beam to electrical effective irradiance
  /// ONCE. Do not feed a monthly already-shaded HSP to this bridge.
  ///
  /// Ambient-to-cell temperature modelling is NOT silently assumed.
  /// Caller must supply a measured or traceably modelled Tcell per hour.
  Solar3dPhysicalModule fromHour({
    required Solar3dObject panel,
    required Solar3dScene scene,
    required SolarResourceHour hour,
    required double poaTiltDegrees,
    required double poaAzimuthDegrees,
    required double cellTemperatureC,
  }) {
    validate();
    if (panel.kind != Solar3dObjectKind.panel ||
        panel.id != panelId ||
        (panel.tiltDegrees - poaTiltDegrees).abs() > 1e-6 ||
        !cellTemperatureC.isFinite ||
        cellTemperatureC < -70 || cellTemperatureC > 130) {
      throw const FormatException(
          'Orientação, módulo ou temperatura de célula incompatível');
    }
    final diff = (panel.azimuthDegrees - poaAzimuthDegrees).abs() % 360;
    if (math.min(diff, 360 - diff) > 1e-6) {
      throw const FormatException(
          'POA de outra orientação não pode alimentar o módulo');
    }
    if (hour.poaDirectWm2 < 0 || hour.poaSkyDiffuseWm2 < 0 ||
        hour.poaGroundWm2 < 0) {
      throw const FormatException('POA horário negativo');
    }
    final grid = Solar3dGeometricShading.inspectPanelGrid(
      panel: panel, scene: scene,
      sunAzimuthDegrees: hour.solarAzimuthDegrees,
      sunElevationDegrees: hour.apparentSolarElevationDegrees,
      rows: rows, columns: columns,
    );
    if (grid == null && hour.poaDirectWm2 > 1e-4) {
      throw const FormatException(
          'Série de sol/POA incompatível com a face do módulo');
    }
    final components = <Solar3dPhysicalSubstring>[];
    for (final part in substrings) {
      final shade = grid?.blockedFractionFor(part.sampleCells) ?? 0.0;
      final effectiveG = math.max(0.0,
          hour.poaSkyDiffuseWm2 + hour.poaGroundWm2 +
          hour.poaDirectWm2 * (1 - shade));
      final state = part.calibration.at(effectiveG, cellTemperatureC);
      components.add(Solar3dPhysicalSubstring(
        id: part.substringId,
        diode: state,
        topologyVerified: part.topologyVerified,
        bypassDropV: part.bypassDropV,
      ));
    }
    return Solar3dPhysicalModule(
      panelId: panel.id, substrings: List.unmodifiable(components));
  }

  /// The single-substring case spreads the area fraction uniformly:
  /// it is a proxy, NOT a physically resolved cell/bypass calculation.
  bool get uniformPanelProxy => substrings.length == 1;
}

extension on Set<int> {
  bool addAllWithCheck(Iterable<int> values) {
    for (final value in values) {
      if (!add(value)) return false;
    }
    return true;
  }
}
