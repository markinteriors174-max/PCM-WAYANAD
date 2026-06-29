import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';

class QuickAddCeilingToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const QuickAddCeilingToggle({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: AppStyles.neumorphicDecoration(
        color: AppColors.pureWhite,
        hasThickBorder: false,
        borderRadius: 10,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Row(
            children: [
              Icon(Icons.layers, color: AppColors.primaryButton, size: 20),
              SizedBox(width: 8),
              Text(
                'CEILING DESIGN',
                style: TextStyle(
                  color: AppColors.labelColor,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          Switch.adaptive(
            activeThumbColor: AppColors.primaryButton,
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
