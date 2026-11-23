import 'package:flutter/material.dart';
import 'package:pcm_wayanad/theme/app_theme.dart';
import '../../../calculator_controller.dart';
import '../quick_add_unit_rate_selector.dart';
import 'package:pcm_wayanad/screens/calculator/units/calculator_unit_helper.dart';
import 'package:pcm_wayanad/utils/calculator_utils.dart';

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
  Widget build(BuildContext context) {
    const themeColor = Color(0xFF15803D); // Rich green theme

    if (ctrl.extraCentralRows.isEmpty) {
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

    final primaryL = double.tryParse(ctrl.centralLengthController.text) ?? 0.0;
    final primaryW = double.tryParse(ctrl.centralWidthController.text) ?? 0.0;
    final primaryQText = ctrl.centralQuantityController.text.trim();
    final primaryQ = primaryQText.isEmpty ? 1.0 : (double.tryParse(primaryQText) ?? 1.0);
    final primarySqFt = (primaryL * primaryW * primaryQ) * areaFactor;

    ctrl.centralAreaController.text = primarySqFt > 0 ? primarySqFt.toStringAsFixed(2) : '';

    double extraRowsSqFtSum = 0.0;
    for (var r in ctrl.extraCentralRows) {
      final l = double.tryParse(r.lengthController.text) ?? 0.0;
      final b = double.tryParse(r.widthController.text) ?? 0.0;
      final qText = r.quantityController.text.trim();
      final q = qText.isEmpty ? 1.0 : (double.tryParse(qText) ?? 1.0);
      final rowSqFt = (l * b * q) * areaFactor;
      r.areaController.text = rowSqFt > 0 ? rowSqFt.toStringAsFixed(2) : '';
      extraRowsSqFtSum += rowSqFt;
    }

    final totalSqFt = primarySqFt + extraRowsSqFtSum;
    final rate = double.tryParse(ctrl.centralRateController.text) ?? 105.0;
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
                  title: const Text(
                    'Center',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Color(0xFF1E293B)),
                  ),
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
                    decoration: BoxDecoration(
                      color: themeColor,
                      borderRadius: BorderRadius.circular(6),
                    ),
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
                  // Type selector row: Type: with Standard (Center) and Custom Center shown ONLY when ON
                  Row(
                    children: [
                      const Text('Type: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.labelColor)),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('Standard (Center)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        selected: widget.activeType == 'Standard (Center)',
                        selectedColor: themeColor.withValues(alpha: 0.3),
                        backgroundColor: Colors.grey.shade200,
                        labelStyle: TextStyle(color: widget.activeType == 'Standard (Center)' ? Colors.green.shade900 : Colors.black87),
                        onSelected: (sel) {
                          widget.onTypeChanged('Standard (Center)');
                        },
                      ),
                      const SizedBox(width: 6),
                      ChoiceChip(
                        label: const Text('Custom Center', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        selected: widget.activeType == 'Custom Center',
                        selectedColor: themeColor.withValues(alpha: 0.3),
                        backgroundColor: Colors.grey.shade200,
                        labelStyle: TextStyle(color: widget.activeType == 'Custom Center' ? Colors.green.shade900 : Colors.black87),
                        onSelected: (sel) {
                          widget.onTypeChanged('Custom Center');
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  QuickAddUnitRateSelector(
                    ctrl: ctrl,
                    rateController: ctrl.centralRateController,
                    currentUnit: ctrl.centralUnit,
                    borderColor: themeColor,
                    onUnitChanged: (v) {
                      if (v != null) {
                        ctrl.centralUnit = v;
                        ctrl.updateLivePreview();
                        ctrl.triggerAutoSave();
                      }
                    },
                  ),
                  const SizedBox(height: 14),

                  // 3. Primary Center (Length / Width)
                  Row(
                    children: [
                      Expanded(child: _field(ctrl.centralLengthController, 'LENGTH', cardColor: themeColor)),
                      const SizedBox(width: 6),
                      Expanded(child: _field(ctrl.centralWidthController, 'WIDTH', cardColor: themeColor)),
                      const SizedBox(width: 6),
                      Expanded(child: _field(ctrl.centralQuantityController, 'QTY', cardColor: themeColor, hintText: '1')),
                      const SizedBox(width: 6),
                      Expanded(child: _field(ctrl.centralAreaController, 'SQFT', readOnly: true, cardColor: themeColor)),
                    ],
                  ),

                  // Extra Center Rows
                  for (int i = 0; i < ctrl.extraCentralRows.length; i++) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(child: _field(ctrl.extraCentralRows[i].lengthController, 'LENGTH', cardColor: themeColor)),
                        const SizedBox(width: 6),
                        Expanded(child: _field(ctrl.extraCentralRows[i].widthController, 'WIDTH', cardColor: themeColor)),
                        const SizedBox(width: 6),
                        Expanded(child: _field(ctrl.extraCentralRows[i].quantityController, 'QTY', cardColor: themeColor, hintText: '1')),
                        const SizedBox(width: 6),
                        Expanded(child: _field(ctrl.extraCentralRows[i].areaController, 'SQFT', readOnly: true, cardColor: themeColor)),
                        const SizedBox(width: 4),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                          onPressed: () {
                            setState(() {
                              ctrl.extraCentralRows.removeAt(i);
                            });
                            ctrl.updateLivePreview();
                            ctrl.triggerAutoSave();
                          },
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 14),

                  // 6. Action button: green APPLY & RECALCULATE button with check icon
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: themeColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () {
                        ctrl.updateLivePreview();
                        ctrl.triggerAutoSave();
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✓ Center Design Applied & Recalculated!')));
                      },
                      icon: const Icon(Icons.check_circle, size: 16),
                      label: const Text('APPLY & RECALCULATE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5)),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 7. Standardized Center Total Summary Box
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF86EFAC), width: 1.5),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.star_outline, size: 17, color: Color(0xFF166534)),
                            const SizedBox(width: 6),
                            Text(
                              'CENTER TOTAL: ₹${CalculatorUtils.formatIndianCurrency(totalAmount)}',
                              style: const TextStyle(
                                color: Color(0xFF166534),
                                fontWeight: FontWeight.w900,
                                fontSize: 16.5,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'CENTER AREA: ${CalculatorUtils.formatNumber(totalSqFt)} SQFT',
                          style: const TextStyle(
                            color: Color(0xFF14532D),
                            fontWeight: FontWeight.bold,
                            fontSize: 11.5,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _field(TextEditingController c, String l, {bool readOnly = false, bool enabled = true, String? hintText, Color? cardColor}) {
    return TextField(
      controller: c,
      readOnly: readOnly,
      enabled: enabled,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: AppStyles.inputDecoration(l).copyWith(
        fillColor: readOnly ? Colors.grey.shade100 : Colors.white,
        filled: true,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: cardColor ?? Colors.grey.shade400, width: 1.8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: cardColor ?? Colors.blue, width: 2.2),
        ),
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 11),
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      ),
      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: readOnly ? Colors.grey.shade700 : Colors.black),
      onTap: readOnly ? null : () {
        if (c.text == '1' || c.text == '1.0' || c.text == '1.00') {
          c.clear();
        } else {
          c.selection = TextSelection(baseOffset: 0, extentOffset: c.text.length);
        }
      },
      onChanged: readOnly ? null : (_) {
        setState(() {});
        ctrl.updateLivePreview();
        ctrl.triggerAutoSave();
      },
    );
  }
}
