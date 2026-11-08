import '../../entities/solar_system.dart';
import '../solar3d_geometric_shading.dart';

/// Order is explicitly documented from a real connection diagram.
/// Same string name on DIFFERENT inverters is not an electrical join.
class Solar3dStringSpec {
  final String inverterId, stringId;
  final int mpptIndex;
  final List<String> panelIdsInSeries;

  Solar3dStringSpec({
    required this.inverterId, required this.stringId,
    required this.mpptIndex, required List<String> panelIdsInSeries,
  }) : panelIdsInSeries = List.unmodifiable(panelIdsInSeries);

  Map<String, Object?> toJson() => {
    'inverter': inverterId, 'mppt': mpptIndex,
    'string': stringId, 'series_panels': panelIdsInSeries,
  };

  factory Solar3dStringSpec.fromJson(Map<String, dynamic> data) {
    if (data['inverter'] is! String || data['string'] is! String ||
        data['mppt'] is! int || data['series_panels'] is! List ||
        (data['series_panels'] as List).any((v) => v is! String)) {
      throw const FormatException('Topologia serializada inválida');
    }
    return Solar3dStringSpec(
      inverterId: data['inverter'] as String,
      mpptIndex: data['mppt'] as int,
      stringId: data['string'] as String,
      panelIdsInSeries: (data['series_panels'] as List).cast<String>(),
    );
  }
}

class Solar3dElectricalStringDesign {
  final List<Solar3dStringSpec> strings;

  Solar3dElectricalStringDesign(List<Solar3dStringSpec> strings)
      : strings = List.unmodifiable(strings);

  /// Must match the exact real equipment and all physical panels before
  /// any series/parallel electrical calculation is allowed.
  void validate({
    required Solar3dScene scene,
    required List<SolarSystem> systems,
    Set<String> excludedPanelIds = const {},
  }) {
    scene.validate();
    if (strings.isEmpty || systems.isEmpty) {
      throw const FormatException('Defina strings físicas reais');
    }
    final bySystem = {for (final s in systems) s.id: s};
    if (bySystem.length != systems.length) {
      throw const FormatException('Inversores com identificadores repetidos');
    }
    final physicalPanels = {
      for (final p in scene.objects)
        if (p.kind == Solar3dObjectKind.panel &&
            !excludedPanelIds.contains(p.id))
          p.id: p,
    };
    if (physicalPanels.isEmpty) {
      throw const FormatException('Nenhuma placa elétrica ativa');
    }
    final idsSeen = <String>{}, stringsSeen = <String>{};
    for (final s in strings) {
      final inverter = bySystem[s.inverterId];
      if (inverter == null || s.stringId.trim().isEmpty ||
          s.mpptIndex < 1 || s.mpptIndex > inverter.inverter.mpptCount ||
          s.panelIdsInSeries.isEmpty ||
          !stringsSeen.add('${s.inverterId}/${s.mpptIndex}/${s.stringId}')) {
        throw const FormatException('Inversor/MPPT/string física inválida');
      }
      for (final id in s.panelIdsInSeries) {
        final panel = physicalPanels[id];
        if (panel == null || !idsSeen.add(id) ||
            !id.startsWith('${s.inverterId}/') ||
            panel.mpptIndex != s.mpptIndex ||
            (panel.stringId?.trim() ?? '') != s.stringId.trim()) {
          throw FormatException('Placa sem vínculo elétrico único: $id');
        }
      }
    }
    if (idsSeen.length != physicalPanels.length) {
      throw const FormatException(
          'Há placas sem string física e ordem de série');
    }
    if (!excludedPanelIds.every((id) =>
        scene.objects.any((p) => p.id == id &&
            p.kind == Solar3dObjectKind.panel))) {
      throw const FormatException('Exclusão de placa inexistente');
    }
  }

  Map<String, Object?> toJson() => {
    'schema_version': 1,
    'strings': strings.map((s) => s.toJson()).toList(),
  };

  static Solar3dElectricalStringDesign fromJson(
      Map<String, dynamic> data) {
    if (data['schema_version'] != 1 || data['strings'] is! List) {
      throw const FormatException('Versão de string elétrica inválida');
    }
    return Solar3dElectricalStringDesign([
      for (final raw in data['strings'] as List)
        if (raw is Map)
          Solar3dStringSpec.fromJson(Map<String, dynamic>.from(raw))
        else
          throw const FormatException('Circuito elétrico em JSON inválido'),
    ]);
  }
}
