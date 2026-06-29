import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/ceiling_object.dart';

double snapFt(double v, double spacing) {
  if (spacing <= 0) return v;
  return (v / spacing).round() * spacing;
}

Offset snapToGrid(Offset feet, double roomL, double roomW, double spacing) => Offset(
  snapFt(feet.dx, spacing).clamp(-roomL / 2, roomL / 2),
  snapFt(feet.dy, spacing).clamp(-roomW / 2, roomW / 2),
);

double snapDim(double v, double spacing) => math.max(spacing, snapFt(v, spacing));

double distanceToSegment(Offset p, Offset a, Offset b) {
  final double l2 = (b - a).dx * (b - a).dx + (b - a).dy * (b - a).dy;
  if (l2 == 0) return (p - a).distance;
  double t = ((p.dx - a.dx) * (b - a).dx + (p.dy - a.dy) * (b - a).dy) / l2;
  t = t.clamp(0.0, 1.0);
  final Offset projection = a + (b - a) * t;
  return (p - projection).distance;
}

Offset snapToVertices(Offset feet, List<CeilingObject> objects, String? excludeId, double threshold) {
  for (final obj in objects) {
    if (obj.id == excludeId) continue;
    if (obj.startPoint != null) {
      if ((feet - obj.startPoint!).distance < threshold) {
        return obj.startPoint!;
      }
    }
    if (obj.endPoint != null) {
      if ((feet - obj.endPoint!).distance < threshold) {
        return obj.endPoint!;
      }
    }
    // Snap to rect corners
    if (obj.type == 'gypsum_rect' || obj.type == 'border_profile' || obj.type == 'ceiling_grid') {
      final double hw = obj.width / 2;
      final double hh = obj.height / 2;
      final corners = [
        Offset(obj.position.dx - hw, obj.position.dy - hh),
        Offset(obj.position.dx + hw, obj.position.dy - hh),
        Offset(obj.position.dx + hw, obj.position.dy + hh),
        Offset(obj.position.dx - hw, obj.position.dy + hh),
      ];
      for (final c in corners) {
        if ((feet - c).distance < threshold) {
          return c;
        }
      }
    }
  }
  return feet;
}

Offset snapToAngle(Offset feet, Offset startPoint, double angleSnapDeg) {
  if (angleSnapDeg <= 0.0) return feet;
  final Offset v = feet - startPoint;
  final double len = v.distance;
  if (len == 0) return feet;
  
  final double angle = math.atan2(v.dy, v.dx);
  final double snapStepRad = angleSnapDeg * math.pi / 180.0;
  final double snappedAngle = (angle / snapStepRad).round() * snapStepRad;
  
  return startPoint + Offset(math.cos(snappedAngle) * len, math.sin(snappedAngle) * len);
}

Map<String, dynamic> snapToWall(Offset feet, List<CeilingObject> objects, double threshold) {
  Offset bestProj = feet;
  double minDistance = double.infinity;
  double bestAngle = 0.0;
  String? snappedWallId;

  for (final obj in objects) {
    if (obj.type == 'wall_line' && obj.startPoint != null && obj.endPoint != null) {
      final a = obj.startPoint!;
      final b = obj.endPoint!;
      
      final double l2 = (b - a).dx * (b - a).dx + (b - a).dy * (b - a).dy;
      if (l2 == 0) continue;
      
      double t = ((feet.dx - a.dx) * (b - a).dx + (feet.dy - a.dy) * (b - a).dy) / l2;
      t = t.clamp(0.0, 1.0);
      
      final Offset projection = a + (b - a) * t;
      final double dist = (feet - projection).distance;
      
      if (dist < minDistance) {
        minDistance = dist;
        bestProj = projection;
        snappedWallId = obj.id;
        
        // Calculate normal vector facing the center (0.0, 0.0) of the room
        final double dx = b.dx - a.dx;
        final double dy = b.dy - a.dy;
        // Two possible normals: (-dy, dx) and (dy, -dx)
        Offset normal = Offset(-dy, dx);
        if (normal.dx * (0.0 - projection.dx) + normal.dy * (0.0 - projection.dy) < 0) {
          normal = Offset(dy, -dx);
        }
        bestAngle = math.atan2(normal.dy, normal.dx);
      }
    }
  }

  if (minDistance < threshold && snappedWallId != null) {
    return {
      'snapped': true,
      'position': bestProj,
      'rotation': bestAngle,
      'wallId': snappedWallId,
    };
  }

  return {
    'snapped': false,
    'position': feet,
    'rotation': 0.0,
  };
}
