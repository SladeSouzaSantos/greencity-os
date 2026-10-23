import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../../data/models/ai_datasheet_semantic_auditor.dart';
import '../../data/models/ai_equipment_refinement.dart';
import '../../data/models/ai_extraction_result_model.dart';
import '../../data/models/ai_inverter_refinement.dart';
import 'openrouter_free_model_policy.dart';
import 'datasheet_extraction_prompt.dart';

/// Envia PDFs escolhidos pelo usuário ao OpenRouter.
/// Usa uma instância Dio própria, SEM LogInterceptor, para nunca registrar
/// a chave de API ou o conteúdo Base64 do documento no console do app.
class OpenRouterDatasheetService {
  static const endpoint =
      'https://openrouter.ai/api/v1/chat/completions';
  static const defaultModel = OpenRouterFreeModelPolicy.defaultPrimary;
  static const defaultPdfEngine = 'cloudflare-ai';
  static const maxPdfBytes = 10 * 1024 * 1024;

  final Dio _dio;
  final String? _keyOverride;
  final String? _modelOverride;
  final String? _fallbackModelsOverride;
  final String? _pdfEngineOverride;

  OpenRouterDatasheetService({
    Dio? dio,
    String? apiKey,
    String? model,
    String? fallbackModels,
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
        _fallbackModelsOverride = fallbackModels,
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

  List<String> get _models => OpenRouterFreeModelPolicy.resolve(
        primary: _modelOverride ?? dotenv.env['OPENROUTER_MODEL'],
        fallbacks: _fallbackModelsOverride ??
            dotenv.env['OPENROUTER_FALLBACK_MODELS'],
      );

  String get _pdfEngine {
    final engine =
        (_pdfEngineOverride ?? dotenv.env['OPENROUTER_PDF_ENGINE'])?.trim();
    final chosen = engine == null || engine.isEmpty
        ? defaultPdfEngine
        : engine;
    if (!const {'cloudflare-ai', 'native'}.contains(chosen)) {
      throw StateError(
        'Para evitar cobrança adicional, use cloudflare-ai (gratuito) '
        'ou native com um modelo :free. mistral-ocr é pago.',
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

    const prompt = DatasheetExtractionPrompt.text;
    final models = _models; // Rejeita modelos pagos ANTES de qualquer HTTP.
    final key = _apiKey;
    final engine = _pdfEngine;
    final message = <String, dynamic>{
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
    };

    final response = await _request(
      models: models,
      engine: engine,
      key: key,
      message: message,
    );
    try {
      final initial = parseCompletion(response);
      final extractedText = AiInverterRefinement.parsedPdfText(response);
      if (!AiEquipmentRefinement.needsRefinement(initial)) {
        return AiDatasheetSemanticAuditor.audit(initial, extractedText);
      }

      // O CloudflareAI pode devolver markdown em file.annotations;
      // uma única segunda chamada SÓ DE TEXTO evita retransmitir o PDF
      // em Base64 (particularmente importante em arquivos grandes).
      if (extractedText == null) {
        return AiDatasheetSemanticAuditor.audit(initial, null);
      }

      try {
        final refined = await _request(
          models: models,
          engine: engine,
          key: key,
          message: {
            'role': 'user',
            'content': [
              {
                'type': 'text',
                'text': AiEquipmentRefinement.prompt(initial, extractedText),
              },
            ],
          },
        );
        final additional = parseCompletion(refined);
        return AiDatasheetSemanticAuditor.audit(
          AiEquipmentRefinement.mergeMissing(initial, additional),
          extractedText,
        );
      } on Exception {
        // A segunda chamada é opcional. Se falhar (por exemplo, quota
        // do :free), não descarte o que foi extraído na primeira.
        return AiDatasheetSemanticAuditor.audit(initial, extractedText);
      }
    } on FormatException {
      // Uma resposta cortada pode conservar o texto OCR nas annotations.
      // Antes de retransmitir PDF, realizar uma recuperação SÓ DE TEXTO.
      final extractedText = AiInverterRefinement.parsedPdfText(response);
      if (extractedText != null) {
        try {
          final recovered = await _request(
            models: models,
            engine: engine,
            key: key,
            message: {
              'role': 'user',
              'content': [
                {
                  'type': 'text',
                  'text': AiEquipmentRefinement.recoveryPrompt(extractedText),
                }
              ],
            },
          );
          return AiDatasheetSemanticAuditor.audit(
              parseCompletion(recovered), extractedText);
        } on Exception {
          // Usar modelo alternativo apenas para arquivos pequenos.
        }
      }
      // Reenviar PDF grande repetidas vezes gera custo e erro 413/timeout.
      if (models.length < 2 || size > 2 * 1024 * 1024) {
        throw const FormatException(
          'A resposta da IA foi interrompida ou não contém JSON completo. '
          'Use outro modelo gratuito ou otimize o PDF. '
          'O aplicativo evita reenviar automaticamente PDFs grandes.',
        );
      }
      final retry = await _request(
        models: models.skip(1).toList(),
        engine: engine,
        key: key,
        message: message,
      );
      return AiDatasheetSemanticAuditor.audit(
        parseCompletion(retry), AiInverterRefinement.parsedPdfText(retry));
    }
  }

  Future<Map<String, dynamic>> _request({
    required List<String> models,
    required String engine,
    required String key,
    required Map<String, dynamic> message,
    bool includeResponseFormat = true,
  }) async {
    try {
      final parts = message['content'];
      final hasPdf = parts is List && parts.any(
        (part) => part is Map && part['type'] == 'file',
      );
      final response = await _dio.post<dynamic>(
        endpoint,
        data: {
          'model': models.first,
          'models': models,
          'temperature': 0.1,
          'max_tokens': 16384,
          if (includeResponseFormat)
            'response_format': {'type': 'json_object'},
          if (hasPdf)
            'plugins': [
              {
                'id': 'file-parser',
                'pdf': {'engine': engine},
              },
            ],
          'messages': [message],
        },
        options: Options(headers: {
          'Authorization': 'Bearer $key',
          'Content-Type': 'application/json',
          'X-Title': 'GreenCity OS',
        }),
      );
      return _asMap(response.data);
    } on DioException catch (error) {
      // Alguns modelos :free podem não suportar response_format=json_object.
      // Reenvia a requisição sem esse parâmetro somente quando o OpenRouter
      // confirmar ESSA incompatibilidade. Erros 400 de PDF/schema não
      // são corrigidos por troca de modelo, portanto não geram loop.
      if (includeResponseFormat && _unsupportedResponseFormat(error)) {
        return _request(
          models: models,
          engine: engine,
          key: key,
          message: message,
          includeResponseFormat: false,
        );
      }
      // Nunca usar error.toString() porque Dio inclui RequestOptions.
      throw StateError(_friendlyError(error));
    }
  }

  static bool _unsupportedResponseFormat(DioException error) {
    if (error.response?.statusCode != 400) return false;
    final data = error.response?.data;
    if (data is! Map) return false;
    final details = data['error'];
    if (details is! Map || details['message'] is! String) return false;
    final message = (details['message'] as String).toLowerCase();
    return message.contains('response_format') ||
        (message.contains('json') &&
            (message.contains('not support') ||
             message.contains('unsupported')));
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
    // finish_reason=length pode aparecer até quando o modelo encerrou
    // APÓS devolver JSON sintaticamente completo: valide o conteúdo antes
    // de descartar toda a extração por causa desse status.
    final dynamic decoded;
    try {
      decoded = jsonDecode(responseText);
    } on FormatException {
      if (first['finish_reason'] == 'length') {
        throw const FormatException(
          'O modelo atingiu o limite de saída e cortou o JSON do PDF.',
        );
      }
      rethrow;
    }
    if (decoded is! Map || decoded['modules'] is! List ||
        decoded['inverters'] is! List) {
      throw const FormatException(
        'A resposta precisa conter arrays JSON modules e inverters.',
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

  static String _reason400(DioException error) {
    final data = error.response?.data;
    if (data is Map && data['error'] is Map) {
      final details = data['error'] as Map;
      final rawMessage = details['message'];
      if (rawMessage is String) {
        final message = rawMessage.toLowerCase();
        if (message.contains('pdf') || message.contains('file-parser') ||
            message.contains('cloudflare-ai') ||
            message.contains('file_data') || message.contains('base64') ||
            message.contains('file size') || message.contains('payload')) {
          return 'Erro ao processar o arquivo PDF. Experimente salvar uma '
              'cópia otimizada (imagens comprimidas) e confira o motor '
              'OPENROUTER_PDF_ENGINE.';
        }
        if (message.contains('response_format') ||
            message.contains('structured output') ||
            message.contains('json')) {
          return 'O modelo não aceita os parâmetros de saída JSON.';
        }
        if (message.contains('model') || message.contains('provider') ||
            message.contains('endpoint')) {
          return 'O provedor pode não aceitar algum parâmetro. '
              'Confira os modelos gratuitos configurados e suas capacidades.';
        }
        if (message.contains('context') || message.contains('token')) {
          return 'O documento ou a resposta ultrapassou o limite do modelo.';
        }
      }
    }
    return 'Requisição inválida; o motivo exato não veio em formato '
        'reconhecido pelo aplicativo. Consulte Activity no OpenRouter. '
        'Se o PDF tiver muitas imagens, tente uma cópia otimizada.';
  }

  static String _friendlyError(DioException error) {
    final status = error.response?.statusCode;
    switch (status) {
      case 400:
      case 422:
        return 'OpenRouter rejeitou a requisição (HTTP $status). '
            '${_reason400(error)}';
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
