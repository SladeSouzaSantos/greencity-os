import 'dart:math' as math;

/// Approximate NOAA solar ephemeris for the geographic coordinates of the
/// CURRENT SolarProject. No user-editable manual sun azimuth/elevation.
/// UTC is required: callers must convert civil time using the project's
/// declared UTC offset, NOT the operating system/device timezone.
///
/// This computes *geometric* solar elevation (without horizon/refraction).
/// Sufficient for visual preview; hourly POA/yield must still use HSP
/// Simulator's pvlib-backed meteorological series.
class Solar3dSunPosition {
  final double azimuthDegrees;
  final double elevationDegrees;

  const Solar3dSunPosition({
    required this.azimuthDegrees,
    required this.elevationDegrees,
  });

  bool get aboveHorizon => elevationDegrees > 0;

  static double _radians(double value) => value * math.pi / 180;
  static double _degrees(double value) => value * 180 / math.pi;
  static double _sin(double value) => math.sin(_radians(value));
  static double _cos(double value) => math.cos(_radians(value));
  static double _normalize(double value) => (value % 360 + 360) % 360;

  static Solar3dSunPosition calculate({
    required DateTime utc,
    required double latitude,
    required double longitude,
  }) {
    if (!latitude.isFinite || !longitude.isFinite ||
        latitude.abs() > 90 || longitude.abs() > 180) {
      throw const FormatException('Coordenadas geográficas inválidas');
    }
    final instant = utc.toUtc();
    final julianDay = instant.microsecondsSinceEpoch / 86400000000 +
        2440587.5;
    final t = (julianDay - 2451545) / 36525;
    final meanLongitude = _normalize(280.46646 +
        t * (36000.76983 + t * 0.0003032));
    final meanAnomaly = 357.52911 +
        t * (35999.05029 - 0.0001537 * t);
    final eccentricity = 0.016708634 -
        t * (0.000042037 + 0.0000001267 * t);
    final center = _sin(meanAnomaly) *
            (1.914602 - t * (0.004817 + 0.000014 * t)) +
        _sin(2 * meanAnomaly) * (0.019993 - 0.000101 * t) +
        _sin(3 * meanAnomaly) * 0.000289;
    final trueLongitude = meanLongitude + center;
    final omega = 125.04 - 1934.136 * t;
    final apparentLongitude = trueLongitude - 0.00569 -
        0.00478 * _sin(omega);
    final obliquity0 = 23 +
        (26 +
            (21.448 - t * (46.815 + t * (0.00059 - t * 0.001813))) /
                60) / 60;
    final obliquity = obliquity0 + 0.00256 * _cos(omega);
    final declination = math.asin(
        _sin(obliquity) * _sin(apparentLongitude));
    final yy = math.pow(math.tan(_radians(obliquity / 2)), 2).toDouble();
    final equationMinutes = 4 * _degrees(
      yy * _sin(2 * meanLongitude) -
      2 * eccentricity * _sin(meanAnomaly) +
      4 * eccentricity * yy * _sin(meanAnomaly) *
          _cos(2 * meanLongitude) -
      0.5 * yy * yy * _sin(4 * meanLongitude) -
      1.25 * eccentricity * eccentricity * _sin(2 * meanAnomaly),
    );
    final minutesUtc = instant.hour * 60 +
        instant.minute + instant.second / 60 +
        instant.millisecond / 60000;
    final solarMinutes = (minutesUtc + equationMinutes +
        4 * longitude) % 1440;
    final hourAngle = _radians(solarMinutes / 4 - 180);
    final lat = _radians(latitude);
    final cosZenith = (math.sin(lat) * math.sin(declination) +
        math.cos(lat) * math.cos(declination) *
            math.cos(hourAngle)).clamp(-1.0, 1.0);
    final zenith = math.acos(cosZenith);
    final azimuth = _normalize(_degrees(math.atan2(
      math.sin(hourAngle),
      math.cos(hourAngle) * math.sin(lat) -
          math.tan(declination) * math.cos(lat),
    )) + 180);
    return Solar3dSunPosition(
      azimuthDegrees: azimuth,
      elevationDegrees: 90 - _degrees(zenith),
    );
  }
}
