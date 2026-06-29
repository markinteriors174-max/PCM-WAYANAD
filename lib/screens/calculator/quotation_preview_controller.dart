import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/quotation.dart';
import '../../services/database_service.dart';
import '../../services/tts_service.dart';
import '../../providers/language_provider.dart';

class QuotationPreviewController extends ChangeNotifier {
  Quotation? currentQuotation;
  bool isLoading = true;
  final List<PaymentRecord> payments = [];
  final nameController = TextEditingController();
  final locationController = TextEditingController();
  final mobileController = TextEditingController();

  Future<void> initLoad(Quotation? initialQuotation) async {
    if (initialQuotation != null) {
      currentQuotation = initialQuotation;
      payments.clear();
      payments.addAll(initialQuotation.payments);
      nameController.text = initialQuotation.clientName;
      locationController.text = initialQuotation.clientLocation;
      mobileController.text = initialQuotation.clientPhone;
      isLoading = false;
      notifyListeners();
    } else {
      await loadLatestData();
    }
  }

  Future<void> loadLatestData() async {
    isLoading = true;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      final unitNumber = prefs.getString('ui_unitNumber') ?? 'UNIT-NEW';
      
      final all = await DatabaseService.instance.getQuotations();
      if (all.isNotEmpty) {
        final match = all.firstWhere((q) => q.unitNumber == unitNumber, orElse: () => all.first);
        currentQuotation = match;
        payments.clear();
        payments.addAll(match.payments);
        nameController.text = match.clientName;
        locationController.text = match.clientLocation;
        mobileController.text = match.clientPhone;
      }
    } catch (e) {
      debugPrint('Sync Error: $e');
    }
    isLoading = false;
    notifyListeners();
  }

  void speakQuotation(LanguageProvider lang) {
    if (currentQuotation == null) return;
    
    final total = currentQuotation!.totalAmount.toInt();
    final advance = payments.fold(0.0, (s, p) => s + p.amount).toInt();
    final balance = total - advance;

    String text = "";
    if (lang.currentLanguage == AppLanguage.malayalam) {
      text = "ഈ പ്രോജക്റ്റിന്റെ ആകെ തുക $total രൂപയാണ്. മുൻകൂർ തുക കഴിച്ചുള്ള ബാക്കി $balance രൂപ.";
    } else if (lang.currentLanguage == AppLanguage.hindi) {
      text = "कुल राशि $total रुपये है। अग्रिम राशि के बाद शेष $balance रुपये।";
    } else {
      text = "Total amount is $total rupees. Remaining balance after advance is $balance rupees.";
    }
    
    TtsService.instance.speak(text, languageCode: lang.isMalayalam ? "ml-IN" : (lang.isHindi ? "hi-IN" : "en-US"));
  }

  Future<void> addPayment(String description, String amountText) async {
    if (amountText.isNotEmpty && currentQuotation != null) {
      final payment = PaymentRecord(
        quotationId: currentQuotation!.id,
        description: description,
        date: DateFormat('dd-MM-yyyy hh:mm a').format(DateTime.now()),
        amount: double.parse(amountText),
      );
      
      payments.add(payment);
      notifyListeners();
      
      if (currentQuotation!.id != null) {
        final db = await DatabaseService.instance.database;
        await db.insert('quotation_payments', payment.toMap(currentQuotation!.id!));
      }
    }
  }

  void disposeAll() {
    nameController.dispose();
    locationController.dispose();
    mobileController.dispose();
  }
}
