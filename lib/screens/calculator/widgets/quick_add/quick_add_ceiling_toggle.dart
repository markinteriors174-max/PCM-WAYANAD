import 'package:flutter/material.dart';
import '../../calculator_controller.dart';
import 'quick_add_actions.dart';
import 'plain_ceiling/plain_ceiling_card.dart';
import 'cove_ceiling/cove_ceiling_card.dart';
import 'standard_center/standard_center_widget.dart';
import 'custom_center/custom_center_widget.dart';

class QuickAddCeilingToggle extends StatefulWidget {
  final CalculatorController ctrl;

  const QuickAddCeilingToggle({
    super.key,
    required this.ctrl,
  });

  @override
  State<QuickAddCeilingToggle> createState() => _QuickAddCeilingToggleState();
}

class _QuickAddCeilingToggleState extends State<QuickAddCeilingToggle> {
  String _activeCenterType = 'Standard (Center)';

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PlainCeilingCard(
          ctrl: widget.ctrl,
          onChanged: () => setState(() {}),
        ),
        const SizedBox(height: 6),
        CoveCeilingCard(
          ctrl: widget.ctrl,
          onChanged: () => setState(() {}),
        ),
        const SizedBox(height: 6),
        if (_activeCenterType == 'Standard (Center)')
          StandardCenterWidget(
            ctrl: widget.ctrl,
            isActive: widget.ctrl.isCenterCeilingOn,
            linearUnitLabel: 'Feet',
            areaUnitLabel: 'SqFt',
            activeType: _activeCenterType,
            onTypeChanged: (type) => setState(() => _activeCenterType = type),
            onToggle: (val) {
              setState(() {
                widget.ctrl.isCenterCeilingOn = val;
                if (val) {
                  widget.ctrl.isPlainCeilingOn = false;
                  QuickAddActions.toggleCeilingDesign(widget.ctrl, false);
                }
                QuickAddActions.toggleCentral(widget.ctrl, val);
                widget.ctrl.notifyUI();
              });
            },
            onUnitChanged: (_) {},
          )
        else
          CustomCenterWidget(
            ctrl: widget.ctrl,
            isActive: widget.ctrl.isCenterCeilingOn,
            linearUnitLabel: 'Feet',
            areaUnitLabel: 'SqFt',
            activeType: _activeCenterType,
            onTypeChanged: (type) => setState(() => _activeCenterType = type),
            onToggle: (val) {
              setState(() {
                widget.ctrl.isCenterCeilingOn = val;
                if (val) {
                  widget.ctrl.isPlainCeilingOn = false;
                  QuickAddActions.toggleCeilingDesign(widget.ctrl, false);
                }
                QuickAddActions.toggleCentral(widget.ctrl, val);
                widget.ctrl.notifyUI();
              });
            },
            onUnitChanged: (_) {},
          ),
      ],
    );
  }
}
