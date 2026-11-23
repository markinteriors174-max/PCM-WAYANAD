// PROTECTED MODULE - DO NOT MODIFY OR OVERWRITE THIS FILE
import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../calculator_controller.dart';
import 'plain_sub_section.dart';
import 'cove_sub_section.dart';
import 'center_sub_section.dart';
import 'package:pcm_wayanad/utils/calculator_utils.dart';

class CalculatorConstants {
  static const String defaultUnit = 'Meter';
  static const double defaultRate = 105.0;
}

class CalculatorMath {
  static double calculateCircumference(double radius) => 2 * math.pi * radius;
  static double calculateNetWidth(double w, double b1, double b2) => (w - (b1 + b2)) > 0 ? (w - (b1 + b2)) : 0.0;
  static double convertToSqFt(double area, String unit) => area * 10.7639104;
}

class UnifiedRoomCalculatorCard extends StatefulWidget {
  final CalculatorController ctrl;

  const UnifiedRoomCalculatorCard({super.key, required this.ctrl});

  @override
  State<UnifiedRoomCalculatorCard> createState() => _UnifiedRoomCalculatorCardState();
}

class _UnifiedRoomCalculatorCardState extends State<UnifiedRoomCalculatorCard> {
  String _activeCenterType = 'Standard (Center)';

  @override
  void initState() {
    super.initState();
    if (widget.ctrl.unit.isEmpty) widget.ctrl.unit = CalculatorConstants.defaultUnit;
    if (widget.ctrl.rateController.text.trim().isEmpty) {
      widget.ctrl.rateController.text = CalculatorConstants.defaultRate.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PlainSubSection(ctrl: widget.ctrl, onChanged: () => setState(() {})),
        const SizedBox(height: 8),
        CoveSubSection(ctrl: widget.ctrl, onChanged: () => setState(() {})),
        const SizedBox(height: 8),
        CenterSubSection(
          ctrl: widget.ctrl,
          isActive: widget.ctrl.isCenterCeilingOn,
          activeType: _activeCenterType,
          onTypeChanged: (type) => setState(() => _activeCenterType = type),
          onToggle: (val) {
            setState(() {
              widget.ctrl.isCenterCeilingOn = val;
              widget.ctrl.hasCentralDesign = val;
              widget.ctrl.notifyUI();
            });
          },
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.indigo.shade200, width: 1.8),
          ),
          child: Column(
            children: [
              const Text(
                'COMBINED ROOM SUMMARY (PLAIN + COVE + CENTER)',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: Color(0xFF334155), letterSpacing: 0.5),
              ),
              const SizedBox(height: 6),
              Text(
                'TOTAL: ₹${CalculatorUtils.formatIndianCurrency(widget.ctrl.livePreviewAmount)}',
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF1E293B)),
              ),
              const SizedBox(height: 2),
              Text(
                'COMBINED AREA: ${CalculatorUtils.formatNumber(widget.ctrl.livePreviewAreaSqFt)} SQFT',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF475569)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
