import 'package:flutter/material.dart';
import '../website_theme.dart';

class WebsiteWhyUs extends StatelessWidget {
  const WebsiteWhyUs({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 60),
      color: WebsiteTheme.midnightNavy,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Column(
            children: [
              Text('WHY CHOOSE PCM WAYANAD', style: WebsiteTheme.goldAccent(fontSize: 12)),
              const SizedBox(height: 8),
              Text('Craftsmanship, Integrity & On-Time Delivery', style: WebsiteTheme.headingLarge(fontSize: 26)),
              const SizedBox(height: 30),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                alignment: WrapAlignment.center,
                children: const [
                  _FeatureCard(icon: Icons.verified, title: 'Gyproc Certified', desc: '100% genuine Saint-Gobain Gyproc boards & sections'),
                  _FeatureCard(icon: Icons.speed, title: 'Fast Execution', desc: 'Completed in 3-5 days for typical 1500 sq.ft home'),
                  _FeatureCard(icon: Icons.shield, title: '10-Year Warranty', desc: 'Guaranteed sag-free, crack-resistant ceiling warranty'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String desc;

  const _FeatureCard({required this.icon, required this.title, required this.desc});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: WebsiteTheme.navyCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: WebsiteTheme.champagneGold.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: WebsiteTheme.champagneGold, size: 32),
          const SizedBox(height: 10),
          Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 6),
          Text(desc, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white60, fontSize: 11)),
        ],
      ),
    );
  }
}
