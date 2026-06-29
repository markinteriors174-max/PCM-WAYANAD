import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../../models/labor_models.dart';

class WorkerProfileHeader extends StatelessWidget {
  final Worker worker;
  final double starBonus;

  const WorkerProfileHeader({
    super.key,
    required this.worker,
    required this.starBonus,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppStyles.neumorphicDecoration(color: Colors.white, hasThickBorder: true),
      child: Row(
        children: [
          CircleAvatar(
            radius: 35,
            backgroundColor: AppColors.border.withValues(alpha: 0.1),
            child: const Icon(Icons.person, size: 40, color: AppColors.border),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(worker.name.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: AppColors.border)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.star, size: 18, color: Colors.orange),
                    const SizedBox(width: 4),
                    Text('${worker.rating} Stars', style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.orange, fontSize: 14)),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: AppColors.resultGreen.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                      child: Text('+ ₹${starBonus.toStringAsFixed(0)} Bonus', style: const TextStyle(color: AppColors.resultGreen, fontWeight: FontWeight.w900, fontSize: 10)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 14, color: Colors.blueGrey),
                    const SizedBox(width: 4),
                    Text(worker.place.toUpperCase(), style: const TextStyle(fontSize: 12, color: Colors.blueGrey, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.phone, size: 14, color: Colors.blueGrey),
                    const SizedBox(width: 4),
                    Text(worker.phoneNumber, style: const TextStyle(fontSize: 12, color: Colors.blueGrey, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
