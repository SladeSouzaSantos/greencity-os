import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

enum CloudAiProvider { openRouter, gemini, groq, mistral, cloudflare, cohere }

extension CloudAiProviderName on CloudAiProvider {
  String get label => switch (this) {
    CloudAiProvider.openRouter => 'OpenRouter',
    CloudAiProvider.gemini => 'Google Gemini',
    CloudAiProvider.groq => 'Groq',
    CloudAiProvider.mistral => 'Mistral AI',
    CloudAiProvider.cloudflare => 'Cloudflare',
    CloudAiProvider.cohere => 'Cohere',
  };
}

/// Jamais incorpora resposta, prompt ou credencial aos diagnósticos.
class CloudProviderFailure extends StateError {
  final String code;
  final bool allowFallback;
  final int? httpStatus;

  CloudProviderFailure(this.code, String reason, {
    this.allowFallback = true, this.httpStatus,
  }) : super(reason);

  static CloudProviderFailure fromDio(DioException error) {
    final status = error.response?.statusCode;
    if (status != null) {
      if (status == 402) {
        return CloudProviderFailure('saldo_insuficiente', 'Limite de créditos atingido.',
            httpStatus: status);
      }
      if (status == 429) {
        return CloudProviderFailure('limite_requisicoes', 'Cota ou taxa de requisições atingida.',
            httpStatus: status);
      }
      if (status == 401 || status == 403 || status == 498) {
        return CloudProviderFailure('acesso_negado', 'Credencial rejeitada ou acesso indisponível.',
            httpStatus: status);
      }
      if (status == 404) {
        return CloudProviderFailure('modelo_indisponivel', 'Modelo/endpoint não encontrado.',
            httpStatus: status);
      }
      if (status == 408 || status >= 500) {
        return CloudProviderFailure('servico_indisponivel', 'Serviço temporariamente indisponível.',
            httpStatus: status);
      }
      return CloudProviderFailure('requisicao_invalida',
          'Requisição rejeitada; verifique PDF, parâmetros e formato.',
          httpStatus: status, allowFallback: false);
    }
    final code = switch (error.type) {
      DioExceptionType.connectionTimeout => 'timeout_conexao',
      DioExceptionType.sendTimeout => 'timeout_envio',
      DioExceptionType.receiveTimeout => 'timeout_resposta',
      DioExceptionType.connectionError => 'erro_conexao',
      DioExceptionType.cancel => 'cancelado',
      _ => 'falha_transporte',
    };
    return CloudProviderFailure(code,
      'Falha de transporte ao comunicar com a API.',
      allowFallback: code != 'cancelado');
  }
}

void logAiEvent(CloudAiProvider provider, String event, {
  String? model, Duration? elapsed, int? httpStatus, String? detail,
  int? inputTokens, int? outputTokens,
}) {
  // Não registrar documentos, cabeçalhos, URL com chave, corpos ou prompts.
  final ms = elapsed?.inMilliseconds;
  debugPrint('[AI Router] provider=${provider.label}; evento=$event; '
      'modelo=${model ?? "-"}; tempo_ms=${ms ?? "-"}; '
      'http=${httpStatus ?? "-"}; motivo=${detail ?? "-"}; '
      'tokens_entrada=${inputTokens ?? "-"}; '
      'tokens_saida=${outputTokens ?? "-"}');
}
