import 'package:flutter/material.dart';

class WebsiteGallery extends StatelessWidget {
  const WebsiteGallery({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Project Gallery',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          const Text('Explore our craftsmanship and completed ceiling designs.'),
        ],
      ),
    );
  }
}
