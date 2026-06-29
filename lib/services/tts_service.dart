import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter/foundation.dart';

class TtsService {
  static final TtsService instance = TtsService._init();
  final FlutterTts _flutterTts = FlutterTts();

  TtsService._init() {
    _initTts();
  }

  Future<void> _initTts() async {
    try {
      await _flutterTts.setSharedInstance(true);
      await _flutterTts.setIosAudioCategory(IosTextToSpeechAudioCategory.playback,
          [
            IosTextToSpeechAudioCategoryOptions.allowBluetooth,
            IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
            IosTextToSpeechAudioCategoryOptions.mixWithOthers
          ],
          IosTextToSpeechAudioMode.voicePrompt
      );
    } catch (e) {
      debugPrint("TTS Init Error: $e");
    }
  }

  Future<void> speak(String text, {required String languageCode}) async {
    try {
      // languageCode: 'en-US' or 'ml-IN'
      bool isAvailable = await _flutterTts.isLanguageAvailable(languageCode);
      if (isAvailable) {
        await _flutterTts.setLanguage(languageCode);
        await _flutterTts.setPitch(1.0);
        await _flutterTts.setSpeechRate(0.5);
        await _flutterTts.speak(text);
      } else {
        debugPrint("TTS: Language $languageCode not available on this device.");
        // Fallback to English if Malayalam fails
        await _flutterTts.setLanguage("en-US");
        await _flutterTts.speak(text);
      }
    } catch (e) {
      debugPrint("TTS Speak Error: $e");
    }
  }

  Future<void> stop() async {
    await _flutterTts.stop();
  }
}
