import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pcm_wayanad/services/pdf_utils/quotation_builder.dart';
import 'package:pcm_wayanad/models/quotation.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Generate PDF successfully', () async {
    SharedPreferences.setMockInitialValues({
      'bank_upi_id': '9383406185@ybl',
    });
    
    final bytes = await QuotationBuilder.generate(
      clientName: 'Test Client',
      clientLocation: 'Test Location',
      clientPhone: '1234567890',
      unitNumber: 'UNIT-001',
      items: [
        QuotationItem(
          roomName: 'Living Room',
          ceilingType: 'Gypsum Board',
          unit: 'SqFt',
          length: 10,
          width: 12,
          height: 10,
          quantity: 1,
          area: 120,
          rate: 110,
          amount: 13200,
        )
      ],
      materials: [],
      payments: [],
      totalAmount: 13200,
      paidAmount: 0,
      balanceAmount: 13200,
    );

    expect(bytes, isNotNull);
    expect(bytes!.length, greaterThan(0));

    final file = File('test_output.pdf');
    await file.writeAsBytes(bytes);
    debugPrint('Saved PDF to: ${file.absolute.path}');
  });
}