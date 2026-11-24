import 'package:flutter/material.dart';
import 'package:pcm_wayanad/screens/calculator/calculator_controller.dart';
import 'package:pcm_wayanad/utils/calculator_utils.dart';
import '../../../helpers/round_center_quotation_helper.dart';

class CustomCenterSummaryWidget extends StatelessWidget {
  final CalculatorController ctrl;
  final Color themeColor;
  final double totalSqFt;
  final double totalAmount;

  const CustomCenterSummaryWidget({
    super.key,
    required this.ctrl,
    required this.themeColor,
    required this.totalSqFt,
    required this.totalAmount,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
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
            onPressed: () async {
              try {
                ctrl.updateLivePreview();
                ctrl.updateProjectTotals();

                final roomName = ctrl.selectedRoom == 'Other' ? (ctrl.roomController.text.isEmpty ? 'Custom Room' : ctrl.roomController.text) : (ctrl.selectedRoom ?? 'General');
                final ceilingType = ctrl.selectedCeilingType ?? 'Gypsum Board';
                final brandName = ctrl.selectedBrand ?? 'Gypsum Board';
                double factor = 1.0;
                double userRate = double.tryParse(ctrl.customCenterRateController.text.replaceAll(',', '.')) ?? 105.0;
                double q = double.tryParse(ctrl.customCenterQuantityController.text.replaceAll(',', '.')) ?? 1.0;

                RoundCenterQuotationHelper.addRoundCenterItems(
                  ctrl,
                  ctrl.currentItems,
                  roomName: roomName,
                  ceilingType: ceilingType,
                  brandName: brandName,
                  factor: factor,
                  userRate: userRate,
                  q: q,
                );

                // 1. Save to database first
                await ctrl.saveToDatabase(showSnackBar: false);

                // 2. Only if DB save succeeds, apply and sum into bottom total
                ctrl.isCustomCenterApplied = true;
                ctrl.updateLivePreview();
                ctrl.updateProjectTotals();
                ctrl.triggerAutoSave();
                ctrl.notifyUI();

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('✓ Round Design Saved & Applied to Sheet!')),
                  );
                }
              } catch (e) {
                // If saving fails, do not apply unsaved total
                ctrl.isCustomCenterApplied = false;
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to save to database: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            icon: const Icon(Icons.check_circle, size: 16),
            label: const Text('APPLY & RECALCULATE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5)),
          ),
        ),
        const SizedBox(height: 12),
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
    );
  }
}
