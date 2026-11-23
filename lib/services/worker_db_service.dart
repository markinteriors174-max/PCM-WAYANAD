import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class WorkerDbService {
  static final WorkerDbService instance = WorkerDbService._init();
  WorkerDbService._init();

  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  Future<List<Map<String, dynamic>>> getSQLiteWorkers() async {
    try {
      final snap = await _firestore.collection('workers').orderBy('worker_name').get();
      return snap.docs.map((doc) => {
        ...doc.data(),
        'id': doc.id,
        'worker_id': doc.id,
      }).toList();
    } catch (e) {
      debugPrint('Error getting workers from Firestore: $e');
      return [];
    }
  }

  Future<int> insertSQLiteWorker(String name, double dailyWage, double totalDays, double totalPaid) async {
    try {
      final docRef = await _firestore.collection('workers').add({
        'worker_name': name,
        'daily_wage': dailyWage,
        'dailyRate': dailyWage,
        'total_days': totalDays,
        'total_paid': totalPaid,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return docRef.id.hashCode.abs();
    } catch (e) {
      debugPrint('Error inserting worker to Firestore: $e');
      return 0;
    }
  }

  Future<int> updateWorkerDays(dynamic id, double totalDays) async {
    try {
      await _firestore.collection('workers').doc(id.toString()).set({
        'total_days': totalDays,
      }, SetOptions(merge: true));
      return 1;
    } catch (e) {
      debugPrint('Error updating worker days in Firestore: $e');
      return 0;
    }
  }

  Future<int> recordWorkerPayment(dynamic id, double paymentAmount) async {
    try {
      final doc = await _firestore.collection('workers').doc(id.toString()).get();
      final double paid = (doc.data()?['total_paid'] as num?)?.toDouble() ?? 0.0;
      await _firestore.collection('workers').doc(id.toString()).set({
        'total_paid': paid + paymentAmount,
      }, SetOptions(merge: true));
      return 1;
    } catch (e) {
      debugPrint('Error recording worker payment in Firestore: $e');
      return 0;
    }
  }

  Future<int> deleteSQLiteWorker(dynamic id) async {
    try {
      await _firestore.collection('workers').doc(id.toString()).delete();
      return 1;
    } catch (e) {
      debugPrint('Error deleting worker from Firestore: $e');
      return 0;
    }
  }
}
