import '../entities/solar_system.dart';
import '../enums/module_orientation.dart';
import 'solar3d_geometric_shading.dart';

/// Provisional geometry for individual physical panels from existing Isar
/// entities. This is NOT a measured installation layout or string design.
class Solar3dPlanFactory {
  static Solar3dScene fromSystems(List<SolarSystem> systems) {
    final objects = <Solar3dObject>[];
    var offsetEast = 0.0;
    for (final system in systems) {
      if (system.inverter.mpptCount < 1) {
        throw const FormatException('Inversor sem MPPT');
      }
      for (var arrayIndex = 0; arrayIndex < system.arrays.length; arrayIndex++) {
        final array = system.arrays[arrayIndex];
        final scenario = array.solarScenario;
        if (array.mpptIndex < 1 ||
            array.mpptIndex > system.inverter.mpptCount) {
          throw FormatException(
            'MPPT inválido no arranjo: ${scenario.id}');
        }
        final count = scenario.quantityPvModule;
        if (count < 1 || objects.length + count > 100) {
          throw const FormatException(
            'Máximo de 100 placas nesta cena de pesquisa');
        }
        // Current PvModule seeds use millimetres. Legacy imported values
        // may already be metres; the conversion remains explicit.
        final length = scenario.module.length > 100
            ? scenario.module.length / 1000 : scenario.module.length;
        final width = scenario.module.width > 100
            ? scenario.module.width / 1000 : scenario.module.width;
        final portrait = scenario.orientation == ModuleOrientation.portrait;
        final panelWidth = portrait ? width : length;
        final panelDepth = portrait ? length : width;
        if (!panelWidth.isFinite || !panelDepth.isFinite ||
            panelWidth <= 0 || panelDepth <= 0 ||
            panelWidth > 6 || panelDepth > 6) {
          throw FormatException(
            'Dimensões inválidas para ${scenario.module.modelName}');
        }
        // The app asks for the distance from the CENTER of the module
        // to the ground. Never silently raise the module to clear its edge.
        // A ground collision is a warning in the editor, not a geometry
        // override. Preserve this physical input in the 3D scene.
        final elevation = scenario.distanceToGround;
        if (!elevation.isFinite || elevation < 0 || elevation > 500) {
          throw FormatException(
            'Altura do centro do módulo inválida: ${scenario.id}');
        }
        for (var index = 0; index < count; index++) {
          final col = index % 5;
          final row = index ~/ 5;
          objects.add(Solar3dObject(
            id: '${system.id}/${arrayIndex + 1}/${index + 1}',
            kind: Solar3dObjectKind.panel,
            center: Solar3dVector(
              offsetEast + col * (panelWidth + 0.05),
              elevation,
              row * (panelDepth + 0.05),
            ),
            width: panelWidth,
            depth: panelDepth,
            height: 0.045,
            azimuthDegrees: scenario.azimuth % 360,
            tiltDegrees: scenario.inclination,
            moduleModel: '${scenario.module.manufacturer} / ${scenario.module.modelName}',
            mpptIndex: array.mpptIndex,
            // SolarArray has no string identity yet. Never invent it.
            stringId: null,
          ));
        }
        offsetEast += 5 * (panelWidth + 0.05) + 1.5;
      }
    }
    final scene = Solar3dScene(objects);
    scene.validate();
    return scene;
  }
}
