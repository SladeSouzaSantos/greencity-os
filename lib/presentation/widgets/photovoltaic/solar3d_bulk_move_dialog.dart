import 'package:flutter/material.dart';

/// Changes the relative position of the whole transient selection.
/// "Same height" means the panel's LOWER EDGE or obstacle's BASE,
/// not a common geometric centre.
class Solar3dBulkMoveRequest {
  final double east, north, height;
  final bool commonHeight;

  const Solar3dBulkMoveRequest({
    required this.east,
    required this.north,
    required this.height,
    required this.commonHeight,
  });
}

class Solar3dBulkMoveDialog extends StatefulWidget {
  final int selectedCount;

  const Solar3dBulkMoveDialog({
    super.key,
    required this.selectedCount,
  });

  @override
  State<Solar3dBulkMoveDialog> createState() =>
      _Solar3dBulkMoveDialogState();
}

class _Solar3dBulkMoveDialogState extends State<Solar3dBulkMoveDialog> {
  final formKey = GlobalKey<FormState>();
  String east = '0';
  String north = '0';
  String height = '0';
  bool commonHeight = false;

  double? number(String? value) =>
      double.tryParse((value ?? '').trim().replaceAll(',', '.'));

  Widget field({
    required String name,
    required String label,
    required String initialValue,
    required ValueChanged<String> onChanged,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 9),
    child: TextFormField(
      key: ValueKey('bulk-$name'),
      initialValue: initialValue,
      onChanged: onChanged,
      keyboardType: const TextInputType.numberWithOptions(
          signed: true, decimal: true),
      decoration: InputDecoration(
        labelText: label, isDense: true,
        border: const OutlineInputBorder(),
      ),
      validator: (value) {
        final parsed = number(value);
        if (parsed == null || !parsed.isFinite) {
          return 'Informe um número válido';
        }
        if (name == 'height' && commonHeight &&
            (parsed < 0 || parsed > 500)) {
          return 'A altura comum deve ficar entre 0 e 500 m';
        }
        return null;
      },
    ),
  );

  void submit() {
    if (!formKey.currentState!.validate()) return;
    Navigator.of(context).pop(Solar3dBulkMoveRequest(
      east: number(east)!,
      north: number(north)!,
      height: number(height)!,
      commonHeight: commonHeight,
    ));
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    scrollable: true,
    title: Text('Mover ${widget.selectedCount} objetos juntos'),
    content: SizedBox(
      width: 340,
      child: Form(
        key: formKey,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Os objetos mantêm suas distâncias relativas '
              'no deslocamento. Não alteramos inversores ou MPPTs.'),
          const SizedBox(height: 12),
          field(name: 'east', label: 'Deslocar X · Leste/Oeste (m)',
              initialValue: east,
              onChanged: (v) => east = v),
          field(name: 'north', label: 'Deslocar Z · Norte/Sul (m)',
              initialValue: north,
              onChanged: (v) => north = v),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Definir a mesma altura para todos'),
            subtitle: const Text('Usa a borda inferior das placas '
                'e a base dos obstáculos'),
            value: commonHeight,
            onChanged: (v) => setState(() {
              commonHeight = v;
              height = '0';
            }),
          ),
          field(
            name: 'height',
            label: commonHeight
                ? 'Altura comum · borda/base (m)'
                : 'Elevar/descer o conjunto · Δ altura (m)',
            initialValue: '0',
            onChanged: (v) => height = v,
          ),
          if (!commonHeight)
            const Text('Um Δ positivo eleva todas as placas e obstáculos; '
                'um Δ negativo abaixa todos, preservando as diferenças '
                'de altura entre eles.'),

        ]),
      ),
    ),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar')),
      FilledButton.icon(
        onPressed: submit,
        icon: const Icon(Icons.open_with),
        label: const Text('Mover seleção'),
      ),
    ],
  );
}
