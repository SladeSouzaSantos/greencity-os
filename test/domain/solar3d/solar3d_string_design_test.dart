import 'package:flutter_test/flutter_test.dart';
import 'package:greencity_os/domain/entities/inverter.dart';
import 'package:greencity_os/domain/entities/solar_system.dart';
import 'package:greencity_os/domain/enums/inverter_type.dart';
import 'package:greencity_os/domain/enums/grid_connection.dart';
import 'package:greencity_os/domain/solar3d/solar3d_geometric_shading.dart';
import 'package:greencity_os/domain/solar3d/electrical/solar3d_string_design.dart';

void main() {
  final inverter = Inverter(
    manufacturer: 'TEST', modelName: 'INV2',
    inverterType: InverterType.string,
    nominalPowerKw: 5, maxInputPowerKw: 8,
    maxEfficiency: .98, euroEfficiency: .97, mpptCount: 2,
    maxInputVoltage: 600, nominalVoltageDc: 300, startVoltage: 40,
    minMpptVoltage: 40, maxMpptVoltage: 500,
    maxInputCurrentPerMppt: 20, maxShortCircuitCurrent: 30,
    gridConnection: GridConnection.monophasic,
    maxOutputCurrent: 25, nominalVoltageAc: 220,
    dimensions: '', weight: 20, minOperatingTemp: -20,
    maxOperatingTemp: 60, protectionDegree: 'IP65',
    isHybrid: false,
  );
  const panels = [
    Solar3dObject(
      id: 'INV1/1/1', kind: Solar3dObjectKind.panel,
      center: Solar3dVector(0, 1, 0),
      width: 1, depth: 2, height: .04, mpptIndex: 1, stringId: 'S1',
    ),
    Solar3dObject(
      id: 'INV1/1/2', kind: Solar3dObjectKind.panel,
      center: Solar3dVector(1, 1, 0),
      width: 1, depth: 2, height: .04, mpptIndex: 1, stringId: 'S1',
    ),
    Solar3dObject(
      id: 'INV2/1/1', kind: Solar3dObjectKind.panel,
      center: Solar3dVector(2, 1, 0),
      width: 1, depth: 2, height: .04, mpptIndex: 1, stringId: 'S1',
    ),
  ];
  final scene = Solar3dScene(panels);
  final systems = [
    SolarSystem(id: 'INV1', name: 'Primeiro', inverter: inverter),
    SolarSystem(id: 'INV2', name: 'Segundo', inverter: inverter),
  ];
  Solar3dStringSpec spec(String inv, List<String> panels) =>
      Solar3dStringSpec(
        inverterId: inv, stringId: 'S1', mpptIndex: 1,
        panelIdsInSeries: panels,
      );

  test('series order is explicit; MPPT 1 of two inverters stays separate',
      () {
    final design = Solar3dElectricalStringDesign([
      spec('INV1', ['INV1/1/1', 'INV1/1/2']),
      spec('INV2', ['INV2/1/1']),
    ]);
    design.validate(scene: scene, systems: systems);
    final copied = Solar3dElectricalStringDesign.fromJson(design.toJson());
    copied.validate(scene: scene, systems: systems);
    expect(copied.strings.first.panelIdsInSeries,
        ['INV1/1/1', 'INV1/1/2']);
  });

  test('must reject incomplete or duplicate physical module connections',
      () {
    expect(() => Solar3dElectricalStringDesign([
      spec('INV1', ['INV1/1/1']),
      spec('INV2', ['INV2/1/1']),
    ]).validate(scene: scene, systems: systems), throwsFormatException);
    expect(() => Solar3dElectricalStringDesign([
      spec('INV1', ['INV1/1/1', 'INV1/1/1', 'INV1/1/2']),
      spec('INV2', ['INV2/1/1']),
    ]).validate(scene: scene, systems: systems), throwsFormatException);
    expect(() => Solar3dElectricalStringDesign([
      spec('INV1', ['INV2/1/1']),
      spec('INV2', ['INV1/1/1', 'INV1/1/2']),
    ]).validate(scene: scene, systems: systems), throwsFormatException);
  });
}
