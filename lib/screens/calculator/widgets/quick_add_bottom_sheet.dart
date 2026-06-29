import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../calculator_controller.dart';
import '../../../providers/language_provider.dart';
import '../../../models/quotation.dart';
import '../../../utils/calculator_utils.dart';
import 'quick_add/quick_add_header.dart';
import 'quick_add/quick_add_ceiling_toggle.dart';
import 'quick_add/quick_add_unit_rate_selector.dart';
import 'quick_add/quick_add_brand_selector.dart';
import 'quick_add/quick_add_dimensions_row.dart';
import 'quick_add/quick_add_manual_area_override.dart';
import 'quick_add/quick_add_additional_options.dart';
import 'quick_add/quick_add_estimate_preview.dart';
import 'quick_add/quick_add_submit_button.dart';
import 'quick_add/quick_add_actions.dart';
import 'quick_add/quick_add_edit_dialog.dart';

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
  String get _design => ctrl.selectedDesign == 'Other' ? (ctrl.designController.text.isEmpty ? 'Custom Design' : ctrl.designController.text) : (ctrl.selectedDesign ?? newDesignType ?? 'Custom Design');

  @override
  Widget build(BuildContext context) {
    final lin = CalculatorUtils.getLinearUnitLabel(ctrl.unit);
    final ar = CalculatorUtils.getAreaUnitLabel(ctrl.unit);
    final double maxSheetHeight = MediaQuery.of(context).size.height * 0.85;
    return Container(
      constraints: BoxConstraints(maxHeight: maxSheetHeight),
      decoration: const BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      padding: const EdgeInsets.all(20),
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
                    QuickAddHeader(ctrl: ctrl, currentRoomName: _room, currentDesignName: _design, onEditDetails: () => showQuickAddEditDialog(context, ctrl, _design)),
                    const SizedBox(height: 10),
                    QuickAddCeilingToggle(value: ctrl.isCeilingDesign, onChanged: (v) => QuickAddActions.toggleCeilingDesign(ctrl, v)),
                    const SizedBox(height: 15),
                    QuickAddUnitRateSelector(ctrl: ctrl, lang: lang, onUnitChanged: (v) { if (v != null) { if (v == 'RFT') ctrl.widthController.clear(); ctrl.handleUnitChange(v); } }),
                    const SizedBox(height: 15),
                    QuickAddBrandSelector(ctrl: ctrl, isCeilingDesign: ctrl.isCeilingDesign),
                    QuickAddDimensionsRow(ctrl: ctrl, isCeilingDesign: ctrl.isCeilingDesign),
                    if (ctrl.isCeilingDesign) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 15),
                        decoration: AppStyles.neumorphicDecoration(
                          color: AppColors.pureWhite,
                          hasThickBorder: false,
                          borderRadius: 8,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Calculated Main Area',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.labelColor),
                            ),
                            Text(
                              '= ${ctrl.livePreviewMainAreaSqFt.toStringAsFixed(2)} SQFT',
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.black),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 15),
                    QuickAddManualAreaOverride(ctrl: ctrl, isCeilingDesign: ctrl.isCeilingDesign, areaUnit: ar),
                    QuickAddAdditionalOptions(
                      ctrl: ctrl, isCeilingDesign: ctrl.isCeilingDesign, hasCentralDesign: ctrl.hasCentralDesign, hasCove: ctrl.hasCove,
                      linearUnit: lin, areaUnit: ar, onCentralToggle: (v) => QuickAddActions.toggleCentral(ctrl, v), onCoveToggle: (v) => QuickAddActions.toggleCove(ctrl, v),
                    ),
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
