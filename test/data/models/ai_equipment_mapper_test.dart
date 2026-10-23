import 'package:flutter_test/flutter_test.dart';
import 'package:greencity_os/data/models/ai_equipment_mapper.dart';
import 'package:greencity_os/data/models/ai_extraction_result_model.dart';

void main() {
  test('não importa módulos com dados essenciais ausentes', () {
    final empty = AiExtractedModule.fromJson({
      'manufacturer': 'Teste',
      'modelName': 'PV-700',
      'powerWp': 700,
    });
    expect(AiEquipmentMapper.moduleProblems(empty), isNotEmpty);
    expect(() => AiEquipmentMapper.module(empty), throwsFormatException);
  });

  test('preserva modelos diferentes e parâmetros STC', () {
    AiExtractedModule make(int wp) => AiExtractedModule.fromJson({
      'manufacturer': 'Solar',
      'modelName': 'STC-$wp',
      'powerWp': wp,
      'efficiency': 22.5,
      'length': 2382,
      'width': 1134,
      'cellTechnology': 'TOPCON',
      'vOc': 48,
      'iSc': 15,
      'vMp': 40,
      'iMp': 14,
      'isBifacial': true,
    });
    final a = AiEquipmentMapper.module(make(700));
    final b = AiEquipmentMapper.module(make(705));
    expect(a.powerWp, 700);
    expect(b.powerWp, 705);
    expect(a.isBifacial, true);
    expect(a.vOc, 48);
  });

  test('eficiência de inversor vira fração e MPPT preserva faixa', () {
    final extracted = AiExtractedInverter.fromJson({
      'manufacturer': 'Inversor',
      'modelName': 'INV-10K',
      'nominalPowerKw': 10,
      'maxInputPowerKw': 15,
      'maxEfficiency': 98.4,
      'mpptCount': 2,
      'maxInputVoltage': 1100,
      'minMpptVoltage': 150,
      'maxMpptVoltage': 950,
      'maxInputCurrentPerMppt': 30,
      'inverterType': 'string',
      'gridConnection': 'triphasic',
    });
    expect(AiEquipmentMapper.inverterProblems(extracted), isEmpty);
    final inverter = AiEquipmentMapper.inverter(extracted);
    expect(inverter.maxEfficiency, closeTo(.984, .0001));
    expect(inverter.mpptCount, 2);
    expect(inverter.maxMpptVoltage, 950);
  });
}
