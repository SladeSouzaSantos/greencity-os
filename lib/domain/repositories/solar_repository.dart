import '../../data/models/solar_quote_model.dart';
import '../entities/solar_scenario.dart';
import '../entities/solar_engine_result.dart';

abstract class SolarRepository {
  Future<SolarEngineResult> calculateArray({
    required double latitude,
    required double longitude,
    required List<SolarScenario> items,
  });

  Future<List<int>> generateQuotePDF(SolarQuoteModel request);
}