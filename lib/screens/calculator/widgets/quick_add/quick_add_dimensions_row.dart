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
    const cardColor = Color(0xFFDC2626); // Red/Coral theme for Plain Ceiling
    return Row(
      children: [
        Expanded(child: _field('L', ctrl.lengthController, cardColor: cardColor, onChanged: (val) {
          if (ctrl.coveLengthController.text.isEmpty || ctrl.coveLengthController.text == ctrl.lastLength) {
            ctrl.coveLengthController.text = val;
          }
          ctrl.lastLength = val;
          ctrl.updateLivePreview();
          ctrl.triggerAutoSave();
        })),
        const SizedBox(width: 8),
        Expanded(child: _field('Width', ctrl.widthController, enabled: true, cardColor: cardColor, onChanged: (val) {
          double wVal = double.tryParse(val.replaceAll(',', '.')) ?? 0;
          double hVal = double.tryParse(ctrl.coveWidth2Controller.text.replaceAll(',', '.')) ?? double.tryParse(ctrl.coveWidthController.text.replaceAll(',', '.')) ?? 0;
          double adjW = wVal - (2 * hVal);
          if (adjW < 0) adjW = 0;

          if (ctrl.coveLength2Controller.text.isEmpty) {
            ctrl.coveLength2Controller.text = adjW > 0 ? (adjW == adjW.roundToDouble() ? adjW.toInt().toString() : adjW.toString()) : (wVal > 0 ? val : '');
          }
          ctrl.lastLength = ctrl.lengthController.text;
          ctrl.lastWidth = val;
          ctrl.updateLivePreview();
          ctrl.triggerAutoSave();
        })),
        const SizedBox(width: 8),
        if (isCeilingDesign) ...[
          Expanded(child: _field('T', ctrl.thicknessController, hint: '8', cardColor: cardColor)),
          const SizedBox(width: 8),
        ],
        Expanded(child: _field('Q', ctrl.quantityController, cardColor: cardColor)),
      ],
    );
  }

  Widget _field(String label, TextEditingController controller, {bool enabled = true, String? hint, ValueChanged<String>? onChanged, Color? cardColor}) {
    return TextField(
      controller: controller, enabled: enabled,
      keyboardType: const TextInputType.numberWithOptions(decimal: true), textAlign: TextAlign.center,
      style: TextStyle(fontWeight: FontWeight.w900, color: enabled ? Colors.black : Colors.grey.shade400),
      decoration: AppStyles.inputDecoration(label).copyWith(
        contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        fillColor: enabled ? Colors.white : Colors.grey.shade100,
        filled: true,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: cardColor ?? Colors.grey.shade400, width: 1.8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: cardColor ?? Colors.blue, width: 2.2),
        ),
        hintText: enabled ? hint : 'N/A',
        hintStyle: const TextStyle(color: Colors.black38, fontSize: 9),
      ),
      onChanged: onChanged ?? (_) { ctrl.updateLivePreview(); ctrl.triggerAutoSave(); },
    );
  }
}
