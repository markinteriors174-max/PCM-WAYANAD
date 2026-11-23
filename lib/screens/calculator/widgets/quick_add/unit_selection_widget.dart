import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';
import '../../calculator_controller.dart';
import '../../units/calculator_unit_helper.dart';

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
    final units = CalculatorUnitHelper.availableUnits.toSet().toList();
    if (!units.contains('Meter')) units.insert(0, 'Meter');

    String rawUnit = ctrl.unit;
    if (rawUnit.toLowerCase() == 'meters') rawUnit = 'Meter';
    final resolvedUnit = units.contains(rawUnit) ? rawUnit : 'Meter';

    return DropdownButtonFormField<String>(
      isExpanded: true,
      value: resolvedUnit,
      decoration: AppStyles.inputDecoration('UNIT').copyWith(
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      ),
      items: units.map((unit) {
        final idx = units.indexOf(unit);
        final uColor = CalculatorUnitHelper.getUnitColor(unit, idx);
        return DropdownMenuItem<String>(
          value: unit,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: uColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: uColor, width: 1.6),
            ),
            child: Text(
              unit,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: uColor),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        );
      }).toList(),
      onChanged: onUnitChanged,
    );
  }
}
