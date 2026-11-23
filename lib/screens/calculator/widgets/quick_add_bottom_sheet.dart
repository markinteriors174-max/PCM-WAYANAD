import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../calculator_controller.dart';
import '../../../providers/language_provider.dart';
import '../../../models/quotation.dart';
import 'quick_add/quick_add_multi_rate_tiers_widget.dart';
import 'quick_add/quick_add_ceiling_toggle.dart';
import 'quick_add/quick_add_estimate_preview.dart';
import 'quick_add/quick_add_submit_button.dart';

class QuickAddBottomSheet extends StatelessWidget {
  final CalculatorController ctrl; final LanguageProvider lang;
  final String? newDesignType; final QuotationItem? existingItem; final int? existingIndex;
  const QuickAddBottomSheet({super.key, required this.ctrl, required this.lang, this.newDesignType, this.existingItem, this.existingIndex});
  static void show(BuildContext ctx, CalculatorController c, LanguageProvider l, {String? newDesignType, QuotationItem? existingItem, int? existingIndex}) {
    if (newDesignType != null) {
      c.resetInputs(); c.selectedDesign = newDesignType;
      final rate = c.getDefaultRate(c.selectedCeilingType);
      if (rate > 0) c.rateController.text = rate.toString();
    } else if (existingItem != null) {
      c.loadItemIntoControllers(existingItem);
    } else {
      // For any new entry, ensure all dimension fields remain completely empty
      c.lengthController.clear();
      c.widthController.clear();
      c.heightController.clear();
      c.thicknessController.clear();
      c.areaController.clear();
      c.coveRftController.clear();
      c.coveLengthController.clear();
      c.coveWidthController.clear();
      c.coveLength2Controller.clear();
      c.coveWidth2Controller.clear();
      c.centralAreaController.clear();
      c.centralLengthController.clear();
      c.centralWidthController.clear();
      c.extraCentralRows.clear();
      c.extraCoveRows.clear();
      c.unit = 'Meter';
      c.centralUnit = 'Meter';
      c.customCenterUnit = 'Meter';
      c.coveUnit = 'Meter';
      c.rateController.text = '105.0';
      c.centralRateController.text = '105.0';
      c.customCenterRateController.text = '105.0';
      c.coveRateController.text = '105.0';
      c.extraPlainRows.clear();
      c.extraCentralRows.clear();
      c.extraCustomCentralRows.clear();
      c.extraCoveRows.clear();
      c.lastLength = '';
      c.lastWidth = '';
      c.quantityController.text = '1';
      c.livePreviewAmount = 0;
      c.livePreviewAreaSqFt = 0;
      c.livePreviewMainAreaSqFt = 0;
      final rate = c.getDefaultRate(c.selectedCeilingType);
      if (rate > 0) {
        c.rateController.text = rate.toString();
        c.centralRateController.text = rate.toString();
        c.customCenterRateController.text = rate.toString();
        c.coveRateController.text = rate.toString();
      }
    }
    showModalBottomSheet(
      context: ctx, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (cx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(cx).viewInsets.bottom),
        child: QuickAddBottomSheet(ctrl: c, lang: l, newDesignType: newDesignType, existingItem: existingItem, existingIndex: existingIndex),
      ),
    );
  }

  String get _room => ctrl.selectedRoom == 'Other' ? (ctrl.roomController.text.isEmpty ? 'Custom Room' : ctrl.roomController.text) : (ctrl.selectedRoom ?? 'Unknown Room');

  @override
  Widget build(BuildContext context) {
    final double maxSheetHeight = MediaQuery.of(context).size.height * 0.85;
    return Container(
      constraints: BoxConstraints(maxHeight: maxSheetHeight),
      decoration: const BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      child: ListenableBuilder(
        listenable: ctrl,
        builder: (context, _) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (existingItem == null) ...[
                      QuickAddMultiRateTiersWidget(ctrl: ctrl, currentRoomName: _room),
                      const SizedBox(height: 10),
                    ],
                    // Floor & Room # row at the top
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: AppStyles.neumorphicDecoration(color: AppColors.pureWhite, hasThickBorder: false, borderRadius: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: DropdownButtonFormField<String>(
                                  initialValue: ctrl.selectedFloor,
                                  decoration: const InputDecoration(
                                    labelText: 'Floor (നില)',
                                    isDense: true,
                                    border: OutlineInputBorder(),
                                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                  ),
                                  items: const [
                                    DropdownMenuItem(value: 'Ground Floor', child: Text('Ground Floor', style: TextStyle(fontSize: 12))),
                                    DropdownMenuItem(value: '1st Floor', child: Text('1st Floor', style: TextStyle(fontSize: 12))),
                                    DropdownMenuItem(value: '2nd Floor', child: Text('2nd Floor', style: TextStyle(fontSize: 12))),
                                    DropdownMenuItem(value: '3rd Floor', child: Text('3rd Floor', style: TextStyle(fontSize: 12))),
                                    DropdownMenuItem(value: 'Basement', child: Text('Basement', style: TextStyle(fontSize: 12))),
                                    DropdownMenuItem(value: 'Terrace', child: Text('Terrace', style: TextStyle(fontSize: 12))),
                                  ],
                                  onChanged: (v) {
                                    if (v != null) {
                                      ctrl.selectedFloor = v;
                                      ctrl.notifyUI();
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 2,
                                child: TextField(
                                  controller: ctrl.roomNumberController,
                                  decoration: const InputDecoration(
                                    labelText: 'Room #',
                                    isDense: true,
                                    border: OutlineInputBorder(),
                                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Ceiling switch cards (Plain, Cove, Center)
                    QuickAddCeilingToggle(ctrl: ctrl),
                    const SizedBox(height: 15),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 15),
            QuickAddEstimatePreview(ctrl: ctrl),
            QuickAddSubmitButton(ctrl: ctrl, existingItem: existingItem, existingIndex: existingIndex),
          ],
        ),
      ),
    );
  }
}
