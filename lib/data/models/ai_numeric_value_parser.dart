/// Converte formatos de datasheets sem supor unidades nem arredondar faixas.
class AiNumericValueParser {
  static double? number(dynamic raw) {
    if (raw is num) return raw.isFinite ? raw.toDouble() : null;
    if (raw is! String) return null;
    final input = raw.replaceAll('\u00a0', ' ').trim();
    if (input.isEmpty || RegExp(r'^[<>≤≥~]').hasMatch(input)) return null;
    final m = RegExp(
      r'^([+-]?\d[\d.,]*)\s*(kWp|Wp|kW|W|kVA|VA|V|A|kg|mm|%|°C|C)?\s*(STC)?\s*$',
      caseSensitive: false,
    ).firstMatch(input);
    if (m == null) return null;
    final suffix = (m.group(2) ?? '').toLowerCase();
    return _decimal(m.group(1)!,
        thousands: suffix == 'w' || suffix == 'wp' || suffix == 'va');
  }

  static double? powerKw(dynamic raw, {bool rawIsWatts = false}) {
    final value = number(raw);
    if (value == null) return null;
    if (rawIsWatts) return value / 1000;
    if (raw is String) {
      final m = RegExp(r'(kWp|Wp|kW|W|kVA|VA)\s*(?:STC)?\s*$',
          caseSensitive: false).firstMatch(raw);
      if (m != null) {
        final unit = m.group(1)!.toLowerCase();
        if (unit == 'w' || unit == 'wp' || unit == 'va') {
          return value / 1000;
        }
      }
    }
    return value;
  }

  static int? integer(dynamic raw) {
    final value = number(raw);
    return value == null || value != value.roundToDouble() ?
        null : value.toInt();
  }

  static int? mpptCount(dynamic raw) {
    if (raw is String) {
      final m = RegExp(r'^\s*(\d+)\s*/\s*\d+\s*$').firstMatch(raw);
      if (m != null) return int.parse(m.group(1)!);
    }
    return integer(raw);
  }

  static List<double>? currentList(dynamic raw) {
    if (raw is! List && (raw is! String || !raw.contains('/'))) {
      return null;
    }
    final items = raw is List ? raw : (raw as String).split('/');
    if (items.length < 2 || items.length > 16) return null;
    final values = items.map(number).toList();
    if (values.any((v) => v == null || v <= 0)) return null;
    return values.cast<double>();
  }

  static List<double>? mpptRange(dynamic raw) {
    if (raw is! String) return null;
    final m = RegExp(
      r'(\d+(?:[.,]\d+)?)\s*V?\s*[-–~]\s*(\d+(?:[.,]\d+)?)\s*V?',
      caseSensitive: false,
    ).firstMatch(raw);
    if (m == null) return null;
    final min = number(m.group(1));
    final max = number(m.group(2));
    return min == null || max == null || min <= 0 || max < min ?
        null : [min, max];
  }

  static double? nominalFromMpptRange(dynamic raw) {
    if (raw is! String) return null;
    final m = RegExp(r'/\s*(\d+(?:[.,]\d+)?)\s*V',
        caseSensitive: false).firstMatch(raw);
    return m == null ? null : number(m.group(1));
  }

  static double? minCurrent(List<double>? values) =>
      values == null || values.isEmpty ? null :
      values.reduce((a, b) => a < b ? a : b);

  static double? _decimal(String value, {required bool thousands}) {
    var text = value;
    final dot = text.lastIndexOf('.');
    final comma = text.lastIndexOf(',');
    if (dot >= 0 && comma >= 0) {
      text = comma > dot ?
          text.replaceAll('.', '').replaceAll(',', '.') :
          text.replaceAll(',', '');
    } else if (comma >= 0) {
      final digits = text.substring(comma + 1);
      text = thousands && digits.length == 3 ?
          text.replaceAll(',', '') : text.replaceAll(',', '.');
    } else if (dot >= 0 && thousands && text.substring(dot + 1).length == 3) {
      text = text.replaceAll('.', '');
    }
    final parsed = double.tryParse(text);
    return parsed != null && parsed.isFinite ? parsed : null;
  }
}
