class PcmMathEngine {
  static double getUnitConversionFactor(String unit) {
    final u = unit.trim().toLowerCase();
    if (u == 'meters' || u == 'meter' || u == 'sqm' || u == 'm') {
      return 10.7639104;
    } else if (u == 'inches' || u == 'inch' || u == 'in') {
      return 1.0 / 144.0;
    } else if (u == 'mm') {
      return 10.7639104 / 1000000.0;
    } else if (u == 'cm') {
      return 1.0 / (30.48 * 30.48);
    }
    return 1.0;
  }

  static double calculateAreaSqFt({
    required double length,
    required double width,
    required double quantity,
    required String unit,
    bool isAreaUnit = true,
  }) {
    final factor = getUnitConversionFactor(unit);
    final q = quantity > 0 ? quantity : 1.0;
    if (isAreaUnit) {
      return length * width * q * factor;
    } else {
      return length * q * factor;
    }
  }

  static double calculateAmount({
    required double areaSqFt,
    required double rate,
  }) {
    final a = areaSqFt.isFinite ? areaSqFt : 0.0;
    final r = rate.isFinite ? rate : 0.0;
    return double.parse((a * r).toStringAsFixed(2));
  }

  static double calculatePlainAreaSqFt({
    required double length,
    required double width,
    required double quantity,
    required String unit,
    bool isAreaUnit = true,
    double extraSum = 0.0,
  }) {
    final base = calculateAreaSqFt(length: length, width: width, quantity: quantity, unit: unit, isAreaUnit: isAreaUnit);
    return base + extraSum;
  }

  static double calculateCoveAreaSqFt({
    required double rft,
    required double quantity,
    required String unit,
  }) {
    final factor = getUnitConversionFactor(unit);
    final q = quantity > 0 ? quantity : 1.0;
    return rft * q * factor;
  }

  static double calculateSquareCenterAreaSqFt({
    required double length,
    required double width,
    required double quantity,
    required String unit,
  }) {
    return calculateAreaSqFt(length: length, width: width, quantity: quantity, unit: unit, isAreaUnit: true);
  }

  static double calculateRoundCenterAreaSqFt({
    required double radius,
    required double deductionRadius,
    required String unit,
    double extraRowsSum = 0.0,
  }) {
    final factor = getUnitConversionFactor(unit);
    final fullCircleAreaM2 = 3.1415926535 * radius * radius;
    final fullCircleSqFt = fullCircleAreaM2 * factor;
    final deductionAreaM2 = 3.1415926535 * deductionRadius * deductionRadius;
    final deductionCircleSqFt = deductionAreaM2 * factor;
    final netSqFt = deductionRadius > 0 ? (fullCircleSqFt - deductionCircleSqFt) : fullCircleSqFt;
    return (radius > 0 ? netSqFt : 0.0) + extraRowsSum;
  }
}
