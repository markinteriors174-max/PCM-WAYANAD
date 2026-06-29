import 'dart:math' as math;
import 'package:flutter/material.dart';

class CeilingObject {
  final String id;
  final String type;
  // type: 'gypsum_rect', 'gypsum_circle', 'main_channel',
  //       'cross_channel', 'fan_box', 'ac_vent', 'downlight',
  //       'wall_line', 'ceiling_grid', 'border_profile'
  Offset position; // center in feet, relative to room center
  double width;    // feet (or diameter for circle, major diameter for oval)
  double height;   // feet (or minor diameter for oval)
  Offset? startPoint;
  Offset? endPoint;
  double? arcCurvature; // non-zero represents quadratic Bezier offset height
  double rotation;      // rotation in radians
  bool hasLedStrip;     // binds neon LED strip
  bool hasCoveLight;    // binds cove light

  CeilingObject({
    required this.id,
    required this.type,
    required this.position,
    required this.width,
    required this.height,
    this.startPoint,
    this.endPoint,
    this.arcCurvature = 0.0,
    this.rotation = 0.0,
    this.hasLedStrip = false,
    this.hasCoveLight = false,
  });

  double get perimeter {
    switch (type) {
      case 'gypsum_circle':
        return math.pi * width;
      case 'gypsum_oval':
        // Ramanujan approximation: pi * (3(a+b) - sqrt((3a+b)(a+3b)))
        final double a = width / 2;
        final double b = height / 2;
        return math.pi * (3 * (a + b) - math.sqrt((3 * a + b) * (a + 3 * b)));
      case 'gypsum_arc':
      case 'wall_line':
      case 'profile_light':
        if (startPoint != null && endPoint != null) {
          final double chord = (endPoint! - startPoint!).distance;
          if (arcCurvature != null && arcCurvature != 0) {
            // Parabolic arc length approximation
            return math.sqrt(chord * chord + 5.33 * arcCurvature! * arcCurvature!);
          }
          return chord;
        }
        return width;
      case 'border_profile':
        return 2 * (width + height);
      default:
        return 2 * (width + height);
    }
  }
}
