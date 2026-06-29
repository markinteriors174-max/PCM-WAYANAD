import 'dart:io';
import 'dart:typed_data';

class PlatformUtilsImpl {
  static Future<Uint8List?> readFileBytes(String path) async {
    final file = File(path);
    if (await file.exists()) {
      return await file.readAsBytes();
    }
    return null;
  }

  static Future<bool> fileExists(String path) async {
    return await File(path).exists();
  }
}
