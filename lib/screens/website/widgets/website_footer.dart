import 'package:flutter/material.dart';

class WebsiteFooter extends StatelessWidget {
  final void Function(String) onNavItemSelected;

  const WebsiteFooter({super.key, required this.onNavItemSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
      color: Colors.grey.shade900,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            '© PCM Wayanad - Architectural Gypsum & Ceiling Specialists',
            style: TextStyle(color: Colors.white70),
          ),
          TextButton(
            onPressed: () => onNavItemSelected('contact'),
            child: const Text('Contact Support', style: TextStyle(color: Colors.amber)),
          ),
        ],
      ),
    );
  }
}
