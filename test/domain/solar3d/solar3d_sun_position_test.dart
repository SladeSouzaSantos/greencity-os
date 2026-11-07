import 'package:flutter_test/flutter_test.dart';
import 'package:greencity_os/domain/solar3d/solar3d_plan_factory.dart';
import 'package:greencity_os/domain/solar3d/solar3d_sun_position.dart';
import 'package:greencity_os/domain/entities/inverter.dart';
import 'package:greencity_os/domain/entities/pv_module.dart';
import 'package:greencity_os/domain/entities/solar_array.dart';
import 'package:greencity_os/domain/entities/solar_scenario.dart';
import 'package:greencity_os/domain/entities/solar_system.dart';
import 'package:greencity_os/domain/enums/cell_technology.dart';
import 'package:greencity_os/domain/enums/inverter_type.dart';
import 'package:greencity_os/domain/enums/grid_connection.dart';

void main() {
  test('Sol em Greenwich no equinócio: norte/leste e ciclo diário', () {
    final early = Solar3dSunPosition.calculate(
      utc: DateTime.utc(2026, 3, 20, 6),
      latitude: 0, longitude: 0);
    final noon = Solar3dSunPosition.calculate(
      utc: DateTime.utc(2026, 3, 20, 12),
      latitude: 0, longitude: 0);
    final evening = Solar3dSunPosition.calculate(
      utc: DateTime.utc(2026, 3, 20, 18),
      latitude: 0, longitude: 0);
    final night = Solar3dSunPosition.calculate(
      utc: DateTime.utc(2026, 3, 20, 0),
      latitude: 0, longitude: 0);
    expect(early.azimuthDegrees, inInclusiveRange(75, 105));
    expect(noon.elevationDegrees, greaterThan(85));
    expect(evening.azimuthDegrees, inInclusiveRange(255, 285));
    expect(night.aboveHorizon, isFalse);
  });

  test('Natal usa longitude e latitude do projeto, mudando sombras com data', () {
    Solar3dSunPosition at(int month) => Solar3dSunPosition.calculate(
      utc: DateTime.utc(2026, month, 21, 15),
      latitude: -5.79448, longitude: -35.21101);
    final june = at(6);
    final december = at(12);
    expect(june.aboveHorizon, isTrue);
    expect(december.aboveHorizon, isTrue);
    expect((june.elevationDegrees - december.elevationDegrees).abs(),
      greaterThan(15));
    final midnight = Solar3dSunPosition.calculate(
      utc: DateTime.utc(2026, 6, 21, 3),
      latitude: -5.79448, longitude: -35.21101);
    expect(midnight.aboveHorizon, isFalse);
  });

  test('Centro da placa é exatamente a distância declarada até o chão', () {
    final module = PvModule(
      manufacturer: 'TESTE', modelName: '500',
      cellTechnology: CellTechnology.topcon, powerWp: 500,
      efficiency: 20, length: 2000, width: 1000, weight: 22,
      vOc: 49, iSc: 13, vMp: 41, iMp: 12,
      tempCoefVoc: -.3, tempCoefIsc: .04,
      tempCoefPmax: -.3, isBifacial: false,
    );
    final inverter = Inverter(
      manufacturer: 'TESTE', modelName: 'INV',
      inverterType: InverterType.string, isHybrid: false,
      nominalPowerKw: 5, maxInputPowerKw: 10, maxEfficiency: .98,
      euroEfficiency: .97, mpptCount: 2,
      maxInputVoltage: 600, nominalVoltageDc: 380, startVoltage: 40,
      minMpptVoltage: 50, maxMpptVoltage: 550,
      maxInputCurrentPerMppt: 20, maxShortCircuitCurrent: 30,
      gridConnection: GridConnection.monophasic, maxOutputCurrent: 30,
      nominalVoltageAc: 220, dimensions: '', weight: 12,
      minOperatingTemp: -20, maxOperatingTemp: 60,
      protectionDegree: 'IP65',
    );
    final scene = Solar3dPlanFactory.fromSystems([
      SolarSystem(id: 'SYS', name: 'Teste', inverter: inverter, arrays: [
        SolarArray(mpptIndex: 1, solarScenario: SolarScenario(
          id: 'A', city: 'Natal', state: 'RN',
          inclination: 30, azimuth: 0,
          distanceToGround: .18,
          module: module, quantityPvModule: 2,
        )),
      ]),
    ]);
    expect(scene.objects.length, 2);
    for (final panel in scene.objects) {
      expect(panel.center.y, .18);
      expect(panel.tiltDegrees, 30);
    }
  });
}
