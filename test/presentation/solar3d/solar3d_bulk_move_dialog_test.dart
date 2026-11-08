import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greencity_os/presentation/widgets/photovoltaic/solar3d_bulk_move_dialog.dart';

void main() {
  testWidgets('deslocamento X/Z/altura é digitado e confirmado',
      (tester) async {
    Solar3dBulkMoveRequest? value;
    await tester.pumpWidget(MaterialApp(home: Scaffold(
      body: Builder(builder: (context) => TextButton(
        onPressed: () async => value =
            await showDialog<Solar3dBulkMoveRequest>(
          context: context,
          builder: (_) => const Solar3dBulkMoveDialog(selectedCount: 3),
        ),
        child: const Text('Abrir'),
      )),
    )));
    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('bulk-east')), '2,5');
    await tester.enterText(find.byKey(const ValueKey('bulk-north')), '-1');
    await tester.enterText(find.byKey(const ValueKey('bulk-height')), '0,5');
    await tester.tap(find.text('Mover seleção'));
    await tester.pumpAndSettle();
    expect(value, isNotNull);
    expect(value!.east, 2.5);
    expect(value!.north, -1);
    expect(value!.height, .5);
    expect(value!.commonHeight, false);
  });

  testWidgets('altura comum é um valor absoluto e não um delta',
      (tester) async {
    Solar3dBulkMoveRequest? value;
    await tester.pumpWidget(MaterialApp(home: Scaffold(
      body: Builder(builder: (context) => TextButton(
        onPressed: () async => value =
            await showDialog<Solar3dBulkMoveRequest>(
          context: context,
          builder: (_) => const Solar3dBulkMoveDialog(selectedCount: 2),
        ),
        child: const Text('Abrir'),
      )),
    )));
    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('bulk-height')), '5,5');
    await tester.tap(find.text('Mover seleção'));
    await tester.pumpAndSettle();
    expect(value!.commonHeight, true);
    expect(value!.height, 5.5);
  });
}
