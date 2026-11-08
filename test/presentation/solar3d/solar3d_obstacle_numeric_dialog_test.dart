import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greencity_os/domain/solar3d/solar3d_geometric_shading.dart';
import 'package:greencity_os/domain/solar3d/solar3d_obstacle_height.dart';
import 'package:greencity_os/presentation/widgets/photovoltaic/solar3d_obstacle_numeric_dialog.dart';

void main() {
  const obstacle = Solar3dObject(
    id: 'box', kind: Solar3dObjectKind.obstacle,
    center: Solar3dVector(0, 1.5, 0), width: 2, depth: 2, height: 3,
  );

  testWidgets('form edits obstacle dimensions with a typed value',
      (tester) async {
    Solar3dObject? result;
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: Builder(
      builder: (context) => ElevatedButton(
        onPressed: () async {
          result = await showDialog<Solar3dObject>(
            context: context,
            builder: (_) => const Solar3dObstacleNumericDialog(
              obstacle: obstacle,
            ),
          );
        },
        child: const Text('Abrir formulário'),
      ),
    ))));
    await tester.tap(find.text('Abrir formulário'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('obstacle-width')), '4,50');
    await tester.enterText(
      find.byKey(const ValueKey('obstacle-height')), '6');
    await tester.enterText(
      find.byKey(const ValueKey('obstacle-base')), '0');
    await tester.tap(find.text('Aplicar medidas'));
    await tester.pumpAndSettle();
    expect(result, isNotNull);
    expect(result!.width, 4.5);
    expect(result!.height, 6);
    expect(result!.center.y, 3);
    expect(Solar3dObstacleHeight.baseOf(result!), 0);
  });

  testWidgets('invalid obstacle measurements stay in form',
      (tester) async {
    Solar3dObject? result;
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: Builder(
      builder: (context) => ElevatedButton(
        onPressed: () async {
          result = await showDialog<Solar3dObject>(
            context: context,
            builder: (_) => const Solar3dObstacleNumericDialog(
              obstacle: obstacle,
            ),
          );
        },
        child: const Text('Abrir formulário'),
      ),
    ))));
    await tester.tap(find.text('Abrir formulário'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('obstacle-height')), '0');
    await tester.tap(find.text('Aplicar medidas'));
    await tester.pumpAndSettle();
    expect(find.text('Editar dados do obstáculo'), findsOneWidget);
    expect(result, isNull);
  });

  testWidgets('cancel new obstacle does not return any scene object',
      (tester) async {
    Solar3dObject? result;
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: Builder(
      builder: (context) => ElevatedButton(
        onPressed: () async {
          result = await showDialog<Solar3dObject>(
            context: context,
            builder: (_) => const Solar3dObstacleNumericDialog(
              obstacle: obstacle, creating: true,
            ),
          );
        },
        child: const Text('Novo'),
      ),
    ))));
    await tester.tap(find.text('Novo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(result, isNull);
  });
}
