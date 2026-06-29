import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';
import '../../../../models/quotation.dart';
import '../../../../utils/calculator_utils.dart';

class TableMainRowWidget extends StatelessWidget {
  final QuotationItem item; final int idx; final VoidCallback onEdit, onDelete;
  const TableMainRowWidget({super.key, required this.item, required this.idx, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final isArea = item.unit == 'SqFt' || item.unit == 'SqM' || item.unit == 'Meters' || item.unit == 'Inches' || item.unit == 'mm' || item.unit == 'Feet';
    double factor = 1.0;
    if (item.unit == 'Meters' || item.unit == 'SqM') {
      factor = 10.764;
    } else if (item.unit == 'Inches') {
      factor = 1.0 / 144.0;
    } else if (item.unit == 'mm') {
      factor = 10.764 / 1000000.0;
    }

    double displayLength = item.length;
    double displayWidth = item.width;
    if (item.hasCove) {
      if (displayLength == 0 && item.coveLength > 0) displayLength = item.coveLength;
      if (displayWidth == 0 && item.coveWidth > 0) displayWidth = item.coveWidth;
    } else if (item.hasCentralDesign) {
      if (displayLength == 0 && item.centralLength > 0) displayLength = item.centralLength;
      if (displayWidth == 0 && item.centralWidth > 0) displayWidth = item.centralWidth;
    }

    double mainTotal = item.amount > 0 ? item.amount : (isArea 
        ? (displayLength * displayWidth * factor) * item.quantity * item.rate 
        : displayLength * item.quantity * item.rate);
    if (mainTotal == 0 && item.area > 0) {
      double manualArea = (item.area / item.quantity) - item.coveRft - item.centralArea;
      if (manualArea < 0) manualArea = 0;
      mainTotal = (manualArea * factor) * item.quantity * item.rate;
    }

    String displayName = item.designName;
    if (item.hasCove && !item.isCeilingDesign) {
      displayName = 'Cove Design ($displayName)';
    } else if (item.hasCentralDesign && !item.isCeilingDesign) {
      displayName = 'Center Design ($displayName)';
    }

    Color rowBgColor = Colors.white;
    if (item.hasCove && !item.isCeilingDesign) {
      rowBgColor = const Color(0xFFE8F5E9); // Soft light green / mint background
    } else if (item.hasCentralDesign && !item.isCeilingDesign) {
      rowBgColor = const Color(0xFFE3F2FD); // Soft light blue / sky blue background
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(color: rowBgColor, border: Border(bottom: BorderSide(color: AppColors.border.withValues(alpha: 0.1)))),
      child: Row(
        children: [
          SizedBox(
            width: 25,
            child: Text(
              '${idx + 1}',
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black38),
            ),
          ),
          Expanded(
            flex: 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(displayName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.labelColor), overflow: TextOverflow.ellipsis, maxLines: 1),
                if (item.brandName != null && item.brandName!.isNotEmpty && item.brandName != 'Default')
                  Text(item.brandName!, style: const TextStyle(color: Colors.black54, fontSize: 9, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis, maxLines: 1),
              ],
            ),
          ),
          Expanded(
            flex: 8,
            child: Text(
              displayLength > 0 ? displayLength.toStringAsFixed(1) : '-',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 8,
            child: Text(
              displayWidth > 0 ? displayWidth.toStringAsFixed(1) : '-',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 6,
            child: Text(
              item.quantity.toInt().toString(),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 15,
            child: Text(
              '₹${CalculatorUtils.formatIndianCurrency(item.rate)}',
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 18,
            child: Text(
              '₹${CalculatorUtils.formatIndianCurrency(mainTotal)}',
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AppColors.resultGreen),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(
            width: 44,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: onEdit,
                  behavior: HitTestBehavior.opaque,
                  child: const Padding(
                    padding: EdgeInsets.all(2),
                    child: Icon(Icons.edit, color: AppColors.primaryButton, size: 16),
                  ),
                ),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: onDelete,
                  behavior: HitTestBehavior.opaque,
                  child: const Padding(
                    padding: EdgeInsets.all(2),
                    child: Icon(Icons.delete_outline, color: AppColors.alertRed, size: 16),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
