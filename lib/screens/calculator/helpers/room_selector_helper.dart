import 'package:flutter/material.dart';

class RoomSelectorHelper {
  /// Master list of 130+ comprehensive room names across all categories and floors
  static const List<String> masterRoomOptions = [
    // --- LIVING & HALL SPACES ---
    'Living Room',
    'Main Living Hall',
    'Formal Living',
    'Family Living',
    'Upper Living',
    'Lower Living',
    'Double Height Living',
    'Central Hall',
    'Drawing Room',
    'Foyer',
    'Lobby Area',
    'Sitting Area',
    'Family Room',
    'Waiting Lounge',
    'Reception Area',

    // --- BEDROOMS & SUITES ---
    'Master Bedroom',
    'Bedroom 1',
    'Bedroom 2',
    'Bedroom 3',
    'Bedroom 4',
    'Bedroom 5',
    'Second Bedroom',
    'Third Bedroom',
    'Fourth Bedroom',
    'Kids Bedroom',
    'Children Room',
    'Guest Bedroom',
    'Parents Bedroom',
    'Grandparents Room',
    'Teen Bedroom',
    'Studio Bedroom',
    'Penthouse Suite',
    'Servant Room',
    'Caretaker Room',
    'Drivers Room',

    // --- DINING & KITCHEN ---
    'Dining Room',
    'Main Dining Hall',
    'Family Dining',
    'Breakfast Counter',
    'Kitchen',
    'Main Kitchen',
    'Open Kitchen',
    'Modular Kitchen',
    'Dirty Kitchen',
    'Work Area',
    'Wet Kitchen',
    'Pantry',
    'Cafeteria',
    'Bar Counter Area',
    'Wine Cellar',

    // --- BATHROOMS & DRESSING ---
    'Master Bathroom',
    'Common Bathroom',
    'Attached Bathroom',
    'Attached Bathroom 1',
    'Attached Bathroom 2',
    'Attached Bathroom 3',
    'Powder Room',
    'Guest Toilet',
    'Restroom Male',
    'Restroom Female',
    'Handicap Restroom',
    'Dress Room',
    'Walk-in Wardrobe',
    'Change Room',
    'Sauna & Spa Room',

    // --- PRAYER, STUDY & OFFICE ---
    'Pooja Room',
    'Prayer Hall',
    'Meditation Room',
    'Yoga Room',
    'Study Room',
    'Library',
    'Home Office',
    'Conference Room',
    'Board Room',
    'Meeting Room',
    'Manager Cabin',
    'Director Cabin',
    'Staff Room',
    'Billing Counter',
    'Reception Desk',

    // --- ENTERTAINMENT & FITNESS ---
    'Home Theater',
    'Entertainment Room',
    'Music Room',
    'Gaming Room',
    'Studio Room',
    'Art Room',
    'Rehearsal Room',
    'Gym Room',
    'Salon Area',
    'Indoor Games Room',
    'Party Hall',
    'Multipurpose Hall',

    // --- BALCONY, VERANDAH & OUTDOOR ---
    'Sitout',
    'Verandah',
    'Balcony',
    'Balcony 1',
    'Balcony 2',
    'Front Balcony',
    'Master Balcony',
    'Service Balcony',
    'Car Porch',
    'Garage',
    'Portico',
    'Courtyard',
    'Zen Garden Area',
    'Sunroom',
    'Terrace',
    'Open Terrace',
    'Roof Garden',
    'Gazebo',
    'Swimming Pool Deck',
    'Skywalk',
    'Bridge Area',

    // --- UTILITY, STORAGE & TECHNICAL ---
    'Store Room',
    'Food Store',
    'Ironing Room',
    'Laundry Room',
    'Utility Area',
    'Staircase Area',
    'Inverter Room',
    'Generator Room',
    'Electrical Panel Room',
    'Server Room',
    'Security Cabin',
    'Watchman Room',
    'Pump Room',
    'Workshop Area',
    'Warehouse Section',
    'Packing Area',
    'Display Hall',
    'Showroom Area',
    'Clinic Room',
    'First Aid Room',
    'Laboratory',
    'Testing Room',
    'AC Duct Area',
    'Shaft Area',
    'Mezzanine Floor',
  ];

  /// Categorizes each room for easy filtering
  static String getCategory(String room) {
    final lower = room.toLowerCase();
    if (lower.contains('living') || lower.contains('hall') || lower.contains('foyer') || lower.contains('lobby') || lower.contains('lounge') || lower.contains('drawing')) {
      return 'Living';
    }
    if (lower.contains('bed') || lower.contains('suite') || lower.contains('servant') || lower.contains('caretaker') || lower.contains('driver')) {
      return 'Bedroom';
    }
    if (lower.contains('kitchen') || lower.contains('dining') || lower.contains('pantry') || lower.contains('cafeteria') || lower.contains('bar') || lower.contains('wine') || lower.contains('work area')) {
      return 'Kitchen/Dining';
    }
    if (lower.contains('bath') || lower.contains('toilet') || lower.contains('powder') || lower.contains('restroom') || lower.contains('dress') || lower.contains('wardrobe') || lower.contains('spa') || lower.contains('sauna')) {
      return 'Bathroom';
    }
    if (lower.contains('pooja') || lower.contains('prayer') || lower.contains('meditat') || lower.contains('yoga') || lower.contains('study') || lower.contains('library') || lower.contains('office') || lower.contains('cabin') || lower.contains('board') || lower.contains('conference')) {
      return 'Pooja/Office';
    }
    if (lower.contains('theater') || lower.contains('entertain') || lower.contains('music') || lower.contains('game') || lower.contains('gym') || lower.contains('salon') || lower.contains('party')) {
      return 'Luxury';
    }
    if (lower.contains('balcony') || lower.contains('sitout') || lower.contains('verandah') || lower.contains('porch') || lower.contains('portico') || lower.contains('terrace') || lower.contains('garden') || lower.contains('garage') || lower.contains('courtyard')) {
      return 'Outdoor';
    }
    return 'Utility';
  }

  static IconData getCategoryIcon(String category) {
    switch (category) {
      case 'Living':
        return Icons.weekend_outlined;
      case 'Bedroom':
        return Icons.bed_outlined;
      case 'Kitchen/Dining':
        return Icons.restaurant_outlined;
      case 'Bathroom':
        return Icons.bathtub_outlined;
      case 'Pooja/Office':
        return Icons.menu_book_outlined;
      case 'Luxury':
        return Icons.tv_outlined;
      case 'Outdoor':
        return Icons.deck_outlined;
      default:
        return Icons.build_circle_outlined;
    }
  }

  static const List<Color> _roomPalette = [
    Color(0xFF2563EB), // Blue
    Color(0xFF16A34A), // Green
    Color(0xFFD97706), // Amber
    Color(0xFF9333EA), // Purple
    Color(0xFFDC2626), // Red
    Color(0xFF0D9488), // Teal
    Color(0xFF4F46E5), // Indigo
    Color(0xFFEA580C), // Orange
    Color(0xFFDB2777), // Pink/Magenta
    Color(0xFF65A30D), // Lime
    Color(0xFF0891B2), // Cyan
    Color(0xFFE11D48), // Rose
    Color(0xFF7C3AED), // Violet
    Color(0xFFB45309), // Brown/Gold
    Color(0xFF047857), // Emerald
    Color(0xFF4338CA), // Deep Indigo
    Color(0xFFBE185D), // Pink
    Color(0xFF0369A1), // Sky Blue
  ];

  static Color getRoomColor(String room, [int? index]) {
    if (index != null && index >= 0) {
      return _roomPalette[index % _roomPalette.length];
    }
    final hash = room.codeUnits.fold(0, (prev, element) => prev + element);
    return _roomPalette[hash % _roomPalette.length];
  }

  /// Opens the 100+ room selector modal bottom sheet with instant search and single-click tap
  static Future<String?> showRoomPicker(
    BuildContext context, {
    String? currentRoom,
    String title = 'റൂം തിരഞ്ഞെടുക്കുക (Select Room)',
  }) async {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _RoomPickerSheet(
        currentRoom: currentRoom,
        title: title,
      ),
    );
  }
}

class _RoomPickerSheet extends StatefulWidget {
  final String? currentRoom;
  final String title;

  const _RoomPickerSheet({
    this.currentRoom,
    required this.title,
  });

  @override
  State<_RoomPickerSheet> createState() => _RoomPickerSheetState();
}

class _RoomPickerSheetState extends State<_RoomPickerSheet> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _selectedCategory = 'All';
  String _searchQuery = '';

  final List<String> _categories = [
    'All',
    'Living',
    'Bedroom',
    'Kitchen/Dining',
    'Bathroom',
    'Pooja/Office',
    'Luxury',
    'Outdoor',
    'Utility',
  ];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<String> get _filteredRooms {
    final query = _searchQuery.trim().toLowerCase();
    return RoomSelectorHelper.masterRoomOptions.where((room) {
      final matchesQuery = query.isEmpty || room.toLowerCase().contains(query);
      if (!matchesQuery) return false;

      if (_selectedCategory == 'All') return true;
      final cat = RoomSelectorHelper.getCategory(room);
      return cat == _selectedCategory;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final sheetHeight = media.size.height * 0.85;
    final filtered = _filteredRooms;
    final hasExactMatch = RoomSelectorHelper.masterRoomOptions.any(
      (r) => r.toLowerCase() == _searchQuery.trim().toLowerCase(),
    );

    return Container(
      height: sheetHeight,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 6),
              width: 44,
              height: 4.5,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),

          // Header Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.meeting_room, color: Color(0xFFD4AF37), size: 22),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          widget.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD4AF37).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${RoomSelectorHelper.masterRoomOptions.length}+ Rooms',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF854D0E),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey),
                  onPressed: () => Navigator.pop(context),
                  tooltip: 'Close',
                ),
              ],
            ),
          ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: TextField(
              controller: _searchCtrl,
              autofocus: false,
              decoration: InputDecoration(
                hintText: 'റൂം തിരയുക (Search 130+ rooms e.g. Bed, Kitchen, Hall...)',
                hintStyle: TextStyle(fontSize: 12.5, color: Colors.grey.shade500),
                prefixIcon: const Icon(Icons.search, color: Color(0xFFD4AF37), size: 22),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          setState(() {
                            _searchCtrl.clear();
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFD4AF37), width: 1.8),
                ),
              ),
              onChanged: (val) {
                setState(() {
                  _searchQuery = val;
                });
              },
            ),
          ),

          // Quick Category Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              children: _categories.map((cat) {
                final isSelected = _selectedCategory == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: FilterChip(
                    label: Text(
                      cat == 'All' ? 'All (130+)' : cat,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? Colors.white : const Color(0xFF475569),
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: const Color(0xFFD4AF37),
                    backgroundColor: const Color(0xFFF1F5F9),
                    checkmarkColor: Colors.white,
                    showCheckmark: false,
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isSelected ? const Color(0xFFD4AF37) : const Color(0xFFE2E8F0),
                      ),
                    ),
                    onSelected: (sel) {
                      setState(() {
                        _selectedCategory = cat;
                      });
                    },
                  ),
                );
              }).toList(),
            ),
          ),

          const Divider(height: 1),

          // Custom Room Banner if typed something unique
          if (_searchQuery.trim().isNotEmpty && !hasExactMatch) ...[
            Material(
              color: const Color(0xFFFEF3C7),
              child: InkWell(
                onTap: () {
                  Navigator.pop(context, _searchQuery.trim());
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      const Icon(Icons.add_circle, color: Color(0xFFB45309)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '➕ കസ്റ്റം റൂം ചേർക്കുക: "${_searchQuery.trim()}"',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF92400E),
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios, size: 14, color: Color(0xFFB45309)),
                    ],
                  ),
                ),
              ),
            ),
            const Divider(height: 1),
          ],

          // Rooms List View
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 48, color: Colors.grey.shade400),
                        const SizedBox(height: 8),
                        Text(
                          'റൂമുകൾ ഒന്നും കണ്ടെത്തിയില്ല',
                          style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFD4AF37),
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () {
                            if (_searchQuery.trim().isNotEmpty) {
                              Navigator.pop(context, _searchQuery.trim());
                            }
                          },
                          icon: const Icon(Icons.add),
                          label: Text('Use "${_searchQuery.trim()}" as Room'),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final room = filtered[index];
                      final isCurrent = widget.currentRoom != null &&
                          widget.currentRoom!.toLowerCase() == room.toLowerCase();
                      final cat = RoomSelectorHelper.getCategory(room);
                      final icon = RoomSelectorHelper.getCategoryIcon(cat);
                      final roomColor = RoomSelectorHelper.getRoomColor(room, index);

                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        decoration: BoxDecoration(
                          color: roomColor.withValues(alpha: isCurrent ? 0.22 : 0.08),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: roomColor.withValues(alpha: isCurrent ? 1.0 : 0.75),
                            width: isCurrent ? 1.8 : 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: roomColor.withValues(alpha: 0.05),
                              blurRadius: 3,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: () {
                              Navigator.pop(context, room);
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                              child: Row(
                                children: [
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: roomColor.withValues(alpha: 0.6),
                                        width: 1.0,
                                      ),
                                    ),
                                    child: Icon(
                                      icon,
                                      size: 16,
                                      color: roomColor,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          room,
                                          style: TextStyle(
                                            fontSize: 13.5,
                                            fontWeight: isCurrent ? FontWeight.w900 : FontWeight.w700,
                                            color: roomColor,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          cat,
                                          style: TextStyle(
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.w500,
                                            color: roomColor.withValues(alpha: 0.8),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (isCurrent)
                                    Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: roomColor,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.check, color: Colors.white, size: 14),
                                    )
                                  else
                                    Icon(Icons.chevron_right, color: roomColor.withValues(alpha: 0.7), size: 18),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // Bottom Action: Add Custom Room Button
          SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: const BorderSide(color: Color(0xFFD4AF37), width: 1.2),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.edit, color: Color(0xFFB45309), size: 18),
                      label: const Text(
                        '➕ വേറെ കസ്റ്റം റൂം പേര് നൽകുക (Custom Room)',
                        style: TextStyle(
                          color: Color(0xFFB45309),
                          fontWeight: FontWeight.bold,
                          fontSize: 12.5,
                        ),
                      ),
                      onPressed: () async {
                        final customCtrl = TextEditingController();
                        final res = await showDialog<String>(
                          context: context,
                          builder: (c) => AlertDialog(
                            title: const Text('Enter Custom Room Name', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                            content: TextField(
                              controller: customCtrl,
                              autofocus: true,
                              decoration: const InputDecoration(
                                labelText: 'Room Name',
                                hintText: 'e.g. Courtyard, Upper Terrace, Office 2...',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(c), child: const Text('CANCEL')),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD4AF37), foregroundColor: Colors.white),
                                onPressed: () {
                                  if (customCtrl.text.trim().isNotEmpty) {
                                    Navigator.pop(c, customCtrl.text.trim());
                                  }
                                },
                                child: const Text('ADD'),
                              ),
                            ],
                          ),
                        );
                        if (res != null && res.isNotEmpty && context.mounted) {
                          Navigator.pop(context, res);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

