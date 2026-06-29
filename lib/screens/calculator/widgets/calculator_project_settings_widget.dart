import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../calculator_controller.dart';

class CalculatorProjectSettingsWidget extends StatelessWidget {
  final CalculatorController ctrl;

  const CalculatorProjectSettingsWidget({super.key, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: ctrl.globalMaterialCostController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: AppStyles.inputDecoration('Material Cost (₹/SqFt)').copyWith(
                  prefixText: '₹ ',
                  prefixStyle: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.labelColor),
                ),
                style: const TextStyle(fontWeight: FontWeight.bold),
                onChanged: (_) {
                  ctrl.updateLivePreview();
                  ctrl.triggerAutoSave();
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: ctrl.globalMarginController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: AppStyles.inputDecoration('My Margin (₹/SqFt)').copyWith(
                  prefixText: '₹ ',
                  prefixStyle: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.labelColor),
                ),
                style: const TextStyle(fontWeight: FontWeight.bold),
                onChanged: (_) {
                  ctrl.updateLivePreview();
                  ctrl.triggerAutoSave();
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}
