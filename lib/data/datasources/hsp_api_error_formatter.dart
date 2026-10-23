import 'package:dio/dio.dart';

/// Tradução das respostas da API FastAPI/Pydantic para mensagens de UI.
/// Não imprime o payload, tokens nem outras informações sensíveis.
class HspApiErrorFormatter {
  static const Map<String, String> _labels = {
    'altura_obstaculo': 'Altura do obstáculo',
    'distancia_obstaculo': 'Distância do obstáculo',
    'largura_obstaculo': 'Largura do obstáculo',
    'referencia_azimutal_obstaculo': 'Azimute do obstáculo',
    'inclinacao_graus': 'Inclinação',
    'azimute_graus': 'Azimute',
    'albedo_solo': 'Albedo',
    'distancia_centro_modulo_chao': 'Altura do centro do módulo',
    'tecnologia_celula': 'Tecnologia da célula',
    'comprimento_modulo': 'Comprimento do módulo',
    'largura_modulo': 'Largura do módulo',
    'orientacao': 'Orientação do módulo',
    'is_bifacial': 'Bifacialidade',
    'id_placa': 'Identificador do módulo',
    'latitude': 'Latitude',
    'longitude': 'Longitude',
    'itens': 'Arranjos',
    'fonte_dados': 'Fonte meteorológica',
    'modelo_transposicao': 'Modelo de transposição',
  };

  static String format(DioException error) {
    final status = error.response?.statusCode;
    if (status == 422) return _format422(error.response?.data);
    if (status == 404) return 'Endpoint da API HSP não encontrado (HTTP 404).';
    if (status == 429) return 'Muitas requisições à API HSP (HTTP 429). Tente novamente.';
    if (status != null && status >= 500) {
      return 'Serviço HSP indisponível ou com erro (HTTP $status).';
    }
    if (status != null && status >= 400) {
      return 'A API HSP rejeitou a requisição (HTTP $status).';
    }

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        return 'Tempo de conexão com a API HSP esgotado.';
      case DioExceptionType.sendTimeout:
        return 'Tempo limite ao enviar dados à API HSP.';
      case DioExceptionType.receiveTimeout:
        return 'A API HSP demorou demais para responder.';
      case DioExceptionType.connectionError:
        return 'Não foi possível conectar à API HSP. Verifique sua conexão.';
      case DioExceptionType.badCertificate:
        return 'Falha ao validar o certificado da API HSP.';
      case DioExceptionType.cancel:
        return 'Cálculo HSP cancelado.';
      case DioExceptionType.badResponse:
      case DioExceptionType.unknown:
        return 'Falha de comunicação com a API HSP.';
    }
  }

  static String _format422(dynamic responseData) {
    if (responseData is! Map) {
      return 'Dados inválidos para a API HSP (HTTP 422).';
    }
    final detail = responseData['detail'];
    if (detail is String && detail.trim().isNotEmpty) {
      return 'Dados inválidos (HTTP 422): $detail';
    }
    if (detail is! List || detail.isEmpty) {
      return 'Dados inválidos para a API HSP (HTTP 422).';
    }

    final failures = <String>[];
    for (final raw in detail.take(3)) {
      if (raw is! Map) continue;
      final loc = raw['loc'] is List ? raw['loc'] as List : const [];
      final field = loc.isNotEmpty ? loc.last.toString() : 'campo';
      final label = _labels[field] ?? field.replaceAll('_', ' ');

      // Pydantic usa ["body", "itens", 0, ...] para localizar um erro
      // no primeiro arranjo do lote. Convertido aqui para índice humano.
      final itemsPos = loc.indexOf('itens');
      final itemPos = itemsPos >= 0 && itemsPos + 1 < loc.length
          ? loc[itemsPos + 1]
          : null;
      final prefix = itemPos is int ? 'Arranjo ${itemPos + 1}: ' : '';

      final type = raw['type'];
      final ctx = raw['ctx'];
      final limits = ctx is Map ? ctx : const {};
      String description;
      switch (type) {
        case 'greater_than':
          description = 'deve ser maior que ${limits['gt'] ?? 0}';
          break;
        case 'greater_than_equal':
          description = 'deve ser maior ou igual a ${limits['ge'] ?? 0}';
          break;
        case 'less_than':
          description = 'deve ser menor que ${limits['lt'] ?? 0}';
          break;
        case 'less_than_equal':
          description = 'deve ser menor ou igual a ${limits['le'] ?? 0}';
          break;
        case 'missing':
          description = 'é obrigatório';
          break;
        case 'float_parsing':
        case 'int_parsing':
        case 'float_type':
        case 'int_type':
          description = 'deve ser numérico';
          break;
        default:
          description = raw['msg'] is String
              ? (raw['msg'] as String)
              : 'contém um valor inválido';
          break;
      }
      failures.add('$prefix$label $description');
    }
    if (failures.isEmpty) return 'Dados inválidos para a API HSP (HTTP 422).';
    final more = detail.length > 3 ? ' (e outros erros)' : '';
    return 'Dados inválidos (HTTP 422): ${failures.join('; ')}$more.';
  }
}
