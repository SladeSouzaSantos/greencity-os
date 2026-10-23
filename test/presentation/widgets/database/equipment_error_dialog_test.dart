import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greencity_os/presentation/widgets/database/equipment_error_dialog.dart';

void main() {
  testWidgets('mensagem de erro fica sobre formulário modal e preserva a tela',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (pageContext) => ElevatedButton(
            onPressed: () {
              showModalBottomSheet<void>(
                context: pageContext,
                isScrollControlled: true,
                builder: (sheetContext) => SizedBox(
                  height: 450,
                  child: Center(
                    child: ElevatedButton(
                      onPressed: () => EquipmentErrorDialog.show(
                        sheetContext,
                        'Falha na consulta ao banco Isar: RangeError (length)',
                      ),
                      child: const Text('Importar PDF'),
                    ),
                  ),
                ),
              );
            },
            child: const Text('Abrir equipamento'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('Abrir equipamento'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Importar PDF'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text('Não foi possível concluir a operação'), findsOneWidget);
    expect(find.textContaining('RangeError (length)'), findsOneWidget);
    expect(find.byType(SelectableText), findsOneWidget);

    await tester.tap(find.text('Fechar'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('Importar PDF'), findsOneWidget,
        reason: 'O erro não pode fechar o formulário com dados do usuário.');
  });
}
