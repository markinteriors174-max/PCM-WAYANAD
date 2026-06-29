import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

/// Global starfield background — dark deep-space gradient with glowing neon stars.
/// Placed at MaterialApp builder level so it persists across ALL pages.
class StarfieldAnimation extends StatefulWidget {
  const StarfieldAnimation({super.key});

  @override
  State<StarfieldAnimation> createState() => _StarfieldAnimationState();
}

class _StarfieldAnimationState extends State<StarfieldAnimation>
    with TickerProviderStateMixin {
  late final AnimationController _controller;
  final List<Star> _stars = [];
  final Random _random = Random();
  bool _starsGenerated = false;

  // ── Neon palette ────────────────────────────────────────────────────────────
  static const List<Color> _neonColors = [
    Color(0xFF00E5FF), // Neon light blue
    Color(0xFF00B0FF), // Electric blue
    Color(0xFFFF4081), // Electric magenta / hot pink
    Color(0xFFE040FB), // Neon violet-pink
    Color(0xFFFFD600), // Bright neon gold
    Color(0xFFFFAB00), // Deep neon amber
    Color(0xFFFFFFFF), // Pure white (sparkle accent)
    Color(0xFF69FF47), // Neon lime (rare)
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    );
    if (kIsWeb || !Platform.environment.containsKey('FLUTTER_TEST')) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.stop();
    _controller.dispose();
    super.dispose();
  }

  void _generateStars(Size size) {
    if (_starsGenerated) return;
    _starsGenerated = true;
    for (int i = 0; i < 55; i++) {
      _stars.add(Star(
        x: _random.nextDouble() * size.width,
        y: _random.nextDouble() * size.height,
        size: _random.nextDouble() * 2.0 + 0.8,
        color: _neonColors[_random.nextInt(_neonColors.length)],
        blinkSpeed: _random.nextDouble() * 0.35 + 0.08,
        phase: _random.nextDouble() * pi * 2,
        driftSpeedX: _random.nextDouble() * 14.0 + 4.0,
        driftSpeedY: (_random.nextDouble() - 0.5) * 5.0,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Prevent Canvas crash during route transition/pop if constraints become unbounded.
        final w = constraints.hasBoundedWidth && constraints.maxWidth > 0 
            ? constraints.maxWidth 
            : MediaQuery.of(context).size.width;
            
        final h = constraints.hasBoundedHeight && constraints.maxHeight > 0 
            ? constraints.maxHeight 
            : kToolbarHeight * 2;
            
        final size = Size(w > 0 ? w : 400, h > 0 ? h : 120);
        
        _generateStars(size);
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final double elapsed =
                DateTime.now().millisecondsSinceEpoch / 1000.0;
            return CustomPaint(
              size: size,
              painter: _StarfieldPainter(
                stars: _stars,
                elapsed: elapsed,
              ),
            );
          },
        );
      },
    );
  }
}

// ── Data model ────────────────────────────────────────────────────────────────
class Star {
  final double x, y, size, blinkSpeed, phase, driftSpeedX, driftSpeedY;
  final Color color;

  Star({
    required this.x,
    required this.y,
    required this.size,
    required this.color,
    required this.blinkSpeed,
    required this.phase,
    required this.driftSpeedX,
    required this.driftSpeedY,
  });
}

// ── Painter ───────────────────────────────────────────────────────────────────
class _StarfieldPainter extends CustomPainter {
  final List<Star> stars;
  final double elapsed;

  _StarfieldPainter({required this.stars, required this.elapsed});

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Deep dark space gradient background
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF0A0A14), // Deep charcoal-navy
          Color(0xFF0D1B2A), // Rich dark blue
          Color(0xFF11101C), // Almost black purple
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // 2. Draw glowing neon stars with drift
    for (final star in stars) {
      final double cx =
          (star.x + elapsed * star.driftSpeedX) % size.width;
      final double cy =
          (star.y + elapsed * star.driftSpeedY) % size.height;

      // Slow breathe: full cycle every ~6-12 s per star
      final double wave =
          sin(elapsed * pi * 2.0 * star.blinkSpeed + star.phase);
      final double opacity = ((wave + 1.0) / 2.0).clamp(0.15, 1.0);

      final Offset center = Offset(cx, cy);

      // Outer glow halo (wide, very transparent)
      canvas.drawCircle(
        center,
        star.size * 5.0,
        Paint()..color = star.color.withValues(alpha: opacity * 0.08),
      );

      // Mid glow halo
      canvas.drawCircle(
        center,
        star.size * 2.8,
        Paint()..color = star.color.withValues(alpha: opacity * 0.22),
      );

      // Core bright dot
      canvas.drawCircle(
        center,
        star.size,
        Paint()..color = star.color.withValues(alpha: opacity.clamp(0.6, 1.0)),
      );

      // Sparkle cross for larger stars
      if (star.size > 1.8) {
        final sparklePaint = Paint()
          ..color = star.color.withValues(alpha: opacity * 0.45)
          ..strokeWidth = 0.7
          ..strokeCap = StrokeCap.round;
        final double arm = star.size * 3.5;
        canvas.drawLine(Offset(cx - arm, cy), Offset(cx + arm, cy), sparklePaint);
        canvas.drawLine(Offset(cx, cy - arm), Offset(cx, cy + arm), sparklePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _StarfieldPainter old) => true;
}
