// PROTECTED MODULE - DO NOT MODIFY OR OVERWRITE THIS FILE
import 'package:flutter/material.dart';
import '../calculator_controller.dart';
import '../widgets/quick_add/standard_center/standard_center_widget.dart';
import '../widgets/quick_add/custom_center/custom_center_widget.dart';

class CenterSubSection extends StatelessWidget {
  final CalculatorController ctrl;
  final bool isActive;
  final String activeType;
  final ValueChanged<String> onTypeChanged;
  final ValueChanged<bool> onToggle;

  const CenterSubSection({
    super.key,
    required this.ctrl,
    required this.isActive,
    required this.activeType,
    required this.onTypeChanged,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    if (activeType == 'Standard (Center)') {
      return StandardCenterWidget(
        ctrl: ctrl,
        isActive: isActive,
        linearUnitLabel: 'Feet',
        areaUnitLabel: 'SqFt',
        activeType: activeType,
        onTypeChanged: onTypeChanged,
        onToggle: onToggle,
        onUnitChanged: (_) {},
      );
    } else {
      return CustomCenterWidget(
        ctrl: ctrl,
        isActive: isActive,
        linearUnitLabel: 'Feet',
        areaUnitLabel: 'SqFt',
        activeType: activeType,
        onTypeChanged: onTypeChanged,
        onToggle: onToggle,
        onUnitChanged: (_) {},
      );
    }
  }
}
