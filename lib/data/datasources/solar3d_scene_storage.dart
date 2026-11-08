import 'dart:io';
import 'package:path_provider/path_provider.dart';

import '../../domain/solar3d/solar3d_scene_document.dart';

/// Explicit save/load; does not mutate the production SolarProject models.
class Solar3dSceneStorage {
  final String projectKey;
  /// Test override for deterministic storage isolation; production uses
  /// getApplicationSupportDirectory() without any injected path.
  final Directory? rootDirectory;

  const Solar3dSceneStorage(this.projectKey, {this.rootDirectory});

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

  Future<void> save(Solar3dSceneDocument document) async {
    final file = await _file();
    await file.writeAsString(document.encode(), flush: true);
  }

  /// Removes only THIS project's scene file, not any other project,
  /// cached equipment data, or the production HSP results.
  Future<void> clear() async {
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
