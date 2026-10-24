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
  test('a chave identifica duplicidade independente de espaços/maiúsculas',
      () {
    expect(
      EquipmentCatalog.key('  Auxsol ', ' ASN-10SL '),
      EquipmentCatalog.key('auxsol', 'asn-10sl'),
    );
    expect(
      EquipmentCatalog.key('Jetion Solar', 'JT690SLk(B)'),
      EquipmentCatalog.key('JETION  SOLAR', 'jt690slk(b)'),
    );
    expect(
      EquipmentCatalog.key('AUXSOL', 'ASN-9SL'),
      isNot(EquipmentCatalog.key('AUXSOL', 'ASN-10SL')),
    );
    expect(
      EquipmentCatalog.key('AUXSOL', 'ASN-10SL'),
      isNot(EquipmentCatalog.key('Outra Marca', 'ASN-10SL')),
    );
  });

  test('candidatos duplicados são filtrados somente na lista a salvar', () {
    final existing = {
      EquipmentCatalog.key('AUXSOL', 'ASN-9SL'),
    };
    final input = ['ASN-9SL', ' ASN-10SL ', 'asn-10sl', 'ASN-10.5SL'];
    final newModels = EquipmentCatalog.uniqueNew(
      input,
      existing,
      (String name) => EquipmentCatalog.key('auxsol', name),
    );
    expect(newModels, [' ASN-10SL ', 'ASN-10.5SL']);
    expect(existing, {EquipmentCatalog.key('AUXSOL', 'ASN-9SL')},
        reason: 'Filtro não modifica os registros já cadastrados.');
  });

  test('módulo e inversor com mesmo nome usam coleções independentes', () {
    const item = 'MODEL-100';
    final modules = EquipmentCatalog.uniqueNew(
      [item], {EquipmentCatalog.key('Fabricante', item)},
      (String name) => EquipmentCatalog.key('Fabricante', name),
    );
    final inverters = EquipmentCatalog.uniqueNew(
      [item], <String>{},
      (String name) => EquipmentCatalog.key('Fabricante', name),
    );
    expect(modules, isEmpty);
    expect(inverters, [item]);
  });

}
