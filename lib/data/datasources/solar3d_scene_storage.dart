import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

import '../../domain/solar3d/solar3d_scene_document.dart';
import '../../domain/solar3d/solar3d_optical_correction.dart';
import '../../domain/solar3d/solar3d_plan_factory.dart';
import '../../domain/solar3d/solar3d_geometric_shading.dart';
import '../../domain/entities/solar_project.dart';
import '../../domain/entities/solar_system.dart';

/// Explicit save/load; does not mutate the production SolarProject models.
class Solar3dSceneStorage {
  final String projectKey;
  /// Test override for deterministic storage isolation; production uses
  /// getApplicationSupportDirectory() without any injected path.
  final Directory? rootDirectory;

  const Solar3dSceneStorage(this.projectKey, {this.rootDirectory});

  /// Both the editor and project summary MUST use the same stable key.
  factory Solar3dSceneStorage.forProject(
      SolarProject project, List<SolarSystem> systems) =>
      Solar3dSceneStorage([
        project.clientName, project.city, project.state,
        project.latitude.toStringAsFixed(6),
        project.longitude.toStringAsFixed(6),
        ...systems.map((system) => system.id),
      ].join('|'));

  String get _hash {
    // Stable 32-bit FNV-1a, used only as a path key; not cryptographic.
    var value = 0x811c9dc5;
    for (final c in projectKey.codeUnits) {
      value = ((value ^ c) * 0x01000193) & 0xffffffff;
    }
    return value.toRadixString(16).padLeft(8, '0');
  }

  Future<File> _file() async {
    final directory = rootDirectory ?? await getApplicationSupportDirectory();
    final folder = Directory('${directory.path}${Platform.pathSeparator}solar3d');
    if (!await folder.exists()) await folder.create(recursive: true);
    return File('${folder.path}${Platform.pathSeparator}scene-$_hash.json');
  }

  Future<File> _correctionFile() async {
    final sceneFile = await _file();
    return File('${sceneFile.parent.path}${Platform.pathSeparator}'
        'optical-$_hash.json');
  }

  /// Persist factors ONLY after the user confirms applying the full-year
  /// simulation. Link the factor snapshot to the exact persisted scene.
  Future<void> saveAppliedCorrection({
    required Solar3dSceneDocument scene,
    required Solar3dOpticalCorrection correction,
  }) async {
    final file = await _correctionFile();
    final source = jsonEncode({
      'schema_version': 1,
      'scene': scene.encode(),
      'correction': correction.toJson(),
    });
    await file.writeAsString(source, flush: true);
  }

  Future<Solar3dOpticalCorrection?> loadAppliedCorrection({
    required List<SolarSystem> systems,
  }) async {
    final file = await _correctionFile();
    if (!await file.exists()) {
      return null;
    }
    try {
      final savedScene = await load();
      if (savedScene == null) {
        return null;
      }
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! Map || decoded['schema_version'] != 1 ||
          decoded['scene'] != savedScene.encode() ||
          decoded['correction'] is! Map) {
        return null;
      }

      // Reject a stale snapshot if current installed equipment, modules
      // or wiring differs from the equipment used during application.
      final reconciled = savedScene.reconciledWith(
          Solar3dPlanFactory.fromSystems(systems));
      if (reconciled.encode() != savedScene.encode()) {
        return null;
      }
      final correction = Solar3dOpticalCorrection.fromJson(
          Map<String, dynamic>.from(decoded['correction'] as Map));
      if (!correction.isValidFor(systems)) {
        return null;
      }

      // Each MPPT retains exactly the modules recorded in the saved
      // scene; MPPT 1 of two inverters is NOT a shared tracker.
      final expectedCounts = <String, Map<int, int>>{};
      for (final panel in savedScene.scene.objects) {
        if (panel.kind != Solar3dObjectKind.panel) continue;
        final matching = systems.where(
            (sys) => panel.id.startsWith('${sys.id}/')).toList();
        if (matching.length != 1 || panel.mpptIndex == null) {
          return null;
        }
        final system = matching.single;
        if (panel.mpptIndex! > system.inverter.mpptCount) {
          return null;
        }
        final byMppt = expectedCounts.putIfAbsent(system.id, () => {});
        byMppt[panel.mpptIndex!] = (byMppt[panel.mpptIndex!] ?? 0) + 1;
      }
      for (final group in correction.groupsBySystemMppt.entries) {
        final expected = expectedCounts.remove(group.key);
        if (expected == null || group.value.length != expected.length) {
          return null;
        }
        for (final tracker in group.value.entries) {
          if (expected[tracker.key] != tracker.value.moduleCount) {
            return null;
          }
        }
      }
      if (expectedCounts.isNotEmpty) {
        return null;
      }
      return correction;
    } on FormatException {
      return null;
    } on TypeError {
      return null;
    } on FileSystemException {
      return null;
    }
  }

  Future<void> clearAppliedCorrection() async {
    final file = await _correctionFile();
    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<void> save(Solar3dSceneDocument document) async {
    final file = await _file();
    await file.writeAsString(document.encode(), flush: true);
  }

  /// Removes only THIS project's scene file, not any other project,
  /// cached equipment data, or the production HSP results.
  Future<void> clear() async {
    await clearAppliedCorrection();
    final file = await _file();
    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<Solar3dSceneDocument?> load() async {
    final file = await _file();
    if (!await file.exists()) return null;
    return Solar3dSceneDocument.decode(await file.readAsString());
  }
}
