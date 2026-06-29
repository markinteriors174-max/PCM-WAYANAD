import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';
import '../../calculator_controller.dart';

class QuickAddEstimatePreview extends StatelessWidget {
  final CalculatorController ctrl;

  const QuickAddEstimatePreview({super.key, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 15),
          decoration: BoxDecoration(
            color: AppColors.resultGreen.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.resultGreen.withValues(alpha: 0.2)),
          ),
          alignment: Alignment.center,
          child: Column(
            children: [
              Text(
                'GRAND TOTAL: ₹${ctrl.livePreviewAmount.toStringAsFixed(1)}',
                style: const TextStyle(color: AppColors.resultGreen, fontWeight: FontWeight.w900, fontSize: 22),
              ),
              const SizedBox(height: 5),
              Text(
                'TOTAL AREA: ${ctrl.livePreviewAreaSqFt.toStringAsFixed(2)} SQFT',
                style: TextStyle(color: AppColors.resultGreen.withValues(alpha: 0.8), fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}
