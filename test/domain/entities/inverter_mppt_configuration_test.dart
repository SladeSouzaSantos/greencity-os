import 'package:flutter_test/flutter_test.dart';
import 'package:greencity_os/domain/entities/inverter_mppt_configuration.dart';
import 'package:greencity_os/data/models/ai_equipment_mapper.dart';
import 'package:greencity_os/data/models/ai_extraction_result_model.dart';

void main() {
  test('AUXSOL ASN-10SL: 2 rastreadores e 3 entradas distintas', () {
    final ai = AiExtractedInverter.fromJson({
      'manufacturer': 'AUXSOL',
      'modelName': 'ASN-10SL',
      'inverterType': 'string',
      'gridConnection': 'monophasic',
      'nominalPowerKw': 10,
      'maxInputPowerKw': 20,
      'mpptCount': 2,
      'totalDcInputs': 3,
      'maxInputVoltage': 600,
      'minMpptVoltage': 40,
      'maxMpptVoltage': 550,
      'maxInputCurrentPerMppt': '32 A / 16 A',
      'maxShortCircuitCurrent': '40 A / 20 A',
      'maxOutputCurrent': 45.5,
      'nominalVoltageAc': 220,
    });
    expect(ai.mpptCount, 2);
    expect(ai.totalDcInputs, 3);
    expect(ai.mpptInputCurrentsA, [32, 16]);
    expect(ai.mpptShortCircuitCurrentsA, [40, 20]);
    expect(AiEquipmentMapper.inverterProblems(ai), isEmpty);

    final inverter = AiEquipmentMapper.inverter(ai);
    expect(inverter.mpptCount, 2);
    expect(inverter.maxInputCurrentPerMppt, 16); // Compatibilidade legada.
    expect(inverter.maxShortCircuitCurrent, 20);
    expect(inverter.mpptConfiguration?.totalDcInputs, 3);
    expect(inverter.mpptConfiguration?.inputCurrentsA, [32, 16]);
    expect(inverter.mpptConfiguration?.shortCircuitCurrentsA, [40, 20]);
    expect(inverter.mpptConfiguration?.validate(inverter.mpptCount), isEmpty);
  });

  test('não confunde três entradas com três MPPTs', () {
    final ai = AiExtractedInverter.fromJson({
      'manufacturer': 'AUXSOL', 'modelName': 'ASN-10SL',
      'inverterType': 'string', 'gridConnection': 'monophasic',
      'nominalPowerKw': 10, 'maxInputPowerKw': 20,
      'mpptCount': 3, 'totalDcInputs': 3,
      'maxInputVoltage': 600, 'minMpptVoltage': 40,
      'maxMpptVoltage': 550,
      'maxInputCurrentPerMppt': '32A/16A',
      'maxShortCircuitCurrent': '40A/20A',
    });
    expect(AiEquipmentMapper.inverterProblems(ai),
        contains('número de correntes não corresponde aos MPPTs'));
    expect(() => AiEquipmentMapper.inverter(ai), throwsFormatException);
  });

  test('corrige contagem inconsistente com refinamento explícito', () {
    final initial = AiExtractedInverter.fromJson({
      'manufacturer': 'AUXSOL', 'modelName': 'ASN-10SL',
      'nominalPowerKw': 10, 'mpptCount': 3,
      'maxInputCurrentPerMppt': '32A/16A',
      'maxShortCircuitCurrent': '40A/20A',
    });
    final corrected = AiExtractedInverter.fromJson({
      'manufacturer': 'AUXSOL', 'modelName': 'ASN-10SL',
      'mpptCount': 2, 'totalDcInputs': 3,
      'maxInputCurrentPerMppt': '32A/16A',
      'maxShortCircuitCurrent': '40A/20A',
    });
    final merged = initial.fillMissing(corrected);
    expect(merged.mpptCount, 2);
    expect(merged.totalDcInputs, 3);
    expect(merged.mpptInputCurrentsA, [32, 16]);
  });

  test('dados legados sem perfil continuam sem MPPTs inventados', () {
    expect(InverterMpptConfiguration.decode(null), isNull);
    expect(InverterMpptConfiguration.decode(''), isNull);
    expect(InverterMpptConfiguration.decode('json inválido'), isNull);
    expect(InverterMpptConfiguration.decode('{}'), isNull);
  });
}
