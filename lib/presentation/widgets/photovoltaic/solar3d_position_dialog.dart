import 'package:flutter/material.dart';

import '../../../domain/solar3d/solar3d_geometric_shading.dart';
import '../../../domain/solar3d/solar3d_obstacle_height.dart';
import '../../../domain/solar3d/solar3d_panel_height.dart';

/// Edit object coordinates with fields owned by the dialog route.
///
/// Avoid disposing text controllers in the caller immediately after
/// showDialog completes. The route can still be mounted during its reverse
/// transition; that teardown previously triggered a Flutter inherited
/// element assertion when editing a panel's lower-edge elevation.
class Solar3dPositionDialog extends StatefulWidget {
  final Solar3dObject object;

  const Solar3dPositionDialog({super.key, required this.object});

  @override
  State<Solar3dPositionDialog> createState() => _Solar3dPositionDialogState();
}

class _Solar3dPositionDialogState extends State<Solar3dPositionDialog> {
  final _formKey = GlobalKey<FormState>();
  late String east;
  late String north;
  late String elevation;
  String? validationError;

  @override
  void initState() {
    super.initState();
    final item = widget.object;
    east = item.center.x.toStringAsFixed(3);
    north = item.center.z.toStringAsFixed(3);
    elevation = (item.kind == Solar3dObjectKind.panel
        ? Solar3dPanelHeight.lowerEdgeOf(item)
        : Solar3dObstacleHeight.baseOf(item)).toStringAsFixed(3);
  }

  static double? _number(String? text) =>
      double.tryParse((text ?? '').trim().replaceAll(',', '.'));

  Widget _field({
    required String keyName,
    required String label,
    required String initial,
    required ValueChanged<String> onChanged,
    required double min,
    required double max,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: TextFormField(
      key: ValueKey('solar3d-position-$keyName'),
      initialValue: initial,
      decoration: InputDecoration(labelText: label,
          border: const OutlineInputBorder(), isDense: true),
      keyboardType: TextInputType.numberWithOptions(
          decimal: true, signed: min < 0),
      onChanged: onChanged,
      validator: (value) {
        final n = _number(value);
        if (n == null || !n.isFinite || n < min || n > max) {
          return 'Valor entre $min e $max m';
        }
        return null;
      },
    ),
  );

  void _apply() {
    if (!_formKey.currentState!.validate()) return;
    final item = widget.object;
    final center = Solar3dVector(
        _number(east)!, item.center.y, _number(north)!);
    final moved = item.copyWith(center: center);
    try {
      final updated = item.kind == Solar3dObjectKind.panel
          ? Solar3dPanelHeight.withLowerEdge(moved, _number(elevation)!)
          : Solar3dObstacleHeight.withBase(moved, _number(elevation)!);
      updated.validate();
      Navigator.of(context).pop(updated);
    } on FormatException catch (error) {
      setState(() => validationError = error.message.toString());
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    scrollable: true,
    title: Text(widget.object.kind == Solar3dObjectKind.panel
        ? 'Posicionar placa (metros)' : 'Posicionar obstáculo (metros)'),
    content: SizedBox(
      width: 340,
      child: Form(
        key: _formKey,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          _field(keyName: 'east', label: 'X · Leste (+) / Oeste (−)',
            initial: east, onChanged: (value) => east = value,
            min: -500, max: 500),
          _field(keyName: 'north', label: 'Z · Norte (+) / Sul (−)',
            initial: north, onChanged: (value) => north = value,
            min: -500, max: 500),
          _field(keyName: 'lower', label:
              widget.object.kind == Solar3dObjectKind.panel
                  ? 'Altura da borda inferior ao solo (m)'
                  : 'Y · altura da BASE ao solo (m)',
            initial: elevation,
            onChanged: (value) => elevation = value,
            min: 0, max: 500),
          if (validationError != null)
            Text(validationError!, style: TextStyle(
                color: Theme.of(context).colorScheme.error)),
        ]),
      ),
    ),
    actions: [
      TextButton(onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar')),
      FilledButton(onPressed: _apply, child: const Text('Aplicar')),
    ],
  );
}
