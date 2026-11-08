import 'package:flutter/material.dart';

import '../../../domain/solar3d/electrical/solar3d_single_diode.dart';

/// Manual import from a traceable calibration or manufacturer's model fit.
/// STC nameplate numbers are NOT silently converted to five parameters.
class Solar3dCalibrationDialog extends StatefulWidget {
  final String moduleModel;
  final Solar3dDiodeCalibration? existing;

  const Solar3dCalibrationDialog({
    super.key, required this.moduleModel, this.existing,
  });

  @override
  State<Solar3dCalibrationDialog> createState() =>
      _Solar3dCalibrationDialogState();
}

class _Solar3dCalibrationDialogState extends State<Solar3dCalibrationDialog> {
  final formKey = GlobalKey<FormState>();
  late final Map<String, String> fields;
  late String source;
  String? error;

  @override
  void initState() {
    super.initState();
    final old = widget.existing;
    source = old?.source ?? '';
    fields = {
      'cells': old?.seriesCells.toString() ?? '',
      'il': old?.ilRefA.toString() ?? '',
      'io': old?.ioRefA.toString() ?? '',
      'rs': old?.rsOhm.toString() ?? '',
      'rsh': old?.rshRefOhm.toString() ?? '',
      'a': old?.aRefV.toString() ?? '',
      'alpha': old?.alphaScAperC.toString() ?? '',
      'eg': old?.bandGapEv.toString() ?? '1.121',
    };
  }

  double? parse(String text) =>
      double.tryParse(text.trim().replaceAll(',', '.'));

  Widget field(String key, String label, {bool whole = false}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 9),
        child: TextFormField(
          key: ValueKey('electrical-$key'),
          initialValue: fields[key],
          decoration: InputDecoration(labelText: label,
              border: const OutlineInputBorder(), isDense: true),
          keyboardType: TextInputType.text,
          onChanged: (v) => fields[key] = v,
          validator: (value) {
            if (whole) {
              final n = int.tryParse((value ?? '').trim());
              return n == null || n <= 0 ? 'Inteiro positivo obrigatório' : null;
            }
            final v = parse(value ?? '');
            return v == null || !v.isFinite
                ? 'Informe número físico válido' : null;
          },
        ),
      );

  void submit() {
    if (!formKey.currentState!.validate()) return;
    try {
      final c = Solar3dDiodeCalibration(
        moduleModel: widget.moduleModel,
        source: source.trim(),
        seriesCells: int.parse(fields['cells']!.trim()),
        ilRefA: parse(fields['il']!)!,
        ioRefA: parse(fields['io']!)!,
        rsOhm: parse(fields['rs']!)!,
        rshRefOhm: parse(fields['rsh']!)!,
        aRefV: parse(fields['a']!)!,
        alphaScAperC: parse(fields['alpha']!)!,
        bandGapEv: parse(fields['eg']!)!,
      );
      c.validate();
      Navigator.of(context).pop(c);
    } on FormatException catch (e) {
      setState(() => error = e.message);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    scrollable: true,
    title: const Text('Parâmetros físicos I–V (laboratório)'),
    content: SizedBox(
      width: 360,
      child: Form(key: formKey, child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(widget.moduleModel,
              style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Cadastre apenas coeficientes De Soto/CEC ajustados '
              'com origem rastreável. Voc, Isc, Vmp e Imp do datasheet '
              'não bastam para descobrir estes parâmetros. '
              'O preenchimento não garante validação com ensaios.'),
          const SizedBox(height: 12),
          TextFormField(
            key: const ValueKey('electrical-source'),
            initialValue: source,
            decoration: const InputDecoration(
              labelText: 'Fonte / arquivo / versão de calibração',
              border: OutlineInputBorder(), isDense: true,
            ),
            onChanged: (v) => source = v,
            validator: (v) => (v ?? '').trim().isEmpty
                ? 'Informe a origem dos parâmetros' : null,
          ),
          const SizedBox(height: 12),
          field('cells', 'Células efetivas em série (Ns)', whole: true),
          field('il', 'IL_ref · corrente fotogerada (A)'),
          field('io', 'I0_ref · saturação (A, ex.: 1e-10)'),
          field('rs', 'Rs · resistência série (Ω)'),
          field('rsh', 'Rsh_ref · resistência paralela (Ω)'),
          field('a', 'a_ref = n Ns Vth (V)'),
          field('alpha', 'α_Isc · coeficiente (A/°C)'),
          field('eg', 'Eg_ref · band gap (eV)'),
          if (error != null)
            Text(error!, style: TextStyle(
                color: Theme.of(context).colorScheme.error)),
        ],
      )),
    ),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar')),
      FilledButton(onPressed: submit,
          child: const Text('Salvar parâmetros de estudo')),
    ],
  );
}
