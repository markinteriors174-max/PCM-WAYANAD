import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'pdf_icons.dart';

class QuotationHeaderBuilder {
  static pw.Widget buildModernHeader(
    pw.MemoryImage? logo,
    pw.MemoryImage? emblem,
    String companyName,
    String tagline, {
    pw.Font? boldFont,
    String? upiId,
    String? unitNumber,
    bool isDispatchList = false,
  }) {
    final hasUpi = upiId != null && upiId.isNotEmpty;
    final hasProject = unitNumber != null && unitNumber.isNotEmpty;
    const double qrSize = 45.0;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Left corner: UPI QR Code or symmetric spacing
            if (hasUpi)
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.BarcodeWidget(
                    barcode: pw.Barcode.qrCode(),
                    data: 'upi://pay?pa=$upiId&pn=${Uri.encodeComponent(companyName)}&cu=INR',
                    width: qrSize,
                    height: qrSize,
                    color: PdfColors.green900,
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    'SCAN TO PAY',
                    style: pw.TextStyle(
                      font: boldFont ?? pw.Font.helveticaBold(),
                      fontSize: 5,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.green900,
                    ),
                  ),
                ],
              )
            else
              pw.SizedBox(width: qrSize, height: qrSize + 7),

            pw.Spacer(),

            // Center Content
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                // Emblem & Registration at the very top - Compressed
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    if (emblem != null) ...[
                      pw.Image(emblem, height: 25),
                      pw.SizedBox(width: 6),
                    ],
                    pw.Text(
                      "MSME Reg No: UDYAM-KL-14-0031878",
                      style: pw.TextStyle(
                        font: boldFont ?? pw.Font.helveticaBold(),
                        fontSize: 8.5,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.brown900,
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 5),
                if (logo != null) pw.Image(logo, height: 40),
                pw.SizedBox(height: 5),
                pw.Text(
                  companyName.toUpperCase(),
                  style: pw.TextStyle(
                    font: boldFont ?? pw.Font.helveticaBold(),
                    fontSize: 22,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.brown900,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  tagline,
                  style: pw.TextStyle(
                    font: pw.Font.timesItalic(),
                    fontSize: 10,
                    color: PdfColors.brown700,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  'MOB: ${PdfIcons.ownerPhone}',
                  style: pw.TextStyle(
                    font: boldFont ?? pw.Font.helveticaBold(),
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
              ],
            ),

            pw.Spacer(),

            // Right corner: Project QR Code or symmetric spacing
            if (hasProject)
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.BarcodeWidget(
                    barcode: pw.Barcode.qrCode(),
                    data: isDispatchList
                        ? 'https://pcmwayanad.com/dispatch/$unitNumber'
                        : 'https://pcmwayanad.com/quotation/$unitNumber',
                    width: qrSize,
                    height: qrSize,
                    color: PdfColors.brown900,
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    isDispatchList ? 'EDIT DISPATCH' : 'VIEW PROJECT',
                    style: pw.TextStyle(
                      font: boldFont ?? pw.Font.helveticaBold(),
                      fontSize: 5,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.brown900,
                    ),
                  ),
                ],
              )
            else
              pw.SizedBox(width: qrSize, height: qrSize + 7),
          ],
        ),
        pw.SizedBox(height: 6),
        pw.Divider(color: PdfColors.brown900, thickness: 1),
      ],
    );
  }

  static pw.Widget buildClientCard({
    required String clientName, required String clientLocation, required String clientPhone,
    required String unitNumber, required double totalArea, required bool includeWastage,
    required pw.Font font, required pw.Font boldFont,
  }) {
    final safeClientName = clientName.trim().isEmpty ? 'SITE DRAFT' : clientName.trim();
    final safeClientLocation = clientLocation.trim().isEmpty ? 'N/A' : clientLocation.trim();
    final safeClientPhone = clientPhone.trim().isEmpty ? 'N/A' : clientPhone.trim();
    final safeUnitNumber = unitNumber.trim().isEmpty ? 'N/A' : unitNumber.trim();
    final safeTotalArea = totalArea.isFinite ? totalArea : 0.0;

    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.brown900, width: 1.5), color: PdfColors.orange50),
      child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
          pw.Text('QUOTATION: $safeUnitNumber', style: pw.TextStyle(font: boldFont, fontSize: 9)),
          pw.Text('DATE: ${DateFormat('dd-MMM-yyyy').format(DateTime.now())}', style: pw.TextStyle(font: font, fontSize: 8)),
        ]),
        pw.SizedBox(height: 4),
        pw.Divider(color: PdfColors.brown200, thickness: 0.5),
        pw.SizedBox(height: 4),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Expanded(child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Text('CLIENT: $safeClientName', style: pw.TextStyle(font: boldFont, fontSize: 10, color: PdfColors.brown900)),
              pw.SizedBox(height: 1),
              pw.Text('Location: $safeClientLocation | Phone: $safeClientPhone', style: pw.TextStyle(font: font, fontSize: 8.5)),
            ])),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              decoration: const pw.BoxDecoration(color: PdfColors.yellow100, borderRadius: pw.BorderRadius.all(pw.Radius.circular(3))),
              child: pw.Row(children: [
                pw.Text(includeWastage ? 'TOTAL AREA (+Wastage): ' : 'TOTAL AREA: ', style: pw.TextStyle(font: boldFont, fontSize: 8, color: PdfColors.grey900)),
                pw.Text('${safeTotalArea.toStringAsFixed(2)} SqFt', style: pw.TextStyle(font: boldFont, fontSize: 10, color: PdfColors.black)),
              ]),
            ),
          ],
        ),
      ]),
    );
  }

  static pw.Widget buildDispatchClientCard({
    required String siteLocation,
    required String clientSite,
    required String contractor,
    required pw.Font font,
    required pw.Font boldFont,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.brown900, width: 1.5), color: PdfColors.orange50),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('MATERIAL DISPATCH LIST', style: pw.TextStyle(font: boldFont, fontSize: 10, color: PdfColors.brown900)),
              pw.Text('DATE: ${DateFormat('dd-MMM-yyyy').format(DateTime.now())}', style: pw.TextStyle(font: font, fontSize: 8)),
            ],
          ),
          pw.SizedBox(height: 4),
          pw.Divider(color: PdfColors.brown200, thickness: 0.5),
          pw.SizedBox(height: 4),
          pw.Text('SITE LOCATION: $siteLocation', style: pw.TextStyle(font: boldFont, fontSize: 8.5)),
          pw.SizedBox(height: 2),
          pw.Text('CLIENT / SITE: $clientSite', style: pw.TextStyle(font: font, fontSize: 8.5)),
          pw.SizedBox(height: 2),
          pw.Text('CONTRACTOR: $contractor', style: pw.TextStyle(font: font, fontSize: 8.5)),
        ],
      ),
    );
  }
}
