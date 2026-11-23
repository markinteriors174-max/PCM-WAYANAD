import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class LoadedFonts {
  final pw.Font regular;
  final pw.Font bold;
  final pw.Font malayalam;
  final pw.Font emoji;

  LoadedFonts({
    required this.regular,
    required this.bold,
    required this.malayalam,
    required this.emoji,
  });
}

class RoomColorSpec {
  final PdfColor bgTint;
  final PdfColor border;
  final PdfColor accent;
  final PdfColor primary;

  const RoomColorSpec({
    required this.bgTint,
    required this.border,
    required this.accent,
    required this.primary,
  });
}

class PdfImageHelper {
  static Future<LoadedFonts> loadFonts() async {
    try {
      final regular = await PdfGoogleFonts.notoSansRegular().timeout(const Duration(seconds: 3));
      final bold = await PdfGoogleFonts.notoSansBold().timeout(const Duration(seconds: 3));
      pw.Font malayalam;
      try {
        malayalam = await PdfGoogleFonts.notoSansMalayalamRegular().timeout(const Duration(seconds: 3));
      } catch (_) {
        malayalam = regular;
      }
      pw.Font emoji;
      try {
        emoji = await PdfGoogleFonts.notoColorEmoji().timeout(const Duration(seconds: 3));
      } catch (_) {
        emoji = regular;
      }
      return LoadedFonts(regular: regular, bold: bold, malayalam: malayalam, emoji: emoji);
    } catch (_) {
      final helvetica = pw.Font.helvetica();
      final helveticaBold = pw.Font.helveticaBold();
      return LoadedFonts(regular: helvetica, bold: helveticaBold, malayalam: helvetica, emoji: helvetica);
    }
  }

  static Future<pw.MemoryImage?> loadLogo() async {
    try {
      final bytes = await rootBundle.load('assets/images/logo.png');
      return pw.MemoryImage(bytes.buffer.asUint8List());
    } catch (_) {
      return null;
    }
  }

  static Future<pw.MemoryImage?> loadAssetImage(String path) async {
    try {
      final bytes = await rootBundle.load(path);
      return pw.MemoryImage(bytes.buffer.asUint8List());
    } catch (_) {
      return null;
    }
  }
}
