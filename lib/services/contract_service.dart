import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'workflow_service.dart';
import '../models/quotation.dart';
import 'pdf_utils/quotation_builder.dart';
import 'package:http/http.dart' as http;

/// Handles the two-way contract signing workflow via Firebase Firestore:
class ContractService {
  static final ContractService instance = ContractService._init();
  ContractService._init();

  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  // ══════════════════════════════════════════════════════════════
  //  STEP 1: Admin uploads unsigned PDF + creates contracts row
  // ══════════════════════════════════════════════════════════════

  Future<String?> uploadUnsignedContract(Quotation quotation) async {
    // 1. Generate PDF bytes using the existing builder
    final pdfBytes = await QuotationBuilder.generate(
      clientName: quotation.clientName,
      clientLocation: quotation.clientLocation,
      clientPhone: quotation.clientPhone,
      unitNumber: quotation.unitNumber,
      items: quotation.items,
      materials: quotation.materials,
      payments: quotation.payments,
      totalAmount: quotation.totalAmount,
      paidAmount: quotation.paidAmount,
      balanceAmount: quotation.balanceAmount,
      includeWastage: quotation.includeWastage,
      revisionNote: quotation.revisionNote,
      originalAmount: quotation.originalAmount,
    );

    if (pdfBytes == null) {
      debugPrint('[ContractService] PDF generation failed');
      return null;
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final token = 'token_${quotation.unitNumber}_$timestamp';
    final base64Pdf = 'data:application/pdf;base64,${base64Encode(pdfBytes)}';

    // 2. Create the contract in Firestore
    try {
      await _firestore.collection('contracts').doc(quotation.unitNumber).set({
        'unit_number': quotation.unitNumber,
        'client_name': quotation.clientName,
        'client_phone': quotation.clientPhone,
        'unsigned_pdf_url': base64Pdf,
        'contract_status': 'pending_client_signature',
        'access_token': token,
        'created_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      debugPrint('[ContractService] Contract row created in Firestore. Token: $token');
      return token;
    } catch (e) {
      debugPrint('[ContractService] Firestore contract insert exception: $e');
      return null;
    }
  }

  // ══════════════════════════════════════════════════════════════
  //  SHAREABLE URL
  // ══════════════════════════════════════════════════════════════

  String buildClientSigningUrl(String accessToken) =>
      'https://pcmwayanad.com/contract/$accessToken';

  Future<void> shareContractLink(String accessToken, String clientName) async {
    final url = buildClientSigningUrl(accessToken);
    final text =
        'Hello $clientName,\n\n'
        'Your PCM Wayanad project contract is ready for your review and digital signature.\n\n'
        '📄 Please open the link below to view and approve:\n$url\n\n'
        'Thank you!\n— PCM WAYANAD Team';
    await Share.share(text, subject: 'PCM Wayanad — Contract for Signature');
  }

  // ══════════════════════════════════════════════════════════════
  //  STATUS POLLING
  // ══════════════════════════════════════════════════════════════

  Future<Map<String, dynamic>?> getContract(String unitNumber) =>
      WorkflowService.instance.getContract(unitNumber);

  Future<bool> isContractSigned(String unitNumber) async {
    final contract = await getContract(unitNumber);
    return contract?['contract_status'] == 'signed_by_client';
  }

  // ══════════════════════════════════════════════════════════════
  //  STEP 4: Admin downloads / opens signed PDF
  // ══════════════════════════════════════════════════════════════

  Future<Uint8List?> downloadSignedPdf(String signedPdfUrl) async {
    try {
      if (signedPdfUrl.startsWith('data:application/pdf;base64,')) {
        return base64Decode(signedPdfUrl.split(',').last);
      }
      if (signedPdfUrl.startsWith('http')) {
        final response = await http.get(Uri.parse(signedPdfUrl));
        if (response.statusCode == 200) {
          return response.bodyBytes;
        }
      }
    } catch (e) {
      debugPrint('[ContractService] Download signed PDF failed: $e');
    }
    return null;
  }

  Future<void> openSignedContract(String signedPdfUrl, String unitNumber) async {
    final bytes = await downloadSignedPdf(signedPdfUrl);
    if (bytes == null) return;
    await Printing.layoutPdf(
      onLayout: (_) async => bytes,
      name: 'SignedContract_$unitNumber.pdf',
    );
  }
}
