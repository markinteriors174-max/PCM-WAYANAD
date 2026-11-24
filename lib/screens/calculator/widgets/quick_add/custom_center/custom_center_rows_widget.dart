import 'package:flutter/material.dart';
import 'package:pcm_wayanad/theme/app_theme.dart';
import 'package:pcm_wayanad/screens/calculator/calculator_controller.dart';
import 'custom_center_primary_row.dart';
import 'custom_center_deduction_row.dart';

class CustomCenterRowsWidget extends StatelessWidget {
  final CalculatorController ctrl;
  final Color themeColor;
  final double rVal;
  final double deductionVal;
  final VoidCallback onChanged;

  const CustomCenterRowsWidget({
    super.key,
    required this.ctrl,
    required this.themeColor,
    required this.rVal,
    required this.deductionVal,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Primary Custom Center (Length / Width)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87)),
        const SizedBox(height: 6),
        if (rVal > 0) ...[
          Row(
            children: [
              Expanded(child: _field(ctrl.customCenterCircleRadiusController, 'RADIUS', readOnly: true)),
              const SizedBox(width: 6),
              Expanded(child: _field(ctrl.customCenterCircleAreaM2Controller, 'AREA (m²)', readOnly: true)),
              const SizedBox(width: 6),
              Expanded(child: _field(ctrl.customCenterCircleQtyController, 'QTY', readOnly: true)),
              const SizedBox(width: 6),
              Expanded(child: _field(ctrl.customCenterCircleSqftController, 'SQFT', readOnly: true)),
            ],
          ),
          const SizedBox(height: 8),
        ],
        CustomCenterPrimaryRow(
          ctrl: ctrl,
          themeColor: themeColor,
          onChanged: onChanged,
        ),
        if (deductionVal > 0) ...[
          const SizedBox(height: 10),
          CustomCenterDeductionRow(
            ctrl: ctrl,
            themeColor: themeColor,
            onChanged: onChanged,
          ),
        ],
      ],
    );
  }

  Widget _field(TextEditingController c, String l, {bool readOnly = false}) {
    return TextField(
      controller: c,
      readOnly: readOnly,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: AppStyles.inputDecoration(l).copyWith(
        fillColor: readOnly ? Colors.grey.shade100 : Colors.white,
        filled: true,
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: themeColor, width: 1.8)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: themeColor, width: 2.2)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      ),
      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: readOnly ? Colors.grey.shade700 : Colors.black),
    );
  }
}
