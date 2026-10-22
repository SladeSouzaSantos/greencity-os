class Hsp {
  final double annualAverage;
  final List<double> monthlyValues;

  Hsp({
    required this.annualAverage,
    required this.monthlyValues,
  });

  @override
  String toString() {
    return 'Hsp(average: $annualAverage, monthly: $monthlyValues)';
  }
}