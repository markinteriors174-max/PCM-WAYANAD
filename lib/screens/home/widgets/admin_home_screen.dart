import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../services/auth_service.dart';
import '../../../theme/app_theme.dart';
import 'home_promotion_section.dart';
import '../pcm_ai_designer_screen.dart';
import 'home_material_list_section.dart';
import 'quick_expenses_widget.dart';
import '../../main_navigation.dart';

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => RoleNavigationShell.scaffoldKey.currentState?.openDrawer(),
        ),
        title: const Text(
          'ADMIN DASHBOARD',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.border,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => AuthService.instance.logout(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const HomePromotionSection(),
            const SizedBox(height: 30),
            const QuickExpensesWidget(),
            const SizedBox(height: 30),
            const PortalQrCodeCard(),
            const SizedBox(height: 30),
            const PcmAiDesignerLaunchCard(),
            const SizedBox(height: 30),
            const HomeMaterialListSection(),
          ],
        ),
      ),
    );
  }
}

class PortalQrCodeCard extends StatelessWidget {
  const PortalQrCodeCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: AppStyles.neumorphicDecoration(color: Colors.white),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.border.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.qr_code_2, color: AppColors.border, size: 24),
              ),
              const SizedBox(width: 15),
              const Text(
                'PCM WEB PORTAL ACCESS',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                  color: AppColors.border,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 25),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: AppColors.border.withValues(alpha: 0.15), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: QrImageView(
              data: 'HTTPS://PCM-WAYANAD-PORTAL.SURGE.SH/',
              version: QrVersions.auto,
              size: 180.0,
              gapless: false,
              eyeStyle: const QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: AppColors.border,
              ),
              dataModuleStyle: const QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: AppColors.border,
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'SCAN TO OPEN WEB PORTAL',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: AppColors.border, letterSpacing: 0.5),
          ),
          const SizedBox(height: 8),
          const Text(
            'Scan this code with any mobile camera to instantly access the PCM Portal for advanced management and desktop features.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 10, color: Colors.black54, height: 1.4, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class PcmAiDesignerLaunchCard extends StatelessWidget {
  const PcmAiDesignerLaunchCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: AppStyles.neumorphicDecoration(color: Colors.white, hasThickBorder: true),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.border.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.architecture, color: AppColors.border, size: 30),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'PCM AI DESIGNER Workspace',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: AppColors.border, letterSpacing: 0.5),
                ),
                SizedBox(height: 4),
                Text(
                  'Access the full-screen 2D/3D interactive ceiling CAD visualizer. Design custom gypsum steps, calculate real-time framing materials, and export dispatch details.',
                  style: TextStyle(color: Colors.black45, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(width: 15),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.border,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PcmAiDesignerScreen()),
              );
            },
            child: const Text('LAUNCH', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
          ),
        ],
      ),
    );
  }
}
