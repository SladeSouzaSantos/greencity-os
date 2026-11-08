import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greencity_os/presentation/widgets/photovoltaic/solar3d_touch_surface.dart';

void main() {
  testWidgets('vertical swipe is captured by 3D, not its parent ListView',
      (tester) async {
    final scroll = ScrollController();
    var moved = 0;
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: ListView(
      controller: scroll,
      children: [
        const SizedBox(height: 48),
        SizedBox(height: 280, child: Solar3dTouchSurface(
          onSingleStart: (_) {},
          onSingleMove: (_) => moved++,
          onMultiStart: () {},
          onMultiUpdate: (_, __, ___, ____) {},
          onInteractionEnd: () {},
          child: const ColoredBox(color: Colors.blue),
        )),
        const SizedBox(height: 1800),
      ],
    ))));
    final start = tester.getCenter(find.byType(Solar3dTouchSurface));
    final finger = await tester.startGesture(start, pointer: 1);
    await finger.moveBy(const Offset(0, -130));
    await tester.pump();
    expect(moved, greaterThan(0));
    expect(scroll.offset, 0);
    await finger.up();
    scroll.dispose();
  });

  testWidgets('one finger selects/orbits; two fingers pinch, pan and twist',
      (tester) async {
    final singleMoves = <Offset>[];
    final multi = <(Offset, Offset, double, double)>[];
    var started = 0;
    var reset = 0;
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: SizedBox(
      width: 360,
      height: 320,
      child: Solar3dTouchSurface(
        onSingleStart: (_) => started++,
        onSingleMove: singleMoves.add,
        onMultiStart: () {},
        onMultiUpdate: (focal, pan, ratio, twist) =>
            multi.add((focal, pan, ratio, twist)),
        onInteractionEnd: () => reset++,
        child: const ColoredBox(color: Colors.black),
      ),
    ))));
    final center = tester.getCenter(find.byType(Solar3dTouchSurface));
    final one = await tester.startGesture(
        center + const Offset(-35, 0), pointer: 11);
    await one.moveBy(const Offset(0, -15));
    await tester.pump();
    expect(started, 1);
    expect(singleMoves, isNotEmpty);
    final two = await tester.startGesture(
        center + const Offset(35, 0), pointer: 12);
    final n = singleMoves.length;
    await two.moveBy(const Offset(45, 20));
    await tester.pump();
    expect(multi, isNotEmpty);
    expect(multi.any((e) => e.$3 > 1.01), true); // pinch outward
    expect(multi.any((e) => e.$2.dx.abs() > 1), true); // pan
    expect(multi.any((e) => e.$4.abs() > 0.01), true); // twist
    await two.up();
    await one.moveBy(const Offset(10, 0));
    await tester.pump();
    expect(singleMoves.length, n); // suppress one-finger post-pinch jump
    await one.up();
    expect(reset, 1);
  });
}
