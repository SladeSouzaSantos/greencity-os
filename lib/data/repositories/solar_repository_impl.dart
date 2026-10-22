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
    // 1. Convertemos a lista de ENTITIES em uma lista de MAPS (JSON) para a API
    final itemsPayload = items.map((item) => {
      'id_placa': item.id,
      'inclinacao_graus': item.inclination,
      'azimute_graus': item.azimuth,
      'albedo_solo': item.albedo,
      'distancia_centro_modulo_chao': item.distanceToGround,
      'tecnologia_celula': item.module.cellTechnology.apiKey,
      'is_bifacial': item.module.isBifacial,
      if (item.obstacle != null) 'config_obstaculo': {
        'altura_obstaculo': item.obstacle!.height,
        'distancia_obstaculo': item.obstacle!.distance,
        'referencia_azimutal_obstaculo': item.obstacle!.azimuthReference,
        'largura_obstaculo': item.obstacle!.width,
      }
    }).toList();

    // 2. Chamamos o Data Source
    return await remoteDataSource.getCalculateArray(
      latitude: latitude,
      longitude: longitude,
      items: itemsPayload,
    );
  }

  @override
  Future<List<int>> generateQuotePDF(SolarQuoteModel request) async {
    return await remoteDataSource.generateQuotePDF(request);
  }
}