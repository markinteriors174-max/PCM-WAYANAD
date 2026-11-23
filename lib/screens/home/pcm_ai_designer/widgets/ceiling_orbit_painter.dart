import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../models/ceiling_object.dart';
import '../utils/bezier_helpers.dart';
import '../utils/component_library.dart';
import '../utils/gltf_parser.dart';

class CeilingOrbitPainter extends CustomPainter {
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

  static const double halfW   = 68.0;
  static const double halfH   = 42.0;
  static const double halfD   = 68.0;
  static const double camDist = 300.0;
  static const double dropH   = 9.0;

  CeilingOrbitPainter({
    required this.objects,
    required this.rotationX,
    required this.rotationY,
    required this.zoomScale,
    required this.roomL,
    required this.roomW,
    this.fanAngle = 0.0,
    this.downlightsOn = true,
    this.coveLightOn = true,
    this.showFramework = false,
  });

  Offset _proj(double x, double y, double z, Size sz) {
    final c = Offset(sz.width / 2, sz.height / 2);
    final cosY = math.cos(rotationY), sinY = math.sin(rotationY);
    final x1 = x * cosY - z * sinY, z1 = x * sinY + z * cosY;
    final cosX = math.cos(rotationX), sinX = math.sin(rotationX);
    final y2 = y * cosX - z1 * sinX, z2 = y * sinX + z1 * cosX;
    final s = (camDist * zoomScale) / (z2 + camDist);
    return Offset(c.dx + x1 * s, c.dy + y2 * s);
  }

  Offset _projFt(double xf, double zf, double y3, Size sz) =>
    _proj(xf * (halfW / (roomL > 0 ? roomL / 2 : 1)), y3, zf * (halfD / (roomW > 0 ? roomW / 2 : 1)), sz);

  Color _shadeFace({
    required List<Offset> verticesFt,
    required double yFt,
    required Offset normalFt,
    required Color baseColor,
    required double opacity,
  }) {
    if (verticesFt.isEmpty) return baseColor.withValues(alpha: opacity);
    double ambient = 0.45;
    double diffuse = 0.0;

    if (downlightsOn) {
      for (final obj in objects) {
        if (obj.type == 'downlight') {
          double sumX = 0, sumZ = 0;
          for (final v in verticesFt) {
            sumX += v.dx;
            sumZ += v.dy;
          }
          final double faceCenterX = sumX / verticesFt.length;
          final double faceCenterZ = sumZ / verticesFt.length;
          final double faceCenterY = yFt;

          final double dx = faceCenterX - obj.position.dx;
          final double dz = faceCenterZ - obj.position.dy;
          final double dy = faceCenterY - (-5.0); // downlight feet height is -5.0

          final double dist = math.sqrt(dx * dx + dy * dy + dz * dz);
          if (dist > 0) {
            final double lx = -dx / dist;
            final double ly = -dy / dist;
            final double lz = -dz / dist;

            // Horizontal (downward facing) normal is default
            double nx = 0.0, ny = 1.0, nz = 0.0;
            if (normalFt != Offset.zero) {
              nx = normalFt.dx;
              ny = 0.0;
              nz = normalFt.dy;
            }

            final double dot = nx * lx + ny * ly + nz * lz;
            if (dot > 0) {
              final double falloff = 2.2 / (1.0 + 0.12 * dist * dist);
              diffuse += dot * falloff;
            }
          }
        }
      }
    }

    if (coveLightOn) {
      diffuse += 0.28;
    }

    final double totalLight = (ambient + diffuse).clamp(0.0, 1.0);
    return Color.lerp(const Color(0xFF1B1A18), baseColor, totalLight)!.withValues(alpha: opacity);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final bgRect = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawRect(bgRect, Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF080B11), Color(0xFF0B0F18)],
      ).createShader(bgRect));

    final wireP = Paint()..color = const Color(0xFFD4AF37).withValues(alpha: 0.25)..style = PaintingStyle.stroke..strokeWidth = 0.8;

    final verts = [
      [-halfW, -halfH, -halfD], [ halfW, -halfH, -halfD],
      [ halfW, -halfH,  halfD], [-halfW, -halfH,  halfD],
      [-halfW,  halfH, -halfD], [ halfW,  halfH, -halfD],
      [ halfW,  halfH,  halfD], [-halfW,  halfH,  halfD],
    ];
    final proj = verts.map((v) => _proj(v[0], v[1], v[2], size)).toList();

    // 1. Concrete Roof Slab (at y = -halfH - 8)
    final slabVerts = [
      _proj(-halfW, -halfH - 8, -halfD, size),
      _proj( halfW, -halfH - 8, -halfD, size),
      _proj( halfW, -halfH - 8,  halfD, size),
      _proj(-halfW, -halfH - 8,  halfD, size),
    ];
    canvas.drawPath(Path()..addPolygon(slabVerts, true), Paint()..color = const Color(0xFF263238)..style = PaintingStyle.fill);
    canvas.drawPath(Path()..addPolygon(slabVerts, true), Paint()..color = const Color(0xFF37474F)..style = PaintingStyle.stroke..strokeWidth = 1.0);

    // 2. X-Ray Hanger Rods (drawn behind ceiling plate)
    if (showFramework) {
      _drawHangerRods(canvas, size);
    }

    // 3. Ceiling Boards (Gypsum Board Skin, semi-transparent if showFramework is true)
    final ceilPts = [proj[0], proj[1], proj[2], proj[3]];
    final ceilPath = Path()..addPolygon(ceilPts, true);
    final ceilRect = Rect.fromPoints(proj[0], proj[2]);
    final double ceilOpacity = showFramework ? 0.45 : 1.0;

    final Color ceilColorStart = (coveLightOn || downlightsOn) 
        ? const Color(0xFFFFFFFF).withValues(alpha: ceilOpacity) 
        : const Color(0xFFF0EFEA).withValues(alpha: ceilOpacity);
    final Color ceilColorEnd = (coveLightOn || downlightsOn) 
        ? const Color(0xFFEFECE5).withValues(alpha: ceilOpacity) 
        : const Color(0xFFDCD8CF).withValues(alpha: ceilOpacity);

    canvas.drawPath(ceilPath, Paint()
      ..shader = RadialGradient(
        center: Alignment.center, radius: 0.85,
        colors: [ceilColorStart, ceilColorEnd],
      ).createShader(ceilRect)
      ..style = PaintingStyle.fill);
    canvas.drawPath(ceilPath, wireP..color = Colors.white.withValues(alpha: showFramework ? 0.25 : 0.6));

    // 4. Draw Room boundary lines
    for (final e in [[0,4],[1,5],[2,6],[3,7],[4,5],[5,6],[6,7],[7,4],[0,1],[1,2],[2,3],[3,0]]) {
      canvas.drawLine(proj[e[0]], proj[e[1]], wireP);
    }

    // 5. Metallic Channels (drawn in front of ceiling board, facing the room)
    if (showFramework) {
      _drawMetallicChannels(canvas, size);
    }

    // 6. Render designed objects
    for (final obj in objects) {
      _draw3dObj(canvas, obj, size);
    }
  }

  void _drawHangerRods(Canvas canvas, Size sz) {
    final rodPaint = Paint()
      ..color = const Color(0xFF90CAF9).withValues(alpha: 0.5) // Hanger rods distinct light metallic blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (double x = -roomL / 2 + 2.0; x < roomL / 2; x += 4.0) {
      for (double z = -roomW / 2 + 2.0; z < roomW / 2; z += 4.0) {
        final Offset rodTop = _projFt(x, z, -halfH - 8, sz);
        final Offset rodBottom = _projFt(x, z, -halfH + 0.5, sz);
        canvas.drawLine(rodTop, rodBottom, rodPaint);
      }
    }
  }

  void _drawMetallicChannels(Canvas canvas, Size sz) {
    final metalPaint = Paint()
      ..color = const Color(0xFF2979FF) // Distinct metallic steel blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final double lAngleY = -halfH + 1.0;
    final Offset tlL = _projFt(-roomL / 2, -roomW / 2, lAngleY, sz);
    final Offset trL = _projFt( roomL / 2, -roomW / 2, lAngleY, sz);
    final Offset brL = _projFt( roomL / 2,  roomW / 2, lAngleY, sz);
    final Offset blL = _projFt(-roomL / 2,  roomW / 2, lAngleY, sz);

    // Wall perimeter (yellow steel angle)
    canvas.drawPath(Path()..addPolygon([tlL, trL, brL, blL], true), Paint()
      ..color = const Color(0xFFFFD54F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5);

    // Main Channels
    for (double z = -roomW / 2 + 2.0; z < roomW / 2; z += 4.0) {
      final List<Offset> mainLine = [];
      for (double x = -roomL / 2; x <= roomL / 2; x += 1.0) {
        mainLine.add(_projFt(x, z, -halfH + 0.5, sz));
      }
      canvas.drawPath(Path()..addPolygon(mainLine, false), metalPaint..strokeWidth = 3.5);
    }

    // Cross Section Channels
    for (double x = -roomL / 2 + 2.0; x < roomL / 2; x += 2.0) {
      final List<Offset> crossLine = [];
      for (double z = -roomW / 2; z <= roomW / 2; z += 1.0) {
        crossLine.add(_projFt(x, z, -halfH + 1.2, sz));
      }
      canvas.drawPath(Path()..addPolygon(crossLine, false), metalPaint..color = const Color(0xFF00B0FF)..strokeWidth = 2.0);

      // Connection clips
      for (double z = -roomW / 2 + 2.0; z < roomW / 2; z += 4.0) {
        final Offset intersectPos = _projFt(x, z, -halfH + 0.85, sz);
        canvas.drawRect(
          Rect.fromCenter(center: intersectPos, width: 4.0, height: 4.0),
          Paint()..color = const Color(0xFFE3F2FD)..style = PaintingStyle.fill,
        );
      }
    }
  }

  void _draw3dObj(Canvas canvas, CeilingObject obj, Size sz) {
    final double opacity = showFramework ? 0.35 : 1.0;

    ComponentItem? comp;
    try {
      comp = componentLibrary.firstWhere((c) => c.id == obj.type);
    } catch (_) {}
    final String family = comp?.shapeFamily ?? obj.type;

    final gltfModel = GltfParser.getModel(obj.type);
    if (gltfModel != null) {
      _drawGltfModel(canvas, obj, gltfModel, sz);
      return;
    }

    if (family == 'louver') {
      _draw3dLouvers(canvas, obj, sz);
      return;
    }
    if (family == 'sticker') {
      _draw3dSticker(canvas, obj, sz);
      return;
    }
    if (family == 'door') {
      _draw3dDoor(canvas, obj, sz);
      return;
    }
    if (family == 'window') {
      _draw3dWindow(canvas, obj, sz);
      return;
    }
    if (family == 'fan' && obj.type.contains('wall_fan')) {
      _draw3dWallFan(canvas, obj, sz);
      return;
    }
    if (family == 'gypsum_oval' || family == 'oval') {
      _draw3dOval(canvas, obj, sz);
      return;
    }
    if (family == 'gypsum_arc' || family == 'arc') {
      _draw3dArc(canvas, obj, sz);
      return;
    }

    switch (obj.type) {
      case 'perimeter_cove':
        final double hw = obj.width / 2, hh = obj.height / 2;
        final double dy = -halfH + dropH;

        final List<Offset> innerTop = [], innerBot = [], lipReturn = [];
        final List<Offset> ptsFt = [];
        const int steps = 18;
        for (int i = 0; i <= steps; i++) {
          final double ang = i * 2 * math.pi / steps;
          final double cx = obj.position.dx + math.cos(ang) * hw;
          final double cz = obj.position.dy + math.sin(ang) * hh;
          
          innerTop.add(_projFt(cx, cz, -halfH, sz));
          innerBot.add(_projFt(cx, cz, dy, sz));
          ptsFt.add(Offset(cx, cz));
          
          final double lipX = obj.position.dx + math.cos(ang) * (hw - 0.4);
          final double lipZ = obj.position.dy + math.sin(ang) * (hh - 0.4);
          lipReturn.add(_projFt(lipX, lipZ, dy - 0.25, sz));
        }

        final double opacityVal = showFramework ? 0.45 : 1.0;
        final Paint strokeP = Paint()..color = const Color(0xFFB0BEC5).withValues(alpha: 0.4 * opacityVal)..style = PaintingStyle.stroke..strokeWidth = 0.8;
        
        // Draw vertical drop face (panels)
        for (int i = 0; i < steps; i++) {
          final int next = (i + 1) % steps;
          final face = [innerTop[i], innerTop[next], innerBot[next], innerBot[i]];
          
          final double ang = (i + 0.5) * 2 * math.pi / steps;
          final Offset normalFt = Offset(math.cos(ang), math.sin(ang));
          
          final Color faceColor = _shadeFace(
            verticesFt: [ptsFt[i], ptsFt[next]],
            yFt: (-halfH + dropH / 2) * (5.0 / halfH),
            normalFt: normalFt,
            baseColor: const Color(0xFFF5F5F0),
            opacity: opacityVal,
          );
          canvas.drawPath(Path()..addPolygon(face, true), Paint()..color = faceColor..style = PaintingStyle.fill);
          canvas.drawPath(Path()..addPolygon(face, true), strokeP);
        }

        // Draw lip pocket bottom face
        for (int i = 0; i < steps; i++) {
          final int next = (i + 1) % steps;
          final bottomFace = [innerBot[i], innerBot[next], lipReturn[next], lipReturn[i]];
          
          final double ang = (i + 0.5) * 2 * math.pi / steps;
          final double midX = obj.position.dx + math.cos(ang) * (hw - 0.2);
          final double midZ = obj.position.dy + math.sin(ang) * (hh - 0.2);
          
          final Color faceColor = _shadeFace(
            verticesFt: [Offset(midX, midZ)],
            yFt: dy * (5.0 / halfH),
            normalFt: Offset.zero,
            baseColor: const Color(0xFFFFFFFF),
            opacity: opacityVal,
          );
          canvas.drawPath(Path()..addPolygon(bottomFace, true), Paint()..color = faceColor..style = PaintingStyle.fill);
          canvas.drawPath(Path()..addPolygon(bottomFace, true), strokeP);
        }

        // Project soft upward wash light
        if (coveLightOn) {
          final washPaint = Paint()
            ..shader = RadialGradient(
              center: Alignment.center,
              radius: 0.9,
              colors: [
                const Color(0xFFFFE082).withValues(alpha: 0.35 * opacityVal),
                const Color(0xFFFFD54F).withValues(alpha: 0.12 * opacityVal),
                const Color(0x00FFD54F),
              ],
            ).createShader(Rect.fromPoints(innerTop[0], innerTop[steps ~/ 2]));
          canvas.drawPath(Path()..addPolygon(innerTop, true), washPaint);

          // LED strip glowing inside the pocket
          for (int i = 0; i < steps - 1; i++) {
            canvas.drawLine(
              innerBot[i] + const Offset(0, -2),
              innerBot[i + 1] + const Offset(0, -2),
              Paint()
                ..color = const Color(0xFFFFF59D).withValues(alpha: opacityVal)
                ..strokeWidth = 2.0
                ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0),
            );
          }
        }
        break;

      case 'wall_line':
        if (obj.startPoint != null && obj.endPoint != null) {
          final bool hasCurve = obj.arcCurvature != null && obj.arcCurvature != 0;
          if (hasCurve) {
            final Offset pcFeet = getControlPoint(obj.startPoint!, obj.endPoint!, obj.arcCurvature!);
            final List<Offset> ptsFeet = sampleBezier(obj.startPoint!, obj.endPoint!, pcFeet, 12);
            for (int i = 0; i < ptsFeet.length - 1; i++) {
              final Offset p0 = ptsFeet[i];
              final Offset p1 = ptsFeet[i+1];
              final Offset a = _projFt(p0.dx, p0.dy, -halfH, sz);
              final Offset b = _projFt(p1.dx, p1.dy, -halfH, sz);
              final Offset aFloor = _projFt(p0.dx, p0.dy, halfH, sz);
              final Offset bFloor = _projFt(p1.dx, p1.dy, halfH, sz);
              
              canvas.drawPath(Path()..addPolygon([a, b, bFloor, aFloor], true), Paint()..color = const Color(0xFF8D6E63).withValues(alpha: 0.7 * opacity)..style = PaintingStyle.fill);
              canvas.drawPath(Path()..addPolygon([a, b, bFloor, aFloor], true), Paint()..color = const Color(0xFFD7CCC8).withValues(alpha: opacity)..style = PaintingStyle.stroke..strokeWidth = 1.5);
            }
          } else {
            final Offset a = _projFt(obj.startPoint!.dx, obj.startPoint!.dy, -halfH, sz);
            final Offset b = _projFt(obj.endPoint!.dx, obj.endPoint!.dy, -halfH, sz);
            final Offset aFloor = _projFt(obj.startPoint!.dx, obj.startPoint!.dy, halfH, sz);
            final Offset bFloor = _projFt(obj.endPoint!.dx, obj.endPoint!.dy, halfH, sz);
            
            canvas.drawPath(Path()..addPolygon([a, b, bFloor, aFloor], true), Paint()..color = const Color(0xFF8D6E63).withValues(alpha: 0.7 * opacity)..style = PaintingStyle.fill);
            canvas.drawPath(Path()..addPolygon([a, b, bFloor, aFloor], true), Paint()..color = const Color(0xFFD7CCC8).withValues(alpha: opacity)..style = PaintingStyle.stroke..strokeWidth = 1.5);
          }
        }
        break;

      case 'main_channel':
      case 'cross_channel':
        if (obj.startPoint != null && obj.endPoint != null) {
          final bool hasCurve = obj.arcCurvature != null && obj.arcCurvature != 0;
          if (hasCurve) {
            final Offset pcFeet = getControlPoint(obj.startPoint!, obj.endPoint!, obj.arcCurvature!);
            final List<Offset> ptsFeet = sampleBezier(obj.startPoint!, obj.endPoint!, pcFeet, 12);
            for (int i = 0; i < ptsFeet.length - 1; i++) {
              final Offset pStart = _projFt(ptsFeet[i].dx, ptsFeet[i].dy, -halfH + 1.0, sz);
              final Offset pEnd = _projFt(ptsFeet[i+1].dx, ptsFeet[i+1].dy, -halfH + 1.0, sz);
              canvas.drawLine(pStart, pEnd, Paint()..color = const Color(0xFFB0BEC5).withValues(alpha: opacity)..style = PaintingStyle.stroke..strokeWidth = 3.0);
              canvas.drawLine(pStart, pEnd, Paint()..color = Colors.white.withValues(alpha: opacity)..style = PaintingStyle.stroke..strokeWidth = 1.0);
            }
          } else {
            final Offset pStart = _projFt(obj.startPoint!.dx, obj.startPoint!.dy, -halfH + 1.0, sz);
            final Offset pEnd = _projFt(obj.endPoint!.dx, obj.endPoint!.dy, -halfH + 1.0, sz);
            canvas.drawLine(pStart, pEnd, Paint()..color = const Color(0xFFB0BEC5).withValues(alpha: opacity)..style = PaintingStyle.stroke..strokeWidth = 3.0);
            canvas.drawLine(pStart, pEnd, Paint()..color = Colors.white.withValues(alpha: opacity)..style = PaintingStyle.stroke..strokeWidth = 1.0);
          }
        }
        break;

      case 'ceiling_grid':
        final double hw = obj.width / 2, hh = obj.height / 2;
        final Offset a = _projFt(obj.position.dx - hw, obj.position.dy - hh, -halfH + 1.5, sz);
        final Offset b = _projFt(obj.position.dx + hw, obj.position.dy - hh, -halfH + 1.5, sz);
        final Offset c = _projFt(obj.position.dx + hw, obj.position.dy + hh, -halfH + 1.5, sz);
        final Offset d = _projFt(obj.position.dx - hw, obj.position.dy + hh, -halfH + 1.5, sz);
        
        canvas.drawPath(Path()..addPolygon([a, b, c, d], true), Paint()..color = const Color(0xFFECEFF1).withValues(alpha: 0.8 * opacity)..style = PaintingStyle.fill);
        canvas.drawPath(Path()..addPolygon([a, b, c, d], true), Paint()..color = const Color(0xFFB0BEC5).withValues(alpha: opacity)..style = PaintingStyle.stroke..strokeWidth = 1.2);
        
        final gridP = Paint()..color = const Color(0xFF90A4AE).withValues(alpha: opacity)..style = PaintingStyle.stroke..strokeWidth = 1.8;
        for (double x = -hw + 2.0; x < hw; x += 2.0) {
          canvas.drawLine(_projFt(obj.position.dx + x, obj.position.dy - hh, -halfH + 1.3, sz),
                          _projFt(obj.position.dx + x, obj.position.dy + hh, -halfH + 1.3, sz), gridP);
        }
        for (double y = -hh + 2.0; y < hh; y += 2.0) {
          canvas.drawLine(_projFt(obj.position.dx - hw, obj.position.dy + y, -halfH + 1.3, sz),
                          _projFt(obj.position.dx + hw, obj.position.dy + y, -halfH + 1.3, sz), gridP);
        }
        break;

      case 'border_profile':
        final double hw = obj.width / 2, hh = obj.height / 2;
        for (int step = 0; step < 3; step++) {
          final double offset = step * 0.4;
          final double hOff = -halfH + (step * 2.5);
          final double wSub = hw - offset;
          final double hSub = hh - offset;
          if (wSub <= 0 || hSub <= 0) break;
          
          final Offset a = _projFt(obj.position.dx - wSub, obj.position.dy - hSub, hOff, sz);
          final Offset b = _projFt(obj.position.dx + wSub, obj.position.dy - hSub, hOff, sz);
          final Offset c = _projFt(obj.position.dx + wSub, obj.position.dy + hSub, hOff, sz);
          final Offset d = _projFt(obj.position.dx - wSub, obj.position.dy + hSub, hOff, sz);
          
          canvas.drawPath(Path()..addPolygon([a, b, c, d], true), Paint()..color = const Color(0xFFFFFDF9).withValues(alpha: 0.3 * opacity)..style = PaintingStyle.fill);
          canvas.drawPath(Path()..addPolygon([a, b, c, d], true), Paint()..color = const Color(0xFFD4AF37).withValues(alpha: (0.8 - step * 0.2) * opacity)..style = PaintingStyle.stroke..strokeWidth = 1.5);
        }
        break;
      case 'gypsum_rect':
        final double hw = obj.width  / 2, hh = obj.height / 2;
        final double dy = -halfH + dropH;
        
        final Offset a = _projFt(obj.position.dx - hw, obj.position.dy - hh, -halfH, sz);
        final Offset b = _projFt(obj.position.dx + hw, obj.position.dy - hh, -halfH, sz);
        final Offset c = _projFt(obj.position.dx + hw, obj.position.dy + hh, -halfH, sz);
        final Offset d = _projFt(obj.position.dx - hw, obj.position.dy + hh, -halfH, sz);
        
        final Offset aD = _projFt(obj.position.dx - hw, obj.position.dy - hh, dy, sz);
        final Offset bD = _projFt(obj.position.dx + hw, obj.position.dy - hh, dy, sz);
        final Offset cD = _projFt(obj.position.dx + hw, obj.position.dy + hh, dy, sz);
        final Offset dD = _projFt(obj.position.dx - hw, obj.position.dy + hh, dy, sz);

        final double opacityVal = showFramework ? 0.45 : 1.0;
        final Paint strokeP = Paint()..color = const Color(0xFFB0BEC5).withValues(alpha: 0.4 * opacityVal)..style = PaintingStyle.stroke..strokeWidth = 0.8;

        final Offset fA = Offset(obj.position.dx - hw, obj.position.dy - hh);
        final Offset fB = Offset(obj.position.dx + hw, obj.position.dy - hh);
        final Offset fC = Offset(obj.position.dx + hw, obj.position.dy + hh);
        final Offset fD = Offset(obj.position.dx - hw, obj.position.dy + hh);

        // Side 1: A-B (North, normal is (0, -1))
        final Color cAB = _shadeFace(
          verticesFt: [fA, fB],
          yFt: (dy - dropH/2) * (5.0/halfH),
          normalFt: const Offset(0, -1),
          baseColor: const Color(0xFFF5F5F0),
          opacity: opacityVal,
        );
        canvas.drawPath(Path()..addPolygon([a, b, bD, aD], true), Paint()..color = cAB..style = PaintingStyle.fill);
        canvas.drawPath(Path()..addPolygon([a, b, bD, aD], true), strokeP);

        // Side 2: B-C (East, normal is (1, 0))
        final Color cBC = _shadeFace(
          verticesFt: [fB, fC],
          yFt: (dy - dropH/2) * (5.0/halfH),
          normalFt: const Offset(1, 0),
          baseColor: const Color(0xFFF5F5F0),
          opacity: opacityVal,
        );
        canvas.drawPath(Path()..addPolygon([b, c, cD, bD], true), Paint()..color = cBC..style = PaintingStyle.fill);
        canvas.drawPath(Path()..addPolygon([b, c, cD, bD], true), strokeP);

        // Side 3: C-D (South, normal is (0, 1))
        final Color cCD = _shadeFace(
          verticesFt: [fC, fD],
          yFt: (dy - dropH/2) * (5.0/halfH),
          normalFt: const Offset(0, 1),
          baseColor: const Color(0xFFF5F5F0),
          opacity: opacityVal,
        );
        canvas.drawPath(Path()..addPolygon([c, d, dD, cD], true), Paint()..color = cCD..style = PaintingStyle.fill);
        canvas.drawPath(Path()..addPolygon([c, d, dD, cD], true), strokeP);

        // Side 4: D-A (West, normal is (-1, 0))
        final Color cDA = _shadeFace(
          verticesFt: [fD, fA],
          yFt: (dy - dropH/2) * (5.0/halfH),
          normalFt: const Offset(-1, 0),
          baseColor: const Color(0xFFF5F5F0),
          opacity: opacityVal,
        );
        canvas.drawPath(Path()..addPolygon([d, a, aD, dD], true), Paint()..color = cDA..style = PaintingStyle.fill);
        canvas.drawPath(Path()..addPolygon([d, a, aD, dD], true), strokeP);

        // Bottom face
        final Color bottomColor = _shadeFace(
          verticesFt: [fA, fB, fC, fD],
          yFt: dy * (5.0 / halfH),
          normalFt: Offset.zero,
          baseColor: const Color(0xFFFFFFFF),
          opacity: opacityVal,
        );
        canvas.drawPath(Path()..addPolygon([aD, bD, cD, dD], true), Paint()..color = bottomColor..style = PaintingStyle.fill);
        canvas.drawPath(Path()..addPolygon([aD, bD, cD, dD], true), strokeP);

        // LED/Cove light strip binding
        if (obj.hasLedStrip || obj.hasCoveLight) {
          final List<Offset> rectPts = [
            Offset(obj.position.dx - hw, obj.position.dy - hh),
            Offset(obj.position.dx + hw, obj.position.dy - hh),
            Offset(obj.position.dx + hw, obj.position.dy + hh),
            Offset(obj.position.dx - hw, obj.position.dy + hh),
            Offset(obj.position.dx - hw, obj.position.dy - hh),
          ];
          _drawNeonGlow3d(canvas, rectPts, dy, obj.hasLedStrip, obj.hasCoveLight, sz);
        }
        break;

      case 'ac_vent':
        final double hw = obj.width  / 2, hh = obj.height / 2;
        final Offset a = _projFt(obj.position.dx - hw, obj.position.dy - hh, -halfH, sz);
        final Offset b = _projFt(obj.position.dx + hw, obj.position.dy - hh, -halfH, sz);
        final Offset c = _projFt(obj.position.dx + hw, obj.position.dy + hh, -halfH, sz);
        final Offset d = _projFt(obj.position.dx - hw, obj.position.dy + hh, -halfH, sz);
        final double dyVal = -halfH + dropH;
        final Offset aD = _projFt(obj.position.dx - hw, obj.position.dy - hh, dyVal, sz);
        final Offset bD = _projFt(obj.position.dx + hw, obj.position.dy - hh, dyVal, sz);
        final Offset cD = _projFt(obj.position.dx + hw, obj.position.dy + hh, dyVal, sz);
        final Offset dD = _projFt(obj.position.dx - hw, obj.position.dy + hh, dyVal, sz);

        Color objColor = Colors.lightBlueAccent;
        Color fill3d   = const Color(0xFFA8D8E8);

        final fillP   = Paint()..color = fill3d.withValues(alpha: 0.30 * opacity)..style = PaintingStyle.fill;
        final strokeP = Paint()..color = objColor.withValues(alpha: 0.85 * opacity)..style = PaintingStyle.stroke..strokeWidth = 1.5;
        final sideP   = Paint()..color = fill3d.withValues(alpha: 0.15 * opacity)..style = PaintingStyle.fill;

        canvas.drawPath(Path()..addPolygon([a, b, c, d], true), fillP);
        canvas.drawPath(Path()..addPolygon([a, b, c, d], true), strokeP);

        for (final face in [[a, b, bD, aD], [b, c, cD, bD], [c, d, dD, cD]]) {
          canvas.drawPath(Path()..addPolygon(face, true), sideP);
          canvas.drawPath(Path()..addPolygon(face, true), strokeP..color = objColor.withValues(alpha: 0.45 * opacity));
        }

        for (int i = 1; i <= 3; i++) {
          final double lx = obj.position.dx - hw + obj.width * i / 4;
          canvas.drawLine(
            _projFt(lx, obj.position.dy - hh, -halfH, sz),
            _projFt(lx, obj.position.dy + hh, -halfH, sz),
            Paint()..color = Colors.lightBlueAccent.withValues(alpha: 0.4 * opacity)..strokeWidth = 0.8);
        }
        break;

      case 'fan_box':
        // 1. Vertical Rod
        final double fanY = -halfH + 4.5;
        final Offset rodTop = _projFt(obj.position.dx, obj.position.dy, -halfH, sz);
        final Offset rodBot = _projFt(obj.position.dx, obj.position.dy, fanY, sz);
        canvas.drawLine(rodTop, rodBot, Paint()..color = const Color(0xFF3E2723).withValues(alpha: opacity)..strokeWidth = 4.0); // Brown rod
        canvas.drawLine(rodTop, rodBot, Paint()..color = const Color(0xFFD4AF37).withValues(alpha: opacity)..strokeWidth = 1.0); // Gold accent stripe
        
        // 2. Motor Hub Casing (Cylinder)
        final int circlePoints = 12;
        final double hubRadius = 0.8; // ft
        final double hubThickness = 0.6; // ft
        final List<Offset> hubTopPoints = [];
        final List<Offset> hubBotPoints = [];
        
        for (int i = 0; i < circlePoints; i++) {
          final double ang = i * 2 * math.pi / circlePoints;
          final double dx = obj.position.dx + math.cos(ang) * hubRadius;
          final double dy = obj.position.dy + math.sin(ang) * hubRadius;
          hubTopPoints.add(_projFt(dx, dy, fanY - hubThickness / 2, sz));
          hubBotPoints.add(_projFt(dx, dy, fanY + hubThickness / 2, sz));
        }
        
        // Draw hub cylinder sides
        for (int i = 0; i < circlePoints; i++) {
          final int next = (i + 1) % circlePoints;
          final face = [hubTopPoints[i], hubTopPoints[next], hubBotPoints[next], hubTopPoints[i]];
          final double ang = (i + 0.5) * 2 * math.pi / circlePoints;
          final double intensity = 0.5 + 0.5 * math.cos(ang + rotationY);
          final Color sideColor = Color.lerp(const Color(0xFF3E2723), const Color(0xFFD4AF37), intensity)!;
          canvas.drawPath(Path()..addPolygon(face, true), Paint()..color = sideColor.withValues(alpha: opacity)..style = PaintingStyle.fill);
          canvas.drawPath(Path()..addPolygon(face, true), Paint()..color = const Color(0x33000000).withValues(alpha: opacity)..style = PaintingStyle.stroke..strokeWidth = 0.5);
        }
        
        // Draw top and bottom lids of hub
        canvas.drawPath(Path()..addPolygon(hubTopPoints, true), Paint()..color = const Color(0xFFD4AF37).withValues(alpha: opacity)..style = PaintingStyle.fill);
        canvas.drawPath(Path()..addPolygon(hubBotPoints, true), Paint()..color = const Color(0xFF3E2723).withValues(alpha: opacity)..style = PaintingStyle.fill);
        
        // 3. Three spinning blades
        final double bladeLength = 3.5; // ft
        final double bladeWidth = 0.5; // ft
        final Paint bladePaint = Paint()..style = PaintingStyle.fill;
        final Paint bladeOutline = Paint()..color = const Color(0xFF2D1500).withValues(alpha: opacity)..style = PaintingStyle.stroke..strokeWidth = 0.8;
        
        for (int i = 0; i < 3; i++) {
          final double baseAngle = fanAngle + i * 2 * math.pi / 3;
          final double cosB = math.cos(baseAngle);
          final double sinB = math.sin(baseAngle);
          final double bx = obj.position.dx;
          final double bz = obj.position.dy;
          
          // Base points
          final double x1 = bx + cosB * hubRadius - sinB * (bladeWidth / 2);
          final double z1 = bz + sinB * hubRadius + cosB * (bladeWidth / 2);
          final double y1 = fanY - 0.08;
          
          final double x2 = bx + cosB * hubRadius + sinB * (bladeWidth / 2);
          final double z2 = bz + sinB * hubRadius - cosB * (bladeWidth / 2);
          final double y2 = fanY + 0.08;
          
          // Tip points
          final double x3 = bx + cosB * (hubRadius + bladeLength) + sinB * (bladeWidth / 2);
          final double z3 = bz + sinB * (hubRadius + bladeLength) - cosB * (bladeWidth / 2);
          final double y3 = fanY + 0.12;
          
          final double x4 = bx + cosB * (hubRadius + bladeLength) - sinB * (bladeWidth / 2);
          final double z4 = bz + sinB * (hubRadius + bladeLength) + cosB * (bladeWidth / 2);
          final double y4 = fanY - 0.12;
          
          final Offset p1 = _projFt(x1, z1, y1, sz);
          final Offset p2 = _projFt(x2, z2, y2, sz);
          final Offset p3 = _projFt(x3, z3, y3, sz);
          final Offset p4 = _projFt(x4, z4, y4, sz);
          
          final double shadingVal = 0.5 + 0.5 * math.cos(baseAngle + rotationY);
          final Color woodColor = Color.lerp(const Color(0xFF4E342E), const Color(0xFF8D6E63), shadingVal)!;
          
          final bladePath = Path()..addPolygon([p1, p2, p3, p4], true);
          canvas.drawPath(bladePath, bladePaint..color = woodColor.withValues(alpha: opacity));
          canvas.drawPath(bladePath, bladeOutline);
        }
        break;
      case 'gypsum_circle':
        const int segs = 24;
        final double rFeet = obj.width / 2;
        List<Offset> topRing = [], botRing = [];
        List<Offset> topPtsFt = [], botPtsFt = [];
        
        for (int i = 0; i <= segs; i++) {
          final double ang = i * 2 * math.pi / segs;
          final double dx = obj.position.dx + math.cos(ang) * rFeet;
          final double dz = obj.position.dy + math.sin(ang) * rFeet;
          
          topPtsFt.add(Offset(dx, dz));
          botPtsFt.add(Offset(dx, dz));
          
          topRing.add(_projFt(dx, dz, -halfH, sz));
          botRing.add(_projFt(dx, dz, -halfH + dropH, sz));
        }

        final double opacityVal = showFramework ? 0.45 : 1.0;
        final Paint strokeP = Paint()..color = const Color(0xFFB0BEC5).withValues(alpha: 0.4 * opacityVal)..style = PaintingStyle.stroke..strokeWidth = 0.8;
        final double dy = -halfH + dropH;

        // Draw side cylinder faces
        for (int i = 0; i < segs; i++) {
          final int next = i + 1;
          final face = [topRing[i], topRing[next], botRing[next], botRing[i]];
          
          final double ang = (i + 0.5) * 2 * math.pi / segs;
          final Offset normalFt = Offset(math.cos(ang), math.sin(ang));
          
          final Color faceColor = _shadeFace(
            verticesFt: [topPtsFt[i], topPtsFt[next]],
            yFt: (-halfH + dropH / 2) * (5.0 / halfH),
            normalFt: normalFt,
            baseColor: const Color(0xFFF5F5F0),
            opacity: opacityVal,
          );
          canvas.drawPath(Path()..addPolygon(face, true), Paint()..color = faceColor..style = PaintingStyle.fill);
          canvas.drawPath(Path()..addPolygon(face, true), strokeP);
        }

        // Draw bottom circle face
        final Color bottomColor = _shadeFace(
          verticesFt: botPtsFt,
          yFt: dy * (5.0 / halfH),
          normalFt: Offset.zero,
          baseColor: const Color(0xFFFFFFFF),
          opacity: opacityVal,
        );
        canvas.drawPath(Path()..addPolygon(botRing, true), Paint()..color = bottomColor..style = PaintingStyle.fill);
        canvas.drawPath(Path()..addPolygon(botRing, true), strokeP);
        break;
      case 'downlight':
        final Offset lightPos = _projFt(obj.position.dx, obj.position.dy, -halfH, sz);
        if (downlightsOn) {
          canvas.drawCircle(lightPos, 24, Paint()
            ..color = const Color(0xFFFFDD88).withValues(alpha: 0.10 * opacity)
            ..style = PaintingStyle.fill
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16));
          canvas.drawCircle(lightPos, 12, Paint()
            ..color = const Color(0xFFFFFFAA).withValues(alpha: 0.35 * opacity)
            ..style = PaintingStyle.fill
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
          canvas.drawCircle(lightPos, 5, Paint()..color = Colors.white.withValues(alpha: opacity));
        } else {
          canvas.drawCircle(lightPos, 5, Paint()..color = const Color(0xFF444444).withValues(alpha: opacity)..style = PaintingStyle.fill);
          canvas.drawCircle(lightPos, 5, Paint()..color = const Color(0xFF222222).withValues(alpha: opacity)..style = PaintingStyle.stroke..strokeWidth = 0.5);
        }
        break;

      case 'profile_light':
        if (obj.startPoint != null && obj.endPoint != null) {
          final Offset pStart = _projFt(obj.startPoint!.dx, obj.startPoint!.dy, -halfH + 0.1, sz);
          final Offset pEnd = _projFt(obj.endPoint!.dx, obj.endPoint!.dy, -halfH + 0.1, sz);
          canvas.drawLine(pStart, pEnd, Paint()
            ..color = const Color(0xFF151821).withValues(alpha: opacity)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 4.5);
          if (coveLightOn) {
            canvas.drawLine(pStart, pEnd, Paint()
              ..color = const Color(0x6600E5FF).withValues(alpha: opacity)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 9.0
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0));
            canvas.drawLine(pStart, pEnd, Paint()
              ..color = const Color(0xFF00FFD8).withValues(alpha: opacity)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 3.5);
            canvas.drawLine(pStart, pEnd, Paint()
              ..color = Colors.white.withValues(alpha: opacity)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.2);
          } else {
            canvas.drawLine(pStart, pEnd, Paint()
              ..color = const Color(0xFF4A4D55).withValues(alpha: opacity)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2.0);
          }
        }
        break;
    }
  }

  void _drawNeonGlow3d(Canvas canvas, List<Offset> pointsFt, double yFt, bool led, bool cove, Size sz) {
    if (!led && !cove) return;
    
    final List<Offset> projPts = [];
    for (final pt in pointsFt) {
      projPts.add(_projFt(pt.dx, pt.dy, yFt, sz));
    }
    
    final path = Path();
    if (projPts.isNotEmpty) {
      path.moveTo(projPts.first.dx, projPts.first.dy);
      for (int i = 1; i < projPts.length; i++) {
        path.lineTo(projPts[i].dx, projPts[i].dy);
      }
    }

    final double opacityVal = showFramework ? 0.35 : 1.0;

    // 1. Ceiling wash reflection
    if (coveLightOn) {
      final List<Offset> ceilProjPts = [];
      for (final pt in pointsFt) {
        ceilProjPts.add(_projFt(pt.dx, pt.dy, -halfH + 0.2, sz));
      }
      final ceilPath = Path();
      if (ceilProjPts.isNotEmpty) {
        ceilPath.moveTo(ceilProjPts.first.dx, ceilProjPts.first.dy);
        for (int i = 1; i < ceilProjPts.length; i++) {
          ceilPath.lineTo(ceilProjPts[i].dx, ceilProjPts[i].dy);
        }
      }
      
      if (led) {
        canvas.drawPath(ceilPath, Paint()
          ..color = const Color(0xFF00E5FF).withValues(alpha: 0.22 * opacityVal)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 20.0
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10));
      }
      if (cove) {
        canvas.drawPath(ceilPath, Paint()
          ..color = const Color(0xFFFF9800).withValues(alpha: 0.28 * opacityVal)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 28.0
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14));
      }
    }

    // 2. Direct light glow
    if (led) {
      canvas.drawPath(path, Paint()
        ..color = const Color(0xFF00E5FF).withValues(alpha: 0.7 * opacityVal)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.5
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0));
      canvas.drawPath(path, Paint()
        ..color = Colors.white.withValues(alpha: opacityVal)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2);
    }
    if (cove) {
      canvas.drawPath(path, Paint()
        ..color = const Color(0xFFFFB74D).withValues(alpha: 0.7 * opacityVal)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6.0
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5));
      canvas.drawPath(path, Paint()
        ..color = const Color(0xFFFFE082).withValues(alpha: opacityVal)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5);
    }
  }


  void _drawGltfModel(Canvas canvas, CeilingObject obj, GltfModel model, Size sz) {
    final double cosR = math.cos(obj.rotation);
    final double sinR = math.sin(obj.rotation);

    for (final mesh in model.meshes) {
      for (final primitive in mesh.primitives) {
        Color baseCol = const Color(0xFF90A4AE);
        switch (primitive.material) {
          case 'wood': baseCol = const Color(0xFF8D6E63); break;
          case 'fabric_mattress': baseCol = const Color(0xFFECEFF1); break;
          case 'fabric_pillow': baseCol = const Color(0xFF80DEEA); break;
          case 'fabric_cushion':
          case 'fabric_back': baseCol = const Color(0xFF26A69A); break;
          case 'fabric_arm': baseCol = const Color(0xFF00897B); break;
          case 'glass_dark': baseCol = const Color(0xCC263238); break;
          case 'fabric_curtain': baseCol = const Color(0xFFB0BEC5); break;
          case 'clay_pot': baseCol = const Color(0xFFFF8A65); break;
          case 'leaf_green': baseCol = const Color(0xFF66BB6A); break;
        }

        final edgePaint = Paint()..color = baseCol.withValues(alpha: 0.3)..style = PaintingStyle.stroke..strokeWidth = 0.5;

        // Triangles drawing
        for (int i = 0; i < primitive.indices.length; i += 3) {
          final int i0 = primitive.indices[i];
          final int i1 = primitive.indices[i + 1];
          final int i2 = primitive.indices[i + 2];

          final double v0x = primitive.positions[i0 * 3];
          final double v0y = primitive.positions[i0 * 3 + 1];
          final double v0z = primitive.positions[i0 * 3 + 2];

          final double v1x = primitive.positions[i1 * 3];
          final double v1y = primitive.positions[i1 * 3 + 1];
          final double v1z = primitive.positions[i1 * 3 + 2];

          final double v2x = primitive.positions[i2 * 3];
          final double v2y = primitive.positions[i2 * 3 + 1];
          final double v2z = primitive.positions[i2 * 3 + 2];

          // Rotate and translate in room coordinate space
          final double rx0 = v0x * cosR - v0z * sinR + obj.position.dx;
          final double rz0 = v0x * sinR + v0z * cosR + obj.position.dy;
          final double ry0 = halfH - v0y * (halfH * 2 / 10); // scale height from floor upwards

          final double rx1 = v1x * cosR - v1z * sinR + obj.position.dx;
          final double rz1 = v1x * sinR + v1z * cosR + obj.position.dy;
          final double ry1 = halfH - v1y * (halfH * 2 / 10);

          final double rx2 = v2x * cosR - v2z * sinR + obj.position.dx;
          final double rz2 = v2x * sinR + v2z * cosR + obj.position.dy;
          final double ry2 = halfH - v2y * (halfH * 2 / 10);

          final Offset p0 = _projFt(rx0, rz0, ry0, sz);
          final Offset p1 = _projFt(rx1, rz1, ry1, sz);
          final Offset p2 = _projFt(rx2, rz2, ry2, sz);

          // Apply simple shading: shade faces differently based on orientation to create 3D shape depth
          final double shade = 0.5 + 0.5 * math.cos(i0.toDouble() + rotationY);
          final Color shadedCol = Color.lerp(Colors.black, baseCol, 0.4 + 0.6 * shade)!;

          canvas.drawPath(Path()..addPolygon([p0, p1, p2], true), Paint()..color = shadedCol..style = PaintingStyle.fill);
          canvas.drawPath(Path()..addPolygon([p0, p1, p2], true), edgePaint);
        }
      }
    }

    // Apply bound LED / Cove light borders in 3D around the base coordinates
    if (obj.hasLedStrip || obj.hasCoveLight) {
      final double hw = obj.width / 2;
      final double hh = obj.height / 2;
      final double dy = halfH - 1.0; // close to floor for furniture
      final List<Offset> basePts = [
        Offset(obj.position.dx - hw, obj.position.dy - hh),
        Offset(obj.position.dx + hw, obj.position.dy - hh),
        Offset(obj.position.dx + hw, obj.position.dy + hh),
        Offset(obj.position.dx - hw, obj.position.dy + hh),
        Offset(obj.position.dx - hw, obj.position.dy - hh),
      ];
      // Apply rotation to base path
      final List<Offset> rotatedPts = [];
      for (final pt in basePts) {
        final double dx = pt.dx - obj.position.dx;
        final double dz = pt.dy - obj.position.dy;
        final double rx = dx * cosR - dz * sinR + obj.position.dx;
        final double rz = dx * sinR + dz * cosR + obj.position.dy;
        rotatedPts.add(Offset(rx, rz));
      }
      _drawNeonGlow3d(canvas, rotatedPts, dy, obj.hasLedStrip, obj.hasCoveLight, sz);
    }
  }

  void _draw3dLouvers(Canvas canvas, CeilingObject obj, Size sz) {
    final double cosR = math.cos(obj.rotation);
    final double sinR = math.sin(obj.rotation);

    final double hw = obj.width / 2;
    final double thick = 0.2; // Ft
    final int slatCount = 10;
    
    final Paint linePaint = Paint()..color = const Color(0xFF5D4037)..style = PaintingStyle.stroke..strokeWidth = 0.5;

    for (int i = 0; i < slatCount; i++) {
      final double lx = -hw + i * (obj.width / (slatCount - 1));
      
      // Slats represented as narrow boxes projecting out
      final double xStart = lx - 0.08;
      final double xEnd = lx + 0.08;
      
      // Calculate corner vertices in 3D space
      final List<Offset> topVerts = [];
      final List<Offset> botVerts = [];

      final double zStart = -thick / 2;
      final double zEnd = thick / 2;

      final corners = [
        Offset(xStart, zStart), Offset(xEnd, zStart),
        Offset(xEnd, zEnd), Offset(xStart, zEnd),
      ];

      for (final c in corners) {
        // Rotate in room space
        final double rx = c.dx * cosR - c.dy * sinR + obj.position.dx;
        final double rz = c.dx * sinR + c.dy * cosR + obj.position.dy;
        
        topVerts.add(_projFt(rx, rz, -halfH, sz));
        botVerts.add(_projFt(rx, rz, halfH, sz));
      }

      // Draw sides of this louver slat
      for (int f = 0; f < 4; f++) {
        final next = (f + 1) % 4;
        final face = [topVerts[f], topVerts[next], botVerts[next], botVerts[f]];
        
        final double shade = 0.4 + 0.6 * ((f + rotationY).abs() % 1.0);
        final Color col = Color.lerp(Colors.black, const Color(0xFF8D6E63), shade)!;
        
        canvas.drawPath(Path()..addPolygon(face, true), Paint()..color = col..style = PaintingStyle.fill);
        canvas.drawPath(Path()..addPolygon(face, true), linePaint);
      }
    }
  }

  void _draw3dSticker(Canvas canvas, CeilingObject obj, Size sz) {
    final double cosR = math.cos(obj.rotation);
    final double sinR = math.sin(obj.rotation);

    final double hw = obj.width / 2;
    final double hh = obj.height / 2;

    // Draw sticker flat plane on wall from ceiling to floor
    final List<Offset> screenPts = [];
    final corners = [
      Offset(-hw, -hh), Offset(hw, -hh),
      Offset(hw, hh), Offset(-hw, hh)
    ];

    for (final c in corners) {
      final double rx = c.dx * cosR + obj.position.dx;
      final double rz = c.dx * sinR + obj.position.dy;
      // Map vertical height
      final double ry = halfH - (c.dy + hh) * (halfH * 2 / (hh * 2));
      screenPts.add(_projFt(rx, rz, ry, sz));
    }

    final Color stickerColor = const Color(0xFF80CBC4).withValues(alpha: 0.85);
    canvas.drawPath(Path()..addPolygon(screenPts, true), Paint()..color = stickerColor..style = PaintingStyle.fill);
    canvas.drawPath(Path()..addPolygon(screenPts, true), Paint()..color = const Color(0xFF004D40)..style = PaintingStyle.stroke..strokeWidth = 1.0);

    // Decorative horizontal strips inside sticker
    for (int i = 1; i <= 3; i++) {
      final double yFract = i / 4;
      final Offset p0 = Offset.lerp(screenPts[0], screenPts[3], yFract)!;
      final Offset p1 = Offset.lerp(screenPts[1], screenPts[2], yFract)!;
      canvas.drawLine(p0, p1, Paint()..color = Colors.white54..strokeWidth = 0.5);
    }
  }

  void _draw3dDoor(Canvas canvas, CeilingObject obj, Size sz) {
    final double cosR = math.cos(obj.rotation);
    final double sinR = math.sin(obj.rotation);

    final double hw = obj.width / 2;
    // 1. Cutout frame
    final Offset tl = _projFt(obj.position.dx - hw * cosR, obj.position.dy - hw * sinR, -halfH + 10.0, sz);
    final Offset tr = _projFt(obj.position.dx + hw * cosR, obj.position.dy + hw * sinR, -halfH + 10.0, sz);
    final Offset bl = _projFt(obj.position.dx - hw * cosR, obj.position.dy - hw * sinR, halfH, sz);
    final Offset br = _projFt(obj.position.dx + hw * cosR, obj.position.dy + hw * sinR, halfH, sz);

    // Draw door frame cutout lines
    final framePaint = Paint()..color = const Color(0xFFD84315)..style = PaintingStyle.stroke..strokeWidth = 3.0;
    canvas.drawPath(Path()..addPolygon([bl, tl, tr, br], false), framePaint);

    // 2. Interactive door panel opened at 45 deg
    final double leafAngle = obj.rotation - math.pi / 4;
    final double lx = -hw * math.cos(leafAngle);
    final double lz = -hw * math.sin(leafAngle);
    
    final Offset doorTop = _projFt(obj.position.dx - hw * cosR + lx * 2, obj.position.dy - hw * sinR + lz * 2, -halfH + 11.0, sz);
    final Offset doorBot = _projFt(obj.position.dx - hw * cosR + lx * 2, obj.position.dy - hw * sinR + lz * 2, halfH, sz);
    final Offset hingeBot = bl;

    // Draw solid door panel
    final doorPath = Path()..addPolygon([hingeBot, doorBot, doorTop, _projFt(obj.position.dx - hw * cosR, obj.position.dy - hw * sinR, -halfH + 11.0, sz)], true);
    canvas.drawPath(doorPath, Paint()..color = const Color(0xEE8D6E63)..style = PaintingStyle.fill);
    canvas.drawPath(doorPath, Paint()..color = const Color(0xFF3E2723)..style = PaintingStyle.stroke..strokeWidth = 1.0);
  }

  void _draw3dWindow(Canvas canvas, CeilingObject obj, Size sz) {
    final double cosR = math.cos(obj.rotation);
    final double sinR = math.sin(obj.rotation);

    final double hw = obj.width / 2;
    // Window sits at standard height (eg. from floor-offset 6ft to 16ft)
    final double topY = -halfH + 14.0;
    final double botY = -halfH + 24.0;

    final Offset tl = _projFt(obj.position.dx - hw * cosR, obj.position.dy - hw * sinR, topY, sz);
    final Offset tr = _projFt(obj.position.dx + hw * cosR, obj.position.dy + hw * sinR, topY, sz);
    final Offset bl = _projFt(obj.position.dx - hw * cosR, obj.position.dy - hw * sinR, botY, sz);
    final Offset br = _projFt(obj.position.dx + hw * cosR, obj.position.dy + hw * sinR, botY, sz);

    // Frame
    final winPath = Path()..addPolygon([bl, tl, tr, br], true);
    canvas.drawPath(winPath, Paint()..color = const Color(0x6680DEEA)..style = PaintingStyle.fill); // glass
    canvas.drawPath(winPath, Paint()..color = const Color(0xFFCFD8DC)..style = PaintingStyle.stroke..strokeWidth = 2.0); // frames

    // Grid divider line
    final Offset midTop = (tl + tr) / 2;
    final Offset midBot = (bl + br) / 2;
    canvas.drawLine(midTop, midBot, Paint()..color = const Color(0xFFCFD8DC)..strokeWidth = 1.2);
  }

  void _draw3dWallFan(Canvas canvas, CeilingObject obj, Size sz) {
    // Wall Fan hanging on wall at ceiling-height offset
    final double fanY = -halfH + 15.0; 
    
    // Bracket
    final Offset bracket = _projFt(obj.position.dx, obj.position.dy, fanY, sz);
    final Offset hub = _projFt(obj.position.dx + 0.8 * math.cos(obj.rotation), obj.position.dy + 0.8 * math.sin(obj.rotation), fanY + 0.6, sz);
    
    canvas.drawLine(bracket, hub, Paint()..color = const Color(0xFF78909C)..strokeWidth = 4.0);

    // Hub Circle
    canvas.drawCircle(hub, 8, Paint()..color = const Color(0xFFCFD8DC));

    // Rotating blades panel
    for (int i = 0; i < 3; i++) {
      final double ang = fanAngle + i * 2 * math.pi / 3;
      final Offset bladeTip = hub + Offset(math.cos(ang) * 16, math.sin(ang) * 16);
      canvas.drawLine(hub, bladeTip, Paint()..color = const Color(0xFF90A4AE)..strokeWidth = 2.5);
    }
  }

  void _draw3dOval(Canvas canvas, CeilingObject obj, Size sz) {
    const int steps = 24;
    final double rx = obj.width / 2;
    final double ry = obj.height / 2;
    final double dy = -halfH + dropH;

    List<Offset> topRing = [], botRing = [];
    List<Offset> ptsFt = [];
    
    for (int i = 0; i <= steps; i++) {
      final double ang = i * 2 * math.pi / steps;
      final double dx = obj.position.dx + math.cos(ang) * rx;
      final double dz = obj.position.dy + math.sin(ang) * ry;
      
      ptsFt.add(Offset(dx, dz));
      topRing.add(_projFt(dx, dz, -halfH, sz));
      botRing.add(_projFt(dx, dz, dy, sz));
    }

    final double opacityVal = showFramework ? 0.45 : 1.0;
    final Paint strokeP = Paint()..color = const Color(0xFFB0BEC5).withValues(alpha: 0.4 * opacityVal)..style = PaintingStyle.stroke..strokeWidth = 0.8;

    // Side cylinder faces
    for (int i = 0; i < steps; i++) {
      final face = [topRing[i], topRing[i+1], botRing[i+1], botRing[i]];
      final double ang = (i + 0.5) * 2 * math.pi / steps;
      final Offset normalFt = Offset(math.cos(ang), math.sin(ang));

      final Color faceColor = _shadeFace(
        verticesFt: [ptsFt[i], ptsFt[i+1]],
        yFt: (-halfH + dropH / 2) * (5.0 / halfH),
        normalFt: normalFt,
        baseColor: const Color(0xFFF5F5F0),
        opacity: opacityVal,
      );
      canvas.drawPath(Path()..addPolygon(face, true), Paint()..color = faceColor..style = PaintingStyle.fill);
      canvas.drawPath(Path()..addPolygon(face, true), strokeP);
    }

    // Bottom face
    final Color bottomColor = _shadeFace(
      verticesFt: ptsFt,
      yFt: dy * (5.0 / halfH),
      normalFt: Offset.zero,
      baseColor: const Color(0xFFFFFFFF),
      opacity: opacityVal,
    );
    canvas.drawPath(Path()..addPolygon(botRing, true), Paint()..color = bottomColor..style = PaintingStyle.fill);
    canvas.drawPath(Path()..addPolygon(botRing, true), strokeP);

    if (obj.hasLedStrip || obj.hasCoveLight) {
      _drawNeonGlow3d(canvas, ptsFt, dy, obj.hasLedStrip, obj.hasCoveLight, sz);
    }
  }

  void _draw3dArc(Canvas canvas, CeilingObject obj, Size sz) {
    if (obj.startPoint == null || obj.endPoint == null) return;
    
    final bool hasCurve = obj.arcCurvature != null && obj.arcCurvature != 0;
    final Offset pcFeet = hasCurve 
        ? getControlPoint(obj.startPoint!, obj.endPoint!, obj.arcCurvature!) 
        : (obj.startPoint! + obj.endPoint!) / 2;
    
    const int steps = 12;
    final List<Offset> ptsFeet = sampleBezier(obj.startPoint!, obj.endPoint!, pcFeet, steps);
    
    const double thick = 1.0; // width of arc drop board
    final List<Offset> outerPtsFt = [];
    final List<Offset> innerPtsFt = [];
    
    for (int i = 0; i <= steps; i++) {
      final Offset p = ptsFeet[i];
      Offset tangent = (i < steps) ? (ptsFeet[i+1] - p) : (p - ptsFeet[i-1]);
      final double tLen = tangent.distance;
      final Offset normal = tLen > 0 ? Offset(-tangent.dy, tangent.dx) / tLen : Offset.zero;
      outerPtsFt.add(p + normal * thick / 2);
      innerPtsFt.add(p - normal * thick / 2);
    }
    
    final List<Offset> outerTop = [], outerBot = [];
    final List<Offset> innerTop = [], innerBot = [];
    
    for (int i = 0; i <= steps; i++) {
      outerTop.add(_projFt(outerPtsFt[i].dx, outerPtsFt[i].dy, -halfH, sz));
      outerBot.add(_projFt(outerPtsFt[i].dx, outerPtsFt[i].dy, -halfH + dropH, sz));
      innerTop.add(_projFt(innerPtsFt[i].dx, innerPtsFt[i].dy, -halfH, sz));
      innerBot.add(_projFt(innerPtsFt[i].dx, innerPtsFt[i].dy, -halfH + dropH, sz));
    }

    final double opacityVal = showFramework ? 0.45 : 1.0;
    final Paint strokeP = Paint()..color = const Color(0xFFB0BEC5).withValues(alpha: 0.4 * opacityVal)..style = PaintingStyle.stroke..strokeWidth = 0.8;
    final double dy = -halfH + dropH;

    // Draw side panel faces
    for (int i = 0; i < steps; i++) {
      final Offset tangent = ptsFeet[i+1] - ptsFeet[i];
      final double tLen = tangent.distance;
      final Offset normal = tLen > 0 ? Offset(-tangent.dy, tangent.dx) / tLen : Offset.zero;

      // Outer side panel
      final Color outerColor = _shadeFace(
        verticesFt: [outerPtsFt[i], outerPtsFt[i+1]],
        yFt: (-halfH + dropH / 2) * (5.0 / halfH),
        normalFt: normal,
        baseColor: const Color(0xFFF5F5F0),
        opacity: opacityVal,
      );
      canvas.drawPath(Path()..addPolygon([outerTop[i], outerTop[i+1], outerBot[i+1], outerBot[i]], true), Paint()..color = outerColor..style = PaintingStyle.fill);
      canvas.drawPath(Path()..addPolygon([outerTop[i], outerTop[i+1], outerBot[i+1], outerBot[i]], true), strokeP);

      // Inner side panel
      final Color innerColor = _shadeFace(
        verticesFt: [innerPtsFt[i], innerPtsFt[i+1]],
        yFt: (-halfH + dropH / 2) * (5.0 / halfH),
        normalFt: -normal,
        baseColor: const Color(0xFFF5F5F0),
        opacity: opacityVal,
      );
      canvas.drawPath(Path()..addPolygon([innerTop[i], innerTop[i+1], innerBot[i+1], innerBot[i]], true), Paint()..color = innerColor..style = PaintingStyle.fill);
      canvas.drawPath(Path()..addPolygon([innerTop[i], innerTop[i+1], innerBot[i+1], innerBot[i]], true), strokeP);
    }

    // Draw bottom face
    final List<Offset> botFace = [...outerBot, ...innerBot.reversed];
    final Color bottomColor = _shadeFace(
      verticesFt: [...outerPtsFt, ...innerPtsFt.reversed],
      yFt: dy * (5.0 / halfH),
      normalFt: Offset.zero,
      baseColor: const Color(0xFFFFFFFF),
      opacity: opacityVal,
    );
    canvas.drawPath(Path()..addPolygon(botFace, true), Paint()..color = bottomColor..style = PaintingStyle.fill);
    canvas.drawPath(Path()..addPolygon(botFace, true), strokeP);

    if (obj.hasLedStrip || obj.hasCoveLight) {
      _drawNeonGlow3d(canvas, outerPtsFt, dy, obj.hasLedStrip, obj.hasCoveLight, sz);
    }
  }

  @override
  bool shouldRepaint(covariant CeilingOrbitPainter old) => true;
}
