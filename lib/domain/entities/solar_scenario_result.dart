class SolarScenarioResult {
  final String id;
  final double averageHspReal;
  final List<double> monthlyHspReal;
  final double averageHspReference;
  final List<double> monthlyHspReference;
  final String shadowLossPercentage;

  SolarScenarioResult({
    required this.id,
    required this.averageHspReal,
    required this.monthlyHspReal,
    required this.averageHspReference,
    required this.monthlyHspReference,
    required this.shadowLossPercentage,
  });

  @override
  String toString() {
    return 'SolarScenarioResult(id: $id, realAvg: $averageHspReal, loss: $shadowLossPercentage)';
  }  
}