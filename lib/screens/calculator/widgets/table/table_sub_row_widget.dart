import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';
import '../../../../utils/calculator_utils.dart';

class TableSubRowWidget extends StatelessWidget {
  final String title;
  final double length;
  final double width;
  final double qty;
  final double rate;
  final double total;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const TableSubRowWidget({
    super.key,
    required this.title,
    required this.length,
    required this.width,
    required this.qty,
    required this.rate,
    required this.total,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(
          bottom: BorderSide(color: AppColors.border.withValues(alpha: 0.1)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 26,
            child: Row(
              children: [
                const SizedBox(width: 12),
                const Icon(Icons.subdirectory_arrow_right, size: 12, color: Colors.black38),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontSize: 11, color: Colors.black54, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 8,
            child: Text(
              length > 0 ? length.toStringAsFixed(1) : '-',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, color: Colors.black54),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 8,
            child: Text(
              width > 0 ? width.toStringAsFixed(1) : '-',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, color: Colors.black54),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 6,
            child: Text(
              qty.toInt().toString(),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, color: Colors.black54),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 15,
            child: Text(
              '₹${CalculatorUtils.formatIndianCurrency(rate)}',
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 11, color: Colors.black54, fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 18,
            child: Text(
              '₹${CalculatorUtils.formatIndianCurrency(total)}',
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 11, color: Colors.black54, fontWeight: FontWeight.bold),
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
                    child: Icon(Icons.edit, color: Colors.black38, size: 16),
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
