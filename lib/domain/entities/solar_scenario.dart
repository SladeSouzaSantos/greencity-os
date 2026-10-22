import '../enums/module_orientation.dart';
import 'obstacle_config.dart';
import 'pv_module.dart';

class SolarScenario {
  final String id;
  final String city;
  final String state;
  final double inclination;
  final double azimuth;
  final double albedo;
  final double distanceToGround;
  final PvModule module;
  final int quantityPvModule;
  final ModuleOrientation orientation;
  final ObstacleConfig? obstacle;

  SolarScenario({
    required this.id,
    required this.city,
    required this.state,
    required this.inclination,
    required this.azimuth,
    this.quantityPvModule = 1,
    this.albedo = 0.2,
    this.distanceToGround = 0.015,
    required this.module,
    this.orientation = ModuleOrientation.portrait,
    this.obstacle,
  });

  @override
  String toString() {
    return 'SolarScenario(\n'
        '  id: $id,\n'
        '  state: $state,\n'
        '  city: $city,\n'
        '  inclination: $inclination°,\n'
        '  azimuth: $azimuth°,\n'
        '  albedo: $albedo,\n'
        '  distanceToGround: ${distanceToGround}m,\n'
        '  orientation: ${orientation.name},\n'
        '  module: ${module.toString()},\n'
        '  quantidade: $quantityPvModule,\n'
        '  obstacle: ${obstacle?.toString() ?? "Nenhum"}\n'
        ')';
  }
}