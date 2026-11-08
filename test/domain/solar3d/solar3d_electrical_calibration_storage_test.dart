import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:greencity_os/data/datasources/solar3d_electrical_calibration_storage.dart';
import 'package:greencity_os/domain/entities/pv_module.dart';
import 'package:greencity_os/domain/enums/cell_technology.dart';
import 'package:greencity_os/domain/solar3d/electrical/solar3d_single_diode.dart';

void main() {
  PvModule module({double voc = 49}) => PvModule(
    manufacturer: 'MANUFACTURER', modelName: 'MODULE-500',
    cellTechnology: CellTechnology.topcon,
    powerWp: 500, efficiency: 20,
    length: 2000, width: 1000, weight: 25,
    vOc: voc, iSc: 13, vMp: 41, iMp: 12,
    tempCoefVoc: -.3, tempCoefIsc: .04,
    tempCoefPmax: -.3, isBifacial: false,
  );

  test('calibration persists separately and STC change blocks reuse',
      () async {
    final dir = await Directory.systemTemp.createTemp('solar3d-lab');
    addTearDown(() async => dir.delete(recursive: true));
    final catalog = Solar3dElectricalCalibrationStorage(rootDirectory: dir);
    final m = module();
    final model = Solar3dElectricalCalibrationStorage.modelLabel(m);
    final cal = Solar3dDiodeCalibration(
      moduleModel: model, source: 'Manufacturer fit, needs verification',
      seriesCells: 72, ilRefA: 13, ioRefA: 1e-10, rsOhm: .3,
      rshRefOhm: 500, aRefV: 2.5, alphaScAperC: .004,
    );
    expect(await catalog.load(m), isNull);
    await catalog.save(m, cal);
    final reopened = Solar3dElectricalCalibrationStorage(rootDirectory: dir);
    final data = await reopened.load(m);
    expect(data?.ilRefA, 13);
    expect(data?.source, cal.source);
    expect(data?.independentlyVerified, false);
    expect(await reopened.load(module(voc: 50)), isNull);
    await reopened.remove(m);
    expect(await reopened.load(m), isNull);
  });

  test('rejects assigning parameters from a different module', () async {
    final dir = await Directory.systemTemp.createTemp('solar3d-lab');
    addTearDown(() async => dir.delete(recursive: true));
    final m = module();
    final catalog = Solar3dElectricalCalibrationStorage(rootDirectory: dir);
    expect(() => catalog.save(m, const Solar3dDiodeCalibration(
      moduleModel: 'ANOTHER MODULE', source: 'External',
      seriesCells: 72, ilRefA: 10, ioRefA: 1e-10,
      rsOhm: .3, rshRefOhm: 500, aRefV: 2.5,
      alphaScAperC: .004,
    )), throwsFormatException);
  });
}
