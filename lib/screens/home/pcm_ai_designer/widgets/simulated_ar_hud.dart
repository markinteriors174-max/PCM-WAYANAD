import 'package:flutter/material.dart';

class SimulatedArHudOverlay extends StatefulWidget {
  final double scanProgress;
  final String coachingText;
  final bool isLocked;
  final bool depthApiEnabled;

  const SimulatedArHudOverlay({
    super.key,
    this.scanProgress = 0.5,
    this.coachingText = "",
    this.isLocked = false,
    required this.depthApiEnabled,
  });

  @override
  State<SimulatedArHudOverlay> createState() => _SimulatedArHudOverlayState();
}

class _SimulatedArHudOverlayState extends State<SimulatedArHudOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool locked = widget.isLocked;
    final String cText = widget.coachingText.isNotEmpty ? widget.coachingText : (locked ? 'CEILING PLANE MATCHED' : 'PAN CAMERA SLOWLY TO SCAN CEILING PLANE');
    
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final double progress = widget.scanProgress;
        return Container(
          width: double.infinity,
          height: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(
              color: locked ? const Color(0xFF00FF87).withValues(alpha: 0.4) : const Color(0xFFFFD54F).withValues(alpha: 0.4),
              width: 1.5,
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: locked ? const Color(0xFF00FF87) : const Color(0xFFFFD54F),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: locked ? const Color(0xFF00FF87) : const Color(0xFFFFD54F),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            locked ? 'AR ANCHOR: LOCKED' : 'AR STATUS: SCANNING...',
                            style: TextStyle(
                              color: locked ? const Color(0xFF00FF87) : const Color(0xFFFFD54F),
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      if (!locked) ...[
                        const SizedBox(height: 4),
                        SizedBox(
                          width: 120,
                          height: 2,
                          child: LinearProgressIndicator(
                            value: progress,
                            backgroundColor: Colors.white12,
                            color: const Color(0xFFFFD54F),
                          ),
                        ),
                      ] else ...[
                        const SizedBox(height: 2),
                        const Text(
                          'CONFIDENCE: 98.4% | ACCURACY: ±0.01m',
                          style: TextStyle(color: Colors.white70, fontSize: 7, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'ENGINE: ARCORE v1.38\nDEPTH API: ${widget.depthApiEnabled ? "DYNAMIC (ACTIVE)" : "OFF"}\nFREQ: 60Hz',
                    style: const TextStyle(color: Colors.white54, fontSize: 6.5, height: 1.3, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              Positioned(
                bottom: 8,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      cText.toUpperCase(),
                      style: const TextStyle(color: Colors.white70, fontSize: 8, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class CrosshairPainter extends CustomPainter {
  final bool isLocked;
  CrosshairPainter({required this.isLocked});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isLocked ? const Color(0xFF00FF87) : const Color(0xFFFFD54F)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final double w = size.width;
    final double h = size.height;

    canvas.drawLine(const Offset(0, 0), const Offset(5, 0), paint);
    canvas.drawLine(const Offset(0, 0), const Offset(0, 5), paint);

    canvas.drawLine(Offset(w, 0), Offset(w - 5, 0), paint);
    canvas.drawLine(Offset(w, 0), Offset(w, 5), paint);

    canvas.drawLine(Offset(0, h), Offset(5, h), paint);
    canvas.drawLine(Offset(0, h), Offset(0, h - 5), paint);

    canvas.drawLine(Offset(w, h), Offset(w - 5, h), paint);
    canvas.drawLine(Offset(w, h), Offset(w, h - 5), paint);
  }

  @override
  bool shouldRepaint(covariant CrosshairPainter old) => isLocked != old.isLocked;
}
