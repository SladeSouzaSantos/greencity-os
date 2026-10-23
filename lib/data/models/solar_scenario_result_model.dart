import '../../domain/entities/solar_scenario_result.dart';

class SolarScenarioResultModel extends SolarScenarioResult {
  SolarScenarioResultModel({
    required super.id,
    required super.averageHspReal,
    required super.monthlyHspReal,
    required super.averageHspReference,
    required super.monthlyHspReference,
    required super.shadowLossPercentage,
    super.horizontalHsp,
    super.frontalHsp,
    super.rearEquivalentHsp,
    super.dataSource,
    super.transpositionModel,
  });

  factory SolarScenarioResultModel.fromJson(Map<String, dynamic> json) {
    final kwhData = json['kWh/m²/dia'] as Map<String, dynamic>;
    final details = json['detalhes'] is Map<String, dynamic>
        ? json['detalhes'] as Map<String, dynamic>
        : <String, dynamic>{};
    
    return SolarScenarioResultModel(
      id: json['id_placa'],
      averageHspReal: (kwhData['real']['media'] as num).toDouble(),
      monthlyHspReal: (kwhData['real']['mensal'] as List).map((value) => (value as num).toDouble()).toList(),
      averageHspReference: (kwhData['referencia']['media_sem_sombra'] as num).toDouble(),
      monthlyHspReference: (kwhData['referencia']['mensal_sem_sombra'] as List).map((value) => (value as num).toDouble()).toList(),
      shadowLossPercentage: json['perda_sombreamento_estimada'] as String,
      horizontalHsp: (details['hsp_horizontal'] as num?)?.toDouble(),
      frontalHsp: (details['hsp_frontal'] as num?)?.toDouble(),
      rearEquivalentHsp: (details['hsp_traseira_equivalente'] as num?)?.toDouble(),
      dataSource: details['fonte'] as String?,
      transpositionModel: details['modelo_transposicao'] as String?,
    );
  }
}
