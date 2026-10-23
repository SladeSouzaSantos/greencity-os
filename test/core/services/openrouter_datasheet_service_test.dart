import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greencity_os/core/services/openrouter_datasheet_service.dart';

void main() {
  late Directory tmp;
  late File pdf;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('greencity_openrouter_test_');
    pdf = File('${tmp.path}/datasheet.pdf');
    await pdf.writeAsBytes(utf8.encode('%PDF-1.4\n% sample test PDF\n'));
  });

  tearDown(() async {
    if (await tmp.exists()) await tmp.delete(recursive: true);
  });

  test('envia PDF Base64, chave OpenRouter e modelo configurável sem rede', () async {
    final dio = Dio();
    RequestOptions? captured;
    dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
      captured = options;
      handler.resolve(Response(
        requestOptions: options,
        statusCode: 200,
        data: {
          'choices': [
            {
              'finish_reason': 'stop',
              'message': {
                'role': 'assistant',
                'content': jsonEncode({
                  'modules': [
                    {'manufacturer': 'Teste', 'modelName': 'PV-600', 'powerWp': 600},
                    {'manufacturer': 'Teste', 'modelName': 'PV-605', 'powerWp': 605},
                  ],
                  'inverters': [
                    {'manufacturer': 'Teste', 'modelName': 'INV-3K', 'nominalPowerKw': 3},
                  ],
                }),
              },
            },
          ],
        },
      ));
    }));

    final service = OpenRouterDatasheetService(
      dio: dio,
      apiKey: 'test-not-secret',
      model: 'openai/gpt-4o-mini',
      pdfEngine: 'cloudflare-ai',
    );
    final result = await service.extractEquipmentData(pdf.path);

    expect(result.modules, hasLength(2));
    expect(result.inverters, hasLength(1));
    expect(result.modules[0].modelName, 'PV-600');
    expect(result.modules[1].modelName, 'PV-605');
    expect(captured, isNotNull);
    expect(captured!.uri.toString(), OpenRouterDatasheetService.endpoint);
    expect(captured!.headers['Authorization'], 'Bearer test-not-secret');

    final body = captured!.data as Map;
    expect(body['model'], 'openai/gpt-4o-mini');
    expect(body['response_format'], {'type': 'json_object'});
    expect((body['plugins'] as List).first['pdf'], {'engine': 'cloudflare-ai'});
    final content = ((body['messages'] as List).first['content'] as List);
    final part = content[1] as Map;
    expect(part['type'], 'file');
    expect(part['file']['filename'], 'datasheet.pdf');
    expect(
      part['file']['file_data'] as String,
      startsWith('data:application/pdf;base64,JVBERi0'),
    );
  });

  test('HTTP 401 fornece erro de autenticação sem expor chave', () async {
    final dio = Dio();
    dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
      handler.reject(DioException(
        requestOptions: options,
        response: Response(
          requestOptions: options,
          statusCode: 401,
          data: {'error': {'message': 'unauthorized'}},
        ),
        type: DioExceptionType.badResponse,
      ));
    }));
    final service = OpenRouterDatasheetService(
      dio: dio,
      apiKey: 'private-key',
      model: 'google/gemini-3.8-flash',
      pdfEngine: 'cloudflare-ai',
    );
    await expectLater(
      service.extractEquipmentData(pdf.path),
      throwsA(
        isA<StateError>()
          .having((e) => e.message.toString(), 'mensagem', contains('OPENROUTER_API_KEY'))
          .having((e) => e.message.toString(), 'sem a chave', isNot(contains('private-key'))),
      ),
    );
  });

  test('não importa retorno truncado', () {
    expect(
      () => OpenRouterDatasheetService.parseCompletion({
        'choices': [
          {'finish_reason': 'length', 'message': {'content': '{"modules": []}'}}
        ]
      }),
      throwsFormatException,
    );
  });

  test('recusa arquivos sem assinatura PDF antes de enviar', () async {
    await pdf.writeAsString('not a PDF');
    final service = OpenRouterDatasheetService(apiKey: 'test');
    await expectLater(
      service.extractEquipmentData(pdf.path),
      throwsFormatException,
    );
  });
}
