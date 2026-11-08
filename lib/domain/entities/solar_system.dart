import 'solar_array.dart';
import 'inverter.dart';
import '../solar3d/solar3d_optical_correction.dart';

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
  
  int calculateSystemGenerationForMonth(
    int monthIndex,
    List<double>? monthlyTmax, {
    Map<int, List<double>>? opticalRetentionByMppt,
    Map<int, Solar3dMpptOpticalGroup>? opticalMpptGroups,
  }) {
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

    // A 3D study can assign individual modules to a different MPPT of
    // THIS inverter. Use its hypothetical group powers + baseline HSP
    // rather than silently applying a new MPPT ratio to old array wiring.
    // Production wiring in SolarArray is not modified.
    if (opticalMpptGroups != null) {
      final accountedPower = opticalMpptGroups.values.fold<double>(
          0, (sum, group) => sum + group.powerWp);
      if ((accountedPower - totalSystemPower).abs() > 1e-5) {
        throw const FormatException(
          'Potência 3D não corresponde ao inversor de referência');
      }
      for (final entry in opticalMpptGroups.entries) {
        final mppt = entry.key, group = entry.value;
        if (mppt < 1 || mppt > inverter.mpptCount ||
            group.baselineMonthlyHsp.length != 12 ||
            group.retentionMonthly.length != 12) {
          throw const FormatException('Grupo MPPT óptico inválido');
        }
        final ratio = group.retentionMonthly[monthIndex];
        final baseHsp = group.baselineMonthlyHsp[monthIndex];
        if (!ratio.isFinite || ratio < 0 || ratio > 1 ||
            !baseHsp.isFinite || baseHsp < 0) {
          throw const FormatException('Irradiância MPPT óptica inválida');
        }
        totalGeneration += (group.powerWp / 1000.0 * baseHsp * ratio *
          diasNoMes * fatorDesempenho * fatorTemperatura * eficienciaInversor);
      }
      return totalGeneration.ceil();
    }

    for (final mppt in mpptGroups.entries) {
      final group = mppt.value;
      // Nivelamento do HSP pelo menor do MPPT
      double minHspInMppt = group
          .map((a) => a.solarScenarioResult!.monthlyHspReal[monthIndex])
          .reduce((curr, next) => curr < next ? curr : next);
      
      // Potência total do MPPT em kW!
      double pKw = group.fold(0, (sum, array) => sum + array.totalPowerWp) / 1000.0;

      // Optional 3D optical retention acts ONCE on the baseline MPPT
      // production. Never apply individual plate losses by multiplying all
      // percentages: each MPPT receives a single power/POA-weighted ratio.
      final opticalFactor = opticalRetentionByMppt?[mppt.key]?[monthIndex] ?? 1.0;
      if (!opticalFactor.isFinite || opticalFactor < 0 ||
          opticalFactor > 1) {
        throw const FormatException('Correção óptica por MPPT inválida');
      }
      totalGeneration += (pKw * minHspInMppt * opticalFactor *
          diasNoMes * fatorDesempenho * fatorTemperatura *
          eficienciaInversor);
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