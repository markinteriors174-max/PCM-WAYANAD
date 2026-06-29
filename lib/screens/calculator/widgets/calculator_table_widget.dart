import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../calculator/calculator_controller.dart';
import 'table/table_header_widget.dart';
import 'table/table_item_row_widget.dart';
import 'table/table_add_button_widget.dart';

class CalculatorTableWidget extends StatelessWidget {
  final CalculatorController ctrl;
  final VoidCallback onStateChanged;

  const CalculatorTableWidget({super.key, required this.ctrl, required this.onStateChanged});

  @override
  Widget build(BuildContext context) {
    if (ctrl.currentItems.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'MEASUREMENT SHEET',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
              fontSize: 11,
              color: AppColors.labelColor,
            ),
          ),
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            final tableWidth = constraints.maxWidth > 480 ? constraints.maxWidth : 480.0;
            return Container(
              decoration: AppStyles.neumorphicDecoration(
                color: Colors.white,
                hasThickBorder: true,
                borderRadius: 12,
              ),
              clipBehavior: Clip.antiAlias,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: tableWidth,
                  child: Column(
                    children: [
                      const TableHeaderWidget(),
                      ...List.generate(ctrl.currentItems.length, (idx) {
                        return TableItemRowWidget(ctrl: ctrl, idx: idx, onStateChanged: onStateChanged);
                      }),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 15),
        TableAddButtonWidget(ctrl: ctrl),
      ],
    );
  }
}
