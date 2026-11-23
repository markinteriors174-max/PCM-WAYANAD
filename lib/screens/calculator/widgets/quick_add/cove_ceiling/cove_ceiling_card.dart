import 'package:flutter/material.dart';
import '../../../calculator_controller.dart';
import '../quick_add_actions.dart';
import '../cove_light_input_widget.dart';

class CoveCeilingCard extends StatelessWidget {
  final CalculatorController ctrl;
  final VoidCallback onChanged;

  const CoveCeilingCard({
    super.key,
    required this.ctrl,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    const cardColor = Color(0xFFD97706); // Rich amber/orange
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: cardColor,
          width: ctrl.isCoveCeilingOn ? 2.0 : 1.4,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: SwitchListTile(
                  title: const Text(
                    'Cove',
                    style: TextStyle(color: Color(0xFF1E293B), fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  value: ctrl.isCoveCeilingOn,
                  activeThumbColor: cardColor,
                  activeTrackColor: cardColor.withValues(alpha: 0.4),
                  onChanged: (val) {
                    ctrl.isCoveCeilingOn = val;
                    if (val) {
                      ctrl.isPlainCeilingOn = false;
                      QuickAddActions.toggleCeilingDesign(ctrl, false);
                    }
                    QuickAddActions.toggleCove(ctrl, val);
                    ctrl.notifyUI();
                    onChanged();
                  },
                ),
              ),
              if (ctrl.isCoveCeilingOn)
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.add, color: Colors.white, size: 18),
                  ),
                  tooltip: 'Add Row',
                  onPressed: () {
                    ctrl.extraCoveRows.add(CoveLightRow());
                    ctrl.updateLivePreview();
                    onChanged();
                  },
                ),
              const SizedBox(width: 8),
            ],
          ),
          if (ctrl.isCoveCeilingOn) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('COVE LIGHT', style: TextStyle(color: Color(0xFFD97706), fontWeight: FontWeight.w900, fontSize: 12)),
                      Icon(Icons.check_circle, color: Color(0xFFD97706), size: 18),
                    ],
                  ),
                  const SizedBox(height: 10),
                  CoveLightInputWidget(
                    ctrl: ctrl,
                    isActive: ctrl.isCoveCeilingOn,
                    onToggle: (val) {
                      ctrl.isCoveCeilingOn = val;
                      if (val) {
                        ctrl.isPlainCeilingOn = false;
                        QuickAddActions.toggleCeilingDesign(ctrl, false);
                      }
                      QuickAddActions.toggleCove(ctrl, val);
                      ctrl.notifyUI();
                      onChanged();
                    },
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
