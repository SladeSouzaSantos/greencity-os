import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greencity_os/data/datasources/hsp_api_error_formatter.dart';

void main() {
  final request = RequestOptions(path: '/api/calcular-arranjo');

  DioException failedRequest(int status, dynamic data) => DioException(
        requestOptions: request,
        response: Response(
          requestOptions: request,
          statusCode: status,
          data: data,
        ),
        type: DioExceptionType.badResponse,
      );

  test('traduz HTTP 422 para campo e índice de arranjo', () {
    final error = failedRequest(422, {
      'detail': [
        {
          'loc': ['body', 'itens', 0, 'config_obstaculo', 'largura_obstaculo'],
          'type': 'greater_than',
          'msg': 'Input should be greater than 0',
          'ctx': {'gt': 0},
        },
      ],
    });
    final text = HspApiErrorFormatter.format(error);
    expect(text, contains('422'));
    expect(text, contains('Arranjo 1'));
    expect(text, contains('Largura do obstáculo'));
    expect(text, contains('maior que 0'));
  });

  test('restringe corpo inesperado sem lançar outra exceção', () {
    expect(
      HspApiErrorFormatter.format(failedRequest(422, 'invalid body')),
      contains('422'),
    );
  });

  test('distingue timeout de validação', () {
    final timeout = DioException(
      requestOptions: request,
      type: DioExceptionType.receiveTimeout,
    );
    expect(HspApiErrorFormatter.format(timeout), contains('demorou'));
    expect(
      HspApiErrorFormatter.format(failedRequest(503, {})),
      contains('503'),
    );
  });
}
