import 'package:flutter/material.dart';
import '../website_theme.dart';

class WebsiteBeforeAfter extends StatelessWidget {
  const WebsiteBeforeAfter({super.key});

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
              Text('TRANSFORMATION SHOWCASE', style: WebsiteTheme.goldAccent(fontSize: 12)),
              const SizedBox(height: 8),
              Text('Raw Concrete To Luxury False Ceiling Finish', style: WebsiteTheme.headingLarge(fontSize: 26)),
              const SizedBox(height: 30),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: WebsiteTheme.navyCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: WebsiteTheme.champagneGold.withValues(alpha: 0.4)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: const [
                        Expanded(
                          child: Column(
                            children: [
                              Icon(Icons.construction, color: Colors.orangeAccent, size: 36),
                              SizedBox(height: 8),
                              Text('BEFORE', style: TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold)),
                              SizedBox(height: 4),
                              Text('Raw concrete slab with exposed wiring', textAlign: TextAlign.center, style: TextStyle(color: Colors.white70, fontSize: 11)),
                            ],
                          ),
                        ),
                        Icon(Icons.arrow_forward, color: WebsiteTheme.champagneGold, size: 30),
                        Expanded(
                          child: Column(
                            children: [
                              Icon(Icons.auto_awesome, color: Color(0xFF10B981), size: 36),
                              SizedBox(height: 8),
                              Text('AFTER', style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold)),
                              SizedBox(height: 4),
                              Text('Seamless Gyproc ceiling with warm LED cove', textAlign: TextAlign.center, style: TextStyle(color: Colors.white70, fontSize: 11)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
