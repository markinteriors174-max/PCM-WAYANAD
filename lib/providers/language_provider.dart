import 'package:flutter/material.dart';

enum AppLanguage { english, malayalam, hindi }

class LanguageProvider with ChangeNotifier {
  AppLanguage _currentLanguage = AppLanguage.english;
  AppLanguage get currentLanguage => _currentLanguage;

  void setLanguage(AppLanguage lang) {
    _currentLanguage = lang;
    notifyListeners();
  }

  bool get isMalayalam => _currentLanguage == AppLanguage.malayalam;
  bool get isHindi => _currentLanguage == AppLanguage.hindi;
  bool get isEnglish => _currentLanguage == AppLanguage.english;

  String translate(String key) {
    if (_currentLanguage == AppLanguage.malayalam) return _malayalamStrings[key] ?? key;
    if (_currentLanguage == AppLanguage.hindi) return _hindiStrings[key] ?? key;
    return _englishStrings[key] ?? key;
  }

  void toggleLanguage() {
    if (_currentLanguage == AppLanguage.english) {
      setLanguage(AppLanguage.malayalam);
    } else if (_currentLanguage == AppLanguage.malayalam) {
      setLanguage(AppLanguage.hindi);
    } else {
      setLanguage(AppLanguage.english);
    }
  }

  static final Map<String, String> _englishStrings = {
    'REGISTER': 'REGISTER',
    'CALCULATOR': 'CALCULATOR',
    'HISTORY': 'HISTORY',
    'RATES': 'RATES',
    'GRAND TOTAL': 'GRAND TOTAL',
    'BALANCE': 'BALANCE',
    'LOCATION': 'LOCATION',
    'SAVE NOW': 'SAVE NOW',
    'GENERATE PDF': 'GENERATE PDF',
    'VIEW PDF': 'VIEW PDF',
    'ADD TO LIST': 'ADD TO LIST',
    'ROOM': 'ROOM',
    'CEILING': 'CEILING',
    'RATE': 'RATE',
    'DRAFT': 'DRAFT',
    'FOLDERS': 'SITE FOLDERS',
    'SPEAK': 'SPEAK',
    'QUOTATION': 'QUOTATION',
  };

  static final Map<String, String> _malayalamStrings = {
    'REGISTER': 'രജിസ്റ്റർ',
    'CALCULATOR': 'കാൽക്കുലേറ്റർ',
    'HISTORY': 'ചരിത്രം',
    'RATES': 'നിരക്കുകൾ',
    'GRAND TOTAL': 'ആകെ തുക',
    'BALANCE': 'ബാക്കി തുക',
    'LOCATION': 'സ്ഥലം',
    'SAVE NOW': 'സേവ് ചെയ്യുക',
    'GENERATE PDF': 'PDF ആക്കുക',
    'VIEW PDF': 'PDF കാണുക',
    'ADD TO LIST': 'ലിസ്റ്റിൽ ചേർക്കുക',
    'ROOM': 'റൂം',
    'CEILING': 'സീലിംഗ്',
    'RATE': 'നിരക്ക്',
    'DRAFT': 'ഡ്രാഫ്റ്റ്',
    'FOLDERS': 'സൈറ്റ് ഫോൾഡറുകൾ',
    'SPEAK': 'കേൾക്കുക',
    'QUOTATION': 'കൊട്ടേഷൻ',
  };

  static final Map<String, String> _hindiStrings = {
    'REGISTER': 'रजिस्टर',
    'CALCULATOR': 'कैलकुलेटर',
    'HISTORY': 'इतिहास',
    'RATES': 'दरें',
    'GRAND TOTAL': 'कुल राशि',
    'BALANCE': 'शेष राशि',
    'LOCATION': 'स्थान',
    'SAVE NOW': 'अभी सहेजें',
    'GENERATE PDF': 'पीडीएफ बनाएं',
    'VIEW PDF': 'पीडीएफ देखें',
    'ADD TO LIST': 'सूची में जोड़ें',
    'ROOM': 'कमरा',
    'CEILING': 'छत',
    'RATE': 'दर',
    'DRAFT': 'ड्राफ्ट',
    'FOLDERS': 'साइट फ़ोल्डर',
    'SPEAK': 'सुनें',
    'QUOTATION': 'प्रशस्ति पत्र',
  };
}
