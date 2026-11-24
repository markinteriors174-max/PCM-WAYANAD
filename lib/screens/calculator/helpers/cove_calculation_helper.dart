import '../calculator_controller.dart';

class CoveCalculationHelper {
  static double parseNum(String? val) {
    if (val == null) return 0.0;
    return double.tryParse(val.trim().replaceAll(',', '.')) ?? 0.0;
  }

  static double getConversionFactor(CalculatorController ctrl) {
    final u = ctrl.coveUnit.isNotEmpty ? ctrl.coveUnit : ctrl.unit;
    switch (u.toLowerCase()) {
      case 'cm':
        return 1.0 / (30.48 * 30.48);
      case 'meters':
      case 'meter':
      case 'sqm':
      case 'm':
        return 10.7639104;
      case 'inches':
      case 'inch':
      case 'in':
        return 1.0 / 144.0;
      case 'mm':
        return 10.7639104 / 1000000.0;
      case 'feet':
      case 'sqft':
      case 'ft':
      default:
        return 1.0;
    }
  }

  static double toFeet(double val, String unit) {
    switch (unit.toLowerCase()) {
      case 'cm':
        return val / 30.48;
      case 'meters':
      case 'meter':
      case 'm':
        return val * 3.28084;
      case 'inches':
      case 'inch':
      case 'in':
        return val / 12.0;
      case 'feet':
      case 'ft':
      default:
        return val;
    }
  }

  static double getLengthRowSqft(CalculatorController ctrl) {
    final l = parseNum(ctrl.coveLengthController.text);
    final b = parseNum(ctrl.coveWidthController.text);
    final q = parseNum(ctrl.coveQuantityController.text);
    return (l * b * (q == 0 ? 1.0 : q)) * getConversionFactor(ctrl);
  }

  static double getWidthRowSqft(CalculatorController ctrl) {
    final l = parseNum(ctrl.coveLength2Controller.text);
    final border1 = parseNum(ctrl.coveWidthController.text);
    final border2 = parseNum(ctrl.coveWidth2Controller.text);
    final b = border2 > 0 ? border2 : border1;
    final q = parseNum(ctrl.coveQuantity2Controller.text);
    return (l * b * (q == 0 ? 1.0 : q)) * getConversionFactor(ctrl);
  }

  static double getExtraRowSqft(CoveLightRow row, CalculatorController ctrl) {
    final l = parseNum(row.lengthController.text);
    final b = parseNum(row.widthController.text);
    final q = parseNum(row.quantityController.text);
    return (l * b * (q == 0 ? 1.0 : q)) * getConversionFactor(ctrl);
  }

  static double getExtraRowsTotalSqft(CalculatorController ctrl) {
    double sum = 0.0;
    for (final r in ctrl.extraCoveRows) {
      sum += getExtraRowSqft(r, ctrl);
    }
    return sum;
  }

  static double getSingleCurveSqft(String rText, String rUnit, String hText, String hUnit, String archType) {
    final r = parseNum(rText);
    final h = parseNum(hText);
    if (r <= 0 || h <= 0) return 4.36;

    final rInFeet = toFeet(r, rUnit);
    final hInFeet = toFeet(h, hUnit);

    double angleFactor = 3.1415926535 / 2.0;
    if (archType.contains('180')) {
      angleFactor = 3.1415926535;
    } else if (archType.contains('360')) {
      angleFactor = 2.0 * 3.1415926535;
    }

    return (angleFactor * rInFeet) * hInFeet;
  }

  static double getCustomRate(CalculatorController ctrl) {
    final val = parseNum(ctrl.coveRateController.text);
    if (val > 0) return val;
    final mainR = parseNum(ctrl.rateController.text);
    if (mainR > 0) return mainR;
    return 105.0;
  }
}
