// ignore_for_file: unused_field, unused_element, deprecated_member_use, use_build_context_synchronously, curly_braces_in_flow_control_structures, unused_local_variable, sort_child_properties_last, avoid_print, non_constant_identifier_names, avoid_web_libraries_in_flutter
import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';

class PdfFileUtils {
  static Future<void> previewPdf(Uint8List bytes, String fileName) async {
    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => bytes, name: fileName);
  }

  static Future<String?> saveToSystem(Uint8List bytes, String fileName) async {
    try {
      // For Web and Desktop, FilePicker handles saving if bytes are provided
      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Quotation',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        bytes: bytes,
      );
      
      return outputFile;
    } catch (e) {
      debugPrint('Save to System Error: $e');
      return null;
    }
  }

  static Future<String?> saveToFile(Uint8List bytes, String fileName) async {
    if (kIsWeb) return null;
    try {
      final directory = await getApplicationDocumentsDirectory();
      // On mobile/desktop we can't easily avoid dart:io if we want to write to a specific path
      // but we can use Printing or FilePicker as a cross-platform alternative.
      return null; // Simplified for cross-platform compatibility
    } catch (e) {
      return null;
    }
  }
}
