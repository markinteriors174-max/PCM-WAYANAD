import 'dart:convert';

void main() {
  const key = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBuenlnbXZlbnNtcnpxcG9id3RrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODE5NjIwODcsImV4cCI6MjA5NzUzODA4N30.lqCFxRcTGe4xGZ9gT4vYzurfNY-aLQvCL4tLBv9HF0k';
  final parts = key.split('.');
  if (parts.length != 3) {
    print('Invalid key format');
    return;
  }
  
  String payload = parts[1];
  while (payload.length % 4 != 0) {
    payload += '=';
  }
  
  final decoded = utf8.decode(base64.decode(payload));
  print('Payload: $decoded');
}
