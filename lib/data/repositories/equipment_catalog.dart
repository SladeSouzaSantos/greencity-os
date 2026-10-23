import 'package:isar/isar.dart';

import '../../domain/entities/inverter.dart';
import '../../domain/entities/pv_module.dart';

/// Acesso único ao cadastro de equipamentos. Mantém o catálogo local
/// persistente e evita nomes repetidos sem alterar o esquema Isar existente.
class EquipmentCatalog {
  final Isar _isar;
  EquipmentCatalog(this._isar);

  static String normalize(String value) =>
      value.trim().replaceAll(RegExp(r'\\s+'), ' ').toLowerCase();

  static String key(String manufacturer, String model) =>
      '${normalize(manufacturer)}::${normalize(model)}';

  Future<bool> moduleExists(String manufacturer, String model) async {
    final entries = await _isar.pvModules.where().findAll();
    return entries.any((entry) =>
        key(entry.manufacturer, entry.modelName) == key(manufacturer, model));
  }

  Future<bool> inverterExists(String manufacturer, String model) async {
    final entries = await _isar.inverters.where().findAll();
    return entries.any((entry) =>
        key(entry.manufacturer, entry.modelName) == key(manufacturer, model));
  }

  Future<void> addModule(PvModule module) async {
    if (await moduleExists(module.manufacturer, module.modelName)) {
      throw StateError('Este modelo de módulo já está cadastrado.');
    }
    await _isar.writeTxn(() async {
      await _isar.pvModules.put(module);
    });
  }

  Future<void> addInverter(Inverter inverter) async {
    if (await inverterExists(inverter.manufacturer, inverter.modelName)) {
      throw StateError('Este modelo de inversor já está cadastrado.');
    }
    await _isar.writeTxn(() async {
      await _isar.inverters.put(inverter);
    });
  }

  Future<void> deleteModule(Id id) => _isar.writeTxn(() async {
        await _isar.pvModules.delete(id);
      });

  Future<void> deleteInverter(Id id) => _isar.writeTxn(() async {
        await _isar.inverters.delete(id);
      });
}
