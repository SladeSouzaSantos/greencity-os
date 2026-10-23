import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../../data/models/ai_extraction_result_model.dart';
import 'ollama_datasheet_service.dart';
import 'openrouter_datasheet_service.dart';

typedef DatasheetExtractor = Future<AiExtractionResultModel> Function(String path);

/// Seleção explícita de provedor; falha local NUNCA causa cobrança remota.
class DatasheetAiService {
  final bool? _ollamaEnabledOverride;
  final DatasheetExtractor? _ollamaExtractor;
  final DatasheetExtractor? _openRouterExtractor;

  DatasheetAiService({
    bool? ollamaEnabled,
    DatasheetExtractor? ollamaExtractor,
    DatasheetExtractor? openRouterExtractor,
  }) : _ollamaEnabledOverride = ollamaEnabled,
       _ollamaExtractor = ollamaExtractor,
       _openRouterExtractor = openRouterExtractor;

  bool get useOllama {
    if (_ollamaEnabledOverride != null) return _ollamaEnabledOverride;
    final value = (dotenv.env['OLLAMA_ENABLED'] ?? 'false').trim().toLowerCase();
    if (value == 'true') return true;
    if (value == 'false' || value.isEmpty) return false;
    throw StateError('OLLAMA_ENABLED deve ser true ou false no .env.');
  }

  String get providerDescription => useOllama
      ? 'Processamento local com Ollama; PDF não enviado ao OpenRouter.'
      : 'PDF enviado ao OpenRouter e ao provedor do modelo.';

  Future<AiExtractionResultModel> extractEquipmentData(String filePath) {
    if (useOllama) {
      return (_ollamaExtractor ?? OllamaDatasheetService().extractEquipmentData)(
        filePath,
      );
    }
    return (_openRouterExtractor ??
        OpenRouterDatasheetService().extractEquipmentData)(filePath);
  }
}
