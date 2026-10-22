import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import '../models/solar_engine_result_model.dart';
import '../models/solar_quote_model.dart';

abstract class SolarRemoteDataSource {
  Future<SolarEngineResultModel> getCalculateArray({
    required double latitude,
    required double longitude,
    required List<Map<String, dynamic>> items,
  });

  Future<List<int>> generateQuotePDF(SolarQuoteModel request);
  
}

@LazySingleton(as: SolarRemoteDataSource)
class SolarRemoteDataSourceImpl implements SolarRemoteDataSource {
  final Dio dio;

  SolarRemoteDataSourceImpl({required this.dio});

  @override
  Future<SolarEngineResultModel> getCalculateArray({
    required double latitude,
    required double longitude,
    required List<Map<String, dynamic>> items,
  }) async {
    const url = 'https://hsp.greencity.net.br/api/calcular-arranjo';
    
    try {      
      // 1. O 'await' fica dentro do 'try'
      final response = await dio.post(
        url,
        data: {
          'latitude': latitude,
          'longitude': longitude,
          'itens': items,
        },
      );

      // 2. Se chegou aqui, a rede funcionou. Verificamos o status da API.
      if (response.statusCode == 200) {
        return SolarEngineResultModel.fromJson(response.data);
      } else {
        throw Exception('Erro do Servidor: Código ${response.statusCode}');
      }

    } on DioException catch (e) {
      // 3. Captura erros específicos do Dio (Internet fora, timeout, etc)
      // Você pode logar isso ou tratar conforme o tipo de erro
      String errorMessage = 'Erro de conexão desconhecido';
      
      if (e.type == DioExceptionType.connectionTimeout) {
        errorMessage = 'Tempo de conexão esgotado. Verifique sua internet.';
      } else if (e.response?.statusCode == 404) {
        errorMessage = 'Endpoint da API não encontrado.';
      }
      
      throw Exception(errorMessage);
    } catch (e) {
      // 4. Captura qualquer outro erro inesperado
      throw Exception('Erro inesperado: $e');
    }
  }

  @override
  Future<List<int>> generateQuotePDF(SolarQuoteModel request) async {
    const url = "https://orcamento.greencity.net.br/api/gerar-orcamento";
    try {
      final response = await dio.post(
        url, 
        data: request.toJson(),
        options: Options(responseType: ResponseType.bytes), // ESSENCIAL
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data; // Retorna os bytes do PDF
      }
      throw Exception("Erro ao gerar PDF");
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    }
  }

  String _handleDioError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout) return 'Erro de timeout.';
    if (e.response?.statusCode == 404) return 'API não encontrada.';
    return e.response?.data?['message'] ?? 'Erro de conexão desconhecido';
  }

}