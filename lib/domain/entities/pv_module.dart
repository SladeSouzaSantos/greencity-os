import 'package:isar/isar.dart';

import '../enums/cell_technology.dart';

part 'pv_module.g.dart';

@Collection()
class PvModule {
  Id id = Isar.autoIncrement;

  // Informações Básicas
  @Index()
  final String manufacturer;
  final String modelName;
  @enumerated // <--- Adicione isto
  final CellTechnology cellTechnology; // ex: TOPCon, PERC
  final bool isTier1; // default: true

  // Dimensões e Peso
  final double length;
  final double width;
  final double weight; // Peso (kg)

  // Potência e Eficiência
  final int powerWp; // $P_{max}$
  final double efficiency; // Eficiência (%)

  // Parâmetros Elétricos (STC)
  final double vOc; // Open Circuit Voltage ($V_{oc}$)
  final double iSc; // Short Circuit Current ($I_{sc}$)
  final double vMp; // Maximum Power Voltage ($V_{mp}$)
  final double iMp; // Maximum Power Current ($I_{mp}$)
  final double maxSystemVoltage; // ex: 1500V

  // Coeficientes de Temperatura
  final double tempCoefVoc; // %/°C ($\beta$)
  final double tempCoefIsc; // %/°C ($\alpha$)
  final double tempCoefPmax; // %/°C ($\gamma$)

  // Limites de Operação
  final double minOperatingTemp; // default: -40
  final double maxOperatingTemp; // default: 85
  final double fuseCurrent; // default: 25A

  // Garantias e Degradação
  final int physicalWarranty; // Anos (padrão 10)
  final int efficiencyWarranty; // Anos (padrão 25)
  final double efficiencyLoss; // Perda total ao fim da vida útil (%)

  final bool isBifacial;

  PvModule({
    required this.manufacturer,
    required this.modelName,
    required this.cellTechnology,
    this.isTier1 = true,
    required this.length,
    required this.width,
    required this.weight,
    required this.powerWp,
    required this.efficiency,
    required this.vOc,
    required this.iSc,
    required this.vMp,
    required this.iMp,
    this.maxSystemVoltage = 1500,
    required this.tempCoefVoc,
    required this.tempCoefIsc,
    required this.tempCoefPmax,
    this.minOperatingTemp = -40,
    this.maxOperatingTemp = 85,
    this.fuseCurrent = 25,
    this.physicalWarranty = 10,
    this.efficiencyWarranty = 25,
    this.efficiencyLoss = 20,
    required this.isBifacial,
  });

  @override
  String toString() {
    return 'PvModule(\n'
        '  model: $manufacturer $modelName,\n'
        '  power: ${powerWp}Wp (${cellTechnology.name}),\n'
        '  bifacial: $isBifacial, efficiency: $efficiency%,\n'
        '  dimensions: ${length}x${width}mm, weight: ${weight}kg,\n'
        '  electrical: [Voc: ${vOc}V, Isc: ${iSc}A, Vmp: ${vMp}V, Imp: ${iMp}A],\n'
        '  coefficients: [Voc: $tempCoefVoc%/°C, Pmax: $tempCoefPmax%/°C]\n'
        ')';
  }
}