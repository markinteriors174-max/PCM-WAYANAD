import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import '../../../models/quotation.dart';
import 'pdf_widgets.dart';
import '../../../utils/calculator_utils.dart';

class QuotationRowBuilder {
  static double _getFactor(String unit) {
    if (unit == 'Meters' || unit == 'SqM') return 10.764;
    if (unit == 'Inches') return 1.0 / 144.0;
    if (unit == 'mm') return 10.764 / 1000000.0;
    return 1.0;
  }

  static pw.TableRow buildRoomHeaderRow(
      String roomName,
      double roomTotal,
      pw.Font boldFont,
      NumberFormat currencyFormat, {
        String? floor,
        String? roomNumber,
        String? colorPattern,
      }) {
    final safeRoomName = roomName.trim().isEmpty ? 'GENERAL' : roomName.trim();
    final safeTotal = roomTotal.isFinite ? roomTotal : 0.0;

    final List<String> details = [];
    if (floor != null && floor.isNotEmpty && floor != 'Ground Floor') details.add(floor.toUpperCase());
    if (roomNumber != null && roomNumber.isNotEmpty) details.add('RM #$roomNumber');
    if (colorPattern != null && colorPattern.isNotEmpty && colorPattern != 'None') details.add('THEME: $colorPattern');

    final String fullTitle = details.isNotEmpty
        ? '${safeRoomName.toUpperCase()} [${details.join(' | ')}]'
        : safeRoomName.toUpperCase();

    return pw.TableRow(
      decoration: const pw.BoxDecoration(color: PdfColors.brown50),
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: pw.Text(
            fullTitle,
            style: pw.TextStyle(font: boldFont, fontSize: 8.5, color: PdfColors.brown900),
          ),
        ),
        pw.SizedBox(),
        pw.SizedBox(),
        pw.SizedBox(),
        pw.SizedBox(),
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Text(
              'Total: ${currencyFormat.format(safeTotal)}',
              style: pw.TextStyle(font: boldFont, fontSize: 8.5, color: PdfColors.brown900),
            ),
          ),
        ),
      ],
    );
  }

  static pw.TableRow buildDesignHeaderRow(
      String designName,
      double designTotal,
      pw.Font boldFont,
      NumberFormat currencyFormat,
      ) {
    final safeDesignName = designName.trim().isEmpty ? 'STANDARD DESIGN' : designName.trim();
    final safeTotal = designTotal.isFinite ? designTotal : 0.0;
    return pw.TableRow(
      decoration: const pw.BoxDecoration(color: PdfColors.purple50),
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 3),
          child: pw.Text(
            safeDesignName.toUpperCase(),
            style: pw.TextStyle(font: boldFont, fontSize: 8, color: PdfColors.black),
          ),
        ),
        pw.SizedBox(),
        pw.SizedBox(),
        pw.SizedBox(),
        pw.SizedBox(),
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          child: pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Text(
              'Sub: ${currencyFormat.format(safeTotal)}',
              style: pw.TextStyle(font: boldFont, fontSize: 8, color: PdfColors.black),
            ),
          ),
        ),
      ],
    );
  }

  static pw.TableRow buildPlainItemRow(
      QuotationItem item,
      pw.Font font,
      pw.Font boldFont,
      NumberFormat currencyFormat,
      ) {
    final double factor = _getFactor(item.unit);
    final double totalArea = item.area;
    final double centralComp = item.centralArea * item.quantity;
    final double coveComp = item.coveRft * item.quantity;
    final double plainArea = (totalArea - centralComp - coveComp).clamp(0, double.infinity);

    // FIX: Skip the Plain row if it's 0 and the item is clearly just a container for design elements
    if (plainArea <= 0.01 && (item.hasCentralDesign || item.hasCove)) {
      return pw.TableRow(
        children: [
          pw.SizedBox(),
          pw.SizedBox(),
          pw.SizedBox(),
          pw.SizedBox(),
          pw.SizedBox(),
          pw.SizedBox(),
        ],
      );
    }

    final double totalPlainSqFt = plainArea * factor;
    final double totalCost = totalPlainSqFt * item.rate;

    final String unitLabel = CalculatorUtils.getAreaUnitLabel(item.unit);
    final String areaDisplay = factor != 1.0
        ? '${(plainArea).toStringAsFixed(2)} $unitLabel (${totalPlainSqFt.toStringAsFixed(2)} SqFt)'
        : '${totalPlainSqFt.toStringAsFixed(2)} SqFt';

    return pw.TableRow(
      decoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xfff8fafc)),
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.only(left: 16, top: 4, bottom: 4, right: 4),
          child: pw.Text(
            'PLAIN DESIGN',
            style: pw.TextStyle(font: boldFont, fontSize: 8),
          ),
        ),
        PdfWidgets.tableCell(
          '${item.length.toStringAsFixed(1)} x ${item.width.toStringAsFixed(1)}',
          font: font,
          fontSize: 7.5,
        ),
        PdfWidgets.tableCell(item.quantity.toInt().toString(), font: font, fontSize: 7.5),
        PdfWidgets.tableCell(areaDisplay, font: font, fontSize: 7.5),
        PdfWidgets.tableCell('${currencyFormat.format(item.rate)} /SqFt', font: font, fontSize: 7.5),
        PdfWidgets.tableCell(
          currencyFormat.format(totalCost),
          font: boldFont,
          isBold: true,
          fontSize: 7.5,
        ),
      ],
    );
  }

  static pw.TableRow buildCoveDesignRow(
      QuotationItem item,
      pw.Font font,
      pw.Font boldFont,
      NumberFormat currencyFormat,
      ) {
    final double factor = _getFactor(item.unit);
    final double q = item.quantity.isFinite ? item.quantity : 1.0;
    double rftVal = item.coveRft.isFinite ? item.coveRft : 0.0;

    // Self-healing check: If metric and rftVal was previously stored in SqFt (already multiplied by factor)
    if ((item.unit == 'Meters' || item.unit == 'SqM') && factor > 1.0 && rftVal > 0) {
      double l1 = item.coveLength > 0 ? item.coveLength : item.length;
      double w1 = item.coveWidth > 0 ? item.coveWidth : item.width;
      double q1 = item.coveQuantity > 0 ? item.coveQuantity : 1.0;
      double l2 = item.coveLength2;
      double w2 = item.coveWidth2 > 0 ? item.coveWidth2 : w1;
      double q2 = item.coveQuantity2 > 0 ? item.coveQuantity2 : 0.0;
      double nativeCalc = (l1 * w1 * q1) + (l2 * w2 * q2);
      if (nativeCalc > 0 && (rftVal - (nativeCalc * factor)).abs() < (rftVal - nativeCalc).abs()) {
        rftVal = rftVal / factor;
      }
    }

    final double totalUnits = rftVal * q;
    final double totalSqFt = totalUnits * factor;
    final double rate = item.coveRate > 0 ? item.coveRate : item.rate;
    final double totalCost = totalSqFt * rate;

    final String unitLabel = CalculatorUtils.getAreaUnitLabel(item.unit);
    final String areaDisplay = factor != 1.0
        ? '${totalUnits.toStringAsFixed(2)} $unitLabel (${totalSqFt.toStringAsFixed(2)} SqFt)'
        : '${totalSqFt.toStringAsFixed(2)} SqFt';

    double displayLength = item.coveLength > 0 ? item.coveLength : item.length;
    double displayWidth = item.coveWidth > 0 ? item.coveWidth : item.width;

    return pw.TableRow(
      decoration: const pw.BoxDecoration(color: PdfColors.green50),
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.only(left: 24, top: 4, bottom: 4, right: 4),
          child: pw.Text(
            'COVE DESIGN',
            style: pw.TextStyle(font: boldFont, fontSize: 8, color: PdfColors.black),
          ),
        ),
        PdfWidgets.tableCell(
          '${displayLength.toStringAsFixed(1)} x ${displayWidth.toStringAsFixed(1)}',
          font: font,
          fontSize: 7.5,
        ),
        PdfWidgets.tableCell(q.toInt().toString(), font: font, fontSize: 7.5),
        PdfWidgets.tableCell(areaDisplay, font: font, fontSize: 7.5),
        PdfWidgets.tableCell('${currencyFormat.format(rate)} /SqFt', font: font, fontSize: 7.5),
        PdfWidgets.tableCell(
          currencyFormat.format(totalCost),
          font: boldFont,
          isBold: true,
          fontSize: 7.5,
          color: PdfColors.black,
        ),
      ],
    );
  }

  static pw.TableRow buildCentralDesignRow(
      QuotationItem item,
      pw.Font font,
      pw.Font boldFont,
      NumberFormat currencyFormat,
      ) {
    final double factor = _getFactor(item.unit);
    final double q = item.quantity.isFinite ? item.quantity : 1.0;
    final double areaVal = item.centralArea.isFinite ? item.centralArea : 0.0;
    final double totalUnits = areaVal * q;
    final double totalSqFt = totalUnits * factor;
    final double rate = item.centralRate > 0 ? item.centralRate : item.rate;
    final double totalCost = totalSqFt * rate;

    final String unitLabel = (item.unit == 'Meters' || item.unit == 'SqM') ? 'SqM' : 'SqFt';
    final String areaDisplay = factor != 1.0
        ? '${totalUnits.toStringAsFixed(2)} $unitLabel (${totalSqFt.toStringAsFixed(2)} SqFt)'
        : '${totalSqFt.toStringAsFixed(2)} SqFt';

    final name = item.designName.toLowerCase();
    final isRound = name.contains('round') || name.contains('curve') || name.contains('custom') || name.contains('circle') || name.contains('radius');
    final String centerLabel = isRound ? 'ROUND DESIGN' : 'CENTER DESIGN';

    return pw.TableRow(
      decoration: const pw.BoxDecoration(color: PdfColors.blue50),
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.only(left: 24, top: 4, bottom: 4, right: 4),
          child: pw.Text(
            centerLabel,
            style: pw.TextStyle(font: boldFont, fontSize: 8, color: PdfColors.black),
          ),
        ),
        PdfWidgets.tableCell(
          '${item.centralLength.toStringAsFixed(1)} x ${item.centralWidth.toStringAsFixed(1)}',
          font: font,
          fontSize: 7.5,
        ),
        PdfWidgets.tableCell(q.toInt().toString(), font: font, fontSize: 7.5),
        PdfWidgets.tableCell(areaDisplay, font: font, fontSize: 7.5),
        PdfWidgets.tableCell('${currencyFormat.format(rate)} /SqFt', font: font, fontSize: 7.5),
        PdfWidgets.tableCell(
          currencyFormat.format(totalCost),
          font: boldFont,
          isBold: true,
          fontSize: 7.5,
          color: PdfColors.black,
        ),
      ],
    );
  }

  static pw.TableRow buildItemRow(
      QuotationItem item,
      pw.Font font,
      pw.Font boldFont,
      NumberFormat currencyFormat,
      ) {
    // This is now a legacy bridge, ideally use the split methods in TableBuilder
    return buildPlainItemRow(item, font, boldFont, currencyFormat);
  }
}
