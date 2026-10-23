import 'package:flutter_test/flutter_test.dart';
import 'package:greencity_os/data/models/ai_extraction_result_model.dart';

void main() {
  test('extrai múltiplos modelos distintos do mesmo datasheet', () {
    final result = AiExtractionResultModel.fromJson({
      'modules': [
        {
          'manufacturer': 'DAH Solar',
          'modelName': 'DHN-700',
          'powerWp': 700,
          'efficiency': 22.5,
          'cellTechnology': 'TOPCON',
          'vOc': 47.6,
          'iSc': 18.4,
          'vMp': 39.8,
          'iMp': 17.5,
          'isBifacial': true,
        },
        {
          'manufacturer': 'DAH Solar',
          'modelName': 'DHN-705',
          'powerWp': '705',
          'efficiency': '22,7',
          'vOc': '47,8',
          'iSc': 18.5,
          'vMp': 40.2,
          'iMp': 17.54,
        },
      ],
      'inverters': [
        {
          'manufacturer': 'Hoymiles',
          'modelName': 'HMS-1600',
          'nominalPowerKw': 1.6,
          'mpptCount': 4,
          'maxEfficiency': 96.7,
        },
        {
          'manufacturer': 'Hoymiles',
          'modelName': 'HMS-1800',
          'nominalPowerKw': 1.8,
          'mpptCount': 4,
        },
      ],
    });
    expect(result.modules, hasLength(2));
    expect(result.inverters, hasLength(2));
    expect(result.modules[1].powerWp, 705);
    expect(result.modules[1].efficiency, 22.7);
    expect(result.modules[1].isBifacial, false);
    expect(result.inverters[0].maxEfficiency, 96.7);
  });

  test('campos ausentes ficam opcionais para revisão', () {
    final data = AiExtractionResultModel.fromJson({
      'modules': [
        {'manufacturer': 'Marca', 'modelName': 'Modelo'}
      ],
      'inverters': [],
    });
    expect(data.modules.single.powerWp, 0);
    expect(data.modules.single.length, isNull);
    expect(data.modules.single.tempCoefVoc, isNull);
  });
}
