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
  
  /// Estimativa simplificada: cada arranjo utiliza sua própria POA mensal,
  /// potência e coeficiente térmico. Mismatch elétrico e clipping NÃO são
  /// modelados: o usuário é alertado quando há misturas no mesmo MPPT.
  int calculateSystemGenerationForMonth(int monthIndex, List<double>? monthlyTmax) {
    if (arrays.isEmpty || arrays.any((a) => a.solarScenarioResult == null)) {
      return 0;
    }
    if (monthIndex < 0 || monthIndex >= 12) {
      throw RangeError.range(monthIndex, 0, 11, 'monthIndex');
    }

    const fatorDesempenho = 0.9 * 0.97 * 0.98 * 0.99 * 0.98 * 0.99;
    const diasNoMes = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];

    double totalGeneration = 0.0;
    for (final array in arrays) {
      final hsp = array.solarScenarioResult!.monthlyHspReal[monthIndex];
      final double tempMax =
          monthlyTmax != null && monthlyTmax.length > monthIndex
              ? monthlyTmax[monthIndex]
              : 25.0 - 29.0;
      final double temperaturaCelula = tempMax + 29;
      final coef = array.solarScenario.module.tempCoefPmax;
      final fatorTemperatura =
          (1 + ((temperaturaCelula - 25) * coef / 100)).clamp(0.0, 1.0);

      totalGeneration += (array.totalPowerWp / 1000.0) *
          hsp *
          diasNoMes[monthIndex] *
          fatorDesempenho *
          fatorTemperatura *
          inverter.maxEfficiency;
    }
    return totalGeneration.ceil();
  }

  /// Não reduz irradiância pela menor POA de um MPPT.
  /// As perdas por incompatibilidade elétrica exigem modelagem de strings/I-V.
  double getEffectiveHspForArray(SolarArray array) =>
      array.solarScenarioResult?.averageHspReal ?? 0.0;

  /// Um mesmo MPPT com configurações distintas exige validação elétrica.
  /// Este método é um aviso, NÃO uma estimativa percentual de mismatch.
  bool needsMpptElectricalReview(SolarArray candidate) {
    final peers = arrays.where((a) => a.mpptIndex == candidate.mpptIndex).toList();
    if (peers.length < 2) return false;
    final first = peers.first.solarScenario;
    return peers.any((array) {
      final current = array.solarScenario;
      return current.inclination != first.inclination ||
          current.azimuth != first.azimuth ||
          current.module.manufacturer != first.module.manufacturer ||
          current.module.modelName != first.module.modelName ||
          current.quantityPvModule != first.quantityPvModule;
    });
  }

  double get totalSystemPower => 
      arrays.fold(0, (sum, array) => sum + array.totalPowerWp);
}