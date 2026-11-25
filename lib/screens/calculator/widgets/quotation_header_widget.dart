import 'package:flutter/material.dart';
import 'sync_status_badge.dart';

/// PCM Web Header Widget (`pcm-web-header`)
/// Displays PCM WAYANAD branding with logo, company name, subtitle,
/// phone badge, and quick action color buttons in a 2-row layout.
class QuotationHeaderWidget extends StatelessWidget {
  final String companyName;
  final String subtitle;
  final String phoneNumber;
  final VoidCallback? onGreenTap;
  final VoidCallback? onRedTap;
  final VoidCallback? onYellowTap;

  const QuotationHeaderWidget({
    super.key,
    this.companyName = 'PCM WAYANAD',
    this.subtitle = 'Architectural & Interiors',
    this.phoneNumber = '9383406185',
    this.onGreenTap,
    this.onRedTap,
    this.onYellowTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xF50F172A), // rgba(15, 23, 42, 0.95)
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Logo & Company Name (WAYANAD മുറിഞ്ഞുപോകാതെ പൂർണ്ണമായി കാണാൻ)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Image.asset(
                      'assets/images/logo.png',
                      height: 32,
                      width: 32,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.architecture,
                        color: Colors.amber,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            companyName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                              height: 1.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.visible,
                          ),
                          Text(
                            subtitle,
                            style: const TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 10,
                              height: 1.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.visible,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Line Separator
          Container(
            width: double.infinity,
            height: 1,
            color: Colors.white.withValues(alpha: 0.15),
          ),

          const SizedBox(height: 8),

          // Bottom Row: Phone Badge & Action Color Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Phone Badge & Sync Status Badge
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          '📞',
                          style: TextStyle(fontSize: 11, color: Color(0xFF38BDF8)),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          phoneNumber,
                          style: const TextStyle(
                            color: Color(0xFFF8FAFC),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const SyncStatusBadge(),
                ],
              ),

              // Action Buttons
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: onGreenTap,
                    child: Container(
                      width: 26,
                      height: 26,
                      decoration: const BoxDecoration(
                        color: Color(0xFF22C55E),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: onRedTap,
                    child: Container(
                      width: 26,
                      height: 26,
                      decoration: const BoxDecoration(
                        color: Color(0xFFEF4444),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: onYellowTap,
                    child: Container(
                      width: 26,
                      height: 26,
                      decoration: const BoxDecoration(
                        color: Color(0xFFEAB308),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}


