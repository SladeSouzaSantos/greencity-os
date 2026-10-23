import 'package:flutter_test/flutter_test.dart';
import 'package:greencity_os/core/services/datasheet_ai_service.dart';
import 'package:greencity_os/data/models/ai_extraction_result_model.dart';

void main() {
  final fixture = AiExtractionResultModel.fromJson({
    'modules': [{'manufacturer': 'Test', 'modelName': 'PV-700',
      'powerWp': 700}],
    'inverters': [],
  });

  test('OLLAMA_ENABLED=true seleciona somente serviço local', () async {
    var local = 0;
    var remote = 0;
    final route = DatasheetAiService(
      ollamaEnabled: true,
      ollamaExtractor: (path) async { local++; return fixture; },
      openRouterExtractor: (path) async { remote++; return fixture; },
    );
    expect(route.providerDescription, contains('Ollama'));
    expect((await route.extractEquipmentData('arquivo.pdf')).modules,
        hasLength(1));
    expect(local, 1);
    expect(remote, 0);
  });

  test('OLLAMA_ENABLED=false mantém OpenRouter sem carregar Ollama', () async {
    var local = 0;
    var remote = 0;
    final route = DatasheetAiService(
      ollamaEnabled: false,
      ollamaExtractor: (path) async { local++; return fixture; },
      openRouterExtractor: (path) async { remote++; return fixture; },
    );
    expect(route.providerDescription, contains('OpenRouter'));
    await route.extractEquipmentData('arquivo.pdf');
    expect(local, 0);
    expect(remote, 1);
  });

  test('falha de Ollama não realiza fallback nem cobrança OpenRouter', () async {
    var remote = 0;
    final route = DatasheetAiService(
      ollamaEnabled: true,
      ollamaExtractor: (path) async =>
          throw StateError('Ollama fora do ar'),
      openRouterExtractor: (path) async { remote++; return fixture; },
    );
    await expectLater(route.extractEquipmentData('arquivo.pdf'),
        throwsStateError);
    expect(remote, 0);
  });
}
