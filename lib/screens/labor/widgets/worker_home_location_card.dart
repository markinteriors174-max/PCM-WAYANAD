import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../../models/labor_models.dart';

class WorkerHomeLocationCard extends StatelessWidget {
  final Worker worker;
  final bool isSavingHome;
  final VoidCallback onRegisterHome;

  const WorkerHomeLocationCard({
    super.key,
    required this.worker,
    required this.isSavingHome,
    required this.onRegisterHome,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasHome = worker.homeLat != null && worker.homeLng != null;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppStyles.neumorphicDecoration(color: Colors.white, hasThickBorder: true),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.home, color: AppColors.border, size: 20),
              const SizedBox(width: 10),
              const Text('REGISTERED HOME LOCATION', style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.border, fontSize: 11)),
              const Spacer(),
              if (hasHome) const Icon(Icons.verified, color: AppColors.resultGreen, size: 16),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            hasHome 
              ? 'Lat: ${worker.homeLat!.toStringAsFixed(4)}, Lng: ${worker.homeLng!.toStringAsFixed(4)}'
              : 'Home location not registered. Travel allowance cannot be calculated.',
            style: TextStyle(fontSize: 10, color: hasHome ? Colors.black87 : Colors.red, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 15),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: isSavingHome ? null : onRegisterHome,
              icon: isSavingHome ? const SizedBox(height: 15, width: 15, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.my_location, size: 16),
              label: const Text('REGISTER CURRENT LOCATION AS HOME', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 10)),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryButton, foregroundColor: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
