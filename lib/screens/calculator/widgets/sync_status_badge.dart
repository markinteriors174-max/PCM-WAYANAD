import 'package:flutter/material.dart';
import '../../../services/sync_status_service.dart';

class SyncStatusBadge extends StatelessWidget {
  const SyncStatusBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: SyncStatusService.isSynced,
      builder: (context, isSynced, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: isSynced ? const Color(0xFF22C55E).withValues(alpha: 0.15) : const Color(0xFFD97706).withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSynced ? const Color(0xFF22C55E) : const Color(0xFFD97706),
              width: 1.0,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: isSynced ? const Color(0xFF22C55E) : const Color(0xFFD97706),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                isSynced ? 'Synced' : 'Offline / Saved on Device',
                style: TextStyle(
                  color: isSynced ? const Color(0xFF4ADE80) : const Color(0xFFFBBF24),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
