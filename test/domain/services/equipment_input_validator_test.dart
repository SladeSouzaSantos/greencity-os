import 'package:flutter_test/flutter_test.dart';
import 'package:greencity_os/domain/services/equipment_input_validator.dart';

void main() {
  test('modelo alfanumérico é texto válido para módulos e inversores', () {
    for (final isModule in [true, false]) {
      expect(EquipmentInputValidator.isTextField('model'), isTrue);
      expect(
        EquipmentInputValidator.validate(
          key: 'model', value: 'BYD595TUI66T', isModule: isModule,
        ), isNull,
      );
      expect(
        EquipmentInputValidator.validate(
          key: 'model', value: 'ASN-3SL', isModule: isModule,
        ), isNull,
      );
      expect(
        EquipmentInputValidator.validate(
          key: 'model', value: '   ', isModule: isModule,
        ), isNotNull,
      );
    }
  });

  test('campos realmente numéricos seguem sendo validados', () {
    expect(EquipmentInputValidator.isTextField('powerWp'), isFalse);
    expect(
      EquipmentInputValidator.validate(
        key: 'powerWp', value: '595', isModule: true,
      ), isNull,
    );
    expect(
      EquipmentInputValidator.validate(
        key: 'powerWp', value: 'ABC', isModule: true,
      ), contains('Número'),
    );
    expect(
      EquipmentInputValidator.validate(
        key: 'mpptCount', value: '1,5', isModule: false,
      ), contains('inteiro'),
    );
  });

  test('dimensões e grau de proteção são campos textuais', () {
    expect(
      EquipmentInputValidator.validate(
        key: 'dimensions', value: '355 x 427 x 172 mm', isModule: false,
      ), isNull,
    );
    expect(
      EquipmentInputValidator.validate(
        key: 'protDegree', value: 'IP65', isModule: false,
      ), isNull,
    );
  });
}
