import 'package:flutter_test/flutter_test.dart';
import 'package:greencity_os/domain/solar3d/electrical/solar3d_single_diode.dart';
import 'package:greencity_os/domain/solar3d/electrical/solar3d_circuit_solver.dart';

void main() {
  const physical = Solar3dDiodeCalibration(
    moduleModel: 'Synthetic 72-cell', source: 'Test-only reference parameters',
    seriesCells: 72, ilRefA: 10, ioRefA: 1e-10,
    rsOhm: .3, rshRefOhm: 800, aRefV: 2.5,
    alphaScAperC: .005,
  );
  Solar3dPhysicalModule module(String id, double irradiance,
      {bool bypass = false}) =>
      Solar3dPhysicalModule(panelId: id, substrings: [
        Solar3dPhysicalSubstring(
          id: '$id/c1', diode: physical.at(irradiance, 25),
          topologyVerified: bypass,
          bypassDropV: bypass ? .55 : null,
        ),
      ]);
  Solar3dPhysicalString string(String id, List<Solar3dPhysicalModule> modules) =>
      Solar3dPhysicalString(stringId: id, modules: modules);
  Solar3dPhysicalMppt tracker(List<Solar3dPhysicalString> strings,
      {double current = 25, double isc = 35}) =>
      Solar3dPhysicalMppt(
        inverterId: 'INV1', mpptIndex: 1, strings: strings,
        voltageMinV: 20, voltageMaxV: 600, startVoltageV: 20,
        operatingCurrentLimitA: current, shortCircuitCurrentLimitA: isc,
      );

  test('two modules in series share current and double voltage/power', () {
    final single = tracker([string('S1', [module('p1', 1000)])])
        .globalMaximum(samples: 96);
    final series = tracker([string('S1', [
      module('p1', 1000), module('p2', 1000),
    ])]).globalMaximum(samples: 96);
    expect(series.dcPowerW / single.dcPowerW, closeTo(2, .02));
    expect(series.mpp.currentA, closeTo(single.mpp.currentA, .05));
    expect(series.mpp.voltageV, closeTo(single.mpp.voltageV * 2, .3));
  });

  test('two parallel strings share voltage and add current', () {
    final single = tracker([string('S1', [module('p1', 1000)])])
        .globalMaximum(samples: 96);
    final parallel = tracker([
      string('S1', [module('p1', 1000)]),
      string('S2', [module('p2', 1000)]),
    ]).globalMaximum(samples: 96);
    expect(parallel.dcPowerW, closeTo(single.dcPowerW * 2, 1));
    expect(parallel.mpp.voltageV, closeTo(single.mpp.voltageV, .1));
  });

  test('explicit bypass rescues stronger substring under uneven irradiance', () {
    final plain = tracker([string('S1', [
      module('strong', 1000), module('weak', 200),
    ])]).globalMaximum(samples: 180);
    final bypassed = tracker([string('S1', [
      module('strong', 1000, bypass: true),
      module('weak', 200, bypass: true),
    ])]).globalMaximum(samples: 180);
    expect(bypassed.dcPowerW, greaterThan(plain.dcPowerW));
    expect(bypassed.mpp.voltageV, greaterThan(20));
  });

  test('unverified substring topology and duplicate IDs are blocked', () {
    final bad = Solar3dPhysicalModule(panelId: 'p1', substrings: [
      Solar3dPhysicalSubstring(id: 'a', diode: physical.at(900, 25)),
      Solar3dPhysicalSubstring(id: 'b', diode: physical.at(900, 25)),
    ]);
    expect(bad.validate, throwsFormatException);
    final duplicate = tracker([
      string('S1', [module('p1', 1000)]),
      string('S2', [module('p1', 1000)]),
    ]);
    expect(duplicate.validate, throwsFormatException);
  });

  test('Isc absolute violation rejects, Imp operational cap clips', () {
    final strings = [
      string('S1', [module('p1', 1000)]),
      string('S2', [module('p2', 1000)]),
    ];
    expect(() => tracker(strings, isc: 12).globalMaximum(samples: 96),
        throwsFormatException);
    final clipped = tracker(strings, current: 5)
        .globalMaximum(samples: 96);
    final full = tracker(strings).globalMaximum(samples: 96);
    expect(clipped.dcPowerW, lessThan(full.dcPowerW));
    expect(clipped.currentClipped, true);
  });

  test('different inverters with MPPT 1 remain isolated', () {
    final one = tracker([string('S1', [module('p1', 1000)])]);
    final two = Solar3dPhysicalMppt(
      inverterId: 'INV2', mpptIndex: 1,
      strings: [string('S1', [module('p2', 600)])],
      voltageMinV: 20, voltageMaxV: 600, startVoltageV: 20,
      operatingCurrentLimitA: 25, shortCircuitCurrentLimitA: 35,
    );
    final a = one.globalMaximum(samples: 96).dcPowerW;
    final b = two.globalMaximum(samples: 96).dcPowerW;
    expect(a, greaterThan(b));
    expect(a, greaterThan(0));
  });
}
