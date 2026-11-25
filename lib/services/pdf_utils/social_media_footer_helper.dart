import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class SocialMediaFooterHelper {
  static Future<pw.Widget?> buildSocialMediaRow({
    required pw.Font font,
    required pw.Font boldFont,
    bool ytEnabled = true,
    String ytUrl = 'https://www.youtube.com/@Perimeteceilingmasters',
    bool fbEnabled = true,
    String fbUrl = 'https://www.facebook.com/share/1A8m5yFFt6/',
    bool igEnabled = true,
    String igUrl = 'https://www.instagram.com/premiumceilingmasters?avpt=bXd6c3dpNGpnamZn',
  }) async {
    final List<pw.Widget> children = [];

    if (ytEnabled && ytUrl.isNotEmpty) {
      children.add(
        pw.UrlLink(
          destination: ytUrl,
          child: pw.Row(
            mainAxisSize: pw.MainAxisSize.min,
            children: [
              pw.Text('YouTube: ', style: pw.TextStyle(font: boldFont, fontSize: 8, color: PdfColors.red700)),
              pw.Text(ytUrl, style: pw.TextStyle(font: font, fontSize: 7.5, color: PdfColors.blue800, decoration: pw.TextDecoration.underline)),
            ],
          ),
        ),
      );
    }

    if (fbEnabled && fbUrl.isNotEmpty) {
      if (children.isNotEmpty) children.add(pw.SizedBox(width: 10));
      children.add(
        pw.UrlLink(
          destination: fbUrl,
          child: pw.Row(
            mainAxisSize: pw.MainAxisSize.min,
            children: [
              pw.Text('Facebook: ', style: pw.TextStyle(font: boldFont, fontSize: 8, color: PdfColors.blue900)),
              pw.Text(fbUrl, style: pw.TextStyle(font: font, fontSize: 7.5, color: PdfColors.blue800, decoration: pw.TextDecoration.underline)),
            ],
          ),
        ),
      );
    }

    if (igEnabled && igUrl.isNotEmpty) {
      if (children.isNotEmpty) children.add(pw.SizedBox(width: 10));
      children.add(
        pw.UrlLink(
          destination: igUrl,
          child: pw.Row(
            mainAxisSize: pw.MainAxisSize.min,
            children: [
              pw.Text('Instagram: ', style: pw.TextStyle(font: boldFont, fontSize: 8, color: PdfColors.purple800)),
              pw.Text(igUrl, style: pw.TextStyle(font: font, fontSize: 7.5, color: PdfColors.blue800, decoration: pw.TextDecoration.underline)),
            ],
          ),
        ),
      );
    }

    if (children.isEmpty) return null;

    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(4),
        border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
      ),
      child: pw.Wrap(
        alignment: pw.WrapAlignment.center,
        spacing: 12,
        runSpacing: 4,
        children: children,
      ),
    );
  }
}
