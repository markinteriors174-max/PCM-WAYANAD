import 'dart:io';
import 'dart:convert';

void main() async {
  final supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBuenlnbXZlbnNtcnpxcG9id3RrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODE5NjIwODcsImV4cCI6MjA5NzUzODA4N30.lqCFxRcTGe4xGZ9gT4vYzurfNY-aLQvCL4tLBv9HF0k';
  final client = HttpClient();

  // Test 1: OPTIONS on main_categories
  try {
    print('--- OPTIONS on main_categories ---');
    final uri = Uri.parse('https://pNZYGMVENSMRZQPOBWTK.supabase.co/rest/v1/main_categories');
    final req = await client.openUrl('OPTIONS', uri);
    req.headers.set('apikey', supabaseKey);
    req.headers.set('Authorization', 'Bearer $supabaseKey');
    
    final res = await req.close();
    final body = await res.transform(utf8.decoder).join();
    print('Status: ${res.statusCode}');
    print('Body: $body');
  } catch (e) {
    print('Error: $e');
  }

  // Test 2: OPTIONS on sub_materials
  try {
    print('\n--- OPTIONS on sub_materials ---');
    final uri = Uri.parse('https://pNZYGMVENSMRZQPOBWTK.supabase.co/rest/v1/sub_materials');
    final req = await client.openUrl('OPTIONS', uri);
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
