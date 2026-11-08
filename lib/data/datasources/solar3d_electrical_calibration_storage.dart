import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../../domain/entities/pv_module.dart';
import '../../domain/solar3d/electrical/solar3d_single_diode.dart';

/// Opt-in LOCAL research parameter registry, isolated from Isar generated
/// schemas and the approved optical-correction file. No automatic values.
class Solar3dElectricalCalibrationStorage {
  final Directory? rootDirectory;
  const Solar3dElectricalCalibrationStorage({this.rootDirectory});

  static String modelLabel(PvModule module) =>
      '${module.manufacturer} / ${module.modelName}';

  /// An updated datasheet or STC nameplate invalidates a prior fit.
  static String identity(PvModule m) => jsonEncode({
    'make': m.manufacturer.trim().toLowerCase(),
    'model': m.modelName.trim().toLowerCase(),
    'technology': m.cellTechnology.name,
    'p_stc': m.powerWp, 'voc': m.vOc, 'isc': m.iSc,
    'vmp': m.vMp, 'imp': m.iMp,
    'alpha_isc': m.tempCoefIsc, 'beta_voc': m.tempCoefVoc,
    'gamma_power': m.tempCoefPmax, 'bifacial': m.isBifacial,
    'dimensions_mm': [m.length, m.width],
  });

  Future<File> _file() async {
    final root = rootDirectory ?? await getApplicationSupportDirectory();
    final folder = Directory('${root.path}${Platform.pathSeparator}solar3d');
    if (!await folder.exists()) await folder.create(recursive: true);
    return File('${folder.path}${Platform.pathSeparator}'
        'electrical-calibrations-v1.json');
  }

  Future<Map<String, dynamic>> _read() async {
    final file = await _file();
    if (!await file.exists()) return {};
    final raw = jsonDecode(await file.readAsString());
    if (raw is! Map || raw['schema_version'] != 1 ||
        raw['records'] is! Map) {
      throw const FormatException('Catálogo de calibração incompatível');
    }
    return Map<String, dynamic>.from(raw['records'] as Map);
  }

  Future<Solar3dDiodeCalibration?> load(PvModule module) async {
    final records = await _read();
    final data = records[identity(module)];
    if (data == null) return null;
    if (data is! Map) {
      throw const FormatException('Registro de calibração corrompido');
    }
    final result = Solar3dDiodeCalibration.fromJson(
        Map<String, dynamic>.from(data));
    if (result.moduleModel != modelLabel(module)) {
      throw const FormatException(
          'Parâmetros I-V de outro equipamento não são reutilizáveis');
    }
    return result;
  }

  Future<void> save(
      PvModule module, Solar3dDiodeCalibration calibration) async {
    calibration.validate();
    if (calibration.moduleModel != modelLabel(module)) {
      throw const FormatException('Modelo do módulo não corresponde ao registro');
    }
    final records = await _read();
    records[identity(module)] = calibration.toJson();
    final file = await _file();
    final pending = File('${file.path}.tmp');
    await pending.writeAsString(jsonEncode({
      'schema_version': 1, 'records': records,
    }), flush: true);
    await pending.rename(file.path);
  }

  Future<void> remove(PvModule module) async {
    final records = await _read();
    records.remove(identity(module));
    final file = await _file();
    final pending = File('${file.path}.tmp');
    await pending.writeAsString(jsonEncode({
      'schema_version': 1, 'records': records,
    }), flush: true);
    await pending.rename(file.path);
  }
}
