import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../models/ceiling_object.dart';
import 'ceiling_orbit_painter.dart';

class Pcm3dViewer extends StatelessWidget {
  final List<CeilingObject> objects;
  final double rotationX;
  final double rotationY;
  final double zoomScale;
  final double roomL;
  final double roomW;
  final double fanAngle;
  final bool downlightsOn;
  final bool coveLightOn;
  final bool showFramework;
  final AnimationController fanAnimController;

  final ValueChanged<double> onRotationXChanged;
  final ValueChanged<double> onRotationYChanged;
  final ValueChanged<double> onZoomScaleChanged;
  final VoidCallback onDownlightsToggled;
  final VoidCallback onCoveLightToggled;
  final VoidCallback onFrameworkToggled;
  final Function(double rx, double ry) onSetCameraPreset;

  const Pcm3dViewer({
    super.key,
    required this.objects,
    required this.rotationX,
    required this.rotationY,
    required this.zoomScale,
    required this.roomL,
    required this.roomW,
    required this.fanAngle,
    required this.downlightsOn,
    required this.coveLightOn,
    required this.showFramework,
    required this.fanAnimController,
    required this.onRotationXChanged,
    required this.onRotationYChanged,
    required this.onZoomScaleChanged,
    required this.onDownlightsToggled,
    required this.onCoveLightToggled,
    required this.onFrameworkToggled,
    required this.onSetCameraPreset,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 3D Toolbar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          color: const Color(0xFF131722),
          child: Row(
            children: [
              const Icon(Icons.layers, color: Color(0xFF00FF87), size: 16),
              const SizedBox(width: 6),
              const Text(
                'REAL-TIME 3D SOLID MODEL',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              _flatBtn('TOP', () => onSetCameraPreset(0.0, 0.0)),
              const SizedBox(width: 4),
              _flatBtn('PERSPECTIVE', () => onSetCameraPreset(0.35, 0.5)),
              const SizedBox(width: 4),
              _flatBtn('FRONT', () => onSetCameraPreset(1.57, 0.0)),
            ],
          ),
        ),
        // Interactive 3D Orbit Viewport
        Expanded(
          child: Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  onScaleUpdate: (d) {
                    double newZoom = (zoomScale * d.scale).clamp(0.5, 3.0);
                    double newRotY = rotationY;
                    double newRotX = rotationX;
                    if (d.pointerCount == 1) {
                      newRotY = rotationY - d.focalPointDelta.dx * 0.01;
                      newRotX = (rotationX + d.focalPointDelta.dy * 0.01).clamp(-math.pi / 2, math.pi / 2);
                    }
                    onRotationXChanged(newRotX);
                    onRotationYChanged(newRotY);
                    onZoomScaleChanged(newZoom);
                  },
                  child: Container(
                    color: const Color(0xFF07090E),
                    child: AnimatedBuilder(
                      animation: fanAnimController,
                      builder: (context, _) {
                        return CustomPaint(
                          size: Size.infinite,
                          painter: CeilingOrbitPainter(
                            objects: objects,
                            rotationX: rotationX,
                            rotationY: rotationY,
                            zoomScale: zoomScale,
                            roomL: roomL,
                            roomW: roomW,
                            fanAngle: fanAngle,
                            downlightsOn: downlightsOn,
                            coveLightOn: coveLightOn,
                            showFramework: showFramework,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              // Floating settings toggles
              Positioned(
                top: 8,
                left: 8,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _toggleLightBtn(
                      label: 'Downlights',
                      isOn: downlightsOn,
                      icon: Icons.lightbulb_outline,
                      onTap: onDownlightsToggled,
                    ),
                    const SizedBox(height: 6),
                    _toggleLightBtn(
                      label: 'Cove Light',
                      isOn: coveLightOn,
                      icon: Icons.highlight,
                      onTap: onCoveLightToggled,
                    ),
                    const SizedBox(height: 6),
                    _toggleLightBtn(
                      label: 'Framework',
                      isOn: showFramework,
                      icon: Icons.grid_goldenratio,
                      onTap: onFrameworkToggled,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _toggleLightBtn({
    required String label,
    required bool isOn,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isOn ? const Color(0xEE1E293B) : const Color(0xEE0F172A),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isOn ? const Color(0xFFD4AF37) : Colors.white24,
            width: 1.0,
          ),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isOn ? const Color(0xFFD4AF37) : Colors.white54,
              size: 10,
            ),
            const SizedBox(width: 4),
            Text(
              '$label: ${isOn ? "ON" : "OFF"}',
              style: TextStyle(
                color: isOn ? Colors.white : Colors.white54,
                fontSize: 8,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _flatBtn(String label, VoidCallback tap) {
    return TextButton(
      style: TextButton.styleFrom(
        backgroundColor: Colors.white10,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        minimumSize: Size.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      onPressed: tap,
      child: Text(
        label,
        style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold),
      ),
    );
  }
}
