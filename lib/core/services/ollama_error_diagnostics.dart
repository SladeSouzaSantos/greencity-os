import 'dart:io';

import 'package:dio/dio.dart';

/// Traduz falhas de transporte do Ollama sem expor prompt, PDF ou corpo HTTP.
class OllamaErrorDiagnostics {
  static String _detail(DioException error) {
    final data = error.response?.data;
    if (data is Map) {
      final raw = data['error'];
      if (raw is String) return raw.toLowerCase();
      if (raw is Map) {
        final message = raw['message'];
        if (message is String) return message.toLowerCase();
      }
    }
    return '';
  }

  static String category(DioException error) {
    final status = error.response?.statusCode;
    if (status != null) {
      final detail = _detail(error);
      if (status == 404) return 'modelo_nao_encontrado';
      if (status == 400 || status == 422) {
        if (detail.contains('context') || detail.contains('token') ||
            detail.contains('num_ctx')) {
          return 'contexto_excedido';
        }
        return 'requisicao_invalida';
      }
      if (status == 429 || status == 503) return 'servidor_ocupado';
      if (status >= 500 &&
          (detail.contains('out of memory') ||
           detail.contains('not enough memory') ||
           detail.contains('cannot allocate') ||
           detail.contains('cuda error') ||
           detail.contains('failed to allocate'))) {
        return 'memoria_insuficiente';
      }
      return 'http_$status';
    }

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        return 'timeout_conexao';
      case DioExceptionType.sendTimeout:
        return 'timeout_envio';
      case DioExceptionType.receiveTimeout:
        return 'timeout_resposta';
      case DioExceptionType.transformTimeout:
        return 'timeout_decodificacao';
      case DioExceptionType.connectionError:
      case DioExceptionType.unknown:
        final underlying = error.error;
        final description = underlying.toString().toLowerCase();
        final code = underlying is SocketException
            ? underlying.osError?.errorCode
            : null;
        if (code == 10061 || code == 111 ||
            description.contains('connection refused')) {
          return 'conexao_recusada';
        }
        if (code == 10054 || code == 104 ||
            description.contains('connection reset') ||
            description.contains('forcibly closed') ||
            description.contains('broken pipe')) {
          return 'conexao_interrompida';
        }
        return 'erro_conexao';
      case DioExceptionType.badCertificate:
        return 'certificado';
      case DioExceptionType.cancel:
        return 'cancelado';
      case DioExceptionType.badResponse:
        return 'resposta_http_invalida';
    }
  }

  static StateError describe(
    DioException error, {
    required String model,
    required Duration elapsed,
    required int receiveTimeoutSeconds,
  }) {
    final kind = category(error);
    final seconds = (elapsed.inMilliseconds / 1000).toStringAsFixed(1);
    String explanation;
    switch (kind) {
      case 'conexao_recusada':
        explanation = 'Conexão recusada. Confirme se o Ollama está aberto '
            'com curl.exe http://127.0.0.1:11434/api/version.';
      case 'conexao_interrompida':
        explanation = 'O servidor encerrou ou reiniciou a conexão durante '
            'a inferência. Verifique ollama ps e os logs do Ollama; '
            'pode haver pressão de RAM/VRAM.';
      case 'timeout_conexao':
        explanation = 'Tempo limite ao conectar. Confira a porta 11434 '
            'e se o serviço está acessível.';
      case 'timeout_envio':
        explanation = 'Tempo limite ao enviar o texto extraído do PDF.';
      case 'timeout_resposta':
        explanation = 'Tempo limite aguardando a geração da resposta '
            '(limite de $receiveTimeoutSeconds s). '
            'Teste um PDF menor, reduza OLLAMA_NUM_CTX ou aumente '
            'OLLAMA_RECEIVE_TIMEOUT_SECONDS.';
      case 'timeout_decodificacao':
        explanation = 'Tempo limite ao decodificar a resposta JSON.';
      case 'modelo_nao_encontrado':
        explanation = 'Modelo não encontrado. Confira OLLAMA_MODEL '
            'e o comando ollama list.';
      case 'memoria_insuficiente':
        explanation = 'O Ollama relatou possível falta de RAM/VRAM. '
            'Use um modelo menor ou reduza OLLAMA_NUM_CTX.';
      case 'contexto_excedido':
        explanation = 'O Ollama rejeitou o tamanho do contexto ou dos tokens. '
            'Reduza o texto do PDF ou ajuste OLLAMA_NUM_CTX '
            'conforme a memória disponível.';
      case 'requisicao_invalida':
        explanation = 'O Ollama rejeitou a estrutura da requisição '
            '(HTTP ${error.response?.statusCode}). '
            'Verifique o suporte do modelo a JSON estruturado.';
      case 'servidor_ocupado':
        explanation = 'Ollama sobrecarregado/indisponível no momento '
            '(HTTP ${error.response?.statusCode}).';
      case 'certificado':
        explanation = 'Falha de certificado no transporte da requisição.';
      case 'cancelado':
        explanation = 'Requisição cancelada.';
      default:
        if (kind.startsWith('http_')) {
          explanation = 'O Ollama retornou HTTP ${error.response?.statusCode}. '
              'Consulte os logs locais do servidor.';
        } else {
          explanation = 'Falha de comunicação não classificada. '
              'Confira o serviço e seus logs locais.';
        }
    }
    return StateError('Ollama [$kind], modelo $model, após $seconds s: '
        '$explanation Nenhuma chamada foi enviada ao OpenRouter.');
  }
}
