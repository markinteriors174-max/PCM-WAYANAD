import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:shared_preferences/shared_preferences.dart';

class QuotationTermsBuilder {
  static pw.Widget buildTermsAndDetails({
    required SharedPreferences prefs,
    required String companyName,
    required String unitNumber,
    required pw.Font font,
    required pw.Font boldFont,
  }) {
    final aboutUs = (prefs.getString('company_about_us') ?? '').trim().isEmpty 
        ? "PCM Wayanad: Elevating interior elegance with premium materials and artistic precision for over a decade."
        : prefs.getString('company_about_us')!.trim();
    final disclaimer = (prefs.getString('company_disclaimer') ?? '').trim().isEmpty 
        ? 'Note: Ceiling works only. Painting and electrical works excluded.'
        : prefs.getString('company_disclaimer')!.trim();
    final terms = (prefs.getString('company_terms') ?? '').trim().isEmpty 
        ? '1. Valid 30 days. 2. 50% advance. 3. Final payment on completion.'
        : prefs.getString('company_terms')!.trim();
    final upiId = (prefs.getString('bank_upi_id') ?? '').trim();
    final safeCompanyName = companyName.trim().isEmpty ? 'PCM WAYANAD' : companyName.trim();

    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          flex: 4,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              if (aboutUs.isNotEmpty) ...[
                pw.Text('VISION: $aboutUs', style: pw.TextStyle(font: font, fontSize: 7, color: PdfColors.grey700, fontStyle: pw.FontStyle.italic)),
                pw.SizedBox(height: 4),
              ],
              pw.Text('DISCLAIMER: $disclaimer', style: pw.TextStyle(font: font, fontSize: 7, color: PdfColors.grey800)),
              pw.SizedBox(height: 4),
              pw.Text('TERMS: $terms', style: pw.TextStyle(font: font, fontSize: 7, color: PdfColors.grey800)),
            ],
          ),
        ),
        if (upiId.isNotEmpty) ...[
          pw.SizedBox(width: 15),
          pw.Column(
            children: [
              pw.Text('SCAN TO PAY', style: pw.TextStyle(font: boldFont, fontSize: 6, color: PdfColors.green900)),
              pw.SizedBox(height: 2),
              pw.BarcodeWidget(
                barcode: pw.Barcode.qrCode(),
                data: 'upi://pay?pa=$upiId&pn=${Uri.encodeComponent(safeCompanyName)}&cu=INR',
                width: 40, height: 40,
              ),
            ],
          ),
        ],
      ],
    );
  }
}
