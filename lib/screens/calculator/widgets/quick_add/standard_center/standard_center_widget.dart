import 'package:flutter/material.dart';
import 'package:pcm_wayanad/screens/calculator/calculator_controller.dart';
import 'package:pcm_wayanad/screens/calculator/units/calculator_unit_helper.dart';
import 'standard_center_type_selector.dart';
import 'standard_center_rows_widget.dart';
import 'standard_center_summary_widget.dart';

class StandardCenterWidget extends StatefulWidget {
  final CalculatorController ctrl;
  final bool isActive;
  final String linearUnitLabel, areaUnitLabel;
  final String activeType;
  final ValueChanged<String> onTypeChanged;
  final ValueChanged<bool> onToggle;
  final ValueChanged<String?> onUnitChanged;

  const StandardCenterWidget({
    super.key,
    required this.ctrl,
    required this.isActive,
    required this.linearUnitLabel,
    required this.areaUnitLabel,
    required this.activeType,
    required this.onTypeChanged,
    required this.onToggle,
    required this.onUnitChanged,
  });

  @override
  State<StandardCenterWidget> createState() => _StandardCenterWidgetState();
}

class _StandardCenterWidgetState extends State<StandardCenterWidget> {
  CalculatorController get ctrl => widget.ctrl;

  @override
  void initState() {
    super.initState();
    widget.ctrl.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    widget.ctrl.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    const themeColor = Color(0xFF15803D);

    if (ctrl.extraCentralRows.isEmpty) {
      ctrl.extraCentralRows.add(CentralDesignRow());
      ctrl.extraCentralRows.add(CentralDesignRow());
    }

    final unit = CalculatorUnitHelper.availableUnits.contains(ctrl.centralUnit) ? ctrl.centralUnit : 'Meter';
    double areaFactor = 1.0;
    switch (unit.toLowerCase()) {
      case 'cm':
        areaFactor = 1.0 / (30.48 * 30.48);
        break;
      case 'meters':
      case 'meter':
      case 'sqm':
      case 'm':
        areaFactor = 10.7639104;
        break;
      case 'inches':
      case 'inch':
      case 'in':
        areaFactor = 1.0 / 144.0;
        break;
      case 'mm':
        areaFactor = 10.7639104 / 1000000.0;
        break;
      case 'feet':
      case 'sqft':
      case 'ft':
      default:
        areaFactor = 1.0;
        break;
    }

    final primaryL = double.tryParse(ctrl.centralLengthController.text.replaceAll(',', '.')) ?? 0.0;
    final primaryW = double.tryParse(ctrl.centralWidthController.text.replaceAll(',', '.')) ?? 0.0;
    final primaryQText = ctrl.centralQuantityController.text.trim();
    final primaryQ = primaryQText.isEmpty ? 1.0 : (double.tryParse(primaryQText.replaceAll(',', '.')) ?? 1.0);
    final primarySqFt = (primaryL * primaryW * primaryQ) * areaFactor;

    ctrl.centralAreaController.text = primarySqFt > 0 ? primarySqFt.toStringAsFixed(2) : '';

    double extraRowsSqFtSum = 0.0;
    for (var r in ctrl.extraCentralRows) {
      final l = double.tryParse(r.lengthController.text.replaceAll(',', '.')) ?? 0.0;
      final b = double.tryParse(r.widthController.text.replaceAll(',', '.')) ?? 0.0;
      final qText = r.quantityController.text.trim();
      final q = qText.isEmpty ? 1.0 : (double.tryParse(qText.replaceAll(',', '.')) ?? 1.0);
      final rowSqFt = (l * b * q) * areaFactor;
      r.areaController.text = rowSqFt > 0 ? rowSqFt.toStringAsFixed(2) : '';
      extraRowsSqFtSum += rowSqFt;
    }

    final totalSqFt = primarySqFt + extraRowsSqFtSum;
    final rate = double.tryParse(ctrl.centralRateController.text.replaceAll(',', '.')) ?? 105.0;
    final totalAmount = totalSqFt * rate;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: themeColor, width: widget.isActive ? 2.0 : 1.4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: SwitchListTile(
                  title: const Text('Center', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Color(0xFF1E293B))),
                  value: widget.isActive,
                  activeThumbColor: themeColor,
                  activeTrackColor: themeColor.withValues(alpha: 0.4),
                  onChanged: widget.onToggle,
                ),
              ),
              if (widget.isActive)
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(color: themeColor, borderRadius: BorderRadius.circular(6)),
                    child: const Icon(Icons.add, color: Colors.white, size: 18),
                  ),
                  tooltip: 'Add Row',
                  onPressed: () {
                    setState(() {
                      ctrl.extraCentralRows.add(CentralDesignRow());
                    });
                    ctrl.updateLivePreview();
                  },
                ),
              const SizedBox(width: 8),
            ],
          ),
          if (widget.isActive) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  StandardCenterTypeSelector(
                    ctrl: ctrl,
                    themeColor: themeColor,
                    activeType: widget.activeType,
                    onTypeChanged: widget.onTypeChanged,
                  ),
                  const SizedBox(height: 14),
                  StandardCenterRowsWidget(
                    ctrl: ctrl,
                    themeColor: themeColor,
                    onChanged: () => setState(() {}),
                  ),
                  const SizedBox(height: 14),
                  StandardCenterSummaryWidget(
                    ctrl: ctrl,
                    themeColor: themeColor,
                    totalSqFt: totalSqFt,
                    totalAmount: totalAmount,
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
