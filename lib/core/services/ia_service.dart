import 'dart:convert';
import 'dart:io';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../../data/models/ai_extraction_result_model.dart';

class IAService {
  String get _apiKey {
    final key = dotenv.env['GEMINI_API_KEY']?.trim();
    if (key == null || key.isEmpty) {
      throw StateError(
        'GEMINI_API_KEY não configurada. Crie um arquivo .env na raiz do projeto.',
      );
    }
    return key;
  } 

  Future<AiExtractionResultModel> extractEquipmentData(String filePath) async {
    final model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: _apiKey);
    final fileBytes = await File(filePath).readAsBytes();

    final prompt = [
      Content.multi([
        TextPart("""Analise este datasheet solar e extraia TODOS os modelos/variações de potência presentes na tabela técnica.
        Retorne um JSON com esta estrutura exata:
        {
          "modules": [ 
            { "manufacturer": "string", "modelName": "string", "powerWp": number, "efficiency": number, "vOc": number, "iSc": number, "vMp": number, "iMp": number, "cellTechnology": "PERC|TOPCon", "isBifacial": bool, "length": number, "width": number, "weight": number, "tempCoefPmax": number, "tempCoefVoc": number, "tempCoefIsc": number }
          ],
          "inverters": [
            { "manufacturer": "string", "modelName": "string", "nominalPowerKw": number, "maxInputPowerKw": number, "mpptCount": number, "maxInputVoltage": number, "maxEfficiency": number, "maxOutputCurrent": number, "inverterType": "string|micro", "gridConnection": "monophasic|triphasic", "isHybrid": bool, "weight": number }
          ]
        }
        Se for um datasheet de módulo, preencha a lista 'modules'. Se for inversor, preencha 'inverters'. 
        Extraia todas as variações da tabela (ex: 450W, 455W, 460W)."""),
        DataPart('application/pdf', fileBytes),
      ])
    ];

    final response = await model.generateContent(prompt);
    
    if (response.text != null) {
      String cleanJson = response.text!.replaceAll('```json', '').replaceAll('```', '').trim();
      return AiExtractionResultModel.fromJson(jsonDecode(cleanJson));
    }
    throw Exception("Falha ao extrair dados do datasheet");
  }

  Future<Map<String, dynamic>?> analyzeDatasheet(String filePath) async {
    final model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: _apiKey);
    final fileBytes = await File(filePath).readAsBytes();

    // Prompt agressivo para garantir que ele retorne apenas JSON
    final prompt = [
      Content.multi([
        TextPart("""Analise este datasheet de equipamento solar. 
        Extraia: Fabricante, Modelo e Potência (Wp para módulos ou kW para inversores).
        Retorne APENAS um JSON no formato: 
        {"manufacturer": "string", "modelName": "string", "power": number}
        Não escreva mais nada além do JSON."""),
        DataPart('application/pdf', fileBytes),
      ])
    ];

    final response = await model.generateContent(prompt);
    
    if (response.text != null) {
      // Limpa possíveis marcações de Markdown que o Gemini coloca (```json ...)
      String cleanJson = response.text!.replaceAll('```json', '').replaceAll('```', '').trim();
      return jsonDecode(cleanJson);
    }
    return null;
  }
}