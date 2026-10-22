import '../../domain/entities/solar_scenario_result.dart';

class SolarScenarioResultModel extends SolarScenarioResult {
  SolarScenarioResultModel({
    required super.id,
    required super.averageHspReal,
    required super.monthlyHspReal,
    required super.averageHspReference,
    required super.monthlyHspReference,
    required super.shadowLossPercentage,
  });

  factory SolarScenarioResultModel.fromJson(Map<String, dynamic> json) {
    final kwhData = json['kWh/m²/dia'];
    
    return SolarScenarioResultModel(
      id: json['id_placa'],
      averageHspReal: (kwhData['real']['media'] as num).toDouble(),
      monthlyHspReal: List<double>.from(kwhData['real']['mensal']),
      averageHspReference: (kwhData['referencia']['media_sem_sombra'] as num).toDouble(),
      monthlyHspReference: List<double>.from(kwhData['referencia']['mensal_sem_sombra']),
      shadowLossPercentage: json['perda_sombreamento_estimada'],
    );
  }
}
