import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
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
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: AppColors.border, letterSpacing: 0.5),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(color: Colors.black45, fontSize: 8, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  void _showOnboardingQrDialog(BuildContext context) async {
    final GlobalKey qrKey = GlobalKey();
    const activeOnboardingLink = 'https://pcm-wayanad-portal.surge.sh/';

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.background,
          shape: RoundedRectangleBorder(
            side: const BorderSide(color: AppColors.border, width: 2),
            borderRadius: BorderRadius.circular(15),
          ),
          title: const Text(
            'Client Onboarding QR',
            style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.border),
            textAlign: TextAlign.center,
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Have prospects scan this QR code to view premium designs, calculate estimations, and register their site directly on our web portal.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, color: Colors.black54, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                RepaintBoundary(
                  key: qrKey,
                  child: Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: QrImageView(
                      data: activeOnboardingLink,
                      version: QrVersions.auto,
                      size: 200.0,
                      gapless: false,
                      embeddedImage: const AssetImage('assets/images/logo.png'),
                      embeddedImageStyle: const QrEmbeddedImageStyle(
                        size: Size(40, 40),
                      ),
                      eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: AppColors.border),
                      dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: AppColors.border),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryButton,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        icon: const Icon(Icons.share, size: 16),
                        label: const Text('SHARE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900)),
                        onPressed: () async {
                          try {
                            RenderRepaintBoundary? boundary = qrKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
                            if (boundary == null) {
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                const SnackBar(content: Text('Could not generate shareable image')),
                              );
                              return;
                            }
                            ui.Image image = await boundary.toImage(pixelRatio: 3.0);
                            ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
                            if (byteData == null) return;
                            Uint8List pngBytes = byteData.buffer.asUint8List();

                            final tempDir = await getTemporaryDirectory();
                            final file = await File('${tempDir.path}/client_onboarding_qr.png').create();
                            await file.writeAsBytes(pngBytes);

                            await Share.shareXFiles(
                              [XFile(file.path)],
                              text: 'Scan this QR code to register as a client and connect with me!\nLink: $activeOnboardingLink',
                            );
                          } catch (e) {
                            debugPrint('Error sharing QR Code: $e');
                            if (ctx.mounted) {
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                SnackBar(content: Text('Error sharing QR: $e')),
                              );
                            }
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.border,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        icon: const Icon(Icons.copy, size: 16),
                        label: const Text('COPY URL', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900)),
                        onPressed: () {
                          Clipboard.setData(const ClipboardData(text: activeOnboardingLink));
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            const SnackBar(content: Text('Portal link copied!')),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('CLOSE', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.border)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
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
        ),
        const SizedBox(height: 15),
        Container(
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
                child: const Icon(Icons.qr_code_2, color: AppColors.border, size: 30),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'PCM PROJECT PORTAL QR',
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: AppColors.border, letterSpacing: 0.5),
                    ),
                    Text(
                      'Common QR for client onboarding & site registry',
                      style: TextStyle(color: Colors.black45, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.border,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                onPressed: () async {
                  const url = 'https://pcm-wayanad-portal.surge.sh/';
                  if (await canLaunchUrl(Uri.parse(url))) {
                    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                  } else {
                    if (context.mounted) {
                      _showOnboardingQrDialog(context);
                    }
                  }
                },
                onLongPress: () => _showOnboardingQrDialog(context),
                child: const Text('OPEN QR', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
