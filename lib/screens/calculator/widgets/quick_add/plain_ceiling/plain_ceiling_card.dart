import 'package:flutter/material.dart';
import '../../../calculator_controller.dart';
import '../quick_add_actions.dart';
import '../quick_add_dimensions_row.dart';
import '../quick_add_unit_rate_selector.dart';
import 'package:pcm_wayanad/utils/calculator_utils.dart';
import 'package:pcm_wayanad/utils/pcm_math_engine.dart';

class PlainCeilingCard extends StatelessWidget {
  final CalculatorController ctrl;
  final VoidCallback onChanged;

  const PlainCeilingCard({
    super.key,
    required this.ctrl,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    const cardColor = Color(0xFFD93829); // Rich red/coral
    final double l = double.tryParse(ctrl.lengthController.text.replaceAll(',', '.')) ?? 0.0;
    final double w = double.tryParse(ctrl.widthController.text.replaceAll(',', '.')) ?? 0.0;
    final double q = double.tryParse(ctrl.quantityController.text.replaceAll(',', '.')) ?? 1.0;

    double extraPlainSqFtSum = 0.0;
    for (var r in ctrl.extraPlainRows) {
      double len = double.tryParse(r.lengthController.text.replaceAll(',', '.')) ?? 0.0;
      double wid = double.tryParse(r.widthController.text.replaceAll(',', '.')) ?? 0.0;
      double qty = double.tryParse(r.quantityController.text.replaceAll(',', '.')) ?? 1.0;
      double converted = PcmMathEngine.calculateAreaSqFt(
        length: len,
        width: wid,
        quantity: qty,
        unit: ctrl.unit,
        isAreaUnit: ctrl.isAreaUnit,
      );
      r.areaController.text = converted > 0 ? converted.toStringAsFixed(2) : '';
      extraPlainSqFtSum += converted;
    }

    final double mainArea = ctrl.livePreviewMainAreaSqFt > 0 ? ctrl.livePreviewMainAreaSqFt : PcmMathEngine.calculateAreaSqFt(
      length: l,
      width: ctrl.isAreaUnit ? w : 1.0,
      quantity: q,
      unit: ctrl.unit,
      isAreaUnit: ctrl.isAreaUnit,
    );
    final double displayedPlainArea = double.tryParse(mainArea.toStringAsFixed(2)) ?? mainArea;
    final double plainArea = displayedPlainArea + extraPlainSqFtSum;
    final double rate = double.tryParse(ctrl.rateController.text.replaceAll(',', '.')) ?? 105.0;
    final double plainTotal = PcmMathEngine.calculateAmount(areaSqFt: plainArea, rate: rate);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: cardColor,
          width: ctrl.isPlainCeilingOn ? 2.0 : 1.4,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: SwitchListTile(
                  title: const Text(
                    'Plain',
                    style: TextStyle(color: Color(0xFF1E293B), fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  value: ctrl.isPlainCeilingOn,
                  activeThumbColor: cardColor,
                  activeTrackColor: cardColor.withValues(alpha: 0.4),
                  onChanged: (val) {
                    ctrl.isPlainCeilingOn = val;
                    if (val) {
                      ctrl.isCoveCeilingOn = false;
                      QuickAddActions.toggleCove(ctrl, false);
                      ctrl.isCenterCeilingOn = false;
                      QuickAddActions.toggleCentral(ctrl, false);
                    }
                    QuickAddActions.toggleCeilingDesign(ctrl, val);
                    ctrl.notifyUI();
                    onChanged();
                  },
                ),
              ),
              if (ctrl.isPlainCeilingOn)
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
                    ctrl.extraPlainRows.add(CentralDesignRow());
                    ctrl.updateLivePreview();
                    onChanged();
                  },
                ),
              const SizedBox(width: 8),
            ],
          ),
          if (ctrl.isPlainCeilingOn) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  QuickAddUnitRateSelector(
                    ctrl: ctrl,
                    rateController: ctrl.rateController,
                    currentUnit: ctrl.unit,
                    borderColor: cardColor,
                    onUnitChanged: (v) {
                      if (v != null) {
                        if (v == 'RFT') ctrl.widthController.clear();
                        ctrl.handleUnitChange(v);
                        onChanged();
                      }
                    },
                  ),
                  const SizedBox(height: 10),
                  QuickAddDimensionsRow(ctrl: ctrl, isCeilingDesign: ctrl.isCeilingDesign),

                  // Extra Plain Rows
                  for (int i = 0; i < ctrl.extraPlainRows.length; i++) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: ctrl.extraPlainRows[i].lengthController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 12),
                            decoration: const InputDecoration(
                              labelText: 'LENGTH',
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
                            controller: ctrl.extraPlainRows[i].widthController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 12),
                            decoration: const InputDecoration(
                              labelText: 'WIDTH',
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
                            controller: ctrl.extraPlainRows[i].quantityController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 12),
                            decoration: const InputDecoration(
                              labelText: 'QTY',
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
                            controller: ctrl.extraPlainRows[i].areaController,
                            readOnly: true,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12),
                            decoration: const InputDecoration(
                              labelText: 'SQFT',
                              labelStyle: TextStyle(color: Colors.grey, fontSize: 11),
                              isDense: true,
                              border: OutlineInputBorder(),
                              fillColor: Color(0xFFF1F5F9),
                              filled: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                          onPressed: () {
                            ctrl.extraPlainRows.removeAt(i);
                            ctrl.updateLivePreview();
                            ctrl.triggerAutoSave();
                            onChanged();
                          },
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 12),
                  // Apply Button matching Cove & Center
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: cardColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      onPressed: () {
                        ctrl.updateLivePreview();
                        ctrl.triggerAutoSave();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('✓ Plain ceiling details applied & recalculated!'),
                            backgroundColor: cardColor,
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      icon: const Icon(Icons.check_circle, size: 16, color: Colors.white),
                      label: const Text(
                        'APPLY PLAIN DETAILS',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 12.5,
                          letterSpacing: 0.6,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Standardized Section Total Summary Box
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFFCA5A5), width: 1.5),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.layers_outlined, size: 17, color: Color(0xFF991B1B)),
                            const SizedBox(width: 6),
                            Text(
                              'PLAIN TOTAL: ₹${CalculatorUtils.formatIndianCurrency(plainTotal)}',
                              style: const TextStyle(
                                color: Color(0xFF991B1B),
                                fontWeight: FontWeight.w900,
                                fontSize: 16.5,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'PLAIN AREA: ${CalculatorUtils.formatNumber(plainArea)} SQFT',
                          style: const TextStyle(
                            color: Color(0xFFB91C1C),
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
}
