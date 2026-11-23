import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';
import '../../calculator_controller.dart';
import 'cove_light_input_widget.dart';
import 'quick_add_edit_dialog.dart';

class QuickAddAdditionalOptions extends StatelessWidget {
  final CalculatorController ctrl;
  final bool isCeilingDesign;
  final bool hasCentralDesign;
  final bool hasCove;
  final String linearUnit;
  final String areaUnit;
  final ValueChanged<bool> onCentralToggle;
  final ValueChanged<bool> onCoveToggle;

  const QuickAddAdditionalOptions({
    super.key, required this.ctrl, required this.isCeilingDesign,
    required this.hasCentralDesign, required this.hasCove,
    required this.linearUnit, required this.areaUnit,
    required this.onCentralToggle, required this.onCoveToggle,
  });

  @override
  Widget build(BuildContext context) {
    if (!isCeilingDesign) return const SizedBox.shrink();

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(15),
          decoration: AppStyles.neumorphicDecoration(color: Colors.white, hasThickBorder: false, borderRadius: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'ADDITIONAL DESIGN OPTIONS',
                style: TextStyle(color: AppColors.labelColor, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1.0),
              ),
              const Divider(height: 20),
              
              // Combined CENTER DESIGN & COVE LIGHT Container
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // CENTER DESIGN Header
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Row(children: [
                      const Text('CENTER DESIGN', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: AppColors.labelColor)),
                      if (hasCentralDesign) ...[const SizedBox(width: 8), const Icon(Icons.check_circle, color: AppColors.resultGreen, size: 16)],
                    ]),
                    if (!hasCentralDesign)
                      TextButton.icon(
                        onPressed: () => onCentralToggle(true),
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
                        IconButton(
                          tooltip: 'Add Row',
                          icon: const Icon(Icons.add_circle_outline, color: Colors.green, size: 18), 
                          onPressed: () {
                            ctrl.extraCentralRows.add(CentralDesignRow());
                            ctrl.notifyUI();
                            ctrl.updateLivePreview();
                            ctrl.triggerAutoSave();
                          },
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        const SizedBox(width: 10),
                        IconButton(
                          tooltip: 'Delete',
                          icon: const Icon(Icons.delete_outline, color: AppColors.alertRed, size: 18), 
                          onPressed: () => onCentralToggle(false), 
                          padding: EdgeInsets.zero, 
                          constraints: const BoxConstraints(),
                        ),
                      ]),
                  ]),
                  
                  // CENTRAL DESIGN Inputs
                  if (hasCentralDesign) ...[
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
                    for (int i = 0; i < ctrl.extraCentralRows.length; i++) ...[
                      const SizedBox(height: 8),
                      Row(children: [
                        Expanded(child: _field(ctrl.extraCentralRows[i].lengthController, 'Length')),
                        const SizedBox(width: 6),
                        Expanded(child: _field(ctrl.extraCentralRows[i].widthController, 'Width', enabled: true)),
                        const SizedBox(width: 6),
                        Expanded(child: _field(ctrl.extraCentralRows[i].quantityController, 'Qty')),
                        const SizedBox(width: 6),
                        Expanded(child: _field(ctrl.extraCentralRows[i].areaController, 'SQFT (Auto)', readOnly: true)),
                        const SizedBox(width: 4),
                        IconButton(
                          tooltip: 'Edit Row',
                          icon: const Icon(Icons.edit, color: Color(0xFF0284C7), size: 18),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () => showEditCentralDesignDialog(
                            context,
                            ctrl,
                            extraRow: ctrl.extraCentralRows[i],
                            extraIndex: i,
                          ),
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          tooltip: 'Delete Row',
                          icon: const Icon(Icons.remove_circle_outline, color: AppColors.alertRed, size: 18),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () {
                            ctrl.extraCentralRows.removeAt(i);
                            ctrl.notifyUI();
                            ctrl.updateLivePreview();
                            ctrl.triggerAutoSave();
                          },
                        ),
                      ]),
                    ],
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
                  
                  // Horizontal Divider and COVE LIGHT Section inside the same container
                  const SizedBox(height: 15),
                  const Divider(height: 10),
                  const SizedBox(height: 10),
                  
                  // COVE LIGHT Section
                  CoveLightInputWidget(
                    ctrl: ctrl,
                    isActive: hasCove,
                    onToggle: onCoveToggle,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 15),
      ],
    );
  }

  Widget _field(TextEditingController c, String l, {bool readOnly = false, bool enabled = true, ValueChanged<String>? onChanged}) => TextField(
    controller: c, readOnly: readOnly, enabled: enabled, keyboardType: const TextInputType.numberWithOptions(decimal: true),
    decoration: AppStyles.inputDecoration(l).copyWith(fillColor: (readOnly || !enabled) ? Colors.grey.shade100 : null, filled: readOnly || !enabled),
    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
    onChanged: onChanged ?? (readOnly ? null : (_) { ctrl.updateLivePreview(); ctrl.triggerAutoSave(); }),
  );
}
