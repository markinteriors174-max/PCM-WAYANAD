import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../theme/app_theme.dart';
import '../../../models/labor_models.dart';

class AttendanceHistoryList extends StatelessWidget {
  final List<LaborEntry> history;
  final List<AdvancePayment> advances;
  final Function(AdvancePayment) onLongPressAdvance;

  const AttendanceHistoryList({
    super.key,
    required this.history,
    required this.advances,
    required this.onLongPressAdvance,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // History Section
        const Text('ATTENDANCE HISTORY', style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.border, letterSpacing: 1, fontSize: 12)),
        const SizedBox(height: 15),
        if (history.isEmpty)
          _buildNoHistory()
        else
          ...history.map((entry) => _buildHistoryItem(entry)),

        const SizedBox(height: 30),
        const Text('ADVANCE PAYMENT LOG', style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.border, letterSpacing: 1, fontSize: 12)),
        const SizedBox(height: 4),
        const Text('Long-press a record to delete if entered by mistake', style: TextStyle(fontSize: 9, color: Colors.black38, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        if (advances.isEmpty)
          _buildNoAdvances()
        else
          ...advances.map((adv) => _buildAdvanceItem(adv)),
      ],
    );
  }

  Widget _buildNoHistory() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: AppStyles.neumorphicDecoration(color: Colors.white),
      child: const Center(
        child: Text('No attendance history found.', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildHistoryItem(LaborEntry entry) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: AppStyles.neumorphicDecoration(color: Colors.white),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(entry.siteName.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: AppColors.border)),
              const SizedBox(height: 4),
              Text(DateFormat('dd MMM yyyy').format(entry.date), style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('₹${entry.totalWage.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: AppColors.resultGreen)),
              if (entry.travelAllowance > 0) Text('+₹${entry.travelAllowance.toStringAsFixed(0)} Travel', style: const TextStyle(fontSize: 8, color: Colors.blue, fontWeight: FontWeight.bold)),
              Text(entry.shiftType.name.toUpperCase(), style: const TextStyle(fontSize: 9, color: Colors.blueGrey, fontWeight: FontWeight.w900)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNoAdvances() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: AppStyles.neumorphicDecoration(color: Colors.white),
      child: const Center(
        child: Text('No advance payments recorded.', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildAdvanceItem(AdvancePayment adv) {
    return GestureDetector(
      onLongPress: () => onLongPressAdvance(adv),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: AppStyles.neumorphicDecoration(color: Colors.white),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('ADVANCE GIVEN', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.orange)),
                Text(DateFormat('dd MMM yyyy').format(adv.date), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
            Text('- ₹${adv.amount.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.redAccent)),
          ],
        ),
      ),
    );
  }
}
