import 'package:isar/isar.dart';

import '../../domain/entities/inverter.dart';
import '../../domain/entities/pv_module.dart';

/// Acesso único ao cadastro de equipamentos. Mantém o catálogo local
/// persistente e evita nomes repetidos sem alterar o esquema Isar existente.
class EquipmentImportReport {
  final int modulesAdded;
  final int invertersAdded;
  final int duplicatesSkipped;

  const EquipmentImportReport({
    required this.modulesAdded,
    required this.invertersAdded,
    required this.duplicatesSkipped,
  });

  int get totalAdded => modulesAdded + invertersAdded;
}

class EquipmentCatalog {
  final Isar _isar;
  EquipmentCatalog(this._isar);

  static String normalize(String value) =>
      value.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();

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

  /// Importação em lote, atômica. Modelos já existentes ou repetidos no
  /// próprio PDF são ignorados pela chave fabricante + modelo normalizada.
  Future<EquipmentImportReport> importMany({
    required List<PvModule> modules,
    required List<Inverter> inverters,
  }) async {
    final savedModules = await _isar.pvModules.where().findAll();
    final savedInverters = await _isar.inverters.where().findAll();
    final moduleKeys = savedModules
        .map((m) => key(m.manufacturer, m.modelName))
        .toSet();
    final inverterKeys = savedInverters
        .map((i) => key(i.manufacturer, i.modelName))
        .toSet();

    final newModules = <PvModule>[];
    final newInverters = <Inverter>[];
    var skipped = 0;
    for (final module in modules) {
      if (moduleKeys.add(key(module.manufacturer, module.modelName))) {
        newModules.add(module);
      } else {
        skipped++;
      }
    }
    for (final inverter in inverters) {
      if (inverterKeys.add(key(inverter.manufacturer, inverter.modelName))) {
        newInverters.add(inverter);
      } else {
        skipped++;
      }
    }

    if (newModules.isNotEmpty || newInverters.isNotEmpty) {
      await _isar.writeTxn(() async {
        if (newModules.isNotEmpty) await _isar.pvModules.putAll(newModules);
        if (newInverters.isNotEmpty) await _isar.inverters.putAll(newInverters);
      });
    }
    return EquipmentImportReport(
      modulesAdded: newModules.length,
      invertersAdded: newInverters.length,
      duplicatesSkipped: skipped,
    );
  }

  Future<void> deleteModule(Id id) => _isar.writeTxn(() async {
        await _isar.pvModules.delete(id);
      });

  Future<void> deleteInverter(Id id) => _isar.writeTxn(() async {
        await _isar.inverters.delete(id);
      });
}
