import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../calculator/calculator_controller.dart';
import '../../../providers/language_provider.dart';

class CalculatorRevisionWidget extends StatelessWidget {
  final CalculatorController ctrl;
  final LanguageProvider lang;

  const CalculatorRevisionWidget({super.key, required this.ctrl, required this.lang});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 8),
          child: Text('PROJECT REVISION LOG', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1.5, color: AppColors.labelColor)),
        ),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: AppStyles.neumorphicDecoration(color: AppColors.border),
          child: Column(
            children: [
              TextField(
                controller: ctrl.originalAmountController,
                keyboardType: TextInputType.number,
                decoration: AppStyles.inputDecoration('Original Estimate Amount (₹)').copyWith(
                  labelStyle: const TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.0),
                  floatingLabelStyle: const TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.0),
                ),
                style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                onChanged: (_) => ctrl.triggerAutoSave(),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: ctrl.revisionNoteController,
                decoration: AppStyles.inputDecoration('Reason for Cost Variation').copyWith(
                  labelStyle: const TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.0),
                  floatingLabelStyle: const TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.0),
                ),
                style: const TextStyle(color: Colors.black),
                onChanged: (_) => ctrl.triggerAutoSave(),
              ),
              const SizedBox(height: 10),
              const Text(
                'Note: If a revision note is provided, the PDF will automatically update its title to "Work In Progress" and display the variation.',
                style: TextStyle(color: Colors.white54, fontSize: 10, fontStyle: FontStyle.italic),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
