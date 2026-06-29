import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class WorkerDbService {
  static final WorkerDbService instance = WorkerDbService._init();
  WorkerDbService._init();

  static const String _url = 'https://pNZYGMVENSMRZQPOBWTK.supabase.co/rest/v1';
  static const String _key = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBuenlnbXZlbnNtcnpxcG9id3RrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODE5NjIwODcsImV4cCI6MjA5NzUzODA4N30.lqCFxRcTGe4xGZ9gT4vYzurfNY-aLQvCL4tLBv9HF0k2';

  Future<dynamic> _request(String path, String method, {Map<String, dynamic>? body}) async {
    try {
      final uri = Uri.parse('$_url$path');
      final headers = {
        'apikey': _key,
        'Authorization': 'Bearer $_key',
        'Content-Type': 'application/json',
      };

      http.Response response;
      switch (method.toUpperCase()) {
        case 'GET':
          response = await http.get(uri, headers: headers);
          break;
        case 'POST':
          response = await http.post(uri, headers: headers, body: body != null ? jsonEncode(body) : null);
          break;
        case 'PATCH':
          response = await http.patch(uri, headers: headers, body: body != null ? jsonEncode(body) : null);
          break;
        case 'DELETE':
          response = await http.delete(uri, headers: headers);
          break;
        default:
          throw UnsupportedError('Method $method not supported');
      }

      if (response.statusCode == 200 || response.statusCode == 201 || response.statusCode == 204) {
        return response.body.isEmpty ? null : jsonDecode(response.body);
      }
    } catch (e) {
      debugPrint('Supabase HTTP error: $e');
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> getSQLiteWorkers() async {
    final res = await _request('/worker_ledger_view?select=*&order=worker_name.asc', 'GET');
    return res != null ? List<Map<String, dynamic>>.from(res) : [];
  }

  Future<int> insertSQLiteWorker(String name, double dailyWage, double totalDays, double totalPaid) async {
    final res = await _request('/workers', 'POST', body: {
      'worker_name': name, 'daily_wage': dailyWage, 'total_days': totalDays, 'total_paid': totalPaid
    });
    return res != null ? 1 : 0;
  }

  Future<int> updateWorkerDays(int id, double totalDays) async {
    await _request('/workers?id=eq.$id', 'PATCH', body: {'total_days': totalDays});
    return 1;
  }

  Future<int> recordWorkerPayment(int id, double paymentAmount) async {
    final current = await _request('/workers?id=eq.$id&select=total_paid', 'GET');
    final double paid = current != null && current.isNotEmpty ? (current.first['total_paid'] ?? 0.0).toDouble() : 0.0;
    await _request('/workers?id=eq.$id', 'PATCH', body: {'total_paid': paid + paymentAmount});
    return 1;
  }

  Future<int> deleteSQLiteWorker(int id) async {
    await _request('/workers?id=eq.$id', 'DELETE');
    return 1;
  }
}
