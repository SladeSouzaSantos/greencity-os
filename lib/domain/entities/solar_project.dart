import 'hsp.dart';
import 'solar_system.dart';
import 'solar_climate.dart';
import '../solar3d/solar3d_optical_correction.dart';

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

  /// Applied optical-only estimate. The designer restores this from a
  /// versioned, scene-bound local cache after explicit user confirmation.
  /// It is NOT a certified electrical yield or approved project output.
  Solar3dOpticalCorrection? opticalCorrection;

  bool get hasAppliedOpticalCorrection =>
      opticalCorrection?.isValidFor(systems) ?? false;

  SolarProject({
    required this.clientName,
    this.document,
    required this.city,
    required this.state,
    required this.latitude,
    required this.longitude,
    required this.monthlyConsumption,
    List<SolarSystem> systems = const [],
    this.useSafetyMargin = false,
  }) : systems = List<SolarSystem>.of(systems);
  
  double get effectiveConsumption => 
      useSafetyMargin ? monthlyConsumption * 1.25 : monthlyConsumption;
  
  double get totalProjectPowerWp => 
      systems.fold(0, (sum, sys) => sum + (sys.totalSystemPower/1000));
  
  List<int> _monthlyGeneration({required bool applyOptical}) {
    final totals = List<int>.filled(12, 0);
    final tMaxList = climate?.tempMaxMonthly;
    final applied = applyOptical && hasAppliedOpticalCorrection
        ? opticalCorrection : null;
    for (final system in systems) {
      for (var month = 0; month < 12; month++) {
        totals[month] += system.calculateSystemGenerationForMonth(
          month,
          tMaxList,
          opticalRetentionByMppt:
              applied?.retentionBySystemMppt[system.id],
          opticalMpptGroups:
              applied?.groupsBySystemMppt[system.id],
        );
      }
    }
    return totals;
  }

  List<int> get baselineMonthlyGeneration =>
      _monthlyGeneration(applyOptical: false);

  List<int> get totalMonthlyGeneration =>
      _monthlyGeneration(applyOptical: true);

  int get baselineAverageAnnualGeneration {
    final totals = baselineMonthlyGeneration;
    return totals.reduce((sum, value) => sum + value) ~/ 12;
  }

  int get totalAverageAnnualGeneration {
    final totals = totalMonthlyGeneration;
    return totals.reduce((sum, value) => sum + value) ~/ 12;
  }
  
  @override
  String toString() {
    return 'SolarProject(clientName: $clientName, document: $document, city: $city, state: $state, '
           'lat: $latitude, lon: $longitude, consumption: $monthlyConsumption, '
           'safetyMargin: $useSafetyMargin, effective: $effectiveConsumption)';
  }
}