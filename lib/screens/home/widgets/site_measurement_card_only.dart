// PCM Wayanad - Site Measurement Card Only
import 'package:flutter/material.dart';
import '../../calculator/site_measurement_screen.dart';

class SiteMeasurementCardOnly extends StatelessWidget {
  const SiteMeasurementCardOnly({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SiteMeasurementScreen()),
          );
        },
        borderRadius: BorderRadius.circular(16.0),
        child: Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Colors.amber[400],
            borderRadius: BorderRadius.circular(16.0),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.assignment,
                  color: Colors.brown,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'സൈറ്റ് മെഷർമെന്റ്',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.brown,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'ഓട്ടോ GPS ലൊക്കേഷനും ഫാസ്റ്റ് അളവെടുപ്പും',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.brown,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                color: Colors.brown,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

