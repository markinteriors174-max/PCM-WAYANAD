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
    
    final items = [
      QuotationItem(
        roomName: 'Living Room',
        ceilingType: 'Plain Design',
        unit: 'Ft',
        length: 1.3,
        width: 3.2,
        height: 10,
        quantity: 1,
        area: 44.09,
        rate: 70,
        amount: 3086.25,
        colorPattern: 'Expert',
        brandName: 'Saint-Gobain Gyproc (Regular) + kj',
      ),
      QuotationItem(
        roomName: 'Main Living Hall',
        ceilingType: 'Center Design',
        unit: 'Ft',
        length: 3.6,
        width: 1.7,
        height: 10,
        quantity: 1,
        area: 66.24,
        rate: 70,
        amount: 4636.92,
        colorPattern: 'Expert',
        brandName: 'Saint-Gobain Gyproc (Regular) + kj',
        hasCentralDesign: true,
      ),
      QuotationItem(
        roomName: 'Living Room',
        ceilingType: 'Cove Light',
        unit: 'Ft',
        length: 2.4,
        width: 1.2,
        height: 10,
        quantity: 1,
        area: 32.04,
        rate: 70,
        amount: 2242.96,
        colorPattern: 'Warm White (3000K)',
        brandName: 'Saint-Gobain Gyproc (Regular) + k - kj - Standard Medium G.I. (0.45mm)',
        hasCove: true,
      ),
      QuotationItem(
        roomName: 'Living Room',
        ceilingType: 'Plain Design',
        unit: 'Ft',
        length: 2.4,
        width: 0.5,
        height: 10,
        quantity: 1,
        area: 278.42,
        rate: 70,
        amount: 19489.51,
        colorPattern: 'Warm White (3000K)',
        brandName: 'Saint-Gobain Gyproc (Regular) + k - kj - Standard Medium G.I. (0.45mm)',
      ),
    ];

    final bytes = await QuotationBuilder.generate(
      clientName: 'JOSEPH MATHEW',
      clientLocation: 'Pallikkunnu',
      clientPhone: '+91 94979076447',
      unitNumber: '20261117-1622',
      items: items,
      materials: [],
      payments: [],
      totalAmount: 29455.64,
      paidAmount: 0,
      balanceAmount: 29455.64,
    );

    expect(bytes, isNotNull);
    expect(bytes.length, greaterThan(0));

    final pdfStr = String.fromCharCodes(bytes);
    final pageMatches = RegExp(r'/Type\s*/Page\b').allMatches(pdfStr).length;
    debugPrint('Generated PDF Page count: $pageMatches');
    expect(pageMatches, equals(2));

    final file = File('test_output.pdf');
    await file.writeAsBytes(bytes);
    debugPrint('Saved PDF to: ${file.absolute.path}');
  });

  test('Generate PDF without digital signature', () async {
    final items = [
      QuotationItem(
        roomName: 'Living Room',
        ceilingType: 'Plain Design',
        unit: 'Ft',
        length: 1.3,
        width: 3.2,
        height: 10,
        quantity: 1,
        area: 44.09,
        rate: 70,
        amount: 3086.25,
      ),
    ];

    final bytesWithoutSig = await QuotationBuilder.generate(
      clientName: 'JOSEPH MATHEW',
      clientLocation: 'Pallikkunnu',
      clientPhone: '+91 94979076447',
      unitNumber: '20261117-1622',
      items: items,
      materials: [],
      payments: [],
      totalAmount: 3086.25,
      paidAmount: 0,
      balanceAmount: 3086.25,
      includeDigitalSignature: false,
    );

    expect(bytesWithoutSig, isNotNull);
    expect(bytesWithoutSig.length, greaterThan(0));
  });

  test('Generate PDF with payment breakdown and remaining amount', () async {
    final items = [
      QuotationItem(
        roomName: 'Living Room',
        ceilingType: 'Plain Design',
        unit: 'Ft',
        length: 10,
        width: 10,
        height: 10,
        quantity: 1,
        area: 100,
        rate: 100,
        amount: 10000.0,
      ),
    ];

    // Total 10000, Advance 55% = 5500 paid
    final payments = [
      PaymentRecord(
        id: 1,
        quotationId: 1,
        description: 'Advance 55%',
        date: '2026-11-17',
        amount: 5500.0,
      ),
    ];

    final bytesWithPayment = await QuotationBuilder.generate(
      clientName: 'JOSEPH MATHEW',
      clientLocation: 'Pallikkunnu',
      clientPhone: '+91 94979076447',
      unitNumber: '20261117-1622',
      items: items,
      materials: [],
      payments: payments,
      totalAmount: 10000.0,
      paidAmount: 5500.0,
      balanceAmount: 4500.0,
      includeDigitalSignature: true,
    );

    expect(bytesWithPayment, isNotNull);
    expect(bytesWithPayment.length, greaterThan(0));

    final pdfStr = String.fromCharCodes(bytesWithPayment);
    final pageMatches = RegExp(r'/Type\s*/Page\b').allMatches(pdfStr).length;
    expect(pageMatches, equals(2));
  });

  test('Generate PDF with multiple payments in PAYMENT HISTORY LOG', () async {
    final items = [
      QuotationItem(
        roomName: 'Living Room',
        ceilingType: 'Plain Design',
        unit: 'Ft',
        length: 10,
        width: 10,
        height: 10,
        quantity: 1,
        area: 100,
        rate: 100,
        amount: 10000.0,
      ),
    ];

    final payments = [
      PaymentRecord(
        id: 1,
        quotationId: 1,
        description: 'Advance Payment',
        date: '10-11-2026',
        amount: 5500.0,
      ),
      PaymentRecord(
        id: 2,
        quotationId: 1,
        description: 'Sheet Installation',
        date: '15-11-2026',
        amount: 3000.0,
      ),
    ];

    final bytes = await QuotationBuilder.generate(
      clientName: 'JOSEPH MATHEW',
      clientLocation: 'Pallikkunnu',
      clientPhone: '+91 94979076447',
      unitNumber: '20261117-1622',
      items: items,
      materials: [],
      payments: payments,
      totalAmount: 10000.0,
      paidAmount: 8500.0,
      balanceAmount: 1500.0,
      includeDigitalSignature: true,
    );

    expect(bytes, isNotNull);
    final pdfStr = String.fromCharCodes(bytes);
    final pageMatches = RegExp(r'/Type\s*/Page\b').allMatches(pdfStr).length;
    expect(pageMatches, equals(2));
  });

  test('Generate PDF with selected multi-tier estimates and verify 2-page constraint', () async {
    final items = [
      QuotationItem(
        roomName: 'Living Room',
        ceilingType: 'Plain Design',
        unit: 'Ft',
        length: 10,
        width: 10,
        height: 10,
        quantity: 1,
        area: 100,
        rate: 105,
        amount: 10500.0,
      ),
    ];

    final selectedTiers = [
      {'name': 'BASE TIER (₹105 / sq.ft)', 'rate': 105.0},
      {'name': 'PREMIUM TIER (₹120 / sq.ft)', 'rate': 120.0},
      {'name': 'LUXURY TIER (₹145 / sq.ft)', 'rate': 145.0},
    ];

    final bytes = await QuotationBuilder.generate(
      clientName: 'JOSEPH MATHEW',
      clientLocation: 'Pallikkunnu',
      clientPhone: '+91 94979076447',
      unitNumber: '20261117-1622',
      items: items,
      materials: [],
      payments: [],
      totalAmount: 10500.0,
      paidAmount: 0.0,
      balanceAmount: 10500.0,
      includeDigitalSignature: true,
      selectedTiersList: selectedTiers,
    );

    expect(bytes, isNotNull);
    expect(bytes.length, greaterThan(0));
    final pdfStr = String.fromCharCodes(bytes);
    final pageMatches = RegExp(r'/Type\s*/Page\b').allMatches(pdfStr).length;
    debugPrint('PDF with Selected Tiers Page count: $pageMatches');
    expect(pageMatches, equals(2));
  });
}