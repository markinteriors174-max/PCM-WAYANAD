import 'package:flutter/material.dart';

/// Reusable Widget that overlays the user's Brand Logo & Badge
/// onto any catalog item photo or site ad banner photo ("എൻറെ ലോഗോ ആ ഫോട്ടോയിൽ വരണം").
class BrandLogoOverlayWidget extends StatelessWidget {
  final Widget child;
  final Alignment logoAlignment;
  final double logoSize;
  final String brandText;
  final bool showBadge;

  const BrandLogoOverlayWidget({
    super.key,
    required this.child,
    this.logoAlignment = Alignment.bottomRight,
    this.logoSize = 18,
    this.brandText = 'PCM WAYANAD',
    this.showBadge = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!showBadge) return child;

    return Stack(
      children: [
        child,
        Positioned.fill(
          child: Align(
            alignment: logoAlignment,
            child: Container(
              margin: const EdgeInsets.all(5),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xCC000000), Color(0xEE3E2723)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFFFD700), width: 0.8),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black45,
                    blurRadius: 4,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/pcm_logo.png',
                    width: logoSize,
                    height: logoSize,
                    errorBuilder: (_, __, ___) => Image.asset(
                      'assets/images/logo.png',
                      width: logoSize,
                      height: logoSize,
                      errorBuilder: (_, __, ___) => Image.asset(
                        'assets/logo.png',
                        width: logoSize,
                        height: logoSize,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.verified_rounded,
                          color: Color(0xFFFFD700),
                          size: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    brandText.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
