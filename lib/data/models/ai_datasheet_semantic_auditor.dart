import 'ai_extraction_result_model.dart';

/// Verifica apenas valores explicitamente rastreáveis ao PDF.
/// Não infere distribuição entre colunas com correspondência ambígua.
class AiDatasheetSemanticAuditor {
  static String key(Object item) {
    if (item is AiExtractedModule) {
      return 'module:${item.manufacturer.toLowerCase().trim()}::'
          '${item.modelName.toLowerCase().trim()}';
    }
    final i = item as AiExtractedInverter;
    return 'inverter:${i.manufacturer.toLowerCase().trim()}::'
        '${i.modelName.toLowerCase().trim()}';
  }

  static AiExtractionResultModel audit(
      AiExtractionResultModel original, String? source) {
    final warnings = <String, List<String>>{};
    if (source == null || source.trim().length < 50) {
      for (final item in <Object>[...original.modules, ...original.inverters]) {
        warnings[key(item)] = [
          'NÃO AUDITADO: texto da ficha indisponível. '
          'Confira o PDF antes de salvar.'
        ];
      }
      return AiExtractionResultModel(
        modules: original.modules, inverters: original.inverters,
        auditWarnings: warnings,
      );
    }

    final fuse = _fuse(source);
    final temperatures = _temperatures(source);
    final productWarranty = _warranty(source, product: true);
    final performanceWarranty = _warranty(source, product: false);
    final exactLoss = _finalLoss(source);
    final modules = <AiExtractedModule>[];
    for (final m in original.modules) {
      final issues = <String>[];
      var physical = m.physicalWarranty;
      var performance = m.efficiencyWarranty;
      var loss = m.efficiencyLoss;
      if (physical != null && physical != productWarranty) {
        issues.add('INCONSISTENTE: garantia física não comprovada no '
            'datasheet. Não usar a garantia de desempenho como garantia física.');
        physical = null;
      }
      if (performanceWarranty != null &&
          performanceWarranty != performance) {
        issues.add('EXTRAÍDO DA FONTE: garantia de desempenho '
            '$performanceWarranty anos.');
        performance = performanceWarranty;
      }
      if (loss != null &&
          (exactLoss == null || (loss - exactLoss).abs() > 0.01)) {
        issues.add('NÃO CONFIRMADO: degradação final informada como '
            '$loss%, sem evidência de valor exato.');
        loss = null;
      }
      loss ??= exactLoss;
      var fuseCurrent = m.fuseCurrent;
      var low = m.minOperatingTemp;
      var high = m.maxOperatingTemp;
      if (fuse != null &&
          (fuseCurrent == null || (fuse - fuseCurrent).abs() > 0.01)) {
        fuseCurrent = fuse;
        issues.add('EXTRAÍDO DA FONTE: fusível máximo $fuse A.');
      }
      if (temperatures != null) {
        if (low == null || low != temperatures.$1) {
          low = temperatures.$1;
          issues.add('EXTRAÍDO DA FONTE: temperatura mínima $low °C.');
        }
        if (high == null || high != temperatures.$2) {
          high = temperatures.$2;
          issues.add('EXTRAÍDO DA FONTE: temperatura máxima $high °C.');
        }
      }
      final updated = AiExtractedModule(
        manufacturer: m.manufacturer, modelName: m.modelName,
        powerWp: m.powerWp, efficiency: m.efficiency,
        cellTechnology: m.cellTechnology,
        vOc: m.vOc, iSc: m.iSc, vMp: m.vMp, iMp: m.iMp,
        length: m.length, width: m.width, weight: m.weight,
        isBifacial: m.isBifacial, isTier1: m.isTier1,
        maxSystemVoltage: m.maxSystemVoltage,
        tempCoefPmax: m.tempCoefPmax, tempCoefVoc: m.tempCoefVoc,
        tempCoefIsc: m.tempCoefIsc,
        minOperatingTemp: low, maxOperatingTemp: high,
        fuseCurrent: fuseCurrent, physicalWarranty: physical,
        efficiencyWarranty: performance, efficiencyLoss: loss,
      );
      modules.add(updated);
      if (issues.isNotEmpty) warnings[key(updated)] = issues;
    }

    final trackers = _uniformRow(source, RegExp(
      r'(?:quantidade\s+(?:de\s+)?mppts?|number\s+of\s+mppts?)',
      caseSensitive: false,
    ));
    final dcInputs = _uniformRow(source, RegExp(
      r'(?:n[uú]mero\s+de\s+entradas(?:\s+do\s+inversor)?|'
      r'(?:number|total)\s+of\s+(?:dc\s+)?inputs)',
      caseSensitive: false,
    ));
    final inverters = <AiExtractedInverter>[];
    for (final i in original.inverters) {
      final issues = <String>[];
      var count = i.mpptCount;
      var inputs = i.totalDcInputs;
      if (count != null && inputs != null && inputs < count) {
        issues.add('INCONSISTENTE: $count rastreadores MPPT para apenas '
            '$inputs entradas CC. Entradas precisam ser >= MPPTs.');
      }
      if (trackers == null && _row(source, RegExp(
            r'(?:quantidade\s+(?:de\s+)?mppts?|number\s+of\s+mppts?)',
            caseSensitive: false)) != null) {
        issues.add('NÃO CONFIRMADO: a tabela apresenta quantidades '
            'de MPPT distintas ou não legíveis por modelo.');
      }
      if (dcInputs == null && _row(source, RegExp(
            r'(?:n[uú]mero\s+de\s+entradas(?:\s+do\s+inversor)?|'
            r'(?:number|total)\s+of\s+(?:dc\s+)?inputs)',
            caseSensitive: false)) != null) {
        issues.add('NÃO CONFIRMADO: entradas CC distintas por modelo; '
            'confira a coluna correspondente no PDF.');
      }
      if (trackers != null && trackers != count) {
        issues.add('INCONSISTENTE: MPPTs ${count ?? "?"}; '
            'PDF indica $trackers.');
        count = trackers;
      }
      if (dcInputs != null && dcInputs != inputs) {
        issues.add('INCONSISTENTE: entradas CC ${inputs ?? "?"}; '
            'PDF indica $dcInputs.');
        inputs = dcInputs;
      }
      final ac = _acCurrent(source, i, original.inverters);
      var output = i.maxOutputCurrent;
      if (ac != null && (output == null || (output - ac).abs() > 0.01)) {
        issues.add('EXTRAÍDO DA FONTE: corrente máxima CA '
            '$ac A para ${i.modelName}.');
        output = ac;
      }
      final updated = AiExtractedInverter(
        manufacturer: i.manufacturer, modelName: i.modelName,
        nominalPowerKw: i.nominalPowerKw,
        maxInputPowerKw: i.maxInputPowerKw,
        maxEfficiency: i.maxEfficiency, euroEfficiency: i.euroEfficiency,
        mpptCount: count, totalDcInputs: inputs,
        maxInputVoltage: i.maxInputVoltage,
        nominalVoltageDc: i.nominalVoltageDc,
        startVoltage: i.startVoltage,
        minMpptVoltage: i.minMpptVoltage, maxMpptVoltage: i.maxMpptVoltage,
        maxInputCurrentPerMppt: i.maxInputCurrentPerMppt,
        mpptInputCurrentsA: i.mpptInputCurrentsA,
        mpptShortCircuitCurrentsA: i.mpptShortCircuitCurrentsA,
        maxShortCircuitCurrent: i.maxShortCircuitCurrent,
        maxOutputCurrent: output, nominalVoltageAc: i.nominalVoltageAc,
        inverterType: i.inverterType, gridConnection: i.gridConnection,
        isHybrid: i.isHybrid, dimensions: i.dimensions,
        weight: i.weight, minOperatingTemp: i.minOperatingTemp,
        maxOperatingTemp: i.maxOperatingTemp,
        protectionDegree: i.protectionDegree, warrantyYears: i.warrantyYears,
      );
      inverters.add(updated);
      if (issues.isNotEmpty) warnings[key(updated)] = issues;
    }
    return AiExtractionResultModel(
      modules: modules, inverters: inverters, auditWarnings: warnings,
    );
  }

  static String? _row(String text, RegExp label) {
    final lines = text.split(RegExp(r'\r?\n'));
    for (var n = 0; n < lines.length; n++) {
      final match = label.firstMatch(lines[n]);
      if (match == null) continue;
      // PDFs convertidos para Markdown normalmente possuem células como
      // "| Operating Temperature | -40°C-+85°C |". Sem remover bordas
      // e formatação, os parsers numéricos deixam os campos em branco.
      String clean(String value) => value.trim()
          .replaceFirst(RegExp(r'^[\s*_:|]+'), '')
          .replaceFirst(RegExp(r'[\s*_|]+
    }
    return null;
  }

  static int? _uniformRow(String source, RegExp label) {
    final row = _row(source, label);
    if (row == null) return null;
    final values = row.replaceAll('|', ' ').trim();
    if (!RegExp(r'^\d{1,2}(?:\s+\d{1,2})*$').hasMatch(values)) return null;
    final nums = values.split(RegExp(r'\s+')).map(int.parse).toList();
    if (nums.any((n) => n <= 0)) return null;
    return nums.every((n) => n == nums.first) ? nums.first : null;
  }

  static double? _fuse(String text) {
    final row = _row(text, RegExp(
        r'(?:maximum\s+series\s+fuse|fus[ií]vel\s+m[aá]ximo)',
        caseSensitive: false));
    if (row == null) return null;
    final match = RegExp(r'^\s*(\d+(?:[.,]\d+)?)\s*A\b',
        caseSensitive: false).firstMatch(row);
    return match == null ? null :
        double.tryParse(match.group(1)!.replaceAll(',', '.'));
  }

  static (double, double)? _temperatures(String text) {
    final row = _row(text, RegExp(
        r'(?:operating\s+temperature|temperatura\s+(?:de\s+)?opera[cç][aã]o)',
        caseSensitive: false));
    if (row == null) return null;
    final m = RegExp(
        r'(-\d{1,3})\s*°?\s*C?\s*[-–~.]{1,3}\s*\+?(\d{1,3})\s*°?\s*C',
        caseSensitive: false).firstMatch(row);
    if (m == null) return null;
    final lo = double.parse(m.group(1)!);
    final hi = double.parse(m.group(2)!);
    return lo < hi ? (lo, hi) : null;
  }

  static int? _warranty(String text, {required bool product}) {
    final patterns = product ? [
      RegExp(r'(\d{1,2})\s*years?\s+(?:product|material|'
          r'workmanship|physical)\s+warranty', caseSensitive: false),
      RegExp(r'(?:product|material|workmanship|physical)\s+warranty'
          r'\s*:?\s*(\d{1,2})\s*years?', caseSensitive: false),
      RegExp(r'garantia\s+(?:f[ií]sica|do\s+produto)\s*:?\s*'
          r'(\d{1,2})\s*anos', caseSensitive: false),
    ] : [
      RegExp(r'(\d{1,2})\s*years?\s+(?:linear\s+)?'
          r'(?:performance|power)\s+warranty', caseSensitive: false),
    ];
    for (final pattern in patterns) {
      final m = pattern.firstMatch(text);
      if (m != null) return int.tryParse(m.group(1)!);
    }
    return null;
  }

  static double? _finalLoss(String text) {
    final m = RegExp(
      r'(?:final\s+power\s+loss|total\s+degradation|'
      r'perda\s+(?:final|total)\s+(?:de\s+efici[eê]ncia)?)'
      r'\s*:?\s*(\d+(?:[.,]\d+)?)\s*%',
      caseSensitive: false,
    ).firstMatch(text);
    return m == null ? null :
        double.tryParse(m.group(1)!.replaceAll(',', '.'));
  }

  static double? _acCurrent(
      String text, AiExtractedInverter target, List<AiExtractedInverter> all) {
    String? header;
    for (final line in text.split(RegExp(r'\r?\n'))) {
      if (RegExp(r'\b(?:modelo|model)\b', caseSensitive: false)
          .hasMatch(line) &&
          line.toLowerCase().contains(target.modelName.toLowerCase())) {
        header = line;
        break;
      }
    }
    if (header == null) return null;
    final heading = header.toLowerCase();
    final models = all.where((i) => heading.contains(i.modelName.toLowerCase()))
        .toList()
      ..sort((a, b) => heading.indexOf(a.modelName.toLowerCase())
          .compareTo(heading.indexOf(b.modelName.toLowerCase())));
    if (models.isEmpty || models.length != all.length) return null;
    final row = _row(text, RegExp(
      r'(?:corrente\s+m[aá]x(?:ima|\.)?\s+de\s+sa[ií]da|'
      r'max(?:imum)?\.?\s+(?:ac\s+)?output\s+current)',
      caseSensitive: false,
    ));
    if (row == null) return null;
    final values = RegExp(r'(\d+(?:[.,]\d+)?)\s*A\b',
        caseSensitive: false)
        .allMatches(row)
        .map((m) => double.tryParse(m.group(1)!.replaceAll(',', '.')))
        .toList();
    if (values.length != models.length || values.any((v) => v == null)) {
      return null;
    }
    final index = models.indexWhere(
        (i) => i.modelName.toLowerCase() == target.modelName.toLowerCase());
    return index < 0 ? null : values[index];
  }
}
), '')
          .trim();
      final rest = clean(lines[n].substring(match.end));
      if (rest.isNotEmpty) return rest;
      if (n + 1 < lines.length) {
        final next = clean(lines[n + 1]);
        if (RegExp(r'^[\d\s|/.,+°CA-]+
    }
    return null;
  }

  static int? _uniformRow(String source, RegExp label) {
    final row = _row(source, label);
    if (row == null) return null;
    final values = row.replaceAll('|', ' ').trim();
    if (!RegExp(r'^\d{1,2}(?:\s+\d{1,2})*$').hasMatch(values)) return null;
    final nums = values.split(RegExp(r'\s+')).map(int.parse).toList();
    if (nums.any((n) => n <= 0)) return null;
    return nums.every((n) => n == nums.first) ? nums.first : null;
  }

  static double? _fuse(String text) {
    final row = _row(text, RegExp(
        r'(?:maximum\s+series\s+fuse|fus[ií]vel\s+m[aá]ximo)',
        caseSensitive: false));
    if (row == null) return null;
    final match = RegExp(r'^\s*(\d+(?:[.,]\d+)?)\s*A\b',
        caseSensitive: false).firstMatch(row);
    return match == null ? null :
        double.tryParse(match.group(1)!.replaceAll(',', '.'));
  }

  static (double, double)? _temperatures(String text) {
    final row = _row(text, RegExp(
        r'(?:operating\s+temperature|temperatura\s+(?:de\s+)?opera[cç][aã]o)',
        caseSensitive: false));
    if (row == null) return null;
    final m = RegExp(
        r'(-\d{1,3})\s*°?\s*C?\s*[-–~.]{1,3}\s*\+?(\d{1,3})\s*°?\s*C',
        caseSensitive: false).firstMatch(row);
    if (m == null) return null;
    final lo = double.parse(m.group(1)!);
    final hi = double.parse(m.group(2)!);
    return lo < hi ? (lo, hi) : null;
  }

  static int? _warranty(String text, {required bool product}) {
    final patterns = product ? [
      RegExp(r'(\d{1,2})\s*years?\s+(?:product|material|'
          r'workmanship|physical)\s+warranty', caseSensitive: false),
      RegExp(r'(?:product|material|workmanship|physical)\s+warranty'
          r'\s*:?\s*(\d{1,2})\s*years?', caseSensitive: false),
      RegExp(r'garantia\s+(?:f[ií]sica|do\s+produto)\s*:?\s*'
          r'(\d{1,2})\s*anos', caseSensitive: false),
    ] : [
      RegExp(r'(\d{1,2})\s*years?\s+(?:linear\s+)?'
          r'(?:performance|power)\s+warranty', caseSensitive: false),
    ];
    for (final pattern in patterns) {
      final m = pattern.firstMatch(text);
      if (m != null) return int.tryParse(m.group(1)!);
    }
    return null;
  }

  static double? _finalLoss(String text) {
    final m = RegExp(
      r'(?:final\s+power\s+loss|total\s+degradation|'
      r'perda\s+(?:final|total)\s+(?:de\s+efici[eê]ncia)?)'
      r'\s*:?\s*(\d+(?:[.,]\d+)?)\s*%',
      caseSensitive: false,
    ).firstMatch(text);
    return m == null ? null :
        double.tryParse(m.group(1)!.replaceAll(',', '.'));
  }

  static double? _acCurrent(
      String text, AiExtractedInverter target, List<AiExtractedInverter> all) {
    String? header;
    for (final line in text.split(RegExp(r'\r?\n'))) {
      if (RegExp(r'\b(?:modelo|model)\b', caseSensitive: false)
          .hasMatch(line) &&
          line.toLowerCase().contains(target.modelName.toLowerCase())) {
        header = line;
        break;
      }
    }
    if (header == null) return null;
    final heading = header.toLowerCase();
    final models = all.where((i) => heading.contains(i.modelName.toLowerCase()))
        .toList()
      ..sort((a, b) => heading.indexOf(a.modelName.toLowerCase())
          .compareTo(heading.indexOf(b.modelName.toLowerCase())));
    if (models.isEmpty || models.length != all.length) return null;
    final row = _row(text, RegExp(
      r'(?:corrente\s+m[aá]x(?:ima|\.)?\s+de\s+sa[ií]da|'
      r'max(?:imum)?\.?\s+(?:ac\s+)?output\s+current)',
      caseSensitive: false,
    ));
    if (row == null) return null;
    final values = RegExp(r'(\d+(?:[.,]\d+)?)\s*A\b',
        caseSensitive: false)
        .allMatches(row)
        .map((m) => double.tryParse(m.group(1)!.replaceAll(',', '.')))
        .toList();
    if (values.length != models.length || values.any((v) => v == null)) {
      return null;
    }
    final index = models.indexWhere(
        (i) => i.modelName.toLowerCase() == target.modelName.toLowerCase());
    return index < 0 ? null : values[index];
  }
}
).hasMatch(next)) return next;
      }
    }
    return null;
  }

  static int? _uniformRow(String source, RegExp label) {
    final row = _row(source, label);
    if (row == null) return null;
    final values = row.replaceAll('|', ' ').trim();
    if (!RegExp(r'^\d{1,2}(?:\s+\d{1,2})*$').hasMatch(values)) return null;
    final nums = values.split(RegExp(r'\s+')).map(int.parse).toList();
    if (nums.any((n) => n <= 0)) return null;
    return nums.every((n) => n == nums.first) ? nums.first : null;
  }

  static double? _fuse(String text) {
    final row = _row(text, RegExp(
        r'(?:maximum\s+series\s+fuse|fus[ií]vel\s+m[aá]ximo)',
        caseSensitive: false));
    if (row == null) return null;
    final match = RegExp(r'^\s*(\d+(?:[.,]\d+)?)\s*A\b',
        caseSensitive: false).firstMatch(row);
    return match == null ? null :
        double.tryParse(match.group(1)!.replaceAll(',', '.'));
  }

  static (double, double)? _temperatures(String text) {
    final row = _row(text, RegExp(
        r'(?:operating\s+temperature|temperatura\s+(?:de\s+)?opera[cç][aã]o)',
        caseSensitive: false));
    if (row == null) return null;
    final m = RegExp(
        r'(-\d{1,3})\s*°?\s*C?\s*[-–~.]{1,3}\s*\+?(\d{1,3})\s*°?\s*C',
        caseSensitive: false).firstMatch(row);
    if (m == null) return null;
    final lo = double.parse(m.group(1)!);
    final hi = double.parse(m.group(2)!);
    return lo < hi ? (lo, hi) : null;
  }

  static int? _warranty(String text, {required bool product}) {
    final patterns = product ? [
      RegExp(r'(\d{1,2})\s*years?\s+(?:product|material|'
          r'workmanship|physical)\s+warranty', caseSensitive: false),
      RegExp(r'(?:product|material|workmanship|physical)\s+warranty'
          r'\s*:?\s*(\d{1,2})\s*years?', caseSensitive: false),
      RegExp(r'garantia\s+(?:f[ií]sica|do\s+produto)\s*:?\s*'
          r'(\d{1,2})\s*anos', caseSensitive: false),
    ] : [
      RegExp(r'(\d{1,2})\s*years?\s+(?:linear\s+)?'
          r'(?:performance|power)\s+warranty', caseSensitive: false),
    ];
    for (final pattern in patterns) {
      final m = pattern.firstMatch(text);
      if (m != null) return int.tryParse(m.group(1)!);
    }
    return null;
  }

  static double? _finalLoss(String text) {
    final m = RegExp(
      r'(?:final\s+power\s+loss|total\s+degradation|'
      r'perda\s+(?:final|total)\s+(?:de\s+efici[eê]ncia)?)'
      r'\s*:?\s*(\d+(?:[.,]\d+)?)\s*%',
      caseSensitive: false,
    ).firstMatch(text);
    return m == null ? null :
        double.tryParse(m.group(1)!.replaceAll(',', '.'));
  }

  static double? _acCurrent(
      String text, AiExtractedInverter target, List<AiExtractedInverter> all) {
    String? header;
    for (final line in text.split(RegExp(r'\r?\n'))) {
      if (RegExp(r'\b(?:modelo|model)\b', caseSensitive: false)
          .hasMatch(line) &&
          line.toLowerCase().contains(target.modelName.toLowerCase())) {
        header = line;
        break;
      }
    }
    if (header == null) return null;
    final heading = header.toLowerCase();
    final models = all.where((i) => heading.contains(i.modelName.toLowerCase()))
        .toList()
      ..sort((a, b) => heading.indexOf(a.modelName.toLowerCase())
          .compareTo(heading.indexOf(b.modelName.toLowerCase())));
    if (models.isEmpty || models.length != all.length) return null;
    final row = _row(text, RegExp(
      r'(?:corrente\s+m[aá]x(?:ima|\.)?\s+de\s+sa[ií]da|'
      r'max(?:imum)?\.?\s+(?:ac\s+)?output\s+current)',
      caseSensitive: false,
    ));
    if (row == null) return null;
    final values = RegExp(r'(\d+(?:[.,]\d+)?)\s*A\b',
        caseSensitive: false)
        .allMatches(row)
        .map((m) => double.tryParse(m.group(1)!.replaceAll(',', '.')))
        .toList();
    if (values.length != models.length || values.any((v) => v == null)) {
      return null;
    }
    final index = models.indexWhere(
        (i) => i.modelName.toLowerCase() == target.modelName.toLowerCase());
    return index < 0 ? null : values[index];
  }
}
