import 'package:flutter_test/flutter_test.dart';
import 'package:greencity_os/data/models/ai_extraction_result_model.dart';

/// Gabaritos de dados publicados em datasheets da biblioteca Sou Energy.
/// São contratos de conversão, NÃO testes de precisão de inferência remota.
/// As fichas originais não são copiadas para o repositório.
void main() {
  test('AUXSOL série ASN (3–6)SL-G2: sete modelos e CC recomendada', () {
    // https://assistencia.souenergy.com.br/docs/download/360
    const names = [
      'ASN-3SL', 'ASN-3.3SL', 'ASN-3.6SL-G2', 'ASN-4SL-G2',
      'ASN-4.6SL-G2', 'ASN-5SL-G2', 'ASN-6SL-G2',
    ];
    const ac = [3.0, 3.3, 3.6, 4.0, 4.6, 5.0, 6.0];
    const dc = [6.0, 6.6, 7.2, 8.0, 9.2, 10.0, 12.0];
    final result = AiExtractionResultModel.fromJson({
      'modules': [],
      'inverters': List.generate(names.length, (i) => {
        'manufacturer': 'AUXSOL',
        'modelName': names[i],
        'nominalPowerKw': ac[i],
        'maxInputPowerKw': dc[i],
        'mpptCount': i < 2 ? 1 : 2,
        'maxInputVoltage': '550 V',
        'mpptVoltageRange': '40-520 V/360V',
        'startVoltage': '40 V',
      }),
    });
    expect(result.inverters, hasLength(7));
    for (var i = 0; i < names.length; i++) {
      expect(result.inverters[i].modelName, names[i]);
      expect(result.inverters[i].nominalPowerKw, ac[i]);
      expect(result.inverters[i].maxInputPowerKw, dc[i]);
      expect(result.inverters[i].maxMpptVoltage, 520);
      expect(result.inverters[i].mpptCount, i < 2 ? 1 : 2);
    }
  });

  test('Solplanet Série S: cinco colunas e correntes diferentes', () {
    // https://assistencia.souenergy.com.br/docs/download/124
    // Esta revisão traz 12k/15k Wp, diferente da ficha ASW antiga
    // enviada pelo usuário (13,2k/16,5k Wp). Não misturar revisões.
    const names = [
      'ASW7300-S', 'ASW7500-S', 'ASW8000-S',
      'ASW9100-S', 'ASW10000-S',
    ];
    const ac = [7.3, 7.5, 8.0, 9.1, 10.0];
    final result = AiExtractionResultModel.fromJson({
      'modules': [],
      'inverters': List.generate(names.length, (i) => {
        'manufacturer': 'Solplanet',
        'modelName': names[i],
        'nominalAcPowerW': ac[i] * 1000,
        'maxInputPowerWp': i < 3 ? 12000 : 15000,
        'mpptCount': '3/1',
        'maxInputVoltage': 600,
        'mpptVoltageRange': '80 V - 560 V / 360 V',
        'maxInputCurrentPerMppt': i < 3
            ? '16 A / 16 A / 16 A' : '20 A / 16 A / 20 A',
        'maxShortCircuitCurrent': i < 3
            ? '22.5 A / 22.5 A / 22.5 A' : '28 A / 22.5 A / 28 A',
        'maxEfficiency': '97.7%',
      }),
    });
    expect(result.inverters, hasLength(5));
    for (var i = 0; i < names.length; i++) {
      final inv = result.inverters[i];
      expect(inv.modelName, names[i]);
      expect(inv.nominalPowerKw, ac[i]);
      expect(inv.maxInputPowerKw, i < 3 ? 12 : 15);
      expect(inv.mpptCount, 3);
      expect(inv.mpptInputCurrentsA, i < 3 ? [16,16,16] : [20,16,20]);
      expect(inv.maxInputCurrentPerMppt, 16);
    }
  });

  test('SolaX X1-Hybrid G4: intervalo MPPT, tensão e número de rastreadores', () {
    // https://assistencia.souenergy.com.br/docs/download/41
    final result = AiExtractionResultModel.fromJson({
      'modules': [],
      'inverters': ['X1-HYBRID-3.0-D', 'X1-HYBRID-7.5-M'].map((model) => {
        'manufacturer': 'SolaX',
        'modelName': model,
        'nominalPowerKw': model.contains('3.0') ? 3.0 : 7.5,
        'mpptCount': '2 (1 / 1)', // modelo deve preferir valor explícito 2
        'maxInputVoltage': '600 V',
        'mpptVoltageRange': '70 ~ 550 V / 360 V',
        'inverterType': 'string',
        'isHybrid': true,
      }).toList(),
    });
    expect(result.inverters, hasLength(2));
    expect(result.inverters.last.maxInputVoltage, 600);
    expect(result.inverters.last.minMpptVoltage, 70);
    expect(result.inverters.last.maxMpptVoltage, 550);
    expect(result.inverters.last.nominalVoltageDc, 360);
    expect(result.inverters.last.isHybrid, isTrue);
  });

  test('Leapton S1X: tensão nominal, faixa e fabricantes preservados', () {
    // https://assistencia.souenergy.com.br/docs/download/299
    final result = AiExtractionResultModel.fromJson({
      'modules': [],
      'inverters': [5.0, 7.5].map((p) => {
        'manufacturer': 'Leapton',
        'modelName': p == 5.0 ? 'S1X-5K1P-Y' : 'S1X-7.5K1P-Y',
        'nominalPowerKw': p,
        'maxInputVoltage': '600 V',
        'mpptVoltageRange': '40 ~ 560 V / 360 V',
        'maxInputCurrentPerMppt': '20 A',
      }).toList(),
    });
    expect(result.inverters, hasLength(2));
    expect(result.inverters.last.nominalPowerKw, 7.5);
    expect(result.inverters.last.maxMpptVoltage, 560);
    expect(result.inverters.last.maxInputCurrentPerMppt, 20);
  });
}
