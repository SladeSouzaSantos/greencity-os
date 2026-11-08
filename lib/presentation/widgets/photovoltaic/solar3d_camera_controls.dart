import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Camera controls intentionally separated from object drag gestures.
///
/// The geographic buttons set the horizontal orbit heading; the elevation
/// buttons change the SECOND axis (pitch), so this is a true 3D view.
/// No camera action changes the solar scene, object coordinates or MPPTs.
class Solar3dCameraControls extends StatelessWidget {
  final double yaw;
  final double pitch;
  final double zoom;
  final ValueChanged<double> onHeading;
  final ValueChanged<double> onPitchStep;
  final ValueChanged<double> onYawStep;
  final ValueChanged<Offset> onPanStep;
  final VoidCallback onResetPan;
  final VoidCallback onDefaultPerspective;
  final VoidCallback onTopView;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;

  const Solar3dCameraControls({
    super.key,
    required this.yaw,
    required this.pitch,
    required this.zoom,
    required this.onHeading,
    required this.onPitchStep,
    required this.onYawStep,
    required this.onPanStep,
    required this.onResetPan,
    required this.onDefaultPerspective,
    required this.onTopView,
    required this.onZoomIn,
    required this.onZoomOut,
  });

  /// Preset rotation on the horizontal (azimuth) axis. For the current
  /// projection, east-up is yaw=-pi/2 and west-up is yaw=+pi/2.
  static double heading(String cardinal) => switch (cardinal) {
    'N' => 0,
    'S' => math.pi,
    'L' => -math.pi / 2,
    'O' => math.pi / 2,
    _ => throw ArgumentError.value(cardinal, 'cardinal'),
  };

  Widget _direction(String cardinal, String tooltip) => SizedBox(
    width: 39, height: 39,
    child: IconButton(
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
      tooltip: tooltip,
      onPressed: () => onHeading(heading(cardinal)),
      icon: Text(cardinal, style: const TextStyle(
        fontWeight: FontWeight.w800, fontSize: 14,
      )),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Stack(children: [
      Positioned(
        top: 8, right: 8,
        child: Material(
          color: colors.surface.withValues(alpha: .95),
          elevation: 3, borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Text('CÂMERA 3D', style: TextStyle(
                  fontSize: 10, fontWeight: FontWeight.bold)),
              Row(mainAxisSize: MainAxisSize.min, children: [
                _direction('N', 'Orientar vista para Norte'),
                SizedBox(width: 39, height: 39, child: IconButton(
                  tooltip: 'Vista superior N para cima',
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.map_outlined, size: 21),
                  onPressed: onTopView,
                )),
              ]),
              Row(mainAxisSize: MainAxisSize.min, children: [
                _direction('O', 'Orientar vista para Oeste'),
                SizedBox(width: 40, height: 39, child: IconButton(
                  tooltip: 'Restaurar câmera 3D em perspectiva',
                  padding: EdgeInsets.zero,
                  onPressed: onDefaultPerspective,
                  icon: const Icon(Icons.view_in_ar_outlined, size: 22),
                )),
                _direction('L', 'Orientar vista para Leste'),
              ]),
              _direction('S', 'Orientar vista para Sul'),
              Row(mainAxisSize: MainAxisSize.min, children: [
                SizedBox(width: 56, height: 35, child: IconButton(
                  tooltip: 'Elevar câmera para vista superior',
                  icon: const Icon(Icons.keyboard_arrow_up),
                  onPressed: () => onPitchStep(.16),
                )),
                SizedBox(width: 56, height: 35, child: IconButton(
                  tooltip: 'Baixar câmera para perspectiva lateral',
                  icon: const Icon(Icons.keyboard_arrow_down),
                  onPressed: () => onPitchStep(-.16),
                )),
              ]),
              Row(mainAxisSize: MainAxisSize.min, children: [
                SizedBox(width: 56, height: 35, child: IconButton(
                  tooltip: 'Girar câmera para esquerda',
                  icon: const Icon(Icons.rotate_left),
                  onPressed: () => onYawStep(-.18),
                )),
                SizedBox(width: 56, height: 35, child: IconButton(
                  tooltip: 'Girar câmera para direita',
                  icon: const Icon(Icons.rotate_right),
                  onPressed: () => onYawStep(.18),
                )),
              ]),
            ]),
          ),
        ),
      ),
      Positioned(
        right: 8, bottom: 8,
        child: Material(
          color: colors.surface.withValues(alpha: .95),
          elevation: 3, borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Text('MOVER VISTA', style: TextStyle(
                  fontSize: 10, fontWeight: FontWeight.bold)),
              SizedBox(width: 40, height: 37, child: IconButton(
                tooltip: 'Deslocar vista para cima',
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.arrow_upward),
                onPressed: () => onPanStep(const Offset(0, 32)),
              )),
              Row(mainAxisSize: MainAxisSize.min, children: [
                SizedBox(width: 40, height: 37, child: IconButton(
                  tooltip: 'Deslocar vista para esquerda',
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => onPanStep(const Offset(-32, 0)),
                )),
                SizedBox(width: 40, height: 37, child: IconButton(
                  tooltip: 'Centralizar deslocamento da vista',
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.filter_center_focus, size: 19),
                  onPressed: onResetPan,
                )),
                SizedBox(width: 40, height: 37, child: IconButton(
                  tooltip: 'Deslocar vista para direita',
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.arrow_forward),
                  onPressed: () => onPanStep(const Offset(32, 0)),
                )),
              ]),
              SizedBox(width: 40, height: 37, child: IconButton(
                tooltip: 'Deslocar vista para baixo',
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.arrow_downward),
                onPressed: () => onPanStep(const Offset(0, -32)),
              )),
            ]),
          ),
        ),
      ),
      Positioned(
        left: 8, bottom: 8,
        child: Material(
          color: colors.surface.withValues(alpha: .95),
          elevation: 3, borderRadius: BorderRadius.circular(12),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            IconButton(
              tooltip: 'Aproximar cena',
              onPressed: onZoomIn,
              icon: const Icon(Icons.add, size: 27),
            ),
            const Divider(height: 1, indent: 7, endIndent: 7),
            IconButton(
              tooltip: 'Afastar cena',
              onPressed: onZoomOut,
              icon: const Icon(Icons.remove, size: 27),
            ),
          ]),
        ),
      ),
    ]);
  }
}
