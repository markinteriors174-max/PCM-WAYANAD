import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../models/ceiling_object.dart';
import '../utils/bezier_helpers.dart';
import '../utils/component_library.dart';

class CadBlueprintPainter extends CustomPainter {
  final List<CeilingObject> objects;
  final String? selectedId;
  final double roomL;
  final double roomW;
  final double gridSpacing;
  final List<Offset> sketchPoints;
  final double canvasZoom;
  final Offset canvasOffset;

  CadBlueprintPainter({
    required this.objects,
    required this.selectedId,
    required this.roomL,
    required this.roomW,
    required this.gridSpacing,
    required this.sketchPoints,
    required this.canvasZoom,
    required this.canvasOffset,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double maxRoom = math.max(roomL, roomW);
    final double baseScale = (math.min(size.width, size.height) * 0.70) / (maxRoom <= 0 ? 1 : maxRoom);
    final double scale = baseScale * canvasZoom;
    final Offset center = Offset(size.width / 2, size.height / 2) + canvasOffset;

    Offset ft(Offset feet) => center + Offset(feet.dx * scale, feet.dy * scale);

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), Paint()..color = const Color(0xFF0F141D));

    final majGrid = Paint()..color = const Color(0xFF1E293B)..strokeWidth = 0.8;
    final minGrid = Paint()..color = const Color(0xFF131C28)..strokeWidth = 0.4;
    final double step = gridSpacing;

    final double leftFt = (0.0 - center.dx) / scale;
    final double rightFt = (size.width - center.dx) / scale;
    final double topFt = (0.0 - center.dy) / scale;
    final double bottomFt = (size.height - center.dy) / scale;

    final double startX = (leftFt / step).floor() * step;
    final double endX = (rightFt / step).ceil() * step;
    final double startY = (topFt / step).floor() * step;
    final double endY = (bottomFt / step).ceil() * step;

    for (double x = startX; x <= endX; x += step) {
      final px = center.dx + x * scale;
      canvas.drawLine(Offset(px, 0), Offset(px, size.height), (x.abs() % (step * 2) < 0.001) ? majGrid : minGrid);
    }
    for (double y = startY; y <= endY; y += step) {
      final py = center.dy + y * scale;
      canvas.drawLine(Offset(0, py), Offset(size.width, py), (y.abs() % (step * 2) < 0.001) ? majGrid : minGrid);
    }

    for (double i = -(roomL / 2).floor().toDouble(); i <= (roomL / 2).floor(); i += 2) {
      _txt(canvas, '${i.toInt()}', Offset(center.dx + i * scale, size.height - 10), Colors.white24, 7);
    }
    for (double i = -(roomW / 2).floor().toDouble(); i <= (roomW / 2).floor(); i += 2) {
      _txt(canvas, '${i.toInt()}', Offset(14, center.dy + i * scale), Colors.white24, 7);
    }

    final Offset tl = ft(Offset(-roomL / 2, -roomW / 2));
    final Offset br = ft(Offset( roomL / 2,  roomW / 2));
    final roomRect  = Rect.fromPoints(tl, br);
    canvas.drawRect(roomRect, Paint()..color = const Color(0xFFD4AF37)..style = PaintingStyle.stroke..strokeWidth = 3.5);
    canvas.drawRect(roomRect.deflate(3), Paint()..color = const Color(0xFF1E2A3A)..style = PaintingStyle.stroke..strokeWidth = 1.0);

    final dimP = Paint()..color = const Color(0xFFD4AF37).withValues(alpha: 0.55)..strokeWidth = 0.8;
    final dTop = tl.dy - 15;
    canvas.drawLine(Offset(tl.dx, dTop), Offset(br.dx, dTop), dimP);
    canvas.drawLine(Offset(tl.dx, tl.dy), Offset(tl.dx, dTop - 2), dimP);
    canvas.drawLine(Offset(br.dx, tl.dy), Offset(br.dx, dTop - 2), dimP);
    _txt(canvas, '${roomL.toStringAsFixed(0)} Ft', Offset(center.dx, dTop - 9), const Color(0xFFD4AF37), 8.5);

    final dRight = br.dx + 15;
    canvas.drawLine(Offset(dRight, tl.dy), Offset(dRight, br.dy), dimP);
    canvas.drawLine(Offset(br.dx, tl.dy), Offset(dRight + 2, tl.dy), dimP);
    canvas.drawLine(Offset(br.dx, br.dy), Offset(dRight + 2, br.dy), dimP);
    _txt(canvas, '${roomW.toStringAsFixed(0)} Ft', Offset(dRight + 16, center.dy), const Color(0xFFD4AF37), 8.5);

    _txt(canvas, '${roomL.toStringAsFixed(0)} Ft × ${roomW.toStringAsFixed(0)} Ft Grid (Snap: $gridSpacing Ft)', Offset(center.dx, size.height - 10), Colors.white38, 8.5);

    for (final obj in objects) {
      _drawObj(canvas, obj, ft, scale, obj.id == selectedId);
    }

    if (sketchPoints.isNotEmpty) {
      final sketchPaint = Paint()
        ..color = const Color(0xFFD4AF37).withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      final path = Path();
      path.moveTo(ft(sketchPoints.first).dx, ft(sketchPoints.first).dy);
      for (int i = 1; i < sketchPoints.length; i++) {
        path.lineTo(ft(sketchPoints[i]).dx, ft(sketchPoints[i]).dy);
      }
      canvas.drawPath(path, sketchPaint);
    }
  }

  void _drawGlowPerimeter(Canvas canvas, Path path, bool led, bool cove) {
    if (led) {
      canvas.drawPath(path, Paint()
        ..color = const Color(0xFF00E5FF).withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6.0
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0));
      canvas.drawPath(path, Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5);
    }
    if (cove) {
      canvas.drawPath(path, Paint()
        ..color = const Color(0xFFFF9800).withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8.0
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0));
      canvas.drawPath(path, Paint()
        ..color = const Color(0xFFFFD54F)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0);
    }
  }
  void _drawObj(Canvas canvas, CeilingObject obj, Offset Function(Offset) ft, double scale, bool sel) {
    final pos = ft(obj.position);

    // Look up component specs
    ComponentItem? comp;
    try {
      comp = componentLibrary.firstWhere((c) => c.id == obj.type);
    } catch (_) {}
    final String family = comp?.shapeFamily ?? obj.type;

    if (obj.type == 'profile_light' && obj.startPoint != null && obj.endPoint != null) {
      final Offset pStart = ft(obj.startPoint!);
      final Offset pEnd = ft(obj.endPoint!);
      canvas.drawLine(pStart, pEnd, Paint()
        ..color = const Color(0xAA00E5FF)
        ..strokeWidth = sel ? 6.0 : 4.0);
      canvas.drawLine(pStart, pEnd, Paint()
        ..color = Colors.white
        ..strokeWidth = 1.5);
      if (sel) {
        _resizeHandle(canvas, pStart);
        _resizeHandle(canvas, pEnd);
        _dimLabel(canvas, '${obj.width.toStringAsFixed(1)} Ft Profile Light', (pStart + pEnd) / 2 - const Offset(0, 12), const Color(0xFF00E5FF));
      } else {
        _dimLabel(canvas, '${obj.width.toStringAsFixed(1)} Ft Profile', (pStart + pEnd) / 2 - const Offset(0, 8), const Color(0xFF00E5FF).withValues(alpha: 0.6));
      }
      return;
    }

    if (obj.type == 'gypsum_arc' && obj.startPoint != null && obj.endPoint != null) {
      final Offset pStart = ft(obj.startPoint!);
      final Offset pEnd = ft(obj.endPoint!);
      
      final bool hasCurve = obj.arcCurvature != null && obj.arcCurvature != 0;
      final Offset pControl = hasCurve 
          ? ft(getControlPoint(obj.startPoint!, obj.endPoint!, obj.arcCurvature!)) 
          : (pStart + pEnd) / 2;

      final edgePaint = Paint()..color = const Color(0xFF00E5FF)..style = PaintingStyle.stroke..strokeWidth = sel ? 2.5 : 1.5;

      final path = Path()..moveTo(pStart.dx, pStart.dy);
      if (hasCurve) {
        path.quadraticBezierTo(pControl.dx, pControl.dy, pEnd.dx, pEnd.dy);
      } else {
        path.lineTo(pEnd.dx, pEnd.dy);
      }
      
      canvas.drawPath(path, edgePaint);

      // Light glow bindings
      _drawGlowPerimeter(canvas, path, obj.hasLedStrip, obj.hasCoveLight);
      
      if (sel) {
        _resizeHandle(canvas, pStart);
        _resizeHandle(canvas, pEnd);
        if (hasCurve) {
          final Offset midFeet = getControlPoint(obj.startPoint!, obj.endPoint!, obj.arcCurvature! / 2);
          _resizeHandle(canvas, ft(midFeet));
        }
        _dimLabel(canvas, '${obj.width.toStringAsFixed(1)} Ft Gypsum Arc', (hasCurve ? ft((obj.startPoint! + obj.endPoint!) / 2) : (pStart + pEnd) / 2) - const Offset(0, 12), const Color(0xFF00E5FF));
      } else {
        _dimLabel(canvas, '${obj.width.toStringAsFixed(1)} Ft Gypsum Arc', (hasCurve ? ft((obj.startPoint! + obj.endPoint!) / 2) : (pStart + pEnd) / 2) - const Offset(0, 8), const Color(0xFF00E5FF).withValues(alpha: 0.6));
      }
      return;
    }

    if (obj.type == 'wall_line' && obj.startPoint != null && obj.endPoint != null) {
      final Offset pStart = ft(obj.startPoint!);
      final Offset pEnd = ft(obj.endPoint!);
      
      final bool hasCurve = obj.arcCurvature != null && obj.arcCurvature != 0;
      final Offset? pControl = hasCurve ? ft(getControlPoint(obj.startPoint!, obj.endPoint!, obj.arcCurvature!)) : null;

      final strokePaint = Paint()..color = const Color(0xFF8D6E63)..style = PaintingStyle.stroke..strokeWidth = sel ? 7.0 : 5.0;
      final innerPaint = Paint()..color = const Color(0xFFD7CCC8)..style = PaintingStyle.stroke..strokeWidth = 2.0;

      final path = Path()..moveTo(pStart.dx, pStart.dy);
      if (hasCurve) {
        path.quadraticBezierTo(pControl!.dx, pControl.dy, pEnd.dx, pEnd.dy);
        canvas.drawPath(path, strokePaint);
        canvas.drawPath(path, innerPaint);
      } else {
        canvas.drawLine(pStart, pEnd, strokePaint);
        canvas.drawLine(pStart, pEnd, innerPaint);
        path.lineTo(pEnd.dx, pEnd.dy);
      }

      // Allow bound lights on partition walls too
      _drawGlowPerimeter(canvas, path, obj.hasLedStrip, obj.hasCoveLight);
      
      if (sel) {
        _resizeHandle(canvas, pStart);
        _resizeHandle(canvas, pEnd);
        if (hasCurve) {
          final Offset midFeet = getControlPoint(obj.startPoint!, obj.endPoint!, obj.arcCurvature! / 2);
          _resizeHandle(canvas, ft(midFeet));
        }
        _dimLabel(canvas, '${obj.width.toStringAsFixed(1)} Ft Wall', (hasCurve ? ft((obj.startPoint! + obj.endPoint!) / 2) : (pStart + pEnd) / 2) - const Offset(0, 12), const Color(0xFF8D6E63));
      } else {
        _dimLabel(canvas, '${obj.width.toStringAsFixed(1)} Ft Wall', (hasCurve ? ft((obj.startPoint! + obj.endPoint!) / 2) : (pStart + pEnd) / 2) - const Offset(0, 8), const Color(0xFF8D6E63).withValues(alpha: 0.6));
      }
      return;
    }

    if ((obj.type == 'main_channel' || obj.type == 'cross_channel') && obj.startPoint != null && obj.endPoint != null) {
      final Offset pStart = ft(obj.startPoint!);
      final Offset pEnd = ft(obj.endPoint!);
      final Color stroke = const Color(0xFF00FF87);
      
      final bool hasCurve = obj.arcCurvature != null && obj.arcCurvature != 0;
      final Offset? pControl = hasCurve ? ft(getControlPoint(obj.startPoint!, obj.endPoint!, obj.arcCurvature!)) : null;

      if (hasCurve) {
        _drawDashedPath(canvas, pStart, pEnd, pControl!, stroke, sel ? 2.5 : 1.5);
      } else {
        _dashedLine(canvas, pStart, pEnd, stroke, sel ? 2.5 : 1.5);
      }

      if (sel) {
        _resizeHandle(canvas, pStart);
        _resizeHandle(canvas, pEnd);
        if (hasCurve) {
          final Offset midFeet = getControlPoint(obj.startPoint!, obj.endPoint!, obj.arcCurvature! / 2);
          _resizeHandle(canvas, ft(midFeet));
        }
        _dimLabel(canvas, '${obj.width.toStringAsFixed(1)} Ft Channel', (hasCurve ? ft((obj.startPoint! + obj.endPoint!) / 2) : (pStart + pEnd) / 2) - const Offset(0, 12), stroke);
      } else {
        _dimLabel(canvas, '${obj.width.toStringAsFixed(1)} Ft', (hasCurve ? ft((obj.startPoint! + obj.endPoint!) / 2) : (pStart + pEnd) / 2) - const Offset(0, 8), stroke.withValues(alpha: 0.6));
      }
      return;
    }

    if (family == 'oval' || family == 'gypsum_oval') {
      final double rx = (obj.width / 2) * scale;
      final double ry = (obj.height / 2) * scale;
      final Rect r = Rect.fromCenter(center: pos, width: rx * 2, height: ry * 2);
      
      canvas.drawOval(r, Paint()..color = const Color(0xFF0D2340).withValues(alpha: 0.5)..style = PaintingStyle.fill);
      canvas.drawOval(r, Paint()..color = const Color(0xFF00E5FF)..style = PaintingStyle.stroke..strokeWidth = sel ? 2.5 : 1.5);

      final path = Path()..addOval(r);
      _drawGlowPerimeter(canvas, path, obj.hasLedStrip, obj.hasCoveLight);

      if (sel) {
        _selBox(canvas, r);
        _resizeHandle(canvas, pos + Offset(rx, ry));
        _dimLabel(canvas, 'Oval ${obj.width.toStringAsFixed(1)}x${obj.height.toStringAsFixed(1)} Ft', pos - Offset(0, ry + 14), const Color(0xFF00E5FF));
      } else {
        _dimLabel(canvas, 'Oval ${obj.width.toStringAsFixed(1)}x${obj.height.toStringAsFixed(1)} Ft', pos + const Offset(0, -8), const Color(0xFF00E5FF).withValues(alpha: 0.6));
      }
      return;
    }

    if (family == 'circle' || family == 'gypsum_circle' || family == 'downlight') {
      final double radius = (obj.width / 2) * scale;
      final double r = math.max(radius, 5.0);
      Color stroke = obj.type == 'downlight' || family == 'downlight' ? const Color(0xFF00FF87) : const Color(0xFF00E5FF);
      canvas.drawCircle(pos, r, Paint()..color = stroke.withValues(alpha: 0.12)..style = PaintingStyle.fill);
      canvas.drawCircle(pos, r, Paint()..color = stroke..style = PaintingStyle.stroke..strokeWidth = sel ? 2.5 : 1.5);
      
      if (family == 'gypsum_circle' || obj.type == 'gypsum_circle') {
        final path = Path()..addOval(Rect.fromCircle(center: pos, radius: r));
        _drawGlowPerimeter(canvas, path, obj.hasLedStrip, obj.hasCoveLight);
      }
      
      if (obj.type == 'downlight' || family == 'downlight') {
        canvas.drawCircle(pos, r + 4, Paint()..color = const Color(0xFF00FF87).withValues(alpha: 0.18)..style = PaintingStyle.fill);
        canvas.drawLine(pos - Offset(r + 4, 0), pos + Offset(r + 4, 0), Paint()..color = Colors.white30..strokeWidth = 0.8);
        canvas.drawLine(pos - Offset(0, r + 4), pos + Offset(0, r + 4), Paint()..color = Colors.white30..strokeWidth = 0.8);
      }
      
      if (sel) {
        _selBox(canvas, Rect.fromCircle(center: pos, radius: r + 2));
        _resizeHandle(canvas, pos + Offset(r, r));
        _dimLabel(canvas, 'Ø ${obj.width.toStringAsFixed(1)} Ft', pos - Offset(0, r + 14), stroke);
      } else {
        _dimLabel(canvas, 'Ø ${obj.width.toStringAsFixed(1)} Ft', pos + const Offset(0, -8), stroke.withValues(alpha: 0.6));
      }
      return;
    }

    // Rotated architectural elements rendering using Canvas Matrix Transformations
    final double wPix = obj.width * scale;
    final double hPix = obj.height * scale;
    final rLocal = Rect.fromCenter(center: Offset.zero, width: wPix, height: hPix);

    canvas.save();
    canvas.translate(pos.dx, pos.dy);
    canvas.rotate(obj.rotation);

    Color fill = const Color(0xFF0D2340);
    Color stroke = const Color(0xFF00E5FF);

    if (family == 'ceiling_grid') { fill = const Color(0xFF0F1A24); stroke = const Color(0xFF1E88E5); }
    else if (family == 'border_profile') { fill = const Color(0xFF1E150B); stroke = const Color(0xFFD4AF37); }
    else if (family == 'fan') { fill = const Color(0xFF1A1200); stroke = Colors.amber; }
    else if (family == 'ac') { fill = const Color(0xFF001820); stroke = Colors.lightBlueAccent; }
    else if (family == 'bed') { fill = const Color(0xFF1F1B2C); stroke = const Color(0xFF9E8CF4); }
    else if (family == 'sofa') { fill = const Color(0xFF122424); stroke = const Color(0xFF4DB6AC); }
    else if (family == 'table') { fill = const Color(0xFF2C1E18); stroke = const Color(0xFFFFB74D); }
    else if (family == 'wardrobe') { fill = const Color(0xFF202020); stroke = const Color(0xFFCFD8DC); }
    else if (family == 'sticker' || family == 'decor') { fill = const Color(0x33B2DFDB); stroke = const Color(0xFF80CBC4); }
    else if (family == 'door' || family == 'window') { fill = Colors.transparent; stroke = const Color(0xFFFF8A65); }

    final fillPaint = Paint()..color = fill..style = PaintingStyle.fill;
    final strokePaint = Paint()..color = stroke..style = PaintingStyle.stroke..strokeWidth = sel ? 2.5 : 1.5;

    // Draw base boundary if not transparent
    if (fill != Colors.transparent) {
      canvas.drawRect(rLocal, fillPaint);
    }

    if (family == 'bed') {
      canvas.drawRect(rLocal, strokePaint);
      // Headboard
      canvas.drawRect(Rect.fromLTWH(-wPix / 2, -hPix / 2, wPix, hPix * 0.12), Paint()..color = stroke);
      // Pillows
      final pillowW = wPix * 0.28;
      final pillowH = hPix * 0.18;
      canvas.drawRect(Rect.fromLTWH(-wPix * 0.36, -hPix * 0.32, pillowW, pillowH), strokePaint..strokeWidth = 1.0);
      canvas.drawRect(Rect.fromLTWH(wPix * 0.08, -hPix * 0.32, pillowW, pillowH), strokePaint..strokeWidth = 1.0);
      // Mattress border line
      canvas.drawLine(Offset(-wPix/2, -hPix * 0.34), Offset(wPix/2, -hPix * 0.34), strokePaint..strokeWidth = 0.8);
    } 
    else if (family == 'sofa') {
      canvas.drawRect(rLocal, strokePaint);
      // Backrest
      canvas.drawRect(Rect.fromLTWH(-wPix / 2, -hPix / 2, wPix, hPix * 0.22), Paint()..color = stroke.withValues(alpha: 0.4));
      canvas.drawRect(Rect.fromLTWH(-wPix / 2, -hPix / 2, wPix, hPix * 0.22), strokePaint..strokeWidth = 1.0);
      // Armrests
      final armW = wPix * 0.12;
      canvas.drawRect(Rect.fromLTWH(-wPix / 2, -hPix / 2, armW, hPix), Paint()..color = stroke.withValues(alpha: 0.3));
      canvas.drawRect(Rect.fromLTWH(-wPix / 2, -hPix / 2, armW, hPix), strokePaint..strokeWidth = 1.0);
      canvas.drawRect(Rect.fromLTWH(wPix / 2 - armW, -hPix / 2, armW, hPix), Paint()..color = stroke.withValues(alpha: 0.3));
      canvas.drawRect(Rect.fromLTWH(wPix / 2 - armW, -hPix / 2, armW, hPix), strokePaint..strokeWidth = 1.0);
      // Cushion dividers
      final double innerW = wPix - armW * 2;
      if (obj.width > 5.0) { // 3 seater splits
        canvas.drawLine(Offset(-innerW / 6, -hPix * 0.28), Offset(-innerW / 6, hPix / 2), strokePaint..strokeWidth = 0.8);
        canvas.drawLine(Offset(innerW / 6, -hPix * 0.28), Offset(innerW / 6, hPix / 2), strokePaint..strokeWidth = 0.8);
      } else { // 2 seater splits
        canvas.drawLine(Offset(0.0, -hPix * 0.28), Offset(0.0, hPix / 2), strokePaint..strokeWidth = 0.8);
      }
    }
    else if (family == 'table') {
      canvas.drawRect(rLocal, strokePaint);
      // Center circle indicator or cross
      canvas.drawCircle(Offset.zero, 6.0, strokePaint..strokeWidth = 1.0);
      // Chairs symbols
      final double chairSize = math.min(wPix, hPix) * 0.25;
      final chairPaint = Paint()..color = stroke.withValues(alpha: 0.4)..style = PaintingStyle.stroke..strokeWidth = 1.0;
      // Draw 4 chairs
      canvas.drawRect(Rect.fromCenter(center: Offset(0.0, -hPix / 2 - chairSize / 2 - 2), width: chairSize, height: chairSize), chairPaint);
      canvas.drawRect(Rect.fromCenter(center: Offset(0.0, hPix / 2 + chairSize / 2 + 2), width: chairSize, height: chairSize), chairPaint);
      canvas.drawRect(Rect.fromCenter(center: Offset(-wPix / 2 - chairSize / 2 - 2, 0.0), width: chairSize, height: chairSize), chairPaint);
      canvas.drawRect(Rect.fromCenter(center: Offset(wPix / 2 + chairSize / 2 + 2, 0.0), width: chairSize, height: chairSize), chairPaint);
    }
    else if (family == 'wardrobe') {
      canvas.drawRect(rLocal, strokePaint);
      // Wardrobe hanger or door splits
      canvas.drawLine(Offset(-wPix / 2, -hPix / 2), Offset(wPix / 2, hPix / 2), strokePaint..strokeWidth = 0.5);
      canvas.drawLine(Offset(-wPix / 2, hPix / 2), Offset(wPix / 2, -hPix / 2), strokePaint..strokeWidth = 0.5);
      canvas.drawRect(rLocal.deflate(4.0), strokePaint..strokeWidth = 0.8);
    }
    else if (family == 'louver') {
      canvas.drawRect(rLocal, strokePaint);
      // Louvers repeating lines
      final louverP = Paint()..color = stroke.withValues(alpha: 0.45)..strokeWidth = 0.8;
      for (double lx = -wPix / 2 + 3.0; lx < wPix / 2; lx += 3.5) {
        canvas.drawLine(Offset(lx, -hPix / 2), Offset(lx, hPix / 2), louverP);
      }
    }
    else if (family == 'sticker') {
      // Dotted dashed rect
      final dashPaint = Paint()..color = stroke..strokeWidth = 1.0..style = PaintingStyle.stroke;
      const double dash = 4.0;
      const double gap = 3.0;
      // Top
      for (double lx = -wPix/2; lx < wPix/2; lx += dash + gap) {
        canvas.drawLine(Offset(lx, -hPix/2), Offset(math.min(lx + dash, wPix/2), -hPix/2), dashPaint);
        canvas.drawLine(Offset(lx, hPix/2), Offset(math.min(lx + dash, wPix/2), hPix/2), dashPaint);
      }
      // Sides
      for (double ly = -hPix/2; ly < hPix/2; ly += dash + gap) {
        canvas.drawLine(Offset(-wPix/2, ly), Offset(-wPix/2, math.min(ly + dash, hPix/2)), dashPaint);
        canvas.drawLine(Offset(wPix/2, ly), Offset(wPix/2, math.min(ly + dash, hPix/2)), dashPaint);
      }
    }
    else if (family == 'fan') {
      final double radius = wPix / 2;
      canvas.drawCircle(Offset.zero, 6.0, strokePaint..style = PaintingStyle.fill);
      canvas.drawCircle(Offset.zero, radius * 0.22, strokePaint..style = PaintingStyle.stroke);
      // Fan blades
      for (int i = 0; i < 3; i++) {
        final double ang = i * 2 * math.pi / 3;
        canvas.drawLine(
          Offset.zero,
          Offset(math.cos(ang) * radius, math.sin(ang) * radius),
          strokePaint..strokeWidth = 2.0,
        );
      }
    }
    else if (family == 'ac') {
      canvas.drawRect(rLocal, strokePaint);
      canvas.drawRect(rLocal.deflate(6.0), strokePaint..strokeWidth = 0.8);
      // Directional air lines
      canvas.drawLine(Offset(-wPix/3, -hPix/4), Offset(wPix/3, -hPix/4), strokePaint..strokeWidth = 0.5);
      canvas.drawLine(Offset(-wPix/3, hPix/4), Offset(wPix/3, hPix/4), strokePaint..strokeWidth = 0.5);
    }
    else if (family == 'door') {
      // Door Swing blueprint representation
      final double hingeX = -wPix / 2;
      final double hingeY = hPix / 2;
      // 1. Door Leaf at 45 degrees
      final double leafAngle = -math.pi / 4; // 45 degrees open
      final double leafX = hingeX + wPix * math.cos(leafAngle);
      final double leafY = hingeY + wPix * math.sin(leafAngle);
      canvas.drawLine(Offset(hingeX, hingeY), Offset(leafX, leafY), strokePaint..strokeWidth = 2.0);
      // 2. Door Frame
      canvas.drawLine(Offset(-wPix/2, -hPix/2), Offset(-wPix/2, hPix/2), strokePaint..strokeWidth = 1.0);
      canvas.drawLine(Offset(wPix/2, -hPix/2), Offset(wPix/2, hPix/2), strokePaint..strokeWidth = 1.0);
      // 3. Swing Arc
      final swingPaint = Paint()..color = stroke.withValues(alpha: 0.5)..style = PaintingStyle.stroke..strokeWidth = 0.8;
      final Rect arcRect = Rect.fromCircle(center: Offset(hingeX, hingeY), radius: wPix);
      canvas.drawArc(arcRect, 0, leafAngle, false, swingPaint);
    }
    else if (family == 'window') {
      // Standard window double line block
      canvas.drawRect(rLocal, strokePaint);
      canvas.drawLine(Offset(-wPix / 2, -hPix / 6), Offset(wPix / 2, -hPix / 6), strokePaint..strokeWidth = 0.8);
      canvas.drawLine(Offset(-wPix / 2, hPix / 6), Offset(wPix / 2, hPix / 6), strokePaint..strokeWidth = 0.8);
    }
    else {
      // Default rectangular shape
      canvas.drawRect(rLocal, strokePaint);
    }

    // Apply bound LED / Cove light borders on elements if toggled
    if (obj.hasLedStrip || obj.hasCoveLight) {
      final path = Path()..addRect(rLocal);
      _drawGlowPerimeter(canvas, path, obj.hasLedStrip, obj.hasCoveLight);
    }

    if (family == 'ceiling_grid') {
      final gridPaint = Paint()..color = stroke.withValues(alpha: 0.4)..strokeWidth = 0.8;
      final double stepPixels = 2.0 * scale;
      for (double x = rLocal.left + stepPixels; x < rLocal.right; x += stepPixels) {
        canvas.drawLine(Offset(x, rLocal.top), Offset(x, rLocal.bottom), gridPaint);
      }
      for (double y = rLocal.top + stepPixels; y < rLocal.bottom; y += stepPixels) {
        canvas.drawLine(Offset(rLocal.left, y), Offset(rLocal.right, y), gridPaint);
      }
    }

    if (family == 'border_profile') {
      if (rLocal.width > 12 && rLocal.height > 12) {
        canvas.drawRect(rLocal.deflate(4.0), Paint()..color = stroke.withValues(alpha: 0.5)..style = PaintingStyle.stroke..strokeWidth = 1.0);
        canvas.drawRect(rLocal.deflate(8.0), Paint()..color = stroke.withValues(alpha: 0.25)..style = PaintingStyle.stroke..strokeWidth = 0.8);
      } else {
        canvas.drawRect(rLocal.deflate(2.0), Paint()..color = stroke.withValues(alpha: 0.5)..style = PaintingStyle.stroke..strokeWidth = 1.0);
      }
    }

    canvas.restore();

    if (sel) {
      _selBox(canvas, Rect.fromCenter(center: pos, width: wPix + 2, height: hPix + 2));
      _resizeHandle(canvas, pos + Offset(wPix / 2, hPix / 2));
      _dimLabel(canvas, '${obj.width.toStringAsFixed(1)}x${obj.height.toStringAsFixed(1)} Ft', pos - Offset(0, hPix / 2 + 14), stroke);
    } else {
      _dimLabel(canvas, '${obj.width.toStringAsFixed(1)}x${obj.height.toStringAsFixed(1)} Ft', pos + const Offset(0, -8), stroke.withValues(alpha: 0.6));
    }
  }

  void _txt(Canvas canvas, String text, Offset pos, Color color, double size) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: TextStyle(color: color, fontSize: size, fontWeight: FontWeight.bold)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, pos - Offset(tp.width / 2, tp.height / 2));
  }

  void _resizeHandle(Canvas canvas, Offset pos) {
    canvas.drawCircle(pos, 5.0, Paint()..color = const Color(0xFFD4AF37)..style = PaintingStyle.fill);
    canvas.drawCircle(pos, 5.0, Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 1.0);
  }

  void _dimLabel(Canvas canvas, String text, Offset pos, Color color) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: TextStyle(color: color, fontSize: 8.0, fontWeight: FontWeight.bold)),
      textDirection: TextDirection.ltr,
    )..layout();
    final Rect rect = Rect.fromCenter(center: pos, width: tp.width + 6, height: tp.height + 2);
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(3)), Paint()..color = const Color(0xFF0F141D));
    tp.paint(canvas, pos - Offset(tp.width / 2, tp.height / 2));
  }

  void _dashedLine(Canvas canvas, Offset p1, Offset p2, Color color, double width) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = width
      ..style = PaintingStyle.stroke;
    final double distance = (p2 - p1).distance;
    final Offset direction = (p2 - p1) / (distance == 0 ? 1.0 : distance);
    const double dashLength = 6.0;
    const double gapLength = 4.0;
    double currentDistance = 0.0;
    while (currentDistance < distance) {
      final double nextDistance = math.min(currentDistance + dashLength, distance);
      canvas.drawLine(
        p1 + direction * currentDistance,
        p1 + direction * nextDistance,
        paint,
      );
      currentDistance += dashLength + gapLength;
    }
  }

  void _drawDashedPath(Canvas canvas, Offset p0, Offset p1, Offset pc, Color color, double width) {
    final List<Offset> pts = sampleBezier(p0, p1, pc, 24);
    final paint = Paint()
      ..color = color
      ..strokeWidth = width
      ..style = PaintingStyle.stroke;
    for (int i = 0; i < pts.length - 1; i += 2) {
      canvas.drawLine(pts[i], pts[i+1], paint);
    }
  }

  void _selBox(Canvas canvas, Rect rect) {
    final paint = Paint()
      ..color = const Color(0xFFD4AF37)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawRect(rect, paint);
  }

  @override
  bool shouldRepaint(covariant CadBlueprintPainter old) => true;
}
