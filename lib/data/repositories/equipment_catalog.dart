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

  /// A checagem decisiva ocorre na mesma transação da inserção.
  /// Assim, a conferência usa o fabricante/modelo final do formulário e
  /// não permite que uma lista obtida antes da revisão fique obsoleta.
  Future<void> addModule(PvModule module) => _isar.writeTxn(() async {
        final existing = await _isar.pvModules.where().findAll();
        if (existing.any((item) =>
            key(item.manufacturer, item.modelName) ==
            key(module.manufacturer, module.modelName))) {
          throw StateError('Módulo já cadastrado com fabricante '
              '"${module.manufacturer}" e modelo "${module.modelName}". '
              'Nenhum registro foi alterado.');
        }
        await _isar.pvModules.put(module);
      });

  Future<void> addInverter(Inverter inverter) => _isar.writeTxn(() async {
        final existing = await _isar.inverters.where().findAll();
        if (existing.any((item) =>
            key(item.manufacturer, item.modelName) ==
            key(inverter.manufacturer, inverter.modelName))) {
          throw StateError('Inversor já cadastrado com fabricante '
              '"${inverter.manufacturer}" e modelo "${inverter.modelName}". '
              'Nenhum registro foi alterado.');
        }
        await _isar.inverters.put(inverter);
      });

  /// Edição preserva o ID Isar e bloqueia colisões fabricante+modelo
  /// com OUTROS registros, mas permite manter o mesmo modelo.
  Future<void> updateModule(PvModule module) async {
    await _isar.writeTxn(() async {
      final previous = await _isar.pvModules.get(module.id);
      if (previous == null) {
        throw StateError('Módulo não encontrado. Atualize a lista.');
      }
      final modules = await _isar.pvModules.where().findAll();
      if (modules.any((entry) => entry.id != module.id &&
          key(entry.manufacturer, entry.modelName) ==
          key(module.manufacturer, module.modelName))) {
        throw StateError('Outro módulo já utiliza este fabricante e modelo.');
      }
      await _isar.pvModules.put(module);
    });
  }

  Future<void> updateInverter(Inverter inverter) async {
    await _isar.writeTxn(() async {
      final previous = await _isar.inverters.get(inverter.id);
      if (previous == null) {
        throw StateError('Inversor não encontrado. Atualize a lista.');
      }
      final inverters = await _isar.inverters.where().findAll();
      if (inverters.any((entry) => entry.id != inverter.id &&
          key(entry.manufacturer, entry.modelName) ==
          key(inverter.manufacturer, inverter.modelName))) {
        throw StateError('Outro inversor já utiliza este fabricante e modelo.');
      }
      await _isar.inverters.put(inverter);
    });
  }

  /// Seleciona apenas registros ainda ausentes, deduplicando também a lista
  /// recebida. Cada coleção recebe seu próprio conjunto de chaves.
  static List<T> uniqueNew<T>(
    Iterable<T> candidates,
    Set<String> existingKeys,
    String Function(T) identity,
  ) {
    final seen = <String>{...existingKeys};
    return [
      for (final candidate in candidates)
        if (seen.add(identity(candidate))) candidate,
    ];
  }

  /// Importação em lote atômica: consulta duplicidades NO MOMENTO do salvar.
  /// Registros existentes não são modificados; itens repetidos no PDF ou
  /// inseridos enquanto o usuário revisava são ignorados.
  Future<EquipmentImportReport> importMany({
    required List<PvModule> modules,
    required List<Inverter> inverters,
  }) => _isar.writeTxn(() async {
        final existingModules = modules.isEmpty
            ? <PvModule>[]
            : await _isar.pvModules.where().findAll();
        final existingInverters = inverters.isEmpty
            ? <Inverter>[]
            : await _isar.inverters.where().findAll();

        final newModules = uniqueNew(
          modules,
          existingModules.map((m) => key(m.manufacturer, m.modelName)).toSet(),
          (PvModule m) => key(m.manufacturer, m.modelName),
        );
        final newInverters = uniqueNew(
          inverters,
          existingInverters
              .map((i) => key(i.manufacturer, i.modelName)).toSet(),
          (Inverter i) => key(i.manufacturer, i.modelName),
        );

        if (newModules.isNotEmpty) await _isar.pvModules.putAll(newModules);
        if (newInverters.isNotEmpty) {
          await _isar.inverters.putAll(newInverters);
        }
        return EquipmentImportReport(
          modulesAdded: newModules.length,
          invertersAdded: newInverters.length,
          duplicatesSkipped: modules.length + inverters.length -
              newModules.length - newInverters.length,
        );
      });

  Future<void> deleteModule(Id id) => _isar.writeTxn(() async {
        await _isar.pvModules.delete(id);
      });

  Future<void> deleteInverter(Id id) => _isar.writeTxn(() async {
        await _isar.inverters.delete(id);
      });
}
