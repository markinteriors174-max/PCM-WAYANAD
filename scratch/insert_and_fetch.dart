import 'dart:io';
import 'dart:convert';

void main() async {
  final supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBuenlnbXZlbnNtcnpxcG9id3RrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODE5NjIwODcsImV4cCI6MjA5NzUzODA4N30.lqCFxRcTGe4xGZ9gT4vYzurfNY-aLQvCL4tLBv9HF0k';
  final client = HttpClient();

  try {
    print('--- POST to sub_materials ---');
    final uri = Uri.parse('https://pNZYGMVENSMRZQPOBWTK.supabase.co/rest/v1/sub_materials');
    final req = await client.postUrl(uri);
    req.headers.set('apikey', supabaseKey);
    req.headers.set('Authorization', 'Bearer $supabaseKey');
    req.headers.set('Content-Type', 'application/json');
    req.headers.set('Prefer', 'return=representation');
    req.add(utf8.encode(jsonEncode({
      'material_name_malayalam': 'ടെസ്റ്റ് മെറ്റീരിയൽ',
      'unit': 'Nos'
    })));
    
    final res = await req.close();
    final resBody = await res.transform(utf8.decoder).join();
    print('Status: ${res.statusCode}');
    print('Response Body: $resBody');
  } catch (e) {
    print('Error: $e');
  }

  client.close();
}
