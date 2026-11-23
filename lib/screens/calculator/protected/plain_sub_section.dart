// PROTECTED MODULE - DO NOT MODIFY OR OVERWRITE THIS FILE
import 'package:flutter/material.dart';
import '../calculator_controller.dart';
import '../widgets/quick_add/plain_ceiling/plain_ceiling_card.dart';

class PlainSubSection extends StatelessWidget {
  final CalculatorController ctrl;
  final VoidCallback onChanged;

  const PlainSubSection({super.key, required this.ctrl, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return PlainCeilingCard(ctrl: ctrl, onChanged: onChanged);
  }
}
