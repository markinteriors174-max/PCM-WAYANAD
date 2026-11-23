import 'package:flutter/material.dart';
import '../website_theme.dart';

class WebsiteWorkflow extends StatelessWidget {
  const WebsiteWorkflow({super.key});

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
              Text('WORKFLOW & PROCESS', style: WebsiteTheme.goldAccent(fontSize: 12)),
              const SizedBox(height: 8),
              Text('4 Steps to Your Premium Ceiling', style: WebsiteTheme.headingLarge(fontSize: 26)),
              const SizedBox(height: 30),
              Row(
                children: [
                  _step('1', 'Site Survey', 'Laser level measurement'),
                  _step('2', 'Design & Estimate', 'Transparent itemized rate'),
                  _step('3', 'Expert Fixing', 'Gyproc G.I. grid framework'),
                  _step('4', 'Putty & Paint', 'Flawless smooth hand-finish'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _step(String num, String title, String desc) {
    return Expanded(
      child: Column(
        children: [
          CircleAvatar(
            backgroundColor: WebsiteTheme.champagneGold,
            foregroundColor: Colors.black,
            child: Text(num, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 10),
          Text(title, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 4),
          Text(desc, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white60, fontSize: 10)),
        ],
      ),
    );
  }
}
