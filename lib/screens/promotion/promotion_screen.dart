import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_app_bar.dart';

class PromotionScreen extends StatelessWidget {
  const PromotionScreen({super.key});

  final String _appInstallUrl = 'https://pcm-wayanad.app/install';
  final String _ownerName = 'PCM WAYANAD';
  final String _ownerPlace = 'Wayanad, Kerala';
  final String _ownerPhone = '93 83 40 61 85';

  void _playClickSound() {}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 30),
        child: Column(
          children: [
            const Text('PCM Team Growth', style: TextStyle(fontSize: 10, color: AppColors.labelColor, letterSpacing: 2, fontWeight: FontWeight.bold)),
            Text('APP PROMOTION', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: AppColors.border, letterSpacing: 1)),
            const SizedBox(height: 40),
            
            Container(
              padding: const EdgeInsets.all(30),
              decoration: AppStyles.neumorphicDecoration(color: Colors.white, hasThickBorder: true),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.border, width: 3),
                    ),
                    child: QrImageView(
                      data: _appInstallUrl,
                      version: QrVersions.auto,
                      size: 200.0,
                    ),
                  ),
                  const SizedBox(height: 25),
                  const Text('SCAN TO INSTALL', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 2, color: AppColors.resultGreen)),
                  const SizedBox(height: 10),
                  const Text('Share this app with site owners, workers, and supervisors for seamless logistics management.', 
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.blueGrey, height: 1.5, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 40),
            
            // Owner Branding
            Container(
              padding: const EdgeInsets.all(20),
              decoration: AppStyles.neumorphicDecoration(color: Colors.white, hasThickBorder: true),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(color: AppColors.border, shape: BoxShape.circle),
                    child: const Icon(Icons.business, color: Colors.white),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_ownerName, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.border)),
                        Text(_ownerPlace, style: const TextStyle(fontSize: 12, color: Colors.blueGrey, fontWeight: FontWeight.bold)),
                        Text('Mob: $_ownerPhone', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.resultGreen)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 40),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  _playClickSound();
                  Share.share('Install Premium Ceiling Master App for professional project estimates and labor management: $_appInstallUrl');
                },
                icon: const Icon(Icons.share, color: Colors.white),
                label: const Text('SHARE APP LINK', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryButton,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            
            const SizedBox(height: 40),
            const Text('PREMIUM CEILING MASTER', style: TextStyle(fontSize: 10, letterSpacing: 4, color: AppColors.labelColor, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
