import 'solar3d_geometric_shading.dart';

/// Proposes study-only series strings for modules registered in the same
/// SolarArray and assigned to the same MPPT in the 3D scene.
///
/// Does NOT infer actual wiring. The user must explicitly opt in and review
/// MPPT start voltage, series limits, DC inputs and all blocking findings.
class Solar3dStudyStringSuggestions {
  static int missingCount(Solar3dScene scene) => scene.objects
      .where((o) => o.kind == Solar3dObjectKind.panel &&
          (o.stringId == null || o.stringId!.trim().isEmpty))
      .length;

  static Solar3dScene fillMissing(Solar3dScene scene) {
    scene.validate();
    return Solar3dScene([
      for (final object in scene.objects)
        if (object.kind == Solar3dObjectKind.panel &&
            (object.stringId == null || object.stringId!.trim().isEmpty))
          object.copyWith(
            stringId: _studyIdFor(object),
          )
        else
          object,
    ]);
  }

  static String _studyIdFor(Solar3dObject panel) {
    // Same project array, same inverter and MPPT => ONE hypothetical
    // series string. Since IDs use inverterId/arrayIndex/panelIndex,
    // arrayIndex is always the penultimate segment. String IDs are
    // scoped to inverter by Solar3dElectricalAudit.
    final parts = panel.id.split('/');
    if (parts.length < 3 || parts[parts.length - 2].isEmpty ||
        panel.mpptIndex == null) {
      throw FormatException(
        'Placa ${panel.id} não pode receber string sugerida');
    }
    return 'ESTUDO-ARR${parts[parts.length - 2]}-MPPT${panel.mpptIndex}';
  }
}
