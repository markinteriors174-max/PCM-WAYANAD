import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';
import '../../calculator_controller.dart';

class QuickAddDimensionsRow extends StatelessWidget {
  final CalculatorController ctrl;
  final bool isCeilingDesign;

  const QuickAddDimensionsRow({
    super.key, required this.ctrl, required this.isCeilingDesign,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _field('L', ctrl.lengthController, onChanged: (val) {
          if (ctrl.coveLengthController.text.isEmpty || ctrl.coveLengthController.text == ctrl.lastLength) {
            ctrl.coveLengthController.text = val;
          }
          ctrl.lastLength = val;
          ctrl.updateLivePreview();
          ctrl.triggerAutoSave();
        })),
        const SizedBox(width: 8),
        Expanded(child: _field('Width', ctrl.widthController, enabled: true, onChanged: (val) {
          double wVal = double.tryParse(val) ?? 0;
          double hVal = double.tryParse(ctrl.coveWidth2Controller.text) ?? double.tryParse(ctrl.coveWidthController.text) ?? 0;
          double adjW = wVal - (2 * hVal);
          if (adjW < 0) adjW = 0;

          // If the Cove Width is either empty or matches the previously calculated deducted width, update it.
          double lastWVal = double.tryParse(ctrl.lastWidth) ?? 0;
          double lastAdjW = lastWVal - (2 * hVal);
          if (lastAdjW < 0) lastAdjW = 0;

          if (ctrl.coveLength2Controller.text.isEmpty ||
              ctrl.coveLength2Controller.text == lastAdjW.toStringAsFixed(2) ||
              ctrl.coveLength2Controller.text == ctrl.lastWidth) {
            ctrl.coveLength2Controller.text = adjW > 0 ? adjW.toStringAsFixed(2) : (wVal > 0 ? val : '');
          }
          ctrl.lastWidth = val;
          ctrl.updateLivePreview();
          ctrl.triggerAutoSave();
        })),
        const SizedBox(width: 8),
        if (isCeilingDesign) ...[
          Expanded(child: _field('T', ctrl.thicknessController, hint: '8')),
          const SizedBox(width: 8),
        ],
        Expanded(child: _field('Q', ctrl.quantityController)),
      ],
    );
  }

  Widget _field(String label, TextEditingController controller, {bool enabled = true, String? hint, ValueChanged<String>? onChanged}) {
    return TextField(
      controller: controller, enabled: enabled,
      keyboardType: TextInputType.number, textAlign: TextAlign.center,
      style: TextStyle(fontWeight: FontWeight.w900, color: enabled ? Colors.black : Colors.grey.shade400),
      decoration: AppStyles.inputDecoration(label).copyWith(
        contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        fillColor: enabled ? Colors.transparent : Colors.grey.shade100, filled: !enabled,
        hintText: enabled ? hint : 'N/A',
        hintStyle: const TextStyle(color: Colors.black38, fontSize: 9),
      ),
      onChanged: onChanged ?? (_) { ctrl.updateLivePreview(); ctrl.triggerAutoSave(); },
    );
  }
}
