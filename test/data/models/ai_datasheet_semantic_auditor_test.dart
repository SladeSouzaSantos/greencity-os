import 'package:flutter_test/flutter_test.dart';
import 'package:greencity_os/data/models/ai_datasheet_semantic_auditor.dart';
import 'package:greencity_os/data/models/ai_extraction_result_model.dart';

void main() {
  test('Jetion: não confunde garantia física e corrige limites explícitos', () {
    final raw = AiExtractionResultModel.fromJson({
      'modules': [{
        'manufacturer': 'Jetion Solar', 'modelName': 'JT690SLk(B)',
        'powerWp': 690, 'efficiency': 22.2, 'physicalWarranty': 30,
        'efficiencyWarranty': 30, 'efficiencyLoss': 10,
      }],
      'inverters': [],
    });
    const text = '''
Jetion Solar JT690SLk(B) JT695SLk(B) JT700SLk(B)
30 years linear performance warranty<10%
Guaranteed Power 100% 99% 90.3%
Maximum System Voltage 1500V/DC(IEC)
Operating Temperature -40°C-+85°C
Maximum Series Fuse 35A
''';
    final audit = AiDatasheetSemanticAuditor.audit(raw, text);
    final m = audit.modules.single;
    expect(m.physicalWarranty, isNull);
    expect(m.efficiencyWarranty, 30);
    expect(m.efficiencyLoss, isNull);
    expect(m.fuseCurrent, 35);
    expect(m.minOperatingTemp, -40);
    expect(m.maxOperatingTemp, 85);
    final issues = audit.auditWarnings[AiDatasheetSemanticAuditor.key(m)]!;
    expect(issues.any((s) => s.contains('garantia física')), isTrue);
    expect(issues.any((s) => s.contains('degradação final')), isTrue);
  });

  test('AUXSOL: 2 MPPTs, 3 entradas CC e corrente CA por coluna', () {
    final raw = AiExtractionResultModel.fromJson({
      'modules': [],
      'inverters': [
        {'manufacturer': 'AUXSOL', 'modelName': 'ASN-9SL',
         'nominalPowerKw': 9, 'mpptCount': 2, 'totalDcInputs': 2},
        {'manufacturer': 'AUXSOL', 'modelName': 'ASN-10SL',
         'nominalPowerKw': 10, 'mpptCount': 2, 'totalDcInputs': 2},
        {'manufacturer': 'AUXSOL', 'modelName': 'ASN-10.5SL',
         'nominalPowerKw': 10.5, 'mpptCount': 2, 'totalDcInputs': 2},
      ]
    });
    const text = '''
Rev. 20/07/2026
Modelo ASN-9SL ASN-10SL ASN-10.5SL
Potência CC Máx. Recomendada 18kW 20kW 21kW
Corrente Máx. (Impp) 32A/16A 32A/16A 32A/16A
Corrente Máx. Curto Circuito (Isc) 40A/20A 40A/20A 40A/20A
Quantidade MPPT 2 2 2
Número de Entradas do Inversor 3 3 3
Corrente Máx. de Saída 40.9A 45.5A 47.7A
''';
    final audit = AiDatasheetSemanticAuditor.audit(raw, text);
    expect(audit.inverters.map((i) => i.mpptCount), [2, 2, 2]);
    expect(audit.inverters.map((i) => i.totalDcInputs), [3, 3, 3]);
    expect(audit.inverters.map((i) => i.maxOutputCurrent),
        [40.9, 45.5, 47.7]);
    expect(
      audit.auditWarnings[
        AiDatasheetSemanticAuditor.key(audit.inverters[1])
      ]!.any((s) => s.contains('entradas CC')),
      isTrue,
    );
  });

  test('colunas distintas sem associação segura não geram valores', () {
    final raw = AiExtractionResultModel.fromJson({
      'modules': [], 'inverters': [{
        'manufacturer': 'Outra', 'modelName': 'INV-A',
        'nominalPowerKw': 5, 'totalDcInputs': 2,
      }]
    });
    const text = '''
Datasheet com modelos INV-A, INV-B e INV-C
Modelo INV-A INV-B INV-C
Quantidade MPPT 2 3 4
Número de Entradas do Inversor 2 3 4
Corrente Máx. de Saída 20A 21A 22A
Sem mapeamento completo de todas as colunas, não inferir.
''';
    final audit = AiDatasheetSemanticAuditor.audit(raw, text);
    expect(audit.inverters.single.totalDcInputs, 2);
    expect(audit.inverters.single.maxOutputCurrent, isNull);
    expect(audit.inverters.single.mpptCount, isNull);
    expect(audit.auditWarnings.values.single
        .any((message) => message.contains('NÃO CONFIRMADO')), isTrue);
  });

  test('tabelas Markdown reais: Jetion recupera fusível e temperaturas', () {
    final original = AiExtractionResultModel.fromJson({
      'modules': [{
        'manufacturer': 'Jetion Solar', 'modelName': 'JT690SLk(B)',
        'powerWp': 690, 'efficiencyWarranty': 30,
      }],
      'inverters': [],
    });
    const pdfMarkdown = '''
## ELECTRICAL DATA
| Item | Value |
| :-- | :-- |
| Maximum System Voltage | 1500V/DC(IEC) |
| Operating Temperature | -40°C-+85°C |
| Maximum Series Fuse | 35A |
| Warranty | 30 years linear performance warranty<10% |
''';
    final item = AiDatasheetSemanticAuditor.audit(
      original, pdfMarkdown,
    ).modules.single;
    expect(item.fuseCurrent, 35);
    expect(item.minOperatingTemp, -40);
    expect(item.maxOperatingTemp, 85);
    expect(item.physicalWarranty, isNull);
  });

  test('tabela Markdown corrige inversão MPPTs/entradas sem trocar colunas', () {
    final original = AiExtractionResultModel.fromJson({
      'modules': [],
      'inverters': [
        for (final m in ['ASN-9SL', 'ASN-10SL', 'ASN-10.5SL'])
          {'manufacturer': 'AUXSOL', 'modelName': m,
           'nominalPowerKw': 10, 'mpptCount': 3, 'totalDcInputs': 2}
      ],
    });
    const pdfMarkdown = '''
| Modelo | ASN-9SL | ASN-10SL | ASN-10.5SL |
| :--- | :--- | :--- | :--- |
| Quantidade MPPT | 2 | 2 | 2 |
| Número de Entradas do Inversor | 3 | 3 | 3 |
| Corrente Máx. de Saída | 40.9A | 45.5A | 47.7A |
''';
    final checked = AiDatasheetSemanticAuditor.audit(
      original, pdfMarkdown,
    );
    expect(checked.inverters.map((i) => i.mpptCount), [2, 2, 2]);
    expect(checked.inverters.map((i) => i.totalDcInputs), [3, 3, 3]);
    expect(checked.inverters.map((i) => i.maxOutputCurrent),
        [40.9, 45.5, 47.7]);
    expect(checked.auditWarnings.values.every((messages) =>
        messages.any((m) => m.contains('INCONSISTENTE'))), isTrue);
  });

  test('topologia impossível gera aviso mesmo com fonte sem tabela', () {
    final original = AiExtractionResultModel.fromJson({
      'modules': [],
      'inverters': [{'manufacturer': 'AUXSOL',
        'modelName': 'ASN-9SL', 'nominalPowerKw': 9,
        'mpptCount': 3, 'totalDcInputs': 2,
      }],
    });
    final checked = AiDatasheetSemanticAuditor.audit(
      original, 'Ficha técnica AUXSOL com alguns parâmetros elétricos '
          'de entrada CC, tensão de rede, potência nominal e eficiência.',
    );
    expect(checked.auditWarnings.values.single
        .any((v) => v.contains('Entradas precisam')), isTrue);
  });

  test('garantia física explicitamente documentada permanece', () {
    final raw = AiExtractionResultModel.fromJson({
      'modules': [{
        'manufacturer': 'Exemplo', 'modelName': 'M',
        'powerWp': 700, 'physicalWarranty': 12,
        'efficiencyWarranty': 30,
      }],
      'inverters': [],
    });
    const text = '''
Specifications
12 years product warranty
30 years linear performance warranty
Modules under STC conditions
''';
    expect(AiDatasheetSemanticAuditor.audit(raw, text)
        .modules.single.physicalWarranty, 12);
  });

  test('sem texto de origem exige revisão antes de importação em lote', () {
    final raw = AiExtractionResultModel.fromJson({
      'modules': [{'manufacturer': 'X', 'modelName': 'Y'}],
      'inverters': [],
    });
    final audited = AiDatasheetSemanticAuditor.audit(raw, null);
    expect(audited.auditWarnings.values.single.single,
        contains('NÃO AUDITADO'));
  });
}
