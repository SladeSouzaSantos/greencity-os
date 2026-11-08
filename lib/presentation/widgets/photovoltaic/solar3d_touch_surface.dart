import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// The 3D canvas owns its gestures instead of allowing a parent ListView
/// to steal a vertical drag. Touching the canvas moves OBJECTS ONLY:
/// the camera is operated through the separate on-screen controls.
///
/// A second finger cancels the object drag. All fingers must lift before
/// another object can be selected, preventing accidental multitouch moves.
class Solar3dTouchSurface extends StatefulWidget {
  final Widget child;
  final ValueChanged<Offset> onSingleStart;
  final ValueChanged<Offset> onSingleMove;
  final VoidCallback onInteractionEnd;
  final ValueChanged<double>? onMouseScroll;

  const Solar3dTouchSurface({
    super.key,
    required this.child,
    required this.onSingleStart,
    required this.onSingleMove,
    required this.onInteractionEnd,
    this.onMouseScroll,
  });

  @override
  State<Solar3dTouchSurface> createState() => _Solar3dTouchSurfaceState();
}

class _Solar3dTouchSurfaceState extends State<Solar3dTouchSurface> {
  final Set<int> _pointers = {};
  bool _canceledByMultitouch = false;

  void _down(PointerDownEvent event) {
    _pointers.add(event.pointer);
    if (_pointers.length == 1) {
      _canceledByMultitouch = false;
      widget.onSingleStart(event.localPosition);
    } else if (_pointers.length == 2) {
      _canceledByMultitouch = true;
      widget.onInteractionEnd();
    }
  }

  void _move(PointerMoveEvent event) {
    if (_pointers.length == 1 &&
        _pointers.contains(event.pointer) && !_canceledByMultitouch) {
      widget.onSingleMove(event.localPosition);
    }
  }

  void _end(int pointer) {
    if (!_pointers.remove(pointer)) return;
    if (_pointers.isEmpty) {
      if (!_canceledByMultitouch) widget.onInteractionEnd();
      _canceledByMultitouch = false;
    }
  }

  @override
  void dispose() {
    _pointers.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RawGestureDetector(
    behavior: HitTestBehavior.opaque,
    gestures: {
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
