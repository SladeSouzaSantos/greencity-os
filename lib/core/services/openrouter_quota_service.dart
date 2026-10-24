import 'package:dio/dio.dart';

import 'cloud_provider_support.dart';

/// GET /key informa limite diário :free e limite da chave, mas não a
/// disponibilidade por minuto ou do modelo: a requisição real prevalece.
class OpenRouterQuotaService {
  final Dio _dio;
  OpenRouterQuotaService({Dio? dio}) : _dio = dio ?? Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 8),
    receiveTimeout: const Duration(seconds: 12),
  ));

  Future<bool?> hasFreeCapacity(String apiKey) async {
    try {
      final response = await _dio.get<dynamic>(
        'https://openrouter.ai/api/v1/key',
        options: Options(headers: {'Authorization': 'Bearer $apiKey'}),
      );
      final body = response.data;
      if (body is! Map || body['data'] is! Map) return null;
      final key = body['data'] as Map;
      final remaining = key['limit_remaining'];
      if (remaining is num && remaining <= 0) return false;
      final free = key['free_model_daily_requests'];
      if (free is Map) {
        final freeRemaining = free['remaining'];
        if (freeRemaining is num && freeRemaining <= 0) return false;
      }
      return true;
    } on DioException catch (error) {
      // Chave inválida não pode ser resolvida repetindo a requisição.
      if (error.response?.statusCode == 401 ||
          error.response?.statusCode == 403) {
        throw CloudProviderFailure(
          'acesso_negado', 'A chave OpenRouter foi rejeitada.',
          httpStatus: error.response?.statusCode,
        );
      }
      // Uma falha na consulta NÃO comprova falta de cota. Tenta inferência.
      return null;
    }
  }
}
