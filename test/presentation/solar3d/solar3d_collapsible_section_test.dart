import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greencity_os/presentation/widgets/photovoltaic/solar3d_collapsible_section.dart';

void main() {
  testWidgets('collapsed group safely creates and destroys a Scrollable',
      (tester) async {
    var selected = 1;
    Widget screen() => MaterialApp(home: Scaffold(
      body: ListView(children: [
        Solar3dCollapsibleSection(
          title: 'Calcular perdas ópticas',
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: const SizedBox(width: 1100, height: 100,
                  child: Text('Resultados')),
            ),
          ],
        ),
        Solar3dCollapsibleSection(
          title: 'Objetos e MPPTs',
          initiallyExpanded: true,
          children: [
            DropdownButton<int>(
              value: selected,
              items: const [
                DropdownMenuItem(value: 1, child: Text('MPPT 1')),
                DropdownMenuItem(value: 2, child: Text('MPPT 2')),
              ],
              onChanged: (value) => selected = value!,
            ),
          ],
        ),
      ]),
    ));

    await tester.pumpWidget(screen());
    await tester.tap(find.text('Calcular perdas ópticas'));
    await tester.pumpAndSettle();
    expect(find.text('Resultados'), findsOneWidget);
    await tester.tap(find.text('MPPT 1'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('MPPT 2').last);
    await tester.pumpAndSettle();
    await tester.pumpWidget(screen());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Calcular perdas ópticas'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('collapsed analysis section can be expanded and hidden',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(
      body: SingleChildScrollView(child: Solar3dCollapsibleSection(
        title: 'Resultados',
        children: [Text('Detalhes de sombreamento')],
      )),
    )));
    expect(find.text('Resultados'), findsOneWidget);
    expect(find.text('Detalhes de sombreamento'), findsNothing);
    await tester.tap(find.text('Resultados'));
    await tester.pumpAndSettle();
    expect(find.text('Detalhes de sombreamento'), findsOneWidget);
    await tester.tap(find.text('Resultados'));
    await tester.pumpAndSettle();
    expect(find.text('Detalhes de sombreamento'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
