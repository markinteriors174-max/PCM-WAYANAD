import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import '../models/quotation.dart';
import 'pdf_utils/quotation_builder.dart';

class PdfGenerationService {
  // REQUIREMENT: 31-day pastel color matrix keyed to DateTime.now().day
  static final List<PdfColor> dayColors = [
    PdfColor.fromInt(0xfffff0f5), // Day 1  — LavenderBlush
    PdfColor.fromInt(0xfff0f8ff), // Day 2  — AliceBlue
    PdfColor.fromInt(0xfff5f5dc), // Day 3  — Beige
    PdfColor.fromInt(0xfffff8dc), // Day 4  — Cornsilk
    PdfColor.fromInt(0xffe0f7fa), // Day 5  — Cyan Tint
    PdfColor.fromInt(0xfffff9e6), // Day 6  — Soft Amber
    PdfColor.fromInt(0xfff0f4f8), // Day 7  — Slate Pastel
    PdfColor.fromInt(0xfffff0f0), // Day 8  — Soft Rose
    PdfColor.fromInt(0xfffaf0e6), // Day 9  — Linen
    PdfColor.fromInt(0xfff3e5f5), // Day 10 — Soft Purple
    PdfColor.fromInt(0xfffff8e1), // Day 11 — Soft Amber
    PdfColor.fromInt(0xffe0ffff), // Day 12 — LightCyan
    PdfColor.fromInt(0xfff5fffa), // Day 13 — MintCream
    PdfColor.fromInt(0xffffe4e1), // Day 14 — MistyRose
    PdfColor.fromInt(0xffFFFacd), // Day 15 — LemonChiffon
    PdfColor.fromInt(0xffffe4b5), // Day 16 — Moccasin Light
    PdfColor.fromInt(0xffffefd5), // Day 17 — PapayaWhip
    PdfColor.fromInt(0xfffff8e7), // Day 18 — Cosmic Latte
    PdfColor.fromInt(0xfff0ffff), // Day 19 — Azure
    PdfColor.fromInt(0xffe8f5e9), // Day 20 — Soft Green
    PdfColor.fromInt(0xffe1f5fe), // Day 21 — Soft Blue
    PdfColor.fromInt(0xfff9fbe7), // Day 22 — Soft Lime
    PdfColor.fromInt(0xfffff5ee), // Day 23 — Seashell
    PdfColor.fromInt(0xfff8f8ff), // Day 24 — GhostWhite
    PdfColor.fromInt(0xfff0fff0), // Day 25 — Honeydew
    PdfColor.fromInt(0xffe6e6fa), // Day 26 — Lavender
    PdfColor.fromInt(0xfffdf5e6), // Day 27 — OldLace
    PdfColor.fromInt(0xfff4f9f4), // Day 28 — Soft Emerald
    PdfColor.fromInt(0xfffafff2), // Day 29 — Light Lime Tint
    PdfColor.fromInt(0xffFFFdf0), // Day 30 — Ivory Premium
    PdfColor.fromInt(0xfffff2f2), // Day 31 — Soft Coral Tint
  ];

  // REQUIREMENT: Light Orange Discount Block color tint
  static const PdfColor discountBgColor = PdfColor.fromInt(0xfffff3e0);

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
  }) => QuotationBuilder.generate(
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
}
