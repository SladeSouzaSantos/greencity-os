import 'package:flutter_test/flutter_test.dart';
import 'package:greencity_os/data/repositories/equipment_catalog.dart';

void main() {
  test('normaliza nome de fabricante e modelo para deduplicação', () {
    expect(
      EquipmentCatalog.key('  DAH    Solar ', ' DHN-66Y18 / DG-700 '),
      EquipmentCatalog.key('dah solar', 'dhn-66y18 / dg-700'),
    );
    expect(
      EquipmentCatalog.key('DAH', '700'),
      isNot(EquipmentCatalog.key('DAH', '705')),
    );
  });
}
