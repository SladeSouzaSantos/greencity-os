import 'package:flutter/material.dart';

import '../../../domain/solar3d/solar3d_geometric_shading.dart';
import '../../../domain/solar3d/solar3d_obstacle_height.dart';
import '../../../domain/solar3d/solar3d_obstacle_numeric_input.dart';

/// A mobile-friendly, scrollable form with editable numeric measures.
/// It returns a complete validated object only when the user confirms.
class Solar3dObstacleNumericDialog extends StatefulWidget {
  final Solar3dObject obstacle;
  final bool creating;

  const Solar3dObstacleNumericDialog({
    super.key,
    required this.obstacle,
    this.creating = false,
  });

  @override
  State<Solar3dObstacleNumericDialog> createState() =>
      _Solar3dObstacleNumericDialogState();
}

class _Solar3dObstacleNumericDialogState
    extends State<Solar3dObstacleNumericDialog> {
  final _form = GlobalKey<FormState>();
  late final Map<String, TextEditingController> _fields;
  String? _combinedError;

  @override
  void initState() {
    super.initState();
    final o = widget.obstacle;
    String format(double value) => value.toStringAsFixed(3);
    _fields = {
      'x': TextEditingController(text: format(o.center.x)),
      'z': TextEditingController(text: format(o.center.z)),
      'base': TextEditingController(
          text: format(Solar3dObstacleHeight.baseOf(o))),
      'width': TextEditingController(text: format(o.width)),
      'depth': TextEditingController(text: format(o.depth)),
      'height': TextEditingController(text: format(o.height)),
      'azimuth': TextEditingController(text: format(o.azimuthDegrees)),
    };
  }

  @override
  void dispose() {
    for (final field in _fields.values) {
      field.dispose();
    }
    super.dispose();
  }

  Widget _number(
    String key,
    String label, {
    double min = 0,
    double max = 1000,
    bool positive = false,
    bool signed = false,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: TextFormField(
      key: ValueKey('obstacle-$key'),
      controller: _fields[key],
      keyboardType: TextInputType.numberWithOptions(
        decimal: true, signed: signed),
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
      validator: (value) {
        try {
          Solar3dObstacleNumericInput.parseNumber(
            value ?? '', label,
            min: min, max: max, strictlyPositive: positive,
          );
          return null;
        } on FormatException catch (error) {
          return error.message.toString();
        }
      },
      onChanged: (_) {
        if (_combinedError != null) {
          setState(() => _combinedError = null);
        }
      },
    ),
  );

  void _submit() {
    if (!_form.currentState!.validate()) return;
    try {
      final result = Solar3dObstacleNumericInput.apply(
        obstacle: widget.obstacle,
        east: _fields['x']!.text,
        north: _fields['z']!.text,
        base: _fields['base']!.text,
        width: _fields['width']!.text,
        depth: _fields['depth']!.text,
        height: _fields['height']!.text,
        azimuth: _fields['azimuth']!.text,
      );
      Navigator.of(context).pop(result);
    } on FormatException catch (error) {
      setState(() => _combinedError = error.message.toString());
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    scrollable: true,
    title: Text(widget.creating
        ? 'Adicionar obstáculo — medidas'
        : 'Editar dados do obstáculo'),
    content: SizedBox(
      width: 360,
      child: Form(
        key: _form,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Informe valores em metros. A altura Y representa '
              'a BASE do obstáculo; 0 m = apoiado no solo. '
              'O centro 3D será calculado automaticamente.'),
          const SizedBox(height: 12),
          _number('x', 'Posição X · Leste/Oeste (m)',
              min: -500, max: 500, signed: true),
          _number('z', 'Posição Z · Norte/Sul (m)',
              min: -500, max: 500, signed: true),
          _number('base', 'Altura da BASE ao solo (m)', max: 500),
          _number('width', 'Largura (m)', positive: true),
          _number('depth', 'Profundidade (m)', positive: true),
          _number('height', 'Altura TOTAL (m)', positive: true),
          _number('azimuth', 'Rotação do obstáculo · azimute (°)',
              max: 360),
          if (_combinedError != null)
            Text(_combinedError!, style: TextStyle(
              color: Theme.of(context).colorScheme.error,
            )),
        ]),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Cancelar'),
      ),
      FilledButton.icon(
        onPressed: _submit,
        icon: const Icon(Icons.check),
        label: Text(widget.creating ? 'Adicionar' : 'Aplicar medidas'),
      ),
    ],
  );
}
