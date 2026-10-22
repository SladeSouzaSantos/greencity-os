class AiExtractionResultModel {
  final List<AiExtractedModule> modules;
  final List<AiExtractedInverter> inverters;

  AiExtractionResultModel({required this.modules, required this.inverters});

  factory AiExtractionResultModel.fromJson(Map<String, dynamic> json) {
    return AiExtractionResultModel(
      modules: (json['modules'] as List? ?? [])
          .map((e) => AiExtractedModule.fromJson(e))
          .toList(),
      inverters: (json['inverters'] as List? ?? [])
          .map((e) => AiExtractedInverter.fromJson(e))
          .toList(),
    );
  }
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
  final double? tempCoefPmax;
  final double? tempCoefVoc;
  final double? tempCoefIsc;

  AiExtractedModule({
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
    this.tempCoefPmax,
    this.tempCoefVoc,
    this.tempCoefIsc,
  });

  factory AiExtractedModule.fromJson(Map<String, dynamic> json) {
    return AiExtractedModule(
      manufacturer: json['manufacturer'] ?? '',
      modelName: json['modelName'] ?? '',
      powerWp: (json['powerWp'] ?? 0).toInt(),
      efficiency: (json['efficiency'] ?? 0).toDouble(),
      cellTechnology: json['cellTechnology'] ?? 'TOPCon',
      vOc: (json['vOc'] ?? 0).toDouble(),
      iSc: (json['iSc'] ?? 0).toDouble(),
      vMp: (json['vMp'] ?? 0).toDouble(),
      iMp: (json['iMp'] ?? 0).toDouble(),
      length: (json['length'])?.toDouble(),
      width: (json['width'])?.toDouble(),
      weight: (json['weight'])?.toDouble(),
      isBifacial: json['isBifacial'] ?? false,
      tempCoefPmax: (json['tempCoefPmax'])?.toDouble(),
      tempCoefVoc: (json['tempCoefVoc'])?.toDouble(),
      tempCoefIsc: (json['tempCoefIsc'])?.toDouble(),
    );
  }
}

class AiExtractedInverter {
  final String manufacturer;
  final String modelName;
  final double nominalPowerKw;
  final double? maxInputPowerKw;
  final int? mpptCount;
  final double? maxInputVoltage;
  final double? maxEfficiency;
  final double? maxOutputCurrent;
  final String inverterType; // string, micro, central
  final String gridConnection; // monophasic, triphasic
  final bool isHybrid;
  final double? weight;

  AiExtractedInverter({
    required this.manufacturer,
    required this.modelName,
    required this.nominalPowerKw,
    this.maxInputPowerKw,
    this.mpptCount,
    this.maxInputVoltage,
    this.maxEfficiency,
    this.maxOutputCurrent,
    required this.inverterType,
    required this.gridConnection,
    required this.isHybrid,
    this.weight,
  });

  factory AiExtractedInverter.fromJson(Map<String, dynamic> json) {
    return AiExtractedInverter(
      manufacturer: json['manufacturer'] ?? '',
      modelName: json['modelName'] ?? '',
      nominalPowerKw: (json['nominalPowerKw'] ?? 0).toDouble(),
      maxInputPowerKw: (json['maxInputPowerKw'])?.toDouble(),
      mpptCount: (json['mpptCount'])?.toInt(),
      maxInputVoltage: (json['maxInputVoltage'])?.toDouble(),
      maxEfficiency: (json['maxEfficiency'])?.toDouble(),
      maxOutputCurrent: (json['maxOutputCurrent'])?.toDouble(),
      inverterType: json['inverterType'] ?? 'string',
      gridConnection: json['gridConnection'] ?? 'triphasic',
      isHybrid: json['isHybrid'] ?? false,
      weight: (json['weight'])?.toDouble(),
    );
  }
}