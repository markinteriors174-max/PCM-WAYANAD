import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../models/ceiling_object.dart';

class PhotoOverlayPainter extends CustomPainter {
  final String? imagePath;
  final int presetIndex;
  final List<Offset> handles;
  final List<CeilingObject> objects;
  final double roomL;
  final double roomW;

  PhotoOverlayPainter({
    required this.imagePath,
    required this.presetIndex,
    required this.handles,
    required this.objects,
    required this.roomL,
    required this.roomW,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (handles.length < 4) return;
    final Offset tl = handles[0], tr = handles[1], br = handles[2], bl = handles[3];
    final Offset center = (tl + tr + br + bl) / 4;

    canvas.drawPath(Path()..addPolygon(handles, true),
      Paint()..color = const Color(0xFF0F141D).withValues(alpha: 0.52));

    canvas.drawPath(Path()..addPolygon(handles, true),
      Paint()..color = const Color(0xFFD4AF37).withValues(alpha: 0.7)..style = PaintingStyle.stroke..strokeWidth = 1.8);

    final linePaint = Paint()..color = const Color(0xFF00E5FF).withValues(alpha: 0.85)..style = PaintingStyle.stroke..strokeWidth = 1.4;
    final glowPaint = Paint()..color = const Color(0xFFFFDD88).withValues(alpha: 0.18)..style = PaintingStyle.fill..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7);

    Offset project(Offset feet) {
      final double u = (feet.dx + roomL / 2) / (roomL <= 0 ? 1.0 : roomL);
      final double v = (feet.dy + roomW / 2) / (roomW <= 0 ? 1.0 : roomW);
      return _lerp2(tl, tr, bl, br, u.clamp(0.0, 1.0), v.clamp(0.0, 1.0));
    }

    switch (presetIndex) {
      case 0: // Custom CAD Drawing
        final Paint borderP = Paint()..color = const Color(0xFFD4AF37).withValues(alpha: 0.45)..style = PaintingStyle.stroke..strokeWidth = 1.0;
        for (double u = 0.2; u < 1.0; u += 0.2) {
          canvas.drawLine(_lerp2(tl, tr, bl, br, u, 0), _lerp2(tl, tr, bl, br, u, 1), borderP);
          canvas.drawLine(_lerp2(tl, tr, bl, br, 0, u), _lerp2(tl, tr, bl, br, 1, u), borderP);
        }
        for (final obj in objects) {
          if (obj.startPoint != null && obj.endPoint != null) {
            final Offset pStart = project(obj.startPoint!);
            final Offset pEnd = project(obj.endPoint!);
            if (obj.type == 'wall_line') {
              canvas.drawLine(pStart, pEnd, Paint()..color = const Color(0xFF8D6E63)..strokeWidth = 3.5);
              canvas.drawLine(pStart, pEnd, Paint()..color = const Color(0xFFD7CCC8)..strokeWidth = 1.0);
            } else {
              final Color stroke = obj.type == 'main_channel' ? const Color(0xFFB0BEC5) : const Color(0xFF78909C);
              canvas.drawLine(pStart, pEnd, Paint()..color = stroke..strokeWidth = 2.0);
            }
          } else if (obj.type == 'gypsum_circle' || obj.type == 'downlight') {
            final Offset pPos = project(obj.position);
            if (obj.type == 'downlight') {
              canvas.drawCircle(pPos, 3.5, Paint()..color = const Color(0xFFFFFFFF));
              canvas.drawCircle(pPos, 8.0, Paint()..color = const Color(0xFFFFDD88).withValues(alpha: 0.25)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));
            } else {
              final double r = obj.width / 2;
              const int segs = 18;
              final List<Offset> pts = [];
              for (int i = 0; i <= segs; i++) {
                final double ang = i * 2 * math.pi / segs;
                final Offset ptFeet = obj.position + Offset(math.cos(ang) * r, math.sin(ang) * r);
                pts.add(project(ptFeet));
              }
              canvas.drawPath(Path()..addPolygon(pts, true), Paint()..color = const Color(0xFF00E5FF).withValues(alpha: 0.15)..style = PaintingStyle.fill);
              canvas.drawPath(Path()..addPolygon(pts, true), Paint()..color = const Color(0xFF00E5FF)..style = PaintingStyle.stroke..strokeWidth = 1.5);
            }
          } else {
            final double hw = obj.width / 2;
            final double hh = obj.height / 2;
            final Offset a = project(obj.position + Offset(-hw, -hh));
            final Offset b = project(obj.position + Offset(hw, -hh));
            final Offset c = project(obj.position + Offset(hw, hh));
            final Offset d = project(obj.position + Offset(-hw, hh));

            Color stroke = const Color(0xFF00E5FF);
            Color fill = const Color(0xFF00E5FF).withValues(alpha: 0.12);
            if (obj.type == 'ceiling_grid') { stroke = const Color(0xFF1E88E5); fill = const Color(0xFF1E88E5).withValues(alpha: 0.08); }
            if (obj.type == 'border_profile') { stroke = const Color(0xFFD4AF37); fill = const Color(0xFFD4AF37).withValues(alpha: 0.08); }
            if (obj.type == 'fan_box') { stroke = Colors.amber; fill = Colors.amber.withValues(alpha: 0.08); }
            if (obj.type == 'ac_vent') { stroke = Colors.lightBlueAccent; fill = Colors.lightBlueAccent.withValues(alpha: 0.08); }

            canvas.drawPath(Path()..addPolygon([a, b, c, d], true), Paint()..color = fill..style = PaintingStyle.fill);
            canvas.drawPath(Path()..addPolygon([a, b, c, d], true), Paint()..color = stroke..style = PaintingStyle.stroke..strokeWidth = 1.5);

            if (obj.type == 'ceiling_grid') {
              final gridP = Paint()..color = stroke.withValues(alpha: 0.35)..strokeWidth = 0.8;
              for (double x = -hw + 2.0; x < hw; x += 2.0) {
                final Offset topP = project(obj.position + Offset(x, -hh));
                final Offset bottomP = project(obj.position + Offset(x, hh));
                canvas.drawLine(topP, bottomP, gridP);
              }
              for (double y = -hh + 2.0; y < hh; y += 2.0) {
                final Offset leftP = project(obj.position + Offset(-hw, y));
                final Offset rightP = project(obj.position + Offset(hw, y));
                canvas.drawLine(leftP, rightP, gridP);
              }
            }
            if (obj.type == 'border_profile') {
              for (double step = 1; step <= 2; step++) {
                final double f = step * 0.2;
                final Offset aSub = project(obj.position + Offset(-hw * (1 - f), -hh * (1 - f)));
                final Offset bSub = project(obj.position + Offset(hw * (1 - f), -hh * (1 - f)));
                final Offset cSub = project(obj.position + Offset(hw * (1 - f), hh * (1 - f)));
                final Offset dSub = project(obj.position + Offset(-hw * (1 - f), hh * (1 - f)));
                canvas.drawPath(Path()..addPolygon([aSub, bSub, cSub, dSub], true), Paint()..color = stroke.withValues(alpha: 0.4)..style = PaintingStyle.stroke..strokeWidth = 0.8);
              }
            }
          }
        }
        break;

      case 1: // Grid Drop
        for (int i = 1; i <= 3; i++) {
          canvas.drawLine(Offset.lerp(tl, tr, i / 4)!, Offset.lerp(bl, br, i / 4)!, linePaint..strokeWidth = 0.9);
          canvas.drawLine(Offset.lerp(tl, bl, i / 4)!, Offset.lerp(tr, br, i / 4)!, linePaint);
        }
        break;

      case 2: // Circular Cove
        final double r = (center - tl).distance * 0.55;
        canvas.drawCircle(center, r, glowPaint);
        canvas.drawCircle(center, r,       Paint()..color = const Color(0xFFD4AF37).withValues(alpha: 0.8)..style = PaintingStyle.stroke..strokeWidth = 1.8);
        canvas.drawCircle(center, r * 0.68, linePaint..strokeWidth = 1.0);
        canvas.drawCircle(center, r * 0.95, glowPaint);
        break;

      case 3: // Coffered
        for (int row = 1; row <= 2; row++) {
          for (int col = 1; col <= 2; col++) {
            final Offset a = _lerp2(tl, tr, bl, br, col / 3, row / 3);
            final Offset b = _lerp2(tl, tr, bl, br, (col + 0.7) / 3, row / 3);
            final Offset c = _lerp2(tl, tr, bl, br, (col + 0.7) / 3, (row + 0.7) / 3);
            final Offset d = _lerp2(tl, tr, bl, br, col / 3, (row + 0.7) / 3);
            canvas.drawPath(Path()..addPolygon([a, b, c, d], true), linePaint..strokeWidth = 1.0);
          }
        }
        break;

      case 4: // Step Border
        for (int i = 1; i <= 3; i++) {
          final double f = i * 0.11;
          canvas.drawPath(Path()..addPolygon([
            Offset.lerp(tl, center, f)!, Offset.lerp(tr, center, f)!,
            Offset.lerp(br, center, f)!, Offset.lerp(bl, center, f)!,
          ], true), Paint()
            ..color = const Color(0xFFD4AF37).withValues(alpha: 0.8 - i * 0.15)
            ..style = PaintingStyle.stroke..strokeWidth = 1.5);
        }
        canvas.drawCircle(center, (center - tl).distance * 0.07, glowPaint..color = const Color(0xFFFFDD88).withValues(alpha: 0.35));
        break;

      case 5: // Tray Ceiling
        for (int i = 1; i <= 3; i++) {
          final double f = i * 0.12;
          canvas.drawPath(Path()..addPolygon([
            Offset.lerp(tl, center, f)!, Offset.lerp(tr, center, f)!,
            Offset.lerp(br, center, f)!, Offset.lerp(bl, center, f)!,
          ], true), linePaint..strokeWidth = i == 2 ? 1.6 : 0.9);
        }
        break;
    }
  }

  Offset _lerp2(Offset tl, Offset tr, Offset bl, Offset br, double u, double v) {
    final top = Offset.lerp(tl, tr, u)!;
    final bot = Offset.lerp(bl, br, u)!;
    return Offset.lerp(top, bot, v)!;
  }

  @override
  bool shouldRepaint(covariant PhotoOverlayPainter old) =>
      presetIndex != old.presetIndex || handles != old.handles || objects.length != old.objects.length;
}
