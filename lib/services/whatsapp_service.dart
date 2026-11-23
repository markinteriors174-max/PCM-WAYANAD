import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class WhatsAppService {
  static final WhatsAppService instance = WhatsAppService._init();
  WhatsAppService._init();

  static const String _apiVersion = 'v19.0';
  static const String _phoneNumberId = 'YOUR_PHONE_NUMBER_ID';
  static const String _accessToken = 'YOUR_ACCESS_TOKEN';
  
  Future<bool> sendMessage({
    required String to,
    required String message,
  }) async {
    final cleanPhone = to.replaceAll(RegExp(r'[^0-9]'), '');
    
    if (_accessToken == 'YOUR_ACCESS_TOKEN') {
      debugPrint('SIMULATED WHATSAPP: To: $cleanPhone, Msg: $message');
      return true;
    }

    try {
      final url = 'https://graph.facebook.com/$_apiVersion/$_phoneNumberId/messages';
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $_accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "messaging_product": "whatsapp",
          "recipient_type": "individual",
          "to": cleanPhone,
          "type": "text",
          "text": {
            "preview_url": false,
            "body": message
          }
        }),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        debugPrint('WhatsApp message sent successfully to $cleanPhone');
        return true;
      } else {
        debugPrint('WhatsApp API Error: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('Error sending WhatsApp message: $e');
      return false;
    }
  }

  Future<bool> sendTemplateMessage({
    required String to,
    required String templateName,
    required List<String> parameters,
  }) async {
    final cleanPhone = to.replaceAll(RegExp(r'[^0-9]'), '');
    
    if (_accessToken == 'YOUR_ACCESS_TOKEN') {
      debugPrint('SIMULATED WHATSAPP TEMPLATE: To: $cleanPhone, Template: $templateName, Params: $parameters');
      return true;
    }

    try {
      final url = 'https://graph.facebook.com/$_apiVersion/$_phoneNumberId/messages';
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $_accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "messaging_product": "whatsapp",
          "to": cleanPhone,
          "type": "template",
          "template": {
            "name": templateName,
            "language": { "code": "en_US" },
            "components": [
              {
                "type": "body",
                "parameters": parameters.map((p) => { "type": "text", "text": p }).toList()
              }
            ]
          }
        }),
      );
      if (response.statusCode >= 200 && response.statusCode < 300) return true;
    } catch (e) {
      debugPrint('Error sending WhatsApp template: $e');
    }
    return false;
  }

  Future<void> notifyPunchIn({
    required String phone,
    required String workerName,
    required String siteName,
    required String time,
  }) async {
    final message = '✅ *PCM PUNCH-IN ALERT*\n\nWorker: $workerName\nSite: $siteName\nTime: $time\n\nShift started. Stay safe!';
    await sendMessage(to: phone, message: message);
  }

  Future<void> notifyPunchOut({
    required String phone,
    required String workerName,
    required String siteName,
    required String duration,
    required double wage,
  }) async {
    final message = '🏁 *PCM PUNCH-OUT ALERT*\n\nWorker: $workerName\nSite: $siteName\nDuration: $duration\nWage Earned: ₹${wage.toStringAsFixed(2)}\n\nShift completed successfully.';
    await sendMessage(to: phone, message: message);
  }

  Future<void> notifyPaymentReceived({
    required String phone,
    required String clientName,
    required double amount,
    required String receiptNo,
  }) async {
    final message = '💰 *PCM PAYMENT CONFIRMATION*\n\nDear $clientName,\nWe have successfully received your payment of *₹${amount.toStringAsFixed(2)}*.\nReceipt No: $receiptNo\n\nThank you for choosing PCM WAYANAD!';
    await sendMessage(to: phone, message: message);
  }

  Future<void> notifyProgressMilestone({
    required String phone,
    required String siteName,
    required double progress,
  }) async {
    final message = '🏗️ *PCM PROGRESS MILESTONE*\n\nYour project at site *$siteName* has reached *${progress.toStringAsFixed(0)}%* completion.\n\nCheck the app for live photos and updates!';
    await sendMessage(to: phone, message: message);
  }
}
