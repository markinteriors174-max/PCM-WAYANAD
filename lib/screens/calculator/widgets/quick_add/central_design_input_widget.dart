import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';
import '../../calculator_controller.dart';

class CentralDesignInputWidget extends StatelessWidget {
  final CalculatorController ctrl; final bool isActive;
  final String linearUnitLabel, areaUnitLabel;
  final ValueChanged<bool> onToggle; final ValueChanged<String?> onUnitChanged;
  const CentralDesignInputWidget({super.key, required this.ctrl, required this.isActive, required this.linearUnitLabel, required this.areaUnitLabel, required this.onToggle, required this.onUnitChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Row(children: [
            const Text('CENTRAL DESIGN', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: AppColors.labelColor)),
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
          Row(children: [
            Expanded(child: _field(ctrl.centralLengthController, 'Length')),
            const SizedBox(width: 8),
            Expanded(child: _field(ctrl.centralWidthController, 'Width', enabled: true)),
            const SizedBox(width: 8),
            Expanded(child: _field(ctrl.centralQuantityController, 'Qty')),
            const SizedBox(width: 8),
            Expanded(child: _field(ctrl.centralAreaController, 'SQFT (Auto)', readOnly: true)),
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
