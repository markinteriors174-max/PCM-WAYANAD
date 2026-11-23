// PCM Wayanad - Real-time Two-Way Firestore Sync Integration
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class RealtimeSyncService {
  static final RealtimeSyncService instance = RealtimeSyncService._();
  RealtimeSyncService._();

  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  // Real-time stream to listen for any changes from website or app instantly
  Stream<QuerySnapshot<Map<String, dynamic>>> streamAllAdminData(String collectionName) {
    return _firestore
        .collection(collectionName)
        .snapshots();
  }

  // Real-time single document stream
  Stream<DocumentSnapshot<Map<String, dynamic>>> streamDocument(String collectionName, String docId) {
    return _firestore
        .collection(collectionName)
        .doc(docId)
        .snapshots();
  }

  // Function to push updates from App to Cloud (which will reflect on the Website instantly)
  Future<void> updateDataToCloud(String collectionName, String docId, Map<String, dynamic> updatedData) async {
    try {
      await _firestore.collection(collectionName).doc(docId).set(
        updatedData,
        SetOptions(merge: true),
      );
    } catch (e) {
      debugPrint("RealtimeSync Error: $e");
    }
  }

  // Helper to sync project work stages and payment details
  Future<void> updateProjectStage({
    required String projectId,
    required int stage,
    required String remarks,
    double? totalAmount,
    double? paidAmount,
  }) async {
    final payload = <String, dynamic>{
      'stage': stage,
      'remarks': remarks,
      'lastUpdated': FieldValue.serverTimestamp(),
    };
    if (totalAmount != null) payload['totalAmount'] = totalAmount;
    if (paidAmount != null) {
      payload['paidAmount'] = paidAmount;
      if (totalAmount != null) {
        payload['dueAmount'] = totalAmount - paidAmount;
      }
    }
    await updateDataToCloud('projects', projectId, payload);
    await updateDataToCloud('clients', projectId, payload);
  }
}

