import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../models/catalog_model.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/brand_logo_overlay_widget.dart';
import '../../../utils/calculator_utils.dart';

class HomeCatalogSection extends StatefulWidget {
  const HomeCatalogSection({super.key});

  @override
  State<HomeCatalogSection> createState() => _HomeCatalogSectionState();
}

class _HomeCatalogSectionState extends State<HomeCatalogSection> {
  List<CatalogItemModel> _items = [];
  bool _isLoading = true;
  bool _isSaving = false;
  String _selectedCategory = 'ALL CATEGORIES';
  String _searchQuery = '';
  DateTime? _lastSyncedTime;

  static const List<Map<String, String>> _presetImages = [
    {
      'title': 'Gypsum False Ceiling',
      'url': 'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?q=80&w=800&auto=format&fit=crop',
    },
    {
      'title': 'Cove LED Lighting',
      'url': 'https://images.unsplash.com/photo-1600607687939-ce8a6c25118c?q=80&w=800&auto=format&fit=crop',
    },
    {
      'title': 'Grid Acoustic Ceiling',
      'url': 'https://images.unsplash.com/photo-1600566753190-17f0baa2a6c3?q=80&w=800&auto=format&fit=crop',
    },
    {
      'title': 'WPC Louver Panel',
      'url': 'https://images.unsplash.com/photo-1618221195710-dd6b41faaea6?q=80&w=800&auto=format&fit=crop',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadCatalog();
  }

  Future<void> _loadCatalog() async {
    final loaded = await CatalogService.instance.loadCatalog();
    if (mounted) {
      setState(() {
        _items = List.from(loaded);
        _isLoading = false;
      });
    }
  }

  Future<void> _handleSyncToPortal() async {
    setState(() => _isSaving = true);
    await CatalogService.instance.saveCatalog(_items);
    final success = await CatalogService.instance.syncCatalogToFirestore();

    if (mounted) {
      setState(() {
        _isSaving = false;
        if (success) _lastSyncedTime = DateTime.now();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                success ? Icons.check_circle : Icons.error_outline,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  success
                      ? 'Catalog (${_items.length} items) synced to Web Portal (pcm-wayanad-portal.vercel.app) & Cloud!'
                      : 'Saved locally. Please check internet connection for cloud sync.',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ],
          ),
          backgroundColor: success ? const Color(0xFF2E7D32) : Colors.orange.shade800,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<String?> _pickSingleImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 82,
      );
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        return 'data:image/jpeg;base64,${base64Encode(bytes)}';
      }
    } catch (e) {
      debugPrint('Error picking single image: $e');
    }
    return null;
  }

  Future<void> _handleBulkAddPhotos() async {
    try {
      final picker = ImagePicker();
      final List<XFile> pickedFiles = await picker.pickMultiImage(
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 82,
      );

      if (pickedFiles.isEmpty) return;

      setState(() => _isSaving = true);

      final String targetCategory = _selectedCategory != 'ALL CATEGORIES' ? _selectedCategory : 'Gypsum Board';
      final int startCount = _items.length;
      final DateTime now = DateTime.now();

      final List<CatalogItemModel> newItems = [];
      for (int i = 0; i < pickedFiles.length; i++) {
        final file = pickedFiles[i];
        final bytes = await file.readAsBytes();
        final base64Image = 'data:image/jpeg;base64,${base64Encode(bytes)}';
        final itemNumber = startCount + i + 1;

        newItems.add(
          CatalogItemModel(
            id: 'cat_${now.millisecondsSinceEpoch}_$i',
            category: targetCategory,
            name: '$targetCategory Design #$itemNumber',
            description: 'Premium ceiling design catalog item from PCM Wayanad.',
            unit: 'Sq.Ft',
            rate: 95.0,
            imageUrl: base64Image,
            isAvailable: true,
            createdAt: now,
          ),
        );
      }

      _items.insertAll(0, newItems);
      await CatalogService.instance.saveCatalog(_items);
      final success = await CatalogService.instance.syncCatalogToFirestore();

      if (mounted) {
        setState(() {
          _isSaving = false;
          if (success) _lastSyncedTime = DateTime.now();
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Added ${pickedFiles.length} catalog items & synced live to Web Portal!',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF2E7D32),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error bulk adding catalog photos: $e');
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding bulk photos: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showAddEditCatalogDialog({CatalogItemModel? existingItem}) {
    final isEdit = existingItem != null;
    final nameCtrl = TextEditingController(text: existingItem?.name ?? '');
    final catCtrl = TextEditingController(text: existingItem?.category ?? 'Gypsum Board');
    final descCtrl = TextEditingController(text: existingItem?.description ?? '');
    final rateCtrl = TextEditingController(text: existingItem?.rate.toStringAsFixed(0) ?? '95');
    final unitCtrl = TextEditingController(text: existingItem?.unit ?? 'Sq.Ft');
    final skuCtrl = TextEditingController(text: existingItem?.sku ?? '');
    final imageCtrl = TextEditingController(text: existingItem?.imageUrl ?? '');
    bool isAvailable = existingItem?.isAvailable ?? true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final currentPhoto = imageCtrl.text.trim();

          return AlertDialog(
            backgroundColor: AppColors.background,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: AppColors.border, width: 1.5),
            ),
            title: Row(
              children: [
                const Icon(Icons.inventory_2_rounded, color: AppColors.border, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isEdit ? 'Edit Catalog Item' : '+ Add Unlimited Catalog Item',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: AppColors.border,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Photo & Brand Logo Overlay Preview
                  _buildLabel('Product Image (With Brand Logo Watermark):'),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: SizedBox(
                            width: double.infinity,
                            height: 120,
                            child: BrandLogoOverlayWidget(
                              brandText: 'PCM WAYANAD',
                              child: _buildItemThumbnail(currentPhoto, width: double.infinity, height: 120),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          alignment: WrapAlignment.center,
                          children: [
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryButton,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              icon: const Icon(Icons.photo_library, size: 14),
                              label: const Text('GALLERY', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                              onPressed: () async {
                                final img = await _pickSingleImage(ImageSource.gallery);
                                if (img != null) {
                                  setDialogState(() => imageCtrl.text = img);
                                }
                              },
                            ),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.border,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              icon: const Icon(Icons.camera_alt, size: 14),
                              label: const Text('CAMERA', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                              onPressed: () async {
                                final img = await _pickSingleImage(ImageSource.camera);
                                if (img != null) {
                                  setDialogState(() => imageCtrl.text = img);
                                }
                              },
                            ),
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.brown,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                side: BorderSide(color: Colors.brown.shade300),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              icon: const Icon(Icons.collections, size: 14),
                              label: const Text('PRESETS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                              onPressed: () {
                                showDialog(
                                  context: ctx,
                                  builder: (pCtx) => AlertDialog(
                                    title: const Text('Pick Preset Ceiling Photo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                    content: SizedBox(
                                      width: double.maxFinite,
                                      child: ListView.separated(
                                        shrinkWrap: true,
                                        itemCount: _presetImages.length,
                                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                                        itemBuilder: (_, i) {
                                          final p = _presetImages[i];
                                          return ListTile(
                                            leading: Image.network(p['url']!, width: 50, height: 40, fit: BoxFit.cover),
                                            title: Text(p['title']!, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                            onTap: () {
                                              Navigator.pop(pCtx);
                                              setDialogState(() => imageCtrl.text = p['url']!);
                                            },
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                            if (currentPhoto.isNotEmpty)
                              TextButton.icon(
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.redAccent,
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                ),
                                icon: const Icon(Icons.close, size: 14),
                                label: const Text('REMOVE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                onPressed: () => setDialogState(() => imageCtrl.clear()),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  _buildLabel('Category:'),
                  TextField(
                    controller: catCtrl,
                    textCapitalization: TextCapitalization.words,
                    decoration: AppStyles.inputDecoration('e.g. Gypsum Board, PVC, Louver, Grid'),
                  ),
                  const SizedBox(height: 12),

                  _buildLabel('Material / Product Name:'),
                  TextField(
                    controller: nameCtrl,
                    textCapitalization: TextCapitalization.words,
                    decoration: AppStyles.inputDecoration('e.g. Saint-Gobain Gyproc Moisture Resistant'),
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('Rate (₹):'),
                            TextField(
                              controller: rateCtrl,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: AppStyles.inputDecoration('Rate ₹'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('Unit:'),
                            TextField(
                              controller: unitCtrl,
                              decoration: AppStyles.inputDecoration('Sq.Ft / Nos / Box'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  _buildLabel('Description / Specifications:'),
                  TextField(
                    controller: descCtrl,
                    maxLines: 2,
                    decoration: AppStyles.inputDecoration('Product details for client portal...'),
                  ),
                  const SizedBox(height: 12),

                  _buildLabel('SKU / Code (Optional):'),
                  TextField(
                    controller: skuCtrl,
                    textCapitalization: TextCapitalization.characters,
                    decoration: AppStyles.inputDecoration('e.g. SG-GYP-01'),
                  ),
                  const SizedBox(height: 12),

                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      children: [
                        const Text(
                          'Available / Live in Portal:',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.border),
                        ),
                        const Spacer(),
                        Switch(
                          value: isAvailable,
                          activeColor: AppColors.resultGreen,
                          onChanged: (val) => setDialogState(() => isAvailable = val),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('CANCEL', style: TextStyle(color: Colors.black54, fontWeight: FontWeight.bold)),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.border,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: Icon(isEdit ? Icons.save : Icons.add, size: 18),
                label: Text(
                  isEdit ? 'SAVE CHANGES' : 'ADD ITEM',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                onPressed: () async {
                  final name = nameCtrl.text.trim();
                  final cat = catCtrl.text.trim();
                  final rate = double.tryParse(rateCtrl.text.trim()) ?? 0.0;

                  if (name.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter a product/material name.'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  final newItem = CatalogItemModel(
                    id: isEdit ? existingItem.id : 'cat_${DateTime.now().millisecondsSinceEpoch}',
                    category: cat.isNotEmpty ? cat : 'Gypsum Board',
                    name: name,
                    description: descCtrl.text.trim().isNotEmpty
                        ? descCtrl.text.trim()
                        : 'Premium ceiling material from PCM Wayanad.',
                    unit: unitCtrl.text.trim().isNotEmpty ? unitCtrl.text.trim() : 'Sq.Ft',
                    rate: rate,
                    imageUrl: imageCtrl.text.trim().isNotEmpty ? imageCtrl.text.trim() : null,
                    sku: skuCtrl.text.trim().isNotEmpty ? skuCtrl.text.trim() : null,
                    isAvailable: isAvailable,
                    createdAt: isEdit ? existingItem.createdAt : DateTime.now(),
                  );

                  if (isEdit) {
                    await CatalogService.instance.updateItem(newItem);
                  } else {
                    await CatalogService.instance.addItem(newItem);
                  }

                  if (mounted) {
                    Navigator.pop(ctx);
                    await _loadCatalog();
                    await _handleSyncToPortal();
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        label,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.labelColor),
      ),
    );
  }

  Widget _buildItemThumbnail(String? photoData, {double width = 64, double height = 64}) {
    final clean = photoData?.trim() ?? '';

    final fallback = Container(
      width: width,
      height: height,
      color: Colors.amber.shade100.withAlpha(120),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.architecture, color: AppColors.border, size: 24),
          SizedBox(height: 2),
          Text('PCM', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: AppColors.border)),
        ],
      ),
    );

    if (clean.isEmpty) return fallback;

    if (clean.startsWith('http://') || clean.startsWith('https://')) {
      return Image.network(
        clean,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => fallback,
      );
    }

    try {
      final base64Str = clean.contains(',') ? clean.split(',').last.trim() : clean;
      final bytes = base64Decode(base64Str);
      if (bytes.isNotEmpty) {
        return Image.memory(
          bytes,
          width: width,
          height: height,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => fallback,
        );
      }
    } catch (_) {}

    return fallback;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        height: 120,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.amber.shade300, width: 1.5),
        ),
        child: const Center(child: CircularProgressIndicator(color: AppColors.border)),
      );
    }

    final categories = ['ALL CATEGORIES', ...CatalogService.instance.categories];
    final activeCategoryFilter = categories.contains(_selectedCategory) ? _selectedCategory : 'ALL CATEGORIES';

    List<CatalogItemModel> filtered = _items;
    if (activeCategoryFilter != 'ALL CATEGORIES') {
      filtered = filtered.where((i) => i.category.trim().toLowerCase() == activeCategoryFilter.trim().toLowerCase()).toList();
    }

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      filtered = filtered.where((i) =>
          i.name.toLowerCase().contains(q) ||
          i.category.toLowerCase().contains(q) ||
          i.description.toLowerCase().contains(q) ||
          (i.sku?.toLowerCase().contains(q) ?? false)).toList();
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.shade300, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header Row with Prominent "+" & Bulk Photos Actions
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.border.withAlpha(20),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.inventory_2_rounded,
                  color: AppColors.border,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Flexible(
                          child: Text(
                            'PCM PRODUCT CATALOG',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF3E2723),
                              letterSpacing: 0.8,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Overflow-safe unlimited item counter badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primaryButton.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: FittedBox(
                            child: Text(
                              '${_items.length} ITEMS',
                              style: const TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryButton,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Live Catalog Synced With Web Portal (pcm-wayanad-portal.vercel.app)',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.black54,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              // Prominent "+" Quick Add Button (Non-clipped)
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                icon: const Icon(Icons.add_circle, color: AppColors.primaryButton, size: 32),
                tooltip: 'Add Single Catalog Item',
                onPressed: () => _showAddEditCatalogDialog(),
              ),
              const SizedBox(width: 6),
              // Bulk Add Photos Button
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryButton,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 1,
                ),
                icon: const Icon(Icons.photo_library, size: 15),
                label: const Text(
                  '+ BULK PHOTOS',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                ),
                onPressed: _handleBulkAddPhotos,
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 12),

          // Search & Category Filters Row
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextField(
                  onChanged: (val) => setState(() => _searchQuery = val.trim()),
                  decoration: AppStyles.inputDecoration('Search catalog...').copyWith(
                    prefixIcon: const Icon(Icons.search, size: 18, color: AppColors.border),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: activeCategoryFilter,
                      isExpanded: true,
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.labelColor, fontSize: 11),
                      items: categories.map((cat) {
                        return DropdownMenuItem<String>(
                          value: cat,
                          child: Text(cat.toUpperCase(), overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedCategory = val);
                        }
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Catalog Items List (Unlimited & Scrollable)
          if (filtered.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFFFAFAFA),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                children: [
                  const Icon(Icons.inventory_2_outlined, size: 40, color: Colors.grey),
                  const SizedBox(height: 8),
                  const Text(
                    'No Catalog Items Found',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Tap "+" or "+ BULK PHOTOS" above to add products with brand watermark overlay.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.black54, fontSize: 11),
                  ),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filtered.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final item = filtered[index];
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: item.isAvailable ? const Color(0xFFFAFAFA) : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: item.isAvailable ? Colors.amber.shade300 : Colors.grey.shade300,
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Product Thumbnail with Brand Logo Overlay Watermark
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: SizedBox(
                          width: 72,
                          height: 72,
                          child: BrandLogoOverlayWidget(
                            brandText: 'PCM',
                            logoSize: 12,
                            child: _buildItemThumbnail(item.imageUrl, width: 72, height: 72),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Item Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryButton.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      item.category.toUpperCase(),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 9,
                                        color: AppColors.primaryButton,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                if (item.rate > 0)
                                  Text(
                                    '₹${CalculatorUtils.formatIndianCurrency(item.rate)} / ${item.unit}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 11,
                                      color: AppColors.resultGreen,
                                    ),
                                  ),
                                const Spacer(),
                                IconButton(
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                  icon: const Icon(Icons.edit, size: 17, color: AppColors.border),
                                  tooltip: 'Edit Item',
                                  onPressed: () => _showAddEditCatalogDialog(existingItem: item),
                                ),
                                IconButton(
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                  icon: const Icon(Icons.delete_outline, size: 17, color: Colors.redAccent),
                                  tooltip: 'Delete Item',
                                  onPressed: () async {
                                    await CatalogService.instance.deleteItem(item.id);
                                    await _loadCatalog();
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: Color(0xFF2D1E18),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item.description,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade700,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

          const SizedBox(height: 16),

          // Bottom Action Sync Button
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _handleSyncToPortal,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.cloud_upload_rounded, size: 18),
                  label: Text(
                    _isSaving ? 'SYNCING CATALOG TO PORTAL...' : 'SAVE & SYNC CATALOG TO PORTAL',
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 0.5),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.border,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 2,
                  ),
                ),
              ),
            ],
          ),

          if (_lastSyncedTime != null) ...[
            const SizedBox(height: 8),
            Center(
              child: Text(
                'Last synced: ${_lastSyncedTime!.hour.toString().padLeft(2, '0')}:${_lastSyncedTime!.minute.toString().padLeft(2, '0')}:${_lastSyncedTime!.second.toString().padLeft(2, '0')} • Catalog items active live on pcm-wayanad-portal.vercel.app',
                style: TextStyle(fontSize: 10, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
