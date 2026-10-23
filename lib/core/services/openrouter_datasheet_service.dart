import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../../data/models/ai_extraction_result_model.dart';

/// Envia PDFs escolhidos pelo usuário ao OpenRouter.
/// Usa uma instância Dio própria, SEM LogInterceptor, para nunca registrar
/// a chave de API ou o conteúdo Base64 do documento no console do app.
class OpenRouterDatasheetService {
  static const endpoint =
      'https://openrouter.ai/api/v1/chat/completions';
  static const defaultModel = 'google/gemini-3.8-flash';
  static const defaultPdfEngine = 'cloudflare-ai';
  static const maxPdfBytes = 10 * 1024 * 1024;

  final Dio _dio;
  final String? _keyOverride;
  final String? _modelOverride;
  final String? _pdfEngineOverride;

  OpenRouterDatasheetService({
    Dio? dio,
    String? apiKey,
    String? model,
    String? pdfEngine,
  })  : _dio = dio ??
            Dio(BaseOptions(
              connectTimeout: const Duration(seconds: 15),
              sendTimeout: const Duration(seconds: 60),
              receiveTimeout: const Duration(seconds: 120),
              responseType: ResponseType.json,
            )),
        _keyOverride = apiKey,
        _modelOverride = model,
        _pdfEngineOverride = pdfEngine;

  String get _apiKey {
    final key = (_keyOverride ?? dotenv.env['OPENROUTER_API_KEY'])?.trim();
    if (key == null || key.isEmpty) {
      throw StateError(
        'OPENROUTER_API_KEY não configurada. Adicione sua chave no .env local.',
      );
    }
    return key;
  }

  String get _model {
    final model = (_modelOverride ?? dotenv.env['OPENROUTER_MODEL'])?.trim();
    return model == null || model.isEmpty ? defaultModel : model;
  }

  String get _pdfEngine {
    final engine =
        (_pdfEngineOverride ?? dotenv.env['OPENROUTER_PDF_ENGINE'])?.trim();
    final chosen = engine == null || engine.isEmpty
        ? defaultPdfEngine
        : engine;
    if (!const {'cloudflare-ai', 'native', 'mistral-ocr'}.contains(chosen)) {
      throw StateError(
        'OPENROUTER_PDF_ENGINE inválido. Use cloudflare-ai, native ou mistral-ocr.',
      );
    }
    return chosen;
  }

  Future<AiExtractionResultModel> extractEquipmentData(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw const FormatException('Arquivo PDF não encontrado.');
    }
    final size = await file.length();
    if (size == 0 || size > maxPdfBytes) {
      throw const FormatException('O PDF deve ter entre 1 byte e 10 MB.');
    }
    final bytes = await file.readAsBytes();
    if (bytes.length < 5 || String.fromCharCodes(bytes.take(5)) != '%PDF-') {
      throw const FormatException('Selecione um arquivo PDF válido.');
    }

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
    final key = _apiKey;
    try {
      final response = await _dio.post<dynamic>(
        endpoint,
        data: {
          'model': _model,
          'temperature': 0.1,
          'response_format': {'type': 'json_object'},
          'plugins': [
            {
              'id': 'file-parser',
              'pdf': {'engine': _pdfEngine},
            },
          ],
          'messages': [
            {
              'role': 'user',
              'content': [
                {'type': 'text', 'text': prompt},
                {
                  'type': 'file',
                  'file': {
                    'filename': file.uri.pathSegments.last,
                    'file_data': 'data:application/pdf;base64,${base64Encode(bytes)}',
                  },
                },
              ],
            },
          ],
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $key',
            'Content-Type': 'application/json',
            'X-Title': 'GreenCity OS',
          },
        ),
      );
      final json = _asMap(response.data);
      return parseCompletion(json);
    } on DioException catch (error) {
      // Nunca exibir error.toString() nem dados da resposta:
      // alguns SDKs incluem URL, headers ou conteúdo sensível.
      throw StateError(_friendlyError(error));
    }
  }

  static Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    if (value is String) {
      final decoded = jsonDecode(value);
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    }
    throw const FormatException('A API retornou um formato inesperado.');
  }

  /// Separado da camada HTTP para testes sem chamadas pagas ou credenciais.
  static AiExtractionResultModel parseCompletion(Map<String, dynamic> body) {
    final choices = body['choices'];
    if (choices is! List || choices.isEmpty || choices.first is! Map) {
      throw const FormatException('OpenRouter não retornou uma resposta válida.');
    }
    final first = choices.first as Map;
    if (first['finish_reason'] == 'length') {
      throw const FormatException(
        'O modelo interrompeu a extração. Selecione outro modelo '
        'ou um datasheet menor.',
      );
    }
    final message = first['message'];
    if (message is! Map) {
      throw const FormatException('OpenRouter retornou uma mensagem inválida.');
    }
    final rawContent = message['content'];
    String responseText;
    if (rawContent is String) {
      responseText = rawContent;
    } else if (rawContent is List) {
      responseText = rawContent.whereType<Map>()
          .where((part) => part['type'] == 'text' && part['text'] is String)
          .map((part) => part['text'] as String)
          .join('\n');
    } else {
      throw const FormatException(
        'O modelo não retornou texto JSON. Tente outro modelo.',
      );
    }
    responseText = responseText.trim()
        .replaceFirst(RegExp(r'^\x60\x60\x60(?:json)?\s*'), '')
        .replaceFirst(RegExp(r'\s*\x60\x60\x60$'), '')
        .trim();
    if (responseText.isEmpty) {
      throw const FormatException('O modelo retornou uma resposta vazia.');
    }
    final decoded = jsonDecode(responseText);
    if (decoded is! Map) {
      throw const FormatException(
        'A resposta precisa ser um objeto JSON com modules e inverters.',
      );
    }
    final parsed = AiExtractionResultModel.fromJson(
      Map<String, dynamic>.from(decoded),
    );
    if (parsed.modules.isEmpty && parsed.inverters.isEmpty) {
      throw const FormatException(
        'Nenhum módulo ou inversor foi identificado no PDF.',
      );
    }
    return parsed;
  }

  static String _friendlyError(DioException error) {
    final status = error.response?.statusCode;
    switch (status) {
      case 400:
      case 422:
        return 'OpenRouter rejeitou a requisição (HTTP $status). Confira o modelo e o motor de leitura PDF.';
      case 401:
        return 'Chave OPENROUTER_API_KEY inválida ou revogada (HTTP 401).';
      case 402:
        return 'Saldo insuficiente na conta OpenRouter (HTTP 402).';
      case 403:
        return 'Acesso não autorizado ao modelo pelo OpenRouter (HTTP 403).';
      case 404:
        return 'Modelo OpenRouter não encontrado ou indisponível (HTTP 404).';
      case 413:
        return 'Arquivo ou requisição grande demais para o OpenRouter (HTTP 413).';
      case 429:
        return 'Limite de requisições do OpenRouter atingido (HTTP 429).';
      default:
        if (status != null && status >= 500) {
          return 'OpenRouter ou o provedor do modelo está indisponível '
              '(HTTP $status).';
        }
    }
    if (const {'connectionTimeout', 'receiveTimeout', 'sendTimeout',
      'transformTimeout'}.contains(error.type.name)) {
      return 'Tempo limite na conexão ou leitura do PDF pelo OpenRouter.';
    }
    return 'Falha de conexão com o OpenRouter. Verifique sua internet.';
  }
}
