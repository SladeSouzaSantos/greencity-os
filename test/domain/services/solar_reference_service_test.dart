import 'package:flutter_test/flutter_test.dart';
import 'package:greencity_os/domain/entities/solar_climate.dart';
import 'package:greencity_os/domain/entities/solar_engine_result.dart';
import 'package:greencity_os/domain/entities/solar_project.dart';
import 'package:greencity_os/domain/entities/solar_scenario_result.dart';
import 'package:greencity_os/domain/services/solar_reference_service.dart';

void main() {
  final project = SolarProject(
    clientName: 'Teste',
    city: 'Natal',
    state: 'RN',
    latitude: -5.8125,
    longitude: -35.1875,
    monthlyConsumption: 500,
  );
  final climate = SolarClimate(
    tempMaxMonthly: List.filled(12, 31),
    tempAvgMonthly: List.filled(12, 28),
    tempMinMonthly: List.filled(12, 24),
  );
  SolarEngineResult response(String id, double hsp, {double? ghi}) =>
      SolarEngineResult(
        totalItems: 1,
        climate: climate,
        results: [
          SolarScenarioResult(
            id: id,
            averageHspReal: hsp,
            monthlyHspReal: List.filled(12, hsp),
            averageHspReference: hsp,
            monthlyHspReference: List.filled(12, hsp),
            shadowLossPercentage: '0.0%',
            horizontalHsp: ghi,
            dataSource: 'NASA POWER',
          ),
        ],
      );

  test('HSP horizontal permanece estável após arranjos 15° e 55°', () {
    SolarReferenceService.updateProjectReference(
      project, response('placeholder', 5.796),
    );
    expect(project.referenceHspHorizontal!.annualAverage, 5.796);
    SolarReferenceService.updateProjectReference(
      project, response('arranjo-15', 6.45, ghi: 5.796),
    );
    SolarReferenceService.updateProjectReference(
      project, response('arranjo-55', 5.18, ghi: 5.796),
    );
    expect(project.referenceHspHorizontal!.annualAverage, 5.796);
    expect(project.referenceHspHorizontal!.monthlyValues.first, 5.796);
    expect(project.hspDataSource, 'NASA POWER');
  });

  test('fallback antigo não substitui GHI por HSP inclinado', () {
    SolarReferenceService.updateProjectReference(
      project, response('arranjo-55', 5.18),
    );
    expect(project.referenceHspHorizontal!.annualAverage, 5.796);
  });
}
