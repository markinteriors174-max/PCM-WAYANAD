import 'package:flutter/material.dart';

class ChannelBrands {
  static const List<String> brands = [
    'Gyproc',
    'Expert',
    'JK',
    'Two Steel',
    'Jindal',
    'TATA Steel',
    'Boral',
    'Knauf',
    'Gypstar',
    'Gypdec',
    'Superfinish',
    'Frame Rock',
    'Armstrong',
    'Dexune',
    'Everest',
  ];

  static const Map<String, List<String>> ceilingChannelMap = {
    'Gypsum Board': brands,
    'PVC Board': brands,
    'Grid Ceiling': brands,
    'Classic Arch': brands,
    'Insu Board (Insulation Board)': brands,
    'Fiber Cement Board': brands,
    'Mineral Fiber Board': brands,
    'Wooden Ceiling Panels': brands,
    'Metal Ceiling Panels': brands,
    'Louvers (Decorative Panels)': brands,
    'Plywood': brands,
    'WPC (Wood Plastic Composite)': brands,
    'Other': brands,
  };

  static List<String> getChannelsForCeiling(String? ceilingType) {
    if (ceilingType == null) return brands;
    final normalized = ceilingType.trim();
    return ceilingChannelMap[normalized] ?? brands;
  }

  static const List<Color> palette = [
    Color(0xFF2563EB), // Blue
    Color(0xFF16A34A), // Green
    Color(0xFFD97706), // Amber
    Color(0xFF9333EA), // Purple
    Color(0xFFDC2626), // Red
    Color(0xFF0D9488), // Teal
    Color(0xFF4F46E5), // Indigo
    Color(0xFFEA580C), // Orange
    Color(0xFFDB2777), // Pink
    Color(0xFF65A30D), // Lime
    Color(0xFF0891B2), // Cyan
  ];

  static Color getBrandColor(String brand, [int? index]) {
    if (index != null && index >= 0) {
      return palette[index % palette.length];
    }
    final hash = brand.codeUnits.fold(0, (prev, el) => prev + el);
    return palette[hash % palette.length];
  }
}
