import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';
import '../../calculator_controller.dart';
import '../../../../models/quotation.dart';

class QuickAddSubmitButton extends StatelessWidget {
  final CalculatorController ctrl;
  final QuotationItem? existingItem;
  final int? existingIndex;

  const QuickAddSubmitButton({
    super.key, required this.ctrl, this.existingItem, this.existingIndex,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        bool success = false;
        final messenger = ScaffoldMessenger.of(context);
        void showError(String err) {
          messenger.showSnackBar(SnackBar(content: Text(err), backgroundColor: AppColors.alertRed));
        }

        if (existingIndex != null) {
          success = ctrl.updateQuotationItem(existingIndex!, showError);
        } else {
          success = ctrl.addToQuotation(showError);
        }
        if (success) Navigator.pop(context);
      },
      child: Container(
        height: 65,
        alignment: Alignment.center,
        decoration: AppStyles.neumorphicDecoration(color: AppColors.primaryButton, hasThickBorder: true),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Text(
              existingItem != null ? 'UPDATE ENTRY' : 'ADD ENTRY',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1.2),
            ),
          ],
        ),
      ),
    );
  }
}
