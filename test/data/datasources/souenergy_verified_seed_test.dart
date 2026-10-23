import 'package:flutter_test/flutter_test.dart';
import 'package:greencity_os/data/datasources/souenergy_verified_seed.dart';
import 'package:greencity_os/data/repositories/equipment_catalog.dart';

void main() {
  test('Jetion STC: sete módulos com modelos distintos', () {
    final modules = SouEnergyVerifiedSeed.modules();
    expect(modules, hasLength(7));
    expect(modules.map((m) => m.powerWp), [690,695,700,705,710,715,720]);
    expect(modules.first.modelName, 'JT690SLk(B)');
    expect(modules.last.iSc, 17.67);
    expect(modules.map((m) =>
        EquipmentCatalog.key(m.manufacturer, m.modelName)).toSet(), hasLength(7));
  });

  test('AUXSOL sete + Solplanet dois preservam ficha técnica', () {
    final list = SouEnergyVerifiedSeed.inverters();
    expect(list, hasLength(9));
    expect(list.where((v) => v.manufacturer == 'AUXSOL'), hasLength(7));
    final sol = list.where((v) => v.manufacturer == 'Solplanet').toList();
    expect(sol.map((v) => v.modelName), ['ASW7300-S','ASW9100-S']);
    expect(sol.first.maxInputPowerKw, 13.2);
    expect(sol.last.maxInputPowerKw, 16.5);
    expect(sol.last.mpptCount, 3);
    expect(sol.last.maxInputCurrentPerMppt, 16);
    expect(sol.last.maxShortCircuitCurrent, 22.5);
    expect(sol.last.weight, 0);
  });
}
