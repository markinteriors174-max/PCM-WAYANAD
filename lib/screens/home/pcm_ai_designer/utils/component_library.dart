import 'package:flutter/material.dart';

class ComponentItem {
  final String id;
  final String name;
  final String category; // 'Ceiling & Linings', 'Wall Decor', 'Lighting', 'Electrical & Cooling', 'Furniture 3D'
  final String type;     // Maps to CeilingObject type
  final String shapeFamily; // 'box', 'circle', 'oval', 'line', 'arc', 'louver', 'sticker', 'fan', 'ac', 'bed', 'sofa', 'table', 'wardrobe', 'decor'
  final double defaultWidth;
  final double defaultHeight;
  final Color color;
  final IconData icon;
  final String description;
  final String title;
  final String imageUrl;

  ComponentItem({
    required this.id,
    required this.name,
    required this.category,
    required this.type,
    required this.shapeFamily,
    required this.defaultWidth,
    required this.defaultHeight,
    required this.color,
    required this.icon,
    required this.description,
    String? title,
    String? imageUrl,
  }) : title = title ?? name,
       imageUrl = imageUrl ?? _getDynamicImage(id);

  static String _getDynamicImage(String id) {
    final List<String> imgs = [
      'assets/images/workflow_design.png',
      'assets/images/workflow_pcm.png',
      'assets/images/workflow_materials.png',
      'assets/images/workflow_completion.png',
      'assets/images/logo.png',
    ];
    int hash = 0;
    for (int i = 0; i < id.length; i++) {
      hash += id.codeUnitAt(i);
    }
    return imgs[hash % imgs.length];
  }
}

// 200+ Professional Component Library List
final List<ComponentItem> componentLibrary = _buildComponentLibrary();

List<ComponentItem> _buildComponentLibrary() {
  final List<ComponentItem> list = [];

  // ==========================================
  // CATEGORY 1: CEILING & LININGS (30 items)
  // ==========================================
  final List<Map<String, dynamic>> ceilingItems = [
    {'name': 'Standard Rectangular Gypsum Box', 'type': 'gypsum_rect', 'shape': 'box', 'w': 4.0, 'h': 4.0, 'icon': Icons.crop_square, 'desc': 'Standard drop ceiling steps rectangular profile.'},
    {'name': 'Circular Step Panel', 'type': 'gypsum_circle', 'shape': 'circle', 'w': 5.0, 'h': 5.0, 'icon': Icons.radio_button_unchecked, 'desc': 'Circular step down gypsum ceiling panel.'},
    {'name': 'Oval Gypsum Centerpiece', 'type': 'gypsum_oval', 'shape': 'oval', 'w': 6.0, 'h': 4.0, 'icon': Icons.all_out, 'desc': 'Double elliptical centerpiece ceiling element.'},
    {'name': 'Bending Arch Step Panel', 'type': 'gypsum_arc', 'shape': 'arc', 'w': 6.0, 'h': 1.0, 'icon': Icons.gesture, 'desc': 'Bezier curved corner step panel.'},
    {'name': 'Architectural Ceiling Grid', 'type': 'ceiling_grid', 'shape': 'box', 'w': 8.0, 'h': 8.0, 'icon': Icons.grid_on, 'desc': 'Interlocking ceiling tiles layout grid.'},
    {'name': 'Room Boundary Profile', 'type': 'border_profile', 'shape': 'box', 'w': 8.0, 'h': 8.0, 'icon': Icons.border_outer, 'desc': 'Crown ceiling perimeter border profiles.'},
    {'name': 'Straight Room Partition Wall', 'type': 'wall_line', 'shape': 'line', 'w': 8.0, 'h': 0.3, 'icon': Icons.linear_scale, 'desc': 'CAD straight drywall partition line.'},
    {'name': 'Architectural Hanger Channel', 'type': 'main_channel', 'shape': 'line', 'w': 10.0, 'h': 0.2, 'icon': Icons.horizontal_rule, 'desc': 'Steel main carrier channels blueprint line.'},
    {'name': 'Steel Cross Tee Channel', 'type': 'cross_channel', 'shape': 'line', 'w': 6.0, 'h': 0.2, 'icon': Icons.add, 'desc': 'Secondary support furring steel channel tee.'},
    {'name': 'Perimeter Lighting Cove', 'type': 'perimeter_cove', 'shape': 'box', 'w': 12.0, 'h': 10.0, 'icon': Icons.line_weight, 'desc': 'Recessed cove lighting ledge perimeter.'},
  ];

  for (int i = 0; i < ceilingItems.length; i++) {
    final item = ceilingItems[i];
    list.add(ComponentItem(
      id: 'ceil_${item['type']}_$i',
      name: item['name'],
      category: 'Ceiling & Linings',
      type: item['type'],
      shapeFamily: item['shape'],
      defaultWidth: item['w'],
      defaultHeight: item['h'],
      color: const Color(0xFFECEFF1),
      icon: item['icon'],
      description: item['desc'],
    ));
  }

  // Variations for Ceiling & Linings to complete 30 components
  final List<String> woodVariations = ['Teak', 'Mahogany', 'Walnut', 'Cherry', 'Oak', 'Pine', 'Cedar', 'Maple', 'Ash', 'Birch'];
  for (int i = 0; i < woodVariations.length; i++) {
    list.add(ComponentItem(
      id: 'ceil_louver_wood_$i',
      name: 'Fluted Ceiling Panel - ${woodVariations[i]}',
      category: 'Ceiling & Linings',
      type: 'border_profile',
      shapeFamily: 'louver',
      defaultWidth: 6.0,
      defaultHeight: 4.0,
      color: Colors.brown.shade300,
      icon: Icons.view_week_outlined,
      description: 'Elegant ${woodVariations[i]} wooden ceiling flutes/louvers panel.',
    ));
  }
  final List<String> pvcVariations = ['Matte White', 'High Gloss White', 'Silver Line', 'Gold Thread', 'Beige', 'Charcoal', 'Grey', 'Black', 'Oak Wood', 'Teak Wood'];
  for (int i = 0; i < pvcVariations.length; i++) {
    list.add(ComponentItem(
      id: 'ceil_pvc_panel_$i',
      name: 'PVC Ceiling Plank - ${pvcVariations[i]}',
      category: 'Ceiling & Linings',
      type: 'border_profile',
      shapeFamily: 'louver',
      defaultWidth: 8.0,
      defaultHeight: 2.0,
      color: Colors.blueGrey.shade100,
      icon: Icons.dehaze_rounded,
      description: 'Moisture proof ${pvcVariations[i]} PVC ceiling panelling boards.',
    ));
  }

  // ==========================================
  // CATEGORY 2: WALL DECOR (40 items)
  // ==========================================
  final List<String> wallpaperDesigns = [
    'Damask Pattern', 'Geometric Mesh', 'Floral Silhouette', 'Tropical Leaf',
    'Industrial Concrete', 'Striped Classical', 'Abstract Watercolor', 'Starry Night Kids',
    'Art Deco Lines', 'Chevron Modern', 'Vintage Brick', 'Stucco Texture',
    'Silk Brocade', 'Minimalist Grid', 'Marbling Waves'
  ];
  for (int i = 0; i < wallpaperDesigns.length; i++) {
    list.add(ComponentItem(
      id: 'decor_wallpaper_$i',
      name: 'Wallpaper - ${wallpaperDesigns[i]}',
      category: 'Wall Decor',
      type: 'border_profile',
      shapeFamily: 'sticker',
      defaultWidth: 6.0,
      defaultHeight: 0.1,
      color: Colors.orange.shade100,
      icon: Icons.wallpaper,
      description: 'Premium textured wall roll in ${wallpaperDesigns[i]} design.',
    ));
  }

  final List<String> stickerThemes = [
    'Dandelion Wind', 'World Map Minimalist', 'Cat Silhouette Play', 'Birch Tree Silhouette',
    'Geometric Polygon Mountains', 'Inspiring Quote Lettering', 'Solar System Kids', 'Feather Float',
    'Golden Mandala', 'Watercolor Leaves', 'Cute Jungle Animals', 'Hexagon Mirror Tiles',
    'Compass Rose Vintage', 'Coffee Shop Doodles', 'Green Cactus Collection'
  ];
  for (int i = 0; i < stickerThemes.length; i++) {
    list.add(ComponentItem(
      id: 'decor_sticker_$i',
      name: 'Wall Decal - ${stickerThemes[i]}',
      category: 'Wall Decor',
      type: 'border_profile',
      shapeFamily: 'sticker',
      defaultWidth: 4.0,
      defaultHeight: 0.1,
      color: Colors.amber.shade100,
      icon: Icons.photo,
      description: 'Self-adhesive artistic ${stickerThemes[i]} vinyl wall decal.',
    ));
  }

  final List<String> flutedVariations = [
    'Teak', 'Charcoal PVC', 'Walnut Wood', 'Snow White', 'Slate Grey',
    'Gold Line Ivory', 'Earthy Ochre', 'Sage Green', 'Deep Indigo', 'Royal Crimson'
  ];
  for (int i = 0; i < flutedVariations.length; i++) {
    list.add(ComponentItem(
      id: 'decor_fluted_$i',
      name: 'Fluted Wall Panel - ${flutedVariations[i]}',
      category: 'Wall Decor',
      type: 'border_profile',
      shapeFamily: 'louver',
      defaultWidth: 3.0,
      defaultHeight: 0.2,
      color: Colors.brown.shade400,
      icon: Icons.view_column_outlined,
      description: 'Interior vertical cladding ${flutedVariations[i]} fluted slat board.',
    ));
  }

  // ==========================================
  // CATEGORY 3: LIGHTING (45 items)
  // ==========================================
  final List<String> spotlightCol = ['Warm White 3000K', 'Neutral White 4000K', 'Cool White 6500K', 'RGB Color Changing', 'Smart Dimming Wifi'];
  final List<int> wattages = [3, 5, 7, 9, 12];
  for (int wIdx = 0; wIdx < wattages.length; wIdx++) {
    for (int colIdx = 0; colIdx < spotlightCol.length; colIdx++) {
      final int watts = wattages[wIdx];
      final String col = spotlightCol[colIdx];
      list.add(ComponentItem(
        id: 'light_spot_${watts}w_$colIdx',
        name: 'LED Spotlight - ${watts}W ($col)',
        category: 'Lighting',
        type: 'downlight',
        shapeFamily: 'circle',
        defaultWidth: 0.5,
        defaultHeight: 0.5,
        color: colIdx == 0 ? Colors.amber : Colors.cyanAccent,
        icon: Icons.lightbulb,
        description: 'Recessed low-glare COB LED ceiling spot light, ${watts}W, $col.',
      ));
    }
  }

  final List<String> chandeliers = [
    'Crystal Cascade Grand', 'Modern Ring Chandelier', 'Vintage Edison Multi-bulb',
    'Sputnik Mid-Century', 'Orbital Sphere Pendant', 'Minimalist LED Wave',
    'Industrial Cage Chandelier', 'Rustic Wooden Beams Pendant', 'Nordic Glass Globes',
    'Classic Brass Candelabra'
  ];
  for (int i = 0; i < chandeliers.length; i++) {
    list.add(ComponentItem(
      id: 'light_chandelier_$i',
      name: 'Chandelier - ${chandeliers[i]}',
      category: 'Lighting',
      type: 'downlight',
      shapeFamily: 'circle',
      defaultWidth: 3.5,
      defaultHeight: 3.5,
      color: Colors.amberAccent,
      icon: Icons.filter_tilt_shift,
      description: 'Premium decorative hanging ceiling light: ${chandeliers[i]}.',
    ));
  }

  final List<String> profiles = [
    'Alu-Profile Corner Warm', 'Alu-Profile Recessed Cool', 'Silicon Neon Flex Red',
    'Silicon Neon Flex Blue', 'Silicon Neon Flex Green', 'Silicon Neon Flex RGB',
    'Under-cabinet Slim Profile', 'Surface Mount Wide Track', 'Suspended Linear Fixture',
    'Curved Profile Channel'
  ];
  for (int i = 0; i < profiles.length; i++) {
    list.add(ComponentItem(
      id: 'light_profile_$i',
      name: 'Linear Profile Light - ${profiles[i]}',
      category: 'Lighting',
      type: 'profile_light',
      shapeFamily: 'line',
      defaultWidth: 5.0,
      defaultHeight: 0.15,
      color: Colors.cyanAccent,
      icon: Icons.linear_scale_outlined,
      description: 'Architectural extrusion light channel: ${profiles[i]}.',
    ));
  }

  // ==========================================
  // CATEGORY 4: ELECTRICAL & COOLING (45 items)
  // ==========================================
  final List<String> fanStyles = ['Oak Wood', 'Classic White', 'Aero Matte Black', 'Polished Brass', 'Industrial Metal', 'Kid\'s Colorful'];
  final List<int> fanBlades = [3, 4, 5];
  for (int sIdx = 0; sIdx < fanStyles.length; sIdx++) {
    for (int bIdx = 0; bIdx < fanBlades.length; bIdx++) {
      final style = fanStyles[sIdx];
      final blades = fanBlades[bIdx];
      list.add(ComponentItem(
        id: 'elec_fan_${blades}b_$sIdx',
        name: 'Ceiling Fan - $blades-Blade ($style)',
        category: 'Electrical & Cooling',
        type: 'fan_box',
        shapeFamily: 'fan',
        defaultWidth: 4.2,
        defaultHeight: 4.2,
        color: Colors.brown.shade800,
        icon: Icons.mode_fan_off,
        description: 'Premium ceiling fan with $blades aerodynamic blades in $style finish.',
      ));
    }
  }

  final List<String> wallFanColors = ['Alpine White', 'Piano Black', 'Steel Silver', 'Rose Gold'];
  for (int i = 0; i < wallFanColors.length; i++) {
    list.add(ComponentItem(
      id: 'elec_wall_fan_$i',
      name: 'Wall-Mount Fan - ${wallFanColors[i]}',
      category: 'Electrical & Cooling',
      type: 'fan_box',
      shapeFamily: 'fan',
      defaultWidth: 2.0,
      defaultHeight: 2.0,
      color: Colors.grey.shade600,
      icon: Icons.mode_fan_off_outlined,
      description: 'Adjustable angle wall-mounted bracket fan, ${wallFanColors[i]} finish.',
    ));
  }

  final List<String> acTypes = [
    'Cassette AC 1.5 Ton Slim', 'Cassette AC 2.0 Ton High-Cap', 'Cassette AC 3.0 Ton Quad-Flow',
    'Split AC Indoor Unit 1.0 Ton', 'Split AC Indoor Unit 1.5 Ton Inverter', 'Split AC Indoor Unit 2.0 Ton Inverter',
    'Linear Air Vent Slot 1m', 'Linear Air Vent Slot 2m', 'Circular HVAC Diffuser Vent',
    'Exhaust Vent Fan Square', 'Exhaust Vent Fan Round', 'HVAC Air Return Grille'
  ];
  for (int i = 0; i < acTypes.length; i++) {
    list.add(ComponentItem(
      id: 'elec_ac_$i',
      name: acTypes[i],
      category: 'Electrical & Cooling',
      type: 'ac_vent',
      shapeFamily: acTypes[i].contains('Split') ? 'box' : 'ac',
      defaultWidth: acTypes[i].contains('Split') ? 3.0 : (acTypes[i].contains('Slot') ? 4.0 : 2.0),
      defaultHeight: acTypes[i].contains('Split') ? 0.8 : (acTypes[i].contains('Slot') ? 0.3 : 2.0),
      color: Colors.lightBlueAccent,
      icon: Icons.ac_unit,
      description: 'Cooling & ventilation asset: ${acTypes[i]}.',
    ));
  }

  final List<String> safetySensors = ['Photoelectric Smoke Detector', 'Heat & Thermal Alarm Sensor', 'CO toxic Gas Alarm Sensor', 'Fire Water Sprinkler Head', 'Ambient Temp Sensor Panel'];
  for (int i = 0; i < safetySensors.length; i++) {
    list.add(ComponentItem(
      id: 'elec_sensor_$i',
      name: safetySensors[i],
      category: 'Electrical & Cooling',
      type: 'downlight',
      shapeFamily: 'circle',
      defaultWidth: 0.8,
      defaultHeight: 0.8,
      color: Colors.redAccent,
      icon: Icons.emergency,
      description: 'Safety automation sensor: ${safetySensors[i]}.',
    ));
  }

  // ==========================================
  // CATEGORY 5: FURNITURE 3D (50 items)
  // ==========================================
  final List<String> bedSizes = ['King Size Bed Frame', 'Queen Size Bed Frame', 'Double Bed Frame', 'Single Platform Bed', 'Bunk Bed Kids', 'Daybed Lounger', 'Canopy Poster Bed'];
  final List<String> bedStyles = ['Modern Oak', 'Upholstered Fabric', 'Walnut Classical', 'Nordic Pine', 'Minimalist Black Steel'];
  for (int sizeIdx = 0; sizeIdx < bedSizes.length; sizeIdx++) {
    for (int styleIdx = 0; styleIdx < bedStyles.length; styleIdx++) {
      list.add(ComponentItem(
        id: 'furn_bed_${sizeIdx}_$styleIdx',
        name: '${bedSizes[sizeIdx]} - ${bedStyles[styleIdx]}',
        category: 'Furniture 3D',
        type: 'gypsum_rect',
        shapeFamily: 'bed',
        defaultWidth: sizeIdx == 0 ? 6.5 : (sizeIdx == 1 ? 5.5 : 4.0),
        defaultHeight: 6.8,
        color: Colors.indigo.shade200,
        icon: Icons.bed,
        description: 'Complete 3D bed assembly containing headboard, custom fabric pillows and ${bedStyles[styleIdx]} framing.',
      ));
    }
  }

  final List<String> sofas = [
    'Premium Fabric Sofa Triple', 'Luxury Leather Sofa Double', 'Minimalist Armchair Single',
    'L-Shape Sectional Sofa Left', 'L-Shape Sectional Sofa Right', 'Plush Accent Lounge Chair',
    'Circular Lounge Ottoman', 'Velvet Tufted Daybed Sofa', 'Compact Studio Loveseat',
    'Home Theater Power Recliner'
  ];
  for (int i = 0; i < sofas.length; i++) {
    list.add(ComponentItem(
      id: 'furn_sofa_$i',
      name: sofas[i],
      category: 'Furniture 3D',
      type: 'gypsum_rect',
      shapeFamily: 'sofa',
      defaultWidth: i == 0 ? 7.0 : (i == 1 || i == 8 ? 5.5 : (i == 2 || i == 5 ? 3.0 : 8.0)),
      defaultHeight: 3.2,
      color: Colors.blueAccent.shade100,
      icon: Icons.chair,
      description: 'Interactive cushion-divided 3D sofa: ${sofas[i]}.',
    ));
  }

  final List<String> storage = [
    'Double Cabinet Wardrobe Oak', 'Triple Sliding Door Wardrobe', 'Modular TV Console Shelf',
    'Wall-Mounted Floating TV Unit', 'Bookshelf Case Walnut', 'Low Sideboard Credenza Cabinet',
    'Dressing Table Mirror Unit', 'Nightstand Side Drawer Wooden', 'Executive Office Desk Wooden',
    'Ergonomic Workstation Desk'
  ];
  for (int i = 0; i < storage.length; i++) {
    list.add(ComponentItem(
      id: 'furn_storage_$i',
      name: storage[i],
      category: 'Furniture 3D',
      type: 'gypsum_rect',
      shapeFamily: storage[i].contains('Wardrobe') ? 'wardrobe' : (storage[i].contains('Desk') ? 'table' : 'box'),
      defaultWidth: storage[i].contains('Wardrobe') ? 6.0 : (storage[i].contains('TV') ? 5.5 : 3.0),
      defaultHeight: storage[i].contains('Wardrobe') ? 2.2 : (storage[i].contains('TV') ? 1.6 : 1.8),
      color: Colors.brown.shade200,
      icon: Icons.door_sliding_outlined,
      description: 'Storage unit: ${storage[i]}.',
    ));
  }

  final List<String> tables = [
    'Dining Table Rectangular 6-Seater', 'Dining Table Round Glass 4-Seater', 'Dining Table Large Oval 8-Seater',
    'Coffee Table Wooden Square', 'Coffee Table Oval Modern Gloss', 'Coffee Table Nested Glass Set'
  ];
  for (int i = 0; i < tables.length; i++) {
    list.add(ComponentItem(
      id: 'furn_table_$i',
      name: tables[i],
      category: 'Furniture 3D',
      type: 'gypsum_rect',
      shapeFamily: 'table',
      defaultWidth: i == 0 ? 5.5 : (i == 1 || i == 3 || i == 4 ? 3.5 : 6.5),
      defaultHeight: i == 0 || i == 2 ? 3.5 : 3.5,
      color: Colors.orange.shade200,
      icon: Icons.table_restaurant,
      description: 'Table assembly with chairs layout: ${tables[i]}.',
    ));
  }

  final List<String> decorItems = [
    'Indoor Potted Fan Palm Plant', 'Indoor Ficus Lyrata Leaf Plant', 'Hanging English Ivy Planter',
    'Minimalist Round Wall Mirror', 'Full-Length Floor Dressing Mirror', 'Modern Abstract Framed Canvas',
    'Classic Oil Landscape Painting', 'Plush Shag Floor Carpet Rect', 'Braided Jute Round Accent Rug',
    'Modern Tall Tripod Floor Lamp', 'Bedside Ceramic Table Lamp'
  ];
  for (int i = 0; i < decorItems.length; i++) {
    list.add(ComponentItem(
      id: 'furn_decor_$i',
      name: decorItems[i],
      category: 'Furniture 3D',
      type: decorItems[i].contains('Mirror') || decorItems[i].contains('Painting') ? 'border_profile' : 'gypsum_circle',
      shapeFamily: 'decor',
      defaultWidth: decorItems[i].contains('Carpet') || decorItems[i].contains('Rug') ? 6.0 : 2.0,
      defaultHeight: decorItems[i].contains('Carpet') || decorItems[i].contains('Rug') ? 4.0 : 2.0,
      color: Colors.green.shade300,
      icon: decorItems[i].contains('Plant') ? Icons.park_outlined : Icons.light_mode,
      description: 'Decorative interior asset: ${decorItems[i]}.',
    ));
  }

  return list;
}
