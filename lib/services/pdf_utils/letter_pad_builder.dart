import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../../../utils/platform_utils.dart';

class LetterPadBuilder {
  static Future<String?> generate({
    required String title,
    required String recipient,
    required String content,
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
      final signPath = prefs.getString('signature_path');
      pw.MemoryImage? signature;
      if (!kIsWeb && signPath != null) {
        final bytes = await PlatformUtilsImpl.readFileBytes(signPath);
        if (bytes != null) signature = pw.MemoryImage(bytes);
      }

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (context) => pw.Column(
            children: [
              if (logo != null) pw.Image(logo, width: 100),
              pw.SizedBox(height: 20),
              pw.Text(title.toUpperCase(), style: pw.TextStyle(font: bold, fontSize: 18)),
              pw.SizedBox(height: 20),
              pw.Text('To: $recipient', style: pw.TextStyle(font: regular)),
              pw.SizedBox(height: 10),
              pw.Text('Date: ${DateFormat('dd MMM yyyy').format(DateTime.now())}', style: pw.TextStyle(font: regular)),
              pw.Divider(),
              pw.SizedBox(height: 20),
              pw.Text(content, style: pw.TextStyle(font: regular)),
              pw.Spacer(),
              if (signature != null) pw.Image(signature, width: 100),
              pw.Text('PCM WAYANAD', style: pw.TextStyle(font: bold)),
            ],
          ),
        ),
      );

      final bytes = await pdf.save();
      await Printing.layoutPdf(onLayout: (format) async => bytes, name: 'LetterPad.pdf');
      return 'success';
    } catch (e) {
      debugPrint('LetterPad Error: $e');
      return null;
    }
  }
}
