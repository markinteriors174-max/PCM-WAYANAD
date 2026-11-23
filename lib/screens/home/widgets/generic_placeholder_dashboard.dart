import 'package:flutter/material.dart';
import '../../../services/auth_service.dart';
import '../../../theme/app_theme.dart';

class GenericPlaceholderDashboard extends StatelessWidget {
  final String title;
  const GenericPlaceholderDashboard({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.handyman, size: 80, color: AppColors.border),
            const SizedBox(height: 25),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, color: AppColors.border)),
            const SizedBox(height: 12),
            const Text('Module integration in progress...', style: TextStyle(color: Colors.black45, fontWeight: FontWeight.bold)),
            const SizedBox(height: 35),
            GestureDetector(
              onTap: () => AuthService.instance.logout(),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                decoration: AppStyles.neumorphicDecoration(color: AppColors.border, borderRadius: 10),
                child: const Text('BACK TO LOGIN', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
