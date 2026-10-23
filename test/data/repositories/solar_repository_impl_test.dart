import 'package:flutter_test/flutter_test.dart';
import 'package:greencity_os/data/repositories/solar_repository_impl.dart';
import 'package:greencity_os/domain/entities/pv_module.dart';
import 'package:greencity_os/domain/entities/solar_scenario.dart';
import 'package:greencity_os/domain/enums/cell_technology.dart';
import 'package:greencity_os/domain/enums/module_orientation.dart';

void main() {
  test('envia geometria real, orientação e tecnologia ao HSP', () {
    final module = PvModule(
      manufacturer: 'DAH Solar',
      modelName: 'DHN-66Y18/DG-710',
      cellTechnology: CellTechnology.topcon,
      length: 2384,
      width: 1303,
      weight: 37.3,
      powerWp: 710,
      efficiency: 22.86,
      vOc: 48,
      iSc: 18.61,
      vMp: 40.4,
      iMp: 17.57,
      tempCoefVoc: -0.25,
      tempCoefIsc: 0.046,
      tempCoefPmax: -0.29,
      isBifacial: true,
    );
    final scenario = SolarScenario(
      id: 'painel-1',
      city: 'Natal',
      state: 'RN',
      inclination: 15,
      azimuth: 0,
      module: module,
      orientation: ModuleOrientation.landscape,
    );
    final payload = SolarRepositoryImpl.buildItemPayload(scenario);
    expect(payload['comprimento_modulo'], 2.384);
    expect(payload['largura_modulo'], 1.303);
    expect(payload['orientacao'], 'Paisagem');
    expect(payload['is_bifacial'], isTrue);
    expect(payload['tecnologia_celula'], 'TOPCON');
    expect(payload['modelo_transposicao'], 'perez');
    expect(payload['fonte_dados'], 'auto');
    expect(payload.containsKey('config_obstaculo'), isFalse);
  });
}
