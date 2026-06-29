import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

class WorkerHeaderCard extends StatelessWidget {
  final int attendanceCount;
  final double totalEarned;
  final double totalAdvanced;
  final double balanceDue;

  const WorkerHeaderCard({
    super.key,
    required this.attendanceCount,
    required this.totalEarned,
    required this.totalAdvanced,
    required this.balanceDue,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildStatCard('ATTENDANCE', '$attendanceCount Days', Icons.calendar_today, Colors.blue),
          const SizedBox(width: 10),
          _buildStatCard('EARNED', '₹${totalEarned.toStringAsFixed(0)}', Icons.payments, AppColors.resultGreen),
          const SizedBox(width: 10),
          _buildStatCard('ADVANCED', '₹${totalAdvanced.toStringAsFixed(0)}', Icons.money_off, Colors.redAccent),
          const SizedBox(width: 10),
          _buildStatCard('BALANCE', '₹${balanceDue.toStringAsFixed(0)}', Icons.account_balance_wallet, balanceDue > 0 ? Colors.orange : AppColors.resultGreen),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      width: 110,
      padding: const EdgeInsets.all(12),
      decoration: AppStyles.neumorphicDecoration(color: Colors.white, hasThickBorder: true),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 8, color: Colors.grey, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
          Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: color)),
        ],
      ),
    );
  }
}
