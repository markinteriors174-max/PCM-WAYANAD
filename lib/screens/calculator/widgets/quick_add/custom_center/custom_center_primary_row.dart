import 'package:flutter/material.dart';
import 'package:pcm_wayanad/theme/app_theme.dart';
import 'package:pcm_wayanad/screens/calculator/calculator_controller.dart';

class CustomCenterPrimaryRow extends StatelessWidget {
  final CalculatorController ctrl;
  final Color themeColor;
  final VoidCallback onChanged;

  const CustomCenterPrimaryRow({
    super.key,
    required this.ctrl,
    required this.themeColor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _field(ctrl.customCenterLengthController, 'LENGTH', readOnly: true, cardColor: themeColor)),
        const SizedBox(width: 6),
        Expanded(child: _field(ctrl.customCenterWidthController, 'BORDER', cardColor: themeColor, hintText: '0.0')),
        const SizedBox(width: 6),
        Expanded(child: _field(ctrl.customCenterQuantityController, 'QTY', cardColor: themeColor, hintText: '1')),
        const SizedBox(width: 6),
        Expanded(child: _field(ctrl.customCenterAreaController, 'SQFT', readOnly: true, cardColor: themeColor)),
      ],
    );
  }

  Widget _field(TextEditingController c, String l, {bool readOnly = false, String? hintText, Color? cardColor}) {
    return TextField(
      controller: c,
      readOnly: readOnly,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: AppStyles.inputDecoration(l).copyWith(
        fillColor: readOnly ? Colors.grey.shade100 : Colors.white,
        filled: true,
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: cardColor ?? Colors.grey.shade400, width: 1.8)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: cardColor ?? Colors.blue, width: 2.2)),
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 11),
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      ),
      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: readOnly ? Colors.grey.shade700 : Colors.black),
      onTap: readOnly ? null : () {
        if (c.text == '1' || c.text == '1.0' || c.text == '1.00') {
          c.clear();
        } else {
          c.selection = TextSelection(baseOffset: 0, extentOffset: c.text.length);
        }
      },
      onChanged: readOnly ? null : (_) {
        onChanged();
        ctrl.updateLivePreview();
        ctrl.triggerAutoSave();
      },
    );
  }
}
