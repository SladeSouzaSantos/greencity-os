/// Resultado tipado da extração de datasheets. Valores não informados
/// permanecem ausentes e precisam de revisão antes de salvar no catálogo.
class AiExtractionResultModel {
  final List<AiExtractedModule> modules;
  final List<AiExtractedInverter> inverters;

  const AiExtractionResultModel({
    required this.modules,
    required this.inverters,
  });

  factory AiExtractionResultModel.fromJson(Map<String, dynamic> json) {
    List<Map<String, dynamic>> objects(dynamic raw) {
      if (raw is! List) return const [];
      return raw.whereType<Map>().map(
        (item) => Map<String, dynamic>.from(item),
      ).toList();
    }

    return AiExtractionResultModel(
      modules: objects(json['modules'])
          .map(AiExtractedModule.fromJson)
          .toList(),
      inverters: objects(json['inverters'])
          .map(AiExtractedInverter.fromJson)
          .toList(),
    );
  }
}

double? _number(dynamic raw) {
  if (raw == null) return null;
  if (raw is num) return raw.toDouble().isFinite ? raw.toDouble() : null;
  if (raw is String) {
    final result = double.tryParse(raw.trim().replaceAll(',', '.'));
    return result != null && result.isFinite ? result : null;
  }
  return null;
}

int? _integer(dynamic raw) {
  final value = _number(raw);
  if (value == null || value != value.roundToDouble()) return null;
  return value.toInt();
}

String _string(dynamic raw, [String fallback = '']) =>
    raw is String ? raw.trim() : fallback;

bool? _boolean(dynamic raw) {
  if (raw is bool) return raw;
  if (raw is String) {
    final value = raw.trim().toLowerCase();
    if (value == 'true') return true;
    if (value == 'false') return false;
  }
  return null;
}

class AiExtractedModule {
  final String manufacturer;
  final String modelName;
  final int powerWp;
  final double efficiency;
  final String cellTechnology;
  final double vOc;
  final double iSc;
  final double vMp;
  final double iMp;
  final double? length;
  final double? width;
  final double? weight;
  final bool isBifacial;
  final bool? isTier1;
  final double? maxSystemVoltage;
  final double? tempCoefPmax;
  final double? tempCoefVoc;
  final double? tempCoefIsc;
  final double? minOperatingTemp;
  final double? maxOperatingTemp;
  final double? fuseCurrent;
  final int? physicalWarranty;
  final int? efficiencyWarranty;
  final double? efficiencyLoss;

  const AiExtractedModule({
    required this.manufacturer,
    required this.modelName,
    required this.powerWp,
    required this.efficiency,
    required this.cellTechnology,
    required this.vOc,
    required this.iSc,
    required this.vMp,
    required this.iMp,
    this.length,
    this.width,
    this.weight,
    required this.isBifacial,
    this.isTier1,
    this.maxSystemVoltage,
    this.tempCoefPmax,
    this.tempCoefVoc,
    this.tempCoefIsc,
    this.minOperatingTemp,
    this.maxOperatingTemp,
    this.fuseCurrent,
    this.physicalWarranty,
    this.efficiencyWarranty,
    this.efficiencyLoss,
  });

  factory AiExtractedModule.fromJson(Map<String, dynamic> json) {
    return AiExtractedModule(
      manufacturer: _string(json['manufacturer']),
      modelName: _string(json['modelName']),
      powerWp: _integer(json['powerWp']) ?? 0,
      efficiency: _number(json['efficiency']) ?? 0,
      cellTechnology: _string(json['cellTechnology']),
      vOc: _number(json['vOc']) ?? 0,
      iSc: _number(json['iSc']) ?? 0,
      vMp: _number(json['vMp']) ?? 0,
      iMp: _number(json['iMp']) ?? 0,
      length: _number(json['length']),
      width: _number(json['width']),
      weight: _number(json['weight']),
      isBifacial: _boolean(json['isBifacial']) ?? false,
      isTier1: _boolean(json['isTier1']),
      maxSystemVoltage: _number(json['maxSystemVoltage']),
      tempCoefPmax: _number(json['tempCoefPmax']),
      tempCoefVoc: _number(json['tempCoefVoc']),
      tempCoefIsc: _number(json['tempCoefIsc']),
      minOperatingTemp: _number(json['minOperatingTemp']),
      maxOperatingTemp: _number(json['maxOperatingTemp']),
      fuseCurrent: _number(json['fuseCurrent']),
      physicalWarranty: _integer(json['physicalWarranty']),
      efficiencyWarranty: _integer(json['efficiencyWarranty']),
      efficiencyLoss: _number(json['efficiencyLoss']),
    );
  }
}

class AiExtractedInverter {
  final String manufacturer;
  final String modelName;
  final double nominalPowerKw;
  final double? maxInputPowerKw;
  final double? maxEfficiency;
  final double? euroEfficiency;
  final int? mpptCount;
  final double? maxInputVoltage;
  final double? nominalVoltageDc;
  final double? startVoltage;
  final double? minMpptVoltage;
  final double? maxMpptVoltage;
  final double? maxInputCurrentPerMppt;
  final double? maxShortCircuitCurrent;
  final double? maxOutputCurrent;
  final double? nominalVoltageAc;
  final String inverterType;
  final String gridConnection;
  final bool isHybrid;
  final String? dimensions;
  final double? weight;
  final double? minOperatingTemp;
  final double? maxOperatingTemp;
  final String? protectionDegree;
  final int? warrantyYears;

  const AiExtractedInverter({
    required this.manufacturer,
    required this.modelName,
    required this.nominalPowerKw,
    this.maxInputPowerKw,
    this.maxEfficiency,
    this.euroEfficiency,
    this.mpptCount,
    this.maxInputVoltage,
    this.nominalVoltageDc,
    this.startVoltage,
    this.minMpptVoltage,
    this.maxMpptVoltage,
    this.maxInputCurrentPerMppt,
    this.maxShortCircuitCurrent,
    this.maxOutputCurrent,
    this.nominalVoltageAc,
    required this.inverterType,
    required this.gridConnection,
    required this.isHybrid,
    this.dimensions,
    this.weight,
    this.minOperatingTemp,
    this.maxOperatingTemp,
    this.protectionDegree,
    this.warrantyYears,
  });

  factory AiExtractedInverter.fromJson(Map<String, dynamic> json) {
    return AiExtractedInverter(
      manufacturer: _string(json['manufacturer']),
      modelName: _string(json['modelName']),
      nominalPowerKw: _number(json['nominalPowerKw']) ?? 0,
      maxInputPowerKw: _number(json['maxInputPowerKw']),
      maxEfficiency: _number(json['maxEfficiency']),
      euroEfficiency: _number(json['euroEfficiency']),
      mpptCount: _integer(json['mpptCount']),
      maxInputVoltage: _number(json['maxInputVoltage']),
      nominalVoltageDc: _number(json['nominalVoltageDc']),
      startVoltage: _number(json['startVoltage']),
      minMpptVoltage: _number(json['minMpptVoltage']),
      maxMpptVoltage: _number(json['maxMpptVoltage']),
      maxInputCurrentPerMppt: _number(json['maxInputCurrentPerMppt']),
      maxShortCircuitCurrent: _number(json['maxShortCircuitCurrent']),
      maxOutputCurrent: _number(json['maxOutputCurrent']),
      nominalVoltageAc: _number(json['nominalVoltageAc']),
      inverterType: _string(json['inverterType']),
      gridConnection: _string(json['gridConnection']),
      isHybrid: _boolean(json['isHybrid']) ?? false,
      dimensions: _string(json['dimensions']).isEmpty
          ? null
          : _string(json['dimensions']),
      weight: _number(json['weight']),
      minOperatingTemp: _number(json['minOperatingTemp']),
      maxOperatingTemp: _number(json['maxOperatingTemp']),
      protectionDegree: _string(json['protectionDegree']).isEmpty
          ? null
          : _string(json['protectionDegree']),
      warrantyYears: _integer(json['warrantyYears']),
    );
  }
}
