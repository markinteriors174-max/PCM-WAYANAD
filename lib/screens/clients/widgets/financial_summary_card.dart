import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/calculator_utils.dart';

class FinancialSummaryCard extends StatelessWidget {
  final double totalContract;
  final double advanceReceived;
  final double totalLaborCost;
  final double balanceDue;

  const FinancialSummaryCard({
    super.key,
    required this.totalContract,
    required this.advanceReceived,
    required this.totalLaborCost,
    required this.balanceDue,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 2.8,
      mainAxisSpacing: 8,
      crossAxisSpacing: 12,
      children: [
        _buildFinanceItem('TOTAL CONTRACT', totalContract, AppColors.border),
        _buildFinanceItem('TOTAL RECEIVED', advanceReceived, AppColors.resultGreen),
        _buildFinanceItem('TOTAL LABOR COST', totalLaborCost, Colors.blueGrey),
        _buildFinanceItem('BALANCE DUE', balanceDue, balanceDue > 0 ? AppColors.alertRed : AppColors.resultGreen),
      ],
    );
  }

  Widget _buildFinanceItem(String label, double amount, Color amountColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.labelColor, fontSize: 8.5, fontWeight: FontWeight.bold, letterSpacing: 0.5),
        ),
        const SizedBox(height: 2),
        Text(
          '₹${CalculatorUtils.formatIndianCurrency(amount)}',
          style: TextStyle(fontWeight: FontWeight.w900, color: amountColor, fontSize: 14),
        ),
      ],
    );
  }
}
