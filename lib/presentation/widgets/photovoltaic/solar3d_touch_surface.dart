import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// Takes ownership of touch pointers INSIDE the 3D canvas, ahead of a
/// surrounding ListView/ScrollView. The rest of the screen still scrolls.
///
/// Single finger: select/drag an object or orbit over empty ground.
/// Two fingers: zoom (pinch), rotate (twist), pan (move both fingers).
/// The first finger left after a pinch does NOT suddenly drag an object.
class Solar3dTouchSurface extends StatefulWidget {
  final Widget child;
  final ValueChanged<Offset> onSingleStart;
  final ValueChanged<Offset> onSingleMove;
  final VoidCallback onMultiStart;
  final void Function(
      Offset focal, Offset pan, double scale, double rotation) onMultiUpdate;
  final VoidCallback onInteractionEnd;
  final ValueChanged<double>? onMouseScroll;

  const Solar3dTouchSurface({
    super.key,
    required this.child,
    required this.onSingleStart,
    required this.onSingleMove,
    required this.onMultiStart,
    required this.onMultiUpdate,
    required this.onInteractionEnd,
    this.onMouseScroll,
  });

  @override
  State<Solar3dTouchSurface> createState() => _Solar3dTouchSurfaceState();
}

class _Solar3dTouchSurfaceState extends State<Solar3dTouchSurface> {
  final Map<int, Offset> _touches = {};
  Offset? _previousFocal;
  double? _previousDistance;
  double? _previousAngle;
  bool _hadMultiTouch = false;

  (Offset, double, double) _pair() {
    final points = _touches.values.take(2).toList();
    final delta = points[1] - points[0];
    return (
      (points[0] + points[1]) / 2,
      delta.distance,
      math.atan2(delta.dy, delta.dx),
    );
  }

  void _rebasePair() {
    if (_touches.length < 2) {
      _previousFocal = null;
      _previousDistance = null;
      _previousAngle = null;
      return;
    }
    final (focal, distance, angle) = _pair();
    _previousFocal = focal;
    _previousDistance = distance;
    _previousAngle = angle;
  }

  void _down(PointerDownEvent event) {
    _touches[event.pointer] = event.localPosition;
    if (_touches.length == 1) {
      _hadMultiTouch = false;
      widget.onSingleStart(event.localPosition);
    } else {
      if (_touches.length == 2) {
        _hadMultiTouch = true;
        widget.onMultiStart();
      }
      _rebasePair();
    }
  }

  void _move(PointerMoveEvent event) {
    if (!_touches.containsKey(event.pointer)) return;
    _touches[event.pointer] = event.localPosition;

    if (_touches.length >= 2) {
      final (focal, distance, angle) = _pair();
      final previousFocal = _previousFocal;
      final previousDistance = _previousDistance;
      final previousAngle = _previousAngle;
      _rebasePair();
      if (previousFocal == null || previousDistance == null ||
          previousAngle == null) {
        return;
      }
      final scale = previousDistance > 1e-3
          ? distance / previousDistance : 1.0;
      var rotation = angle - previousAngle;
      if (rotation > math.pi) {
        rotation -= 2 * math.pi;
      }
      if (rotation < -math.pi) {
        rotation += 2 * math.pi;
      }
      widget.onMultiUpdate(
        focal,
        focal - previousFocal,
        scale.isFinite && scale > 0 ? scale : 1.0,
        rotation.isFinite ? rotation : 0,
      );
    } else if (!_hadMultiTouch) {
      widget.onSingleMove(event.localPosition);
    }
  }

  void _end(int pointer) {
    if (_touches.remove(pointer) == null) return;
    _rebasePair();
    if (_touches.isEmpty) {
      _hadMultiTouch = false;
      widget.onInteractionEnd();
    }
    // With only one remaining finger, wait for all fingers to lift
    // before allowing a fresh object drag/orbit. Prevents jumpy motions.
  }

  @override
  void dispose() {
    _touches.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RawGestureDetector(
    behavior: HitTestBehavior.opaque,
    gestures: {
      // Eagerly win the arena INSIDE this canvas. Otherwise vertical drags
      // are intermittently interpreted as the parent ListView scrolling.
      EagerGestureRecognizer:
          GestureRecognizerFactoryWithHandlers<EagerGestureRecognizer>(
        () => EagerGestureRecognizer(),
        (recognizer) {},
      ),
    },
    child: Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: _down,
      onPointerMove: _move,
      onPointerUp: (event) => _end(event.pointer),
      onPointerCancel: (event) => _end(event.pointer),
      onPointerSignal: (event) {
        if (event is PointerScrollEvent) {
          widget.onMouseScroll?.call(event.scrollDelta.dy);
        }
      },
      child: widget.child,
    ),
  );
}
