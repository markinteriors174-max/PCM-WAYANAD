import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';
import '../../calculator_controller.dart';

void showQuickAddEditDialog(BuildContext context, CalculatorController ctrl, String currentDesign) {
  final designController = TextEditingController(text: currentDesign);
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Edit Entry Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      content: TextField(controller: designController, decoration: AppStyles.inputDecoration('Design Name')),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryButton),
          onPressed: () {
            ctrl.selectedDesign = 'Other';
            ctrl.designController.text = designController.text;
            ctrl.notifyUI();
            ctrl.triggerAutoSave();
            Navigator.pop(ctx);
          },
          child: const Text('SAVE', style: TextStyle(color: Colors.white)),
        ),
      ],
    ),
  );
}

void showEditCentralDesignDialog(
  BuildContext context,
  CalculatorController ctrl, {
  CentralDesignRow? extraRow,
  int? extraIndex,
}) {
  final lengthCtrl = TextEditingController(
    text: extraRow != null ? extraRow.lengthController.text : ctrl.centralLengthController.text,
  );
  final widthCtrl = TextEditingController(
    text: extraRow != null ? extraRow.widthController.text : ctrl.centralWidthController.text,
  );
  final qtyCtrl = TextEditingController(
    text: extraRow != null ? extraRow.quantityController.text : (ctrl.centralQuantityController.text.isNotEmpty ? ctrl.centralQuantityController.text : '1'),
  );

  showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (context, setDialogState) {
        final double l = double.tryParse(lengthCtrl.text.trim()) ?? 0.0;
        final double w = double.tryParse(widthCtrl.text.trim()) ?? 0.0;
        final double q = double.tryParse(qtyCtrl.text.trim()) ?? 1.0;
        final double area = l * w * (q > 0 ? q : 1.0);

        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF0284C7).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.edit_note, color: Color(0xFF0284C7), size: 22),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Edit Center Design', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text('കണക്കുകൾ മാറ്റുക (Modify Dimensions)', style: TextStyle(fontSize: 11, color: Colors.grey)),
                  ],
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: lengthCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'നീളം / LENGTH (Feet)',
                    prefixIcon: Icon(Icons.straighten, size: 18, color: Color(0xFF0284C7)),
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (_) => setDialogState(() {}),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: widthCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'വീതി / WIDTH (Feet)',
                    prefixIcon: Icon(Icons.square_foot, size: 18, color: Color(0xFF0284C7)),
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (_) => setDialogState(() {}),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: qtyCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'എണ്ണം / QTY (Quantity)',
                    prefixIcon: Icon(Icons.numbers, size: 18, color: Color(0xFF0284C7)),
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (_) => setDialogState(() {}),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF86EFAC)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Area (ഏരിയ):',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: Color(0xFF166534)),
                      ),
                      Text(
                        '${area.toStringAsFixed(2)} Sq.Ft',
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Color(0xFF15803D)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('CANCEL', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0284C7),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
              onPressed: () {
                final lenVal = lengthCtrl.text.trim();
                final widVal = widthCtrl.text.trim();
                final qtyVal = qtyCtrl.text.trim().isNotEmpty ? qtyCtrl.text.trim() : '1';

                if (extraRow != null) {
                  extraRow.lengthController.text = lenVal;
                  extraRow.widthController.text = widVal;
                  extraRow.quantityController.text = qtyVal;
                  extraRow.areaController.text = '${area.toStringAsFixed(2)} SQFT';
                } else {
                  ctrl.centralLengthController.text = lenVal;
                  ctrl.centralWidthController.text = widVal;
                  ctrl.centralQuantityController.text = qtyVal;
                  ctrl.centralAreaController.text = '${area.toStringAsFixed(2)} SQFT';
                }
                ctrl.notifyUI();
                ctrl.updateLivePreview();
                ctrl.triggerAutoSave();
                Navigator.pop(ctx);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✓ Center Design കണക്കുകൾ അപ്ഡേറ്റ് ചെയ്തു!'),
                    backgroundColor: Color(0xFF059669),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              icon: const Icon(Icons.check, size: 16),
              label: const Text('UPDATE / മാറ്റുക', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    ),
  );
}
