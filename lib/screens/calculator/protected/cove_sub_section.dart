// PROTECTED MODULE - DO NOT MODIFY OR OVERWRITE THIS FILE
import 'package:flutter/material.dart';
import '../calculator_controller.dart';
import '../widgets/quick_add/cove_ceiling/cove_ceiling_card.dart';

class CoveSubSection extends StatelessWidget {
  final CalculatorController ctrl;
  final VoidCallback onChanged;

  const CoveSubSection({super.key, required this.ctrl, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return CoveCeilingCard(ctrl: ctrl, onChanged: onChanged);
  }
}
