import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../clients/clients_screen.dart';
import '../../labor/labor_management_screen.dart';

class HomePromotionSection extends StatelessWidget {
  const HomePromotionSection({super.key});

  Widget _buildQuickCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: AppStyles.neumorphicDecoration(color: Colors.white, hasThickBorder: true),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 10, color: AppColors.border, letterSpacing: 0.5),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.black45, fontSize: 8, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildQuickCard(
            context: context,
            title: 'CLIENTS HUB',
            subtitle: 'Registry & GPS Pin',
            icon: Icons.people_alt,
            color: AppColors.border,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ClientsScreen()),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildQuickCard(
            context: context,
            title: 'WORKERS HUB',
            subtitle: 'Team & Attendance',
            icon: Icons.engineering,
            color: AppColors.resultGreen,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LaborManagementScreen()),
            ),
          ),
        ),
      ],
    );
  }
}
