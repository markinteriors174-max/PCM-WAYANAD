import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class PdfIcons {
  static const String ownerPhone = '93 83 40 61 85';

  static pw.Widget buildContactItem(pw.Widget icon, String text, String url, pw.Font font) {
    return pw.UrlLink(
      destination: url,
      child: pw.Row(
        mainAxisSize: pw.MainAxisSize.min,
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          icon,
          pw.SizedBox(width: 4),
          pw.Text(text, style: pw.TextStyle(font: font, fontSize: 8, color: PdfColors.blue800)),
        ],
      ),
    );
  }

  /// Safe text-based phone icon
  static pw.Widget phoneIcon() {
    return pw.Text('T:', style: pw.TextStyle(fontSize: 8, color: PdfColors.blue800, font: pw.Font.helveticaBold()));
  }

  /// Safe text-based email icon
  static pw.Widget emailIcon() {
    return pw.Text('E:', style: pw.TextStyle(fontSize: 8, color: PdfColors.blue800, font: pw.Font.helveticaBold()));
  }

  /// Safe text-based instagram icon
  static pw.Widget instaIcon() {
    return pw.Text('IG', style: pw.TextStyle(fontSize: 7, color: PdfColors.blue800, font: pw.Font.helveticaBold()));
  }

  /// Safe text-based facebook icon
  static pw.Widget fbIcon(pw.Font boldFont) {
    return pw.Text('FB', style: pw.TextStyle(font: boldFont, fontSize: 7, color: PdfColors.blue800));
  }
}
