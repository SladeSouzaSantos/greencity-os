import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greencity_os/presentation/widgets/photovoltaic/solar3d_collapsible_section.dart';

void main() {
  testWidgets('collapsed analysis section can be expanded and hidden',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(
      body: SingleChildScrollView(child: Solar3dCollapsibleSection(
        title: 'Resultados',
        children: [Text('Detalhes de sombreamento')],
      )),
    )));
    expect(find.text('Resultados'), findsOneWidget);
    // Children kept alive, but not visible before expanding.
    expect(find.text('Detalhes de sombreamento', skipOffstage: false),
        findsOneWidget);
    await tester.tap(find.text('Resultados'));
    await tester.pumpAndSettle();
    expect(find.text('Detalhes de sombreamento'), findsOneWidget);
    await tester.tap(find.text('Resultados'));
    await tester.pumpAndSettle();
    expect(find.text('Resultados'), findsOneWidget);
  });
}
