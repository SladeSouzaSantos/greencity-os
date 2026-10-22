import 'package:isar/isar.dart';

import '../enums/grid_connection.dart';
import '../enums/inverter_type.dart';

part 'inverter.g.dart';

@Collection()
class Inverter {
  Id id = Isar.autoIncrement;

  @Index()
  final String manufacturer; // Ex: AUXSOL
  final String modelName;    // Ex: ASN-10SL

  @enumerated
  final InverterType inverterType; // String, Micro, etc.

  // Potência e Eficiência
  final double nominalPowerKw;    // Potência Nominal de Saída (ex: 10kW)
  final double maxInputPowerKw;   // Potência CC Máx. Recomendada (ex: 20kW)
  final double maxEfficiency;     // Eficiência Máxima (ex: 98.1%)
  final double euroEfficiency;    // Eficiência Europeia (ex: 97.6%)

  // Entrada CC (MPPTs)
  final int mpptCount;
  final double maxInputVoltage;       // Tensão CC Máx. (ex: 600V)
  final double nominalVoltageDc;      // Tensão CC Nominal (ex: 380V)
  final double startVoltage;          // Tensão de Início (ex: 40V)
  final double minMpptVoltage;        // Faixa Tensão MPPT (Início)
  final double maxMpptVoltage;        // Faixa Tensão MPPT (Fim)
  final double maxInputCurrentPerMppt; // Corrente Max. Impp (ex: 32A/18A)
  final double maxShortCircuitCurrent; // Corrente Max. Curto Circuito (Isc) (ex: 40A/22A)

  // Saída CA
  @enumerated
  final GridConnection gridConnection;    // Monofásico / Trifásico
  final double maxOutputCurrent;   // Corrente Máx. de Saída (ex: 45.5A)
  final double nominalVoltageAc;   // 220V/230V/240V

  // Físico e Ambiental
  final String dimensions;         // L x A x P (ex: 355 x 427 x 172 mm)
  final double weight;             // Peso (kg) (ex: 14.5kg)
  final double minOperatingTemp;   // Faixa Temperatura (ex: -25)
  final double maxOperatingTemp;   // Faixa Temperatura (ex: 60)
  final String protectionDegree;   // Índice de Proteção (ex: IP65)
  final bool isHybrid;            // Híbrido (ex: true/false)

  // Garantia
  final int warrantyYears;         // Anos de Garantia

  Inverter({
    required this.manufacturer,
    required this.modelName,
    required this.inverterType,
    required this.nominalPowerKw,
    required this.maxInputPowerKw,
    required this.maxEfficiency,
    required this.euroEfficiency,
    required this.mpptCount,
    required this.maxInputVoltage,
    required this.nominalVoltageDc,
    required this.startVoltage,
    required this.minMpptVoltage,
    required this.maxMpptVoltage,
    required this.maxInputCurrentPerMppt,
    required this.maxShortCircuitCurrent,
    required this.gridConnection,
    required this.maxOutputCurrent,
    required this.nominalVoltageAc,
    required this.dimensions,
    required this.weight,
    required this.minOperatingTemp,
    required this.maxOperatingTemp,
    required this.protectionDegree,
    required this.isHybrid,
    this.warrantyYears = 10, // Padrão comum, mas ajustável
  });

  @override
  String toString() {
    return 'Inverter(\n'
        '  model: $manufacturer $modelName,\n'
        '  type: ${inverterType.name}, connection: ${gridConnection.name},\n'
        '  power: ${nominalPowerKw}kW (Max Input: ${maxInputPowerKw}kW),\n'
        '  mppts: $mpptCount, efficiency: $maxEfficiency%,\n'
        '  dc_limits: [Max: ${maxInputVoltage}V, Start: ${startVoltage}V, Range: ${minMpptVoltage}V-${maxMpptVoltage}V],\n'
        '  ac_limits: [Nominal: ${nominalVoltageAc}V, MaxCurrent: ${maxOutputCurrent}A],\n'
        '  physical: $protectionDegree, ${weight}kg, hybrid: $isHybrid\n'
        ')';
  }
}