import 'package:dio/dio.dart';
import '../../domain/solar3d/solar_resource_hour.dart';
import 'hsp_api_error_formatter.dart';

/// Opt-in hourly POA client. Not used by the existing sizing workflow.
/// The endpoint must be deployed on HSP before this class is activated.
class SolarResourceHourlyDataSource {
  final Dio dio;
  final String endpoint;

  const SolarResourceHourlyDataSource({
    required this.dio,
    this.endpoint = 'https://hsp.greencity.net.br/api/recurso-solar/horario',
  });

  Future<HourlySolarResource> getHourlyResource({
    required double latitude,
    required double longitude,
    required double inclination,
    required double azimuth,
    double albedo = 0.2,
    String transposition = 'perez',
    String source = 'auto',
    int? yearUtc,
    int? monthUtc,
  }) async {
    if (!latitude.isFinite || latitude.abs() > 90 ||
        !longitude.isFinite || longitude.abs() > 180 ||
        !inclination.isFinite || inclination < 0 || inclination > 90 ||
        !azimuth.isFinite || azimuth < 0 || azimuth > 360 ||
        !albedo.isFinite || albedo < 0 || albedo > 1 ||
        (monthUtc != null && (monthUtc < 1 || monthUtc > 12)) ||
        !['perez', 'haydavies', 'isotropic'].contains(transposition) ||
        !['auto', 'NASA POWER', 'PVGIS'].contains(source)) {
      throw const FormatException('Parâmetros de recurso solar inválidos');
    }
    try {
      final response = await dio.post<Object?>(
        endpoint,
        data: <String, Object?>{
          'latitude': latitude,
          'longitude': longitude,
          'inclinacao_graus': inclination,
          'azimute_graus': azimuth,
          'albedo_solo': albedo,
          'modelo_transposicao': transposition,
          'fonte_dados': source,
          if (yearUtc != null) 'ano_utc': yearUtc,
          if (monthUtc != null) 'mes_utc': monthUtc,
        },
        options: Options(
          receiveTimeout: const Duration(seconds: 90),
          sendTimeout: const Duration(seconds: 30),
        ),
      );
      if (response.statusCode != 200 || response.data is! Map) {
        throw const FormatException('Resposta horária inválida');
      }
      return HourlySolarResource.fromJson(
        Map<String, dynamic>.from(response.data! as Map),
      );
    } on DioException catch (error) {
      throw Exception(HspApiErrorFormatter.format(error));
    }
  }
}
