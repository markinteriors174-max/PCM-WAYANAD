import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../models/ceiling_object.dart';

import '../utils/bezier_helpers.dart';
import '../utils/component_library.dart';
import '../utils/gltf_parser.dart';

class ArLayoutPainter extends CustomPainter {
  final List<CeilingObject> objects;
  final double roomL;
  final double roomW;
  final double arCeilingHeight;
  final double arRotationYaw;
  final double arOffsetX;
  final double arOffsetY;
  final double arScale;
  final double ambientBrightness;
  final Color ambientColor;
  final double fanAngle;
  final bool downlightsOn;
  final bool coveLightOn;
  final bool depthApiEnabled;

  static const double halfW   = 68.0;
  static const double halfH   = 42.0;
  static const double halfD   = 68.0;
  static const double camDist = 300.0;
  static const double dropH   = 9.0;

  ArLayoutPainter({
    required this.objects,
    required this.roomL,
    required this.roomW,
    required this.arCeilingHeight,
    required this.arRotationYaw,
    required this.arOffsetX,
    required this.arOffsetY,
    required this.arScale,
    required this.ambientBrightness,
    required this.ambientColor,
    required this.fanAngle,
    required this.downlightsOn,
    required this.coveLightOn,
    required this.depthApiEnabled,
  });

  Offset _proj(double x, double y, double z, Size sz) {
    final c = Offset(sz.width / 2, sz.height / 2);
    const double rotationX = 1.25;
    const double rotationY = 0.0; 
    
    final double sx = x * arScale;
    final double sy = y * arScale;
    final double szVal = z * arScale;
    
    final cosY = math.cos(rotationY), sinY = math.sin(rotationY);
    final x1 = sx * cosY - szVal * sinY, z1 = sx * sinY + szVal * cosY;
    final cosX = math.cos(rotationX), sinX = math.sin(rotationX);
    final y2 = sy * cosX - z1 * sinX, z2 = sy * sinX + z1 * cosX;
    
    final s = (camDist) / (z2 + camDist);
    return Offset(c.dx + x1 * s, c.dy + y2 * s);
  }

  Offset _projFt(double xf, double zf, double y3, Size sz) {
    final double cosR = math.cos(arRotationYaw);
    final double sinR = math.sin(arRotationYaw);
    
    final double rx = xf * cosR - zf * sinR;
    final double rz = xf * sinR + zf * cosR;
    
    final double finalX = rx + arOffsetX;
    final double finalZ = rz + arOffsetY;
    
    final double scaleX = finalX * (halfW / (roomL > 0 ? roomL / 2 : 1));
    final double scaleZ = finalZ * (halfD / (roomW > 0 ? roomW / 2 : 1));
    
    final double finalY = y3 + arCeilingHeight * 4.0;
    
    return _proj(scaleX, finalY, scaleZ, sz);
  }

  // Calculate coordinate distance from camera along view axis
  double _getDepth(double xf, double zf, double y3) {
    final double cosR = math.cos(arRotationYaw);
    final double sinR = math.sin(arRotationYaw);
    
    final double rx = xf * cosR - zf * sinR;
    final double rz = xf * sinR + zf * cosR;
    
    final double finalX = rx + arOffsetX;
    final double finalZ = rz + arOffsetY;
    
    final double scaleX = finalX * (halfW / (roomL > 0 ? roomL / 2 : 1));
    final double scaleZ = finalZ * (halfD / (roomW > 0 ? roomW / 2 : 1));
    
    final double finalY = y3 + arCeilingHeight * 4.0;
    
    const double rotationX = 1.25;
    const double rotationY = 0.0;
    
    final double sx = scaleX * arScale;
    final double sy = finalY * arScale;
    final double szVal = scaleZ * arScale;
    
    final cosY = math.cos(rotationY), sinY = math.sin(rotationY);
    final z1 = sx * sinY + szVal * cosY;
    final cosX = math.cos(rotationX), sinX = math.sin(rotationX);
    final double z2 = sy * sinX + z1 * cosX;
    
    return z2 + camDist;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final List<_Drawable> drawables = [];

    // 1. Ceiling Border polygon
    final Offset tl = _projFt(-roomL / 2, -roomW / 2, -halfH, size);
    final Offset tr = _projFt( roomL / 2, -roomW / 2, -halfH, size);
    final Offset br = _projFt( roomL / 2,  roomW / 2, -halfH, size);
    final Offset bl = _projFt(-roomL / 2,  roomW / 2, -halfH, size);
    
    final double borderDepth = (
      _getDepth(-roomL / 2, -roomW / 2, -halfH) +
      _getDepth( roomL / 2, -roomW / 2, -halfH) +
      _getDepth( roomL / 2,  roomW / 2, -halfH) +
      _getDepth(-roomL / 2,  roomW / 2, -halfH)
    ) / 4.0;

    drawables.add(_Drawable(borderDepth, () {
      canvas.drawPath(Path()..addPolygon([tl, tr, br, bl], true), Paint()
        ..color = const Color(0xFFD4AF37).withValues(alpha: 0.1)
        ..style = PaintingStyle.fill);
      canvas.drawPath(Path()..addPolygon([tl, tr, br, bl], true), Paint()
        ..color = const Color(0xFFD4AF37).withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0);
    }));

    // 2. Virtual objects
    for (final obj in objects) {
      double objDepth;
      if (obj.startPoint != null && obj.endPoint != null) {
        objDepth = (_getDepth(obj.startPoint!.dx, obj.startPoint!.dy, -halfH) +
                    _getDepth(obj.endPoint!.dx, obj.endPoint!.dy, -halfH)) / 2.0;
      } else {
        objDepth = _getDepth(obj.position.dx, obj.position.dy, -halfH);
      }
      drawables.add(_Drawable(objDepth, () {
        _draw3dObj(canvas, obj, size);
      }));
    }

    // 3. Physical ceiling fan on site
    final double fanDepth = depthApiEnabled ? _getDepth(0.0, 0.0, -halfH + 4.5) : 99999.0;
    drawables.add(_Drawable(fanDepth, () {
      _drawPhysicalFan(canvas, size);
    }));

    // 4. Physical concrete pillar on site
    final double columnDepth = depthApiEnabled ? _getDepth(roomL / 3.0, roomW / 4.0, 0.0) : 99998.0;
    drawables.add(_Drawable(columnDepth, () {
      _drawPhysicalColumn(canvas, size);
    }));

    // Sort by depth descending: furthest items drawn first
    drawables.sort((a, b) => b.depth.compareTo(a.depth));

    // Execute draw commands
    for (final drawable in drawables) {
      drawable.draw();
    }
  }

  void _draw3dObj(Canvas canvas, CeilingObject obj, Size sz) {
    final Color baseGypsumColor = Color.lerp(const Color(0xFF33302A), const Color(0xFFFFFDF9), ambientBrightness)!;
    final Color blendedGypsum = Color.lerp(baseGypsumColor, ambientColor, 0.25)!;

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

    switch (obj.type) {
      case 'wall_line':
        if (obj.startPoint != null && obj.endPoint != null) {
          final Offset a = _projFt(obj.startPoint!.dx, obj.startPoint!.dy, -halfH, sz);
          final Offset b = _projFt(obj.endPoint!.dx, obj.endPoint!.dy, -halfH, sz);
          final Offset aFloor = _projFt(obj.startPoint!.dx, obj.startPoint!.dy, halfH, sz);
          final Offset bFloor = _projFt(obj.endPoint!.dx, obj.endPoint!.dy, halfH, sz);
          
          canvas.drawPath(Path()..addPolygon([a, b, bFloor, aFloor], true), Paint()..color = const Color(0xFF8D6E63).withValues(alpha: 0.5)..style = PaintingStyle.fill);
          canvas.drawPath(Path()..addPolygon([a, b, bFloor, aFloor], true), Paint()..color = const Color(0xFFD7CCC8).withValues(alpha: 0.8)..style = PaintingStyle.stroke..strokeWidth = 1.0);
        }
        break;

      case 'main_channel':
      case 'cross_channel':
        if (obj.startPoint != null && obj.endPoint != null) {
          final Offset pStart = _projFt(obj.startPoint!.dx, obj.startPoint!.dy, -halfH + 1.0, sz);
          final Offset pEnd = _projFt(obj.endPoint!.dx, obj.endPoint!.dy, -halfH + 1.0, sz);
          canvas.drawLine(pStart, pEnd, Paint()..color = const Color(0xAAFFFFFF)..style = PaintingStyle.stroke..strokeWidth = 1.5);
        }
        break;

      case 'ceiling_grid':
        final double hw = obj.width / 2, hh = obj.height / 2;
        final Offset a = _projFt(obj.position.dx - hw, obj.position.dy - hh, -halfH + 1.5, sz);
        final Offset b = _projFt(obj.position.dx + hw, obj.position.dy - hh, -halfH + 1.5, sz);
        final Offset c = _projFt(obj.position.dx + hw, obj.position.dy + hh, -halfH + 1.5, sz);
        final Offset d = _projFt(obj.position.dx - hw, obj.position.dy + hh, -halfH + 1.5, sz);
        
        canvas.drawPath(Path()..addPolygon([a, b, c, d], true), Paint()..color = blendedGypsum.withValues(alpha: 0.5)..style = PaintingStyle.fill);
        canvas.drawPath(Path()..addPolygon([a, b, c, d], true), Paint()..color = const Color(0xFFB0BEC5)..style = PaintingStyle.stroke..strokeWidth = 1.0);
        break;

      case 'border_profile':
        final double hw = obj.width / 2, hh = obj.height / 2;
        for (int step = 0; step < 2; step++) {
          final double offset = step * 0.4;
          final double hOff = -halfH + (step * 2.5);
          final double wSub = hw - offset;
          final double hSub = hh - offset;
          if (wSub <= 0 || hSub <= 0) break;
          
          final Offset a = _projFt(obj.position.dx - wSub, obj.position.dy - hSub, hOff, sz);
          final Offset b = _projFt(obj.position.dx + wSub, obj.position.dy - hSub, hOff, sz);
          final Offset c = _projFt(obj.position.dx + wSub, obj.position.dy + hSub, hOff, sz);
          final Offset d = _projFt(obj.position.dx - wSub, obj.position.dy + hSub, hOff, sz);
          
          canvas.drawPath(Path()..addPolygon([a, b, c, d], true), Paint()..color = blendedGypsum.withValues(alpha: 0.4)..style = PaintingStyle.fill);
          canvas.drawPath(Path()..addPolygon([a, b, c, d], true), Paint()..color = const Color(0xFFD4AF37).withValues(alpha: 0.8)..style = PaintingStyle.stroke..strokeWidth = 1.2);
        }
        break;

      case 'gypsum_rect':
      case 'ac_vent':
        final double hw = obj.width  / 2, hh = obj.height / 2;
        final Offset a = _projFt(obj.position.dx - hw, obj.position.dy - hh, -halfH, sz);
        final Offset b = _projFt(obj.position.dx + hw, obj.position.dy - hh, -halfH, sz);
        final Offset c = _projFt(obj.position.dx + hw, obj.position.dy + hh, -halfH, sz);
        final Offset d = _projFt(obj.position.dx - hw, obj.position.dy + hh, -halfH, sz);
        final double dy = -halfH + dropH;
        final Offset aD = _projFt(obj.position.dx - hw, obj.position.dy - hh, dy, sz);
        final Offset bD = _projFt(obj.position.dx + hw, obj.position.dy - hh, dy, sz);
        final Offset cD = _projFt(obj.position.dx + hw, obj.position.dy + hh, dy, sz);
        final Offset dD = _projFt(obj.position.dx - hw, obj.position.dy + hh, dy, sz);

        Color objColor = const Color(0xFF00E5FF);
        Color fill3d   = blendedGypsum;
        if (obj.type == 'ac_vent') { objColor = Colors.lightBlueAccent; fill3d = Color.lerp(Colors.lightBlueAccent, blendedGypsum, 0.7)!; }

        final fillP   = Paint()..color = fill3d.withValues(alpha: 0.6)..style = PaintingStyle.fill;
        final strokeP = Paint()..color = objColor.withValues(alpha: 0.85)..style = PaintingStyle.stroke..strokeWidth = 1.2;
        final sideP   = Paint()..color = fill3d.withValues(alpha: 0.3)..style = PaintingStyle.fill;

        canvas.drawPath(Path()..addPolygon([a, b, c, d], true), fillP);
        canvas.drawPath(Path()..addPolygon([a, b, c, d], true), strokeP);

        for (final face in [[a, b, bD, aD], [b, c, cD, bD], [c, d, dD, cD]]) {
          canvas.drawPath(Path()..addPolygon(face, true), sideP);
          canvas.drawPath(Path()..addPolygon(face, true), strokeP..color = objColor.withValues(alpha: 0.45));
        }

        if (obj.type == 'ac_vent') {
          for (int i = 1; i <= 3; i++) {
            final double lx = obj.position.dx - hw + obj.width * i / 4;
            canvas.drawLine(
              _projFt(lx, obj.position.dy - hh, -halfH, sz),
              _projFt(lx, obj.position.dy + hh, -halfH, sz),
              Paint()..color = Colors.lightBlueAccent.withValues(alpha: 0.4)..strokeWidth = 0.8);
          }
        }

        // Apply neon light bindings in AR
        if (obj.type == 'gypsum_rect' && (obj.hasLedStrip || obj.hasCoveLight)) {
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

      case 'gypsum_oval':
        const int segs = 20;
        final double rx = obj.width / 2;
        final double ry = obj.height / 2;
        List<Offset> topRing = [], botRing = [];
        List<Offset> ptsFt = [];
        
        for (int i = 0; i <= segs; i++) {
          final double ang = i * 2 * math.pi / segs;
          final double dx = obj.position.dx + math.cos(ang) * rx;
          final double dz = obj.position.dy + math.sin(ang) * ry;
          ptsFt.add(Offset(dx, dz));
          topRing.add(_projFt(dx, dz, -halfH, sz));
          botRing.add(_projFt(dx, dz, -halfH + dropH, sz));
        }

        final double dy = -halfH + dropH;
        final fillP = Paint()..color = blendedGypsum.withValues(alpha: 0.6)..style = PaintingStyle.fill;
        final strokeP = Paint()..color = const Color(0xFF00E5FF).withValues(alpha: 0.85)..style = PaintingStyle.stroke..strokeWidth = 1.2;
        final sideP = Paint()..color = blendedGypsum.withValues(alpha: 0.3)..style = PaintingStyle.fill;

        canvas.drawPath(Path()..addPolygon(topRing, true), fillP);
        canvas.drawPath(Path()..addPolygon(topRing, true), strokeP);

        for (int i = 0; i < segs; i++) {
          final face = [topRing[i], topRing[i+1], botRing[i+1], botRing[i]];
          canvas.drawPath(Path()..addPolygon(face, true), sideP);
          canvas.drawPath(Path()..addPolygon(face, true), strokeP..color = const Color(0xFF00E5FF).withValues(alpha: 0.45));
        }

        canvas.drawPath(Path()..addPolygon(botRing, true), fillP);
        canvas.drawPath(Path()..addPolygon(botRing, true), strokeP);

        if (obj.hasLedStrip || obj.hasCoveLight) {
          _drawNeonGlow3d(canvas, ptsFt, dy, obj.hasLedStrip, obj.hasCoveLight, sz);
        }
        break;

      case 'gypsum_arc':
        if (obj.startPoint != null && obj.endPoint != null) {
          final bool hasCurve = obj.arcCurvature != null && obj.arcCurvature != 0;
          final Offset pcFeet = hasCurve 
              ? getControlPoint(obj.startPoint!, obj.endPoint!, obj.arcCurvature!) 
              : (obj.startPoint! + obj.endPoint!) / 2;
          
          final int steps = 8;
          final List<Offset> ptsFeet = sampleBezier(obj.startPoint!, obj.endPoint!, pcFeet, steps);
          
          const double thick = 1.0;
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

          final double dy = -halfH + dropH;
          final fillP = Paint()..color = blendedGypsum.withValues(alpha: 0.6)..style = PaintingStyle.fill;
          final strokeP = Paint()..color = const Color(0xFF00E5FF).withValues(alpha: 0.85)..style = PaintingStyle.stroke..strokeWidth = 1.2;
          final sideP = Paint()..color = blendedGypsum.withValues(alpha: 0.3)..style = PaintingStyle.fill;

          for (int i = 0; i < steps; i++) {
            canvas.drawPath(Path()..addPolygon([outerTop[i], outerTop[i+1], outerBot[i+1], outerBot[i]], true), sideP);
            canvas.drawPath(Path()..addPolygon([outerTop[i], outerTop[i+1], outerBot[i+1], outerBot[i]], true), strokeP..color = const Color(0xFF00E5FF).withValues(alpha: 0.4));
            
            canvas.drawPath(Path()..addPolygon([innerTop[i], innerTop[i+1], innerBot[i+1], innerBot[i]], true), sideP);
            canvas.drawPath(Path()..addPolygon([innerTop[i], innerTop[i+1], innerBot[i+1], innerBot[i]], true), strokeP..color = const Color(0xFF00E5FF).withValues(alpha: 0.4));
          }

          final List<Offset> botFace = [...outerBot, ...innerBot.reversed];
          canvas.drawPath(Path()..addPolygon(botFace, true), fillP);
          canvas.drawPath(Path()..addPolygon(botFace, true), strokeP);

          if (obj.hasLedStrip || obj.hasCoveLight) {
            _drawNeonGlow3d(canvas, outerPtsFt, dy, obj.hasLedStrip, obj.hasCoveLight, sz);
          }
        }
        break;

      case 'fan_box':
        final double fanY = -halfH + 4.5;
        final Offset rodTop = _projFt(obj.position.dx, obj.position.dy, -halfH, sz);
        final Offset rodBot = _projFt(obj.position.dx, obj.position.dy, fanY, sz);
        canvas.drawLine(rodTop, rodBot, Paint()..color = const Color(0xFF3E2723)..strokeWidth = 3.5);
        canvas.drawLine(rodTop, rodBot, Paint()..color = const Color(0xFFD4AF37)..strokeWidth = 0.8);
        
        final int circlePoints = 12;
        final double hubRadius = 0.8;
        final double hubThickness = 0.6;
        final List<Offset> hubTopPoints = [];
        final List<Offset> hubBotPoints = [];
        
        for (int i = 0; i < circlePoints; i++) {
          final double ang = i * 2 * math.pi / circlePoints;
          final double dx = obj.position.dx + math.cos(ang) * hubRadius;
          final double dy = obj.position.dy + math.sin(ang) * hubRadius;
          hubTopPoints.add(_projFt(dx, dy, fanY - hubThickness / 2, sz));
          hubBotPoints.add(_projFt(dx, dy, fanY + hubThickness / 2, sz));
        }
        
        for (int i = 0; i < circlePoints; i++) {
          final int next = (i + 1) % circlePoints;
          final face = [hubTopPoints[i], hubTopPoints[next], hubBotPoints[next], hubTopPoints[i]];
          final double ang = (i + 0.5) * 2 * math.pi / circlePoints;
          final double intensity = (0.5 + 0.5 * math.cos(ang)) * ambientBrightness;
          final Color sideColor = Color.lerp(const Color(0xFF3E2723), const Color(0xFFD4AF37), intensity)!;
          canvas.drawPath(Path()..addPolygon(face, true), Paint()..color = sideColor..style = PaintingStyle.fill);
        }
        
        canvas.drawPath(Path()..addPolygon(hubTopPoints, true), Paint()..color = const Color(0xFFD4AF37)..style = PaintingStyle.fill);
        canvas.drawPath(Path()..addPolygon(hubBotPoints, true), Paint()..color = const Color(0xFF3E2723)..style = PaintingStyle.fill);
        
        final double bladeLength = 3.5;
        final double bladeWidth = 0.5;
        
        for (int i = 0; i < 3; i++) {
          final double baseAngle = fanAngle + i * 2 * math.pi / 3;
          final double cosB = math.cos(baseAngle);
          final double sinB = math.sin(baseAngle);
          final double bx = obj.position.dx;
          final double bz = obj.position.dy;
          
          final double x1 = bx + cosB * hubRadius - sinB * (bladeWidth / 2);
          final double z1 = bz + sinB * hubRadius + cosB * (bladeWidth / 2);
          final double y1 = fanY - 0.08;
          
          final double x2 = bx + cosB * hubRadius + sinB * (bladeWidth / 2);
          final double z2 = bz + sinB * hubRadius - cosB * (bladeWidth / 2);
          final double y2 = fanY + 0.08;
          
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
          
          final double shadingVal = (0.5 + 0.5 * math.cos(baseAngle)) * ambientBrightness;
          final Color woodColor = Color.lerp(const Color(0xFF4E342E), const Color(0xFF8D6E63), shadingVal)!;
          
          final bladePath = Path()..addPolygon([p1, p2, p3, p4], true);
          canvas.drawPath(bladePath, Paint()..color = woodColor..style = PaintingStyle.fill);
        }
        break;

      case 'gypsum_circle':
        const int segs = 18;
        List<Offset> topRing = [], botRing = [];
        List<Offset> ptsFt = [];
        for (int i = 0; i <= segs; i++) {
          final double ang = i * 2 * math.pi / segs;
          final double cx = obj.position.dx + math.cos(ang) * obj.width / 2;
          final double cz = obj.position.dy + math.sin(ang) * obj.width / 2;
          ptsFt.add(Offset(cx, cz));
          topRing.add(_projFt(cx, cz, -halfH, sz));
          botRing.add(_projFt(cx, cz, -halfH + dropH, sz));
        }
        canvas.drawPath(Path()..addPolygon(topRing, true), Paint()..color = blendedGypsum.withValues(alpha: 0.5)..style = PaintingStyle.fill);
        canvas.drawPath(Path()..addPolygon(topRing, true), Paint()..color = const Color(0xFF00E5FF).withValues(alpha: 0.8)..style = PaintingStyle.stroke..strokeWidth = 1.0);
        
        if (obj.hasLedStrip || obj.hasCoveLight) {
          _drawNeonGlow3d(canvas, ptsFt, -halfH + dropH, obj.hasLedStrip, obj.hasCoveLight, sz);
        }
        break;

      case 'downlight':
        final Offset lightPos = _projFt(obj.position.dx, obj.position.dy, -halfH, sz);
        if (downlightsOn) {
          canvas.drawCircle(lightPos, 16, Paint()
            ..color = const Color(0xFFFFDD88).withValues(alpha: 0.25)
            ..style = PaintingStyle.fill
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10));
          canvas.drawCircle(lightPos, 4, Paint()..color = const Color(0xFFFFFFFF));
        }
        break;

      case 'profile_light':
        if (obj.startPoint != null && obj.endPoint != null) {
          final Offset pStart = _projFt(obj.startPoint!.dx, obj.startPoint!.dy, -halfH + 0.1, sz);
          final Offset pEnd = _projFt(obj.endPoint!.dx, obj.endPoint!.dy, -halfH + 0.1, sz);
          canvas.drawLine(pStart, pEnd, Paint()
            ..color = const Color(0x66151821)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3.0);
          if (coveLightOn) {
            canvas.drawLine(pStart, pEnd, Paint()
              ..color = const Color(0x4400E5FF)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 7.0
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0));
            canvas.drawLine(pStart, pEnd, Paint()
              ..color = const Color(0xFF00FFD8)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2.5);
            canvas.drawLine(pStart, pEnd, Paint()
              ..color = Colors.white
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.0);
          } else {
            canvas.drawLine(pStart, pEnd, Paint()
              ..color = const Color(0xFF5A5D65)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.5);
          }
        }
        break;
    }
  }

  void _drawPhysicalFan(Canvas canvas, Size sz) {
    final double fanY = -halfH + 4.5;
    final Offset rodTop = _projFt(0.0, 0.0, -halfH, sz);
    final Offset rodBot = _projFt(0.0, 0.0, fanY, sz);
    
    // Draw hanging rod
    canvas.drawLine(rodTop, rodBot, Paint()..color = const Color(0xFF2C3E50)..strokeWidth = 4.5);
    canvas.drawLine(rodTop, rodBot, Paint()..color = const Color(0xFFBDC3C7)..strokeWidth = 1.0);
    
    final int circlePoints = 12;
    final double hubRadius = 1.0;
    final double hubThickness = 0.8;
    final List<Offset> hubTopPoints = [];
    final List<Offset> hubBotPoints = [];
    
    for (int i = 0; i < circlePoints; i++) {
      final double ang = i * 2 * math.pi / circlePoints;
      final double dx = math.cos(ang) * hubRadius;
      final double dy = math.sin(ang) * hubRadius;
      hubTopPoints.add(_projFt(dx, dy, fanY - hubThickness / 2, sz));
      hubBotPoints.add(_projFt(dx, dy, fanY + hubThickness / 2, sz));
    }
    
    for (int i = 0; i < circlePoints; i++) {
      final int next = (i + 1) % circlePoints;
      final face = [hubTopPoints[i], hubTopPoints[next], hubBotPoints[next], hubTopPoints[i]];
      final double ang = (i + 0.5) * 2 * math.pi / circlePoints;
      final double intensity = (0.5 + 0.5 * math.cos(ang)) * ambientBrightness;
      final Color sideColor = Color.lerp(const Color(0xFF2C3E50), const Color(0xFF7F8C8D), intensity)!;
      canvas.drawPath(Path()..addPolygon(face, true), Paint()..color = sideColor..style = PaintingStyle.fill);
    }
    
    canvas.drawPath(Path()..addPolygon(hubTopPoints, true), Paint()..color = const Color(0xFF7F8C8D)..style = PaintingStyle.fill);
    canvas.drawPath(Path()..addPolygon(hubBotPoints, true), Paint()..color = const Color(0xFF2C3E50)..style = PaintingStyle.fill);
    
    final double bladeLength = 4.5;
    final double bladeWidth = 0.7;
    
    for (int i = 0; i < 3; i++) {
      final double baseAngle = fanAngle + i * 2 * math.pi / 3;
      final double cosB = math.cos(baseAngle);
      final double sinB = math.sin(baseAngle);
      
      final double x1 = cosB * hubRadius - sinB * (bladeWidth / 2);
      final double z1 = sinB * hubRadius + cosB * (bladeWidth / 2);
      final double y1 = fanY - 0.1;
      
      final double x2 = cosB * hubRadius + sinB * (bladeWidth / 2);
      final double z2 = sinB * hubRadius - cosB * (bladeWidth / 2);
      final double y2 = fanY + 0.1;
      
      final double x3 = cosB * (hubRadius + bladeLength) + sinB * (bladeWidth / 2);
      final double z3 = sinB * (hubRadius + bladeLength) - cosB * (bladeWidth / 2);
      final double y3 = fanY + 0.15;
      
      final double x4 = cosB * (hubRadius + bladeLength) - sinB * (bladeWidth / 2);
      final double z4 = sinB * (hubRadius + bladeLength) + cosB * (bladeWidth / 2);
      final double y4 = fanY - 0.15;
      
      final Offset p1 = _projFt(x1, z1, y1, sz);
      final Offset p2 = _projFt(x2, z2, y2, sz);
      final Offset p3 = _projFt(x3, z3, y3, sz);
      final Offset p4 = _projFt(x4, z4, y4, sz);
      
      final double shadingVal = (0.5 + 0.5 * math.cos(baseAngle)) * ambientBrightness;
      final Color bladeColor = Color.lerp(const Color(0xFF34495E), const Color(0xFFBDC3C7), shadingVal)!;
      
      canvas.drawPath(Path()..addPolygon([p1, p2, p3, p4], true), Paint()..color = bladeColor..style = PaintingStyle.fill);
      canvas.drawPath(Path()..addPolygon([p1, p2, p3, p4], true), Paint()..color = const Color(0xFF2C3E50)..style = PaintingStyle.stroke..strokeWidth = 0.5);
    }

    final Offset tagPos = _projFt(0.0, 0.0, fanY + 1.5, sz);
    _drawTextTag(canvas, tagPos, "PHYSICAL FAN (ON-SITE)");
  }

  void _drawPhysicalColumn(Canvas canvas, Size sz) {
    final double cx = roomL / 3.0;
    final double cz = roomW / 4.0;
    final double w = 1.6; 
    final double d = 1.6; 
    
    final double xMin = cx - w / 2;
    final double xMax = cx + w / 2;
    final double zMin = cz - d / 2;
    final double zMax = cz + d / 2;
    
    final Offset tfl = _projFt(xMin, zMin, -halfH, sz);
    final Offset tfr = _projFt(xMax, zMin, -halfH, sz);
    final Offset tbr = _projFt(xMax, zMax, -halfH, sz);
    final Offset tbl = _projFt(xMin, zMax, -halfH, sz);
    
    final Offset bfl = _projFt(xMin, zMin, halfH, sz);
    final Offset bfr = _projFt(xMax, zMin, halfH, sz);
    final Offset bbr = _projFt(xMax, zMax, halfH, sz);
    final Offset bbl = _projFt(xMin, zMax, halfH, sz);
    
    final Paint facePaint = Paint()..color = const Color(0xFFBDC3C7).withValues(alpha: 0.85)..style = PaintingStyle.fill;
    final Paint edgePaint = Paint()..color = const Color(0xFF7F8C8D)..strokeWidth = 1.2..style = PaintingStyle.stroke;
    
    canvas.drawPath(Path()..addPolygon([tfl, tfr, bfr, bfl], true), facePaint);
    canvas.drawPath(Path()..addPolygon([tfl, tfr, bfr, bfl], true), edgePaint);
    
    canvas.drawPath(Path()..addPolygon([tfr, tbr, bbr, bfr], true), facePaint..color = const Color(0xFF95A5A6).withValues(alpha: 0.85));
    canvas.drawPath(Path()..addPolygon([tfr, tbr, bbr, bfr], true), edgePaint);
    
    canvas.drawPath(Path()..addPolygon([tbl, tfl, bfl, bbl], true), facePaint..color = const Color(0xFFECF0F1).withValues(alpha: 0.85));
    canvas.drawPath(Path()..addPolygon([tbl, tfl, bfl, bbl], true), edgePaint);

    final Offset tagPos = _projFt(cx, cz, 0.0, sz);
    _drawTextTag(canvas, tagPos, "PHYSICAL COLUMN (ON-SITE)");
  }

  void _drawTextTag(Canvas canvas, Offset pos, String text) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 6.5,
          fontWeight: FontWeight.bold,
          backgroundColor: Colors.transparent,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    
    final double paddingW = 4.0;
    final double paddingH = 2.0;
    final Rect bgRect = Rect.fromLTWH(
      pos.dx - textPainter.width / 2 - paddingW,
      pos.dy - textPainter.height / 2 - paddingH,
      textPainter.width + paddingW * 2,
      textPainter.height + paddingH * 2,
    );
    
    canvas.drawRRect(
      RRect.fromRectAndRadius(bgRect, const Radius.circular(4)),
      Paint()..color = Colors.black87..style = PaintingStyle.fill,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(bgRect, const Radius.circular(4)),
      Paint()..color = const Color(0xFF00FF87).withValues(alpha: 0.5)..strokeWidth = 0.5..style = PaintingStyle.stroke,
    );
    
    textPainter.paint(canvas, Offset(pos.dx - textPainter.width / 2, pos.dy - textPainter.height / 2));
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

    final double opacityVal = 1.0;

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

          final double rx0 = v0x * cosR - v0z * sinR + obj.position.dx;
          final double rz0 = v0x * sinR + v0z * cosR + obj.position.dy;
          final double ry0 = halfH - v0y * (halfH * 2 / 10);

          final double rx1 = v1x * cosR - v1z * sinR + obj.position.dx;
          final double rz1 = v1x * sinR + v1z * cosR + obj.position.dy;
          final double ry1 = halfH - v1y * (halfH * 2 / 10);

          final double rx2 = v2x * cosR - v2z * sinR + obj.position.dx;
          final double rz2 = v2x * sinR + v2z * cosR + obj.position.dy;
          final double ry2 = halfH - v2y * (halfH * 2 / 10);

          final Offset p0 = _projFt(rx0, rz0, ry0, sz);
          final Offset p1 = _projFt(rx1, rz1, ry1, sz);
          final Offset p2 = _projFt(rx2, rz2, ry2, sz);

          final double shade = 0.5 + 0.5 * math.cos(i0.toDouble());
          final Color shadedCol = Color.lerp(Colors.black, baseCol, 0.4 + 0.6 * shade)!;

          canvas.drawPath(Path()..addPolygon([p0, p1, p2], true), Paint()..color = shadedCol..style = PaintingStyle.fill);
          canvas.drawPath(Path()..addPolygon([p0, p1, p2], true), edgePaint);
        }
      }
    }

    if (obj.hasLedStrip || obj.hasCoveLight) {
      final double hw = obj.width / 2;
      final double hh = obj.height / 2;
      final double dy = halfH - 1.0;
      final List<Offset> basePts = [
        Offset(obj.position.dx - hw, obj.position.dy - hh),
        Offset(obj.position.dx + hw, obj.position.dy - hh),
        Offset(obj.position.dx + hw, obj.position.dy + hh),
        Offset(obj.position.dx - hw, obj.position.dy - hh),
        Offset(obj.position.dx - hw, obj.position.dy - hh),
      ];
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
    final double thick = 0.2;
    final int slatCount = 10;
    
    final Paint linePaint = Paint()..color = const Color(0xFF5D4037)..style = PaintingStyle.stroke..strokeWidth = 0.5;

    for (int i = 0; i < slatCount; i++) {
      final double lx = -hw + i * (obj.width / (slatCount - 1));
      final double xStart = lx - 0.08;
      final double xEnd = lx + 0.08;
      
      final List<Offset> topVerts = [];
      final List<Offset> botVerts = [];

      final double zStart = -thick / 2;
      final double zEnd = thick / 2;

      final corners = [
        Offset(xStart, zStart), Offset(xEnd, zStart),
        Offset(xEnd, zEnd), Offset(xStart, zEnd),
      ];

      for (final c in corners) {
        final double rx = c.dx * cosR - c.dy * sinR + obj.position.dx;
        final double rz = c.dx * sinR + c.dy * cosR + obj.position.dy;
        
        topVerts.add(_projFt(rx, rz, -halfH, sz));
        botVerts.add(_projFt(rx, rz, halfH, sz));
      }

      for (int f = 0; f < 4; f++) {
        final next = (f + 1) % 4;
        final face = [topVerts[f], topVerts[next], botVerts[next], botVerts[f]];
        final double shade = 0.4 + 0.6 * ((f).abs() % 1.0);
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

    final List<Offset> screenPts = [];
    final corners = [
      Offset(-hw, -hh), Offset(hw, -hh),
      Offset(hw, hh), Offset(-hw, hh)
    ];

    for (final c in corners) {
      final double rx = c.dx * cosR + obj.position.dx;
      final double rz = c.dx * sinR + obj.position.dy;
      final double ry = halfH - (c.dy + hh) * (halfH * 2 / (hh * 2));
      screenPts.add(_projFt(rx, rz, ry, sz));
    }

    final Color stickerColor = const Color(0xFF80CBC4).withValues(alpha: 0.85);
    canvas.drawPath(Path()..addPolygon(screenPts, true), Paint()..color = stickerColor..style = PaintingStyle.fill);
    canvas.drawPath(Path()..addPolygon(screenPts, true), Paint()..color = const Color(0xFF004D40)..style = PaintingStyle.stroke..strokeWidth = 1.0);

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
    final Offset tl = _projFt(obj.position.dx - hw * cosR, obj.position.dy - hw * sinR, -halfH + 10.0, sz);
    final Offset tr = _projFt(obj.position.dx + hw * cosR, obj.position.dy + hw * sinR, -halfH + 10.0, sz);
    final Offset bl = _projFt(obj.position.dx - hw * cosR, obj.position.dy - hw * sinR, halfH, sz);
    final Offset br = _projFt(obj.position.dx + hw * cosR, obj.position.dy + hw * sinR, halfH, sz);

    final framePaint = Paint()..color = const Color(0xFFD84315)..style = PaintingStyle.stroke..strokeWidth = 3.0;
    canvas.drawPath(Path()..addPolygon([bl, tl, tr, br], false), framePaint);

    final double leafAngle = obj.rotation - math.pi / 4;
    final double lx = -hw * math.cos(leafAngle);
    final double lz = -hw * math.sin(leafAngle);
    
    final Offset doorTop = _projFt(obj.position.dx - hw * cosR + lx * 2, obj.position.dy - hw * sinR + lz * 2, -halfH + 11.0, sz);
    final Offset doorBot = _projFt(obj.position.dx - hw * cosR + lx * 2, obj.position.dy - hw * sinR + lz * 2, halfH, sz);
    final Offset hingeBot = bl;

    final doorPath = Path()..addPolygon([hingeBot, doorBot, doorTop, _projFt(obj.position.dx - hw * cosR, obj.position.dy - hw * sinR, -halfH + 11.0, sz)], true);
    canvas.drawPath(doorPath, Paint()..color = const Color(0xEE8D6E63)..style = PaintingStyle.fill);
    canvas.drawPath(doorPath, Paint()..color = const Color(0xFF3E2723)..style = PaintingStyle.stroke..strokeWidth = 1.0);
  }

  void _draw3dWindow(Canvas canvas, CeilingObject obj, Size sz) {
    final double cosR = math.cos(obj.rotation);
    final double sinR = math.sin(obj.rotation);

    final double hw = obj.width / 2;
    final double topY = -halfH + 14.0;
    final double botY = -halfH + 24.0;

    final Offset tl = _projFt(obj.position.dx - hw * cosR, obj.position.dy - hw * sinR, topY, sz);
    final Offset tr = _projFt(obj.position.dx + hw * cosR, obj.position.dy + hw * sinR, topY, sz);
    final Offset bl = _projFt(obj.position.dx - hw * cosR, obj.position.dy - hw * sinR, botY, sz);
    final Offset br = _projFt(obj.position.dx + hw * cosR, obj.position.dy + hw * sinR, botY, sz);

    final winPath = Path()..addPolygon([bl, tl, tr, br], true);
    canvas.drawPath(winPath, Paint()..color = const Color(0x6680DEEA)..style = PaintingStyle.fill);
    canvas.drawPath(winPath, Paint()..color = const Color(0xFFCFD8DC)..style = PaintingStyle.stroke..strokeWidth = 2.0);

    final Offset midTop = (tl + tr) / 2;
    final Offset midBot = (bl + br) / 2;
    canvas.drawLine(midTop, midBot, Paint()..color = const Color(0xFFCFD8DC)..strokeWidth = 1.2);
  }

  void _draw3dWallFan(Canvas canvas, CeilingObject obj, Size sz) {
    final double fanY = -halfH + 15.0; 
    
    final Offset bracket = _projFt(obj.position.dx, obj.position.dy, fanY, sz);
    final Offset hub = _projFt(obj.position.dx + 0.8 * math.cos(obj.rotation), obj.position.dy + 0.8 * math.sin(obj.rotation), fanY + 0.6, sz);
    
    canvas.drawLine(bracket, hub, Paint()..color = const Color(0xFF78909C)..strokeWidth = 4.0);
    canvas.drawCircle(hub, 8, Paint()..color = const Color(0xFFCFD8DC));

    for (int i = 0; i < 3; i++) {
      final double ang = fanAngle + i * 2 * math.pi / 3;
      final Offset bladeTip = hub + Offset(math.cos(ang) * 16, math.sin(ang) * 16);
      canvas.drawLine(hub, bladeTip, Paint()..color = const Color(0xFF90A4AE)..strokeWidth = 2.5);
    }
  }

  @override
  bool shouldRepaint(covariant ArLayoutPainter old) => true;
}

class _Drawable {
  final double depth;
  final VoidCallback draw;
  _Drawable(this.depth, this.draw);
}
