import 'solar_climate.dart';
import 'solar_scenario_result.dart';

class SolarEngineResult {
  final SolarClimate climate; 
  final int totalItems;
  final List<SolarScenarioResult> results;

  SolarEngineResult({required this.totalItems, required this.results, required this.climate});

  @override
  String toString() {
    return 'SolarEngineResult(\n'
           '  totalItems: $totalItems,\n'
           '  climate: ${climate.toString()},\n'
           '  results: ${results.map((e) => e.toString()).toList()}\n'
           ')';
  }
}