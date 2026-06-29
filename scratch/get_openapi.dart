import 'dart:io';
import 'dart:convert';

void main() async {
  final supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBuenlnbXZlbnNtcnpxcG9id3RrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODE5NjIwODcsImV4cCI6MjA5NzUzODA4N30.lqCFxRcTGe4xGZ9gT4vYzurfNY-aLQvCL4tLBv9HF0k';
  final client = HttpClient();

  try {
    print('--- Fetching PostgREST OpenAPI spec ---');
    final uri = Uri.parse('https://pNZYGMVENSMRZQPOBWTK.supabase.co/rest/v1/');
    final req = await client.getUrl(uri);
    req.headers.set('apikey', supabaseKey);
    req.headers.set('Authorization', 'Bearer $supabaseKey');
    
    final res = await req.close();
    final body = await res.transform(utf8.decoder).join();
    final jsonObj = json.decode(body);
    
    // Print keys or write to file
    final file = File('scratch/openapi_spec.json');
    await file.writeAsString(const JsonEncoder.withIndent('  ').convert(jsonObj));
    print('OpenAPI spec written to scratch/openapi_spec.json');
  } catch (e) {
    print('Error: $e');
  }

  client.close();
}
