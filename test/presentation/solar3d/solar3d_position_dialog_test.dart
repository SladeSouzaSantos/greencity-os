import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greencity_os/domain/solar3d/solar3d_geometric_shading.dart';
import 'package:greencity_os/domain/solar3d/solar3d_panel_height.dart';
import 'package:greencity_os/presentation/widgets/photovoltaic/solar3d_position_dialog.dart';

void main() {
  const module = Solar3dObject(
    id: 'inv/1/1', kind: Solar3dObjectKind.panel,
    center: Solar3dVector(1, 1, 1),
    width: 1.2, depth: 2, height: .045,
    tiltDegrees: 20, mpptIndex: 1,
  );

  testWidgets('changing lower-edge height closes dialog and preserves panel',
      (tester) async {
    Solar3dObject? result;
    await tester.pumpWidget(MaterialApp(home: Scaffold(
      body: Builder(builder: (context) => TextButton(
        onPressed: () async {
          result = await showDialog<Solar3dObject>(
            context: context,
            builder: (_) => const Solar3dPositionDialog(object: module),
          );
        },
        child: const Text('Editar placa'),
      )),
    )));
    await tester.tap(find.text('Editar placa'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('solar3d-position-lower')), '5,50');
    await tester.tap(find.text('Aplicar'));
    await tester.pumpAndSettle();
    expect(result, isNotNull);
    expect(Solar3dPanelHeight.lowerEdgeOf(result!), closeTo(5.5, 1e-6));
    expect(result!.center.x, 1);
    expect(result!.center.z, 1);
    expect(result!.mpptIndex, 1);
  });

  testWidgets('invalid value keeps dialog open and cancel changes nothing',
      (tester) async {
    Solar3dObject? result;
    await tester.pumpWidget(MaterialApp(home: Scaffold(
      body: Builder(builder: (context) => TextButton(
        onPressed: () async {
          result = await showDialog<Solar3dObject>(
            context: context,
            builder: (_) => const Solar3dPositionDialog(object: module),
          );
        },
        child: const Text('Editar placa'),
      )),
    )));
    await tester.tap(find.text('Editar placa'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('solar3d-position-lower')), '-1');
    await tester.tap(find.text('Aplicar'));
    await tester.pumpAndSettle();
    expect(find.text('Posicionar placa (metros)'), findsOneWidget);
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(result, isNull);
  });
}
