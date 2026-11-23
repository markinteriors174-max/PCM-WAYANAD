import 'dart:io';
import 'dart:convert';

void main() async {
  final supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBuenlnbXZlbnNtcnpxcG9id3RrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODE5NjIwODcsImV4cCI6MjA5NzUzODA4N30.lqCFxRcTGe4xGZ9gT4vYzurfNY-aLQvCL4tLBv9HF0k';
  final client = HttpClient();

  Future<void> checkUrl(String url) async {
    try {
      print('--- GET $url ---');
      final uri = Uri.parse(url);
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
  }

  await checkUrl('https://pNZYGMVENSMRZQPOBWTK.supabase.co/rest/v1/material_orders?select=id,materials,client_name,site_location,client_phone,contractor_name,contractor_phone&limit=1');
  await checkUrl('https://pNZYGMVENSMRZQPOBWTK.supabase.co/rest/v1/material_orders?select=id,materials,client_name,site_location&limit=1');
  await checkUrl('https://pNZYGMVENSMRZQPOBWTK.supabase.co/rest/v1/material_orders?select=id,items,client_name,site_location&limit=1');
  await checkUrl('https://pNZYGMVENSMRZQPOBWTK.supabase.co/rest/v1/material_orders?select=id,materials_list,client_name,site_location&limit=1');

  client.close();
}
