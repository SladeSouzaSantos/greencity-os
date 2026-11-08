import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greencity_os/presentation/widgets/photovoltaic/solar3d_touch_surface.dart';

void main() {
  testWidgets('vertical drag belongs to 3D, not its parent ListView',
      (tester) async {
    final controller = ScrollController();
    var moved = 0;
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: ListView(
      controller: controller,
      children: [
        const SizedBox(height: 48),
        SizedBox(height: 280, child: Solar3dTouchSurface(
          onSingleStart: (_) {},
          onSingleMove: (_) => moved++,
          onInteractionEnd: () {},
          child: const ColoredBox(color: Colors.blue),
        )),
        const SizedBox(height: 1800),
      ],
    ))));
    final center = tester.getCenter(find.byType(Solar3dTouchSurface));
    final finger = await tester.startGesture(center, pointer: 1);
    await finger.moveBy(const Offset(0, -130));
    await tester.pump();
    expect(moved, greaterThan(0));
    expect(controller.offset, 0);
    await finger.up();
  });

  testWidgets('second finger cancels movement until all pointers are lifted',
      (tester) async {
    var starts = 0;
    var moves = 0;
    var ends = 0;
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: SizedBox(
      height: 300, width: 350,
      child: Solar3dTouchSurface(
        onSingleStart: (_) => starts++,
        onSingleMove: (_) => moves++,
        onInteractionEnd: () => ends++,
        child: const ColoredBox(color: Colors.black),
      ),
    ))));
    final center = tester.getCenter(find.byType(Solar3dTouchSurface));
    final first = await tester.startGesture(
        center - const Offset(40, 0), pointer: 1);
    await first.moveBy(const Offset(14, 0));
    expect(starts, 1);
    expect(moves, 1);
    final second = await tester.startGesture(
        center + const Offset(40, 0), pointer: 2);
    expect(ends, 1);
    await second.moveBy(const Offset(20, 10));
    await second.up();
    await first.moveBy(const Offset(50, 0));
    expect(moves, 1);
    await first.up();
    expect(ends, 1);
    final fresh = await tester.startGesture(center, pointer: 3);
    await fresh.moveBy(const Offset(10, 0));
    expect(starts, 2);
    expect(moves, 2);
    await fresh.up();
    expect(ends, 2);
  });

  testWidgets('blank tap is still delivered; controller decides selection',
      (tester) async {
    Offset? touched;
    await tester.pumpWidget(MaterialApp(home: Scaffold(
      body: SizedBox.expand(
        child: Solar3dTouchSurface(
          onSingleStart: (at) => touched = at,
          onSingleMove: (_) {},
          onInteractionEnd: () {},
          child: const ColoredBox(color: Colors.black),
        ),
      ),
    )));
    await tester.tapAt(const Offset(80, 80));
    expect(touched, const Offset(80, 80));
  });
}
