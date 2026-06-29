import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'workflow_service.dart';
import '../models/quotation.dart';
import 'pdf_utils/quotation_builder.dart';
import 'package:http/http.dart' as http;

/// Handles the two-way contract signing workflow:
class ContractService {
  static final ContractService instance = ContractService._init();
  ContractService._init();

  static const String _baseUrl = 'https://pNZYGMVENSMRZQPOBWTK.supabase.co';
  static const String _anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBuenlnbXZlbnNtcnpxcG9id3RrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODE5NjIwODcsImV4cCI6MjA5NzUzODA4N30.lqCFxRcTGe4xGZ9gT4vYzurfNY-aLQvCL4tLBv9HF0k';

  Map<String, String> get _headers => {
        'apikey': _anonKey,
        'Authorization': 'Bearer $_anonKey',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

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

    // 2. Upload unsigned PDF to Supabase Storage
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final storagePath = 'unsigned/${quotation.unitNumber}_$timestamp.pdf';
    final uploadUrl = '$_baseUrl/storage/v1/object/contracts/$storagePath';

    String? unsignedPdfUrl;
    try {
      final response = await http.put(
        Uri.parse(uploadUrl),
        headers: {
          'apikey': _anonKey,
          'Authorization': 'Bearer $_anonKey',
          'Content-Type': 'application/pdf',
          'x-upsert': 'true',
        },
        body: pdfBytes,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        unsignedPdfUrl = '$_baseUrl/storage/v1/object/public/contracts/$storagePath';
        debugPrint('[ContractService] Unsigned PDF uploaded: $unsignedPdfUrl');
      } else {
        debugPrint('[ContractService] Upload failed ${response.statusCode}: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('[ContractService] Upload exception: $e');
      return null;
    }

    // 3. Create the contracts row
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/rest/v1/contracts'),
        headers: {
          ..._headers,
          'Prefer': 'return=representation',
        },
        body: jsonEncode({
          'unit_number': quotation.unitNumber,
          'client_name': quotation.clientName,
          'client_phone': quotation.clientPhone,
          'unsigned_pdf_url': unsignedPdfUrl,
          'contract_status': 'pending_client_signature',
        }),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        final row = data is List ? data.first : data;
        final token = row['access_token'] as String?;
        debugPrint('[ContractService] Contract row created. Token: $token');
        return token;
      } else {
        debugPrint('[ContractService] DB insert failed ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      debugPrint('[ContractService] DB insert exception: $e');
    }
    return null;
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
      final response = await http.get(Uri.parse(signedPdfUrl));
      if (response.statusCode == 200) {
        return response.bodyBytes;
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
