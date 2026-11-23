import 'package:flutter/material.dart';
import 'package:pcm_wayanad/theme/app_theme.dart';
import 'package:pcm_wayanad/screens/calculator/calculator_controller.dart';

class CustomCenterCoveArchBox extends StatelessWidget {
  final CalculatorController ctrl;
  final Color themeColor;
  final double rVal;
  final double deductionVal;
  final String unit;
  final double mainCircumference;
  final double deductionCircumference;
  final double fullCircleSqFt;
  final double deductionCircleSqFt;
  final double netSqFt;
  final VoidCallback onChanged;

  const CustomCenterCoveArchBox({
    super.key,
    required this.ctrl,
    required this.themeColor,
    required this.rVal,
    required this.deductionVal,
    required this.unit,
    required this.mainCircumference,
    required this.deductionCircumference,
    required this.fullCircleSqFt,
    required this.deductionCircleSqFt,
    required this.netSqFt,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: themeColor, width: 1.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.architecture, color: Color(0xFF15803D), size: 16),
              SizedBox(width: 6),
              Text('DYNAMIC COVE ARCH / CURVE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF15803D))),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Circum: ${mainCircumference.toStringAsFixed(2)} $unit',
                style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Colors.green),
              ),
              Text(
                deductionVal > 0
                    ? 'Circle Area: ${netSqFt.toStringAsFixed(2)} SQFT (${fullCircleSqFt.toStringAsFixed(2)} - ${deductionCircleSqFt.toStringAsFixed(2)})'
                    : 'Circle Area: ${fullCircleSqFt.toStringAsFixed(2)} SQFT',
                style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w900, color: Color(0xFF15803D)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: ctrl.customCenterRadiusController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: AppStyles.inputDecoration('Radius (R)').copyWith(
                    helperText: 'Circum: ${mainCircumference.toStringAsFixed(2)} $unit',
                    helperStyle: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: Colors.green),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: themeColor, width: 1.8)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: themeColor, width: 2.2)),
                    fillColor: Colors.white,
                    filled: true,
                    hintText: '',
                  ),
                  onTap: () {
                    if (ctrl.customCenterRadiusController.text == '1' || ctrl.customCenterRadiusController.text == '1.0') {
                      ctrl.customCenterRadiusController.clear();
                    } else {
                      ctrl.customCenterRadiusController.selection = TextSelection(baseOffset: 0, extentOffset: ctrl.customCenterRadiusController.text.length);
                    }
                  },
                  onChanged: (_) {
                    onChanged();
                    ctrl.updateLivePreview();
                    ctrl.triggerAutoSave();
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: ctrl.customCenterDeductionController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: AppStyles.inputDecoration('DEDUCTION').copyWith(
                    helperText: deductionVal > 0
                        ? 'Circum: ${deductionCircumference.toStringAsFixed(2)} $unit\nLess Deduction: -${deductionCircleSqFt.toStringAsFixed(2)} SQFT'
                        : 'Circum: 0.00 $unit\nLess Deduction: 0.00 SQFT',
                    helperStyle: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: Colors.red),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: themeColor, width: 1.8)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: themeColor, width: 2.2)),
                    fillColor: Colors.white,
                    filled: true,
                    hintText: '0.0',
                  ),
                  onTap: () {
                    if (ctrl.customCenterDeductionController.text == '0' || ctrl.customCenterDeductionController.text == '0.0') {
                      ctrl.customCenterDeductionController.clear();
                    } else {
                      ctrl.customCenterDeductionController.selection = TextSelection(baseOffset: 0, extentOffset: ctrl.customCenterDeductionController.text.length);
                    }
                  },
                  onChanged: (_) {
                    onChanged();
                    ctrl.updateLivePreview();
                    ctrl.triggerAutoSave();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
