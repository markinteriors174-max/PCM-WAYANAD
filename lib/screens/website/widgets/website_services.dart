import 'package:flutter/material.dart';
import '../website_theme.dart';

class WebsiteServices extends StatelessWidget {
  final VoidCallback? onConsultTap;
  const WebsiteServices({super.key, this.onConsultTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 60),
      color: WebsiteTheme.navyCard,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            children: [
              Text('OUR SPECIALIZED SOLUTIONS', style: WebsiteTheme.goldAccent(fontSize: 12)),
              const SizedBox(height: 8),
              Text('Expert Gypsum & Architectural Ceiling Works', style: WebsiteTheme.headingLarge(fontSize: 28)),
              const SizedBox(height: 40),
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 750;
                  final cards = [
                    _serviceCard('Gypsum False Ceiling', 'Saint-Gobain Gyproc plain and stepped cove designs for living rooms and bedrooms.', Icons.grid_4x4),
                    _serviceCard('LED Cove Lighting', 'Warm white indirect LED channel profiles and spot light cutouts for ambient glow.', Icons.lightbulb_outline),
                    _serviceCard('PVC & WPC Wall Paneling', 'Waterproof interior wall and exterior balcony ceiling louvers and fluted panels.', Icons.view_quilt),
                    _serviceCard('Commercial Grid Ceilings', '60x60 acoustic ceiling tiles and T-grid framework for offices and auditoriums.', Icons.business),
                  ];

                  if (isWide) {
                    return Wrap(
                      spacing: 20,
                      runSpacing: 20,
                      children: cards.map((c) => SizedBox(width: (constraints.maxWidth - 20) / 2, child: c)).toList(),
                    );
                  }
                  return Column(
                    children: cards.map((c) => Padding(padding: const EdgeInsets.only(bottom: 16), child: c)).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _serviceCard(String title, String desc, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: WebsiteTheme.midnightNavy,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: WebsiteTheme.champagneGold.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: WebsiteTheme.champagneGold.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: WebsiteTheme.champagneGold, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: WebsiteTheme.headingMedium(fontSize: 18)),
                const SizedBox(height: 6),
                Text(desc, style: WebsiteTheme.bodyText(fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
