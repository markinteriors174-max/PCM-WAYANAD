import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Service for all advanced workflow operations:
///   - Client extensions (email, GSTIN, payment due, discount)
///   - Stage-wise progress tracker
///   - Change orders (create + poll approval)
///   - Payment receipts (create row after PDF upload)
///   - GPS site visit logging
///   - Contract operations (upload unsigned, poll status, download signed)
class WorkflowService {
  static final WorkflowService instance = WorkflowService._init();
  WorkflowService._init();

  static const String _baseUrl     = 'https://pNZYGMVENSMRZQPOBWTK.supabase.co';
  static const String _anonKey     = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBuenlnbXZlbnNtcnpxcG9id3RrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODE5NjIwODcsImV4cCI6MjA5NzUzODA4N30.lqCFxRcTGe4xGZ9gT4vYzurfNY-aLQvCL4tLBv9HF0k2';

  // ── HELPERS ────────────────────────────────────────────────────

  Map<String, String> get _headers => {
        'apikey': _anonKey,
        'Authorization': 'Bearer $_anonKey',
        'Content-Type': 'application/json',
      };

  Future<Map<String, dynamic>?> _get(String path) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/rest/v1/$path'), headers: {
        ..._headers,
        'Accept': 'application/json',
      });
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(response.body);
        if (decoded is List && decoded.isNotEmpty) return Map<String, dynamic>.from(decoded.first);
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      }
    } catch (e) {
      debugPrint('[WorkflowService] GET $path failed: $e');
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> _getList(String path) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/rest/v1/$path'), headers: {
        ..._headers,
        'Accept': 'application/json',
      });
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(response.body);
        if (decoded is List) return decoded.map((e) => Map<String, dynamic>.from(e)).toList();
      }
    } catch (e) {
      debugPrint('[WorkflowService] GET LIST $path failed: $e');
    }
    return [];
  }

  Future<bool> _upsert(String table, Map<String, dynamic> data, {String? onConflict}) async {
    try {
      final headers = {
        ..._headers,
        'Prefer': 'resolution=merge-duplicates',
      };
      if (onConflict != null) {
        headers['Prefer'] = 'resolution=merge-duplicates,on_conflict=$onConflict';
      }
      final response = await http.post(
        Uri.parse('$_baseUrl/rest/v1/$table'),
        headers: headers,
        body: jsonEncode(data),
      );
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      debugPrint('[WorkflowService] UPSERT $table failed: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> _insert(String table, Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/rest/v1/$table'),
        headers: {
          ..._headers,
          'Prefer': 'return=representation',
        },
        body: jsonEncode(data),
      );
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(response.body);
        if (decoded is List && decoded.isNotEmpty) return Map<String, dynamic>.from(decoded.first);
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      } else {
        debugPrint('[WorkflowService] INSERT $table failed (${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      debugPrint('[WorkflowService] INSERT $table exception: $e');
    }
    return null;
  }

  Future<bool> _patchWhere(String table, String filter, Map<String, dynamic> data) async {
    try {
      final response = await http.patch(
        Uri.parse('$_baseUrl/rest/v1/$table?$filter'),
        headers: _headers,
        body: jsonEncode(data),
      );
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      debugPrint('[WorkflowService] PATCH $table failed: $e');
      return false;
    }
  }

  Future<bool> _deleteWhere(String table, String filter) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/rest/v1/$table?$filter'),
        headers: _headers,
      );
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      debugPrint('[WorkflowService] DELETE $table failed: $e');
      return false;
    }
  }

  /// Upload bytes to Supabase Storage. Returns public URL or null.
  Future<String?> _uploadToStorage(String bucket, String path, Uint8List bytes, String contentType) async {
    try {
      final uploadUrl = '$_baseUrl/storage/v1/object/$bucket/$path';
      final response = await http.put(
        Uri.parse(uploadUrl),
        headers: {
          'apikey': _anonKey,
          'Authorization': 'Bearer $_anonKey',
          'Content-Type': contentType,
          'x-upsert': 'true',
        },
        body: bytes,
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return '$_baseUrl/storage/v1/object/public/$bucket/$path';
      }
      debugPrint('[WorkflowService] Storage upload failed ${response.statusCode}: ${response.body}');
    } catch (e) {
      debugPrint('[WorkflowService] Storage upload exception: $e');
    }
    return null;
  }

  // ══════════════════════════════════════════════════════════════
  //  CLIENT EXTENSIONS
  // ══════════════════════════════════════════════════════════════

  Future<Map<String, dynamic>?> loadClientExtensions(String unitNumber) =>
      _get('client_extensions?unit_number=eq.$unitNumber&select=*');

  Future<bool> saveClientExtensions(String unitNumber, {
    String? email,
    String? customerType,
    bool? gstEnabled,
    String? gstin,
    DateTime? nextPaymentDueDate,
    double? discountAmount,
    String? discountNote,
    String? upiId,
    String? bankName,
    String? accountNumber,
    String? ifscCode,
  }) {
    final data = <String, dynamic>{'unit_number': unitNumber};
    if (email != null)              data['email']                  = email;
    if (customerType != null)       data['customer_type']          = customerType;
    if (gstEnabled != null)         data['gstin_enabled']          = gstEnabled;
    if (gstin != null)              data['gstin']                  = gstin;
    if (nextPaymentDueDate != null) data['next_payment_due_date']  = nextPaymentDueDate.toIso8601String().split('T').first;
    if (discountAmount != null)     data['discount_amount']        = discountAmount;
    if (discountNote != null)       data['discount_note']          = discountNote;
    if (upiId != null)              data['upi_id']                 = upiId;
    if (bankName != null)           data['bank_name']              = bankName;
    if (accountNumber != null)      data['account_number']         = accountNumber;
    if (ifscCode != null)           data['ifsc_code']              = ifscCode;
    return _upsert('client_extensions', data, onConflict: 'unit_number');
  }

  // ══════════════════════════════════════════════════════════════
  //  STAGE PROGRESS TRACKER
  // ══════════════════════════════════════════════════════════════

  Future<List<Map<String, dynamic>>> loadStages(String unitNumber) =>
      _getList('project_stages?unit_number=eq.$unitNumber&select=stage_name,completion_percent,updated_at&order=updated_at.asc');

  Future<bool> saveStageProgress(String unitNumber, Map<String, int> stages) async {
    bool allOk = true;
    for (final entry in stages.entries) {
      final ok = await _upsert('project_stages', {
        'unit_number': unitNumber,
        'stage_name': entry.key,
        'completion_percent': entry.value,
        'updated_by': 'admin',
      }, onConflict: 'unit_number,stage_name');
      if (!ok) allOk = false;
    }
    return allOk;
  }

  // ══════════════════════════════════════════════════════════════
  //  CHANGE ORDERS
  // ══════════════════════════════════════════════════════════════

  Future<Map<String, dynamic>?> createChangeOrder({
    required String unitNumber,
    required String description,
    required double extraAmount,
    required Uint8List pdfBytes,
  }) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final path = 'change_orders/${unitNumber}_$timestamp.pdf';
    final pdfUrl = await _uploadToStorage('contracts', path, pdfBytes, 'application/pdf');

    return _insert('change_orders', {
      'unit_number': unitNumber,
      'description': description,
      'extra_amount': extraAmount,
      'pdf_url': pdfUrl,
    });
  }

  Future<List<Map<String, dynamic>>> getChangeOrders(String unitNumber) =>
      _getList('change_orders?unit_number=eq.$unitNumber&select=*&order=created_at.desc');

  // ══════════════════════════════════════════════════════════════
  //  PAYMENT RECEIPTS
  // ══════════════════════════════════════════════════════════════

  Future<Map<String, dynamic>?> createPaymentReceipt({
    required String unitNumber,
    required double amountReceived,
    required double totalPaidToDate,
    required double balanceRemaining,
    required Uint8List receiptPdfBytes,
    String paymentMode = 'Cash',
    String? notes,
  }) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final receiptNumber = 'PCM-RCP-${DateTime.now().year}-$timestamp';
    final path = 'receipts/${unitNumber}_$timestamp.pdf';
    final pdfUrl = await _uploadToStorage('contracts', path, receiptPdfBytes, 'application/pdf');

    return _insert('payment_receipts', {
      'unit_number': unitNumber,
      'receipt_number': receiptNumber,
      'amount_received': amountReceived,
      'total_paid_to_date': totalPaidToDate,
      'balance_remaining': balanceRemaining,
      'payment_date': DateTime.now().toIso8601String().split('T').first,
      'payment_mode': paymentMode,
      'notes': notes,
      'receipt_pdf_url': pdfUrl,
    });
  }

  Future<List<Map<String, dynamic>>> getPaymentReceipts(String unitNumber) =>
      _getList('payment_receipts?unit_number=eq.$unitNumber&select=*&order=created_at.desc');

  // ══════════════════════════════════════════════════════════════
  //  GPS SITE VISIT LOGGING
  // ══════════════════════════════════════════════════════════════

  Future<void> logSiteVisit({
    required String unitNumber,
    required double latitude,
    required double longitude,
    String actionType = 'manual_checkin',
    String? actionDetail,
  }) async {
    await _insert('site_visits', {
      'unit_number': unitNumber,
      'admin_user': 'admin',
      'latitude': latitude,
      'longitude': longitude,
      'action_type': actionType,
      'action_detail': actionDetail,
    });
  }

  // ══════════════════════════════════════════════════════════════
  //  CONTRACT
  // ══════════════════════════════════════════════════════════════

  Future<Map<String, dynamic>?> getContract(String unitNumber) =>
      _get('contracts?unit_number=eq.$unitNumber&select=*&order=created_at.desc&limit=1');

  Future<Map<String, dynamic>> pollProjectData(String unitNumber) async {
    final results = await Future.wait([
      getContract(unitNumber),
      getChangeOrders(unitNumber),
      getPaymentReceipts(unitNumber),
      loadStages(unitNumber),
      loadClientExtensions(unitNumber),
    ]);
    return {
      'contract':        results[0],
      'changeOrders':    results[1],
      'paymentReceipts': results[2],
      'stages':          results[3],
      'extensions':      results[4],
    };
  }

  // ══════════════════════════════════════════════════════════════
  //  SITE EXPENSES
  // ══════════════════════════════════════════════════════════════

  Future<bool> addSiteExpense({
    required String unitNumber,
    required String expenseType,
    required double amount,
    required String remarks,
    String? customCategory,
  }) async {
    final data = {
      'project_id': unitNumber,
      'expense_type': expenseType,
      'custom_category': customCategory,
      'amount': amount,
      'remarks': remarks,
      'created_at': DateTime.now().toIso8601String(),
    };
    final res = await _insert('expenses', data);
    return res != null;
  }

  Future<List<Map<String, dynamic>>> getSiteExpenses(String unitNumber) =>
      _getList('expenses?project_id=eq.$unitNumber&order=created_at.desc');

  Future<bool> updateSiteExpense(int id, Map<String, dynamic> data) =>
      _patchWhere('expenses', 'id=eq.$id', data);

  Future<bool> deleteSiteExpense(int id) =>
      _deleteWhere('expenses', 'id=eq.$id');
}
