import 'package:flutter/material.dart';

class CrossSectionPainter extends CustomPainter {
  final double roomL;
  final double roomW;

  CrossSectionPainter({required this.roomL, required this.roomW});

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), Paint()..color = const Color(0xFF0C0E14));

    final gridP = Paint()..color = const Color(0xFF1E293B).withValues(alpha: 0.35)..strokeWidth = 0.5;
    for (double x = 0; x < w; x += 15) {
      canvas.drawLine(Offset(x, 0), Offset(x, h), gridP);
    }
    for (double y = 0; y < h; y += 15) {
      canvas.drawLine(Offset(0, y), Offset(w, y), gridP);
    }

    final roofP = Paint()..color = const Color(0xFF37474F);
    canvas.drawRect(Rect.fromLTWH(20, 20, w - 40, 15), roofP);
    final hatchP = Paint()..color = Colors.white24..strokeWidth = 1.0;
    for (double x = 30; x < w - 30; x += 30) {
      canvas.drawLine(Offset(x, 20), Offset(x - 10, 35), hatchP);
    }

    final wallP = Paint()..color = const Color(0xFF263238);
    canvas.drawRect(Rect.fromLTWH(0, 20, 20, h - 40), wallP);
    canvas.drawRect(Rect.fromLTWH(w - 20, 20, 20, h - 40), wallP);

    final hangerP = Paint()..color = const Color(0xFF90A4AE)..strokeWidth = 1.2;
    final double mainChannelY = 90.0;
    canvas.drawLine(Offset(w * 0.25, 35), Offset(w * 0.25, mainChannelY), hangerP);
    canvas.drawLine(Offset(w * 0.75, 35), Offset(w * 0.75, mainChannelY), hangerP);

    final mainP = Paint()..color = const Color(0xFFB0BEC5)..style = PaintingStyle.fill;
    final mainStroke = Paint()..color = Colors.white70..style = PaintingStyle.stroke..strokeWidth = 0.8;
    final rectMain1 = Rect.fromCenter(center: Offset(w * 0.25, mainChannelY), width: 16, height: 10);
    final rectMain2 = Rect.fromCenter(center: Offset(w * 0.75, mainChannelY), width: 16, height: 10);
    canvas.drawRect(rectMain1, mainP);
    canvas.drawRect(rectMain1, mainStroke);
    canvas.drawRect(rectMain2, mainP);
    canvas.drawRect(rectMain2, mainStroke);

    final crossY = mainChannelY + 12;
    final crossP = Paint()..color = const Color(0xFF78909C)..strokeWidth = 4.0;
    canvas.drawLine(Offset(20, crossY), Offset(w - 20, crossY), crossP);
    
    for (double cx = 50; cx < w - 50; cx += 50) {
      final rectCross = Rect.fromCenter(center: Offset(cx, crossY), width: 10, height: 6);
      canvas.drawRect(rectCross, Paint()..color = const Color(0xFFCFD8DC));
      canvas.drawRect(rectCross, Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 0.5);
    }

    final periP = Paint()..color = const Color(0xFFFFD54F)..strokeWidth = 2.0;
    canvas.drawLine(Offset(20, crossY - 2), Offset(35, crossY - 2), periP);
    canvas.drawLine(Offset(20, crossY - 2), Offset(20, crossY - 14), periP);
    canvas.drawLine(Offset(w - 20, crossY - 2), Offset(w - 35, crossY - 2), periP);
    canvas.drawLine(Offset(w - 20, crossY - 2), Offset(w - 20, crossY - 14), periP);

    final double sheetY = crossY + 5;
    final double sheetH = 8.0; 
    final sheetP = Paint()..color = const Color(0xFFECEFF1)..style = PaintingStyle.fill;
    final sheetOutline = Paint()..color = const Color(0xFFB0BEC5)..style = PaintingStyle.stroke..strokeWidth = 0.5;
    
    final double jointX = w / 2;
    final rectSheetLeft = Rect.fromLTRB(20, sheetY, jointX - 1.5, sheetY + sheetH);
    final rectSheetRight = Rect.fromLTRB(jointX + 1.5, sheetY, w - 20, sheetY + sheetH);
    canvas.drawRect(rectSheetLeft, sheetP);
    canvas.drawRect(rectSheetLeft, sheetOutline);
    canvas.drawRect(rectSheetRight, sheetP);
    canvas.drawRect(rectSheetRight, sheetOutline);

    final jointCompP = Paint()..color = const Color(0xFF80DEEA)..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(jointX, sheetY + 2), 3, jointCompP);

    _label(canvas, "Concrete Roof Slab", Offset(w * 0.5, 27), Colors.white70, true);
    
    _pointer(canvas, Offset(w * 0.25 - 10, 60), Offset(w * 0.25, 60));
    _label(canvas, "Hanger Rod", Offset(w * 0.25 - 15, 56), const Color(0xFFCFD8DC), false);

    _pointer(canvas, Offset(w * 0.25 - 20, mainChannelY), Offset(w * 0.25 - 8, mainChannelY));
    _label(canvas, "Main Channel (0.8mm GI)", Offset(w * 0.25 - 24, mainChannelY - 4), const Color(0xFFCFD8DC), false);

    _pointer(canvas, Offset(w * 0.75 + 20, crossY), Offset(w * 0.75 + 5, crossY));
    _label(canvas, "Cross Stud (0.5mm GI)", Offset(w * 0.75 + 24, crossY - 4), const Color(0xFFCFD8DC), true);

    _pointer(canvas, Offset(50, crossY - 10), Offset(22, crossY - 10));
    _label(canvas, "Perimeter Angle (24x24mm)", Offset(54, crossY - 14), const Color(0xFFFFD54F), true);

    _pointer(canvas, Offset(jointX + 30, sheetY + 18), Offset(jointX + 20, sheetY + 4));
    _label(canvas, "Gypsum Board (12.5mm)", Offset(jointX + 34, sheetY + 14), Colors.white, true);

    _pointer(canvas, Offset(jointX - 30, sheetY + 18), Offset(jointX, sheetY + 2));
    _label(canvas, "Mesh Taped Joint", Offset(jointX - 34, sheetY + 14), const Color(0xFF80DEEA), false);
  }

  void _pointer(Canvas canvas, Offset textEnd, Offset target) {
    final p = Paint()..color = const Color(0xFFD4AF37)..strokeWidth = 0.8..style = PaintingStyle.stroke;
    canvas.drawLine(textEnd, target, p);
    canvas.drawCircle(target, 2, Paint()..color = const Color(0xFFD4AF37));
  }

  void _label(Canvas canvas, String text, Offset pos, Color color, bool leftAlign) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: TextStyle(color: color, fontSize: 7.5, fontWeight: FontWeight.bold)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, pos - Offset(leftAlign ? 0 : tp.width, tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant CrossSectionPainter old) => false;
}
