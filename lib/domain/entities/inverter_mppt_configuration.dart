import 'dart:convert';

/// Dados por rastreador quando o datasheet distingue as entradas CC.
/// Não atribui automaticamente a quantidade total de entradas por MPPT.
class InverterMpptConfiguration {
  final List<double>? inputCurrentsA;
  final List<double>? shortCircuitCurrentsA;
  final int? totalDcInputs;

  const InverterMpptConfiguration({
    this.inputCurrentsA,
    this.shortCircuitCurrentsA,
    this.totalDcInputs,
  });

  bool get hasDetails => inputCurrentsA != null ||
      shortCircuitCurrentsA != null || totalDcInputs != null;

  String encode() => jsonEncode({
    if (inputCurrentsA != null) 'inputCurrentsA': inputCurrentsA,
    if (shortCircuitCurrentsA != null)
      'shortCircuitCurrentsA': shortCircuitCurrentsA,
    if (totalDcInputs != null) 'totalDcInputs': totalDcInputs,
  });

  static InverterMpptConfiguration? decode(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    try {
      final json = jsonDecode(raw);
      if (json is! Map) return null;
      List<double>? numbers(Object? value) {
        if (value is! List || value.isEmpty) return null;
        final values = <double>[];
        for (final element in value) {
          if (element is! num || !element.isFinite || element <= 0) {
            return null;
          }
          values.add(element.toDouble());
        }
        return List.unmodifiable(values);
      }
      final count = json['totalDcInputs'];
      final data = InverterMpptConfiguration(
        inputCurrentsA: numbers(json['inputCurrentsA']),
        shortCircuitCurrentsA: numbers(json['shortCircuitCurrentsA']),
        totalDcInputs: count is int && count > 0 ? count : null,
      );
      return data.hasDetails ? data : null;
    } on FormatException {
      return null;
    }
  }

  /// Indica divergência, nunca converte entradas CC em rastreadores.
  List<String> validate(int mpptCount) {
    final errors = <String>[];
    if (inputCurrentsA != null && inputCurrentsA!.length != mpptCount) {
      errors.add('correntes Impp não correspondem à quantidade de MPPTs');
    }
    if (shortCircuitCurrentsA != null &&
        shortCircuitCurrentsA!.length != mpptCount) {
      errors.add('correntes Isc não correspondem à quantidade de MPPTs');
    }
    if (totalDcInputs != null && totalDcInputs! < mpptCount) {
      errors.add('entradas CC não podem ser menores que a quantidade de MPPTs');
    }
    return errors;
  }
}
