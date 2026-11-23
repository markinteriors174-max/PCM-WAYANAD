import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../website_theme.dart';

class MobileContactBar extends StatelessWidget {
  final VoidCallback onEnquiryTap;

  const MobileContactBar({super.key, required this.onEnquiryTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: WebsiteTheme.midnightNavy,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () async {
                  final uri = Uri.parse('tel:9383406185');
                  if (await canLaunchUrl(uri)) await launchUrl(uri);
                },
                icon: const Icon(Icons.phone, size: 16),
                label: const Text('CALL NOW', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: WebsiteTheme.champagneGold,
                  foregroundColor: Colors.black,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () async {
                  final uri = Uri.parse('https://wa.me/919383406185');
                  if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
                },
                icon: const Icon(Icons.chat, size: 16),
                label: const Text('WHATSAPP', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: WebsiteTheme.whatsappGreen,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
