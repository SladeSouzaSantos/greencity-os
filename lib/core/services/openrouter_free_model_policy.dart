/// Roteamento explícito somente por modelos com tarifação de tokens gratuita.
/// Não aceita `openrouter/auto`, pois pode selecionar modelos pagos.
class OpenRouterFreeModelPolicy {
  static const defaultPrimary = 'nvidia/nemotron-3.5-super-vl:free';
  static const defaultFallbacks =
      'nvidia/nemotron-3-super-120b-a12b:free';

  static bool isFreeModel(String id) =>
      id.trim().endsWith(':free') &&
      RegExp(r'^[a-zA-Z0-9._-]+/[a-zA-Z0-9._-]+:free$')
          .hasMatch(id.trim());

  /// `fallbacks` é uma string CSV, para configuração simples por .env.
  /// Se omitida, usa o segundo modelo gratuito verificado.
  /// Uma string vazia explícita desativa os fallbacks.
  static List<String> resolve({String? primary, String? fallbacks}) {
    final main = primary?.trim().isNotEmpty == true
        ? primary!.trim()
        : defaultPrimary;
    final backups = (fallbacks ?? defaultFallbacks)
        .split(',')
        .map((x) => x.trim())
        .where((x) => x.isNotEmpty);
    final models = <String>[main, ...backups].toSet().toList();
    if (models.length > 4) {
      throw StateError('Configure no máximo quatro modelos gratuitos.');
    }
    for (final model in models) {
      if (!isFreeModel(model)) {
        throw StateError(
          'A importação gratuita exige modelos com sufixo :free. '
          'Modelo não permitido: $model',
        );
      }
    }
    return models;
  }
}
