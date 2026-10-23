import 'dart:convert';
import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

import '../../data/models/ai_extraction_result_model.dart';

/// Extração de múltiplos equipamentos a partir de datasheets PDF.
/// O documento é enviado ao Gemini apenas após seleção explícita do usuário.
class IAService {
  String get _apiKey {
    final key = dotenv.env['GEMINI_API_KEY']?.trim();
    if (key == null || key.isEmpty) {
      throw StateError(
        'GEMINI_API_KEY ausente no .env. Configure a chave para importar PDFs.',
      );
    }
    return key;
  }

  String get _model {
    final configured = dotenv.env['GEMINI_MODEL']?.trim();
    return configured == null || configured.isEmpty
        ? 'gemini-3.8-flash'
        : configured;
  }

  Future<AiExtractionResultModel> extractEquipmentData(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw const FormatException('Arquivo PDF não encontrado.');
    }
    final length = await file.length();
    if (length == 0 || length > 20 * 1024 * 1024) {
      throw const FormatException('O PDF deve ter entre 1 byte e 20 MB.');
    }
    final bytes = await file.readAsBytes();
    if (bytes.length < 5 ||
        String.fromCharCodes(bytes.take(5)) != '%PDF-') {
      throw const FormatException('Selecione um arquivo PDF válido.');
    }

    final model = GenerativeModel(
      model: _model,
      apiKey: _apiKey,
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
        temperature: 0.1,
      ),
    );

    const prompt = '''
Analise o PDF de datasheet fotovoltaico e devolva SOMENTE JSON
com duas listas: "modules" e "inverters" (listas vazias se não houver).
Extraia TODOS os modelos exatos e variações, um objeto por modelo, SEM
agrupar várias potências em um único objeto. Se o PDF listar 600, 605 e
610 W, gere três módulos, cada um com seus próprios dados STC.
Extraia apenas o que estiver explícito no documento. NÃO estime, NÃO
extrapole valores de tabelas, NÃO invente dimensões, eficiência, tipo ou
garantias. Para cada campo não informado retorne null. Use números JSON
sem unidade, ponto decimal e booleanos JSON. Mantenha a potência de
módulos em Wp, de inversores em kW; dimensões de módulos em mm, peso
em kg, temperatura em °C, tensão em V, corrente em A.
Eficiência de módulo em porcentagem (ex: 22.8) e eficiência de
inversor em porcentagem (ex: 98.2). Coeficientes térmicos em %/°C.
Use parâmetros de STC, não NMOT. Preserve o fabricante e o código
integral do modelo (incluindo sufixos); repita dados compartilhados
da família para cada variante SOMENTE se estiverem no documento.

Estrutura:
{
 "modules": [{
   "manufacturer": "string", "modelName": "string",
   "powerWp": null, "efficiency": null,
   "cellTechnology": "TOPCON|PERC|AL_BSF|HJT",
   "isBifacial": null, "isTier1": null,
   "length": null, "width": null, "weight": null,
   "vOc": null, "iSc": null, "vMp": null, "iMp": null,
   "maxSystemVoltage": null, "tempCoefPmax": null,
   "tempCoefVoc": null, "tempCoefIsc": null,
   "minOperatingTemp": null, "maxOperatingTemp": null,
   "fuseCurrent": null, "physicalWarranty": null,
   "efficiencyWarranty": null, "efficiencyLoss": null
 }],
 "inverters": [{
   "manufacturer": "string", "modelName": "string",
   "inverterType": "string|microInverter|optimizer",
   "gridConnection": "monophasic|biphasic|triphasic",
   "isHybrid": null, "nominalPowerKw": null,
   "maxInputPowerKw": null, "maxEfficiency": null,
   "euroEfficiency": null, "mpptCount": null,
   "maxInputVoltage": null, "nominalVoltageDc": null,
   "startVoltage": null, "minMpptVoltage": null,
   "maxMpptVoltage": null, "maxInputCurrentPerMppt": null,
   "maxShortCircuitCurrent": null, "maxOutputCurrent": null,
   "nominalVoltageAc": null, "dimensions": null,
   "weight": null, "minOperatingTemp": null,
   "maxOperatingTemp": null, "protectionDegree": null,
   "warrantyYears": null
 }]
}

Se o documento não permitir identificar modelos distintos, devolva
listas vazias. Não crie modelos por interpolação ou intervalo.
''';

    final response = await model.generateContent([
      Content.multi([
        TextPart(prompt),
        DataPart('application/pdf', bytes),
      ]),
    ]);

    final responseText = response.text?.trim();
    if (responseText == null || responseText.isEmpty) {
      throw const FormatException('A IA não retornou dados.');
    }
    final jsonText = responseText
        .replaceAll(RegExp(r'^\s*\x60\x60\x60(?:json)?\s*'), '')
        .replaceAll(RegExp(r'\s*\x60\x60\x60\s*$'), '');
    final decoded = jsonDecode(jsonText);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('A IA retornou um JSON inesperado.');
    }
    final result = AiExtractionResultModel.fromJson(decoded);
    if (result.modules.isEmpty && result.inverters.isEmpty) {
      throw const FormatException(
        'Nenhum módulo ou inversor foi identificado no PDF.',
      );
    }
    return result;
  }
}
