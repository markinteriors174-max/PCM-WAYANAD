import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SafePreferences {
  static Future<SharedPreferences?> getInstance() async {
    try {
      return await SharedPreferences.getInstance();
    } catch (e) {
      if (e is MissingPluginException || e.toString().contains('MissingPluginException')) {
        if (kDebugMode) {
          debugPrint('SafePreferences: MissingPluginException caught on SharedPreferences.getInstance(). Returning null fallback.');
        }
      } else {
        if (kDebugMode) {
          debugPrint('SafePreferences: SharedPreferences error: $e');
        }
      }
      return null;
    }
  }
}
