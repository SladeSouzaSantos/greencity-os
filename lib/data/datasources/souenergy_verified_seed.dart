import '../../domain/entities/inverter.dart';
import '../../domain/entities/pv_module.dart';
import '../../domain/enums/cell_technology.dart';
import '../../domain/enums/grid_connection.dart';
import '../../domain/enums/inverter_type.dart';

/// Seed incremental VALIDADO, não é o espelho completo da biblioteca.
/// Jetion: https://assistencia.souenergy.com.br/docs/download/285
/// AUXSOL: https://assistencia.souenergy.com.br/docs/download/360
/// Solplanet: PDF ASW7300-S/ASW9100-S anexado na conversa.
class SouEnergyVerifiedSeed {
  static List<PvModule> modules() {
    const wp = <int>[690, 695, 700, 705, 710, 715, 720];
    const vm = <double>[41.8, 41.95, 42.1, 42.25, 42.4, 42.55, 42.7];
    const im = <double>[16.51, 16.57, 16.63, 16.69, 16.75, 16.81, 16.87];
    const vo = <double>[49.70, 49.85, 50.00, 50.15, 50.30, 50.45, 50.60];
    const isc = <double>[17.31, 17.37, 17.43, 17.49, 17.55, 17.61, 17.67];
    const eff = <double>[22.2, 22.4, 22.5, 22.7, 22.9, 23.0, 23.2];
    return [
      for (var i = 0; i < wp.length; i++)
        PvModule(
          manufacturer: 'Jetion Solar',
          modelName: 'JT${wp[i]}SLk(B)',
          cellTechnology: CellTechnology.hjt,
          powerWp: wp[i], efficiency: eff[i],
          vOc: vo[i], iSc: isc[i], vMp: vm[i], iMp: im[i],
          length: 2384, width: 1303, weight: 37.3,
          tempCoefVoc: -0.24, tempCoefIsc: 0.040, tempCoefPmax: -0.24,
          isBifacial: true, isTier1: false,
          maxSystemVoltage: 1500, fuseCurrent: 35,
          physicalWarranty: 0, efficiencyWarranty: 0, efficiencyLoss: 0,
        ),
    ];
  }

  static List<Inverter> inverters() {
    const names = <String>[
      'ASN-3SL', 'ASN-3.3SL', 'ASN-3.6SL-G2', 'ASN-4SL-G2',
      'ASN-4.6SL-G2', 'ASN-5SL-G2', 'ASN-6SL-G2',
    ];
    const ac = <double>[3, 3.3, 3.6, 4, 4.6, 5, 6];
    const pv = <double>[6, 6.6, 7.2, 8, 9.2, 10, 12];
    const out = <double>[15, 15, 18, 20, 23, 25, 27.3];
    final result = <Inverter>[
      for (var i = 0; i < names.length; i++)
        Inverter(
          manufacturer: 'AUXSOL', modelName: names[i],
          inverterType: InverterType.string,
          gridConnection: GridConnection.monophasic, isHybrid: false,
          nominalPowerKw: ac[i], maxInputPowerKw: pv[i],
          maxEfficiency: 0.975, euroEfficiency: 0.970,
          mpptCount: i < 2 ? 1 : 2,
          maxInputVoltage: 550, nominalVoltageDc: 360,
          startVoltage: 40, minMpptVoltage: 40, maxMpptVoltage: 520,
          maxInputCurrentPerMppt: 18, maxShortCircuitCurrent: 22,
          maxOutputCurrent: out[i], nominalVoltageAc: 220,
          dimensions: '', weight: 0,
          minOperatingTemp: -30, maxOperatingTemp: 60,
          protectionDegree: 'IP66', warrantyYears: 0,
        ),
    ];
    // Assimetria ASW9100-S: 20/16/20 A e Isc 28/22.5/28 A.
    // O esquema Isar atual utiliza o menor limite por MPPT.
    for (final v in const [
      (name: 'ASW7300-S', ac: 7.3, pv: 13.2, output: 40.0),
      (name: 'ASW9100-S', ac: 9.1, pv: 16.5, output: 50.0),
    ]) {
      result.add(Inverter(
        manufacturer: 'Solplanet', modelName: v.name,
        inverterType: InverterType.string,
        gridConnection: GridConnection.monophasic, isHybrid: false,
        nominalPowerKw: v.ac, maxInputPowerKw: v.pv,
        maxEfficiency: 0.977, euroEfficiency: 0,
        mpptCount: 3, maxInputVoltage: 600, nominalVoltageDc: 360,
        startVoltage: 100, minMpptVoltage: 80, maxMpptVoltage: 560,
        maxInputCurrentPerMppt: 16, maxShortCircuitCurrent: 22.5,
        maxOutputCurrent: v.output, nominalVoltageAc: 220,
        dimensions: '503 x 435 x 183 mm', weight: 0,
        minOperatingTemp: -25, maxOperatingTemp: 60,
        protectionDegree: 'IP66', warrantyYears: 0,
      ));
    }
    return result;
  }
}
