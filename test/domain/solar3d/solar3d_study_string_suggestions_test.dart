import 'package:flutter_test/flutter_test.dart';
import 'package:greencity_os/domain/solar3d/solar3d_geometric_shading.dart';
import 'package:greencity_os/domain/solar3d/solar3d_study_string_suggestions.dart';

Solar3dObject p(String id, int mppt, [String? string]) =>
    Solar3dObject(id: id, kind: Solar3dObjectKind.panel,
      center: const Solar3dVector(0, 1, 0),
      width: 1, depth: 2, height: .045, mpptIndex: mppt,
      stringId: string);

void main() {
  test('quatro placas 3+1 em MPPTs têm strings distintas do mesmo arranjo', () {
    final scene = Solar3dScene([
      p('sysA/1/1', 1), p('sysA/1/2', 1),
      p('sysA/1/3', 1), p('sysA/1/4', 2),
      p('sysB/1/1', 1),
    ]);
    expect(Solar3dStudyStringSuggestions.missingCount(scene), 5);
    final result = Solar3dStudyStringSuggestions.fillMissing(scene);
    expect(Solar3dStudyStringSuggestions.missingCount(result), 0);
    expect(result.objects[0].stringId, result.objects[2].stringId);
    expect(result.objects[0].stringId, isNot(result.objects[3].stringId));
    expect(result.objects[4].stringId, result.objects[0].stringId);
    // Matching label across inverters is intentional; audit scopes it.
    expect(scene.objects.every((p) => p.stringId == null), true);
  });

  test('identificações manuais são preservadas, sem alterar MPPT', () {
    final original = Solar3dScene([
      p('sys/1/1', 1, 'MANUAL-A'),
      p('sys/1/2', 1),
      p('sys/2/1', 2),
    ]);
    final next = Solar3dStudyStringSuggestions.fillMissing(original);
    expect(next.objects[0].stringId, 'MANUAL-A');
    expect(next.objects[1].stringId, 'ESTUDO-ARR1-MPPT1');
    expect(next.objects[2].stringId, 'ESTUDO-ARR2-MPPT2');
    expect(next.objects[2].mpptIndex, 2);
  });
}
