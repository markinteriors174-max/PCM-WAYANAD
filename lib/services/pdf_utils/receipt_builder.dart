import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../../../utils/platform_utils.dart';

class ReceiptBuilder {
  static Future<Uint8List?> generate({
    required String clientName,
    required String unitNumber,
    required double amount,
    required String paymentMode,
    required String receiptNo,
    String? notes,
    double? totalPaidToDate,
    double? balanceRemaining,
  }) async {
    try {
      final pdf = pw.Document();
      pw.Font regular;
      pw.Font bold;
      try {
        regular = await PdfGoogleFonts.notoSansRegular().timeout(const Duration(seconds: 3));
        bold = await PdfGoogleFonts.notoSansBold().timeout(const Duration(seconds: 3));
      } catch (_) {
        regular = pw.Font.helvetica();
        bold = pw.Font.helveticaBold();
      }
      
      pw.MemoryImage? logo;
      try {
        final logoBytes = await rootBundle.load('assets/images/logo.png');
        logo = pw.MemoryImage(logoBytes.buffer.asUint8List());
      } catch (_) {}

      final prefs = await SharedPreferences.getInstance();
      final sealPath = prefs.getString('seal_path');
      pw.MemoryImage? seal;
      if (!kIsWeb && sealPath != null) {
        final bytes = await PlatformUtilsImpl.readFileBytes(sealPath);
        if (bytes != null) seal = pw.MemoryImage(bytes);
      }

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (context) => pw.Container(
            padding: const pw.EdgeInsets.all(40),
            decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey, width: 2)),
            child: pw.Column(
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    logo != null ? pw.Image(logo, width: 80) : pw.SizedBox(),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text('PAYMENT RECEIPT', style: pw.TextStyle(font: bold, fontSize: 20)),
                        pw.Text('No: $receiptNo', style: pw.TextStyle(font: regular)),
                      ],
                    ),
                  ],
                ),
                pw.Divider(thickness: 2),
                pw.SizedBox(height: 30),
                _row(regular, bold, 'Client Name:', clientName),
                _row(regular, bold, 'Site ID:', unitNumber),
                _row(regular, bold, 'Date:', DateFormat('dd-MM-yyyy').format(DateTime.now())),
                _row(regular, bold, 'Amount Received:', 'INR ${amount.toStringAsFixed(2)}'),
                _row(regular, bold, 'Payment Mode:', paymentMode),
                if (totalPaidToDate != null)
                  _row(regular, bold, 'Total Paid to Date:', 'INR ${totalPaidToDate.toStringAsFixed(2)}'),
                if (balanceRemaining != null)
                  _row(regular, bold, 'BALANCE REMAINING:', 'INR ${balanceRemaining.toStringAsFixed(2)}', isBalance: true),
                if (notes != null) _row(regular, bold, 'Notes:', notes),
                pw.Spacer(),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      children: [
                        if (seal != null) pw.Image(seal, width: 70),
                        pw.Text('AUTHORIZED SEAL', style: pw.TextStyle(font: regular, fontSize: 8)),
                      ],
                    ),
                    pw.Column(
                      children: [
                        pw.SizedBox(height: 50, width: 120, child: pw.Divider()),
                        pw.Text('RECEIVER SIGNATURE', style: pw.TextStyle(font: regular, fontSize: 8)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

      return await pdf.save();
    } catch (e) {
      debugPrint('Receipt Error: $e');
      return null;
    }
  }

  static Future<Uint8List?> generateBytes({
    required String receiptNumber,
    required String unitNumber,
    required String clientName,
    required String clientPhone,
    required double amountReceived,
    required double totalPaidToDate,
    required double balanceRemaining,
    String paymentMode = 'Cash',
    String? notes,
  }) async {
    return generate(
      clientName: clientName,
      unitNumber: unitNumber,
      amount: amountReceived,
      paymentMode: paymentMode,
      receiptNo: receiptNumber,
      notes: notes,
      totalPaidToDate: totalPaidToDate,
      balanceRemaining: balanceRemaining,
    );
  }

  static pw.Widget _row(pw.Font reg, pw.Font b, String label, String val, {bool isBalance = false}) {
    return pw.Padding(
      padding: pw.EdgeInsets.symmetric(vertical: isBalance ? 8 : 5),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: 160,
            child: pw.Text(
              label,
              style: pw.TextStyle(
                font: isBalance ? b : reg,
                fontSize: isBalance ? 13 : 10,
                color: isBalance ? PdfColors.red900 : PdfColors.black,
              ),
            ),
          ),
          pw.Text(
            val,
            style: pw.TextStyle(
              font: b,
              fontSize: isBalance ? 18 : 12,
              color: isBalance ? PdfColors.red900 : PdfColors.black,
            ),
          ),
        ],
      ),
    );
  }
}
