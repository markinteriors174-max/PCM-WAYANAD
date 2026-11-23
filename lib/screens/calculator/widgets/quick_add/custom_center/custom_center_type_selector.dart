import 'package:flutter/material.dart';
import 'package:pcm_wayanad/theme/app_theme.dart';
import 'package:pcm_wayanad/screens/calculator/calculator_controller.dart';
import '../quick_add_unit_rate_selector.dart';

class CustomCenterTypeSelector extends StatelessWidget {
  final CalculatorController ctrl;
  final Color themeColor;
  final String activeType;
  final ValueChanged<String> onTypeChanged;

  const CustomCenterTypeSelector({
    super.key,
    required this.ctrl,
    required this.themeColor,
    required this.activeType,
    required this.onTypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('Type: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.labelColor)),
            const SizedBox(width: 8),
            ChoiceChip(
              label: const Text('Standard (Center)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              selected: activeType == 'Standard (Center)',
              selectedColor: themeColor.withValues(alpha: 0.3),
              backgroundColor: Colors.grey.shade200,
              labelStyle: TextStyle(color: activeType == 'Standard (Center)' ? Colors.green.shade900 : Colors.black87),
              onSelected: (_) => onTypeChanged('Standard (Center)'),
            ),
            const SizedBox(width: 6),
            ChoiceChip(
              label: const Text('Custom Center', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              selected: activeType == 'Custom Center',
              selectedColor: themeColor.withValues(alpha: 0.3),
              backgroundColor: Colors.grey.shade200,
              labelStyle: TextStyle(color: activeType == 'Custom Center' ? Colors.green.shade900 : Colors.black87),
              onSelected: (_) => onTypeChanged('Custom Center'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        QuickAddUnitRateSelector(
          ctrl: ctrl,
          rateController: ctrl.customCenterRateController,
          currentUnit: ctrl.customCenterUnit,
          borderColor: themeColor,
          onUnitChanged: (v) {
            if (v != null) {
              ctrl.customCenterUnit = v;
              ctrl.updateLivePreview();
              ctrl.triggerAutoSave();
            }
          },
        ),
      ],
    );
  }
}
