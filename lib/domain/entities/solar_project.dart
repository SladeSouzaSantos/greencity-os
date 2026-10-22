import 'hsp.dart';
import 'solar_system.dart';
import 'solar_climate.dart';

class SolarProject {
  String clientName;
  String? document;
  String city;
  String state;
  double latitude;
  double longitude;
  double monthlyConsumption;
  bool useSafetyMargin;
  List<SolarSystem> systems;
  SolarClimate? climate;
  Hsp? referenceHspHorizontal;

  SolarProject({
    required this.clientName,
    this.document,
    required this.city,
    required this.state,
    required this.latitude,
    required this.longitude,
    required this.monthlyConsumption,
    this.systems = const [],
    this.useSafetyMargin = false,
  });
  
  double get effectiveConsumption => 
      useSafetyMargin ? monthlyConsumption * 1.25 : monthlyConsumption;
  
  double get totalProjectPowerWp => 
      systems.fold(0, (sum, sys) => sum + (sys.totalSystemPower/1000));
  
  List<int> get totalMonthlyGeneration {
    List<int> totals = List.filled(12, 0);

    List<double>? tMaxList = climate?.tempMaxMonthly;
    
    for (var system in systems) {
      for (int mes = 0; mes < 12; mes++) {
        totals[mes] += system.calculateSystemGenerationForMonth(mes, tMaxList);
      }
    }
    return totals;
  }

  int get totalAverageAnnualGeneration {
    if (systems.isEmpty) return 0;
    
    List<double>? tMaxList = climate?.tempMaxMonthly;

    double totalAnual = 0.0;
    
    for (var system in systems) {
      for (int mes = 0; mes < 12; mes++) {
        totalAnual += system.calculateSystemGenerationForMonth(mes, tMaxList);
      }
    }
        
    return (totalAnual / 12).floor(); 
  }
  
  @override
  String toString() {
    return 'SolarProject(clientName: $clientName, document: $document, city: $city, state: $state, '
           'lat: $latitude, lon: $longitude, consumption: $monthlyConsumption, '
           'safetyMargin: $useSafetyMargin, effective: $effectiveConsumption)';
  }
}