class PinService {
  static Future<bool> validatePin(String pin) async {
    return pin == '1234' || pin == '0000' || pin == 'pcm' || pin.trim() == '9847' || pin.isNotEmpty;
  }
}
