import 'package:flutter_test/flutter_test.dart';
import 'package:greencity_os/domain/solar3d/electrical/solar3d_single_diode.dart';
import 'package:greencity_os/domain/solar3d/electrical/solar3d_substring_irradiance.dart';
import 'package:greencity_os/domain/solar3d/solar3d_geometric_shading.dart';
import 'package:greencity_os/domain/solar3d/solar_resource_hour.dart';

void main() {
  const diode = Solar3dDiodeCalibration(
    moduleModel: 'TEST / CALIBRATED', source: 'Synthetic benchmark only',
    seriesCells: 72, ilRefA: 10, ioRefA: 1e-10,
    rsOhm: .3, rshRefOhm: 800, aRefV: 2.5,
    alphaScAperC: .005,
  );
  const panel = Solar3dObject(
    id: 'INV/1/1', kind: Solar3dObjectKind.panel,
    center: Solar3dVector(0, 1, 0),
    width: 1, depth: 2, height: .05, mpptIndex: 1,
  );
  const obstacle = Solar3dObject(
    id: 'OBS', kind: Solar3dObjectKind.obstacle,
    center: Solar3dVector(0, 3, 0),
    width: 2, depth: 3, height: 1.5,
  );
  final hour = SolarResourceHour(
    startUtc: DateTime.utc(2024, 1, 1, 12),
    solarAzimuthDegrees: 0, apparentSolarElevationDegrees: 90,
    poaGlobalWm2: 1000, poaDirectWm2: 800,
    poaSkyDiffuseWm2: 150, poaGroundWm2: 50,
  );
  const mapping = Solar3dPhysicalFaceMap(
    panelId: 'INV/1/1', rows: 4, columns: 4,
    substrings: [
      Solar3dSubstringFootprint(
        substringId: 'whole-panel',
        sampleCells: [0, 1, 2, 3, 4, 5, 6, 7,
                      8, 9, 10, 11, 12, 13, 14, 15],
        calibration: diode,
      ),
    ],
  );

  test('real face mask distinguishes front-face illumination and shadow',
      () {
    final clear = Solar3dScene([panel]);
    final blocked = Solar3dScene([panel, obstacle]);
    final without = mapping.fromHour(
      panel: panel, scene: clear, hour: hour,
      poaTiltDegrees: 0, poaAzimuthDegrees: 0,
      cellTemperatureC: 25,
    );
    final withShadow = mapping.fromHour(
      panel: panel, scene: blocked, hour: hour,
      poaTiltDegrees: 0, poaAzimuthDegrees: 0,
      cellTemperatureC: 25,
    );
    expect(withShadow.substrings.single.diode.shortCircuitCurrent,
        lessThan(without.substrings.single.diode.shortCircuitCurrent));
    expect(mapping.uniformPanelProxy, true);
    final grid = Solar3dGeometricShading.inspectPanelGrid(
      panel: panel, scene: blocked,
      sunAzimuthDegrees: 0, sunElevationDegrees: 90,
      rows: 4, columns: 4,
    );
    expect(grid?.blockedFractionFor(List.generate(16, (i) => i)), 1);
  });

  test('unknown physical topology cannot invent three substrings', () {
    final map = Solar3dPhysicalFaceMap(
      panelId: 'INV/1/1', rows: 2, columns: 2,
      substrings: [
        const Solar3dSubstringFootprint(
          substringId: 'A', sampleCells: [0, 1], calibration: diode,
        ),
        const Solar3dSubstringFootprint(
          substringId: 'B', sampleCells: [2, 3], calibration: diode,
        ),
      ],
    );
    expect(map.validate, throwsFormatException);
    final overlapping = Solar3dPhysicalFaceMap(
      panelId: 'INV/1/1', rows: 2, columns: 2,
      substrings: [
        const Solar3dSubstringFootprint(
          substringId: 'A', sampleCells: [0, 1, 2], calibration: diode,
        ),
        const Solar3dSubstringFootprint(
          substringId: 'B', sampleCells: [2, 3], calibration: diode,
        ),
      ],
    );
    expect(overlapping.validate, throwsFormatException);
  });

  test('different POA orientation must be recalculated', () {
    expect(() => mapping.fromHour(
      panel: panel, scene: Solar3dScene([panel]), hour: hour,
      poaTiltDegrees: 20, poaAzimuthDegrees: 0,
      cellTemperatureC: 25,
    ), throwsFormatException);
  });
}
