import 'package:flutter/material.dart';
import 'package:pcm_wayanad/screens/calculator/calculator_controller.dart';
import 'package:pcm_wayanad/screens/calculator/units/calculator_unit_helper.dart';
import 'custom_center_type_selector.dart';
import 'custom_center_cove_arch_box.dart';
import 'custom_center_rows_widget.dart';
import 'custom_center_summary_widget.dart';

class CustomCenterWidget extends StatefulWidget {
  final CalculatorController ctrl;
  final bool isActive;
  final String linearUnitLabel, areaUnitLabel;
  final String activeType;
  final ValueChanged<String> onTypeChanged;
  final ValueChanged<bool> onToggle;
  final ValueChanged<String?> onUnitChanged;

  const CustomCenterWidget({
    super.key,
    required this.ctrl,
    required this.isActive,
    required this.linearUnitLabel,
    required this.areaUnitLabel,
    required this.activeType,
    required this.onTypeChanged,
    required this.onToggle,
    required this.onUnitChanged,
  });

  @override
  State<CustomCenterWidget> createState() => _CustomCenterWidgetState();
}

class _CustomCenterWidgetState extends State<CustomCenterWidget> {
  CalculatorController get ctrl => widget.ctrl;

  @override
  void initState() {
    super.initState();
    widget.ctrl.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    widget.ctrl.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    const themeColor = Color(0xFF15803D); // Rich green theme

    final rVal = double.tryParse(ctrl.customCenterRadiusController.text.replaceAll(',', '.')) ?? 0.0;
    final deductionVal = double.tryParse(ctrl.customCenterDeductionController.text.replaceAll(',', '.')) ?? 0.0;
    final unit = CalculatorUnitHelper.availableUnits.contains(ctrl.customCenterUnit) ? ctrl.customCenterUnit : 'Meter';

    double areaFactor = 1.0;
    switch (unit.toLowerCase()) {
      case 'cm':
        areaFactor = 1.0 / (30.48 * 30.48);
        break;
      case 'meters':
      case 'meter':
      case 'sqm':
      case 'm':
        areaFactor = 10.7639104;
        break;
      case 'inches':
      case 'inch':
      case 'in':
        areaFactor = 1.0 / 144.0;
        break;
      case 'mm':
        areaFactor = 10.7639104 / 1000000.0;
        break;
      case 'feet':
      case 'sqft':
      case 'ft':
      default:
        areaFactor = 1.0;
        break;
    }

    final mainCircumference = 2 * 3.1415926535 * rVal;
    final deductionCircumference = 2 * 3.1415926535 * deductionVal;

    if (rVal > 0) {
      ctrl.customCenterLengthController.text = mainCircumference.toStringAsFixed(2);
    } else {
      ctrl.customCenterLengthController.clear();
    }

    final primaryL = mainCircumference;
    final primaryW = double.tryParse(ctrl.customCenterWidthController.text.replaceAll(',', '.')) ?? 0.0;
    final primaryQText = ctrl.customCenterQuantityController.text.trim();
    final primaryQ = primaryQText.isEmpty ? 1.0 : (double.tryParse(primaryQText.replaceAll(',', '.')) ?? 1.0);
    final primarySqFt = (primaryL * primaryW * primaryQ) * areaFactor;

    ctrl.customCenterAreaController.text = primarySqFt > 0 ? primarySqFt.toStringAsFixed(2) : '';

    double extraRowsSqFtSum = 0.0;
    for (var r in ctrl.extraCustomCentralRows) {
      final lText = r.lengthController.text.trim();
      final l = lText.isEmpty ? (rVal > 0 ? mainCircumference : 0.0) : (double.tryParse(lText.replaceAll(',', '.')) ?? 0.0);
      final b = double.tryParse(r.widthController.text.replaceAll(',', '.')) ?? 0.0;
      final qText = r.quantityController.text.trim();
      final q = qText.isEmpty ? 1.0 : (double.tryParse(qText.replaceAll(',', '.')) ?? 1.0);
      final rowSqFt = (l * b * q) * areaFactor;
      extraRowsSqFtSum += rowSqFt;
    }

    final fullCircleAreaM2 = 3.1415926535 * rVal * rVal;
    final fullCircleSqFt = fullCircleAreaM2 * areaFactor;

    final deductionAreaM2 = 3.1415926535 * deductionVal * deductionVal;
    final deductionCircleSqFt = deductionAreaM2 * areaFactor;

    final netAreaM2 = deductionVal > 0 ? (fullCircleAreaM2 - deductionAreaM2) : fullCircleAreaM2;
    final netSqFt = deductionVal > 0 ? (fullCircleSqFt - deductionCircleSqFt) : fullCircleSqFt;

    ctrl.customCenterCircleRadiusController.text = rVal > 0 ? rVal.toStringAsFixed(1) : '';
    ctrl.customCenterCircleAreaM2Controller.text = rVal > 0 ? netAreaM2.toStringAsFixed(2) : '';
    ctrl.customCenterCircleSqftController.text = rVal > 0 ? netSqFt.toStringAsFixed(2) : '';

    if (deductionVal > 0) {
      ctrl.customCenterDeductionLengthController.text = deductionCircumference.toStringAsFixed(2);
    } else {
      ctrl.customCenterDeductionLengthController.clear();
      ctrl.customCenterDeductionWidthController.clear();
      ctrl.customCenterDeductionQuantityController.text = '1';
      ctrl.customCenterDeductionAreaController.clear();
    }

    final deductionL = deductionCircumference;
    final deductionW = double.tryParse(ctrl.customCenterDeductionWidthController.text.replaceAll(',', '.')) ?? 0.0;
    final deductionQText = ctrl.customCenterDeductionQuantityController.text.trim();
    final deductionQ = deductionQText.isEmpty ? 1.0 : (double.tryParse(deductionQText.replaceAll(',', '.')) ?? 1.0);
    final deductionRowSqFt = deductionVal > 0 ? (deductionL * deductionW * deductionQ) * areaFactor : 0.0;

    ctrl.customCenterDeductionAreaController.text = deductionRowSqFt > 0 ? deductionRowSqFt.toStringAsFixed(2) : '';

    final circleAreaAdd = rVal > 0 ? netSqFt : 0.0;
    final grossSqFt = primarySqFt + extraRowsSqFtSum + circleAreaAdd + deductionRowSqFt;

    final totalSqFt = grossSqFt > 0 ? grossSqFt : 0.0;
    final rate = double.tryParse(ctrl.customCenterRateController.text.replaceAll(',', '.')) ?? 105.0;
    final totalAmount = totalSqFt * rate;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: themeColor, width: widget.isActive ? 2.0 : 1.4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: SwitchListTile(
                  title: const Text(
                    'Center',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Color(0xFF1E293B)),
                  ),
                  value: widget.isActive,
                  activeThumbColor: themeColor,
                  activeTrackColor: themeColor.withValues(alpha: 0.4),
                  onChanged: widget.onToggle,
                ),
              ),
              if (widget.isActive)
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: themeColor,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.add, color: Colors.white, size: 18),
                  ),
                  tooltip: 'Add Row',
                  onPressed: () {
                    setState(() {
                      ctrl.extraCustomCentralRows.add(CentralDesignRow());
                    });
                    ctrl.updateLivePreview();
                  },
                ),
              const SizedBox(width: 8),
            ],
          ),
          if (widget.isActive) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomCenterTypeSelector(
                    ctrl: ctrl,
                    themeColor: themeColor,
                    activeType: widget.activeType,
                    onTypeChanged: widget.onTypeChanged,
                  ),
                  const SizedBox(height: 14),
                  CustomCenterCoveArchBox(
                    ctrl: ctrl,
                    themeColor: themeColor,
                    rVal: rVal,
                    deductionVal: deductionVal,
                    unit: unit,
                    mainCircumference: mainCircumference,
                    deductionCircumference: deductionCircumference,
                    fullCircleSqFt: fullCircleSqFt,
                    deductionCircleSqFt: deductionCircleSqFt,
                    netSqFt: netSqFt,
                    onChanged: () => setState(() {}),
                  ),
                  const SizedBox(height: 14),
                  CustomCenterRowsWidget(
                    ctrl: ctrl,
                    themeColor: themeColor,
                    rVal: rVal,
                    deductionVal: deductionVal,
                    onChanged: () => setState(() {}),
                  ),
                  const SizedBox(height: 14),
                  CustomCenterSummaryWidget(
                    ctrl: ctrl,
                    themeColor: themeColor,
                    totalSqFt: totalSqFt,
                    totalAmount: totalAmount,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
