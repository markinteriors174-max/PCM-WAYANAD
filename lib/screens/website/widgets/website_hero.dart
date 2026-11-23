import 'package:flutter/material.dart';
import '../website_theme.dart';

class WebsiteHero extends StatelessWidget {
  final String? headline;
  final VoidCallback onGetEstimate;
  final VoidCallback? onExploreGallery;
  final VoidCallback? onViewProjects;

  const WebsiteHero({
    super.key,
    this.headline,
    required this.onGetEstimate,
    this.onExploreGallery,
    this.onViewProjects,
  });

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 60 : 20,
        vertical: isDesktop ? 80 : 40,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [WebsiteTheme.midnightNavy, Color(0xFF1E293B)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: WebsiteTheme.champagneGold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: WebsiteTheme.champagneGold),
                ),
                child: Text(
                  'WAYANAD\'S NO.1 FALSE CEILING CONTRACTOR',
                  style: WebsiteTheme.goldAccent(fontSize: 12, weight: FontWeight.w900),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                headline ?? 'Transform Your Home With Modern Gypsum False Ceilings',
                textAlign: TextAlign.center,
                style: WebsiteTheme.headingLarge(fontSize: isDesktop ? 44 : 28),
              ),
              const SizedBox(height: 16),
              Text(
                'Saint-Gobain Gyproc certified installation, precision laser leveling, and indirect warm LED cove lighting built to perfection.',
                textAlign: TextAlign.center,
                style: WebsiteTheme.bodyText(fontSize: isDesktop ? 16 : 14),
              ),
              const SizedBox(height: 32),
              Wrap(
                spacing: 16,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: onGetEstimate,
                    icon: const Icon(Icons.calculate, size: 20),
                    label: const Text('GET FREE ESTIMATE', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: WebsiteTheme.champagneGold,
                      foregroundColor: WebsiteTheme.midnightNavy,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: onExploreGallery ?? onViewProjects,
                    icon: const Icon(Icons.photo_library, size: 20, color: WebsiteTheme.champagneGold),
                    label: const Text('EXPLORE DESIGNS', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: WebsiteTheme.champagneGold, width: 1.5),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
