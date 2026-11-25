import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CalculatorUtils {
  static final NumberFormat _indianCurrencyFormat =
  NumberFormat.currency(locale: 'en_IN', symbol: '', decimalDigits: 2);
  static final NumberFormat _indianIntegerFormat =
  NumberFormat.currency(locale: 'en_IN', symbol: '', decimalDigits: 0);

  static String formatIndianCurrency(num? amount, {bool trimZeroDecimals = false}) {
    if (amount == null) return '0.00';
    final d = amount.toDouble();
    if (trimZeroDecimals && d % 1 == 0) {
      return _indianIntegerFormat.format(d).trim();
    }
    return _indianCurrencyFormat.format(d).trim();
  }

  static String formatNumber(num? value, {int decimalDigits = 2}) {
    if (value == null) return '0.00';
    final format = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '',
      decimalDigits: decimalDigits,
    );
    return format.format(value.toDouble()).trim();
  }

  static double getUnitScale(String unit) {
    switch (unit) {
      case 'Meters':
      case 'Meter':
      case 'SqM':
        return 3.28084;
      case 'Feet':
      case 'Ft':
        return 1.0;
      case 'Inches':
      case 'Inch':
        return 1.0 / 12.0;
      case 'cm':
        return 1.0 / 30.48;
      case 'mm':
        return 1.0 / 304.8;
      default:
        return 1.0;
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
    final double rawArea = (item.area ?? 0.0).toDouble();
    if (rawArea <= 0.0) return 0.0;

    // item.area ഇതിനകം SQFT-ലാണ് സൂക്ഷിക്കുന്നതെങ്കിൽ വീണ്ടും 10.764 കൊണ്ട് ഗുണിക്കാതെ
    // നേരിട്ട് SQFT തിരികെ നൽകുന്നു (double conversion ഒഴിവാക്കാൻ).
    return rawArea;
  }

  static String sanitizeBrandName(String? raw) {
    if (raw == null || raw.trim().isEmpty) return '';
    final parts = raw.split('•').map((p) => p.trim()).where((p) => p.isNotEmpty).toSet().toList();
    return parts.join(' • ');
  }

  static String normalizePhone(String? rawPhone) {
    if (rawPhone == null || rawPhone.trim().isEmpty) return '';
    String digits = rawPhone.replaceAll(RegExp(r'\D'), '');
    if (digits.length > 10 && digits.startsWith('91')) {
      digits = digits.substring(2);
    } else if (digits.length > 10 && digits.startsWith('0')) {
      digits = digits.replaceFirst(RegExp(r'^0+'), '');
    }
    if (digits.length > 10) {
      digits = digits.substring(digits.length - 10);
    }
    return digits;
  }
}

/// LOCKED SINGLE-PASS BACKEND CALCULATOR
/// 3.0m x 3.0m, Q = 1.0, Rate = 105.0 -> 96.88 SQFT (96.8752...), ₹10,171.90
class PcmBackendResult {
  final double mainAreaSqFt;
  final double mainAmount;
  final double centerAreaSqFt;
  final double centerAmount;
  final double coveAreaSqFt;
  final double coveAmount;
  final double totalAreaSqFt;
  final double grandTotalAmount;

  const PcmBackendResult({
    required this.mainAreaSqFt,
    required this.mainAmount,
    required this.centerAreaSqFt,
    required this.centerAmount,
    required this.coveAreaSqFt,
    required this.coveAmount,
    required this.totalAreaSqFt,
    required this.grandTotalAmount,
  });

  static const empty = PcmBackendResult(
    mainAreaSqFt: 0.0,
    mainAmount: 0.0,
    centerAreaSqFt: 0.0,
    centerAmount: 0.0,
    coveAreaSqFt: 0.0,
    coveAmount: 0.0,
    totalAreaSqFt: 0.0,
    grandTotalAmount: 0.0,
  );
}

class PcmBackendCalculator {
  static const double _meterToFeet = 3.28084;
  static const double _inchToFeet = 1.0 / 12.0;
  static const double _mmToFeet = 1.0 / 304.8;
  static const double _cmToFeet = 1.0 / 30.48;

  static double feetFactor(String? unit) {
    switch (unit?.trim().toLowerCase()) {
      case 'meter':
      case 'meters':
      case 'sqm':
        return _meterToFeet;
      case 'inch':
      case 'inches':
        return _inchToFeet;
      case 'mm':
        return _mmToFeet;
      case 'cm':
        return _cmToFeet;
      case 'feet':
      case 'foot':
      case 'ft':
      case 'sqft':
      default:
        return 1.0;
    }
  }

  /// ഒറ്റ തവണ മാത്രം SQFT കണക്കാക്കുന്നു (10.764 വീണ്ടും ഒരിക്കലും ഗുണിക്കില്ല).
  static double rectToSqFt({
    required double length,
    required double width,
    required double quantity,
    required String? unit,
  }) {
    if (length <= 0 || width <= 0) return 0.0;
    final qty = quantity <= 0 ? 1.0 : quantity;
    final f = feetFactor(unit);
    return (length * f) * (width * f) * qty;
  }

  static double amountFromSqFt({
    required double areaSqFt,
    required double rate,
  }) {
    if (areaSqFt <= 0 || rate <= 0) return 0.0;
    return areaSqFt * rate;
  }

  static PcmBackendResult computeAll({
    required bool isPlainCeilingOn,
    required bool isCeilingDesign,
    required String mainUnit,
    required double length,
    required double width,
    required double quantity,
    required double rate,
    required bool hasCentralDesign,
    required String centralUnit,
    required double centralLength,
    required double centralWidth,
    required double centralQuantity,
    required List<({double length, double width, double quantity})> extraCentral,
    required bool hasCove,
    required double coveLength1,
    required double coveLength2,
    required double coveHeight1,
    required double coveHeight2,
    required double coveQty1,
    required double coveQty2,
    required List<({double length, double width, double quantity})> extraCove,
  }) {
    double mainSqFt = 0.0;
    if (isPlainCeilingOn && isCeilingDesign && quantity > 0) {
      mainSqFt = rectToSqFt(
        length: length,
        width: width,
        quantity: quantity,
        unit: mainUnit,
      );
    }
    final double mainAmount = amountFromSqFt(areaSqFt: mainSqFt, rate: rate);

    double centerSqFt = 0.0;
    if (hasCentralDesign) {
      centerSqFt += rectToSqFt(
        length: centralLength,
        width: centralWidth,
        quantity: centralQuantity <= 0 ? 1.0 : centralQuantity,
        unit: centralUnit,
      );
      for (final row in extraCentral) {
        centerSqFt += rectToSqFt(
          length: row.length,
          width: row.width,
          quantity: row.quantity <= 0 ? 1.0 : row.quantity,
          unit: centralUnit,
        );
      }
    }
    final double centerAmount = amountFromSqFt(areaSqFt: centerSqFt, rate: rate);

    double coveSqFt = 0.0;
    if (hasCove) {
      double h1 = coveHeight1;
      double h2 = coveHeight2;
      if (h2 == 0.0) h2 = h1;
      if (h1 == 0.0) h1 = h2;

      if (coveQty1 > 0) {
        coveSqFt += rectToSqFt(
          length: coveLength1,
          width: h1,
          quantity: coveQty1,
          unit: mainUnit,
        );
      }
      if (coveQty2 > 0) {
        coveSqFt += rectToSqFt(
          length: coveLength2,
          width: h2,
          quantity: coveQty2,
          unit: mainUnit,
        );
      }
      for (final row in extraCove) {
        if (row.quantity > 0) {
          coveSqFt += rectToSqFt(
            length: row.length,
            width: row.width,
            quantity: row.quantity,
            unit: mainUnit,
          );
        }
      }
    }
    final double coveAmount = amountFromSqFt(areaSqFt: coveSqFt, rate: rate);

    final double totalSqFt = mainSqFt + centerSqFt + coveSqFt;
    final double grandTotal = mainAmount + centerAmount + coveAmount;

    return PcmBackendResult(
      mainAreaSqFt: mainSqFt,
      mainAmount: mainAmount,
      centerAreaSqFt: centerSqFt,
      centerAmount: centerAmount,
      coveAreaSqFt: coveSqFt,
      coveAmount: coveAmount,
      totalAreaSqFt: totalSqFt,
      grandTotalAmount: grandTotal,
    );
  }
}

class OptionCardTheme {
  final Color borderColor;
  final Color softBgColor;
  final Color accentTextColor;

  const OptionCardTheme({
    required this.borderColor,
    required this.softBgColor,
    required this.accentTextColor,
  });

  static const greenCenter = OptionCardTheme(
    borderColor: Color(0xFF16A34A),
    softBgColor: Color(0xFFF0FDF4),
    accentTextColor: Color(0xFF15803D),
  );

  static const purpleCove = OptionCardTheme(
    borderColor: Color(0xFF9333EA),
    softBgColor: Color(0xFFFAF5FF),
    accentTextColor: Color(0xFF7E22CE),
  );
}

Widget buildSharedOptionHeaderCard({
  required String title,
  required OptionCardTheme theme,
  required VoidCallback onAddTap,
}) {
  return Container(
    width: double.infinity,
    height: 54,
    padding: const EdgeInsets.symmetric(horizontal: 14),
    decoration: BoxDecoration(
      color: theme.softBgColor,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: theme.borderColor, width: 1.5),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: theme.accentTextColor,
              letterSpacing: 0.2,
            ),
          ),
        ),
        const SizedBox(width: 8),
        InkWell(
          onTap: onAddTap,
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add, size: 18, color: theme.accentTextColor),
                const SizedBox(width: 4),
                Text(
                  'ADD',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: theme.accentTextColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

Widget buildUnifiedOptionCard({
  required String title,
  required bool isActive,
  required OptionCardTheme theme,
  required VoidCallback onAddTap,
  required VoidCallback onEditTap,
  required VoidCallback onAddRowTap,
  required VoidCallback onDeleteTap,
  Widget? childInputs,
  String? unitValue,
  List<String>? unitItems,
  ValueChanged<String?>? onUnitChanged,
}) {
  if (!isActive) {
    return buildSharedOptionHeaderCard(
      title: title,
      theme: theme,
      onAddTap: onAddTap,
    );
  }

  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: theme.softBgColor,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: theme.borderColor, width: 2.5),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 11.5,
                        color: theme.accentTextColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.check_circle, color: theme.borderColor, size: 14),
                  if (unitValue != null && unitItems != null && onUnitChanged != null) ...[
                    const SizedBox(width: 4),
                    FittedBox(
                      child: Container(
                        height: 24,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: theme.borderColor),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: unitItems.contains(unitValue) ? unitValue : unitItems.first,
                            isDense: true,
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black87),
                            items: unitItems.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                            onChanged: onUnitChanged,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextButton.icon(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    foregroundColor: theme.accentTextColor,
                  ),
                  icon: const Icon(Icons.edit_note, size: 14),
                  label: const Text('EDIT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                  onPressed: onEditTap,
                ),
                const SizedBox(width: 4),
                IconButton(
                  tooltip: 'Add Row',
                  icon: Icon(Icons.add_circle_outline, color: theme.borderColor, size: 16),
                  onPressed: onAddRowTap,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 6),
                IconButton(
                  tooltip: 'Delete',
                  icon: const Icon(Icons.delete_outline, color: Colors.red, size: 16),
                  onPressed: onDeleteTap,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ],
        ),
        if (childInputs != null) ...[
          const SizedBox(height: 10),
          childInputs,
        ],
      ],
    ),
  );
}
