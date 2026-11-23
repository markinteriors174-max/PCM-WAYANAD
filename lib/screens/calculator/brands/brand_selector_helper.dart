import 'package:flutter/material.dart';
import 'ceiling_board_brands.dart';
import 'channel_brands.dart';

class BrandSelectorHelper {
  static Future<String?> showBrandPicker(
    BuildContext context, {
    required String title,
    required List<String> brands,
    String? currentBrand,
    bool isChannel = false,
  }) async {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _BrandPickerSheet(
        title: title,
        brands: brands,
        currentBrand: currentBrand,
        isChannel: isChannel,
      ),
    );
  }
}

class _BrandPickerSheet extends StatefulWidget {
  final String title;
  final List<String> brands;
  final String? currentBrand;
  final bool isChannel;

  const _BrandPickerSheet({
    required this.title,
    required this.brands,
    this.currentBrand,
    required this.isChannel,
  });

  @override
  State<_BrandPickerSheet> createState() => _BrandPickerSheetState();
}

class _BrandPickerSheetState extends State<_BrandPickerSheet> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<String> get _filteredBrands {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) return widget.brands;
    return widget.brands.where((b) => b.toLowerCase().contains(query)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final sheetHeight = media.size.height * 0.75;
    final filtered = _filteredBrands;
    final hasExactMatch = widget.brands.any(
      (b) => b.toLowerCase() == _searchQuery.trim().toLowerCase(),
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
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(
                        widget.isChannel ? Icons.architecture : Icons.layers,
                        color: const Color(0xFFD4AF37),
                        size: 22,
                      ),
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
              decoration: InputDecoration(
                hintText: widget.isChannel ? 'Search channel brand or type custom...' : 'Search ceiling board brand or type custom...',
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
          const Divider(height: 1),
          // Custom Brand Banner if typed something unique
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
                          '➕ Use Custom Brand: "${_searchQuery.trim()}"',
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
          // List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final brand = filtered[index];
                final isCurrent = widget.currentBrand != null &&
                    widget.currentBrand!.toLowerCase() == brand.toLowerCase();
                final brandColor = widget.isChannel
                    ? ChannelBrands.getBrandColor(brand, index)
                    : CeilingBoardBrands.getBrandColor(brand, index);

                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    color: brandColor.withValues(alpha: isCurrent ? 0.22 : 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: brandColor.withValues(alpha: isCurrent ? 1.0 : 0.75),
                      width: isCurrent ? 1.8 : 1.5,
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () {
                        if (brand == 'More' || brand == 'Other') {
                          _showCustomBrandDialog(context);
                        } else {
                          Navigator.pop(context, brand);
                        }
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
                                  color: brandColor.withValues(alpha: 0.9),
                                  width: 1.3,
                                ),
                              ),
                              child: Icon(
                                (brand == 'More' || brand == 'Other') ? Icons.edit_note : (widget.isChannel ? Icons.architecture_outlined : Icons.layers_outlined),
                                size: 16,
                                color: brandColor,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                brand,
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: isCurrent ? FontWeight.w900 : FontWeight.w700,
                                  color: brandColor,
                                ),
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.edit_outlined, color: brandColor.withValues(alpha: 0.8), size: 18),
                                  tooltip: 'Edit Brand Name',
                                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                  padding: EdgeInsets.zero,
                                  onPressed: () {
                                    _showEditBrandDialog(context, brand);
                                  },
                                ),
                                const SizedBox(width: 4),
                                if (isCurrent)
                                  Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: brandColor,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.check, color: Colors.white, size: 14),
                                  )
                                else
                                  Icon(Icons.chevron_right, color: brandColor.withValues(alpha: 0.7), size: 18),
                              ],
                            ),
                          ],
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
    );
  }

  void _showEditBrandDialog(BuildContext context, String currentBrand) async {
    final editCtrl = TextEditingController(text: currentBrand);
    final res = await showDialog<String>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('Edit ${widget.isChannel ? "Channel" : "Board"} Brand', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: editCtrl,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Brand Name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text('CANCEL')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD4AF37), foregroundColor: Colors.white),
            onPressed: () {
              if (editCtrl.text.trim().isNotEmpty) {
                Navigator.pop(c, editCtrl.text.trim());
              }
            },
            child: const Text('SAVE'),
          ),
        ],
      ),
    );
    if (res != null && res.isNotEmpty && context.mounted) {
      Navigator.pop(context, res);
    }
  }

  void _showCustomBrandDialog(BuildContext context) async {
    final customCtrl = TextEditingController();
    final res = await showDialog<String>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('Enter Custom ${widget.isChannel ? "Channel" : "Board"} Brand', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: customCtrl,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Brand Name',
            hintText: 'e.g. Custom Brand Name...',
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
  }
}
