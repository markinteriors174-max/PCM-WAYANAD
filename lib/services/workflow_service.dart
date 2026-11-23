import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Service for all advanced workflow operations backed exclusively by Firebase Firestore:
///   - Client extensions (email, GSTIN, payment due, discount)
///   - Stage-wise progress tracker
///   - Change orders
///   - Payment receipts
///   - GPS site visit logging
///   - Contract operations
///   - Site expenses
class WorkflowService {
  static final WorkflowService instance = WorkflowService._init();
  WorkflowService._init();

  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  // ── STORAGE HELPER ─────────────────────────────────────────────
  Future<String?> _uploadToStorage(String bucket, String path, Uint8List bytes, String contentType) async {
    try {
      final base64Data = 'data:$contentType;base64,${base64Encode(bytes)}';
      return base64Data;
    } catch (e) {
      debugPrint('[WorkflowService] Base64 conversion exception: $e');
      return null;
    }
  }

  // ══════════════════════════════════════════════════════════════
  //  CLIENT EXTENSIONS
  // ══════════════════════════════════════════════════════════════

  Future<Map<String, dynamic>?> loadClientExtensions(String unitNumber) async {
    try {
      final doc = await _firestore.collection('client_extensions').doc(unitNumber).get();
      if (doc.exists && doc.data() != null) {
        return doc.data();
      }
    } catch (e) {
      debugPrint('[WorkflowService] loadClientExtensions error: $e');
    }
    return null;
  }

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
  }) async {
    try {
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

      await _firestore.collection('client_extensions').doc(unitNumber).set(data, SetOptions(merge: true));
      return true;
    } catch (e) {
      debugPrint('[WorkflowService] saveClientExtensions error: $e');
      return false;
    }
  }

  // ══════════════════════════════════════════════════════════════
  //  STAGE PROGRESS TRACKER
  // ══════════════════════════════════════════════════════════════

  Future<List<Map<String, dynamic>>> loadStages(String unitNumber) async {
    try {
      final snap = await _firestore
          .collection('project_stages')
          .where('unit_number', isEqualTo: unitNumber)
          .get();
      return snap.docs.map((d) => d.data()).toList();
    } catch (e) {
      debugPrint('[WorkflowService] loadStages error: $e');
      return [];
    }
  }

  Future<bool> saveStageProgress(String unitNumber, Map<String, int> stages) async {
    try {
      for (final entry in stages.entries) {
        final docId = '${unitNumber}_${entry.key.replaceAll(' ', '_')}';
        await _firestore.collection('project_stages').doc(docId).set({
          'unit_number': unitNumber,
          'stage_name': entry.key,
          'completion_percent': entry.value,
          'updated_by': 'admin',
          'updated_at': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
      return true;
    } catch (e) {
      debugPrint('[WorkflowService] saveStageProgress error: $e');
      return false;
    }
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
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final path = 'change_orders/${unitNumber}_$timestamp.pdf';
      final pdfUrl = await _uploadToStorage('contracts', path, pdfBytes, 'application/pdf');

      final payload = {
        'unit_number': unitNumber,
        'description': description,
        'extra_amount': extraAmount,
        'pdf_url': pdfUrl,
        'created_at': DateTime.now().toIso8601String(),
      };

      final ref = await _firestore.collection('change_orders').add(payload);
      return {...payload, 'id': ref.id};
    } catch (e) {
      debugPrint('[WorkflowService] createChangeOrder error: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getChangeOrders(String unitNumber) async {
    try {
      final snap = await _firestore
          .collection('change_orders')
          .where('unit_number', isEqualTo: unitNumber)
          .orderBy('created_at', descending: true)
          .get();
      return snap.docs.map((d) => {...d.data(), 'id': d.id}).toList();
    } catch (e) {
      debugPrint('[WorkflowService] getChangeOrders error: $e');
      return [];
    }
  }

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
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final receiptNumber = 'PCM-RCP-${DateTime.now().year}-$timestamp';
      final path = 'receipts/${unitNumber}_$timestamp.pdf';
      final pdfUrl = await _uploadToStorage('contracts', path, receiptPdfBytes, 'application/pdf');

      final payload = {
        'unit_number': unitNumber,
        'receipt_number': receiptNumber,
        'amount_received': amountReceived,
        'total_paid_to_date': totalPaidToDate,
        'balance_remaining': balanceRemaining,
        'payment_date': DateTime.now().toIso8601String().split('T').first,
        'payment_mode': paymentMode,
        'notes': notes,
        'receipt_pdf_url': pdfUrl,
        'created_at': DateTime.now().toIso8601String(),
      };

      final ref = await _firestore.collection('payment_receipts').add(payload);
      return {...payload, 'id': ref.id};
    } catch (e) {
      debugPrint('[WorkflowService] createPaymentReceipt error: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getPaymentReceipts(String unitNumber) async {
    try {
      final snap = await _firestore
          .collection('payment_receipts')
          .where('unit_number', isEqualTo: unitNumber)
          .orderBy('created_at', descending: true)
          .get();
      return snap.docs.map((d) => {...d.data(), 'id': d.id}).toList();
    } catch (e) {
      debugPrint('[WorkflowService] getPaymentReceipts error: $e');
      return [];
    }
  }

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
    try {
      await _firestore.collection('site_visits').add({
        'unit_number': unitNumber,
        'admin_user': 'admin',
        'latitude': latitude,
        'longitude': longitude,
        'action_type': actionType,
        'action_detail': actionDetail,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('[WorkflowService] logSiteVisit error: $e');
    }
  }

  // ══════════════════════════════════════════════════════════════
  //  CONTRACT
  // ══════════════════════════════════════════════════════════════

  Future<Map<String, dynamic>?> getContract(String unitNumber) async {
    try {
      final doc = await _firestore.collection('contracts').doc(unitNumber).get();
      if (doc.exists && doc.data() != null) {
        return {...doc.data()!, 'id': doc.id};
      }
      final snap = await _firestore
          .collection('contracts')
          .where('unit_number', isEqualTo: unitNumber)
          .limit(1)
          .get();
      if (snap.docs.isNotEmpty) {
        return {...snap.docs.first.data(), 'id': snap.docs.first.id};
      }
    } catch (e) {
      debugPrint('[WorkflowService] getContract error: $e');
    }
    return null;
  }

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
    try {
      final data = {
        'project_id': unitNumber,
        'expense_type': expenseType,
        'custom_category': customCategory,
        'amount': amount,
        'remarks': remarks,
        'created_at': DateTime.now().toIso8601String(),
      };
      await _firestore.collection('expenses').add(data);
      return true;
    } catch (e) {
      debugPrint('[WorkflowService] addSiteExpense error: $e');
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getSiteExpenses(String unitNumber) async {
    try {
      final snap = await _firestore
          .collection('expenses')
          .where('project_id', isEqualTo: unitNumber)
          .orderBy('created_at', descending: true)
          .get();
      return snap.docs.map((d) => {...d.data(), 'id': d.id}).toList();
    } catch (e) {
      debugPrint('[WorkflowService] getSiteExpenses error: $e');
      return [];
    }
  }

  Future<bool> updateSiteExpense(dynamic id, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('expenses').doc(id.toString()).update(data);
      return true;
    } catch (e) {
      debugPrint('[WorkflowService] updateSiteExpense error: $e');
      return false;
    }
  }

  Future<bool> deleteSiteExpense(dynamic id) async {
    try {
      await _firestore.collection('expenses').doc(id.toString()).delete();
      return true;
    } catch (e) {
      debugPrint('[WorkflowService] deleteSiteExpense error: $e');
      return false;
    }
  }
}
