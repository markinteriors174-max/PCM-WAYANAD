import 'dart:convert';

void main() {
  const payload = 'EYjPC3mIoIjZDxbHyMfZzsiSiNjLzIi6iNbUENLNBxzLBNnTCNPXCg9ID3rRiIWICM9Szsi6iMfUB24IlcjPyxqIoJe3ode5nJiWodCSiMv4Cci6mJa5nZuZoda4n30';
  
  String p = payload;
  while (p.length % 4 != 0) {
    p += '=';
  }
  
  try {
    final decoded = utf8.decode(base64.decode(p));
    print('Decoded: $decoded');
  } catch (e) {
    print('Failed to decode: $e');
  }
}
