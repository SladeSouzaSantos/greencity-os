import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greencity_os/core/services/cloud_datasheet_service.dart';
import 'package:greencity_os/core/services/cloud_provider_support.dart';
import 'package:greencity_os/core/services/datasheet_ai_service.dart';
import 'package:greencity_os/core/services/openrouter_quota_service.dart';
import 'package:greencity_os/data/models/ai_extraction_result_model.dart';

void main() {
  late Directory temp;
  late File pdf;
  setUp(() async {
    temp = await Directory.systemTemp.createTemp('cloud_router_test');
    pdf = File('${temp.path}/sample.pdf');
    await pdf.writeAsString('%PDF-1.7\nvalid-fixture');
  });
  tearDown(() async => temp.delete(recursive: true));

  final fixture = AiExtractionResultModel.fromJson({
    'modules': [
      {'manufacturer': 'Jetion', 'modelName': 'JT690', 'powerWp': 690},
    ], 'inverters': [],
  });

  test('Gemini tem prioridade sobre OpenRouter com ambos configurados',
      () async {
    final attempts = <CloudAiProvider>[];
    var checkedOpenRouter = 0;
    final route = DatasheetAiService(
      aiProvider: 'auto', cloudFallbackEnabled: true,
      configuredProviders: {
        CloudAiProvider.gemini, CloudAiProvider.openRouter,
      },
      openRouterCapacityCheck: (_) async { checkedOpenRouter++; return true; },
      openRouterExtractor: (_) async {
        attempts.add(CloudAiProvider.openRouter);
        return fixture;
      },
      cloudExtractor: (provider, path) async {
        attempts.add(provider);
        return fixture;
      },
    );
    await route.extractEquipmentData(pdf.path);
    expect(attempts, [CloudAiProvider.gemini]);
    expect(checkedOpenRouter, 0,
        reason: 'Nenhuma consulta ao OpenRouter antes do Gemini funcionar');
    expect(route.providerDescription, contains('Google Gemini'));
  });

  test('Gemini falha, OpenRouter tem cota disponível e é selecionado',
      () async {
    final attempts = <CloudAiProvider>[];
    var checks = 0;
    final route = DatasheetAiService(
      aiProvider: 'auto', cloudFallbackEnabled: true,
      configuredProviders: {
        CloudAiProvider.gemini, CloudAiProvider.openRouter,
        CloudAiProvider.groq,
      },
      openRouterCapacityCheck: (_) async { checks++; return true; },
      openRouterExtractor: (_) async {
        attempts.add(CloudAiProvider.openRouter);
        return fixture;
      },
      cloudExtractor: (provider, path) async {
        attempts.add(provider);
        throw CloudProviderFailure('limite_requisicoes', '429');
      },
    );
    await route.extractEquipmentData(pdf.path);
    expect(attempts, [CloudAiProvider.gemini, CloudAiProvider.openRouter]);
    expect(checks, 1);
    expect(route.providerDescription, contains('OpenRouter'));
  });

  test('Gemini falha e OpenRouter sem cota: continua no Groq', () async {
    final called = <CloudAiProvider>[];
    final route = DatasheetAiService(
      aiProvider: 'auto', cloudFallbackEnabled: true,
      configuredProviders: {
        CloudAiProvider.gemini, CloudAiProvider.openRouter,
        CloudAiProvider.groq,
      },
      openRouterCapacityCheck: (_) async => false,
      openRouterExtractor: (_) async {
        called.add(CloudAiProvider.openRouter);
        return fixture;
      },
      cloudExtractor: (provider, path) async {
        called.add(provider);
        if (provider == CloudAiProvider.gemini) {
          throw CloudProviderFailure('limite_requisicoes', '429');
        }
        return fixture;
      },
    );
    await route.extractEquipmentData(pdf.path);
    expect(called, [CloudAiProvider.gemini, CloudAiProvider.groq]);
    expect(route.providerDescription, contains('Groq'));
  });

  test('limite na inferência após preflight avança na ordem configurada',
      () async {
    final attempts = <CloudAiProvider>[];
    final route = DatasheetAiService(
      aiProvider: 'auto', cloudFallbackEnabled: true,
      configuredProviders: CloudAiProvider.values.toSet(),
      openRouterCapacityCheck: (_) async => true,
      openRouterExtractor: (_) async {
        attempts.add(CloudAiProvider.openRouter);
        throw CloudProviderFailure('limite_requisicoes', '429');
      },
      cloudExtractor: (provider, path) async {
        attempts.add(provider);
        if (provider == CloudAiProvider.mistral) return fixture;
        throw CloudProviderFailure('servico_indisponivel', '503');
      },
    );
    await route.extractEquipmentData(pdf.path);
    expect(attempts, [
      CloudAiProvider.gemini, CloudAiProvider.openRouter,
      CloudAiProvider.groq, CloudAiProvider.mistral,
    ]);
    expect(route.providerDescription, contains('Mistral'));
  });

  test('Cloudflare e Cohere são alcançados e último funciona', () async {
    final called = <CloudAiProvider>[];
    final route = DatasheetAiService(
      aiProvider: 'auto', cloudFallbackEnabled: true,
      configuredProviders: CloudAiProvider.values.toSet(),
      openRouterCapacityCheck: (_) async => false,
      cloudExtractor: (provider, path) async {
        called.add(provider);
        if (provider == CloudAiProvider.cohere) return fixture;
        throw CloudProviderFailure('limite_requisicoes', '429');
      },
    );
    await route.extractEquipmentData(pdf.path);
    expect(called, [
      CloudAiProvider.gemini, CloudAiProvider.groq,
      CloudAiProvider.mistral, CloudAiProvider.cloudflare,
      CloudAiProvider.cohere,
    ]);
    expect(route.providerDescription, contains('Cohere'));
  });

  test('erro 400 do Gemini não retransmite PDF ao OpenRouter',
      () async {
    var calledOpenRouter = 0;
    final route = DatasheetAiService(
      aiProvider: 'auto', cloudFallbackEnabled: true,
      configuredProviders: {
        CloudAiProvider.gemini, CloudAiProvider.openRouter,
      },
      openRouterCapacityCheck: (_) async => true,
      openRouterExtractor: (_) async {
        calledOpenRouter++;
        return fixture;
      },
      cloudExtractor: (_, __) async =>
          throw CloudProviderFailure('requisicao_invalida', 'PDF inválido',
            allowFallback: false, httpStatus: 400),
    );
    await expectLater(route.extractEquipmentData(pdf.path),
      throwsA(isA<StateError>()));
    expect(calledOpenRouter, 0);
  });

  test('fallback desligado preserva erro do Gemini sem OpenRouter', () async {
    var called = 0;
    final route = DatasheetAiService(
      aiProvider: 'auto', cloudFallbackEnabled: false,
      configuredProviders: {
        CloudAiProvider.gemini, CloudAiProvider.openRouter,
      },
      openRouterCapacityCheck: (_) async => true,
      openRouterExtractor: (_) async { called++; return fixture; },
      cloudExtractor: (_, __) async =>
          throw CloudProviderFailure('limite_requisicoes', '429'),
    );
    await expectLater(route.extractEquipmentData(pdf.path), throwsStateError);
    expect(called, 0);
  });

  test('PDF inválido é rejeitado antes de consultar provedores', () async {
    await pdf.writeAsString('not-a-pdf');
    var called = 0;
    final route = DatasheetAiService(
      aiProvider: 'auto', configuredProviders: {
        CloudAiProvider.openRouter, CloudAiProvider.gemini,
      },
      openRouterCapacityCheck: (_) async { called++; return true; },
      cloudExtractor: (_, __) async { called++; return fixture; },
    );
    await expectLater(route.extractEquipmentData(pdf.path),
      throwsFormatException);
    expect(called, 0);
  });

  test('quota OpenRouter é identificada pelo campo diário restante', () async {
    final dio = Dio();
    dio.interceptors.add(InterceptorsWrapper(onRequest: (request, handler) {
      expect(request.uri.path, '/api/v1/key');
      handler.resolve(Response(
        requestOptions: request,
        statusCode: 200,
        data: {
          'data': {
            'limit_remaining': null,
            'free_model_daily_requests': {
              'limit': 50, 'used': 50, 'remaining': 0,
            },
          },
        },
      ));
    }));
    expect(await OpenRouterQuotaService(dio: dio).hasFreeCapacity('fake'),
        isFalse);
  });

  test('erro de rede na verificação de cota não significa cota esgotada',
      () async {
    final dio = Dio();
    dio.interceptors.add(InterceptorsWrapper(onRequest: (request, handler) {
      handler.reject(DioException(requestOptions: request,
        type: DioExceptionType.connectionTimeout));
    }));
    expect(await OpenRouterQuotaService(dio: dio).hasFreeCapacity('fake'),
        isNull);
  });

  test('adaptadores produzem JSON tipado para os cinco provedores', () async {
    for (final provider in [
      CloudAiProvider.gemini, CloudAiProvider.groq,
      CloudAiProvider.mistral, CloudAiProvider.cloudflare,
      CloudAiProvider.cohere,
    ]) {
      final dio = Dio();
      final responseJson = jsonEncode({
        'modules': [{'manufacturer': 'Jetion', 'modelName': 'JT690',
          'powerWp': 690}],
        'inverters': [],
      });
      dio.interceptors.add(InterceptorsWrapper(onRequest: (req, handler) {
        final payload = req.data as Map;
        if (provider == CloudAiProvider.gemini) {
          final parts = ((payload['contents'] as List).first
              as Map)['parts'] as List;
          expect((parts.last as Map)['inline_data']['mime_type'],
              'application/pdf');
        } else {
          expect(jsonEncode(payload), isNot(contains('inline_data')));
        }
        final reply = switch (provider) {
          CloudAiProvider.gemini => {
            'candidates': [{'content': {'parts': [{'text': responseJson}]}}],
            'usageMetadata': {'promptTokenCount': 100,
              'candidatesTokenCount': 200},
          },
          CloudAiProvider.cloudflare =>
            {'success': true, 'result': {'response': responseJson}},
          CloudAiProvider.cohere => {'message': {'content': [
            {'type': 'text', 'text': responseJson},
          ]}},
          _ => {'choices': [{'message': {'content': responseJson}}],
            'usage': {'prompt_tokens': 100, 'completion_tokens': 200}},
        };
        handler.resolve(Response(
          requestOptions: req, statusCode: 200, data: reply,
        ));
      }));
      final service = CloudDatasheetService(
        dio: dio,
        apiKeys: {provider: 'test-key'},
        models: {provider: 'test-model'},
        cloudflareAccountId: 'test-id',
        pdfTextReader: (_) async => 'Jetion JT690 datasheet sample text.',
        timeoutSeconds: 90,
      );
      final result = await service.extract(provider, pdf.path);
      expect(result.modules.single.powerWp, 690,
          reason: 'Falhou provider ${provider.name}');
    }
  });
  test('PyMuPDF é executado apenas uma vez entre provedores de texto', () async {
    var pdfReads = 0;
    final dio = Dio();
    dio.interceptors.add(InterceptorsWrapper(onRequest: (request, handler) {
      final reply = jsonEncode({'modules': [
        {'manufacturer': 'Jetion', 'modelName': 'JT690', 'powerWp': 690},
      ], 'inverters': []});
      handler.resolve(Response(requestOptions: request, statusCode: 200,
        data: {'choices': [{'message': {'content': reply}}]}));
    }));
    final service = CloudDatasheetService(
      dio: dio,
      apiKeys: {
        CloudAiProvider.groq: 'test-key',
        CloudAiProvider.mistral: 'test-key',
      },
      models: {
        CloudAiProvider.groq: 'test-model',
        CloudAiProvider.mistral: 'test-model',
      },
      pdfTextReader: (_) async {
        pdfReads++;
        return 'Jetion JT690 data sheet: 690 W nominal power.';
      },
      timeoutSeconds: 60,
    );
    await service.extract(CloudAiProvider.groq, pdf.path);
    await service.extract(CloudAiProvider.mistral, pdf.path);
    expect(pdfReads, 1);
  });

}
