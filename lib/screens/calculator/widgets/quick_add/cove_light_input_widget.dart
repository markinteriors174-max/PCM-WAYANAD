import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';
import '../../calculator_controller.dart';

class CoveLightInputWidget extends StatelessWidget {
  final CalculatorController ctrl; final bool isActive;
  final String linearUnitLabel, areaUnitLabel;
  final ValueChanged<bool> onToggle; final ValueChanged<String?> onUnitChanged;
  const CoveLightInputWidget({super.key, required this.ctrl, required this.isActive, required this.linearUnitLabel, required this.areaUnitLabel, required this.onToggle, required this.onUnitChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Row(children: [
            const Text('COVE LIGHT', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: AppColors.labelColor)),
            if (isActive) ...[const SizedBox(width: 8), const Icon(Icons.check_circle, color: AppColors.resultGreen, size: 16)],
          ]),
          if (!isActive)
            TextButton.icon(
              onPressed: () => onToggle(true),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('ADD', style: TextStyle(fontWeight: FontWeight.bold)),
            )
          else
            Row(children: [
              IconButton(icon: const Icon(Icons.edit, color: Colors.blueAccent, size: 18), onPressed: () {}, padding: EdgeInsets.zero, constraints: const BoxConstraints()),
              const SizedBox(width: 12),
              IconButton(icon: const Icon(Icons.delete_outline, color: AppColors.alertRed, size: 20), onPressed: () => onToggle(false), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
            ]),
        ]),
        if (isActive) ...[
          const SizedBox(height: 10),
          const Text('Opposite Walls (Length)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.labelColor)),
          const SizedBox(height: 4),
          Row(children: [
            Expanded(child: _field(ctrl.coveLengthController, 'Length (L)')),
            const SizedBox(width: 8),
            Expanded(child: _field(ctrl.coveWidthController, 'Height (H)')),
            const SizedBox(width: 8),
            Expanded(child: _field(ctrl.coveQuantityController, 'Qty')),
          ]),
          const SizedBox(height: 10),
          const Text('Opposite Walls (Width)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.labelColor)),
          const SizedBox(height: 4),
          Row(children: [
            Expanded(child: _field(ctrl.coveLength2Controller, 'Width (W)')),
            const SizedBox(width: 8),
            Expanded(child: _field(ctrl.coveWidth2Controller, 'Height (H)')),
            const SizedBox(width: 8),
            Expanded(child: _field(ctrl.coveQuantity2Controller, 'Qty')),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            const Spacer(),
            Expanded(flex: 2, child: _field(ctrl.coveRftController, 'SQFT (Auto)', readOnly: true)),
          ]),
        ],
      ],
    );
  }

  Widget _field(TextEditingController c, String l, {bool readOnly = false, bool enabled = true}) => TextField(
    controller: c, readOnly: readOnly, enabled: enabled, keyboardType: const TextInputType.numberWithOptions(decimal: true),
    decoration: AppStyles.inputDecoration(l).copyWith(fillColor: (readOnly || !enabled) ? Colors.grey.shade100 : null, filled: readOnly || !enabled),
    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
    onChanged: readOnly ? null : (_) { ctrl.updateLivePreview(); ctrl.triggerAutoSave(); },
  );
}
