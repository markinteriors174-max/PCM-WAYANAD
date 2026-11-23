import 'package:flutter/material.dart';
import '../../../../models/client_model.dart';
import '../../../../theme/app_theme.dart';

class ProjectHubHeader extends StatelessWidget {
  final Client client;
  final String currentStage;
  final bool isAdmin;
  final bool isUpdatingStage;
  final Function(String?) onStageChanged;
  final VoidCallback onCall;
  final VoidCallback onWhatsApp;
  final VoidCallback onMaps;

  const ProjectHubHeader({
    super.key,
    required this.client,
    required this.currentStage,
    required this.isAdmin,
    required this.isUpdatingStage,
    required this.onStageChanged,
    required this.onCall,
    required this.onWhatsApp,
    required this.onMaps,
  });

  @override
  Widget build(BuildContext context) {
    final hasPin = client.latitude != null && client.longitude != null;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(14),
      decoration: AppStyles.neumorphicDecoration(color: Colors.white, hasThickBorder: true),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.border.withValues(alpha: 0.1),
                backgroundImage: client.clientSelfie.isNotEmpty
                    ? NetworkImage(client.clientSelfie)
                    : null,
                child: client.clientSelfie.isEmpty
                    ? const Icon(Icons.person, color: AppColors.border)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      client.clientName.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: AppColors.border,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'site: ${client.unitNumber.toUpperCase()}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: AppColors.premiumGold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'PROJECT STATUS: ${currentStage.toUpperCase()}',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: Colors.blueGrey.shade700,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: hasPin ? AppColors.resultGreen : AppColors.alertRed,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  hasPin ? 'GPS READY' : 'NO GPS PIN',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 8,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, thickness: 1, color: Colors.black12),
          const SizedBox(height: 12),
          
          // Project Stage Dropdown Row
          Row(
            children: [
              const Icon(Icons.playlist_add_check, size: 20, color: AppColors.border),
              const SizedBox(width: 8),
              const Text(
                'PROJECT STAGE:',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 11,
                  color: AppColors.labelColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  height: 36,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: AppColors.background.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border.withValues(alpha: 0.3)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: const ['Planning', 'Framing', 'Boarding', 'Finishing', 'Painting', 'Handover'].contains(currentStage) ? currentStage : 'Planning',
                      icon: const Icon(Icons.arrow_drop_down, color: AppColors.border),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: AppColors.border,
                      ),
                      items: const ['Planning', 'Framing', 'Boarding', 'Finishing', 'Painting', 'Handover']
                          .map((stage) => DropdownMenuItem(
                                value: stage,
                                child: Text(stage),
                              ))
                          .toList(),
                      onChanged: (isAdmin && !isUpdatingStage) ? onStageChanged : null,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, thickness: 1, color: Colors.black12),
          const SizedBox(height: 12),
          
          // Toolbar actions
          Row(
            children: [
              Expanded(
                child: _buildToolbarButton(
                  icon: Icons.phone_in_talk,
                  label: 'CALL',
                  color: AppColors.primaryButton,
                  onTap: onCall,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildToolbarButton(
                  icon: Icons.chat,
                  label: 'WHATSAPP',
                  color: AppColors.resultGreen,
                  onTap: onWhatsApp,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildToolbarButton(
                  icon: Icons.map,
                  label: 'MAPS',
                  color: AppColors.border,
                  onTap: onMaps,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildToolbarButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 1,
      ),
      onPressed: onTap,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 0.5),
          ),
        ],
      ),
    );
  }
}
