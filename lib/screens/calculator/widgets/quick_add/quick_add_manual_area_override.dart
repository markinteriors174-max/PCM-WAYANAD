import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';
import '../../calculator_controller.dart';

class QuickAddManualAreaOverride extends StatelessWidget {
  final CalculatorController ctrl;
  final bool isCeilingDesign;
  final String areaUnit;

  const QuickAddManualAreaOverride({
    super.key, required this.ctrl, required this.isCeilingDesign, required this.areaUnit,
  });

  @override
  Widget build(BuildContext context) {
    if (!isCeilingDesign) return const SizedBox.shrink();
    return Column(
      children: [
        TextField(
          controller: ctrl.areaController,
          keyboardType: TextInputType.number,
          decoration: AppStyles.inputDecoration('Manual Area Override ($areaUnit)'),
          style: const TextStyle(fontWeight: FontWeight.bold),
          onChanged: (_) {
            ctrl.updateLivePreview();
            ctrl.triggerAutoSave();
          },
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}
