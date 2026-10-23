import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greencity_os/core/services/openrouter_datasheet_service.dart';

void main() {
  const primary = 'nvidia/nemotron-3.5-super-vl:free';
  const fallback = 'nvidia/nemotron-3-super-120b-a12b:free';
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

  Map<String, dynamic> completion({String? content, String? model}) => {
    'model': model ?? primary,
    'choices': [
      {
        'finish_reason': 'stop',
        'message': {
          'role': 'assistant',
          'content': content ?? jsonEncode({
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
  };

  OpenRouterDatasheetService createService(Dio dio) =>
      OpenRouterDatasheetService(
        dio: dio,
        apiKey: 'test-not-secret',
        model: primary,
        fallbackModels: fallback,
        pdfEngine: 'cloudflare-ai',
      );

  test('envia apenas modelos :free, PDF Base64 e chave sem rede', () async {
    final dio = Dio();
    RequestOptions? captured;
    dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
      captured = options;
      handler.resolve(Response(
        requestOptions: options,
        statusCode: 200,
        data: completion(),
      ));
    }));
    final result = await createService(dio).extractEquipmentData(pdf.path);

    expect(result.modules, hasLength(2));
    expect(result.inverters, hasLength(1));
    expect(result.modules.first.modelName, 'PV-600');
    expect(result.modules.last.modelName, 'PV-605');
    expect(captured!.uri.toString(), OpenRouterDatasheetService.endpoint);
    expect(captured!.headers['Authorization'], 'Bearer test-not-secret');

    final body = captured!.data as Map;
    expect(body['model'], primary);
    expect(body['models'], [primary, fallback]);
    expect(body['response_format'], {'type': 'json_object'});
    expect((body['plugins'] as List).first['pdf'], {'engine': 'cloudflare-ai'});
    final content = ((body['messages'] as List).first['content'] as List);
    final part = content[1] as Map;
    expect(part['type'], 'file');
    expect(part['file']['filename'], 'datasheet.pdf');
    expect(part['file']['file_data'] as String,
        startsWith('data:application/pdf;base64,JVBERi0'));
  });

  test('tenta um fallback gratuito se a IA responder 200 sem JSON', () async {
    final dio = Dio();
    final attempts = <List<String>>[];
    dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
      attempts.add(List<String>.from((options.data as Map)['models'] as List));
      handler.resolve(Response(
        requestOptions: options,
        statusCode: 200,
        data: attempts.length == 1
            ? completion(content: 'não é JSON')
            : completion(model: fallback),
      ));
    }));
    final result = await createService(dio).extractEquipmentData(pdf.path);
    expect(result.modules, hasLength(2));
    expect(attempts, [[primary, fallback], [fallback]]);
  });

  test('reenvia sem response_format apenas em erro 400 específico', () async {
    final dio = Dio();
    final bodies = <Map>[];
    dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
      bodies.add(options.data as Map);
      if (bodies.length == 1) {
        handler.reject(DioException(
          requestOptions: options,
          response: Response(
            requestOptions: options,
            statusCode: 400,
            data: {'error': {'message': 'response_format is not supported'}},
          ),
          type: DioExceptionType.badResponse,
        ));
      } else {
        handler.resolve(Response(
          requestOptions: options,
          statusCode: 200,
          data: completion(),
        ));
      }
    }));
    final result = await createService(dio).extractEquipmentData(pdf.path);
    expect(result.modules, hasLength(2));
    expect(bodies, hasLength(2));
    expect(bodies.first.containsKey('response_format'), isTrue);
    expect(bodies.last.containsKey('response_format'), isFalse);
  });

  test('HTTP 400 de PDF não repete requisição malformada', () async {
    final dio = Dio();
    var attempts = 0;
    dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
      attempts++;
      handler.reject(DioException(
        requestOptions: options,
        response: Response(
          requestOptions: options,
          statusCode: 400,
          data: {'error': {'message': 'invalid PDF file input'}},
        ),
        type: DioExceptionType.badResponse,
      ));
    }));
    await expectLater(
      createService(dio).extractEquipmentData(pdf.path),
      throwsA(isA<StateError>().having(
        (error) => error.message.toString(), 'diagnóstico', contains('PDF'),
      )),
    );
    expect(attempts, 1);
  });

  test('HTTP 401 não repete tentativas nem expõe a chave', () async {
    final dio = Dio();
    var attempts = 0;
    dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
      attempts++;
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
      model: primary,
      fallbackModels: fallback,
      pdfEngine: 'cloudflare-ai',
    );
    await expectLater(service.extractEquipmentData(pdf.path),
      throwsA(
        isA<StateError>()
          .having((e) => e.message.toString(), 'mensagem',
              contains('OPENROUTER_API_KEY'))
          .having((e) => e.message.toString(), 'sem a chave',
              isNot(contains('private-key'))),
      ),
    );
    expect(attempts, 1);
  });

  test('não aceita modelo pago antes da tentativa HTTP', () async {
    final dio = Dio();
    var attempts = 0;
    dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
      attempts++;
      handler.reject(DioException(requestOptions: options));
    }));
    final service = OpenRouterDatasheetService(
      dio: dio,
      apiKey: 'test',
      model: 'google/gemini-3.8-flash',
      fallbackModels: fallback,
      pdfEngine: 'cloudflare-ai',
    );
    await expectLater(service.extractEquipmentData(pdf.path),
        throwsStateError);
    expect(attempts, 0);
  });

  test('não aceita OCR pago antes da tentativa HTTP', () async {
    final service = OpenRouterDatasheetService(
      apiKey: 'test',
      model: primary,
      fallbackModels: fallback,
      pdfEngine: 'mistral-ocr',
    );
    await expectLater(service.extractEquipmentData(pdf.path),
        throwsStateError);
  });

  test('datasheet multicoluna AUXSOL: identifica sete inversores distintos', () {
    // Referência: Datasheet AUXSOL ASN (3-6)SL-G2, revisão 20/07/2026.
    // Este é um teste do contrato JSON/parser, NÃO uma chamada real à IA.
    const models = <String>[
      'ASN-3SL',
      'ASN-3.3SL',
      'ASN-3.6SL-G2',
      'ASN-4SL-G2',
      'ASN-4.6SL-G2',
      'ASN-5SL-G2',
      'ASN-6SL-G2',
    ];
    const powers = <double>[3, 3.3, 3.6, 4, 4.6, 5, 6];
    const dcPowers = <double>[6, 6.6, 7.2, 8, 9.2, 10, 12];
    const maxOutput = <double>[15, 15, 18, 20, 23, 25, 27.3];
    final json = jsonEncode({
      'modules': <Object>[],
      'inverters': List.generate(models.length, (index) => {
        'manufacturer': 'AUXSOL',
        'modelName': models[index],
        'inverterType': 'string',
        'gridConnection': 'monophasic',
        'nominalPowerKw': powers[index],
        'maxInputPowerKw': dcPowers[index],
        'maxEfficiency': 97.5,
        'euroEfficiency': 97.0,
        'mpptCount': index < 2 ? 1 : 2,
        'maxInputVoltage': 550,
        'nominalVoltageDc': 360,
        'startVoltage': 40,
        'minMpptVoltage': 40,
        'maxMpptVoltage': 520,
        'maxInputCurrentPerMppt': 18,
        'maxShortCircuitCurrent': 22,
        'maxOutputCurrent': maxOutput[index],
        'nominalVoltageAc': 220,
        'dimensions': index < 2 ? '297x239x139mm' : '330x268x168mm',
        'protectionDegree': 'IP66',
      }),
    });
    final result = OpenRouterDatasheetService.parseCompletion(
      completion(content: json),
    );
    expect(result.modules, isEmpty);
    expect(result.inverters, hasLength(7));
    for (var index = 0; index < models.length; index++) {
      final inv = result.inverters[index];
      expect(inv.modelName, models[index]);
      expect(inv.nominalPowerKw, powers[index]);
      expect(inv.maxInputPowerKw, dcPowers[index]);
      expect(inv.mpptCount, index < 2 ? 1 : 2);
      expect(inv.maxInputCurrentPerMppt, 18);
      expect(inv.maxOutputCurrent, maxOutput[index]);
    }
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

  test('preserva JSON válido mesmo se o modelo disser finish_reason length', () {
    final result = OpenRouterDatasheetService.parseCompletion({
      'choices': [{
        'finish_reason': 'length',
        'message': {
          'content': jsonEncode({
            'modules': [
              {'manufacturer': 'Jetion', 'modelName': 'JT700SLk(B)',
               'powerWp': 700}
            ],
            'inverters': [],
          }),
        },
      }],
    });
    expect(result.modules, hasLength(1));
  });

  test('falha ao encontrar JSON cortado, sem cadastrar dados inconsistentes', () {
    expect(() => OpenRouterDatasheetService.parseCompletion({
      'choices': [
        {'finish_reason': 'length',
         'message': {'content': '{"modules":[{"modelName":"modelo","powerWp":'}}
      ]
    }), throwsFormatException);
  });

  test('recusa arquivos sem assinatura PDF antes de enviar', () async {
    await pdf.writeAsString('not a PDF');
    final service = OpenRouterDatasheetService(apiKey: 'test');
    await expectLater(service.extractEquipmentData(pdf.path),
        throwsFormatException);
  });
}
