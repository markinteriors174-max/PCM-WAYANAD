import 'package:flutter/material.dart';
import '../utils/component_library.dart';

class AssetDrawer extends StatefulWidget {
  final bool isOpened;
  final VoidCallback onToggle;
  final Function(ComponentItem item) onTapAsset;

  const AssetDrawer({
    super.key,
    required this.isOpened,
    required this.onToggle,
    required this.onTapAsset,
  });

  @override
  State<AssetDrawer> createState() => _AssetDrawerState();
}

class _AssetDrawerState extends State<AssetDrawer> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';
  String _searchQuery = '';

  final List<String> _categories = [
    'All',
    'Ceiling & Linings',
    'Wall Decor',
    'Lighting',
    'Electrical & Cooling',
    'Furniture 3D'
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Filter component library based on category and search query
    final filteredItems = componentLibrary.where((item) {
      final matchesCategory = _selectedCategory == 'All' || item.category == _selectedCategory;
      final matchesSearch = _searchQuery.isEmpty ||
          item.name.toLowerCase().contains(_searchQuery) ||
          item.description.toLowerCase().contains(_searchQuery);
      return matchesCategory && matchesSearch;
    }).toList();

    final double drawerH = widget.isOpened ? 240.0 : 40.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      height: drawerH,
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFF10121A),
        border: Border(
          top: BorderSide(color: Color(0xFFD4AF37), width: 1.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black87,
            blurRadius: 10,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: widget.isOpened
          ? Column(
              children: [
                // Drawer Pull-up / Pull-down Handle Bar
                GestureDetector(
                  onTap: widget.onToggle,
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    height: 34,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    color: const Color(0xFF161924),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.keyboard_arrow_down,
                          color: Color(0xFFD4AF37),
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'COLLAPSE ASSET LIBRARY',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 8.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Drawer Contents
                Expanded(
                  child: Row(
                    children: [
                      // Left Side: Category Tabs & Search Bar (Width: 200px)
                      Container(
                        width: 200,
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          border: Border(
                            right: BorderSide(color: Colors.white10, width: 0.8),
                          ),
                        ),
                        child: Column(
                          children: [
                            // Search Bar
                            SizedBox(
                              height: 28,
                              child: TextField(
                                controller: _searchController,
                                style: const TextStyle(color: Colors.white, fontSize: 10),
                                decoration: InputDecoration(
                                  isDense: true,
                                  hintText: 'Search 200+ assets...',
                                  hintStyle: const TextStyle(color: Colors.white24, fontSize: 9),
                                  prefixIcon: const Icon(Icons.search, color: Color(0xFFD4AF37), size: 12),
                                  prefixIconConstraints: const BoxConstraints(minWidth: 24, maxHeight: 24),
                                  suffixIcon: _searchQuery.isNotEmpty
                                      ? GestureDetector(
                                          onTap: () => _searchController.clear(),
                                          child: const Icon(Icons.close, color: Colors.white54, size: 12),
                                        )
                                      : null,
                                  suffixIconConstraints: const BoxConstraints(minWidth: 24, maxHeight: 24),
                                  contentPadding: const EdgeInsets.symmetric(vertical: 6),
                                  border: const OutlineInputBorder(
                                    borderSide: BorderSide(color: Colors.white24),
                                  ),
                                  enabledBorder: const OutlineInputBorder(
                                    borderSide: BorderSide(color: Colors.white12),
                                  ),
                                  focusedBorder: const OutlineInputBorder(
                                    borderSide: BorderSide(color: Color(0xFFD4AF37)),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            // Categories List
                            Expanded(
                              child: ListView.builder(
                                padding: EdgeInsets.zero,
                                itemCount: _categories.length,
                                itemBuilder: (context, index) {
                                  final cat = _categories[index];
                                  final isSelected = _selectedCategory == cat;
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 2),
                                    child: InkWell(
                                      onTap: () {
                                        setState(() {
                                          _selectedCategory = cat;
                                        });
                                      },
                                      borderRadius: BorderRadius.circular(4),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: isSelected ? const Color(0xFFD4AF37) : Colors.transparent,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          cat.toUpperCase(),
                                          style: TextStyle(
                                            color: isSelected ? Colors.black : Colors.white70,
                                            fontSize: 8,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Right Side: Grid of Assets (Lazy loaded)
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          child: filteredItems.isEmpty
                              ? const Center(
                                  child: Text(
                                    'No matching components found.',
                                    style: TextStyle(color: Colors.white30, fontSize: 10),
                                  ),
                                )
                              : GridView.builder(
                                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 4,
                                    crossAxisSpacing: 10,
                                    mainAxisSpacing: 10,
                                    childAspectRatio: 0.85,
                                  ),
                                  itemCount: filteredItems.length,
                                  itemBuilder: (context, index) {
                                    final item = filteredItems[index];
                                    final card = Card(
                                      color: const Color(0xFF1A1D28),
                                      clipBehavior: Clip.antiAlias,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(6),
                                        side: const BorderSide(color: Colors.white10, width: 0.8),
                                      ),
                                      margin: EdgeInsets.zero,
                                      child: InkWell(
                                        onTap: () => widget.onTapAsset(item),
                                        borderRadius: BorderRadius.circular(6),
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Expanded(
                                                child: ClipRRect(
                                                  borderRadius: BorderRadius.circular(4),
                                                  child: Image.asset(
                                                    item.imageUrl,
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (context, error, stackTrace) {
                                                      debugPrint(" missing image at path: ${item.imageUrl}");
                                                      return const Center(
                                                        child: Icon(
                                                          Icons.image_not_supported,
                                                          color: Colors.grey,
                                                        ),
                                                      );
                                                    },
                                                  ),
                                                ),
                                              ),
                                              Padding(
                                                padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 2.0),
                                                child: Text(
                                                  item.title,
                                                  textAlign: TextAlign.center,
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 11.0,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                              Text(
                                                '${item.defaultWidth.toStringAsFixed(1)}×${item.defaultHeight.toStringAsFixed(1)} Ft',
                                                style: const TextStyle(
                                                  color: Colors.white38,
                                                  fontSize: 8.0,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );

                                    // Wrap in Draggable to support drag-and-drop instantiation
                                    return Draggable<ComponentItem>(
                                      data: item,
                                      dragAnchorStrategy: pointerDragAnchorStrategy,
                                      feedback: Material(
                                        color: Colors.transparent,
                                        child: Opacity(
                                          opacity: 0.7,
                                          child: Container(
                                            width: 80,
                                            height: 60,
                                            padding: const EdgeInsets.all(4),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFD4AF37).withValues(alpha: 0.9),
                                              borderRadius: BorderRadius.circular(6),
                                              border: Border.all(color: Colors.white, width: 1.5),
                                            ),
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Icon(item.icon, size: 16, color: Colors.black),
                                                Text(
                                                  item.title,
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    color: Colors.black,
                                                    fontSize: 7.0,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                      childWhenDragging: Opacity(
                                        opacity: 0.35,
                                        child: card,
                                      ),
                                      child: card,
                                    );
                                  },
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            )
          : GestureDetector(
              onTap: widget.onToggle,
              behavior: HitTestBehavior.opaque,
              child: Container(
                height: 38,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                color: const Color(0xFF161924),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.keyboard_arrow_up,
                      color: Color(0xFFD4AF37),
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'EXPAND ASSET LIBRARY (${componentLibrary.length} COMPONENTS)',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 8.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
