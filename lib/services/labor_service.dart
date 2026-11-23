import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/labor_models.dart';

class LaborService {
  static final LaborService instance = LaborService._init();
  LaborService._init();

  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  Stream<List<Worker>> getWorkers() {
    return _firestore
        .collection('workers')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Worker.fromMap(doc.data(), doc.id))
            .toList());
  }

  Future<void> addWorker(Worker worker) async {
    try {
      if (worker.id.isNotEmpty) {
        await _firestore.collection('workers').doc(worker.id).set(worker.toMap());
      } else {
        await _firestore.collection('workers').add(worker.toMap());
      }
    } catch (e) {
      debugPrint('Error adding worker: $e');
    }
  }

  Future<void> deleteWorker(String workerId) async {
    try {
      await _firestore.collection('workers').doc(workerId).delete();
    } catch (e) {
      debugPrint('Error deleting worker: $e');
    }
  }

  Future<void> updateWorkerRate(String workerId, double rate) async {
    try {
      await _firestore.collection('workers').doc(workerId).update({'dailyRate': rate});
    } catch (e) {
      debugPrint('Error updating worker rate: $e');
    }
  }

  Future<void> updateWorkerRating(String workerId, double rating) async {
    try {
      await _firestore.collection('workers').doc(workerId).update({'rating': rating});
    } catch (e) {
      debugPrint('Error updating worker rating: $e');
    }
  }

  Future<void> updateWorkerHomeLocation(String workerId, double lat, double lng) async {
    try {
      await _firestore.collection('workers').doc(workerId).update({'homeLat': lat, 'homeLng': lng});
    } catch (e) {
      debugPrint('Error updating worker home location: $e');
    }
  }

  Future<void> addWorkerAdvance(AdvancePayment advance) async {
    try {
      await _firestore.collection('worker_advances').add(advance.toMap());
    } catch (e) {
      debugPrint('Error adding worker advance: $e');
    }
  }

  Future<void> deleteWorkerAdvance(String advanceId) async {
    try {
      await _firestore.collection('worker_advances').doc(advanceId).delete();
    } catch (e) {
      debugPrint('Error deleting worker advance: $e');
    }
  }

  Future<void> checkInWorker({
    required String workerId,
    required String workerName,
    required String siteId,
    required String siteName,
    required ShiftType shiftType,
    double? lat,
    double? lng,
    double? workerHomeLat,
    double? workerHomeLng,
  }) async {
    try {
      final entry = {
        'workerId': workerId,
        'workerName': workerName,
        'siteId': siteId,
        'siteName': siteName,
        'mode': 'daily',
        'shiftType': shiftType.name,
        'status': 'active',
        'checkInTime': DateTime.now().toIso8601String(),
        'checkInLat': lat,
        'checkInLng': lng,
        'date': DateTime.now().toIso8601String().split('T').first,
      };

      await _firestore.collection('labor_logs').add(entry);
    } catch (e) {
      debugPrint('Error checking in worker: $e');
    }
  }

  Future<void> checkOutWorker({
    required String entryId,
    double paidAmount = 0,
  }) async {
    try {
      final checkOutTime = DateTime.now();
      await _firestore.collection('labor_logs').doc(entryId).update({
        'status': 'completed',
        'checkOutTime': checkOutTime.toIso8601String(),
        'paidAmount': paidAmount,
      });
    } catch (e) {
      debugPrint('Error checking out worker: $e');
    }
  }

  Stream<List<LaborEntry>> getActiveShifts(String workerId) {
    return _firestore
        .collection('labor_logs')
        .where('workerId', isEqualTo: workerId)
        .where('status', isEqualTo: 'active')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => LaborEntry.fromMap(doc.data(), doc.id))
            .toList());
  }

  Stream<List<LaborEntry>> getAllActiveShifts() {
    return _firestore
        .collection('labor_logs')
        .where('status', isEqualTo: 'active')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => LaborEntry.fromMap(doc.data(), doc.id))
            .toList());
  }

  Stream<List<LaborEntry>> getWorkerHistory(String workerId) {
    return _firestore
        .collection('labor_logs')
        .where('workerId', isEqualTo: workerId)
        .where('status', isEqualTo: 'completed')
        .orderBy('checkInTime', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => LaborEntry.fromMap(doc.data(), doc.id))
            .toList());
  }

  Stream<List<AdvancePayment>> getWorkerAdvances(String workerId) {
    return _firestore
        .collection('worker_advances')
        .where('workerId', isEqualTo: workerId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AdvancePayment.fromMap(doc.data(), doc.id))
            .toList());
  }

  Stream<List<LaborEntry>> getAllCompletedReports() {
    return _firestore
        .collection('labor_logs')
        .where('status', isEqualTo: 'completed')
        .orderBy('checkInTime', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => LaborEntry.fromMap(doc.data(), doc.id))
            .toList());
  }
}
