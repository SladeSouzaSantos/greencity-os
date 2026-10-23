import '../entities/obstacle_config.dart';
import '../entities/solar_scenario.dart';

/// Validação do contrato do HSP Simulator (OpenAPI v2):
/// https://hsp.greencity.net.br/api/openapi.json
///
/// O Flutter valida antes do envio; a API continua sendo a fonte definitiva
/// de validação e rejeita entradas inválidas com HTTP 422.
class HspInputValidator {
  static double? parseNumber(String? raw) {
    final text = raw?.trim().replaceAll(',', '.');
    if (text == null || text.isEmpty) return null;
    final number = double.tryParse(text);
    return number != null && number.isFinite ? number : null;
  }

  static String? validateNumber(
    String? raw, {
    required String label,
    required double minimum,
    double? maximum,
    bool exclusiveMinimum = false,
  }) {
    final value = parseNumber(raw);
    if (value == null) return 'Informe um número válido para $label.';
    return validateValue(
      value,
      label: label,
      minimum: minimum,
      maximum: maximum,
      exclusiveMinimum: exclusiveMinimum,
    );
  }

  static String? validateValue(
    double value, {
    required String label,
    required double minimum,
    double? maximum,
    bool exclusiveMinimum = false,
  }) {
    if (!value.isFinite) return '$label precisa ser um número finito.';
    if (exclusiveMinimum ? value <= minimum : value < minimum) {
      final threshold = minimum.toStringAsFixed(0);
      return '$label deve ser ${exclusiveMinimum ? 'maior que' : 'maior ou igual a'} $threshold.';
    }
    if (maximum != null && value > maximum) {
      return '$label deve ser menor ou igual a ${maximum.toStringAsFixed(0)}.';
    }
    return null;
  }

  static String? validateInclination(String? value) => validateNumber(
        value,
        label: 'Inclinação',
        minimum: 0,
        maximum: 90,
      );

  static String? validateAzimuth(String? value) => validateNumber(
        value,
        label: 'Azimute',
        minimum: 0,
        maximum: 360,
      );

  static String? validateModuleCenterHeight(String? value) => validateNumber(
        value,
        label: 'Altura do centro do módulo',
        minimum: 0,
      );

  static String? validateObstacleHeight(String? value) => validateNumber(
        value,
        label: 'Altura do obstáculo',
        minimum: 0,
      );

  static String? validateObstacleWidth(String? value) => validateNumber(
        value,
        label: 'Largura do obstáculo',
        minimum: 0,
        exclusiveMinimum: true,
      );

  static String? validateObstacleDistance(String? value) => validateNumber(
        value,
        label: 'Distância do obstáculo',
        minimum: 0,
        exclusiveMinimum: true,
      );

  static String? validateObstacleAzimuth(String? value) => validateNumber(
        value,
        label: 'Azimute do obstáculo',
        minimum: 0,
        maximum: 360,
      );

  static String? validateQuantity(String? raw) {
    final quantity = int.tryParse(raw?.trim() ?? '');
    if (quantity == null) return 'Informe uma quantidade inteira válida.';
    if (quantity < 1) return 'Informe pelo menos um módulo.';
    // Quando há obstáculo cada placa gera um item; o endpoint aceita até 500.
    if (quantity > 500) return 'Máximo de 500 módulos por conjunto.';
    return null;
  }

  static String? validateObstacle(ObstacleConfig obstacle) =>
      validateValue(
        obstacle.height,
        label: 'Altura do obstáculo',
        minimum: 0,
      ) ??
      validateValue(
        obstacle.distance,
        label: 'Distância do obstáculo',
        minimum: 0,
        exclusiveMinimum: true,
      ) ??
      validateValue(
        obstacle.azimuthReference,
        label: 'Azimute do obstáculo',
        minimum: 0,
        maximum: 360,
      ) ??
      validateValue(
        obstacle.width,
        label: 'Largura do obstáculo',
        minimum: 0,
        exclusiveMinimum: true,
      );

  static String? validateScenario(SolarScenario scenario) {
    if (scenario.id.trim().isEmpty) return 'Identificador do módulo obrigatório.';
    if (scenario.quantityPvModule < 1 || scenario.quantityPvModule > 500) {
      return 'A quantidade deve ficar entre 1 e 500 módulos.';
    }
    return validateValue(
          scenario.inclination,
          label: 'Inclinação',
          minimum: 0,
          maximum: 90,
        ) ??
        validateValue(
          scenario.azimuth,
          label: 'Azimute',
          minimum: 0,
          maximum: 360,
        ) ??
        validateValue(
          scenario.albedo,
          label: 'Albedo',
          minimum: 0,
          maximum: 1,
        ) ??
        validateValue(
          scenario.distanceToGround,
          label: 'Altura do centro do módulo',
          minimum: 0,
        ) ??
        (scenario.obstacle == null
            ? null
            : validateObstacle(scenario.obstacle!));
  }

  static String? validateRequest(
    double latitude,
    double longitude,
    List<SolarScenario> items,
  ) {
    final coordinatesError = validateValue(
          latitude,
          label: 'Latitude',
          minimum: -90,
          maximum: 90,
        ) ??
        validateValue(
          longitude,
          label: 'Longitude',
          minimum: -180,
          maximum: 180,
        );
    if (coordinatesError != null) return coordinatesError;
    if (items.isEmpty) return 'Adicione pelo menos um arranjo.';
    if (items.length > 500) return 'A API aceita até 500 arranjos por chamada.';
    for (var i = 0; i < items.length; i++) {
      final issue = validateScenario(items[i]);
      if (issue != null) return 'Arranjo ${i + 1}: $issue';
    }
    return null;
  }
}
