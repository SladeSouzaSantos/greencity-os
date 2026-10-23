import 'package:flutter_test/flutter_test.dart';
import 'package:greencity_os/data/models/ai_numeric_value_parser.dart';
import 'package:greencity_os/data/models/ai_extraction_result_model.dart';

void main() {
  test('converte unidades explícitas W/Wp → kW sem aproximar intervalos', () {
    expect(AiNumericValueParser.powerKw('13200 Wp STC'), 13.2);
    expect(AiNumericValueParser.powerKw('13.200 Wp'), 13.2);
    expect(AiNumericValueParser.powerKw('16,5 kWp'), 16.5);
    expect(AiNumericValueParser.powerKw(13200, rawIsWatts: true), 13.2);
    expect(AiNumericValueParser.powerKw('7.3 kW'), 7.3);
    expect(AiNumericValueParser.number('97,7 %'), 97.7);
    expect(AiNumericValueParser.number('80 V - 560 V'), isNull);
    expect(AiNumericValueParser.number('< 18 kg'), isNull);
  });

  test('interpreta tensão MPPT composta e número 3/1', () {
    expect(AiNumericValueParser.mpptRange('80 V - 560 V / 360 V'), [80, 560]);
    expect(AiNumericValueParser.nominalFromMpptRange(
        '80 V - 560 V / 360 V'), 360);
    expect(AiNumericValueParser.mpptCount('3/1'), 3);
    expect(AiNumericValueParser.mpptCount('2 (1 / 1)'), 2);
    expect(AiNumericValueParser.mpptCount('3 MPPTs'), 3);
  });

  test('não soma MPPTs diferentes: preserva vetor e usa mínimo conservador', () {
    final inv = AiExtractedInverter.fromJson({
      'manufacturer': 'Solplanet',
      'modelName': 'ASW9100-S',
      'nominalPowerKw': '9100 W',
      'maxInputPowerWp': '16500 Wp',
      'mpptVoltageRange': '80 V - 560 V / 360 V',
      'maxInputVoltage': '600 V',
      'mpptCount': '3/1',
      'maxInputCurrentPerMppt': '20 A / 16 A / 20 A',
      'maxShortCircuitCurrent': '28 A / 22.5 A / 28 A',
      'maxEfficiency': '97.7%',
    });
    expect(inv.nominalPowerKw, 9.1);
    expect(inv.maxInputPowerKw, 16.5);
    expect(inv.nominalVoltageDc, 360);
    expect(inv.maxMpptVoltage, 560);
    expect(inv.mpptCount, 3);
    expect(inv.mpptInputCurrentsA, [20, 16, 20]);
    expect(inv.mpptShortCircuitCurrentsA, [28, 22.5, 28]);
    expect(inv.maxInputCurrentPerMppt, 16);
    expect(inv.maxShortCircuitCurrent, 22.5);
    expect(inv.hasAsymmetricMpptCurrents, isTrue);
    expect(inv.maxEfficiency, 97.7);
  });

  test('não inventa corrente quando há faixa ou limite máximo incerto', () {
    expect(AiNumericValueParser.currentList('18-32 A'), isNull);
    expect(AiNumericValueParser.number('≤ 20 A'), isNull);
  });
}
