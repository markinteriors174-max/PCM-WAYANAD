import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';
import '../../calculator_controller.dart';
import '../../units/calculator_unit_helper.dart';

class QuickAddUnitRateSelector extends StatelessWidget {
  final CalculatorController ctrl;
  final TextEditingController rateController;
  final ValueChanged<String?> onUnitChanged;
  final Color borderColor;
  final String? currentUnit;

  const QuickAddUnitRateSelector({
    super.key,
    required this.ctrl,
    required this.rateController,
    required this.onUnitChanged,
    required this.borderColor,
    this.currentUnit,
  });

  @override
  Widget build(BuildContext context) {
    final units = CalculatorUnitHelper.availableUnits.toSet().toList();
    if (!units.contains('Meter')) units.insert(0, 'Meter');

    String rawUnit = (currentUnit != null && currentUnit!.isNotEmpty) ? currentUnit! : ctrl.unit;
    if (rawUnit.toLowerCase() == 'meters') rawUnit = 'Meter';

    final resolvedUnit = units.contains(rawUnit) ? rawUnit : 'Meter';

    return Row(
      children: [
        Expanded(
          flex: 2,
          child: DropdownButtonFormField<String>(
            isExpanded: true,
            value: resolvedUnit,
            decoration: AppStyles.inputDecoration('UNIT').copyWith(
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              fillColor: Colors.white,
              filled: true,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: borderColor, width: 1.8),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: borderColor, width: 2.2),
              ),
            ),
            items: units.map((unit) {
              final idx = units.indexOf(unit);
              final uColor = CalculatorUnitHelper.getUnitColor(unit, idx);
              return DropdownMenuItem<String>(
                value: unit,
                child: Text(
                  unit,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: uColor),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              );
            }).toList(),
            onChanged: onUnitChanged,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 3,
          child: TextField(
            controller: rateController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: AppStyles.inputDecoration('RATE (₹)').copyWith(
              prefixText: '₹ ',
              prefixStyle: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: borderColor),
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              fillColor: Colors.white,
              filled: true,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: borderColor, width: 1.8),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: borderColor, width: 2.2),
              ),
            ),
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
            onTap: () {
              if (rateController.text == '105' || rateController.text == '105.0') {
                rateController.clear();
              } else {
                rateController.selection = TextSelection(baseOffset: 0, extentOffset: rateController.text.length);
              }
            },
            onChanged: (val) {
              ctrl.updateLivePreview();
              ctrl.triggerAutoSave();
            },
          ),
        ),
      ],
    );
  }
}
