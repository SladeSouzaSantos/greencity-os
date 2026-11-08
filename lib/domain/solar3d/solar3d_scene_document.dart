import 'dart:convert';

import 'solar3d_geometric_shading.dart';

/// Portable, local-only scene document. No electrical production is computed.
class Solar3dSceneDocument {
  final Solar3dScene scene;
  final Set<String> hiddenIds;
  final Set<String> excludedIds;

  const Solar3dSceneDocument({
    required this.scene,
    this.hiddenIds = const {},
    this.excludedIds = const {},
  });

  Map<String, dynamic> toJson() => {
    'schema_version': 1,
    'objects': scene.objects.map((o) => o.toSceneJson()).toList(),
    'hidden_ids': hiddenIds.toList()..sort(),
    'excluded_ids': excludedIds.toList()..sort(),
  };

  String encode() => jsonEncode(toJson());

  static double _number(Map<String, dynamic> input, String key) {
    final v = input[key];
    if (v is! num || !v.isFinite) {
      throw FormatException('Parâmetro 3D numérico inválido: $key');
    }
    return v.toDouble();
  }

  static Solar3dObject parseObject(Map<String, dynamic> json) {
    final p = json['position'];
    final kind = json['kind'];
    final metadata = json['greencity'];
    if (json['id'] is! String || p is! Map || kind is! String ||
        !['panel', 'obstacle', 'building'].contains(kind)) {
      throw const FormatException('Objeto 3D inválido no documento');
    }
    final position = Map<String, dynamic>.from(p);
    final details = metadata is Map ? Map<String, dynamic>.from(metadata) : <String,dynamic>{};
    final mppt = details['mppt_index'];
    final id = json['id'] as String;
    final object = Solar3dObject(
      id: id,
      kind: Solar3dObjectKind.values.byName(kind),
      center: Solar3dVector(_number(position,'east'),
        _number(position,'elevation'), _number(position,'north')),
      width: _number(json,'width'),
      height: _number(json,'height'),
      depth: _number(json,'depth'),
      azimuthDegrees: _number(json,'azimuth'),
      tiltDegrees: _number(json,'tilt'),
      moduleModel: details['module_model'] is String ? details['module_model'] as String : null,
      stringId: details['string_id'] is String ? details['string_id'] as String : null,
      mpptIndex: mppt is int ? mppt : null,
    );
    object.validate();
    return object;
  }

  static Solar3dSceneDocument decode(String source) {
    final raw = jsonDecode(source);
    if (raw is! Map || raw['schema_version'] != 1 || raw['objects'] is! List) {
      throw const FormatException('Versão de documento 3D não suportada');
    }
    final objects = (raw['objects'] as List).map((value) {
      if (value is! Map) throw const FormatException('Objeto 3D não é JSON');
      return parseObject(Map<String, dynamic>.from(value));
    }).toList(growable: false);
    final scene = Solar3dScene(objects);
    scene.validate();
    Set<String> ids(String key) {
      final values = raw[key];
      if (values is! List) return {};
      if (values.any((v) => v is! String)) {
        throw const FormatException('IDs ocultos/excluídos inválidos');
      }
      final all = values.cast<String>().toSet();
      final valid = objects.map((o) => o.id).toSet();
      if (!valid.containsAll(all)) {
        throw const FormatException('Referência a objeto inexistente');
      }
      return all;
    }
    return Solar3dSceneDocument(
      scene: scene, hiddenIds: ids('hidden_ids'),
      excludedIds: ids('excluded_ids'),
    );
  }

  /// Use the current Isar-backed project for equipment identity. A loaded
  /// scene may only override geometry + provisional MPPT assignments for
  /// panels that still exist. Never resurrect deleted equipment.
  Solar3dSceneDocument reconciledWith(Solar3dScene current) {
    final prior = {for (final o in scene.objects) o.id: o};
    final acceptedPanels = <Solar3dObject>[];
    for (final base in current.objects) {
      if (base.kind != Solar3dObjectKind.panel) continue;
      final saved = prior[base.id];
      if (saved == null || saved.kind != Solar3dObjectKind.panel ||
          saved.moduleModel != base.moduleModel ||
          saved.width != base.width || saved.depth != base.depth) {
        acceptedPanels.add(base);
      } else {
        acceptedPanels.add(base.copyWith(
          center: saved.center,
          azimuthDegrees: saved.azimuthDegrees,
          tiltDegrees: saved.tiltDegrees,
          mpptIndex: saved.mpptIndex,
          stringId: saved.stringId,
        ));
      }
    }
    final obstacles = scene.objects.where((o) =>
      o.kind != Solar3dObjectKind.panel).toList();
    final rebuilt = Solar3dScene([...acceptedPanels, ...obstacles]);
    rebuilt.validate();
    final valid = rebuilt.objects.map((o) => o.id).toSet();
    return Solar3dSceneDocument(
      scene: rebuilt,
      hiddenIds: hiddenIds.intersection(valid),
      excludedIds: excludedIds.intersection(valid),
    );
  }
}
