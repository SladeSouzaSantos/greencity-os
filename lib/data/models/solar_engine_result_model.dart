import '../../domain/entities/solar_engine_result.dart';
import 'solar_climate_model.dart';
import 'solar_scenario_result_model.dart';

class SolarEngineResultModel extends SolarEngineResult {
  SolarEngineResultModel({
    required super.totalItems,
    required super.climate,
    required super.results,
  });

  factory SolarEngineResultModel.fromJson(Map<String, dynamic> json) {
    return SolarEngineResultModel(
      climate: SolarClimateModel.fromJson(json['clima']),
      totalItems: json['total_placas'] ?? 0,
      results: (json['resultados'] as List)
          .map((item) => SolarScenarioResultModel.fromJson(item))
          .toList(),
    );
  }
}