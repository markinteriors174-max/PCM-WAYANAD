import 'dart:io';
import 'dart:convert';

void main() async {
  final supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBuenlnbXZlbnNtcnpxcG9id3RrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODE5NjIwODcsImV4cCI6MjA5NzUzODA4N30.lqCFxRcTGe4xGZ9gT4vYzurfNY-aLQvCL4tLBv9HF0k';
  final client = HttpClient();

  // Test 1: GET on sub_materials limit 5
  try {
    print('--- GET on sub_materials ---');
    final uri = Uri.parse('https://pNZYGMVENSMRZQPOBWTK.supabase.co/rest/v1/sub_materials?limit=5');
    final req = await client.getUrl(uri);
    req.headers.set('apikey', supabaseKey);
    req.headers.set('Authorization', 'Bearer $supabaseKey');
    
    final res = await req.close();
    final body = await res.transform(utf8.decoder).join();
    print('Status: ${res.statusCode}');
    print('Body: $body');
  } catch (e) {
    print('Error: $e');
  }

  // Test 2: GET on main_categories
  try {
    print('\n--- GET on main_categories ---');
    final uri = Uri.parse('https://pNZYGMVENSMRZQPOBWTK.supabase.co/rest/v1/main_categories?limit=5');
    final req = await client.getUrl(uri);
    req.headers.set('apikey', supabaseKey);
    req.headers.set('Authorization', 'Bearer $supabaseKey');
    
    final res = await req.close();
    final body = await res.transform(utf8.decoder).join();
    print('Status: ${res.statusCode}');
    print('Body: $body');
  } catch (e) {
    print('Error: $e');
  }

  client.close();
}
