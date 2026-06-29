import 'package:intl/intl.dart';

class CalculatorUtils {
  static String formatIndianCurrency(double amount) {
    final format = NumberFormat.currency(locale: 'en_IN', symbol: '', decimalDigits: 2);
    return format.format(amount);
  }
  static double getUnitScale(String unit) {
    switch (unit) {
      case 'Meters': return 3.28084;
      case 'Inches': return 1.0 / 12.0;
      case 'mm': return 1.0 / 304.8;
      default: return 1.0;
    }
  }

  static String getLinearUnitLabel(String unit) {
    switch (unit) {
      case 'Meters':
      case 'SqM':
        return 'Meter';
      case 'RMT':
        return 'RMT';
      case 'Inches':
        return 'Inch';
      case 'mm':
        return 'mm';
      case 'cm':
        return 'cm';
      case 'RFT':
        return 'RFT';
      default:
        return 'Feet';
    }
  }

  static String getAreaUnitLabel(String unit) {
    switch (unit) {
      case 'Meters':
      case 'SqM':
      case 'RMT':
        return 'SqM';
      case 'Inches':
        return 'SqIn';
      case 'mm':
        return 'Sq mm';
      case 'cm':
        return 'Sq cm';
      default:
        return 'SqFt';
    }
  }

  static double getNormalizedAreaSqFt(dynamic item) {
    double factor = 1.0;
    if (item.unit == 'Meters' || item.unit == 'SqM') {
      factor = 10.764;
    } else if (item.unit == 'Inches') {
      factor = 1.0 / 144.0;
    } else if (item.unit == 'mm') {
      factor = 10.764 / 1000000.0;
    }
    return item.area * factor;
  }
}

