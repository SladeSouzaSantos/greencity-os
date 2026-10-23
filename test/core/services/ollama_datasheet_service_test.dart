import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greencity_os/core/services/ollama_datasheet_service.dart';

void main() {
  late Directory temp;
  late File pdf;
  setUp(() async {
    temp = await Directory.systemTemp.createTemp('greencity_ollama_test_');
    pdf = File(temp.path + '/datasheet.pdf');
    await pdf.writeAsBytes(utf8.encode('%PDF-1.7\nfixture'));
  });
  tearDown(() async {
    await temp.delete(recursive: true);
  });

  const pdfText = '''
Jetion Solar JT690SLk(B) electrical characteristics and dimensions.
Maximum Series Fuse 35A
Operating Temperature -40°C-+85°C
30 years linear performance warranty
''';

  OllamaDatasheetService local(
    Dio dio, {PdfTextReader? reader, String? baseUrl, String? model}
  ) => OllamaDatasheetService(
    dio: dio, pdfTextReader: reader ?? (path) async => pdfText,
    model: model ?? 'qwen3.8:27b',
    baseUrl: baseUrl ?? 'http://127.0.0.1:11434',
    numCtx: 16384,
  );

  Map<String, dynamic> chat(Map<String, dynamic> payload) => {
    'model': 'qwen3.8:27b',
    'done': true,
    'message': {'role': 'assistant', 'content': jsonEncode(payload)},
  };

  test('Ollama recebe texto, não PDF Base64; mesmo parser e auditor', () async {
    final dio = Dio();
    final sent = <RequestOptions>[];
    dio.interceptors.add(InterceptorsWrapper(onRequest: (request, handler) {
      sent.add(request);
      final response = sent.length == 1
          ? chat({'modules': [{
              'manufacturer': 'Jetion Solar',
              'modelName': 'JT690SLk(B)', 'powerWp': 690,
              'physicalWarranty': 30, 'efficiencyWarranty': 30,
            }], 'inverters': []})
          : chat({'modules': [{
              'manufacturer': 'Jetion Solar',
              'modelName': 'JT690SLk(B)', 'powerWp': 690,
              'vOc': 49.7, 'vMp': 41.8,
            }], 'inverters': []});
      handler.resolve(Response(requestOptions: request,
        statusCode: 200, data: response));
    }));
    final result = await local(dio).extractEquipmentData(pdf.path);
    expect(sent, hasLength(2));
    for (final request in sent) {
      expect(request.uri.toString(), 'http://127.0.0.1:11434/api/chat');
      expect(request.headers.containsKey('Authorization'), isFalse);
      final body = request.data as Map;
      expect(body['model'], 'qwen3.8:27b');
      expect(body['stream'], isFalse);
      expect((body['format'] as Map)['required'],
          ['modules', 'inverters']);
      expect((body['options'] as Map)['num_ctx'], 16384);
      expect(jsonEncode(body), isNot(contains('application/pdf;base64')));
    }
    final module = result.modules.single;
    expect(module.powerWp, 690);
    expect(module.vOc, 49.7);
    expect(module.fuseCurrent, 35);
    expect(module.minOperatingTemp, -40);
    expect(module.maxOperatingTemp, 85);
    expect(module.physicalWarranty, isNull);
  });

  test('modelo ausente gera erro local sem tentativa OpenRouter', () async {
    final dio = Dio();
    dio.interceptors.add(InterceptorsWrapper(onRequest: (request, handler) {
      handler.reject(DioException(
        requestOptions: request,
        response: Response(requestOptions: request, statusCode: 404),
        type: DioExceptionType.badResponse,
      ));
    }));
    await expectLater(
      local(dio).extractEquipmentData(pdf.path),
      throwsA(isA<StateError>().having(
        (e) => e.message.toString(), 'diagnóstico', contains('ollama list'),
      )),
    );
  });

  test('rejeita endpoint externo antes de enviar qualquer documento', () async {
    var sent = 0;
    final dio = Dio();
    dio.interceptors.add(InterceptorsWrapper(onRequest: (request, handler) {
      sent++;
      handler.resolve(Response(requestOptions: request, data: const {}));
    }));
    await expectLater(
      local(dio, baseUrl: 'https://api.openrouter.ai')
          .extractEquipmentData(pdf.path),
      throwsStateError,
    );
    expect(sent, 0);
  });

  test('PDF escaneado não é enviado à rede sem texto extraído', () async {
    var sent = 0;
    final dio = Dio();
    dio.interceptors.add(InterceptorsWrapper(onRequest: (request, handler) {
      sent++;
      handler.resolve(Response(requestOptions: request, data: const {}));
    }));
    await expectLater(
      local(dio, reader: (path) async => '').extractEquipmentData(pdf.path),
      throwsFormatException,
    );
    expect(sent, 0);
  });

  test('erro de sintaxe JSON pode ser recuperado em segunda leitura local', () async {
    var calls = 0;
    final dio = Dio();
    dio.interceptors.add(InterceptorsWrapper(onRequest: (request, handler) {
      calls++;
      handler.resolve(Response(requestOptions: request,
        statusCode: 200,
        data: calls == 1
            ? {'message': {'content': 'JSON malformado'}}
            : chat({'modules': [
                {'manufacturer': 'Jetion', 'modelName': 'PV700',
                 'powerWp': 700},
              ], 'inverters': []}),
      ));
    }));
    final result = await local(dio).extractEquipmentData(pdf.path);
    expect(calls, greaterThanOrEqualTo(2));
    expect(result.modules.first.powerWp, 700);
  });
}
