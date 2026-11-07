/// Hourly, obstruction-free irradiance provided by the HSP Simulator.
/// No inverter or MPPT electrical energy is modeled in this contract.
class SolarResourceHour {
  final DateTime startUtc;
  final double solarAzimuthDegrees;
  final double apparentSolarElevationDegrees;
  final double poaGlobalWm2;
  final double poaDirectWm2;
  final double poaSkyDiffuseWm2;
  final double poaGroundWm2;

  const SolarResourceHour({
    required this.startUtc,
    required this.solarAzimuthDegrees,
    required this.apparentSolarElevationDegrees,
    required this.poaGlobalWm2,
    required this.poaDirectWm2,
    required this.poaSkyDiffuseWm2,
    required this.poaGroundWm2,
  });

  static double _number(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is! num || !value.isFinite) {
      throw FormatException('Campo horário não numérico: $key');
    }
    return value.toDouble();
  }

  factory SolarResourceHour.fromJson(Map<String, dynamic> json) {
    final raw = json['inicio_utc'];
    if (raw is! String) throw const FormatException('inicio_utc ausente');
    final timestamp = DateTime.tryParse(raw);
    if (timestamp == null || !timestamp.isUtc) {
      throw const FormatException('inicio_utc precisa ser horário com UTC');
    }
    final result = SolarResourceHour(
      startUtc: timestamp,
      solarAzimuthDegrees: _number(json, 'azimute_solar_graus'),
      apparentSolarElevationDegrees:
          _number(json, 'elevacao_solar_aparente_graus'),
      poaGlobalWm2: _number(json, 'poa_total_w_m2'),
      poaDirectWm2: _number(json, 'poa_direta_w_m2'),
      poaSkyDiffuseWm2: _number(json, 'poa_difusa_ceu_w_m2'),
      poaGroundWm2: _number(json, 'poa_refletida_solo_w_m2'),
    );
    if (result.poaGlobalWm2 < 0 || result.poaDirectWm2 < 0 ||
        result.poaSkyDiffuseWm2 < 0 || result.poaGroundWm2 < 0 ||
        result.poaDirectWm2 > result.poaGlobalWm2 + 0.001 ||
        result.solarAzimuthDegrees < 0 || result.solarAzimuthDegrees > 360 ||
        result.apparentSolarElevationDegrees < -90 ||
        result.apparentSolarElevationDegrees > 90) {
      throw const FormatException('Dados horários fora do domínio físico');
    }
    return result;
  }
}

class HourlySolarResource {
  final int yearUtc;
  final int? monthUtc;
  final String source;
  final List<double> monthlyReferenceHsp;
  final List<SolarResourceHour> samples;

  const HourlySolarResource({
    required this.yearUtc,
    required this.monthUtc,
    required this.source,
    required this.monthlyReferenceHsp,
    required this.samples,
  });

  factory HourlySolarResource.fromJson(Map<String, dynamic> json) {
    if (json['modelo'] != 'recurso_solar_poa_horario_sem_obstaculos_v1' ||
        json['sem_obstaculos'] != true ||
        json['sem_perdas_eletricas'] != true ||
        json['schema_version'] != 1) {
      throw const FormatException('Contrato de recurso solar incompatível');
    }
    final p = json['periodo'];
    final reference = json['hsp_referencia_mensal_kwh_m2_dia'];
    final rawSamples = json['amostras'];
    if (p is! Map || p['ano_utc'] is! int ||
        (p['mes_utc'] != null && p['mes_utc'] is! int) ||
        p['passo_minutos'] != 60 ||
        p['ano_completo_validado'] != true ||
        reference is! List || reference.length != 12 ||
        rawSamples is! List || rawSamples.isEmpty ||
        json['fonte'] is! String) {
      throw const FormatException('Dados de recurso solar incompletos');
    }
    final hsp = reference.map((v) {
      if (v is! num || !v.isFinite || v < 0) {
        throw const FormatException('HSP mensal de referência inválido');
      }
      return v.toDouble();
    }).toList(growable: false);
    final hours = rawSamples.map((v) {
      if (v is! Map) throw const FormatException('Amostra horária inválida');
      return SolarResourceHour.fromJson(Map<String, dynamic>.from(v));
    }).toList(growable: false);
    final month = p['mes_utc'] as int?;
    final year = p['ano_utc'] as int;
    final expectedHours = month == null
        ? (DateTime.utc(year + 1).difference(DateTime.utc(year)).inHours)
        : (DateTime.utc(year, month + 1)
            .difference(DateTime.utc(year, month)).inHours);
    if (month != null && (month < 1 || month > 12)) {
      throw const FormatException('Mês fora de 1–12');
    }
    if (hours.length != expectedHours ||
        p['horas_retornadas'] != expectedHours) {
      throw const FormatException('Período horário incompleto');
    }
    for (var i = 0; i < hours.length; i++) {
      final expected = (month == null ? DateTime.utc(year) : DateTime.utc(year, month))
          .add(Duration(hours: i));
      if (hours[i].startUtc != expected) {
        throw const FormatException('Amostras devem ser contínuas, em UTC');
      }
    }
    return HourlySolarResource(
      yearUtc: year,
      monthUtc: month,
      source: json['fonte'] as String,
      monthlyReferenceHsp: List.unmodifiable(hsp),
      samples: List.unmodifiable(hours),
    );
  }
}
