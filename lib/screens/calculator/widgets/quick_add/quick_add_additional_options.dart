import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';
import '../../calculator_controller.dart';

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
              
              // Combined CENTRAL DESIGN & COVE LIGHT Container
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // CENTRAL DESIGN Header
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Row(children: [
                      const Text('CENTRAL DESIGN', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: AppColors.labelColor)),
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
                        IconButton(icon: const Icon(Icons.edit, color: Colors.blueAccent, size: 18), onPressed: () {}, padding: EdgeInsets.zero, constraints: const BoxConstraints()),
                        const SizedBox(width: 12),
                        IconButton(
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
                        const SizedBox(width: 12),
                        IconButton(icon: const Icon(Icons.delete_outline, color: AppColors.alertRed, size: 20), onPressed: () => onCentralToggle(false), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
                      ]),
                  ]),
                  
                  // CENTRAL DESIGN Inputs
                  if (hasCentralDesign) ...[
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
                    for (int i = 0; i < ctrl.extraCentralRows.length; i++) ...[
                      const SizedBox(height: 8),
                      Row(children: [
                        Expanded(child: _field(ctrl.extraCentralRows[i].lengthController, 'Length')),
                        const SizedBox(width: 8),
                        Expanded(child: _field(ctrl.extraCentralRows[i].widthController, 'Width', enabled: true)),
                        const SizedBox(width: 8),
                        Expanded(child: _field(ctrl.extraCentralRows[i].quantityController, 'Qty')),
                        const SizedBox(width: 8),
                        Expanded(child: _field(ctrl.extraCentralRows[i].areaController, 'SQFT (Auto)', readOnly: true)),
                      ]),
                    ],
                  ],
                  
                  // Horizontal Divider and COVE LIGHT Section inside the same container
                  const SizedBox(height: 15),
                  const Divider(height: 10),
                  const SizedBox(height: 10),
                  
                  // COVE LIGHT Header
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Row(children: [
                      const Text('COVE LIGHT', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: AppColors.labelColor)),
                      if (hasCove) ...[const SizedBox(width: 8), const Icon(Icons.check_circle, color: AppColors.resultGreen, size: 16)],
                    ]),
                    if (!hasCove)
                      TextButton.icon(
                        onPressed: () => onCoveToggle(true),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('ADD', style: TextStyle(fontWeight: FontWeight.bold)),
                      )
                    else
                      Row(children: [
                        IconButton(icon: const Icon(Icons.edit, color: Colors.blueAccent, size: 18), onPressed: () {}, padding: EdgeInsets.zero, constraints: const BoxConstraints()),
                        const SizedBox(width: 12),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline, color: Colors.green, size: 18), 
                          onPressed: () {
                            ctrl.extraCoveRows.add(CoveLightRow());
                            ctrl.notifyUI();
                            ctrl.updateLivePreview();
                            ctrl.triggerAutoSave();
                          },
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        const SizedBox(width: 12),
                        IconButton(icon: const Icon(Icons.delete_outline, color: AppColors.alertRed, size: 20), onPressed: () => onCoveToggle(false), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
                      ]),
                  ]),
                  
                  // COVE LIGHT Inputs
                  if (hasCove) ...[
                    const SizedBox(height: 10),
                    const Text('Opposite Walls (Length)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.labelColor)),
                    const SizedBox(height: 4),
                    Row(children: [
                      Expanded(child: _field(ctrl.coveLengthController, 'Length (L)')),
                      const SizedBox(width: 8),
                      Expanded(child: _field(ctrl.coveWidthController, 'Height (H)', onChanged: (val) {
                        _syncDeduction();
                      })),
                      const SizedBox(width: 8),
                      Expanded(child: _field(ctrl.coveQuantityController, 'Qty')),
                    ]),
                    const SizedBox(height: 10),
                    const Text('Opposite Walls (Width)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.labelColor)),
                    const SizedBox(height: 4),
                    Row(children: [
                      Expanded(child: _field(ctrl.coveLength2Controller, 'Width (W)')),
                      const SizedBox(width: 8),
                      Expanded(child: _field(ctrl.coveWidth2Controller, 'Height (H)', onChanged: (val) {
                        _syncDeduction();
                      })),
                      const SizedBox(width: 8),
                      Expanded(child: _field(ctrl.coveQuantity2Controller, 'Qty')),
                    ]),
                    for (int i = 0; i < ctrl.extraCoveRows.length; i++) ...[
                      const SizedBox(height: 10),
                      Text('Opposite Walls (Extra Row ${i + 1})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.labelColor)),
                      const SizedBox(height: 4),
                      Row(children: [
                        Expanded(child: _field(ctrl.extraCoveRows[i].lengthController, 'Length (L)')),
                        const SizedBox(width: 8),
                        Expanded(child: _field(ctrl.extraCoveRows[i].widthController, 'Height (H)')),
                        const SizedBox(width: 8),
                        Expanded(child: _field(ctrl.extraCoveRows[i].quantityController, 'Qty')),
                      ]),
                    ],
                    const SizedBox(height: 10),
                    Row(children: [
                      const Spacer(),
                      Expanded(flex: 2, child: _field(ctrl.coveRftController, 'SQFT (Auto)', readOnly: true)),
                    ]),
                  ],
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 15),
      ],
    );
  }

  void _syncDeduction() {
    double wVal = double.tryParse(ctrl.widthController.text) ?? 0;
    double hVal = double.tryParse(ctrl.coveWidth2Controller.text) ??
                 double.tryParse(ctrl.coveWidthController.text) ?? 0;
    double adjW = wVal - (2 * hVal);
    if (adjW < 0) adjW = 0;

    ctrl.coveLength2Controller.text = adjW > 0 ? adjW.toStringAsFixed(2) : (wVal > 0 ? wVal.toString() : '');
    ctrl.updateLivePreview();
    ctrl.triggerAutoSave();
  }

  Widget _field(TextEditingController c, String l, {bool readOnly = false, bool enabled = true, ValueChanged<String>? onChanged}) => TextField(
    controller: c, readOnly: readOnly, enabled: enabled, keyboardType: const TextInputType.numberWithOptions(decimal: true),
    decoration: AppStyles.inputDecoration(l).copyWith(fillColor: (readOnly || !enabled) ? Colors.grey.shade100 : null, filled: readOnly || !enabled),
    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
    onChanged: onChanged ?? (readOnly ? null : (_) { ctrl.updateLivePreview(); ctrl.triggerAutoSave(); }),
  );
}
