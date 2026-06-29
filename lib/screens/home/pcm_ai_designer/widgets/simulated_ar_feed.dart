import 'dart:math' as math;
import 'package:flutter/material.dart';

class SimulatedArCameraFeed extends StatefulWidget {
  final bool transparentBg;
  const SimulatedArCameraFeed({super.key, this.transparentBg = false});

  @override
  State<SimulatedArCameraFeed> createState() => _SimulatedArCameraFeedState();
}

class _SimulatedArCameraFeedState extends State<SimulatedArCameraFeed> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<Offset> _featurePoints = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    final random = math.Random(42);
    for (int i = 0; i < 40; i++) {
      _featurePoints.add(Offset(random.nextDouble(), random.nextDouble()));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final double value = _controller.value;
        final double dx = math.sin(value * 2 * math.pi) * 12;
        final double dy = math.cos(value * 2 * math.pi) * 8;

        return CustomPaint(
          painter: _ArCameraSimPainter(
            driftX: dx,
            driftY: dy,
            featurePoints: _featurePoints,
            scanProgress: (value * 2) % 1.0,
            transparentBg: widget.transparentBg,
          ),
          child: Container(),
        );
      },
    );
  }
}

class _ArCameraSimPainter extends CustomPainter {
  final double driftX;
  final double driftY;
  final List<Offset> featurePoints;
  final double scanProgress;
  final bool transparentBg;

  _ArCameraSimPainter({
    required this.driftX,
    required this.driftY,
    required this.featurePoints,
    required this.scanProgress,
    this.transparentBg = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final bgRect = Rect.fromLTWH(0, 0, size.width, size.height);
    if (!transparentBg) {
      canvas.drawRect(bgRect, Paint()..color = const Color(0xFF0F1524));

      final Paint gradPaint = Paint()
        ..shader = RadialGradient(
          center: Alignment.center,
          radius: 1.2,
          colors: [const Color(0xFF1E2A4A), const Color(0xFF0C101D)],
        ).createShader(bgRect);
      canvas.drawRect(bgRect, gradPaint);
    }

    final guidesP = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final Offset tl = Offset(20 + driftX, 30 + driftY);
    final Offset tr = Offset(size.width - 20 + driftX, 30 + driftY);
    final Offset bl = Offset(40 + driftX * 0.5, size.height - 40 + driftY * 0.5);
    final Offset br = Offset(size.width - 40 + driftX * 0.5, size.height - 40 + driftY * 0.5);

    canvas.drawLine(tl, tr, guidesP);
    canvas.drawLine(tr, br, guidesP);
    canvas.drawLine(br, bl, guidesP);
    canvas.drawLine(bl, tl, guidesP);
    
    canvas.drawLine(tl, Offset(tl.dx, size.height), guidesP..color = Colors.white.withValues(alpha: 0.06));
    canvas.drawLine(tr, Offset(tr.dx, size.height), guidesP);
    canvas.drawLine(bl, Offset(bl.dx, size.height), guidesP);
    canvas.drawLine(br, Offset(br.dx, size.height), guidesP);

    final dotPaint = Paint()..style = PaintingStyle.fill;
    for (final pt in featurePoints) {
      final double px = pt.dx * size.width + driftX * (1 + pt.dy);
      final double py = pt.dy * size.height + driftY * (1 + pt.dx);
      if (px >= 0 && px <= size.width && py >= 0 && py <= size.height) {
        final double opacity = 0.2 + 0.6 * math.sin(scanProgress * 2 * math.pi + pt.dx * 10);
        dotPaint.color = const Color(0xFF00FF87).withValues(alpha: opacity);
        canvas.drawCircle(Offset(px, py), 2.0, dotPaint);
      }
    }

    final scanY = scanProgress * size.height;
    final laserPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF00FF87).withValues(alpha: 0.0),
          const Color(0xFF00FF87).withValues(alpha: 0.4),
          const Color(0xFF00FF87).withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTRB(0, scanY - 15, size.width, scanY + 15));
    canvas.drawRect(Rect.fromLTRB(0, scanY - 15, size.width, scanY + 15), laserPaint);

    final linePaint = Paint()
      ..color = const Color(0xFF00FF87).withValues(alpha: 0.7)
      ..strokeWidth = 1.0;
    canvas.drawLine(Offset(0, scanY), Offset(size.width, scanY), linePaint);
  }

  @override
  bool shouldRepaint(covariant _ArCameraSimPainter old) =>
      driftX != old.driftX || driftY != old.driftY || scanProgress != old.scanProgress;
}
