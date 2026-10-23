import 'package:flutter_test/flutter_test.dart';
import 'package:greencity_os/data/models/ai_inverter_refinement.dart';
import 'package:greencity_os/data/models/ai_extraction_result_model.dart';

void main() {
  AiExtractionResultModel make(List<Map<String, dynamic>> inverters) =>
      AiExtractionResultModel.fromJson({
        'modules': [], 'inverters': inverters,
      });

  test('extrai texto anotado sem exigir novo upload PDF', () {
    final text = AiInverterRefinement.parsedPdfText({'choices':[{
      'message': {'annotations': [{
        'type': 'file',
        'file': {'content': [{
          'type': 'text',
          'text': 'Datasheet Solplanet ASW9100-S\n'
              'Potência máxima PV 16500Wp\nMPPT 80-560V/360V\n'
              'MPPT 3/1\nCorrente 20A/16A/20A\n'
              'Curto 28A/22.5A/28A\nPotência nominal 9100W\n'
              'Eficiência 97.7%, tensão máxima 600V\n'
              'Corrente máxima de saída 50A.',
        }]}
      }]}}
    ]});
    expect(text, contains('16500Wp'));
    expect(text, contains('20A/16A/20A'));
    expect(AiInverterRefinement.parsedPdfText({'choices': []}), isNull);
  });

  test('mescla sem sobrescrever valores já identificados e inclui variantes', () {
    final base = make([{
      'manufacturer': 'Solplanet', 'modelName': 'ASW9100-S',
      'nominalPowerKw': 9.1, 'mpptCount': 3,
    }]);
    final extra = make([{
      'manufacturer': 'Solplanet', 'modelName': 'ASW9100-S',
      'nominalPowerKw': 11, 'maxInputPowerWp': 16500,
      'mpptVoltageRange': '80V-560V/360V',
      'maxInputCurrentPerMppt': '20A/16A/20A',
    },{
      'manufacturer': 'Solplanet', 'modelName': 'ASW7300-S',
      'nominalPowerKw': 7.3, 'maxInputPowerWp': 13200,
    }]);
    expect(AiInverterRefinement.needsRefinement(base), isTrue);
    final merged = AiInverterRefinement.mergeMissing(base, extra);
    expect(merged.inverters, hasLength(2));
    expect(merged.inverters.first.nominalPowerKw, 9.1);
    expect(merged.inverters.first.maxInputPowerKw, 16.5);
    expect(merged.inverters.first.mpptInputCurrentsA, [20,16,20]);
    expect(merged.inverters.last.modelName, 'ASW7300-S');
    expect(merged.inverters.last.maxInputPowerKw, 13.2);
  });

  test('módulos isolados não ativam segunda leitura', () {
    final base = AiExtractionResultModel.fromJson({
      'modules': [{'manufacturer': 'BYD', 'modelName': 'BYD595'}],
      'inverters': [],
    });
    expect(AiInverterRefinement.needsRefinement(base), isFalse);
  });
}
