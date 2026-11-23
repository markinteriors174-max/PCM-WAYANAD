import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import '../../../models/quotation.dart';
import 'pdf_widgets.dart';
import 'quotation_row_builder.dart';

class QuotationTableBuilder {
  static pw.Widget buildTable({
    required List<QuotationItem> items,
    required pw.Font font,
    required pw.Font boldFont,
    required NumberFormat currencyFormat,
  }) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.brown100),
      columnWidths: const {
        0: pw.FlexColumnWidth(3.0),
        1: pw.FlexColumnWidth(1.2),
        2: pw.FlexColumnWidth(0.6),
        3: pw.FlexColumnWidth(1.4),
        4: pw.FlexColumnWidth(1.2),
        5: pw.FlexColumnWidth(1.6),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.brown900),
          children: [
            PdfWidgets.tableHeader('DESCRIPTION', font: font, color: PdfColors.white, textAlign: pw.TextAlign.left),
            PdfWidgets.tableHeader('DIMENSIONS', font: font, color: PdfColors.white, textAlign: pw.TextAlign.left),
            PdfWidgets.tableHeader('QTY', font: font, color: PdfColors.white, textAlign: pw.TextAlign.right),
            PdfWidgets.tableHeader('TOTAL UNIT', font: font, color: PdfColors.white, textAlign: pw.TextAlign.left),
            PdfWidgets.tableHeader('RATE', font: font, color: PdfColors.white, textAlign: pw.TextAlign.right),
            PdfWidgets.tableHeader('TOTAL AMT', font: font, color: PdfColors.white, textAlign: pw.TextAlign.right),
          ],
        ),
        ...(() {
          double getUnitFactor(String unit) {
            if (unit == 'Meters' || unit == 'SqM') return 10.764;
            if (unit == 'Inches') return 1.0 / 144.0;
            if (unit == 'mm') return 10.764 / 1000000.0;
            return 1.0;
          }

          // Exclude hidden items from PDF table
          final visibleItems = items.where((it) => !it.isHidden).toList();

          final sanitizedItems = visibleItems.map((item) {
            if ((item.unit == 'Meters' || item.unit == 'SqM') && (item.hasCove || item.designName == 'Cove Light')) {
              final f = getUnitFactor(item.unit);
              double rftVal = item.coveRft.isFinite ? item.coveRft : 0.0;
              double l1 = item.coveLength > 0 ? item.coveLength : item.length;
              double w1 = item.coveWidth > 0 ? item.coveWidth : item.width;
              double q1 = item.coveQuantity > 0 ? item.coveQuantity : 1.0;
              double l2 = item.coveLength2;
              double w2 = item.coveWidth2 > 0 ? item.coveWidth2 : w1;
              double q2 = item.coveQuantity2 > 0 ? item.coveQuantity2 : 0.0;
              double nativeCalc = (l1 * w1 * q1) + (l2 * w2 * q2);
              if (nativeCalc > 0 && (rftVal - (nativeCalc * f)).abs() < (rftVal - nativeCalc).abs()) {
                rftVal = rftVal / f;
              }
              final q = item.quantity.isFinite && item.quantity > 0 ? item.quantity : 1.0;
              final rate = item.coveRate > 0 ? item.coveRate : item.rate;
              final trueTotalSqFt = rftVal * q * f;
              final trueAmount = trueTotalSqFt * rate;
              if (trueAmount > 0 && item.amount > trueAmount * 2) {
                return item.copyWith(
                  coveRft: rftVal,
                  area: rftVal * q,
                  amount: trueAmount,
                );
              }
            }
            return item;
          }).toList();

          Map<String, List<QuotationItem>> roomGroups = {};
          for (var item in sanitizedItems) {
            final roomName = item.roomName.trim().isEmpty ? 'GENERAL' : item.roomName.trim();
            if (!roomGroups.containsKey(roomName)) {
              roomGroups[roomName] = [];
            }
            roomGroups[roomName]!.add(item);
          }
          
          List<pw.TableRow> rows = [];
          for (var roomName in roomGroups.keys) {
            final roomItems = roomGroups[roomName]!;
            double roomTotalAmt = roomItems.fold(0.0, (s, i) => s + (i.amount.isFinite ? i.amount : 0.0));

            final firstItem = roomItems.first;
            rows.add(QuotationRowBuilder.buildRoomHeaderRow(
              roomName,
              roomTotalAmt,
              boldFont,
              currencyFormat,
              floor: firstItem.floor,
              roomNumber: firstItem.roomNumber,
              colorPattern: firstItem.colorPattern,
            ));

            Map<String, List<QuotationItem>> designGroups = {};
            for (var item in roomItems) {
              final design = item.designName.trim().isEmpty ? 'Standard Design' : item.designName.trim();
              if (!designGroups.containsKey(design)) {
                designGroups[design] = [];
              }
              designGroups[design]!.add(item);
            }

            for (var designName in designGroups.keys) {
              final designItems = designGroups[designName]!;
              double designTotalAmt = designItems.fold(0.0, (s, i) => s + (i.amount.isFinite ? i.amount : 0.0));

              rows.add(QuotationRowBuilder.buildDesignHeaderRow(designName, designTotalAmt, boldFont, currencyFormat));

              for (var item in designItems) {
                final double totalArea = item.area;
                final double centralComp = item.centralArea * item.quantity;
                final double coveComp = item.coveRft * item.quantity;
                final double plainArea = (totalArea - centralComp - coveComp).clamp(0, double.infinity);

                if (plainArea > 0.01 || (!item.hasCentralDesign && !item.hasCove)) {
                  rows.add(QuotationRowBuilder.buildPlainItemRow(item, font, boldFont, currencyFormat));
                }
                
                if (item.hasCentralDesign && item.centralArea > 0) {
                  rows.add(QuotationRowBuilder.buildCentralDesignRow(item, font, boldFont, currencyFormat));
                }
                
                if (item.hasCove && item.coveRft > 0) {
                  rows.add(QuotationRowBuilder.buildCoveDesignRow(item, font, boldFont, currencyFormat));
                }
              }
            }
          }
          return rows;
        })(),
      ],
    );
  }

  static pw.Widget buildMaterialsTable({
    required List<MaterialAssignment> materials,
    required pw.Font font,
    required pw.Font boldFont,
    required NumberFormat currencyFormat,
  }) {
    // 1. Group & Auto-Sum by base material name
    final Map<String, MaterialAssignment> grouped = {};
    
    for (var mat in materials) {
      String baseName = mat.materialName;
      final dashIdx = mat.materialName.lastIndexOf(' - ');
      if (dashIdx != -1) {
        baseName = mat.materialName.substring(0, dashIdx).trim();
      }
      
      final qty = mat.quantity.isFinite ? mat.quantity : 0.0;
      final amt = mat.amount.isFinite ? mat.amount : 0.0;
      
      if (grouped.containsKey(baseName)) {
        final existing = grouped[baseName]!;
        grouped[baseName] = MaterialAssignment(
          materialName: baseName,
          unit: mat.unit,
          rate: mat.rate,
          quantity: existing.quantity + qty,
          amount: existing.amount + amt,
        );
      } else {
        grouped[baseName] = MaterialAssignment(
          materialName: baseName,
          unit: mat.unit,
          rate: mat.rate,
          quantity: qty,
          amount: amt,
        );
      }
    }
    
    final List<MaterialAssignment> consolidatedList = grouped.values.toList();
    
    int index = 1;
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.brown100),
      columnWidths: const {
        0: pw.FlexColumnWidth(0.6),
        1: pw.FlexColumnWidth(4.5),
        2: pw.FlexColumnWidth(2.0),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xffe8f5e9)),
          children: [
            PdfWidgets.tableHeader('SL.NO', font: font, color: PdfColors.brown900, textAlign: pw.TextAlign.center),
            PdfWidgets.tableHeader('MATERIAL DESCRIPTION', font: font, color: PdfColors.brown900, textAlign: pw.TextAlign.left),
            PdfWidgets.tableHeader('QTY / TOTAL UNIT', font: font, color: PdfColors.brown900, textAlign: pw.TextAlign.right),
          ],
        ),
        ...consolidatedList.map((mat) {
          final currentSl = index++;
          final qtyStr = mat.quantity.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '');
          return pw.TableRow(
            children: [
              pw.Padding(
                padding: const pw.EdgeInsets.all(5),
                child: pw.Text(currentSl.toString(), style: pw.TextStyle(font: font, fontSize: 8), textAlign: pw.TextAlign.center),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(5),
                child: pw.Text(mat.materialName, style: pw.TextStyle(font: font, fontSize: 8)),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(5),
                child: pw.Text('$qtyStr ${mat.unit}', style: pw.TextStyle(font: font, fontSize: 8), textAlign: pw.TextAlign.right),
              ),
            ],
          );
        }),
      ],
    );
  }
}
