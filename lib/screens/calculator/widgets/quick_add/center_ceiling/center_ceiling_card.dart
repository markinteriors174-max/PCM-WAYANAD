import 'package:flutter/material.dart';
import '../../../calculator_controller.dart';
import '../quick_add_actions.dart';

class CenterCeilingCard extends StatelessWidget {
  final CalculatorController ctrl;
  final VoidCallback onChanged;

  const CenterCeilingCard({
    super.key,
    required this.ctrl,
    required this.onChanged,
  });

  Widget buildCenterDesignInputFields(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: ctrl.centralLengthController,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 12),
            decoration: const InputDecoration(
              labelText: 'Length',
              labelStyle: TextStyle(color: Colors.grey, fontSize: 11),
              isDense: true,
              border: OutlineInputBorder(),
            ),
            onChanged: (_) {
              ctrl.updateLivePreview();
              ctrl.triggerAutoSave();
              onChanged();
            },
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: TextField(
            controller: ctrl.centralWidthController,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 12),
            decoration: const InputDecoration(
              labelText: 'Width',
              labelStyle: TextStyle(color: Colors.grey, fontSize: 11),
              isDense: true,
              border: OutlineInputBorder(),
            ),
            onChanged: (_) {
              ctrl.updateLivePreview();
              ctrl.triggerAutoSave();
              onChanged();
            },
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: TextField(
            controller: ctrl.centralQuantityController,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 12),
            decoration: const InputDecoration(
              labelText: 'Qty',
              labelStyle: TextStyle(color: Colors.grey, fontSize: 11),
              isDense: true,
              border: OutlineInputBorder(),
            ),
            onChanged: (_) {
              ctrl.updateLivePreview();
              ctrl.triggerAutoSave();
              onChanged();
            },
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: TextField(
            controller: ctrl.centralRateController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 12),
            decoration: const InputDecoration(
              labelText: 'Rate (₹)',
              labelStyle: TextStyle(color: Colors.amber, fontSize: 11),
              isDense: true,
              border: OutlineInputBorder(),
            ),
            onChanged: (_) {
              ctrl.updateLivePreview();
              ctrl.triggerAutoSave();
              onChanged();
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    const cardColor = Color(0xFF9333EA); // Rich Purple
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: cardColor.withValues(alpha: ctrl.isCenterCeilingOn ? 0.18 : 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: cardColor.withValues(alpha: ctrl.isCenterCeilingOn ? 0.9 : 0.4),
          width: ctrl.isCenterCeilingOn ? 1.6 : 1.1,
        ),
      ),
      child: Column(
        children: [
          SwitchListTile(
            title: const Text(
              'Center Design Ceiling (സെന്റർ ഡിസൈൻ)',
              style: TextStyle(color: Color(0xFF1E293B), fontSize: 13, fontWeight: FontWeight.bold),
            ),
            value: ctrl.isCenterCeilingOn,
            activeThumbColor: cardColor,
            activeTrackColor: cardColor.withValues(alpha: 0.4),
            onChanged: (val) {
              ctrl.isCenterCeilingOn = val;
              if (val) {
                ctrl.isPlainCeilingOn = false;
                QuickAddActions.toggleCeilingDesign(ctrl, false);
              }
              QuickAddActions.toggleCentral(ctrl, val);
              ctrl.notifyUI();
              onChanged();
            },
          ),
          if (ctrl.isCenterCeilingOn) ...[
            Container(
              margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: cardColor.withValues(alpha: 0.6), width: 1.2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('CENTER DESIGN', style: TextStyle(color: Color(0xFF9333EA), fontWeight: FontWeight.w900, fontSize: 12)),
                      Icon(Icons.add_circle, color: Color(0xFF9333EA), size: 20),
                    ],
                  ),
                  const SizedBox(height: 10),
                  buildCenterDesignInputFields(context),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
