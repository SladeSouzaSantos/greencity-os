import 'package:flutter/material.dart';

/// Exibe falhas do catálogo acima do bottom sheet de edição/importação.
/// Um SnackBar do Scaffold fica encoberto pela rota modal.
class EquipmentErrorDialog {
  static void show(BuildContext context, String message) {
    if (!context.mounted) return;
    showDialog<void>(
      context: context,
      useRootNavigator: true,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.error_outline, color: Colors.red),
        title: const Text(
          'Não foi possível concluir a operação',
          style: TextStyle(color: Colors.red),
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 550),
          child: SingleChildScrollView(
            child: SelectableText(message),
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }
}
