import 'package:flutter/material.dart';
import '../../../../utils/calculator_utils.dart';
import '../../models/room_data.dart';

/// Total Summary Widget for Site Measurement
class SiteMeasurementSummaryWidget extends StatelessWidget {
  final List<RoomData> rooms;
  final double totalSqFt;
  final String activeRate;
  final String selectedTier;
  final String baseRate;
  final TextEditingController baseRateController;
  final String baseChannel;
  final String baseBoard;
  final String premiumRate;
  final TextEditingController premiumRateController;
  final String premiumChannel;
  final String premiumBoard;
  final String luxuryRate;
  final TextEditingController luxuryRateController;
  final String luxuryChannel;
  final String luxuryBoard;
  final List<String> availableChannels;
  final List<String> availableBoards;
  final ValueChanged<String> onSelectTier;
  final ValueChanged<String> onBaseRateChanged;
  final ValueChanged<String> onPremiumRateChanged;
  final ValueChanged<String> onLuxuryRateChanged;
  final Function(String tier, String val) onTierChannelChanged;
  final Function(String tier, String val) onTierBoardChanged;
  final Function(String tier) onCustomChannelDialog;
  final Function(String tier) onCustomBoardDialog;
  final Set<String> selectedTiersForPdf;
  final Function(String tierName, bool selected) onToggleTierForPdf;
  final VoidCallback onSaveAndSync;
  final VoidCallback onPdfPreview;
  final VoidCallback onSharePdf;
  final VoidCallback onTransferToEstimator;

  const SiteMeasurementSummaryWidget({
    super.key,
    required this.rooms,
    required this.totalSqFt,
    required this.activeRate,
    required this.selectedTier,
    required this.baseRate,
    required this.baseRateController,
    required this.baseChannel,
    required this.baseBoard,
    required this.premiumRate,
    required this.premiumRateController,
    required this.premiumChannel,
    required this.premiumBoard,
    required this.luxuryRate,
    required this.luxuryRateController,
    required this.luxuryChannel,
    required this.luxuryBoard,
    required this.availableChannels,
    required this.availableBoards,
    required this.onSelectTier,
    required this.onBaseRateChanged,
    required this.onPremiumRateChanged,
    required this.onLuxuryRateChanged,
    required this.onTierChannelChanged,
    required this.onTierBoardChanged,
    required this.onCustomChannelDialog,
    required this.onCustomBoardDialog,
    this.selectedTiersForPdf = const {'BASE'},
    required this.onToggleTierForPdf,
    required this.onSaveAndSync,
    required this.onPdfPreview,
    required this.onSharePdf,
    required this.onTransferToEstimator,
  });

  // മൾട്ടി-റേറ്റ് ടയർ കാർഡുകൾക്കായി ടിക്ക് മാർക്ക് ബോക്സുകൾ നിർമ്മിക്കുന്ന കോഡ്
  Widget buildMultiTierSelectionCards() {
    return Row(
      children: [
        // 1. BASE TIER
        buildSingleTierCard(
          title: 'BASE',
          rate: baseRate.isNotEmpty ? baseRate : '105',
          isSelected: selectedTiersForPdf.contains('BASE'),
          onTap: () {
            onToggleTierForPdf('BASE', !selectedTiersForPdf.contains('BASE'));
          },
          cardColor: Colors.blueGrey,
          totalSquareFeet: totalSqFt,
        ),

        // 2. PREMIUM TIER
        buildSingleTierCard(
          title: 'PREMIUM',
          rate: premiumRate.isNotEmpty ? premiumRate : '120',
          isSelected: selectedTiersForPdf.contains('PREMIUM'),
          onTap: () {
            onToggleTierForPdf('PREMIUM', !selectedTiersForPdf.contains('PREMIUM'));
          },
          cardColor: Colors.amber,
          totalSquareFeet: totalSqFt,
        ),

        // 3. LUXURY TIER
        buildSingleTierCard(
          title: 'LUXURY',
          rate: luxuryRate.isNotEmpty ? luxuryRate : '145',
          isSelected: selectedTiersForPdf.contains('LUXURY'),
          onTap: () {
            onToggleTierForPdf('LUXURY', !selectedTiersForPdf.contains('LUXURY'));
          },
          cardColor: Colors.purple,
          totalSquareFeet: totalSqFt,
        ),
      ],
    );
  }

  // ഒറ്റപ്പെട്ട കാർഡിന്റെ ഡിസൈനും ടിക്ക് മാർക്കും
  Widget buildSingleTierCard({
    required String title,
    required String rate,
    required bool isSelected,
    required VoidCallback onTap,
    required Color cardColor,
    double? totalSquareFeet,
  }) {
    final rVal = double.tryParse(rate) ?? 0.0;
    final calcAmt = (totalSquareFeet != null && totalSquareFeet > 0) ? totalSquareFeet * rVal : null;

    return Expanded(
      child: GestureDetector(
        onTap: () => onSelectTier(title),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: cardColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? Colors.green : Colors.grey.shade400,
              width: isSelected ? 2.0 : 1.0,
            ),
          ),
          child: Column(
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
              const SizedBox(height: 4),
              Text('₹ $rate', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              if (calcAmt != null && calcAmt > 0) ...[
                const SizedBox(height: 2),
                Text(
                  '₹ ${calcAmt.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber.shade900,
                  ),
                ),
              ],
              const SizedBox(height: 8),

              // ടിക്ക് മാർക്ക് ബട്ടൺ (Tick / Selection Button)
              GestureDetector(
                onTap: onTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.green.shade700 : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                        size: 13,
                        color: isSelected ? Colors.white : Colors.black54,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        isSelected ? 'SELECTED' : 'TAP TO SELECT',
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 1. ഓരോ കാർഡിലും തുകയും ടിക്ക് ബോക്സും കാണിക്കുന്ന കോഡ് (Legacy fallback)
  Widget buildMultiTierCardWithCheckbox({
    required String tierName,
    required double ratePerSqFt,
    required double totalSquareFeet,
    required bool isSelected,
    required ValueChanged<bool?> onChanged,
    required Color cardColor,
  }) {
    return buildSingleTierCard(
      title: tierName,
      rate: ratePerSqFt.toStringAsFixed(0),
      isSelected: isSelected,
      onTap: () => onChanged(!isSelected),
      cardColor: cardColor,
      totalSquareFeet: totalSquareFeet,
    );
  }

  @override
  Widget build(BuildContext context) {
    final rateVal = double.tryParse(activeRate) ?? 105.0;
    final grandTotalAmount = totalSqFt * rateVal;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.amber.shade50,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.amber.shade300, width: 1.2),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('ആകെ റൂമുകൾ (Total Rooms):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.brown)),
                  Text('${rooms.length}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.brown)),
                ],
              ),
              const Divider(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('ആകെ വിസ്തീർണം (Total Area):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.brown)),
                  Text(
                    '${CalculatorUtils.formatNumber(totalSqFt)} Sq.Ft',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.green[800]),
                  ),
                ],
              ),
              const Divider(height: 14),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD97706).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.picture_as_pdf, color: Color(0xFFD97706), size: 16),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'PDF RATE TIER SELECTION',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                      letterSpacing: 0.8,
                      color: Color(0xFF3E2723),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              buildMultiTierSelectionCards(),
              const Divider(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('ആകെ മൊത്തം തുക (Overall Total):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.brown)),
                      Text(
                        '(@ ₹${activeRate.isNotEmpty ? activeRate : '105'} / Sq.Ft • ${rooms.length} റൂമുകൾ ആകെ)',
                        style: const TextStyle(fontSize: 11, color: Color(0xFF8D6E63), fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '₹${CalculatorUtils.formatIndianCurrency(grandTotalAmount)}',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green[900]),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Action Buttons Row
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.brown[800],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: onSaveAndSync,
                icon: const Icon(Icons.cloud_upload, size: 18),
                label: const Text('സേവ് & സിങ്ക്', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0284C7),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 2,
                ),
                onPressed: onPdfPreview,
                icon: const Icon(Icons.picture_as_pdf, size: 18),
                label: const Text('PDF പ്രിവ്യൂ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: onSharePdf,
                icon: const Icon(Icons.share, size: 18),
                label: const Text('ഷെയർ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber[800],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: onTransferToEstimator,
            icon: const Icon(Icons.calculate, size: 22),
            label: const Text('എസ്റ്റിമേറ്ററിലേക്ക് മാറ്റുക', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          ),
        ),
      ],
    );
  }
}
