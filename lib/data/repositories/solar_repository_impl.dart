import 'package:injectable/injectable.dart';

import '../../domain/entities/solar_engine_result.dart';
import '../../domain/entities/solar_scenario.dart';
import '../../domain/repositories/solar_repository.dart';
import '../datasources/solar_remote_data_source.dart';
import '../models/solar_quote_model.dart';

@LazySingleton(as: SolarRepository)
class SolarRepositoryImpl implements SolarRepository {
  final SolarRemoteDataSource remoteDataSource;

  SolarRepositoryImpl({required this.remoteDataSource});

  @override
  Future<SolarEngineResult> calculateArray({
    required double latitude,
    required double longitude,
    required List<SolarScenario> items,
  }) async {
    final itemsPayload = items.map(buildItemPayload).toList();

    // 2. Chamamos o Data Source
    return await remoteDataSource.getCalculateArray(
      latitude: latitude,
      longitude: longitude,
      items: itemsPayload,
    );
  }

  /// Contrato enviado ao HSP Simulator. Dimensões dos módulos em METROS.
  /// Fonte automática corresponde à opção padrão do dashboard.
  static Map<String, dynamic> buildItemPayload(SolarScenario item) {
    return {
      'id_placa': item.id,
      'inclinacao_graus': item.inclination,
      'azimute_graus': item.azimuth,
      'albedo_solo': item.albedo,
      'distancia_centro_modulo_chao': item.distanceToGround,
      'tecnologia_celula': item.module.cellTechnology.apiKey,
      'is_bifacial': item.module.isBifacial,
      'comprimento_modulo': item.module.length / 1000.0,
      'largura_modulo': item.module.width / 1000.0,
      'orientacao': item.orientation.label,
      'modelo_transposicao': 'perez',
      'fonte_dados': 'auto',
      if (item.obstacle != null)
        'config_obstaculo': {
          'altura_obstaculo': item.obstacle!.height,
          'distancia_obstaculo': item.obstacle!.distance,
          'referencia_azimutal_obstaculo': item.obstacle!.azimuthReference,
          'largura_obstaculo': item.obstacle!.width,
        },
    };
  }

  @override
  Future<List<int>> generateQuotePDF(SolarQuoteModel request) async {
    return await remoteDataSource.generateQuotePDF(request);
  }
}