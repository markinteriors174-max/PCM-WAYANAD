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
              // 1. PINNING GPS (White)
              _buildActionButton(
                icon: Icons.pin_drop,
                label: isPinning ? 'PINNING GPS...' : (hasPin ? 'RE-PIN GPS' : 'PIN GPS'),
                onTap: isPinning ? () {} : onPinLocation,
                bgColor: Colors.white,
                textColor: AppColors.border,
                borderColor: AppColors.border,
              ),
              // 2. OPEN CALCULATOR (Red)
              _buildActionButton(
                icon: Icons.calculate,
                label: 'OPEN CALCULATOR',
                onTap: onOpenCalculator,
                bgColor: AppColors.alertRed,
                textColor: Colors.white,
              ),
              // 3. LIVE UPDATE (Yellow)
              _buildActionButton(
                icon: Icons.sync,
                label: 'LIVE UPDATE',
                onTap: onLiveUpdate,
                bgColor: Colors.amber.shade800,
                textColor: Colors.white,
              ),
              // 4. CHAT (Green)
              _buildActionButton(
                icon: Icons.forum,
                label: 'CHAT',
                onTap: onOpenChat,
                bgColor: AppColors.resultGreen,
                textColor: Colors.white,
              ),
              // 5. VOIP CALL (Blue)
              _buildActionButton(
                icon: Icons.phone,
                label: 'VOIP CALL',
                onTap: onVoipCall,
                bgColor: const Color(0xFF1976D2),
                textColor: Colors.white,
              ),
              // 6. ATTENDANCE (Violet)
              _buildActionButton(
                icon: Icons.engineering,
                label: 'ATTENDANCE',
                onTap: onOpenAttendance,
                bgColor: Colors.purple.shade700,
                textColor: Colors.white,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        _buildSmallActionIcon(Icons.delete_outline, onDelete, isRed: true),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color bgColor,
    required Color textColor,
    Color? borderColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: bgColor,
          border: Border.all(color: borderColor ?? bgColor, width: 1.5),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: textColor),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: textColor,
                letterSpacing: 0.3,
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
          border: Border.all(color: isRed ? AppColors.alertRed : AppColors.border, width: 1.5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: isRed ? AppColors.alertRed : AppColors.border, size: 18),
      ),
    );
  }
}
