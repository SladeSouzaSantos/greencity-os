import 'package:flutter_test/flutter_test.dart';
import 'package:greencity_os/data/models/ai_equipment_refinement.dart';
import 'package:greencity_os/data/models/ai_extraction_result_model.dart';

void main() {
  AiExtractionResultModel parse(List<Map<String, dynamic>> modules,
          [List<Map<String, dynamic>> inverters = const []]) =>
      AiExtractionResultModel.fromJson({
        'modules': modules,
        'inverters': inverters,
      });

  test('módulos incompletos acionam uma segunda leitura', () {
    final initial = parse([{
      'manufacturer': 'Jetion', 'modelName': 'JT-700',
      'powerWp': 700, 'vOc': 49.5,
    }]);
    expect(AiEquipmentRefinement.needsRefinement(initial), isTrue);
    final prompt = AiEquipmentRefinement.prompt(initial, 'TABELA STC 700 Wp');
    expect(prompt, contains('Jetion JT-700'));
    expect(prompt, contains('vMp'));
    expect(prompt, contains('TABELA STC 700 Wp'));
    expect(prompt, contains('"modules"'));
  });

  test('completa módulos sem sobrescrever valores STC e inclui variantes', () {
    final initial = parse([{
      'manufacturer': 'Jetion', 'modelName': 'JT-700',
      'powerWp': 700, 'vOc': 49.5,
    }]);
    final recovered = parse([{
      'manufacturer': 'Jetion', 'modelName': 'JT-700',
      'powerWp': 705, 'vOc': 50.0, 'vMp': 41.0,
      'iMp': 17.1, 'efficiency': 22.5, 'length': 2382,
      'cellTechnology': 'TOPCON', 'isBifacial': true,
    }, {
      'manufacturer': 'Jetion', 'modelName': 'JT-705',
      'powerWp': 705,
    }]);
    final result = AiEquipmentRefinement.mergeMissing(initial, recovered);
    expect(result.modules, hasLength(2));
    expect(result.modules.first.powerWp, 700);
    expect(result.modules.first.vOc, 49.5);
    expect(result.modules.first.vMp, 41);
    expect(result.modules.first.cellTechnology, 'TOPCON');
    expect(result.modules.first.isBifacial, isTrue);
    expect(result.modules.last.modelName, 'JT-705');
  });

  test('refinamento demanda correção quando MPPTs e vetores divergem', () {
    final initial = parse([], [{
      'manufacturer': 'AUXSOL',
      'modelName': 'ASN-10SL',
      'nominalPowerKw': 10,
      'mpptCount': 3,
      'mpptInputCurrentsA': [32, 16],
      'mpptShortCircuitCurrentsA': [40, 20],
    }]);
    expect(AiEquipmentRefinement.needsRefinement(initial), isTrue);
    final prompt = AiEquipmentRefinement.prompt(
        initial, 'Quantidade MPPT: 2; Número Entradas: 3');
    expect(prompt, contains('totalDcInputs'));
    expect(prompt, contains('corrigir mpptCount'));
  });

  test('preserva correntes MPPT refinadas sem perder módulos', () {
    final initial = parse([{
      'manufacturer': 'Jetion', 'modelName': 'JT-700', 'powerWp': 700,
    }], [{
      'manufacturer': 'Solplanet', 'modelName': 'ASW9100-S',
      'nominalPowerKw': 9.1,
    }]);
    final recovered = parse([], [{
      'manufacturer': 'Solplanet', 'modelName': 'ASW9100-S',
      'maxInputPowerWp': 16500,
      'maxInputCurrentPerMppt': '20 A/16 A/20 A',
    }]);
    final result = AiEquipmentRefinement.mergeMissing(initial, recovered);
    expect(result.modules, hasLength(1));
    expect(result.inverters.single.maxInputPowerKw, 16.5);
    expect(result.inverters.single.mpptInputCurrentsA, [20, 16, 20]);
  });
}
