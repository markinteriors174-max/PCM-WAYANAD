import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';
import '../../calculator_controller.dart';
import '../../../../models/quotation.dart';

class QuickAddSubmitButton extends StatelessWidget {
  final CalculatorController ctrl;
  final QuotationItem? existingItem;
  final int? existingIndex;

  const QuickAddSubmitButton({
    super.key,
    required this.ctrl,
    this.existingItem,
    this.existingIndex,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ctrl,
      builder: (context, _) {
        final double l = double.tryParse(ctrl.lengthController.text) ?? 0.0;
        final double w = double.tryParse(ctrl.widthController.text) ?? 0.0;
        final double ma = double.tryParse(ctrl.areaController.text) ?? 0.0;
        final double coveSqft = double.tryParse(ctrl.coveRftController.text) ?? 0.0;
        final double centralSqft = double.tryParse(ctrl.centralAreaController.text) ?? 0.0;

        final bool hasCoveActive = ctrl.hasCove || coveSqft > 0;
        final bool hasCentralActive = ctrl.hasCentralDesign || centralSqft > 0;
        final bool hasData = (l > 0 && w > 0) || ma > 0 || l > 0 || hasCoveActive || hasCentralActive || ctrl.livePreviewAreaSqFt > 0;

        final Color btnColor = hasData ? const Color(0xFF15803D) : const Color(0xFF0F766E);

        return Container(
          width: double.infinity,
          height: 54,
          margin: const EdgeInsets.only(top: 8, bottom: 6),
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: btnColor,
              foregroundColor: Colors.white,
              elevation: 3,
              shadowColor: btnColor.withValues(alpha: 0.4),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              // Ensure design and room are non-null defaults
              if (ctrl.selectedDesign == null || ctrl.selectedDesign!.trim().isEmpty) {
                ctrl.selectedDesign = 'Plain Ceiling';
              }
              if (ctrl.selectedRoom == null || ctrl.selectedRoom!.trim().isEmpty) {
                ctrl.selectedRoom = ctrl.roomController.text.trim().isNotEmpty
                    ? ctrl.roomController.text.trim()
                    : 'Room 1';
              }
              if (ctrl.rateController.text.trim().isEmpty) {
                ctrl.rateController.text = '105';
              }

              // If cove details were filled, ensure hasCove is true
              if (coveSqft > 0 || ctrl.coveLengthController.text.isNotEmpty) {
                ctrl.hasCove = true;
              }

              final messenger = ScaffoldMessenger.of(context);
              void showError(String err) {
                messenger.showSnackBar(SnackBar(
                  content: Text(err),
                  backgroundColor: AppColors.alertRed,
                  duration: const Duration(seconds: 2),
                ));
              }

              bool success = false;
              if (existingIndex != null) {
                success = ctrl.updateQuotationItem(existingIndex!, showError);
              } else {
                success = ctrl.addToQuotation(showError);
              }

              if (success) {
                Navigator.pop(context);
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('✓ Entry added to measurement sheet successfully!'),
                    backgroundColor: Color(0xFF15803D),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
            icon: const Icon(Icons.check_circle, color: Colors.white, size: 22),
            label: Text(
              existingItem != null ? 'UPDATE ENTRY' : 'ADD ENTRY',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 15,
                letterSpacing: 1.1,
              ),
            ),
          ),
        );
      },
    );
  }
}
