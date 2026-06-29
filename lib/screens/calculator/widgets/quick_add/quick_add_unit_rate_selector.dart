import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';
import '../../../../providers/language_provider.dart';
import '../../calculator_controller.dart';

class QuickAddUnitRateSelector extends StatelessWidget {
  final CalculatorController ctrl;
  final LanguageProvider lang;
  final ValueChanged<String?> onUnitChanged;

  const QuickAddUnitRateSelector({
    super.key,
    required this.ctrl,
    required this.lang,
    required this.onUnitChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          flex: 2,
          child: DropdownButtonFormField<String>(
            isExpanded: true,
            initialValue: ['SqFt', 'Meters', 'Inches', 'mm', 'Feet'].contains(ctrl.unit) ? ctrl.unit : 'SqFt',
            decoration: AppStyles.inputDecoration('Unit').copyWith(
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
            ),
            items: ['SqFt', 'Meters', 'Inches', 'mm', 'Feet']
                .map((val) => DropdownMenuItem(
                      value: val,
                      child: Text(
                        val,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ))
                .toList(),
            onChanged: onUnitChanged,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 3,
          child: TextField(
            controller: ctrl.rateController,
            keyboardType: TextInputType.number,
            decoration: AppStyles.inputDecoration(lang.translate('RATE')),
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
            onChanged: (_) {
              ctrl.updateLivePreview();
              ctrl.triggerAutoSave();
            },
          ),
        ),
      ],
    );
  }
}
