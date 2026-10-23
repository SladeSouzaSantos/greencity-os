import '../../domain/entities/inverter.dart';
import '../../domain/entities/inverter_mppt_configuration.dart';
import '../../domain/entities/pv_module.dart';
import '../../domain/enums/cell_technology.dart';
import '../../domain/enums/grid_connection.dart';
import '../../domain/enums/inverter_type.dart';
import 'ai_extraction_result_model.dart';

/// Valida as informações indispensáveis antes do import em lote. Dados
/// opcionais não extraídos permanecem 0 no esquema atual (não informados).
class AiEquipmentMapper {
  static bool _positive(num? value) =>
      value != null && value.isFinite && value > 0;

  static List<String> moduleProblems(AiExtractedModule value) {
    final problems = <String>[];
    if (value.manufacturer.trim().isEmpty || value.modelName.trim().isEmpty) {
      problems.add('fabricante/modelo');
    }
    if (!_positive(value.powerWp)) problems.add('potência Wp');
    if (!_positive(value.efficiency) || value.efficiency > 100) {
      problems.add('eficiência do módulo');
    }
    if (!_positive(value.vOc) || !_positive(value.iSc) ||
        !_positive(value.vMp) || !_positive(value.iMp)) {
      problems.add('parâmetros STC (Voc/Isc/Vmp/Imp)');
    }
    if (!_positive(value.length) || !_positive(value.width)) {
      problems.add('dimensões (mm)');
    }
    if (moduleTechnology(value.cellTechnology) == null) {
      problems.add('tecnologia celular');
    }
    return problems;
  }

  static List<String> inverterProblems(AiExtractedInverter value) {
    final problems = <String>[];
    if (value.manufacturer.trim().isEmpty || value.modelName.trim().isEmpty) {
      problems.add('fabricante/modelo');
    }
    if (!_positive(value.nominalPowerKw)) problems.add('potência nominal kW');
    if (!_positive(value.maxInputPowerKw)) problems.add('potência máxima CC kW');
    if (!_positive(value.mpptCount)) problems.add('quantidade de MPPT');
    if (!_positive(value.maxInputVoltage) ||
        !_positive(value.minMpptVoltage) ||
        !_positive(value.maxMpptVoltage) ||
        !_positive(value.maxInputCurrentPerMppt)) {
      problems.add('limites de tensão/corrente MPPT');
    } else if (value.minMpptVoltage! > value.maxMpptVoltage! ||
        value.maxMpptVoltage! > value.maxInputVoltage!) {
      problems.add('faixa de tensão MPPT inconsistente');
    }
    if (value.mpptInputCurrentsA != null && value.mpptCount != null &&
        value.mpptInputCurrentsA!.length != value.mpptCount) {
      problems.add('número de correntes não corresponde aos MPPTs');
    }
    if (value.mpptShortCircuitCurrentsA != null && value.mpptCount != null &&
        value.mpptShortCircuitCurrentsA!.length != value.mpptCount) {
      problems.add('número de correntes Isc não corresponde aos MPPTs');
    }
    if (value.totalDcInputs != null && value.mpptCount != null &&
        value.totalDcInputs! < value.mpptCount!) {
      problems.add('entradas CC menores que a quantidade de MPPTs');
    }
    if (inverterType(value.inverterType) == null) {
      problems.add('tipo de inversor');
    }
    if (gridConnection(value.gridConnection) == null) {
      problems.add('tipo de conexão elétrica');
    }
    return problems;
  }

  static CellTechnology? moduleTechnology(String raw) {
    final key = raw.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
    if (key.contains('TOPCON') || key == 'NTYPE') return CellTechnology.topcon;
    if (key.contains('HJT') || key.contains('HETEROJUNCTION')) {
      return CellTechnology.hjt;
    }
    if (key.contains('PERC')) return CellTechnology.perc;
    if (key.contains('BSF')) return CellTechnology.alBSF;
    return null;
  }

  static InverterType? inverterType(String raw) {
    final value = raw.toLowerCase().trim();
    if (value.contains('micro')) return InverterType.microInverter;
    if (value.contains('optim')) return InverterType.optimizer;
    if (value == 'string' || value.contains('string inverter')) {
      return InverterType.string;
    }
    return null;
  }

  static GridConnection? gridConnection(String raw) {
    final value = raw.toLowerCase();
    if (value.contains('tri')) return GridConnection.triphasic;
    if (value.contains('bi')) return GridConnection.biphasic;
    if (value.contains('mono')) return GridConnection.monophasic;
    return null;
  }

  static PvModule module(AiExtractedModule value) {
    final problems = moduleProblems(value);
    if (problems.isNotEmpty) {
      throw FormatException('Módulo ${value.modelName}: ${problems.join(', ')}.');
    }
    return PvModule(
      manufacturer: value.manufacturer.trim(),
      modelName: value.modelName.trim(),
      cellTechnology: moduleTechnology(value.cellTechnology)!,
      isBifacial: value.isBifacial,
      isTier1: value.isTier1 ?? false,
      length: value.length!,
      width: value.width!,
      weight: value.weight ?? 0,
      powerWp: value.powerWp,
      efficiency: value.efficiency,
      vOc: value.vOc,
      iSc: value.iSc,
      vMp: value.vMp,
      iMp: value.iMp,
      maxSystemVoltage: value.maxSystemVoltage ?? 0,
      tempCoefVoc: value.tempCoefVoc ?? 0,
      tempCoefIsc: value.tempCoefIsc ?? 0,
      tempCoefPmax: value.tempCoefPmax ?? 0,
      minOperatingTemp: value.minOperatingTemp ?? 0,
      maxOperatingTemp: value.maxOperatingTemp ?? 0,
      fuseCurrent: value.fuseCurrent ?? 0,
      physicalWarranty: value.physicalWarranty ?? 0,
      efficiencyWarranty: value.efficiencyWarranty ?? 0,
      efficiencyLoss: value.efficiencyLoss ?? 0,
    );
  }

  static Inverter inverter(AiExtractedInverter value) {
    final problems = inverterProblems(value);
    if (problems.isNotEmpty) {
      throw FormatException('Inversor ${value.modelName}: ${problems.join(', ')}.');
    }
    double efficiency(double? raw) {
      if (raw == null) return 0;
      return raw > 1 ? raw / 100 : raw;
    }

    return Inverter(
      manufacturer: value.manufacturer.trim(),
      modelName: value.modelName.trim(),
      inverterType: inverterType(value.inverterType)!,
      gridConnection: gridConnection(value.gridConnection)!,
      isHybrid: value.isHybrid,
      nominalPowerKw: value.nominalPowerKw,
      maxInputPowerKw: value.maxInputPowerKw!,
      maxEfficiency: efficiency(value.maxEfficiency),
      euroEfficiency: efficiency(value.euroEfficiency),
      mpptCount: value.mpptCount!,
      mpptConfigurationJson: InverterMpptConfiguration(
        inputCurrentsA: value.mpptInputCurrentsA,
        shortCircuitCurrentsA: value.mpptShortCircuitCurrentsA,
        totalDcInputs: value.totalDcInputs,
      ).hasDetails
          ? InverterMpptConfiguration(
              inputCurrentsA: value.mpptInputCurrentsA,
              shortCircuitCurrentsA: value.mpptShortCircuitCurrentsA,
              totalDcInputs: value.totalDcInputs,
            ).encode()
          : null,
      maxInputVoltage: value.maxInputVoltage!,
      nominalVoltageDc: value.nominalVoltageDc ?? 0,
      startVoltage: value.startVoltage ?? 0,
      minMpptVoltage: value.minMpptVoltage!,
      maxMpptVoltage: value.maxMpptVoltage!,
      maxInputCurrentPerMppt: value.maxInputCurrentPerMppt!,
      maxShortCircuitCurrent: value.maxShortCircuitCurrent ?? 0,
      maxOutputCurrent: value.maxOutputCurrent ?? 0,
      nominalVoltageAc: value.nominalVoltageAc ?? 0,
      dimensions: value.dimensions ?? '',
      weight: value.weight ?? 0,
      minOperatingTemp: value.minOperatingTemp ?? 0,
      maxOperatingTemp: value.maxOperatingTemp ?? 0,
      protectionDegree: value.protectionDegree ?? '',
      warrantyYears: value.warrantyYears ?? 0,
    );
  }
}
