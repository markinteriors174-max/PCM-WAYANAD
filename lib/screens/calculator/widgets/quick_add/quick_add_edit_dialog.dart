import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';
import '../../calculator_controller.dart';

void showQuickAddEditDialog(BuildContext context, CalculatorController ctrl, String currentDesign) {
  final designController = TextEditingController(text: currentDesign);
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Edit Entry Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      content: TextField(controller: designController, decoration: AppStyles.inputDecoration('Design Name')),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryButton),
          onPressed: () {
            ctrl.selectedDesign = 'Other';
            ctrl.designController.text = designController.text;
            ctrl.notifyUI();
            ctrl.triggerAutoSave();
            Navigator.pop(ctx);
          },
          child: const Text('SAVE', style: TextStyle(color: Colors.white)),
        ),
      ],
    ),
  );
}
