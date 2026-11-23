import 'package:flutter/material.dart';

class WebsiteCalculator extends StatelessWidget {
  const WebsiteCalculator({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Cost Estimator',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          const Text('Estimate your false ceiling costs instantly.'),
        ],
      ),
    );
  }
}
