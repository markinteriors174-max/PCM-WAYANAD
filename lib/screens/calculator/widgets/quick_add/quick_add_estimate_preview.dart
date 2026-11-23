import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';
import '../../../../utils/calculator_utils.dart';
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
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.calculate_outlined, color: AppColors.resultGreen, size: 20),
                  const SizedBox(width: 6),
                  Text(
                    'THIS ENTRY TOTAL: ₹${CalculatorUtils.formatIndianCurrency(ctrl.livePreviewAmount)}',
                    style: const TextStyle(color: AppColors.resultGreen, fontWeight: FontWeight.w900, fontSize: 20),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'ENTRY AREA: ${CalculatorUtils.formatNumber(ctrl.livePreviewAreaSqFt)} SQFT  •  (ഈ ഡിസൈൻ എൻട്രി തുക)',
                style: TextStyle(color: AppColors.resultGreen.withValues(alpha: 0.85), fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}
