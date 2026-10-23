import 'package:flutter_test/flutter_test.dart';
import 'package:greencity_os/domain/entities/inverter.dart';

void main() {
  test('schema Isar segue a ordem das propriedades geradas', () {
    // A ordem dos offsets deve corresponder à ordem nativa de propriedades.
    // A inclusão do JSON dos MPPTs não pode ficar ao final do esquema.
    final names = InverterSchema.properties.keys.toList();
    final ordered = [...names]..sort();
    expect(names, ordered);
    for (var index = 0; index < names.length; index++) {
      expect(InverterSchema.properties[names[index]]!.id, index,
          reason: 'Offset incorreto para ${names[index]}');
    }
    expect(InverterSchema.properties['mpptConfigurationJson']!.id, 17);
    expect(InverterSchema.properties['mpptCount']!.id, 18);
  });
}
