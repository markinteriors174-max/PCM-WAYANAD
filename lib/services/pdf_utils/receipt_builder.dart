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
  }) async {
    try {
      final pdf = pw.Document();
      final regular = await PdfGoogleFonts.notoSansRegular();
      final bold = await PdfGoogleFonts.notoSansBold();
      
      final logoBytes = await rootBundle.load('assets/images/logo.png');
      final logo = pw.MemoryImage(logoBytes.buffer.asUint8List());

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
                    pw.Image(logo, width: 80),
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
    );
  }

  static pw.Widget _row(pw.Font reg, pw.Font b, String label, String val) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 5),
      child: pw.Row(
        children: [
          pw.SizedBox(width: 150, child: pw.Text(label, style: pw.TextStyle(font: reg))),
          pw.Text(val, style: pw.TextStyle(font: b)),
        ],
      ),
    );
  }
}
