import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

class ActionButtonsBar extends StatelessWidget {
  final bool hasPin;
  final bool isPinning;
  final VoidCallback onPinLocation;
  final VoidCallback onOpenCalculator;
  final VoidCallback onLiveUpdate;
  final VoidCallback onOpenChat;
  final VoidCallback onVoipCall;
  final VoidCallback onOpenAttendance;
  final VoidCallback onDelete;

  const ActionButtonsBar({
    super.key,
    required this.hasPin,
    required this.isPinning,
    required this.onPinLocation,
    required this.onOpenCalculator,
    required this.onLiveUpdate,
    required this.onOpenChat,
    required this.onVoipCall,
    required this.onOpenAttendance,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildActionLabel(
                icon: Icons.pin_drop,
                label: isPinning ? 'PINNING GPS...' : (hasPin ? 'RE-PIN SITE GPS' : 'PIN SITE GPS'),
                onTap: isPinning ? () {} : onPinLocation,
                isAccent: !hasPin,
              ),
              _buildActionLabel(
                icon: Icons.calculate,
                label: 'OPEN CALCULATOR',
                onTap: onOpenCalculator,
                isAccent: true,
              ),
              _buildActionLabel(
                icon: Icons.sync,
                label: 'LIVE UPDATE',
                onTap: onLiveUpdate,
                isAccent: true,
              ),
              _buildActionLabel(
                icon: Icons.forum,
                label: 'CHAT',
                onTap: onOpenChat,
                isAccent: true,
              ),
              _buildActionLabel(
                icon: Icons.wifi_calling,
                label: 'VOIP CALL',
                onTap: onVoipCall,
                isAccent: true,
              ),
              _buildActionLabel(
                icon: Icons.engineering,
                label: 'ATTENDANCE',
                onTap: onOpenAttendance,
                isAccent: true,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        _buildSmallActionIcon(Icons.delete_outline, onDelete, isRed: true),
      ],
    );
  }

  Widget _buildActionLabel({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isAccent = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isAccent ? AppColors.border : Colors.transparent,
          border: Border.all(color: AppColors.border, width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: isAccent ? Colors.white : AppColors.border),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: isAccent ? Colors.white : AppColors.border,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSmallActionIcon(IconData icon, VoidCallback onTap, {bool isRed = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isRed ? AppColors.alertRed.withValues(alpha: 0.05) : AppColors.border.withValues(alpha: 0.05),
          border: Border.all(color: isRed ? AppColors.alertRed : AppColors.border, width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: isRed ? AppColors.alertRed : AppColors.border, size: 20),
      ),
    );
  }
}
