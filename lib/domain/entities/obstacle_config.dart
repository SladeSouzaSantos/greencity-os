class ObstacleConfig {
  final double height;
  final double distance;
  final double azimuthReference;
  final double width;

  ObstacleConfig({
    required this.height,
    required this.distance,
    required this.azimuthReference,
    required this.width,
  });

  @override
  String toString() {
    return 'Obstacle(H: ${height}m, D: ${distance}m, Az: $azimuthReference°, W: ${width}m)';
  }
}