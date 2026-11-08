import 'package:flutter_test/flutter_test.dart';
import 'package:greencity_os/domain/solar3d/electrical/solar3d_single_diode.dart';

void main() {
  const data = Solar3dDiodeCalibration(
    moduleModel: 'Synthetic 72-cell module',
    source: 'Numerical test fixture, NOT measured equipment',
    seriesCells: 72, ilRefA: 10, ioRefA: 1e-10,
    rsOhm: .3, rshRefOhm: 800, aRefV: 2.5,
    alphaScAperC: .005,
  );

  test('physical endpoints, monotonic current, MPP, inverse root', () {
    final s = data.at(1000, 25);
    final voc = s.openCircuitVoltage;
    final isc = s.shortCircuitCurrent;
    expect(voc, greaterThan(50));
    expect(isc, closeTo(10, .1));
    expect(s.currentAtVoltage(voc), 0);
    expect(s.voltageAtCurrent(0), closeTo(voc, 1e-6));
    var previous = double.infinity;
    for (var i = 0; i <= 80; i++) {
      final p = s.pointAtVoltage(voc * i / 80);
      expect(p.currentA, lessThanOrEqualTo(previous + 1e-8));
      expect(p.currentA, greaterThanOrEqualTo(0));
      previous = p.currentA;
    }
    final peak = s.maximumPowerPoint();
    expect(peak.powerW, greaterThan(0));
    expect(peak.voltageV, inInclusiveRange(0, voc));
    expect(peak.currentA, inInclusiveRange(0, isc));
    expect(s.voltageAtCurrent(peak.currentA),
        closeTo(peak.voltageV, 1e-5));
  });

  test('irradiance and temperature sensitivity', () {
    final high = data.at(1000, 25), low = data.at(500, 25);
    expect(low.shortCircuitCurrent, lessThan(high.shortCircuitCurrent));
    expect(low.maximumPowerPoint().powerW,
        lessThan(high.maximumPowerPoint().powerW));
    expect(data.at(0, 25).maximumPowerPoint().powerW, 0);
    expect(data.at(1000, -10).openCircuitVoltage,
        greaterThan(data.at(1000, 65).openCircuitVoltage));
  });

  test('rejects unknown physical parameters and environmental invalidity', () {
    expect(() => const Solar3dDiodeCalibration(
      moduleModel: 'A', source: '', seriesCells: 72,
      ilRefA: 10, ioRefA: 1e-10, rsOhm: .3,
      rshRefOhm: 800, aRefV: 2.5, alphaScAperC: .005,
    ).validate(), throwsFormatException);
    expect(() => data.at(-1, 25), throwsFormatException);
    expect(() => data.at(1000, 900), throwsFormatException);
    expect(data.independentlyVerified, false);
  });
}
