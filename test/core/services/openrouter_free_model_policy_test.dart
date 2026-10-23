import 'package:flutter_test/flutter_test.dart';
import 'package:greencity_os/core/services/openrouter_free_model_policy.dart';

void main() {
  test('modelos gratuitos são roteados em ordem sem duplicações', () {
    final models = OpenRouterFreeModelPolicy.resolve(
      primary: 'nvidia/nemotron-3.5-super-vl:free',
      fallbacks: 'nvidia/nemotron-3-super-120b-a12b:free,'
          'nvidia/nemotron-3.5-super-vl:free',
    );
    expect(models, [
      'nvidia/nemotron-3.5-super-vl:free',
      'nvidia/nemotron-3-super-120b-a12b:free',
    ]);
    expect(models.every(OpenRouterFreeModelPolicy.isFreeModel), isTrue);
  });

  test('não permite modelos pagos nem auto-router sem garantia de gratuidade', () {
    expect(
      () => OpenRouterFreeModelPolicy.resolve(
        primary: 'google/gemini-3.8-flash',
      ),
      throwsStateError,
    );
    expect(
      () => OpenRouterFreeModelPolicy.resolve(
        primary: 'nvidia/nemotron-3.5-super-vl:free',
        fallbacks: 'openrouter/auto',
      ),
      throwsStateError,
    );
    expect(
      () => OpenRouterFreeModelPolicy.resolve(
        primary: 'nvidia/nemotron-3.5-super-vl:free',
        fallbacks: 'openai/gpt-4o-mini',
      ),
      throwsStateError,
    );
  });

  test('permite desativar fallback explicitamente', () {
    expect(
      OpenRouterFreeModelPolicy.resolve(
        primary: 'nvidia/nemotron-3.5-super-vl:free',
        fallbacks: '',
      ),
      ['nvidia/nemotron-3.5-super-vl:free'],
    );
  });

  test('padrões são gratuitos mesmo sem configuração', () {
    final models = OpenRouterFreeModelPolicy.resolve();
    expect(models, hasLength(2));
    expect(models.every(OpenRouterFreeModelPolicy.isFreeModel), isTrue);
  });
}
