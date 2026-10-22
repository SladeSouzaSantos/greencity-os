import '../../domain/entities/solar_climate.dart';

class SolarClimateModel extends SolarClimate {
  SolarClimateModel({
    required super.tempMaxMonthly,
    required super.tempAvgMonthly,
    required super.tempMinMonthly,
  });

  factory SolarClimateModel.fromJson(Map<String, dynamic> json) {
    return SolarClimateModel(
      tempMaxMonthly: List<double>.from(json['temp_max_mensal'].map((x) => x.toDouble())),
      tempAvgMonthly: List<double>.from(json['temp_avg_mensal'].map((x) => x.toDouble())),
      tempMinMonthly: List<double>.from(json['temp_min_mensal'].map((x) => x.toDouble())),
    );
  }
}