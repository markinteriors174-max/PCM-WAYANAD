import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import '../../../models/quotation.dart';
import 'pdf_widgets.dart';
import '../../../utils/calculator_utils.dart';

class QuotationSummaryBuilder {
  static pw.Widget buildSummary({
    required List<QuotationItem> items, required List<PaymentRecord> payments,
    required double totalAmount, required double paidAmount, required double balanceAmount,
    required bool includeWastage, required pw.Font font, required pw.Font boldFont,
    required NumberFormat currencyFormat,
    double discountPercent = 0,
  }) {
    final double safeTotalAmount = totalAmount.isFinite ? totalAmount : 0.0;
    final double safePaidAmount = paidAmount.isFinite ? paidAmount : 0.0;

    // REQUIREMENT 2: Recompute balance from scratch to guarantee exact math.
    // ADVANCE PAID + BALANCE DUE = TOTAL WAGES — no rounding drift possible.
    final double computedBalance = safeTotalAmount - safePaidAmount;
    final double safeBalanceAmount = computedBalance.isFinite ? computedBalance : 0.0;

    final netAreaRaw = items.fold(0.0, (sum, item) {
      return sum + CalculatorUtils.getNormalizedAreaSqFt(item);
    });
    final netArea = netAreaRaw.isFinite ? netAreaRaw : 0.0;
    final wastageBuffer = netArea * 0.05;
    final grandTotalArea = netArea * 1.05;

    final double safeSubtotal = safeTotalAmount / 1.05;
    final double safeWastage = safeTotalAmount - safeSubtotal;

    // REQUIREMENT 1: Complete 31-day pastel color matrix keyed to DateTime.now().day
    // Each day of the month gets a unique, beautiful soft pastel background color.
    final List<PdfColor> dayColors = [
      PdfColor.fromInt(0xfffff0f5), // Day 1  — LavenderBlush
      PdfColor.fromInt(0xfff0f8ff), // Day 2  — AliceBlue
      PdfColor.fromInt(0xfff5f5dc), // Day 3  — Beige
      PdfColor.fromInt(0xfffff8dc), // Day 4  — Cornsilk
      PdfColor.fromInt(0xffe0f7fa), // Day 5  — Cyan Tint
      PdfColor.fromInt(0xfffff9e6), // Day 6  — Soft Amber
      PdfColor.fromInt(0xfff0f4f8), // Day 7  — Slate Pastel
      PdfColor.fromInt(0xfffff0f0), // Day 8  — Soft Rose
      PdfColor.fromInt(0xfffaf0e6), // Day 9  — Linen
      PdfColor.fromInt(0xfff3e5f5), // Day 10 — Soft Purple
      PdfColor.fromInt(0xfffff8e1), // Day 11 — Soft Amber
      PdfColor.fromInt(0xffe0ffff), // Day 12 — LightCyan
      PdfColor.fromInt(0xfff5fffa), // Day 13 — MintCream
      PdfColor.fromInt(0xffffe4e1), // Day 14 — MistyRose
      PdfColor.fromInt(0xffFFFacd), // Day 15 — LemonChiffon
      PdfColor.fromInt(0xffffe4b5), // Day 16 — Moccasin Light
      PdfColor.fromInt(0xffffefd5), // Day 17 — PapayaWhip
      PdfColor.fromInt(0xfffff8e7), // Day 18 — Cosmic Latte
      PdfColor.fromInt(0xfff0ffff), // Day 19 — Azure
      PdfColor.fromInt(0xffe8f5e9), // Day 20 — Soft Green
      PdfColor.fromInt(0xffe1f5fe), // Day 21 — Soft Blue
      PdfColor.fromInt(0xfff9fbe7), // Day 22 — Soft Lime
      PdfColor.fromInt(0xfffff5ee), // Day 23 — Seashell
      PdfColor.fromInt(0xfff8f8ff), // Day 24 — GhostWhite
      PdfColor.fromInt(0xfff0fff0), // Day 25 — Honeydew
      PdfColor.fromInt(0xffe6e6fa), // Day 26 — Lavender
      PdfColor.fromInt(0xfffdf5e6), // Day 27 — OldLace
      PdfColor.fromInt(0xfff4f9f4), // Day 28 — Soft Emerald
      PdfColor.fromInt(0xfffafff2), // Day 29 — Light Lime Tint
      PdfColor.fromInt(0xffFFFdf0), // Day 30 — Ivory Premium
      PdfColor.fromInt(0xfffff2f2), // Day 31 — Soft Coral Tint
    ];

    // Clamp to valid 0-based array index (day 1→index 0, day 31→index 30)
    final int todayIndex = (DateTime.now().day - 1).clamp(0, 30);
    final PdfColor advanceColor = dayColors[todayIndex];

    return pw.Align(
      alignment: pw.Alignment.centerRight,
      child: pw.Container(
        width: 220, // Reduced width
        padding: const pw.EdgeInsets.all(10), // Reduced padding
        decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.brown, width: 1.5), color: PdfColors.white),
        child: pw.Column(children: [
          if (includeWastage) ...[
            PdfWidgets.summaryRow('NET AREA:', '${netArea.toStringAsFixed(2)} SqFt', font: font),
            PdfWidgets.summaryRow('WASTAGE (5%):', '${wastageBuffer.toStringAsFixed(2)} SqFt', font: font),
            pw.Divider(color: PdfColors.brown100, thickness: 0.5),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 6),
              decoration: const pw.BoxDecoration(color: PdfColors.yellow100, borderRadius: pw.BorderRadius.all(pw.Radius.circular(3))),
              child: PdfWidgets.summaryRow('TOTAL AREA:', '${grandTotalArea.toStringAsFixed(2)} SqFt', font: boldFont, color: PdfColors.blue900, isLarge: false),
            ),
          ] else ...[
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 6),
              decoration: const pw.BoxDecoration(color: PdfColors.yellow100, borderRadius: pw.BorderRadius.all(pw.Radius.circular(3))),
              child: PdfWidgets.summaryRow('TOTAL AREA:', '${netArea.toStringAsFixed(2)} SqFt', font: boldFont, color: PdfColors.blue900, isLarge: false),
            ),
          ],
          pw.Divider(color: PdfColors.brown100, thickness: 0.5),
          if (includeWastage) ...[
            PdfWidgets.summaryRow('SUBTOTAL:', currencyFormat.format(safeSubtotal.isFinite ? safeSubtotal : 0.0), font: font),
            PdfWidgets.summaryRow('WASTAGE:', currencyFormat.format(safeWastage.isFinite ? safeWastage : 0.0), font: font),
            pw.Divider(color: PdfColors.brown100, thickness: 0.5),
          ],
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 6),
            decoration: const pw.BoxDecoration(
              color: PdfColors.pink50,
              borderRadius: pw.BorderRadius.all(pw.Radius.circular(3)),
            ),
            child: PdfWidgets.summaryRow('TOTAL WAGES:', currencyFormat.format(safeTotalAmount), font: boldFont, color: PdfColors.black),
          ),
          // DISCOUNT ROW — shown only when a discount percentage is active
          if (discountPercent > 0 && discountPercent < 100) ...[
            pw.Divider(color: PdfColors.brown100, thickness: 0.5),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 6),
              decoration: const pw.BoxDecoration(
                color: PdfColor.fromInt(0xfffff3e0), // Soft Light Orange / Pale Gold
                borderRadius: pw.BorderRadius.all(pw.Radius.circular(3)),
              ),
              child: PdfWidgets.summaryRow(
                'DISCOUNT APPLIED (${discountPercent % 1 == 0 ? discountPercent.toInt() : discountPercent.toStringAsFixed(1)}%):',
                '-${currencyFormat.format(safeTotalAmount * discountPercent / (100 - discountPercent))}',
                font: boldFont,
                color: PdfColors.green900,
              ),
            ),
          ],
          pw.Divider(color: PdfColors.brown100, thickness: 0.5),
          ...payments.map((p) {
            final dateStr = p.date.trim().isNotEmpty ? p.date.trim().split(' ').first : 'Payment';
            final descStr = p.description.trim().isNotEmpty ? p.description.trim().toUpperCase() : 'PAYMENT';
            final amtVal = p.amount.isFinite ? p.amount : 0.0;
            return PdfWidgets.summaryRow('$dateStr | $descStr:', currencyFormat.format(amtVal), font: font);
          }),
          if (payments.isNotEmpty) ...[
            pw.Divider(color: PdfColors.brown100, thickness: 0.5),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 6),
              decoration: pw.BoxDecoration(
                color: advanceColor,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
              ),
              child: PdfWidgets.summaryRow('ADVANCE PAID:', currencyFormat.format(safePaidAmount), font: boldFont, color: PdfColors.black),
            ),
          ],
          pw.Divider(color: PdfColors.brown900, thickness: 1.2),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 8),
            decoration: const pw.BoxDecoration(
              color: PdfColors.red50,
              borderRadius: pw.BorderRadius.all(pw.Radius.circular(4)),
            ),
            child: PdfWidgets.summaryRow('BALANCE DUE:', currencyFormat.format(safeBalanceAmount), font: boldFont, color: PdfColors.black, isLarge: true),
          ),
        ]),
      ),
    );
  }
}
