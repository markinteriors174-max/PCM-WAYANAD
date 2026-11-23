import 'package:flutter/material.dart';
import '../website_theme.dart';

class WebsiteTestimonials extends StatelessWidget {
  const WebsiteTestimonials({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 60),
      color: WebsiteTheme.navyCard,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Column(
            children: [
              Text('CLIENT REVIEWS', style: WebsiteTheme.goldAccent(fontSize: 12)),
              const SizedBox(height: 8),
              Text('Trusted By 500+ Homeowners In Wayanad', style: WebsiteTheme.headingLarge(fontSize: 26)),
              const SizedBox(height: 30),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                alignment: WrapAlignment.center,
                children: const [
                  _ReviewCard(name: 'Dr. Rahul Varma', loc: 'Kalpetta', review: 'Flawless Gyproc false ceiling in my villa. Laser levels and cove lights came out stunning!'),
                  _ReviewCard(name: 'Anil Kumar', loc: 'Sulthan Bathery', review: 'On-time delivery and clean work. Best false ceiling team in Wayanad!'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final String name;
  final String loc;
  final String review;

  const _ReviewCard({required this.name, required this.loc, required this.review});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: WebsiteTheme.midnightNavy,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: WebsiteTheme.champagneGold.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: List.generate(5, (_) => const Icon(Icons.star, color: Colors.amber, size: 16)),
          ),
          const SizedBox(height: 10),
          Text('"$review"', style: const TextStyle(color: Colors.white70, fontStyle: FontStyle.italic, fontSize: 12)),
          const SizedBox(height: 12),
          Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
          Text(loc, style: const TextStyle(color: Colors.white38, fontSize: 10)),
        ],
      ),
    );
  }
}
