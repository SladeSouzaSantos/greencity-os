import 'dart:math' as math;

import '../entities/pv_module.dart';
import '../entities/solar_system.dart';
import 'solar3d_geometric_shading.dart';

/// Pre-feasibility study using REAL Isar nameplate fields and an explicit
/// panel -> string -> MPPT -> inverter assignment. Not an I-V simulation:
/// we do NOT derive bypass substrings or AC shading loss from STC values.
enum Solar3dElectricalSeverity { info, warning, blocking }

class Solar3dElectricalFinding {
  final String code;
  final String scope;
  final Solar3dElectricalSeverity severity;
  final String message;

  const Solar3dElectricalFinding({
    required this.code,
    required this.scope,
    required this.severity,
    required this.message,
  });
}

class Solar3dStringElectricalCheck {
  final String inverterId;
  final int mpptIndex;
  final String stringId;
  final int moduleCount;
  final double powerWp;
  final double vocStcV;
  final double vmpStcV;
  final double impStcA;
  final double iscStcA;
  final double? estimatedVocColdV;

  const Solar3dStringElectricalCheck({
    required this.inverterId,
    required this.mpptIndex,
    required this.stringId,
    required this.moduleCount,
    required this.powerWp,
    required this.vocStcV,
    required this.vmpStcV,
    required this.impStcA,
    required this.iscStcA,
    required this.estimatedVocColdV,
  });
}

class Solar3dMpptElectricalCheck {
  final String inverterId;
  final int mpptIndex;
  final List<Solar3dStringElectricalCheck> strings;
  final double totalPowerWp;
  final double parallelImpStcA;
  final double parallelIscStcA;
  final double operatingCurrentLimitA;
  final double shortCircuitCurrentLimitA;

  const Solar3dMpptElectricalCheck({
    required this.inverterId,
    required this.mpptIndex,
    required this.strings,
    required this.totalPowerWp,
    required this.parallelImpStcA,
    required this.parallelIscStcA,
    required this.operatingCurrentLimitA,
    required this.shortCircuitCurrentLimitA,
  });
}

class Solar3dElectricalAudit {
  final List<Solar3dElectricalFinding> findings;
  final List<Solar3dMpptElectricalCheck> trackers;
  final int totalPanels;
  final int assignedPanels;
  final double? minimumAmbientC;

  const Solar3dElectricalAudit._({
    required this.findings,
    required this.trackers,
    required this.totalPanels,
    required this.assignedPanels,
    required this.minimumAmbientC,
  });

  bool get topologyComplete => totalPanels > 0 &&
      totalPanels == assignedPanels;
  bool get hasBlockers => findings.any((f) =>
      f.severity == Solar3dElectricalSeverity.blocking);
  bool get hasWarnings => findings.any((f) =>
      f.severity == Solar3dElectricalSeverity.warning);

  /// An electrical topology CHECK is not an electrical-YIELD validation.
  /// A calibrated I-V/cell/substring model remains mandatory.
  bool get electricallyCalibrated => false;

  static Solar3dElectricalAudit inspect({
    required List<SolarSystem> systems,
    required Solar3dScene scene,
    double? minimumAmbientC,
  }) {
    if (minimumAmbientC != null &&
        (!minimumAmbientC.isFinite ||
            minimumAmbientC < -60 || minimumAmbientC > 80)) {
      throw const FormatException('Temperatura mínima inválida');
    }
    scene.validate();
    final findings = <Solar3dElectricalFinding>[];
    void issue(String code, String scope,
        Solar3dElectricalSeverity severity, String message) {
      findings.add(Solar3dElectricalFinding(
        code: code, scope: scope, severity: severity, message: message));
    }

    // Physical namespaced panel IDs avoid collisions between MPPT 1
    // on different inverters. Never use just the MPPT number as a key.
    final expected = <String, ({String systemId, PvModule module})>{};
    final systemsById = <String, SolarSystem>{};
    for (final system in systems) {
      if (systemsById.containsKey(system.id)) {
        issue('DUPLICATE_INVERTER', system.id,
            Solar3dElectricalSeverity.blocking,
            'IDs de inversores duplicados impedem separar os MPPTs.');
      }
      systemsById[system.id] = system;
      for (var a = 0; a < system.arrays.length; a++) {
        final array = system.arrays[a];
        for (var p = 0; p < array.solarScenario.quantityPvModule; p++) {
          expected['${system.id}/${a + 1}/${p + 1}'] =
              (systemId: system.id, module: array.solarScenario.module);
        }
      }
    }
    final assigned = <String, Map<int, Map<String, List<PvModule>>>>{};
    final stringMppts = <String, Map<String, int>>{};
    final panelIds = <String>{};
    var assignedCount = 0;
    for (final panel in scene.objects.where(
        (o) => o.kind == Solar3dObjectKind.panel)) {
      panelIds.add(panel.id);
      final model = expected[panel.id];
      if (model == null) {
        issue('UNKNOWN_PANEL', panel.id, Solar3dElectricalSeverity.blocking,
            'Placa não corresponde a um módulo cadastrado no projeto.');
        continue;
      }
      final system = systemsById[model.systemId]!;
      final tracker = panel.mpptIndex ?? 0;
      if (tracker < 1 || tracker > system.inverter.mpptCount) {
        issue('UNKNOWN_MPPT', panel.id, Solar3dElectricalSeverity.blocking,
            'MPPT $tracker não existe neste inversor.');
        continue;
      }
      final label = panel.stringId?.trim() ?? '';
      if (label.isEmpty) {
        issue('UNASSIGNED_STRING', panel.id,
            Solar3dElectricalSeverity.warning,
            'Informe uma string para calcular tensões e correntes '
            'do módulo dentro do MPPT.');
        continue;
      }
      assignedCount++;
      final previously = stringMppts
          .putIfAbsent(model.systemId, () => {})[label];
      if (previously != null && previously != tracker) {
        issue('STRING_CROSSES_MPPTS', model.systemId,
            Solar3dElectricalSeverity.blocking,
            'A string "$label" foi ligada a mais de um MPPT '
            'do mesmo inversor.');
      }
      stringMppts[model.systemId]![label] = tracker;
      assigned.putIfAbsent(model.systemId, () => {})
          .putIfAbsent(tracker, () => {})
          .putIfAbsent(label, () => [])
          .add(model.module);
    }
    for (final id in expected.keys) {
      if (!panelIds.contains(id)) {
        issue('MISSING_PANEL', id, Solar3dElectricalSeverity.blocking,
            'Uma placa do projeto não está na cena de estudo.');
      }
    }
    final trackers = <Solar3dMpptElectricalCheck>[];
    for (final system in systems) {
      final inverter = system.inverter;
      final config = inverter.mpptConfiguration;
      for (final msg in config?.validate(inverter.mpptCount) ?? <String>[]) {
        issue('DATASHEET_CONFIG', system.id,
            Solar3dElectricalSeverity.warning, msg);
      }
      final byMppt = assigned[system.id] ?? {};
      var inverterPowerWp = 0.0;
      var stringCount = 0;
      for (final mppt in byMppt.keys.toList()..sort()) {
        final strings = <Solar3dStringElectricalCheck>[];
        for (final stringId in byMppt[mppt]!.keys.toList()..sort()) {
          final modules = byMppt[mppt]![stringId]!;
          if (modules.any((m) => ![m.vOc, m.vMp, m.iSc, m.iMp]
              .every((v) => v.isFinite && v > 0))) {
            issue('MISSING_IV', system.id,
                Solar3dElectricalSeverity.blocking,
                'Dados STC de Voc/Vmp/Isc/Imp inválidos na string "$stringId".');
            continue;
          }
          // Series: voltages add; current is LIMITED by the weakest
          // module, NOT the sum of the currents.
          final voc = modules.fold<double>(0, (v, m) => v + m.vOc);
          final vmp = modules.fold<double>(0, (v, m) => v + m.vMp);
          final imp = modules.map((m) => m.iMp).reduce(math.min);
          final isc = modules.map((m) => m.iSc).reduce(math.min);
          final power = modules.fold<double>(0, (p, m) => p + m.powerWp);
          final canEstimateCold = minimumAmbientC != null &&
              modules.every((m) => m.tempCoefVoc.isFinite);
          final cold = canEstimateCold
              ? modules.fold<double>(0, (v, m) =>
                  v + m.vOc * (1 + (m.tempCoefVoc / 100) *
                      (minimumAmbientC - 25)))
              : null;
          final scope = '${system.id} / MPPT $mppt / $stringId';
          if (inverter.minMpptVoltage <= 0 ||
              inverter.maxMpptVoltage <= 0 ||
              inverter.startVoltage <= 0 ||
              inverter.maxInputVoltage <= 0) {
            issue('INVERTER_DC_LIMITS_MISSING', scope,
                Solar3dElectricalSeverity.warning,
                'Faixas de tensão do inversor ausentes ou não validadas '
                'no cadastro; não é possível confirmar a viabilidade.');
          }
          if (inverter.minMpptVoltage > 0 &&
              vmp < inverter.minMpptVoltage) {
            issue('MPPT_UNDERVOLTAGE', scope,
                Solar3dElectricalSeverity.blocking,
                'Vmp STC ${vmp.toStringAsFixed(1)} V menor que o mínimo '
                'MPPT ${inverter.minMpptVoltage} V.');
          } else if (inverter.maxMpptVoltage > 0 &&
              vmp > inverter.maxMpptVoltage) {
            issue('MPPT_OVERVOLTAGE', scope,
                Solar3dElectricalSeverity.blocking,
                'Vmp STC ${vmp.toStringAsFixed(1)} V excede o máximo '
                'MPPT ${inverter.maxMpptVoltage} V.');
          }
          if (inverter.startVoltage > 0 &&
              voc < inverter.startVoltage) {
            issue('START_UNDERVOLTAGE', scope,
                Solar3dElectricalSeverity.blocking,
                'Voc STC ${voc.toStringAsFixed(1)} V insuficiente para '
                'partida (${inverter.startVoltage} V).');
          }
          if (inverter.maxInputVoltage > 0 &&
              voc > inverter.maxInputVoltage) {
            issue('VOC_MAX_STC', scope,
                Solar3dElectricalSeverity.blocking,
                'Voc STC excede a tensão máxima CC do inversor.');
          }
          if (cold != null && inverter.maxInputVoltage > 0 &&
              cold > inverter.maxInputVoltage) {
            issue('VOC_MAX_COLD', scope,
                Solar3dElectricalSeverity.blocking,
                'Voc estimado no frio ${cold.toStringAsFixed(1)} V excede '
                'a tensão máxima CC do inversor.');
          }
          final moduleVoltageLimit = modules.map(
              (m) => m.maxSystemVoltage).reduce(math.min);
          if (moduleVoltageLimit > 0 &&
              (cold ?? voc) > moduleVoltageLimit) {
            issue('MODULE_SYSTEM_VOLTAGE', scope,
                Solar3dElectricalSeverity.blocking,
                'Tensão de string excede limite do módulo.');
          }
          if (modules.any((m) => m.tempCoefVoc == 0)) {
            issue('VOC_TEMPERATURE_COEFFICIENT_MISSING', scope,
                Solar3dElectricalSeverity.warning,
                'Coeficiente de temperatura de Voc igual a zero; '
                'confirme no datasheet antes de confiar no Voc frio.');
          }
          // STC screen cannot prove Vmp under high-cell temperature,
          // nor the bypass-current limit of shaded series cells.
          issue('TEMP_VMP_NOT_VERIFIED', scope,
              Solar3dElectricalSeverity.info,
              'Vmp em temperatura de célula elevada e bypass não '
              'foram verificados; estes valores são apenas STC.');
          strings.add(Solar3dStringElectricalCheck(
            inverterId: system.id, mpptIndex: mppt,
            stringId: stringId, moduleCount: modules.length,
            powerWp: power, vocStcV: voc, vmpStcV: vmp,
            impStcA: imp, iscStcA: isc, estimatedVocColdV: cold));
        }
        if (strings.isEmpty) continue;
        stringCount += strings.length;
        final mpptPower = strings.fold<double>(
            0, (sum, s) => sum + s.powerWp);
        inverterPowerWp += mpptPower;
        final parallelImp = strings.fold<double>(
            0, (sum, s) => sum + s.impStcA);
        final parallelIsc = strings.fold<double>(
            0, (sum, s) => sum + s.iscStcA);
        final dcCurrent = config?.inputCurrentsA != null &&
                config!.inputCurrentsA!.length == inverter.mpptCount
            ? config.inputCurrentsA![mppt - 1]
            : inverter.maxInputCurrentPerMppt;
        final shortCircuit = config?.shortCircuitCurrentsA != null &&
                config!.shortCircuitCurrentsA!.length == inverter.mpptCount
            ? config.shortCircuitCurrentsA![mppt - 1]
            : inverter.maxShortCircuitCurrent;
        final scope = '${system.id} / MPPT $mppt';
        if (dcCurrent <= 0 || shortCircuit <= 0) {
          issue('MPPT_DC_CURRENT_LIMITS_MISSING', scope,
              Solar3dElectricalSeverity.warning,
              'Limites Impp/Isc por MPPT ausentes; confira datasheet.');
        }
        if (dcCurrent > 0 && parallelImp > dcCurrent + 1e-6) {
          // Operating input current is a usable MPPT current rating.
          // It is NOT the absolute short-circuit current limit.
          issue('MPPT_CURRENT_LIMIT', scope,
              Solar3dElectricalSeverity.warning,
              'Imp STC combinada das strings '
              '${parallelImp.toStringAsFixed(2)} A excede a '
              'corrente operacional máxima do MPPT '
              '${dcCurrent.toStringAsFixed(2)} A. '
              'Pode ocorrer limitação de corrente/potência. '
              'Confirme compatibilidade com o fabricante; '
              'o cálculo óptico não modela clipping.');
        }
        if (shortCircuit > 0 && parallelIsc > shortCircuit + 1e-6) {
          issue('MPPT_SHORT_CIRCUIT', scope,
              Solar3dElectricalSeverity.blocking,
              'Isc STC somada das strings '
              '${parallelIsc.toStringAsFixed(2)} A excede a '
              'corrente máxima de curto-circuito do MPPT '
              '${shortCircuit.toStringAsFixed(2)} A. '
              'Não aplicar este circuito ao projeto elétrico.');
        }
        final minVmp = strings.map((s) => s.vmpStcV).reduce(math.min);
        final maxVmp = strings.map((s) => s.vmpStcV).reduce(math.max);
        if (strings.length > 1 && maxVmp > 0 &&
            (maxVmp - minVmp) / maxVmp > .05) {
          issue('PARALLEL_VOLTAGE_MISMATCH', scope,
              Solar3dElectricalSeverity.warning,
              'Strings em paralelo têm diferença de Vmp STC acima de 5%; '
              'o MPP comum pode reduzir a potência.');
        }
        trackers.add(Solar3dMpptElectricalCheck(
          inverterId: system.id, mpptIndex: mppt,
          strings: List.unmodifiable(strings), totalPowerWp: mpptPower,
          parallelImpStcA: parallelImp,
          parallelIscStcA: parallelIsc,
          operatingCurrentLimitA: dcCurrent,
          shortCircuitCurrentLimitA: shortCircuit,
        ));
      }
      if (inverter.maxInputPowerKw > 0 &&
          inverterPowerWp / 1000 > inverter.maxInputPowerKw) {
        issue('DC_POWER_INPUT', system.id,
            Solar3dElectricalSeverity.warning,
            'Potência DC conectada excede a potência recomendada de '
            'entrada do inversor. Revise o oversizing.');
      }
      if (config?.totalDcInputs != null &&
          stringCount > config!.totalDcInputs!) {
        issue('DC_INPUT_COUNT', system.id,
            Solar3dElectricalSeverity.warning,
            'Há mais strings que entradas DC especificadas. '
            'Conexões em paralelo precisam de projeto elétrico próprio.');
      }
    }
    if (minimumAmbientC == null) {
      issue('COLD_VOC_UNAVAILABLE', 'Projeto',
          Solar3dElectricalSeverity.warning,
          'Sem temperatura mínima local validada: o limite de Voc '
          'a frio não foi verificado.');
    }
    issue('BYPASS_MODEL_NOT_CALIBRATED', 'Projeto',
        Solar3dElectricalSeverity.info,
        'Datasheets atuais não descrevem a topologia de células e '
        'diodos de bypass. Perdas I-V/DC e clipping AC por '
        'sombreamento não são calculáveis com precisão.');
    return Solar3dElectricalAudit._(
      findings: List.unmodifiable(findings),
      trackers: List.unmodifiable(trackers),
      totalPanels: expected.length,
      assignedPanels: assignedCount,
      minimumAmbientC: minimumAmbientC,
    );
  }
}
