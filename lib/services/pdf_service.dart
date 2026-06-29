import 'dart:typed_data';
import '../models/quotation.dart';
import 'pdf_utils/letter_pad_builder.dart';
import 'pdf_utils/pdf_file_utils.dart';
import 'pdf_generation_service.dart';

class PdfService {
  static Future<String?> generateLetterPad({
    required String title,
    required String recipient,
    required String content,
  }) => LetterPadBuilder.generate(
    title: title,
    recipient: recipient,
    content: content,
  );

  static Future<Uint8List?> generateQuotation({
    required String clientName,
    required String clientLocation,
    required String clientPhone,
    required String unitNumber,
    required List<QuotationItem> items,
    required List<MaterialAssignment> materials,
    required List<PaymentRecord> payments,
    required double totalAmount,
    required double paidAmount,
    required double balanceAmount,
    double heightExtra = 0,
    bool includeWastage = false,
    bool includeDigitalSignature = false,
    bool includeBankDetails = false,
    String? revisionNote,
    double? originalAmount,
    String? approvalSignature,
    bool isMaterialList = false,
    String? contractorName,
    String? contractorPhone,
    bool isDispatchList = false,
    double discountPercent = 0,
  }) => PdfGenerationService.generateQuotation(
    clientName: clientName,
    clientLocation: clientLocation,
    clientPhone: clientPhone,
    unitNumber: unitNumber,
    items: items,
    materials: materials,
    payments: payments,
    totalAmount: totalAmount,
    paidAmount: paidAmount,
    balanceAmount: balanceAmount,
    heightExtra: heightExtra,
    includeWastage: includeWastage,
    includeDigitalSignature: includeDigitalSignature,
    includeBankDetails: includeBankDetails,
    revisionNote: revisionNote,
    originalAmount: originalAmount,
    approvalSignature: approvalSignature,
    isMaterialList: isMaterialList,
    contractorName: contractorName,
    contractorPhone: contractorPhone,
    isDispatchList: isDispatchList,
    discountPercent: discountPercent,
  );

  static Future<void> previewPdf(Uint8List bytes, String fileName) =>
      PdfFileUtils.previewPdf(bytes, fileName);

  static Future<String?> saveToSystem(Uint8List bytes, String fileName) =>
      PdfFileUtils.saveToSystem(bytes, fileName);
}

