import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../../data/models/ai_extraction_result_model.dart';
import 'cloud_datasheet_service.dart';
import 'cloud_provider_support.dart';
import 'ollama_datasheet_service.dart';
import 'openrouter_datasheet_service.dart';
import 'openrouter_quota_service.dart';

typedef DatasheetExtractor = Future<AiExtractionResultModel> Function(String path);
typedef CloudDatasheetExtractor = Future<AiExtractionResultModel> Function(
    CloudAiProvider provider, String path);
typedef OpenRouterCapacityCheck = Future<bool?> Function(String apiKey);

/// Seleciona provedor explícito ou executa sequência automática de APIs.
/// AI_PROVIDER=auto tem precedência sobre OLLAMA_ENABLED legado.
class DatasheetAiService {
  static const order = CloudAiProvider.values;

  final bool? _ollamaEnabledOverride;
  final String? _modeOverride;
  final bool? _fallbackOverride;
  final Set<CloudAiProvider>? _configuredOverride;
  final DatasheetExtractor? _ollamaExtractor;
  final DatasheetExtractor? _openRouterExtractor;
  final CloudDatasheetExtractor? _cloudExtractor;
  final OpenRouterCapacityCheck? _capacityCheck;
  final CloudDatasheetService _cloud;

  CloudAiProvider? _lastProvider;

  DatasheetAiService({
    bool? ollamaEnabled,
    String? aiProvider,
    bool? cloudFallbackEnabled,
    Set<CloudAiProvider>? configuredProviders,
    DatasheetExtractor? ollamaExtractor,
    DatasheetExtractor? openRouterExtractor,
    CloudDatasheetExtractor? cloudExtractor,
    OpenRouterCapacityCheck? openRouterCapacityCheck,
    CloudDatasheetService? cloudService,
  }) : _ollamaEnabledOverride = ollamaEnabled,
       _modeOverride = aiProvider,
       _fallbackOverride = cloudFallbackEnabled,
       _configuredOverride = configuredProviders,
       _ollamaExtractor = ollamaExtractor,
       _openRouterExtractor = openRouterExtractor,
       _cloudExtractor = cloudExtractor,
       _capacityCheck = openRouterCapacityCheck,
       _cloud = cloudService ?? CloudDatasheetService();

  String get _mode {
    if (_modeOverride != null) return _modeOverride.trim().toLowerCase();
    // Compatibilidade com testes e injeção de dependências: a escolha
    // explícita da API antiga não exige carregar dotenv.
    if (_ollamaEnabledOverride != null) return '';
    return (dotenv.env['AI_PROVIDER'] ?? '').trim().toLowerCase();
  }

  bool get useAuto => _mode == 'auto';

  bool get useOllama {
    if (useAuto) return false;
    if (_mode.isNotEmpty) {
      if (_mode == 'ollama') return true;
      if (_mode == 'openrouter') return false;
      throw StateError('AI_PROVIDER deve ser auto, ollama ou openrouter.');
    }
    if (_ollamaEnabledOverride != null) return _ollamaEnabledOverride;
    final value = (dotenv.env['OLLAMA_ENABLED'] ?? 'false').trim().toLowerCase();
    if (value == 'true') return true;
    if (value == 'false' || value.isEmpty) return false;
    throw StateError('OLLAMA_ENABLED deve ser true ou false no .env.');
  }

  bool get _cloudFallbackEnabled => _fallbackOverride ??
      ((dotenv.env['AI_CLOUD_FALLBACK_ENABLED'] ?? 'true')
          .trim().toLowerCase() == 'true');

  String get providerDescription {
    if (useAuto) {
      if (_lastProvider != null) {
        return 'Extração via ${_lastProvider!.label}; '
            'fallback entre provedores configurados.';
      }
      return 'Roteamento automático: OpenRouter, Gemini, Groq, '
          'Mistral, Cloudflare e Cohere.';
    }
    return useOllama
        ? 'Processamento local com Ollama; PDF não enviado ao OpenRouter.'
        : 'PDF enviado ao OpenRouter e ao provedor do modelo.';
  }

  bool _configured(CloudAiProvider provider) {
    if (_configuredOverride != null) {
      return _configuredOverride.contains(provider);
    }
    if (provider == CloudAiProvider.openRouter) {
      return (dotenv.env['OPENROUTER_API_KEY'] ?? '').trim().isNotEmpty;
    }
    return _cloud.isConfigured(provider);
  }

  Future<AiExtractionResultModel> extractEquipmentData(String filePath) {
    if (useAuto) return _extractAutomatic(filePath);
    if (useOllama) {
      return (_ollamaExtractor ?? OllamaDatasheetService().extractEquipmentData)(
        filePath,
      );
    }
    return (_openRouterExtractor ??
        OpenRouterDatasheetService().extractEquipmentData)(filePath);
  }

  Future<AiExtractionResultModel> _extractAutomatic(String path) async {
    _lastProvider = null;
    // Erros de entrada não são disponibilidade de um provedor.
    final file = File(path);
    if (!await file.exists()) throw const FormatException('PDF não encontrado.');
    final size = await file.length();
    if (size <= 0 || size > OpenRouterDatasheetService.maxPdfBytes) {
      throw const FormatException('O PDF deve ter entre 1 byte e 10 MB.');
    }
    final signature = await file.openRead(0, 5).first;
    if (String.fromCharCodes(signature) != '%PDF-') {
      throw const FormatException('Selecione um arquivo PDF válido.');
    }

    final errors = <String>[];
    var tried = 0;
    for (final provider in order) {
      if (!_configured(provider)) {
        logAiEvent(provider, 'ignorado', detail: 'sem_credencial');
        continue;
      }

      if (provider == CloudAiProvider.openRouter) {
        final key = (_configuredOverride != null && _capacityCheck != null)
            ? '' // Teste injetado: nenhuma chave real deve ser consultada.
            : (dotenv.env['OPENROUTER_API_KEY'] ?? '').trim();
        // Em testes, o verificador pode ser injetado sem credenciais reais.
        if (_capacityCheck != null || key.isNotEmpty) {
          final check = _capacityCheck ??
              OpenRouterQuotaService().hasFreeCapacity;
          bool? available;
          try {
            available = await check(key);
          } on CloudProviderFailure catch (error) {
            errors.add('${provider.label}: ${error.code}');
            logAiEvent(provider, 'preflight_falha', detail: error.code,
                httpStatus: error.httpStatus);
            if (!_cloudFallbackEnabled) rethrow;
            continue;
          }
          logAiEvent(provider, 'preflight',
              detail: available == false
                  ? 'cota_gratuita_esgotada'
                  : available == true ? 'cota_confirmada' : 'cota_desconhecida');
          if (available == false) {
            errors.add('${provider.label}: cota_gratuita_esgotada');
            if (!_cloudFallbackEnabled) {
              throw StateError('OpenRouter sem cota gratuita disponível.');
            }
            continue;
          }
        }
      }

      tried++;
      final watch = Stopwatch()..start();
      logAiEvent(provider, 'tentativa');
      try {
        final result = provider == CloudAiProvider.openRouter
            ? await (_openRouterExtractor ??
                OpenRouterDatasheetService().extractEquipmentData)(path)
            : await (_cloudExtractor ?? _cloud.extract)(provider, path);
        _lastProvider = provider;
        logAiEvent(provider, 'selecionado', elapsed: watch.elapsed);
        return result;
      } on CloudProviderFailure catch (error) {
        errors.add('${provider.label}: ${error.code}');
        logAiEvent(provider, 'fallback', elapsed: watch.elapsed,
            httpStatus: error.httpStatus, detail: error.code);
        if (!error.allowFallback || !_cloudFallbackEnabled) {
          throw StateError('${provider.label} [${error.code}]: '
              '${error.message}');
        }
      } on FormatException {
        // O arquivo foi validado; aqui a falha é na estrutura gerada
        // pelo modelo, e outro provedor pode conseguir interpretar o PDF.
        errors.add('${provider.label}: json_invalido');
        logAiEvent(provider, 'fallback', elapsed: watch.elapsed,
            detail: 'json_invalido');
        if (!_cloudFallbackEnabled) rethrow;
      }
    }

    if (tried == 0 && errors.isEmpty) {
      throw StateError('Nenhum provedor configurado. Adicione ao .env '
          'uma chave OpenRouter, Gemini, Groq, Mistral, Cloudflare ou Cohere.');
    }
    throw StateError('Nenhum provedor concluiu o datasheet. '
        'Diagnóstico por tentativa: ${errors.join("; ")}. '
        'Consulte os eventos [AI Router] no console.');
  }
}
