import 'package:flutter_test/flutter_test.dart';
import 'package:greencity_os/domain/entities/inverter.dart';
import 'package:greencity_os/domain/entities/pv_module.dart';
import 'package:greencity_os/domain/entities/solar_array.dart';
import 'package:greencity_os/domain/entities/solar_scenario.dart';
import 'package:greencity_os/domain/entities/solar_system.dart';
import 'package:greencity_os/domain/enums/cell_technology.dart';
import 'package:greencity_os/domain/enums/inverter_type.dart';
import 'package:greencity_os/domain/enums/grid_connection.dart';
import 'package:greencity_os/domain/solar3d/solar3d_geometric_shading.dart';
import 'package:greencity_os/domain/solar3d/solar3d_plan_factory.dart';

void main() {
  test('Converte quantidade Isar para placas físicas com IDs próprios', () {
    final module = PvModule(
      manufacturer: 'EXEMPLO', modelName: '500Wp',
      cellTechnology: CellTechnology.topcon, powerWp: 500,
      efficiency: 20, length: 2000, width: 1000, weight: 25,
      vOc: 49, iSc: 13, vMp: 41, iMp: 12,
      tempCoefVoc: -0.3, tempCoefIsc: 0.045,
      tempCoefPmax: -0.3, isBifacial: false,
    );
    final inverter = Inverter(
      manufacturer: 'EXEMPLO', modelName: 'INV',
      inverterType: InverterType.string, isHybrid: false,
      nominalPowerKw: 5, maxInputPowerKw: 10, maxEfficiency: 0.98,
      euroEfficiency: 0.97, mpptCount: 2,
      maxInputVoltage: 600, nominalVoltageDc: 380,
      startVoltage: 40, minMpptVoltage: 50, maxMpptVoltage: 550,
      maxInputCurrentPerMppt: 20, maxShortCircuitCurrent: 30,
      gridConnection: GridConnection.monophasic, maxOutputCurrent: 30,
      nominalVoltageAc: 220, dimensions: '', weight: 12,
      minOperatingTemp: -20, maxOperatingTemp: 60,
      protectionDegree: 'IP65',
    );
    final array = SolarArray(
      mpptIndex: 2,
      solarScenario: SolarScenario(
        id: 'A01', city: 'Natal', state: 'RN',
        inclination: 15, azimuth: 0,
        module: module, quantityPvModule: 3,
      ),
    );
    final scene = Solar3dPlanFactory.fromSystems([
      SolarSystem(id: 'S01', name: 'Sistema 1', inverter: inverter,
        arrays: [array]),
    ]);
    expect(scene.objects.length, 3);
    expect(scene.objects.map((panel) => panel.id).toSet().length, 3);
    for (final panel in scene.objects) {
      expect(panel.kind, Solar3dObjectKind.panel);
      expect(panel.mpptIndex, 2);
      expect(panel.stringId, isNull);
      expect(panel.width, 1);
      expect(panel.depth, 2);
    }
  });
}
