import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/labor_models.dart';

class LaborService {
  static final LaborService instance = LaborService._init();
  LaborService._init();

  static const String _url = 'https://pNZYGMVENSMRZQPOBWTK.supabase.co/rest/v1';
  static const String _key = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBuenlnbXZlbnNtcnpxcG9id3RrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODE5NjIwODcsImV4cCI6MjA5NzUzODA4N30.lqCFxRcTGe4xGZ9gT4vYzurfNY-aLQvCL4tLBv9HF0k2';

  Map<String, String> get _headers => {
    'apikey': _key,
    'Authorization': 'Bearer $_key',
    'Content-Type': 'application/json',
    'Prefer': 'return=representation',
  };

  Stream<List<Worker>> getWorkers() => _getWorkers().asBroadcastStream();
  Stream<List<Worker>> _getWorkers() async* {
    while (true) {
      try {
        final response = await http.get(Uri.parse('$_url/workers?select=*'), headers: _headers);
        if (response.statusCode == 200) {
          final List data = jsonDecode(response.body);
          yield data.map((m) => Worker.fromMap(m, m['id'].toString())).toList();
        }
      } catch (e) {
        debugPrint('Error fetching workers: $e');
      }
      await Future.delayed(const Duration(seconds: 10));
    }
  }

  Future<void> addWorker(Worker worker) async {
    await http.post(
      Uri.parse('$_url/workers'),
      headers: _headers,
      body: jsonEncode(worker.toMap()),
    );
  }

  Future<void> deleteWorker(String workerId) async {
    await http.delete(
      Uri.parse('$_url/workers?id=eq.$workerId'),
      headers: _headers,
    );
  }

  Future<void> updateWorkerRate(String workerId, double rate) async {
    await http.patch(
      Uri.parse('$_url/workers?id=eq.$workerId'),
      headers: _headers,
      body: jsonEncode({'dailyRate': rate}),
    );
  }

  Future<void> updateWorkerRating(String workerId, double rating) async {
    await http.patch(
      Uri.parse('$_url/workers?id=eq.$workerId'),
      headers: _headers,
      body: jsonEncode({'rating': rating}),
    );
  }

  Future<void> updateWorkerHomeLocation(String workerId, double lat, double lng) async {
    await http.patch(
      Uri.parse('$_url/workers?id=eq.$workerId'),
      headers: _headers,
      body: jsonEncode({'homeLat': lat, 'homeLng': lng}),
    );
  }

  Future<void> addWorkerAdvance(AdvancePayment advance) async {
    await http.post(
      Uri.parse('$_url/worker_advances'),
      headers: _headers,
      body: jsonEncode(advance.toMap()),
    );
  }

  Future<void> deleteWorkerAdvance(String advanceId) async {
    await http.delete(
      Uri.parse('$_url/worker_advances?id=eq.$advanceId'),
      headers: _headers,
    );
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
    final entry = {
      'workerId': workerId,
      'workerName': workerName,
      'siteName': siteName,
      'mode': 'daily',
      'shiftType': shiftType.name,
      'status': 'active',
      'checkInTime': DateTime.now().toIso8601String(),
      'checkInLat': lat,
      'checkInLng': lng,
      'date': DateTime.now().toIso8601String().split('T').first,
    };

    await http.post(Uri.parse('$_url/labor_logs'), headers: _headers, body: jsonEncode(entry));
  }

  Future<void> checkOutWorker({
    required String entryId,
    double paidAmount = 0,
  }) async {
    final checkOutTime = DateTime.now();
    
    await http.patch(
      Uri.parse('$_url/labor_logs?id=eq.$entryId'),
      headers: _headers,
      body: jsonEncode({
        'status': 'completed',
        'checkOutTime': checkOutTime.toIso8601String(),
        'paidAmount': paidAmount,
      }),
    );
  }

  Stream<List<LaborEntry>> getActiveShifts(String workerId) => _getActiveShifts(workerId).asBroadcastStream();
  Stream<List<LaborEntry>> _getActiveShifts(String workerId) async* {
    while (true) {
      try {
        final response = await http.get(
          Uri.parse('$_url/labor_logs?workerId=eq.$workerId&status=eq.active&select=*'),
          headers: _headers,
        );
        if (response.statusCode == 200) {
          final List data = jsonDecode(response.body);
          yield data.map((m) => LaborEntry.fromMap(m, m['id'].toString())).toList();
        }
      } catch (e) { debugPrint(e.toString()); }
      await Future.delayed(const Duration(seconds: 5));
    }
  }

  Stream<List<LaborEntry>> getAllActiveShifts() => _getAllActiveShifts().asBroadcastStream();
  Stream<List<LaborEntry>> _getAllActiveShifts() async* {
    while (true) {
      try {
        final response = await http.get(
          Uri.parse('$_url/labor_logs?status=eq.active&select=*'),
          headers: _headers,
        );
        if (response.statusCode == 200) {
          final List data = jsonDecode(response.body);
          yield data.map((m) => LaborEntry.fromMap(m, m['id'].toString())).toList();
        }
      } catch (e) { debugPrint(e.toString()); }
      await Future.delayed(const Duration(seconds: 5));
    }
  }

  Stream<List<LaborEntry>> getWorkerHistory(String workerId) => _getWorkerHistory(workerId).asBroadcastStream();
  Stream<List<LaborEntry>> _getWorkerHistory(String workerId) async* {
    while (true) {
      try {
        final response = await http.get(
          Uri.parse('$_url/labor_logs?workerId=eq.$workerId&status=eq.completed&select=*&order=checkInTime.desc'),
          headers: _headers,
        );
        if (response.statusCode == 200) {
          final List data = jsonDecode(response.body);
          yield data.map((m) => LaborEntry.fromMap(m, m['id'].toString())).toList();
        }
      } catch (e) { debugPrint(e.toString()); }
      await Future.delayed(const Duration(seconds: 30));
    }
  }

  Stream<List<AdvancePayment>> getWorkerAdvances(String workerId) => _getWorkerAdvances(workerId).asBroadcastStream();
  Stream<List<AdvancePayment>> _getWorkerAdvances(String workerId) async* {
    while (true) {
      try {
        final response = await http.get(
          Uri.parse('$_url/worker_advances?workerId=eq.$workerId&select=*&order=date.desc'),
          headers: _headers,
        );
        if (response.statusCode == 200) {
          final List data = jsonDecode(response.body);
          yield data.map((m) => AdvancePayment.fromMap(m, m['id'].toString())).toList();
        }
      } catch (e) { debugPrint(e.toString()); }
      await Future.delayed(const Duration(seconds: 30));
    }
  }

  Stream<List<LaborEntry>> getAllCompletedReports() => _getAllCompletedReports().asBroadcastStream();
  Stream<List<LaborEntry>> _getAllCompletedReports() async* {
    while (true) {
      try {
        final response = await http.get(
          Uri.parse('$_url/labor_logs?status=eq.completed&select=*&order=checkInTime.desc'),
          headers: _headers,
        );
        if (response.statusCode == 200) {
          final List data = jsonDecode(response.body);
          yield data.map((m) => LaborEntry.fromMap(m, m['id'].toString())).toList();
        }
      } catch (e) { debugPrint(e.toString()); }
      await Future.delayed(const Duration(seconds: 60));
    }
  }
}
