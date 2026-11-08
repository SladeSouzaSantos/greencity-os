import 'solar3d_geometric_shading.dart';
import 'solar3d_panel_height.dart';
import 'solar3d_obstacle_height.dart';

/// A TRANSIENT selection of existing 3D objects. No group entity, JSON
/// migration, or inverter reassignment is required. Positions are updated
/// atomically: if a single selected object would leave the valid scene,
/// nothing is returned or saved.
class Solar3dBulkMove {
  static Solar3dScene apply({
    required Solar3dScene scene,
    required Set<String> selectedIds,
    double east = 0,
    double north = 0,
    double elevation = 0,
    double? commonHeight,
  }) {
    if (selectedIds.isEmpty) {
      throw const FormatException('Selecione ao menos um objeto');
    }
    if (![east, north, elevation].every((v) => v.isFinite) ||
        (commonHeight != null && !commonHeight.isFinite)) {
      throw const FormatException('Deslocamento numérico inválido');
    }
    if (commonHeight != null && elevation != 0) {
      throw const FormatException(
          'Escolha deslocamento vertical OU altura comum');
    }
    final ids = scene.objects.map((o) => o.id).toSet();
    if (!ids.containsAll(selectedIds)) {
      throw const FormatException('A seleção contém um objeto removido');
    }
    final transformed = [
      for (final object in scene.objects)
        if (selectedIds.contains(object.id))
          _move(object, east: east, north: north,
              elevation: elevation, commonHeight: commonHeight)
        else
          object,
    ];
    final unchanged = transformed.asMap().entries.every((entry) {
      final before = scene.objects[entry.key].center;
      final after = entry.value.center;
      return before.x == after.x &&
          before.y == after.y && before.z == after.z;
    });
    if (unchanged) return scene;
    final result = Solar3dScene(transformed);
    result.validate();
    return result;
  }

  static Solar3dObject _move(
    Solar3dObject object, {
    required double east,
    required double north,
    required double elevation,
    required double? commonHeight,
  }) {
    final x = object.center.x + east;
    final z = object.center.z + north;
    if (x.abs() > 500 || z.abs() > 500) {
      throw const FormatException(
          'Um objeto ultrapassaria o limite de ±500 m em X/Z');
    }
    final moved = object.copyWith(
      center: Solar3dVector(x, object.center.y, z),
    );
    if (object.kind == Solar3dObjectKind.panel) {
      final current = Solar3dPanelHeight.lowerEdgeOf(moved);
      final target = commonHeight ?? (current + elevation);
      return Solar3dPanelHeight.withLowerEdge(moved, target);
    }
    final current = Solar3dObstacleHeight.baseOf(moved);
    final target = commonHeight ?? (current + elevation);
    return Solar3dObstacleHeight.withBase(moved, target);
  }
}
