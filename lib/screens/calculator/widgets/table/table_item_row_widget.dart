import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../providers/language_provider.dart';
import '../../calculator_controller.dart';
import '../quick_add_bottom_sheet.dart';
import 'table_main_row_widget.dart';

class TableItemRowWidget extends StatelessWidget {
  final CalculatorController ctrl;
  final int idx;
  final VoidCallback onStateChanged;

  const TableItemRowWidget({
    super.key,
    required this.ctrl,
    required this.idx,
    required this.onStateChanged,
  });

  @override
  Widget build(BuildContext context) {
    final item = ctrl.currentItems[idx];

    return TableMainRowWidget(
      item: item,
      idx: idx,
      onEdit: () => QuickAddBottomSheet.show(context, ctrl, Provider.of<LanguageProvider>(context, listen: false), existingItem: item, existingIndex: idx),
      onDelete: () {
        ctrl.deleteQuotationItem(idx);
        onStateChanged();
      },
    );
  }
}
