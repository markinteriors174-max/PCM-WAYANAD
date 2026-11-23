import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';
import '../../calculator_controller.dart';
import 'quick_add_edit_dialog.dart';

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
            const Text('CENTER DESIGN', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: AppColors.labelColor)),
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
              TextButton.icon(
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  foregroundColor: const Color(0xFF0284C7),
                ),
                icon: const Icon(Icons.edit_note, size: 16),
                label: const Text('EDIT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                onPressed: () => showEditCentralDesignDialog(context, ctrl),
              ),
              const SizedBox(width: 8),
              IconButton(icon: const Icon(Icons.delete_outline, color: AppColors.alertRed, size: 20), onPressed: () => onToggle(false), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
            ]),
        ]),
        if (isActive) ...[
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: _field(ctrl.centralLengthController, 'Length')),
            const SizedBox(width: 6),
            Expanded(child: _field(ctrl.centralWidthController, 'Width', enabled: true)),
            const SizedBox(width: 6),
            Expanded(child: _field(ctrl.centralQuantityController, 'Qty')),
            const SizedBox(width: 6),
            Expanded(child: _field(ctrl.centralAreaController, 'SQFT (Auto)', readOnly: true)),
            const SizedBox(width: 4),
            IconButton(
              tooltip: 'Edit / Modify',
              icon: const Icon(Icons.edit, color: Color(0xFF0284C7), size: 18),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () => showEditCentralDesignDialog(context, ctrl),
            ),
          ]),
          const SizedBox(height: 8),
          // Action Pill: കണക്കുകൾ മാറ്റുക (Edit / Modify)
          InkWell(
            onTap: () => showEditCentralDesignDialog(context, ctrl),
            borderRadius: BorderRadius.circular(6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFF0284C7).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFF0284C7).withValues(alpha: 0.3)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.edit_note, size: 15, color: Color(0xFF0284C7)),
                  SizedBox(width: 5),
                  Text(
                    'കണക്കുകൾ മാറ്റുക (Edit / Modify)',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0284C7),
                    ),
                  ),
                ],
              ),
            ),
          ),
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
