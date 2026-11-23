import 'package:flutter/material.dart';

class ChannelBrands {
  static const List<String> brands = [
    'Saint-Gobain Gypframe / Gypsteel',
    'USG Boral / Knauf',
    'Tata Steelium',
    'Jindal',
    'APL Apollo',
    'SCG Elephant',
    'Visaka',
    'Kamdhenu',
    'Gyp Star',
    '2-Street',
    'Expert JK',
    'KJ',
    'More',
  ];

  static const Map<String, List<String>> ceilingChannelMap = {
    'Gypsum Board': [
      'Saint-Gobain Gypframe / Gypsteel',
      'USG Boral / Knauf',
      'Tata Steelium',
      'Jindal',
      'APL Apollo',
      'SCG Elephant',
      'Visaka',
      'Kamdhenu',
      'Gyp Star',
      '2-Street',
      'Expert JK',
      'KJ',
      'More',
    ],
    'PVC Board': [
      'PVC Battens / Framing',
      'Jindal',
      'APL Apollo',
      'Tata Steelium',
      '2-Street',
      'Expert JK',
      'KJ',
      'More',
    ],
    'Grid Ceiling': [
      'Armstrong Grid System',
      'Saint-Gobain Grid System',
      'USG Boral / Knauf Grid',
      'Tata Steelium',
      'Jindal',
      '2-Street',
      'Expert JK',
      'KJ',
      'More',
    ],
    'Classic Arch': [
      'Saint-Gobain Gypframe / Gypsteel',
      'USG Boral / Knauf',
      'Tata Steelium',
      'Jindal',
      'APL Apollo',
      '2-Street',
      'Expert JK',
      'KJ',
      'More',
    ],
    'Insu Board (Insulation Board)': [
      'Saint-Gobain Gypframe / Gypsteel',
      'Tata Steelium',
      'Jindal',
      'APL Apollo',
      'Kamdhenu',
      '2-Street',
      'Expert JK',
      'KJ',
      'More',
    ],
    'Fiber Cement Board': [
      'Tata Steelium',
      'Jindal',
      'APL Apollo',
      'Visaka',
      'Kamdhenu',
      'Saint-Gobain Gypframe / Gypsteel',
      '2-Street',
      'Expert JK',
      'KJ',
      'More',
    ],
    'Mineral Fiber Board': [
      'Armstrong Grid / Framing',
      'Saint-Gobain Gypframe / Gypsteel',
      'Tata Steelium',
      'Jindal',
      '2-Street',
      'Expert JK',
      'KJ',
      'More',
    ],
    'Wooden Ceiling Panels': [
      'Treated Timber Battens',
      'Jindal',
      'APL Apollo',
      'Tata Steelium',
      '2-Street',
      'Expert JK',
      'KJ',
      'More',
    ],
    'Metal Ceiling Panels': [
      'Armstrong Suspension System',
      'Tata Steelium',
      'Jindal',
      'APL Apollo',
      'Saint-Gobain Gypframe / Gypsteel',
      '2-Street',
      'Expert JK',
      'KJ',
      'More',
    ],
    'Louvers (Decorative Panels)': [
      'Aluminum / GI Concealed Channels',
      'Jindal',
      'APL Apollo',
      'Tata Steelium',
      '2-Street',
      'Expert JK',
      'KJ',
      'More',
    ],
    'Plywood': [
      'Timber / Batten Framing',
      'Jindal',
      'APL Apollo',
      'Tata Steelium',
      '2-Street',
      'Expert JK',
      'KJ',
      'More',
    ],
    'WPC (Wood Plastic Composite)': [
      'GI / Aluminum Sub-frame',
      'Jindal',
      'APL Apollo',
      'Tata Steelium',
      '2-Street',
      'Expert JK',
      'KJ',
      'More',
    ],
    'Other': [
      '2-Street',
      'Expert JK',
      'KJ',
      'More',
    ],
  };

  static List<String> getChannelsForCeiling(String? ceilingType) {
    if (ceilingType == null) return ceilingChannelMap['Gypsum Board']!;
    final normalized = ceilingType.trim();
    return ceilingChannelMap[normalized] ?? ceilingChannelMap['Gypsum Board']!;
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
