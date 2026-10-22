import 'solar_array.dart';
import 'inverter.dart';

class SolarSystem {
  final String id;
  final String name;
  final Inverter inverter;
  final List<SolarArray> arrays;

  SolarSystem({
    required this.id,
    required this.name,
    required this.inverter,
    this.arrays = const [],
  });
  
  int calculateSystemGenerationForMonth(int monthIndex, List<double>? monthlyTmax) {
    if (arrays.isEmpty || arrays.any((a) => a.solarScenarioResult == null)) return 0;

    // Lógica de Temperatura
    double fatorTemperatura = 1.0; 
    if (monthlyTmax != null && monthlyTmax.isNotEmpty) {
      // Pega a temperatura máxima do mês atual
      double tMax = monthlyTmax[monthIndex];
      double temperaturaReal = tMax + 29;
      double temperaturaCalculada = temperaturaReal - 25;
      
      // ATENÇÃO: Pegamos o tempCoefPmax da PRIMEIRA placa do sistema (assumindo que são parecidas)
      // Se você quiser ser mais preciso, pode calcular o fator por array.
      double tempCoefPmax = arrays.first.solarScenario.module.tempCoefPmax; 
      
      fatorTemperatura = 1 + ((temperaturaCalculada * tempCoefPmax) / 100);
    }

    // Fator Fixo de Desempenho (Sujidade, Cabos, Mismatch não-MPPT)
    final double fatorDesempenho = 0.9 * 0.97 * 0.98 * 0.99 * 0.98 * 0.99;
    final double diasNoMes = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31][monthIndex].toDouble();
    final double eficienciaInversor = inverter.maxEfficiency;

    double totalGeneration = 0.0;
    Map<int, List<SolarArray>> mpptGroups = {};
    for (var array in arrays) {
      mpptGroups.putIfAbsent(array.mpptIndex, () => []).add(array);
    }

    for (var group in mpptGroups.values) {
      // Nivelamento do HSP pelo menor do MPPT
      double minHspInMppt = group
          .map((a) => a.solarScenarioResult!.monthlyHspReal[monthIndex])
          .reduce((curr, next) => curr < next ? curr : next);
      
      // Potência total do MPPT em kW!
      double pKw = group.fold(0, (sum, array) => sum + array.totalPowerWp) / 1000.0;

      totalGeneration += (pKw * minHspInMppt * diasNoMes * fatorDesempenho * fatorTemperatura * eficienciaInversor);
    }
    return totalGeneration.ceil();
  }

  double getEffectiveHspForArray(SolarArray array) {
    if (arrays.isEmpty || array.solarScenarioResult == null) return 0.0;
    
    final mpptArrays = arrays.where((a) => a.mpptIndex == array.mpptIndex).toList();
    
    // Se algum array do MPPT ainda não foi calculado, retornamos 0
    if (mpptArrays.any((a) => a.solarScenarioResult == null)) return 0.0;

    // Retorna o menor HSP entre todos os arranjos deste MPPT
    return mpptArrays
        .map((a) => a.solarScenarioResult!.averageHspReal)
        .reduce((curr, next) => curr < next ? curr : next);
  }

  double get totalSystemPower => 
      arrays.fold(0, (sum, array) => sum + array.totalPowerWp);
}