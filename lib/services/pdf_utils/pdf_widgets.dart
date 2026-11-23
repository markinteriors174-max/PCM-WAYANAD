import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class PdfWidgets {
  static pw.Widget tableHeader(
    String text, {
    required pw.Font font,
    PdfColor color = PdfColors.black,
    pw.TextAlign textAlign = pw.TextAlign.left,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Text(
        text,
        softWrap: true,
        textAlign: textAlign,
        style: pw.TextStyle(font: font, fontSize: 8, fontWeight: pw.FontWeight.bold, color: color),
      ),
    );
  }

  static pw.Widget workflowStep(String text, pw.Font font) {
    return pw.Text(
      text,
      style: pw.TextStyle(font: font, fontSize: 8, color: PdfColors.black, fontWeight: pw.FontWeight.bold),
    );
  }

  static pw.Widget tableCell(
    String text, {
    required pw.Font font,
    bool isBold = false,
    double fontSize = 7.5,
    PdfColor color = PdfColors.black,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Text(
        text,
        softWrap: true,
        style: pw.TextStyle(
          font: font,
          fontSize: fontSize,
          color: color,
          fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  static pw.Widget summaryRow(String label, String value, {required pw.Font font, PdfColor color = PdfColors.black, bool isLarge = false}) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(font: font, fontSize: isLarge ? 9 : 8, color: color, fontWeight: pw.FontWeight.bold),
        ),
        pw.Text(
          value,
          style: pw.TextStyle(font: font, fontSize: isLarge ? 12 : 10, fontWeight: pw.FontWeight.bold, color: color),
        ),
      ],
    );
  }
}
