class SolarScenarioResult {
  final String id;
  final double averageHspReal;
  final List<double> monthlyHspReal;
  final double averageHspReference;
  final List<double> monthlyHspReference;
  final String shadowLossPercentage;

  // Campos opcionais disponíveis no detalhamento do HSP Simulator.
  final double? horizontalHsp;
  final double? frontalHsp;
  final double? rearEquivalentHsp;
  final String? dataSource;
  final String? transpositionModel;

  SolarScenarioResult({
    required this.id,
    required this.averageHspReal,
    required this.monthlyHspReal,
    required this.averageHspReference,
    required this.monthlyHspReference,
    required this.shadowLossPercentage,
    this.horizontalHsp,
    this.frontalHsp,
    this.rearEquivalentHsp,
    this.dataSource,
    this.transpositionModel,
  });

  @override
  String toString() {
    return 'SolarScenarioResult(id: $id, realAvg: $averageHspReal, loss: $shadowLossPercentage)';
  }  
}