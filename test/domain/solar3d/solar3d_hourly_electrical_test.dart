import 'package:flutter_test/flutter_test.dart';
import 'package:greencity_os/domain/solar3d/electrical/solar3d_single_diode.dart';
import 'package:greencity_os/domain/solar3d/electrical/solar3d_circuit_solver.dart';
import 'package:greencity_os/domain/solar3d/electrical/solar3d_hourly_electrical.dart';

void main() {
  const cal = Solar3dDiodeCalibration(
    moduleModel: 'Test module', source: 'Synthetic numeric fixture',
    seriesCells: 72, ilRefA: 10, ioRefA: 1e-10,
    rsOhm: .3, rshRefOhm: 800, aRefV: 2.5,
    alphaScAperC: .005,
  );
  Solar3dPhysicalMppt mppt(String id, double irradiance) =>
      Solar3dPhysicalMppt(
        inverterId: id, mpptIndex: 1,
        strings: [
          Solar3dPhysicalString(stringId: 'S1', modules: [
            Solar3dPhysicalModule(panelId: '$id/module1', substrings: [
              Solar3dPhysicalSubstring(
                id: 'cellgroup', diode: cal.at(irradiance, 25)),
            ]),
          ]),
        ],
        voltageMinV: 15, voltageMaxV: 100, startVoltageV: 15,
        operatingCurrentLimitA: 15, shortCircuitCurrentLimitA: 20,
      );
  const inverter = Solar3dInverterElectricalSpec(
    inverterId: 'INV1', provenance: 'Synthetic test-only efficiency curve',
    nominalAcW: 400, maxDcW: 500, startupDcW: 20,
    nominalAcVoltageV: 220,
    dcResistanceOhm: .15, acResistanceOhm: .2, acPhases: 1,
    efficiencyCurve: [
      Solar3dEfficiencyPoint(0, 0),
      Solar3dEfficiencyPoint(.2, .85),
      Solar3dEfficiencyPoint(.5, .95),
      Solar3dEfficiencyPoint(1, .97),
      Solar3dEfficiencyPoint(1.5, .97),
    ],
  );

  test('efficiency interpolates, DC/AC clipping and I2R are separate', () {
    expect(inverter.efficiencyForDc(200), closeTo(.95, .001));
    final normal = inverter.convert([
      const Solar3dMpptElectricalResult(
        mpp: Solar3dIvPoint(50, 7), uncurtailedPowerW: 350,
        currentClipped: false, iscA: 10,
      ),
    ]);
    expect(normal.rawDcW, 350);
    expect(normal.dcCableLossW, closeTo(7.35, 1e-6));
    expect(normal.acAfterCableW, lessThan(normal.acBeforeCableW));
    expect(normal.acAfterCableW, greaterThan(0));
    final clipped = inverter.convert([
      const Solar3dMpptElectricalResult(
        mpp: Solar3dIvPoint(80, 10), uncurtailedPowerW: 800,
        currentClipped: false, iscA: 12,
      ),
    ]);
    expect(clipped.inverterInputW, 500);
    expect(clipped.dcClippingW, greaterThan(0));
    expect(clipped.acBeforeCableW, lessThanOrEqualTo(400));
  });

  test('paired same-weather hours report physical DC/AC deltas only', () {
    final frames = [
      for (var n = 0; n < 2; n++)
        Solar3dElectricalHourInput(
          startUtc: DateTime.utc(2024, 1, 2, 10 + n),
          weatherSource: 'NASA POWER reference XYZ',
          referenceByInverter: {'INV1': [mppt('INV1', 900)]},
          shadedByInverter: {'INV1': [mppt('INV1', 600)]},
        ),
    ];
    final result = Solar3dElectricalWindowSimulator.calculate(
      hours: frames, inverters: {'INV1': inverter},
    );
    expect(result.hours.length, 2);
    expect(result.referenceAcWh, greaterThan(result.shadedAcWh));
    expect(result.referenceAcWhMonthly[0], result.referenceAcWh);
    expect(result.completeUtcYear, false);
    expect(result.annualReferenceAcKwh, isNull);
    expect(result.electricallyCalibrated, false);
  });

  test('different time basis or incomplete MPPT is rejected', () {
    final a = Solar3dElectricalHourInput(
      startUtc: DateTime.utc(2024, 3, 1),
      weatherSource: 'NASA', referenceByInverter: {
        'INV1': [mppt('INV1', 800)],
      }, shadedByInverter: {
        'INV1': [mppt('INV1', 400)],
      },
    );
    final bad = Solar3dElectricalHourInput(
      startUtc: DateTime.utc(2024, 3, 1, 2),
      weatherSource: 'NASA', referenceByInverter: a.referenceByInverter,
      shadedByInverter: a.shadedByInverter,
    );
    expect(() => Solar3dElectricalWindowSimulator.calculate(
      hours: [a, bad], inverters: {'INV1': inverter},
    ), throwsFormatException);
    expect(() => Solar3dElectricalWindowSimulator.calculate(
      hours: [a], inverters: {'INV2': inverter},
    ), throwsFormatException);
    expect(() => Solar3dElectricalWindowSimulator.calculate(
      hours: List.generate(25, (_) => a),
      inverters: {'INV1': inverter},
    ), throwsFormatException);
  });
}
