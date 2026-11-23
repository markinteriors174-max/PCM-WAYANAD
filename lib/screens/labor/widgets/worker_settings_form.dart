import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

class WorkerSettingsForm extends StatelessWidget {
  final TextEditingController rateController;
  final TextEditingController advanceController;
  final bool isSavingRate;
  final bool isSavingAdvance;
  final VoidCallback onUpdateRate;
  final VoidCallback onRecordAdvance;

  const WorkerSettingsForm({
    super.key,
    required this.rateController,
    required this.advanceController,
    required this.isSavingRate,
    required this.isSavingAdvance,
    required this.onUpdateRate,
    required this.onRecordAdvance,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppStyles.neumorphicDecoration(color: Colors.white, hasThickBorder: true),
      child: Column(
        children: [
          TextField(
            controller: rateController,
            decoration: AppStyles.inputDecoration('Daily Wage Rate (₹)'),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 15),
          SizedBox(
            width: double.infinity,
            height: 45,
            child: ElevatedButton(
              onPressed: isSavingRate ? null : onUpdateRate,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.border, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
              child: isSavingRate 
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                : const Text('UPDATE WAGE RATE', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12)),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Divider(color: Colors.black12),
          ),
          TextField(
            controller: advanceController,
            decoration: AppStyles.inputDecoration('Issue Advance Payment (₹)'),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 15),
          SizedBox(
            width: double.infinity,
            height: 45,
            child: ElevatedButton(
              onPressed: isSavingAdvance ? null : onRecordAdvance,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.resultGreen, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
              child: isSavingAdvance 
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                : const Text('RECORD ADVANCE PAYMENT', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }
}
