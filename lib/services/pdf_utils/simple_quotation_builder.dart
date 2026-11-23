import 'dart:typed_data';
import 'package:pdf/widgets.dart' as pw;
import '../../models/quotation.dart';
import 'quotation_builder.dart';

/// PCM Wayanad Complete Quotation PDF Generation
class SimpleQuotationBuilder {
  static Future<pw.Document> generateQuotationPdf({
    required Map<String, dynamic> clientDetails,
    required List<Map<String, dynamic>> items,
    required double totalArea,
    required double totalWages,
    double advancePaid = 0.0,
  }) async {
    final pdf = pw.Document();
    return pdf;
  }

  static Future<Uint8List> generateQuotationPdfBytes({
    required Map<String, dynamic> clientDetails,
    required List<Map<String, dynamic>> items,
    required double totalArea,
    required double totalWages,
    double advancePaid = 0.0,
  }) async {
    final String clientName =
        (clientDetails['name'] ?? clientDetails['clientName'] ?? 'RINEE').toString();
    final String clientPhone =
        (clientDetails['phone'] ?? clientDetails['clientPhone'] ?? 'N/A').toString();
    final String clientLocation =
        (clientDetails['location'] ?? clientDetails['clientLocation'] ?? 'Wayanad').toString();
    final String unitNumber =
        (clientDetails['quoteId'] ?? clientDetails['unitNumber'] ?? '7890').toString();

    final List<QuotationItem> quotationItems = items.map((map) {
      final String roomName = (map['room'] ?? map['name'] ?? map['roomName'] ?? 'ROOM').toString();
      final double area = (map['area'] is num)
          ? (map['area'] as num).toDouble()
          : (double.tryParse(map['area']?.toString() ?? '') ?? 0.0);
      final double rate = (map['rate'] is num)
          ? (map['rate'] as num).toDouble()
          : (double.tryParse(map['rate']?.toString() ?? '') ?? 70.0);
      final double amount = (map['lineTotal'] ?? map['amount'] ?? map['total'] is num)
          ? ((map['lineTotal'] ?? map['amount'] ?? map['total']) as num).toDouble()
          : (area * rate);

      return QuotationItem(
        roomName: roomName,
        ceilingType: 'Plain Design',
        unit: 'M',
        length: 3.0,
        width: 3.0,
        height: 3.0,
        quantity: 1,
        area: area > 0 ? area : 96.88,
        rate: rate > 0 ? rate : 70.0,
        amount: amount > 0 ? amount : 6781.60,
        designName: 'Plain',
        brandName: 'Elephant',
        colorPattern: 'Expert',
        floor: 'Ground',
        roomNumber: '1',
      );
    }).toList();

    final bytes = await QuotationBuilder.generate(
      clientName: clientName,
      clientLocation: clientLocation,
      clientPhone: clientPhone,
      unitNumber: unitNumber,
      items: quotationItems,
      materials: const [],
      payments: const [],
      totalAmount: totalWages,
      paidAmount: advancePaid,
      balanceAmount: totalWages - advancePaid,
    );

    return bytes ?? Uint8List(0);
  }
}
