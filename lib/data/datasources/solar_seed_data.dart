import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import '../../domain/entities/pv_module.dart';
import '../../domain/entities/inverter.dart';
import '../../domain/enums/cell_technology.dart';
import '../../domain/enums/grid_connection.dart';
import '../../domain/enums/inverter_type.dart';

class SolarSeedData {
  static Future<void> seed(Isar isar) async {
    final moduleCount = await isar.pvModules.count();
    final inverterCount = await isar.inverters.count();

    if (moduleCount == 0 || inverterCount == 0) {
      await isar.writeTxn(() async {
        
        // ==========================================
        //         MÓDULOS FOTOVOLTAICOS
        // ==========================================
        if (moduleCount == 0) {
          final modules = [
            // --- TCL (Mantido o existente) ---
            PvModule(
              manufacturer: 'TCL', modelName: 'HSM-ND66-GR615',
              cellTechnology: CellTechnology.topcon, powerWp: 615, efficiency: 22.8,
              vOc: 46.2, iSc: 16.71, vMp: 38.6, iMp: 15.94,
              tempCoefVoc: -0.24, tempCoefIsc: 0.045, tempCoefPmax: -0.28,
              length: 2382, width: 1134, weight: 32.6, isBifacial: true,
            ),

            // --- RENEPV TOPCon Bifacial ---
            PvModule(
              manufacturer: 'RENEPV', modelName: 'ZY620G12RNHB-132',
              cellTechnology: CellTechnology.topcon, powerWp: 620, efficiency: 22.9,
              vOc: 47.98, iSc: 16.30, vMp: 40.39, iMp: 15.35,
              tempCoefVoc: -0.25, tempCoefIsc: 0.05, tempCoefPmax: -0.30,
              length: 2382, width: 1134, weight: 32.0, isBifacial: true,
            ),

            // --- Intelbras N-Type Bifacial ---
            PvModule(
              manufacturer: 'Intelbras',
              modelName: 'EMSS-585B N-TYPE',
              cellTechnology: CellTechnology.topcon, // Tecnologia N-Type
              powerWp: 585,
              efficiency: 22.65,
              vOc: 51.68,
              iSc: 14.42,
              vMp: 42.77,
              iMp: 13.68,
              tempCoefVoc: -0.26,
              tempCoefIsc: 0.045,
              tempCoefPmax: -0.29,
              length: 2278,
              width: 1134,
              weight: 31.2,
              isBifacial: true,
            ),

            // --- MAXEON PERFORMANCE 6 (SPR-P6-XXX-UPP) ---
            ..._buildMaxeonP6Series(),

            // --- DAH SOLAR TOPCon (DHN-66Y18/DG-XXX) ---
            ..._buildDahSolarSeries(),

            // --- ASTRONERGY ASTRO N7 (CHSM66RN(DG)/F-BH) ---
            ..._buildAstronergyN7Series(),
          ];
          await isar.pvModules.putAll(modules);
        }

        // ==========================================
        //               INVERSORES
        // ==========================================
        if (inverterCount == 0) {
          final inverters = [
            // --- AUXSOL (Mantido o existente) ---
            Inverter(
              manufacturer: 'AUXSOL', modelName: 'ASN-10SL', inverterType: InverterType.string,
              isHybrid: false, gridConnection: GridConnection.monophasic,
              nominalPowerKw: 10.0, maxInputPowerKw: 20.0, maxEfficiency: 0.981, euroEfficiency: 0.976,
              mpptCount: 2, maxInputVoltage: 600.0, nominalVoltageDc: 380.0, startVoltage: 40.0,
              minMpptVoltage: 40.0, maxMpptVoltage: 550.0, maxInputCurrentPerMppt: 32.0,
              maxShortCircuitCurrent: 40.0, maxOutputCurrent: 45.5, nominalVoltageAc: 220.0,
              dimensions: '355 x 427 x 172 mm', weight: 14.5, protectionDegree: 'IP65',
              warrantyYears: 10, minOperatingTemp: -25.0, maxOperatingTemp: 60.0
            ),

            // --- SOLPLANET SÉRIE ASW-S (Monofásicos) ---
            Inverter(
              manufacturer: 'Solplanet', modelName: 'ASW6000-S', inverterType: InverterType.string,
              isHybrid: false, gridConnection: GridConnection.monophasic,
              nominalPowerKw: 6.0, maxInputPowerKw: 9.0, maxEfficiency: 0.977, euroEfficiency: 0.973,
              mpptCount: 3, maxInputVoltage: 600.0, nominalVoltageDc: 360.0, startVoltage: 80.0,
              minMpptVoltage: 80.0, maxMpptVoltage: 560.0, maxInputCurrentPerMppt: 16.0,
              maxShortCircuitCurrent: 22.5, maxOutputCurrent: 30.0, nominalVoltageAc: 220.0,
              dimensions: '503 x 435 x 183 mm', weight: 18.0, protectionDegree: 'IP66',
              warrantyYears: 10, minOperatingTemp: -25.0, maxOperatingTemp: 60.0
            ),
            Inverter(
              manufacturer: 'Solplanet', modelName: 'ASW8000-S', inverterType: InverterType.string,
              isHybrid: false, gridConnection: GridConnection.monophasic,
              nominalPowerKw: 8.0, maxInputPowerKw: 12.0, maxEfficiency: 0.977, euroEfficiency: 0.973,
              mpptCount: 3, maxInputVoltage: 600.0, nominalVoltageDc: 360.0, startVoltage: 80.0,
              minMpptVoltage: 80.0, maxMpptVoltage: 560.0, maxInputCurrentPerMppt: 20.0,
              maxShortCircuitCurrent: 28.0, maxOutputCurrent: 40.0, nominalVoltageAc: 220.0,
              dimensions: '503 x 435 x 183 mm', weight: 18.0, protectionDegree: 'IP66',
              warrantyYears: 10, minOperatingTemp: -25.0, maxOperatingTemp: 60.0
            ),
            Inverter(
              manufacturer: 'Solplanet', modelName: 'ASW10000-S', inverterType: InverterType.string,
              isHybrid: false, gridConnection: GridConnection.monophasic,
              nominalPowerKw: 10.0, maxInputPowerKw: 15.0, maxEfficiency: 0.977, euroEfficiency: 0.973,
              mpptCount: 3, maxInputVoltage: 600.0, nominalVoltageDc: 360.0, startVoltage: 80.0,
              minMpptVoltage: 80.0, maxMpptVoltage: 560.0, maxInputCurrentPerMppt: 20.0,
              maxShortCircuitCurrent: 28.0, maxOutputCurrent: 50.0, nominalVoltageAc: 220.0,
              dimensions: '503 x 435 x 183 mm', weight: 18.0, protectionDegree: 'IP66',
              warrantyYears: 10, minOperatingTemp: -25.0, maxOperatingTemp: 60.0
            ),

            // --- SOLPLANET SÉRIE ASW LT-G2 Pro (Trifásicos) ---
            Inverter(
              manufacturer: 'Solplanet', modelName: 'ASW12K-LT-G2 Pro', inverterType: InverterType.string,
              isHybrid: false, gridConnection: GridConnection.triphasic,
              nominalPowerKw: 12.0, maxInputPowerKw: 18.0, maxEfficiency: 0.986, euroEfficiency: 0.982,
              mpptCount: 2, maxInputVoltage: 1100.0, nominalVoltageDc: 630.0, startVoltage: 125.0,
              minMpptVoltage: 150.0, maxMpptVoltage: 1000.0, maxInputCurrentPerMppt: 32.0,
              maxShortCircuitCurrent: 48.0, maxOutputCurrent: 19.1, nominalVoltageAc: 380.0,
              dimensions: '503 x 435 x 183 mm', weight: 18.6, protectionDegree: 'IP66',
              warrantyYears: 10, minOperatingTemp: -25.0, maxOperatingTemp: 60.0
            ),
            Inverter(
              manufacturer: 'Solplanet', modelName: 'ASW15K-LT-G2 Pro', inverterType: InverterType.string,
              isHybrid: false, gridConnection: GridConnection.triphasic,
              nominalPowerKw: 15.0, maxInputPowerKw: 22.5, maxEfficiency: 0.986, euroEfficiency: 0.982,
              mpptCount: 2, maxInputVoltage: 1100.0, nominalVoltageDc: 630.0, startVoltage: 125.0,
              minMpptVoltage: 150.0, maxMpptVoltage: 1000.0, maxInputCurrentPerMppt: 40.0,
              maxShortCircuitCurrent: 48.0, maxOutputCurrent: 24.0, nominalVoltageAc: 380.0,
              dimensions: '503 x 435 x 183 mm', weight: 18.6, protectionDegree: 'IP66',
              warrantyYears: 10, minOperatingTemp: -25.0, maxOperatingTemp: 60.0
            ),
            Inverter(
              manufacturer: 'Solplanet', modelName: 'ASW17K-LT-G2 Pro', inverterType: InverterType.string,
              isHybrid: false, gridConnection: GridConnection.triphasic,
              nominalPowerKw: 17.0, maxInputPowerKw: 25.5, maxEfficiency: 0.986, euroEfficiency: 0.982,
              mpptCount: 2, maxInputVoltage: 1100.0, nominalVoltageDc: 630.0, startVoltage: 125.0,
              minMpptVoltage: 150.0, maxMpptVoltage: 1000.0, maxInputCurrentPerMppt: 32.0,
              maxShortCircuitCurrent: 48.0, maxOutputCurrent: 27.1, nominalVoltageAc: 380.0,
              dimensions: '503 x 435 x 183 mm', weight: 17.3, protectionDegree: 'IP66',
              warrantyYears: 10, minOperatingTemp: -25.0, maxOperatingTemp: 60.0
            ),
            Inverter(
              manufacturer: 'Solplanet', modelName: 'ASW20K-LT-G2 Pro', inverterType: InverterType.string,
              isHybrid: false, gridConnection: GridConnection.triphasic,
              nominalPowerKw: 20.0, maxInputPowerKw: 30.0, maxEfficiency: 0.986, euroEfficiency: 0.982,
              mpptCount: 2, maxInputVoltage: 1100.0, nominalVoltageDc: 630.0, startVoltage: 125.0,
              minMpptVoltage: 150.0, maxMpptVoltage: 1000.0, maxInputCurrentPerMppt: 32.0,
              maxShortCircuitCurrent: 48.0, maxOutputCurrent: 31.9, nominalVoltageAc: 380.0,
              dimensions: '503 x 435 x 183 mm', weight: 17.3, protectionDegree: 'IP66',
              warrantyYears: 10, minOperatingTemp: -25.0, maxOperatingTemp: 60.0
            ),
            Inverter(
              manufacturer: 'Solplanet', modelName: 'ASW25K-LT-G2 Pro', inverterType: InverterType.string,
              isHybrid: false, gridConnection: GridConnection.triphasic,
              nominalPowerKw: 25.0, maxInputPowerKw: 37.5, maxEfficiency: 0.986, euroEfficiency: 0.982,
              mpptCount: 2, maxInputVoltage: 1100.0, nominalVoltageDc: 630.0, startVoltage: 125.0,
              minMpptVoltage: 150.0, maxMpptVoltage: 1000.0, maxInputCurrentPerMppt: 32.0,
              maxShortCircuitCurrent: 60.0, maxOutputCurrent: 39.8, nominalVoltageAc: 380.0,
              dimensions: '503 x 435 x 183 mm', weight: 18.6, protectionDegree: 'IP66',
              warrantyYears: 10, minOperatingTemp: -25.0, maxOperatingTemp: 60.0
            ),            
            Inverter(
              manufacturer: 'Intelbras',
              modelName: 'IONS 2K MICRO',
              inverterType: InverterType.microInverter, // Microinversor
              isHybrid: false,
              gridConnection: GridConnection.monophasic, // Monofásico/Bifásico 220V
              nominalPowerKw: 2.0,
              maxInputPowerKw: 2.48, // 4 entradas de até 620W
              maxEfficiency: 0.962,
              euroEfficiency: 0.962,
              mpptCount: 4,
              maxInputVoltage: 60.0,
              nominalVoltageDc: 36.0, 
              startVoltage: 22.0,
              minMpptVoltage: 16.0,
              maxMpptVoltage: 60.0,
              maxInputCurrentPerMppt: 16.0,
              maxShortCircuitCurrent: 20.0,
              maxOutputCurrent: 9.1,
              nominalVoltageAc: 220.0,
              dimensions: '381 x 286 x 58 mm',
              weight: 8.5,
              protectionDegree: 'IP67',
              warrantyYears: 10,
              minOperatingTemp: -40.0,
              maxOperatingTemp: 65.0,
            ),
            ..._buildHoymilesHMSSeries(),
          ];
          await isar.inverters.putAll(inverters);
        }
      });
      debugPrint("Dados populados com sucesso!");
    } else {
      debugPrint("O banco já possui dados. Seed pulado.");
    }
  }

  // ==========================================
  // FUNÇÕES AUXILIARES PARA GERAR FAMÍLIAS DE INVERSORES
  // ==========================================
  
  static List<Inverter> _buildHoymilesHMSSeries() {
    // Dados extraídos do datasheet Hoymiles Série HMS-2000DW-4T 
    final variations = [
      {
        'model': 'HMS-1600DW-4T',
        'pOut': 1.6,
        'pInMax': 2.4, // 4x 600W+ 
        'iMaxOut': 7.27,
        'effCec': 0.967
      },
      {
        'model': 'HMS-1800DW-4T',
        'pOut': 1.8,
        'pInMax': 2.7, // 4x 675W+ 
        'iMaxOut': 8.18,
        'effCec': 0.965
      },
      {
        'model': 'HMS-2000DW-4T',
        'pOut': 2.0,
        'pInMax': 3.0, // 4x 750W+ 
        'iMaxOut': 9.09,
        'effCec': 0.965
      },
    ];

    return variations.map((v) => Inverter(
      manufacturer: 'Hoymiles',
      modelName: v['model'] as String,
      inverterType: InverterType.microInverter,
      isHybrid: false,
      gridConnection: GridConnection.monophasic,
      nominalPowerKw: v['pOut'] as double,
      maxInputPowerKw: v['pInMax'] as double,
      maxEfficiency: 0.998, // Eficiência MPPT nominal 
      euroEfficiency: v['effCec'] as double, // Usando Eficiência CEC máxima como referência 
      mpptCount: 4,
      maxInputVoltage: 65.0,
      nominalVoltageDc: 36.0,
      startVoltage: 22.0,
      minMpptVoltage: 16.0,
      maxMpptVoltage: 60.0,
      maxInputCurrentPerMppt: 16.0,
      maxShortCircuitCurrent: 25.0,
      maxOutputCurrent: v['iMaxOut'] as double,
      nominalVoltageAc: 220.0,
      dimensions: '331 x 218 x 36.6 mm',
      weight: 4.7,
      protectionDegree: 'IP67',
      warrantyYears: 12, // Padrão Hoymiles Brasil
      minOperatingTemp: -40.0,
      maxOperatingTemp: 65.0,
    )).toList();
  }

  // ==========================================
  // FUNÇÕES AUXILIARES PARA GERAR FAMÍLIAS DE MÓDULOS
  // ==========================================

  static List<PvModule> _buildMaxeonP6Series() {
    // Datasheet Maxeon SPR-P6-XXX-UPP
    final variations = [
      {'wp': 530, 'eff': 20.4, 'voc': 46.3, 'isc': 14.49, 'vmp': 38.8, 'imp': 13.67},
      {'wp': 535, 'eff': 21.1, 'voc': 46.5, 'isc': 14.54, 'vmp': 39.0, 'imp': 13.71},
      {'wp': 540, 'eff': 20.6, 'voc': 46.7, 'isc': 14.59, 'vmp': 39.3, 'imp': 13.76}, // Eff 20.6% base data sheet
      {'wp': 545, 'eff': 20.7, 'voc': 46.9, 'isc': 14.64, 'vmp': 39.5, 'imp': 13.80},
      {'wp': 550, 'eff': 20.9, 'voc': 47.1, 'isc': 14.68, 'vmp': 39.7, 'imp': 13.85},
      {'wp': 555, 'eff': 21.3, 'voc': 47.3, 'isc': 14.73, 'vmp': 40.0, 'imp': 13.89},
    ];

    return variations.map((v) => PvModule(
      manufacturer: 'Maxeon',
      modelName: 'SPR-P6-${v['wp']}-UPP',
      cellTechnology: CellTechnology.perc,
      powerWp: v['wp'] as int,
      efficiency: (v['eff'] as num).toDouble(),
      vOc: (v['voc'] as num).toDouble(),
      iSc: (v['isc'] as num).toDouble(),
      vMp: (v['vmp'] as num).toDouble(),
      iMp: (v['imp'] as num).toDouble(),
      tempCoefVoc: -0.28, tempCoefIsc: 0.06, tempCoefPmax: -0.34,
      length: 2384, width: 1092, weight: 32.4, isBifacial: true,
    )).toList();
  }

  static List<PvModule> _buildDahSolarSeries() {
    // Datasheet DAH Solar DHN-66Y18/DG
    final variations = [
      {'wp': 700, 'eff': 22.53, 'voc': 47.6, 'isc': 18.49, 'vmp': 39.8, 'imp': 17.58}, // Ajustado Imp pela tabela (aprox)
      {'wp': 705, 'eff': 22.70, 'voc': 47.8, 'isc': 18.55, 'vmp': 40.2, 'imp': 17.54},
      {'wp': 710, 'eff': 22.86, 'voc': 48.0, 'isc': 18.61, 'vmp': 40.4, 'imp': 17.57},
      {'wp': 715, 'eff': 23.02, 'voc': 48.2, 'isc': 18.67, 'vmp': 40.6, 'imp': 17.61},
      {'wp': 720, 'eff': 23.18, 'voc': 48.4, 'isc': 18.73, 'vmp': 40.8, 'imp': 17.65},
      {'wp': 725, 'eff': 23.34, 'voc': 48.6, 'isc': 18.79, 'vmp': 41.0, 'imp': 17.68},
      {'wp': 730, 'eff': 23.50, 'voc': 48.8, 'isc': 18.85, 'vmp': 41.2, 'imp': 17.72},
    ];

    return variations.map((v) => PvModule(
      manufacturer: 'DAH Solar',
      modelName: 'DHN-66Y18/DG-${v['wp']}',
      cellTechnology: CellTechnology.topcon,
      powerWp: v['wp'] as int,
      efficiency: (v['eff'] as num).toDouble(),
      vOc: (v['voc'] as num).toDouble(),
      iSc: (v['isc'] as num).toDouble(),
      vMp: (v['vmp'] as num).toDouble(),
      iMp: (v['imp'] as num).toDouble(),
      tempCoefVoc: -0.25, tempCoefIsc: 0.046, tempCoefPmax: -0.29,
      length: 2384, width: 1303, weight: 37.3, isBifacial: true,
    )).toList();
  }

  static List<PvModule> _buildAstronergyN7Series() {
    // Datasheet Astronergy ASTRO N7 CHSM66RN(DG)/F-BH 
    final variations = [
      {'wp': 600, 'eff': 22.2, 'vmp': 41.05, 'imp': 14.62, 'voc': 48.44, 'isc': 15.78}, // 
      {'wp': 605, 'eff': 22.4, 'vmp': 41.18, 'imp': 14.69, 'voc': 48.59, 'isc': 15.86}, // 
      {'wp': 610, 'eff': 22.6, 'vmp': 41.31, 'imp': 14.77, 'voc': 48.74, 'isc': 15.94}, // 
      {'wp': 615, 'eff': 22.8, 'vmp': 41.43, 'imp': 14.84, 'voc': 48.89, 'isc': 16.02}, // 
      {'wp': 620, 'eff': 23.0, 'vmp': 41.56, 'imp': 14.92, 'voc': 49.04, 'isc': 16.11}, // 
      {'wp': 625, 'eff': 23.1, 'vmp': 41.69, 'imp': 14.99, 'voc': 49.19, 'isc': 16.19}, // 
      {'wp': 630, 'eff': 23.3, 'vmp': 41.82, 'imp': 15.07, 'voc': 49.34, 'isc': 16.27}, // 
    ];

    return variations.map((v) => PvModule(
      manufacturer: 'Astronergy', // 
      modelName: 'CHSM66RN(DG)/F-BH-${v['wp']}', // 
      cellTechnology: CellTechnology.topcon, // 
      powerWp: (v['wp'] as int),
      efficiency: (v['eff'] as double),
      vOc: (v['voc'] as double),
      iSc: (v['isc'] as double),
      vMp: (v['vmp'] as double),
      iMp: (v['imp'] as double),
      tempCoefVoc: -0.25,  // 
      tempCoefIsc: 0.043,  // 
      tempCoefPmax: -0.29, // 
      length: 2382,        // 
      width: 1134,         // 
      weight: 31.65,       // 
      isBifacial: true,    // 
    )).toList();
  }
}