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

  test('correntes por MPPT aceitam listas e rejeitam valores inválidos', () {
    expect(EquipmentInputValidator.validate(
      key: 'mpptCurrents', value: '32/16', isModule: false,
    ), isNull);
    expect(EquipmentInputValidator.validate(
      key: 'mpptIscCurrents', value: '40/20', isModule: false,
    ), isNull);
    expect(EquipmentInputValidator.validate(
      key: 'mpptCurrents', value: '32/abc', isModule: false,
    ), isNotNull);
    expect(EquipmentInputValidator.validate(
      key: 'totalDcInputs', value: '3,5', isModule: false,
    ), contains('inteiro'));
  });

  test('entradas CC não podem ser menores que rastreadores MPPT', () {
    expect(EquipmentInputValidator.validateMpptTopology(
      mpptCount: '3', totalDcInputs: '2', mpptCurrents: '32/16',
    ), contains('maiores ou iguais'));
    expect(EquipmentInputValidator.validateMpptTopology(
      mpptCount: '2', totalDcInputs: '3', mpptCurrents: '32/16',
      mpptIscCurrents: '40/20',
    ), isNull);
    expect(EquipmentInputValidator.validateMpptTopology(
      mpptCount: '3', totalDcInputs: '3', mpptCurrents: '32/16',
    ), contains('quantidade de correntes'));
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
