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

  test('aceita anotações de PDF curtas com dados úteis', () {
    final content = AiInverterRefinement.parsedPdfText({
      'choices': [
        {'message': {'annotations': [
          {'type': 'file', 'file': {'content': [
            {'type': 'text', 'text': '| Operating Temperature | -40°C-+85°C |'},
          ]}},
        ]}},
      ]
    });
    expect(content, contains('-40°C-+85°C'));
  });

  test('preserva o início e fim de OCR com mais de 18 mil caracteres', () {
    final source = 'CABECALHO_STC\n${List.filled(20000, 'x').join()}\nTABELA_FINAL';
    final text = AiInverterRefinement.parsedPdfText({
      'choices': [{'message': {'annotations': [{
        'type': 'file',
        'file': {'content': [{'type': 'text', 'text': source}]},
      }]}}],
    });
    expect(text, contains('CABECALHO_STC'));
    expect(text, contains('TABELA_FINAL'));
    expect(text!.length, greaterThan(18000));
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

  test('refino usa o menor limite se primeira leitura ignorou MPPT central', () {
    final first = make([{
      'manufacturer': 'Solplanet', 'modelName': 'ASW9100-S',
      'maxInputCurrentPerMppt': 20,
      'maxShortCircuitCurrent': 28,
    }]);
    final corrected = make([{
      'manufacturer': 'Solplanet', 'modelName': 'ASW9100-S',
      'maxInputCurrentPerMppt': '20 A/16 A/20 A',
      'maxShortCircuitCurrent': '28 A/22.5 A/28 A',
    }]);
    final value = AiInverterRefinement.mergeMissing(
      first, corrected,
    ).inverters.single;
    expect(value.mpptInputCurrentsA, [20,16,20]);
    expect(value.maxInputCurrentPerMppt, 16);
    expect(value.maxShortCircuitCurrent, 22.5);
  });

  test('módulos isolados não ativam segunda leitura', () {
    final base = AiExtractionResultModel.fromJson({
      'modules': [{'manufacturer': 'BYD', 'modelName': 'BYD595'}],
      'inverters': [],
    });
    expect(AiInverterRefinement.needsRefinement(base), isFalse);
  });
}
