import 'package:flutter/material.dart';

class CeilingBoardBrands {
  static const List<String> brands = [
    'Saint-Gobain Gyproc (Regular & MR Green Board)',
    'USG Boral / Knauf',
    'SCG Elephant',
    'Ramco Hilux',
    'Visaka V-Board',
    'Everest',
    'Birla Aerocon',
    'Shera',
    'Bison',
    'Armstrong',
    'KJ',
    'More',
  ];

  static const Map<String, List<String>> ceilingBoardMap = {
    'Gypsum Board': [
      'Saint-Gobain Gyproc (Regular & MR Green Board)',
      'USG Boral / Knauf',
      'SCG Elephant',
      'Ramco Hilux',
      'Visaka V-Board',
      'Everest',
      'Birla Aerocon',
      'Shera',
      'Bison',
      'Armstrong',
      'KJ',
      'More',
    ],
    'PVC Board': [
      'Premier PVC Ceiling Board',
      'Supreme',
      'Finolex',
      'Astral',
      'Sintex',
      'KJ',
      'More',
    ],
    'Grid Ceiling': [
      'Armstrong Mineral Fiber',
      'Saint-Gobain Gyproc (Grid Tiles)',
      'USG Boral / Knauf',
      'Ramco Hilux',
      'KJ',
      'More',
    ],
    'Classic Arch': [
      'Saint-Gobain Gyproc (Regular & Flex/Arch)',
      'USG Boral / Knauf',
      'SCG Elephant',
      'KJ',
      'More',
    ],
    'Insu Board (Insulation Board)': [
      'Saint-Gobain Insulation Board',
      'Armstrong',
      'Ramco Hilux',
      'Birla Aerocon',
      'KJ',
      'More',
    ],
    'Fiber Cement Board': [
      'Visaka V-Board',
      'Everest',
      'Birla Aerocon',
      'Shera',
      'Bison Cement Bonded Panel',
      'Ramco Hilux',
      'KJ',
      'More',
    ],
    'Mineral Fiber Board': [
      'Armstrong Mineral Fiber',
      'Saint-Gobain',
      'USG Boral / Knauf',
      'KJ',
      'More',
    ],
    'Wooden Ceiling Panels': [
      'Thomson Multiwood',
      'CenturyPly',
      'Greenply',
      'Action Tesa',
      'Shera Wood-Grain',
      'KJ',
      'More',
    ],
    'Metal Ceiling Panels': [
      'Armstrong Metal Ceiling',
      'Hunter Douglas',
      'Saint-Gobain Metal',
      'Jindal Metal Panels',
      'KJ',
      'More',
    ],
    'Louvers (Decorative Panels)': [
      'WPC / Charcoal Louvers',
      'Thomson Multiwood',
      'Saint-Gobain',
      'Action Tesa',
      'KJ',
      'More',
    ],
    'Plywood': [
      'CenturyPly',
      'Greenply',
      'Kitply',
      'Austin Plywood',
      'Thomson',
      'KJ',
      'More',
    ],
    'WPC (Wood Plastic Composite)': [
      'CenturyPly WPC',
      'Greenply WPC',
      'Thomson WPC',
      'Alstone WPC',
      'KJ',
      'More',
    ],
    'Other': [
      'KJ',
      'More',
    ],
  };

  static List<String> getBrandsForCeiling(String? ceilingType) {
    if (ceilingType == null) return ceilingBoardMap['Gypsum Board']!;
    final normalized = ceilingType.trim();
    return ceilingBoardMap[normalized] ?? ceilingBoardMap['Gypsum Board']!;
  }

  static const List<Color> palette = [
    Color(0xFF16A34A), // Green
    Color(0xFF2563EB), // Blue
    Color(0xFFD97706), // Amber
    Color(0xFF9333EA), // Purple
    Color(0xFFDC2626), // Red
    Color(0xFF0D9488), // Teal
    Color(0xFF4F46E5), // Indigo
    Color(0xFFEA580C), // Orange
    Color(0xFFDB2777), // Pink
    Color(0xFF65A30D), // Lime
    Color(0xFF0891B2), // Cyan
    Color(0xFF7C3AED), // Violet
  ];

  static Color getBrandColor(String brand, [int? index]) {
    if (index != null && index >= 0) {
      return palette[index % palette.length];
    }
    final hash = brand.codeUnits.fold(0, (prev, el) => prev + el);
    return palette[hash % palette.length];
  }
}
