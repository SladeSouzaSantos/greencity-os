import 'solar_scenario.dart';
import 'solar_scenario_result.dart';

class SolarArray {
  final SolarScenario solarScenario;
  int mpptIndex;
  SolarScenarioResult? solarScenarioResult;

  SolarArray({
    this.solarScenarioResult,
    this.mpptIndex = 1,
    required this.solarScenario
  });

  int get totalPowerWp => solarScenario.module.powerWp * solarScenario.quantityPvModule;

  double getMonthlyProduction(int monthIndex) {
    if (solarScenarioResult == null) return 0.0;
    // Potência * HSP Mensal * 30 dias * Eficiência (PR) / 1000
    return (totalPowerWp * solarScenarioResult!.monthlyHspReal[monthIndex] * 30 * 0.77) / 1000;
  }
}