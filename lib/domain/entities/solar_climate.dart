class SolarClimate {
  final List<double> tempMaxMonthly;
  final List<double> tempAvgMonthly;
  final List<double> tempMinMonthly;

  SolarClimate({
    required this.tempMaxMonthly,
    required this.tempAvgMonthly,
    required this.tempMinMonthly,
  });

  @override
  String toString() {
    return 'SolarClimate(tempMax: $tempMaxMonthly, tempAvg: $tempAvgMonthly, tempMin: $tempMinMonthly)';
  }
}