import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'pdf_icons.dart';

class QuotationFooterBuilder {
  static pw.Widget buildRevisionNote(String? note, double? original, double total, pw.Font font, pw.Font boldFont, NumberFormat currencyFormat) {
    if (note == null || note.trim().isEmpty) return pw.SizedBox.shrink();
    final double safeOriginal = (original != null && original.isFinite) ? original : 0.0;
    final double safeTotal = total.isFinite ? total : 0.0;
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.brown500, width: 1.5), color: PdfColors.orange50),
      child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Text('NOTE ON COST VARIATION', style: pw.TextStyle(font: boldFont, fontSize: 10, color: PdfColors.brown900, letterSpacing: 1)),
        pw.SizedBox(height: 5),
        pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
          pw.Text('Initial Estimate:', style: pw.TextStyle(font: font, fontSize: 9)),
          pw.Text(original != null ? currencyFormat.format(safeOriginal) : 'N/A', style: pw.TextStyle(font: boldFont, fontSize: 9)),
        ]),
        pw.SizedBox(height: 2),
        pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
          pw.Text('Revised Estimate:', style: pw.TextStyle(font: font, fontSize: 9)),
          pw.Text(currencyFormat.format(safeTotal), style: pw.TextStyle(font: boldFont, fontSize: 9)),
        ]),
        pw.SizedBox(height: 5),
        pw.Divider(color: PdfColors.brown200, thickness: 0.5),
        pw.SizedBox(height: 5),
        pw.Text('Reason for Variation: ${note.trim()}', style: pw.TextStyle(font: font, fontSize: 9, fontStyle: pw.FontStyle.italic)),
      ]),
    );
  }

  static pw.Widget buildRepeatingFooter(
    pw.Context context,
    String companyName,
    pw.Font font,
    pw.Font boldFont, {
    String? bankName,
    String? accountName,
    String? accountNumber,
    String? ifsc,
    String? upiId,
    bool includeBankDetails = false,
    pw.MemoryImage? signatureImage,
  }) {
    final safeCompanyName = companyName.trim().isEmpty ? 'PREMIUM CEILING MASTER | WAYANAD' : companyName.trim();
    return pw.Column(children: [
      pw.Divider(color: PdfColors.brown200, thickness: 0.5),
      pw.SizedBox(height: 5),
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Prepared By:', style: pw.TextStyle(font: font, fontSize: 7.5, color: PdfColors.grey700)),
                pw.SizedBox(height: 2),
                pw.Text(safeCompanyName, style: pw.TextStyle(font: boldFont, fontSize: 9.5, color: PdfColors.brown900)),
                pw.SizedBox(height: 1),
                pw.Text('Proprietor, Premium Ceiling Master | Wayanad', style: pw.TextStyle(font: font, fontSize: 7.5, color: PdfColors.grey700)),
              ],
            ),
            pw.SizedBox(height: 4),
            // CONTACT DETAILS (Repeats on all pages)
            pw.Row(
              children: [
                PdfIcons.buildContactItem(PdfIcons.phoneIcon(), 'Mob: 93 83 40 61 85', 'tel:9383406185', font),
                pw.SizedBox(width: 8),
                PdfIcons.buildContactItem(PdfIcons.emailIcon(), 'Email: MARKINTERIOR174@GMAIL.COM', 'mailto:MARKINTERIOR174@GMAIL.COM', font),
              ],
            ),
            if (includeBankDetails && ((accountNumber != null && accountNumber.isNotEmpty) || (upiId != null && upiId.isNotEmpty)))
              pw.Container(
                margin: const pw.EdgeInsets.only(top: 5),
                padding: const pw.EdgeInsets.all(6),
                decoration: pw.BoxDecoration(
                  color: const PdfColor.fromInt(0xfff5f5f5),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                  border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('BANK DETAILS & PAYMENT', style: pw.TextStyle(font: boldFont, fontSize: 7, color: PdfColors.brown900, letterSpacing: 0.8)),
                    pw.SizedBox(height: 3),
                    if (accountNumber != null && accountNumber.isNotEmpty) ...[
                      pw.Text('A/C Name: ${accountName ?? ""}', style: pw.TextStyle(font: font, fontSize: 7, color: PdfColors.grey800)),
                      pw.Row(
                        children: [
                          pw.Text('Bank: ${bankName ?? ""}  |  ', style: pw.TextStyle(font: font, fontSize: 7, color: PdfColors.grey800)),
                          pw.Text('IFSC: ${ifsc ?? ""}', style: pw.TextStyle(font: font, fontSize: 7, color: PdfColors.grey800)),
                        ],
                      ),
                      pw.SizedBox(height: 1),
                      pw.Text('A/C No: $accountNumber', style: pw.TextStyle(font: boldFont, fontSize: 7.5, color: PdfColors.black)),
                    ],
                    if (upiId != null && upiId.isNotEmpty) ...[
                      pw.SizedBox(height: 2),
                      pw.Text('UPI ID: $upiId', style: pw.TextStyle(font: boldFont, fontSize: 7.5, color: PdfColors.black)),
                    ],
                  ],
                ),
              ),
          ]),
        ],
      ),
    ]);
  }

  static pw.Widget buildFinalSignatures(
    pw.Font font,
    pw.Font boldFont, {
    pw.MemoryImage? sealImage,
    pw.MemoryImage? signatureImage,
    pw.MemoryImage? clientSignatureImage,
  }) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.end,
      children: [
        // Left: Client Approval (Requested to be empty/awaiting)
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Container(
              height: 40,
              width: 110,
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300, style: pw.BorderStyle.dashed),
              ),
              alignment: pw.Alignment.center,
              child: pw.Text('Awaiting Signature', 
                style: pw.TextStyle(font: font, fontSize: 7.5, color: PdfColors.grey500, fontStyle: pw.FontStyle.italic)),
            ),
            pw.SizedBox(height: 2),
            pw.Text('Client Digital Approval', 
              style: pw.TextStyle(font: font, fontSize: 7.5, color: PdfColors.black, fontStyle: pw.FontStyle.italic)),
          ],
        ),
        // Right: Authorized Signatory (Proprietor Signature)
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            if (signatureImage != null)
              pw.Container(
                height: 45,
                child: pw.Image(signatureImage, width: 100, fit: pw.BoxFit.contain),
              ),
            pw.Text('Authorized Signatory', 
              style: pw.TextStyle(font: font, fontSize: 7.5, color: PdfColors.black, fontStyle: pw.FontStyle.italic)),
            pw.SizedBox(height: 2),
            if (sealImage != null) ...[
              pw.Image(sealImage, width: 55, height: 55),
              pw.SizedBox(height: 2),
            ],
            pw.Text('Madhusudhan', 
              style: pw.TextStyle(font: boldFont, fontSize: 9.5, color: PdfColors.black)),
          ],
        ),
      ],
    );
  }
}
