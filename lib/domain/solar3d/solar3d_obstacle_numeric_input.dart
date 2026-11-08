import 'solar3d_geometric_shading.dart';
import 'solar3d_obstacle_height.dart';

/// Converts manually typed obstacle dimensions/placement into the SAME
/// center-based Solar3dObject used by JSON v1 and the geometric ray tracer.
/// All fields are validated as one atomic edit: partial values never leak.
class Solar3dObstacleNumericInput {
  static double parseNumber(
    String source,
    String name, {
    required double min,
    required double max,
    bool strictlyPositive = false,
  }) {
    final number = double.tryParse(source.trim().replaceAll(',', '.'));
    if (number == null || !number.isFinite ||
        number < min || number > max ||
        (strictlyPositive && number <= 0)) {
      throw FormatException(
          '$name: informe um número entre $min e $max');
    }
    return number;
  }

  static Solar3dObject apply({
    required Solar3dObject obstacle,
    required String east,
    required String north,
    required String base,
    required String width,
    required String depth,
    required String height,
    required String azimuth,
  }) {
    if (obstacle.kind == Solar3dObjectKind.panel) {
      throw const FormatException(
          'Esse formulário destina-se a obstáculos e construções');
    }
    final x = parseNumber(east, 'Coordenada X',
        min: -500, max: 500);
    final z = parseNumber(north, 'Coordenada Z',
        min: -500, max: 500);
    final yBase = parseNumber(base, 'Altura da base',
        min: 0, max: 500);
    final w = parseNumber(width, 'Largura',
        min: 0, max: 1000, strictlyPositive: true);
    final d = parseNumber(depth, 'Profundidade',
        min: 0, max: 1000, strictlyPositive: true);
    final h = parseNumber(height, 'Altura total',
        min: 0, max: 1000, strictlyPositive: true);
    final az = parseNumber(azimuth, 'Azimute',
        min: 0, max: 360);

    // Use the NEW height first, then compute the center from the chosen
    // BASE. This preserves a grounded obstacle when its height changes.
    final resized = obstacle.copyWith(
      center: Solar3dVector(x, obstacle.center.y, z),
      width: w, depth: d, height: h,
      azimuthDegrees: az == 360 ? 0 : az,
    );
    final result = Solar3dObstacleHeight.withBase(resized, yBase);
    result.validate();
    return result;
  }
}
