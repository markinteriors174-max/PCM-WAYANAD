import 'package:flutter/material.dart';
import 'package:pcm_wayanad/theme/app_theme.dart';
import 'package:pcm_wayanad/screens/calculator/calculator_controller.dart';

class CustomCenterRowsWidget extends StatelessWidget {
  final CalculatorController ctrl;
  final Color themeColor;
  final double rVal;
  final double deductionVal;
  final VoidCallback onChanged;

  const CustomCenterRowsWidget({
    super.key,
    required this.ctrl,
    required this.themeColor,
    required this.rVal,
    required this.deductionVal,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Primary Custom Center (Length / Width)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87)),
        const SizedBox(height: 6),
        if (rVal > 0) ...[
          Row(
            children: [
              Expanded(child: _field(ctrl.customCenterCircleRadiusController, 'RADIUS', readOnly: true, cardColor: themeColor)),
              const SizedBox(width: 6),
              Expanded(child: _field(ctrl.customCenterCircleAreaM2Controller, 'AREA (m²)', readOnly: true, cardColor: themeColor)),
              const SizedBox(width: 6),
              Expanded(child: _field(ctrl.customCenterCircleQtyController, 'QTY', readOnly: true, cardColor: themeColor)),
              const SizedBox(width: 6),
              Expanded(child: _field(ctrl.customCenterCircleSqftController, 'SQFT', readOnly: true, cardColor: themeColor)),
            ],
          ),
          const SizedBox(height: 8),
        ],
        Row(
          children: [
            Expanded(child: _field(ctrl.customCenterLengthController, 'LENGTH', readOnly: true, cardColor: themeColor)),
            const SizedBox(width: 6),
            Expanded(child: _field(ctrl.customCenterWidthController, 'WIDTH', cardColor: themeColor, hintText: '0.0')),
            const SizedBox(width: 6),
            Expanded(child: _field(ctrl.customCenterQuantityController, 'QTY', cardColor: themeColor, hintText: '1')),
            const SizedBox(width: 6),
            Expanded(child: _field(ctrl.customCenterAreaController, 'SQFT', readOnly: true, cardColor: themeColor)),
          ],
        ),
        if (deductionVal > 0) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _field(ctrl.customCenterDeductionLengthController, 'LENGTH', readOnly: true, cardColor: themeColor)),
              const SizedBox(width: 6),
              Expanded(child: _field(ctrl.customCenterDeductionWidthController, 'BORDER', cardColor: themeColor, hintText: '0.0')),
              const SizedBox(width: 6),
              Expanded(child: _field(ctrl.customCenterDeductionQuantityController, 'QTY', cardColor: themeColor, hintText: '1')),
              const SizedBox(width: 6),
              Expanded(child: _field(ctrl.customCenterDeductionAreaController, 'SQFT', readOnly: true, cardColor: themeColor)),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                tooltip: 'Clear Deduction',
                onPressed: () {
                  ctrl.customCenterDeductionController.clear();
                  ctrl.customCenterDeductionWidthController.clear();
                  ctrl.customCenterDeductionQuantityController.text = '1';
                  ctrl.customCenterDeductionAreaController.clear();
                  onChanged();
                  ctrl.updateLivePreview();
                  ctrl.triggerAutoSave();
                },
              ),
            ],
          ),
        ],
        for (int i = 0; i < ctrl.extraCustomCentralRows.length; i++) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _field(ctrl.extraCustomCentralRows[i].lengthController, 'LENGTH', readOnly: false, cardColor: themeColor)),
              const SizedBox(width: 6),
              Expanded(child: _field(ctrl.extraCustomCentralRows[i].widthController, 'BORDER', cardColor: themeColor)),
              const SizedBox(width: 6),
              Expanded(child: _field(ctrl.extraCustomCentralRows[i].quantityController, 'QTY', cardColor: themeColor, hintText: '1')),
              const SizedBox(width: 6),
              Expanded(child: _field(ctrl.extraCustomCentralRows[i].areaController, 'SQFT', readOnly: true, cardColor: themeColor)),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                onPressed: () {
                  ctrl.extraCustomCentralRows.removeAt(i);
                  onChanged();
                  ctrl.updateLivePreview();
                  ctrl.triggerAutoSave();
                },
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _field(TextEditingController c, String l, {bool readOnly = false, bool enabled = true, String? hintText, Color? cardColor}) {
    return TextField(
      controller: c,
      readOnly: readOnly,
      enabled: enabled,
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
