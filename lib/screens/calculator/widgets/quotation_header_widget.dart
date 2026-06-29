import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../theme/app_theme.dart';
import '../../../services/customer_sync_service.dart';

class QuotationHeaderWidget extends StatelessWidget {
  final String unitId;

  const QuotationHeaderWidget({super.key, required this.unitId});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        StreamBuilder<List<CustomerRegistration>>(
          stream: CustomerSyncService.instance.getRegistrations(unitId),
          builder: (context, snapshot) {
            bool isSynced = snapshot.hasData && snapshot.data!.isNotEmpty;
            return Container(
              width: double.infinity,
              color: isSynced ? Colors.green.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 15),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(isSynced ? Icons.cloud_done : Icons.cloud_off, size: 14, color: isSynced ? Colors.green : Colors.orange),
                  const SizedBox(width: 8),
                  Text(
                    isSynced ? 'CLIENT DATA LINKED' : 'WAITING FOR CLIENT FORM...',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: isSynced ? Colors.green : Colors.orange, letterSpacing: 1),
                  ),
                ],
              ),
            );
          }
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: AppStyles.neumorphicDecoration(color: Colors.white, hasThickBorder: true),
          child: Column(
            children: [
              const Text('PCM WAYANAD', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 3, color: AppColors.border)),
              const Text('Premium Interior Solutions', style: TextStyle(fontSize: 10, letterSpacing: 2, color: Colors.black54)),
              const Divider(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('ESTIMATE NOTE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  Text(DateFormat('dd-MMM-yyyy').format(DateTime.now()), style: const TextStyle(fontSize: 12)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
