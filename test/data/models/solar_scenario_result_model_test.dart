import 'package:flutter_test/flutter_test.dart';
import 'package:greencity_os/data/models/solar_scenario_result_model.dart';

void main() {
  Map<String, dynamic> response({Map<String, dynamic>? details}) => {
    'id_placa': 'arranjo-1',
    'kWh/m²/dia': {
      'real': {'media': 6.45, 'mensal': List.filled(12, 6)},
      'referencia': {
        'media_sem_sombra': 6.45,
        'mensal_sem_sombra': List.filled(12, 6.45),
      },
    },
    'perda_sombreamento_estimada': '0.0%',
    if (details != null) 'detalhes': details,
  };

  test('separa GHI horizontal da POA e ganho traseiro', () {
    final result = SolarScenarioResultModel.fromJson(response(details: {
      'hsp_horizontal': 5.796,
      'hsp_frontal': 5.47,
      'hsp_traseira_equivalente': 0.98,
      'fonte': 'NASA POWER',
      'modelo_transposicao': 'perez',
    }));
    expect(result.horizontalHsp, 5.796);
    expect(result.averageHspReal, 6.45);
    expect(result.frontalHsp, 5.47);
    expect(result.rearEquivalentHsp, 0.98);
    expect(result.dataSource, 'NASA POWER');
    expect(result.transpositionModel, 'perez');
    expect(result.monthlyHspReal.first, 6.0);
  });

  test('aceita resposta da API antiga sem detalhes', () {
    final result = SolarScenarioResultModel.fromJson(response());
    expect(result.horizontalHsp, isNull);
    expect(result.frontalHsp, isNull);
    expect(result.dataSource, isNull);
    expect(result.averageHspReal, 6.45);
  });
}
