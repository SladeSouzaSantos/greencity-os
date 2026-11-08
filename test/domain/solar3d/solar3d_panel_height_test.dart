import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:greencity_os/domain/solar3d/solar3d_geometric_shading.dart';
import 'package:greencity_os/domain/solar3d/solar3d_panel_height.dart';

void main() {
  test('15 cm da borda inferior com módulo 2 m e 20 graus', () {
    final center = Solar3dPanelHeight.centerFromLowerEdge(
      lowerEdgeMeters: .15, depthMeters: 2, tiltDegrees: 20);
    final expected = .15 + math.sin(20 * math.pi / 180) +
        .045 / 2 * math.cos(20 * math.pi / 180);
    expect(center, closeTo(expected, 1e-12));
    final panel = Solar3dObject(
      id: 'sys/1/1', kind: Solar3dObjectKind.panel,
      center: Solar3dVector(0, center, 0),
      width: 1, depth: 2, height: .045,
      tiltDegrees: 20, mpptIndex: 1);
    expect(Solar3dPanelHeight.lowerEdgeOf(panel), closeTo(.15, 1e-12));
    final changed = Solar3dPanelHeight.withLowerEdge(
      panel, .15, tiltDegrees: 40);
    expect(Solar3dPanelHeight.lowerEdgeOf(changed), closeTo(.15, 1e-12));
    expect(changed.tiltDegrees, 40);
    expect(changed.center.y, greaterThan(panel.center.y));
  });

  test('0 cm é exatamente solo; inclinação zero usa espessura', () {
    final panel = Solar3dObject(
      id: 'sys/1/1', kind: Solar3dObjectKind.panel,
      center: Solar3dVector(0, 1, 0),
      width: 1, depth: 2, height: .045,
      tiltDegrees: 0, mpptIndex: 1);
    final grounded = Solar3dPanelHeight.withLowerEdge(panel, 0);
    expect(grounded.center.y, closeTo(.045 / 2, 1e-12));
    expect(Solar3dPanelHeight.lowerEdgeOf(grounded), closeTo(0, 1e-12));
  });

  test('borda nominal no limite pode exceder altitude máxima do centro', () {
    expect(
      () => Solar3dPanelHeight.centerFromLowerEdge(
        lowerEdgeMeters: 500, depthMeters: 2, tiltDegrees: 20),
      throwsFormatException,
    );
    expect(
      Solar3dPanelHeight.centerFromLowerEdge(
        lowerEdgeMeters: 499, depthMeters: 1, tiltDegrees: 0),
      greaterThan(499),
    );
  });

  test('valor negativo rejeitado e altura de cena legada não é reinterpretada', () {
    expect(() => Solar3dPanelHeight.centerFromLowerEdge(
      lowerEdgeMeters: -.01, depthMeters: 2, tiltDegrees: 20),
      throwsFormatException);
    const old = Solar3dObject(
      id: 'old/1/1', kind: Solar3dObjectKind.panel,
      center: Solar3dVector(0, .15, 0),
      width: 1, depth: 2, height: .045,
      tiltDegrees: 20, mpptIndex: 1);
    // Original 0.15 m was the centre; do not silently migrate!
    expect(old.center.y, .15);
    expect(Solar3dPanelHeight.lowerEdgeOf(old), lessThan(0));
    final repaired = Solar3dPanelHeight.withLowerEdge(old, .15);
    expect(Solar3dPanelHeight.lowerEdgeOf(repaired), closeTo(.15, 1e-12));
  });
}
