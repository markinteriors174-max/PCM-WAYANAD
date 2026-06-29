import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';
import '../../calculator_controller.dart';

class UnitSelectionWidget extends StatelessWidget {
  final CalculatorController ctrl;
  final ValueChanged<String?> onUnitChanged;

  const UnitSelectionWidget({
    super.key,
    required this.ctrl,
    required this.onUnitChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
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
    );
  }
}
