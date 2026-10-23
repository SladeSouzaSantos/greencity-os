/// Validação dos dados do catálogo, independente dos widgets Flutter.
class EquipmentInputValidator {
  static const Set<String> _moduleRequired = {
    'powerWp', 'efficiency', 'length', 'width', 'vOc', 'iSc', 'vMp', 'iMp',
  };
  static const Set<String> _inverterRequired = {
    'nomPowerKw', 'maxInPowerKw', 'mpptCount', 'maxInVolts',
    'minMpptVolts', 'maxMpptVolts', 'maxInCurrPerMppt',
  };
  static const Set<String> _integerFields = {
    'powerWp', 'mpptCount', 'totalDcInputs', 'physWarranty', 'effWarranty', 'warrantyYrs',
  };
  static const Set<String> _textFields = {
    'brand', 'model', 'dimensions', 'protDegree',
    'mpptCurrents', 'mpptIscCurrents',
  };

  static bool isTextField(String key) => _textFields.contains(key);

  static bool isRequired(String key, {required bool isModule}) =>
      key == 'brand' || key == 'model' ||
      (isModule ? _moduleRequired : _inverterRequired).contains(key);

  static String? validate({
    required String key,
    required String? value,
    required bool isModule,
  }) {
    final text = value?.trim() ?? '';
    if (key == 'mpptCurrents' || key == 'mpptIscCurrents') {
      if (text.isEmpty) return null;
      final values = text.split(RegExp(r'[/;]')).map((item) =>
          double.tryParse(item.trim().replaceAll(',', '.'))).toList();
      return values.isNotEmpty &&
              values.every((v) => v != null && v.isFinite && v > 0)
          ? null : 'Informe correntes positivas separadas por / (ex.: 32/16).';
    }
    if (isTextField(key)) {
      return isRequired(key, isModule: isModule) && text.isEmpty
          ? 'Campo obrigatório.'
          : null;
    }
    if (text.isEmpty) {
      return isRequired(key, isModule: isModule)
          ? 'Campo obrigatório.'
          : null;
    }

    final number = double.tryParse(text.replaceAll(',', '.'));
    if (number == null || !number.isFinite) return 'Número inválido.';
    if (_integerFields.contains(key) && number != number.roundToDouble()) {
      return 'Informe um número inteiro.';
    }
    if (isRequired(key, isModule: isModule) && number <= 0) {
      return 'Informe um valor maior que zero.';
    }
    if (!key.startsWith('tempCoef') &&
        !key.startsWith('minOpTemp') &&
        !key.startsWith('maxOpTemp') &&
        number < 0) {
      return 'Valor não pode ser negativo.';
    }
    if ((key == 'efficiency' || key == 'maxEff' ||
         key == 'euroEff' || key == 'effLoss') && number > 100) {
      return 'Máximo de 100%.';
    }
    return null;
  }
}
