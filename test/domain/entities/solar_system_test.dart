import 'package:flutter_test/flutter_test.dart';
import 'package:greencity_os/domain/entities/inverter.dart';
import 'package:greencity_os/domain/entities/pv_module.dart';
import 'package:greencity_os/domain/entities/solar_array.dart';
import 'package:greencity_os/domain/entities/solar_scenario.dart';
import 'package:greencity_os/domain/entities/solar_scenario_result.dart';
import 'package:greencity_os/domain/entities/solar_system.dart';
import 'package:greencity_os/domain/enums/cell_technology.dart';
import 'package:greencity_os/domain/enums/grid_connection.dart';
import 'package:greencity_os/domain/enums/inverter_type.dart';

void main() {
  final inverter = Inverter(
    manufacturer: 'Teste',
    modelName: 'Inversor de teste',
    inverterType: InverterType.string,
    nominalPowerKw: 3,
    maxInputPowerKw: 5,
    maxEfficiency: 0.98,
    euroEfficiency: 0.97,
    mpptCount: 2,
    maxInputVoltage: 600,
    nominalVoltageDc: 350,
    startVoltage: 100,
    minMpptVoltage: 90,
    maxMpptVoltage: 500,
    maxInputCurrentPerMppt: 30,
    maxShortCircuitCurrent: 40,
    gridConnection: GridConnection.monophasic,
    maxOutputCurrent: 16,
    nominalVoltageAc: 220,
    dimensions: 'teste',
    weight: 10,
    minOperatingTemp: -20,
    maxOperatingTemp: 60,
    protectionDegree: 'IP65',
    isHybrid: false,
  );

  PvModule makeModule(String model, int power, double coef) => PvModule(
    manufacturer: 'Teste',
    modelName: model,
    cellTechnology: CellTechnology.topcon,
    length: 2384,
    width: 1303,
    weight: 30,
    powerWp: power,
    efficiency: 22,
    vOc: 48,
    iSc: 17,
    vMp: 40,
    iMp: 16,
    tempCoefVoc: -0.25,
    tempCoefIsc: 0.046,
    tempCoefPmax: coef,
    isBifacial: false,
  );

  SolarArray array(String id, double inclination, int power, double hsp) {
    return SolarArray(
      solarScenario: SolarScenario(
        id: id,
        city: 'Natal',
        state: 'RN',
        inclination: inclination,
        azimuth: 0,
        module: makeModule(id, power, -0.29),
      ),
      solarScenarioResult: SolarScenarioResult(
        id: id,
        averageHspReal: hsp,
        monthlyHspReal: List.filled(12, hsp),
        averageHspReference: hsp,
        monthlyHspReference: List.filled(12, hsp),
        shadowLossPercentage: '0.0%',
        horizontalHsp: 5.796,
      ),
    );
  }

  test('temperaturas baixas preservam ganho elétrico positivo', () {
    final system = SolarSystem(
      id: '2',
      name: 'teste térmico',
      inverter: inverter,
      arrays: [array('frio', 15, 710, 6.45)],
    );
    final normal = system.calculateSystemGenerationForMonth(0, null);
    final frio = system.calculateSystemGenerationForMonth(
      0, List.filled(12, -15.0),
    );
    expect(frio, greaterThan(normal));
  });

  test('POA do arranjo não é nivelada pelo menor HSP no MPPT', () {
    final a = array('a', 15, 710, 6.45);
    final b = array('b', 55, 615, 5.18);
    final system = SolarSystem(
      id: '1',
      name: 'teste',
      inverter: inverter,
      arrays: [a, b],
    );
    final together = system.calculateSystemGenerationForMonth(0, null);
    expect(system.getEffectiveHspForArray(a), 6.45);
    expect(system.getEffectiveHspForArray(b), 5.18);
    expect(system.needsMpptElectricalReview(a), isTrue);

    // Sem modelo elétrico de mismatch, mudar o agrupamento não inventa perda.
    b.mpptIndex = 2;
    expect(system.calculateSystemGenerationForMonth(0, null), together);
    expect(system.needsMpptElectricalReview(a), isFalse);
  });
}
