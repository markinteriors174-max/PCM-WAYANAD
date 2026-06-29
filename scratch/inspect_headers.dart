import 'dart:io';
import 'dart:convert';

void main() async {
  final supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBuenlnbXZlbnNtcnpxcG9id3RrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODE5NjIwODcsImV4cCI6MjA5NzUzODA4N30.lqCFxRcTGe4xGZ9gT4vYzurfNY-aLQvCL4tLBv9HF0k';
  final client = HttpClient();

  Future<void> getHeaders(String tableName) async {
    try {
      print('--- GET CSV for $tableName ---');
      final uri = Uri.parse('https://pNZYGMVENSMRZQPOBWTK.supabase.co/rest/v1/$tableName');
      final req = await client.getUrl(uri);
      req.headers.set('apikey', supabaseKey);
      req.headers.set('Authorization', 'Bearer $supabaseKey');
      req.headers.set('Accept', 'text/csv');
      
      final res = await req.close();
      final body = await res.transform(utf8.decoder).join();
      print('Status: ${res.statusCode}');
      print('CSV Body: "$body"');
    } catch (e) {
      print('Error: $e');
    }
  }

  await getHeaders('sub_materials');
  await getHeaders('main_categories');
  await getHeaders('material_orders');

  client.close();
}
