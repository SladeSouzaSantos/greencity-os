import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greencity_os/core/services/ollama_error_diagnostics.dart';

void main() {
  final options = RequestOptions(
    path: 'http://127.0.0.1:11434/api/chat',
  );

  DioException issue(
    DioExceptionType type, {
    int? status,
    Object? payload,
    Object? cause,
  }) => DioException(
    requestOptions: options,
    type: type,
    error: cause,
    response: status == null ? null : Response(
      requestOptions: options,
      statusCode: status,
      data: payload,
    ),
  );

  String diagnostic(DioException error) =>
      OllamaErrorDiagnostics.describe(
        error, model: 'qwen2.5:3b',
        elapsed: const Duration(seconds: 17, milliseconds: 300),
        receiveTimeoutSeconds: 900,
      ).message.toString();

  test('timeout de conexão difere de timeout de geração', () {
    final connect = issue(DioExceptionType.connectionTimeout);
    final receive = issue(DioExceptionType.receiveTimeout);
    final send = issue(DioExceptionType.sendTimeout);
    expect(OllamaErrorDiagnostics.category(connect), 'timeout_conexao');
    expect(OllamaErrorDiagnostics.category(receive), 'timeout_resposta');
    expect(OllamaErrorDiagnostics.category(send), 'timeout_envio');
    expect(diagnostic(receive), contains('900 s'));
    expect(diagnostic(receive), contains('17.3 s'));
  });

  test('conexão recusada e conexão interrompida têm causas distintas', () {
    final refused = issue(DioExceptionType.connectionError,
        cause: Exception('Connection refused'));
    final reset = issue(DioExceptionType.connectionError,
        cause: Exception('Connection reset by peer'));
    expect(OllamaErrorDiagnostics.category(refused), 'conexao_recusada');
    expect(OllamaErrorDiagnostics.category(reset), 'conexao_interrompida');
    expect(diagnostic(reset), contains('RAM/VRAM'));
  });

  test('HTTP 404 distingue modelo ausente', () {
    final error = issue(DioExceptionType.badResponse, status: 404);
    expect(OllamaErrorDiagnostics.category(error),
        'modelo_nao_encontrado');
    expect(diagnostic(error), contains('ollama list'));
  });

  test('HTTP 500 de memória recebe diagnóstico específico sem vazar texto', () {
    const secret = 'PRIVATE_PDF_CONTENT_DO_NOT_LOG';
    final error = issue(DioExceptionType.badResponse, status: 500,
        payload: {'error': 'out of memory; $secret'});
    expect(OllamaErrorDiagnostics.category(error), 'memoria_insuficiente');
    expect(diagnostic(error), contains('RAM/VRAM'));
    expect(diagnostic(error), isNot(contains(secret)));
  });

  test('HTTP 500 sem evidência de memória não é confundido com OOM', () {
    final error = issue(DioExceptionType.badResponse, status: 500,
        payload: {'error': 'backend failed unexpectedly'});
    expect(OllamaErrorDiagnostics.category(error), 'http_500');
    expect(diagnostic(error), contains('HTTP 500'));
  });

  test('erro de contexto e schema inválido possuem diagnósticos distintos', () {
    final context = issue(DioExceptionType.badResponse, status: 400,
        payload: {'error': 'context length exceeded'});
    final format = issue(DioExceptionType.badResponse, status: 422,
        payload: {'error': 'invalid JSON format'});
    expect(OllamaErrorDiagnostics.category(context), 'contexto_excedido');
    expect(OllamaErrorDiagnostics.category(format), 'requisicao_invalida');
  });

  test('nunca sugere fallback para OpenRouter', () {
    final error = issue(DioExceptionType.receiveTimeout);
    expect(diagnostic(error), contains('Nenhuma chamada foi enviada'));
    expect(diagnostic(error), isNot(contains('Bearer')));
  });
}
