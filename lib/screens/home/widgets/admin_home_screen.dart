import 'package:flutter/material.dart';
import '../../../services/auth_service.dart';
import '../../../theme/app_theme.dart';
import 'home_screen_admin_hub.dart';
import 'site_measurement_card_only.dart';
import 'home_promotion_section.dart';
import 'home_material_list_section.dart';
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
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            HomeScreenAdminHub(),
            SiteMeasurementCardOnly(),
            SizedBox(height: 15),
            HomePromotionSection(),
            SizedBox(height: 25),
            HomeMaterialListSection(),
          ],
        ),
      ),
    );
  }
}

