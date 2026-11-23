import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../models/promo_banner_model.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/brand_logo_overlay_widget.dart';

class AdminSiteAdsCard extends StatefulWidget {
  const AdminSiteAdsCard({super.key});

  @override
  State<AdminSiteAdsCard> createState() => _AdminSiteAdsCardState();
}

class _AdminSiteAdsCardState extends State<AdminSiteAdsCard> {
  List<PromoBannerModel> _banners = [];
  bool _isLoading = true;
  bool _isSaving = false;
  DateTime? _lastSyncedTime;

  static const List<Map<String, String>> _presetImages = [
    {
      'title': 'Gypsum False Ceiling',
      'url': 'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?q=80&w=800&auto=format&fit=crop',
    },
    {
      'title': 'Cove & LED Lighting',
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
    _loadBanners();
  }

  Future<void> _loadBanners() async {
    final loaded = await PromoBannerService.instance.loadBanners();
    if (mounted) {
      setState(() {
        _banners = List.from(loaded);
        _isLoading = false;
      });
    }
  }

  Future<void> _handleSyncToPortal() async {
    setState(() => _isSaving = true);
    await PromoBannerService.instance.saveBanners(_banners);
    final success = await PromoBannerService.instance.syncBannersToFirestore();

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
                      ? 'Site ads & images synced to Web Portal (pcm-wayanad-portal.vercel.app) & Cloud!'
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

  Future<String?> _pickImageFromDevice(ImageSource source) async {
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
      debugPrint('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error selecting image: $e'), backgroundColor: Colors.red),
        );
      }
    }
    return null;
  }

  void _showQuickPhotoSwapSheet(PromoBannerModel banner) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.swap_horizontal_circle, color: AppColors.border, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Swap Photo: ${banner.title}',
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: AppColors.border),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    width: 70,
                    height: 70,
                    child: _buildBannerThumbnail(banner.imageUrl, width: 70, height: 70),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        banner.tag,
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primaryButton),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        banner.title,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        banner.imageUrl != null && banner.imageUrl!.isNotEmpty ? 'Photo active' : 'No photo assigned',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: AppColors.primaryButton,
                child: Icon(Icons.photo_library, color: Colors.white, size: 20),
              ),
              title: const Text('Pick Photo from Gallery', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              onTap: () async {
                if (ctx.mounted && Navigator.of(ctx).canPop()) Navigator.pop(ctx);
                final img = await _pickImageFromDevice(ImageSource.gallery);
                if (img != null) {
                  final updated = banner.copyWith(imageUrl: img);
                  await PromoBannerService.instance.updateBanner(updated);
                  await _loadBanners();
                  await _handleSyncToPortal();
                }
              },
            ),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: AppColors.border,
                child: Icon(Icons.camera_alt, color: Colors.white, size: 20),
              ),
              title: const Text('Take New Photo with Camera', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              onTap: () async {
                if (ctx.mounted && Navigator.of(ctx).canPop()) Navigator.pop(ctx);
                final img = await _pickImageFromDevice(ImageSource.camera);
                if (img != null) {
                  final updated = banner.copyWith(imageUrl: img);
                  await PromoBannerService.instance.updateBanner(updated);
                  await _loadBanners();
                  await _handleSyncToPortal();
                }
              },
            ),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.amber.shade700,
                child: const Icon(Icons.collections, color: Colors.white, size: 20),
              ),
              title: const Text('Choose Preset Ceiling Image', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              onTap: () {
                if (ctx.mounted && Navigator.of(ctx).canPop()) Navigator.pop(ctx);
                _showPresetChooserDialog(banner);
              },
            ),
            if (banner.imageUrl != null && banner.imageUrl!.isNotEmpty)
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.redAccent,
                  child: Icon(Icons.delete_forever, color: Colors.white, size: 20),
                ),
                title: const Text('Remove Assigned Photo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.redAccent)),
                onTap: () async {
                  if (ctx.mounted && Navigator.of(ctx).canPop()) Navigator.pop(ctx);
                  final updated = banner.copyWith(imageUrl: '');
                  await PromoBannerService.instance.updateBanner(updated);
                  await _loadBanners();
                  await _handleSyncToPortal();
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showPresetChooserDialog(PromoBannerModel banner) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Select Preset Ceiling Ad Image', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: _presetImages.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final preset = _presetImages[index];
              return InkWell(
                onTap: () async {
                  if (ctx.mounted && Navigator.of(ctx).canPop()) Navigator.pop(ctx);
                  final updated = banner.copyWith(imageUrl: preset['url']);
                  await PromoBannerService.instance.updateBanner(updated);
                  await _loadBanners();
                  await _handleSyncToPortal();
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.amber.shade300),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          preset['url']!,
                          width: 60,
                          height: 50,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          preset['title']!,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: AppColors.border),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (ctx.mounted && Navigator.of(ctx).canPop()) Navigator.pop(ctx);
            },
            child: const Text('CANCEL'),
          ),
        ],
      ),
    );
  }

  void _showAddEditAdDialog({PromoBannerModel? existingBanner}) {
    final isEdit = existingBanner != null;
    final tagCtrl = TextEditingController(text: existingBanner?.tag ?? 'PCM WAYANAD SPECIAL');
    final titleCtrl = TextEditingController(text: existingBanner?.title ?? '');
    final subtitleCtrl = TextEditingController(text: existingBanner?.subtitle ?? '');
    final actionCtrl = TextEditingController(text: existingBanner?.actionText ?? 'EXPLORE NOW');
    final targetCtrl = TextEditingController(text: existingBanner?.targetUrl ?? '');
    final imageCtrl = TextEditingController(text: existingBanner?.imageUrl ?? '');
    bool isActive = existingBanner?.isActive ?? true;

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
                const Icon(Icons.campaign_rounded, color: AppColors.border, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isEdit ? 'Edit Site Ad / Banner' : '+ Add Unlimited Site Ad',
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
                  // Photo Selection & Preview Section
                  _buildFieldLabel('Ad Banner Photo / Image:'),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
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
                            height: 110,
                            child: _buildBannerThumbnail(currentPhoto, width: double.infinity, height: 110),
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
                                final img = await _pickImageFromDevice(ImageSource.gallery);
                                if (img != null) {
                                  setDialogState(() {
                                    imageCtrl.text = img;
                                  });
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
                                final img = await _pickImageFromDevice(ImageSource.camera);
                                if (img != null) {
                                  setDialogState(() {
                                    imageCtrl.text = img;
                                  });
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
                                  builder: (presetCtx) => AlertDialog(
                                    title: const Text('Pick Preset Image', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
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
                                              Navigator.pop(presetCtx);
                                              setDialogState(() {
                                                imageCtrl.text = p['url']!;
                                              });
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
                                onPressed: () {
                                  setDialogState(() {
                                    imageCtrl.clear();
                                  });
                                },
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  _buildFieldLabel('Badge / Tag Label:'),
                  TextField(
                    controller: tagCtrl,
                    textCapitalization: TextCapitalization.characters,
                    decoration: AppStyles.inputDecoration('e.g. PCM WAYANAD SPECIAL'),
                  ),
                  const SizedBox(height: 12),

                  _buildFieldLabel('Headline / Main Title:'),
                  TextField(
                    controller: titleCtrl,
                    textCapitalization: TextCapitalization.words,
                    decoration: AppStyles.inputDecoration('e.g. New Residential Project Live Now'),
                  ),
                  const SizedBox(height: 12),

                  _buildFieldLabel('Description / Subtitle:'),
                  TextField(
                    controller: subtitleCtrl,
                    maxLines: 2,
                    decoration: AppStyles.inputDecoration('e.g. Track your ceiling progress in real-time.'),
                  ),
                  const SizedBox(height: 12),

                  _buildFieldLabel('CTA Button Label (Optional):'),
                  TextField(
                    controller: actionCtrl,
                    textCapitalization: TextCapitalization.characters,
                    decoration: AppStyles.inputDecoration('e.g. EXPLORE NOW'),
                  ),
                  const SizedBox(height: 12),

                  _buildFieldLabel('Target Link / CTA URL (Optional):'),
                  TextField(
                    controller: targetCtrl,
                    keyboardType: TextInputType.url,
                    decoration: AppStyles.inputDecoration('e.g. https://pcm-wayanad-portal.vercel.app'),
                  ),
                  const SizedBox(height: 12),

                  _buildFieldLabel('Or Manual Image URL / Base64:'),
                  TextField(
                    controller: imageCtrl,
                    onChanged: (_) => setDialogState(() {}),
                    decoration: AppStyles.inputDecoration('e.g. https://... or Base64 string'),
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
                          'Active Status:',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.border),
                        ),
                        const Spacer(),
                        Switch(
                          value: isActive,
                          activeColor: AppColors.resultGreen,
                          onChanged: (val) => setDialogState(() => isActive = val),
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
                  isEdit ? 'SAVE CHANGES' : 'ADD AD',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                onPressed: () async {
                  final tag = tagCtrl.text.trim();
                  final title = titleCtrl.text.trim();
                  final subtitle = subtitleCtrl.text.trim();

                  if (title.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter a headline/title for the ad.'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  final newBanner = PromoBannerModel(
                    id: isEdit ? existingBanner.id : 'banner_${DateTime.now().millisecondsSinceEpoch}',
                    tag: tag.isNotEmpty ? tag : 'PCM WAYANAD SPECIAL',
                    title: title,
                    subtitle: subtitle.isNotEmpty ? subtitle : 'Special offer for your ceiling project.',
                    actionText: actionCtrl.text.trim().isNotEmpty ? actionCtrl.text.trim() : null,
                    targetUrl: targetCtrl.text.trim().isNotEmpty ? targetCtrl.text.trim() : null,
                    imageUrl: imageCtrl.text.trim().isNotEmpty ? imageCtrl.text.trim() : null,
                    isActive: isActive,
                  );

                  if (isEdit) {
                    await PromoBannerService.instance.updateBanner(newBanner);
                  } else {
                    await PromoBannerService.instance.addBanner(newBanner);
                  }

                  if (mounted) {
                    Navigator.pop(ctx);
                    await _loadBanners();
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

  Widget _buildBannerThumbnail(String? photoData, {double width = 56, double height = 56}) {
    final clean = photoData?.trim() ?? '';

    final fallback = Container(
      width: width,
      height: height,
      color: Colors.amber.shade100.withAlpha(120),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.photo_size_select_actual_outlined, color: AppColors.border, size: 22),
          SizedBox(height: 2),
          Text('No Photo', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: AppColors.border)),
        ],
      ),
    );

    if (clean.isEmpty) return fallback;

    // 1. Network image
    if (clean.startsWith('http://') || clean.startsWith('https://')) {
      return Image.network(
        clean,
        width: width,
        height: height,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) => progress == null
            ? child
            : Container(
                width: width,
                height: height,
                color: Colors.grey.shade200,
                child: const Center(
                  child: SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.border)),
                ),
              ),
        errorBuilder: (_, __, ___) => fallback,
      );
    }

    // 2. Base64 data string
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

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        label,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.labelColor),
      ),
    );
  }

  Future<void> _handleResetDefaults() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Site Ads to Defaults?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text(
          'This will restore standard PCM Wayanad promotional banners and sync them live to the portal.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber.shade800,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('RESET DEFAULTS'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final defaults = [
        const PromoBannerModel(
          id: 'banner_1',
          tag: 'PCM WAYANAD SPECIAL',
          title: 'New Residential Project Live Now',
          subtitle: 'Track your ceiling & gypsum progress in real-time.',
          actionText: 'EXPLORE NOW',
          imageUrl: 'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?q=80&w=800&auto=format&fit=crop',
          isActive: true,
        ),
        const PromoBannerModel(
          id: 'banner_2',
          tag: 'DISCOUNT OFFER',
          title: 'Premium Gyproc Material Offer',
          subtitle: 'Get 10% off on Saint-Gobain Gyproc ceiling packages.',
          actionText: 'GET QUOTE',
          imageUrl: 'https://images.unsplash.com/photo-1600607687939-ce8a6c25118c?q=80&w=800&auto=format&fit=crop',
          isActive: true,
        ),
      ];
      await PromoBannerService.instance.saveBanners(defaults);
      await _loadBanners();
      await _handleSyncToPortal();
    }
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

    final activeCount = _banners.where((b) => b.isActive).length;

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
          // Header Row
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
                  Icons.campaign_rounded,
                  color: AppColors.border,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'SITE ADS & BANNERS MANAGER',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF3E2723),
                        letterSpacing: 0.8,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Promotional Banners for Web Portal & Mobile App ($activeCount Active / ${_banners.length} Total)',
                      style: const TextStyle(
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
              const SizedBox(width: 8),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryButton,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 1,
                ),
                icon: const Icon(Icons.add, size: 16),
                label: const Text(
                  '+ ADD SITE AD',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                ),
                onPressed: () => _showAddEditAdDialog(),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 14),

          // Banner Ads List (Unlimited)
          if (_banners.isEmpty)
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
                  const Icon(Icons.campaign_outlined, size: 40, color: Colors.grey),
                  const SizedBox(height: 8),
                  const Text(
                    'No Site Ads Created Yet',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Tap "+ ADD SITE AD" above to create live promotional banners for the website portal.',
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
              itemCount: _banners.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final banner = _banners[index];
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: banner.isActive ? const Color(0xFFFAFAFA) : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: banner.isActive ? Colors.amber.shade300 : Colors.grey.shade300,
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Thumbnail preview with quick photo swap affordance
                      GestureDetector(
                        onTap: () => _showQuickPhotoSwapSheet(banner),
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: BrandLogoOverlayWidget(
                                brandText: 'PCM',
                                logoSize: 10,
                                child: _buildBannerThumbnail(banner.imageUrl, width: 68, height: 68),
                              ),
                            ),
                            Positioned(
                              right: 2,
                              bottom: 2,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: AppColors.border,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.add_a_photo, color: Colors.white, size: 10),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Main Banner Content
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryButton.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      banner.tag.toUpperCase(),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 9.5,
                                        color: AppColors.primaryButton,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: banner.isActive ? Colors.green.shade50 : Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: banner.isActive ? Colors.green.shade300 : Colors.grey.shade400,
                                    ),
                                  ),
                                  child: Text(
                                    banner.isActive ? 'LIVE' : 'INACTIVE',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 9,
                                      color: banner.isActive ? Colors.green.shade800 : Colors.grey.shade700,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                // Active Switch
                                Switch(
                                  value: banner.isActive,
                                  activeColor: AppColors.resultGreen,
                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  onChanged: (val) async {
                                    final updated = banner.copyWith(isActive: val);
                                    await PromoBannerService.instance.updateBanner(updated);
                                    await _loadBanners();
                                  },
                                ),
                                const SizedBox(width: 2),
                                // Edit Button
                                IconButton(
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                  icon: const Icon(Icons.edit, size: 17, color: AppColors.border),
                                  tooltip: 'Edit Ad',
                                  onPressed: () => _showAddEditAdDialog(existingBanner: banner),
                                ),
                                // Delete Button
                                IconButton(
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                  icon: const Icon(Icons.delete_outline, size: 17, color: Colors.redAccent),
                                  tooltip: 'Delete Ad',
                                  onPressed: () async {
                                    await PromoBannerService.instance.deleteBanner(banner.id);
                                    await _loadBanners();
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              banner.title,
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
                              banner.subtitle,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade700,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (banner.actionText != null && banner.actionText!.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(Icons.touch_app, size: 12, color: AppColors.primaryButton),
                                  const SizedBox(width: 4),
                                  Text(
                                    'CTA: ${banner.actionText}',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primaryButton,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

          const SizedBox(height: 16),

          // Bottom Action Row
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: _isSaving ? null : _handleResetDefaults,
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('DEFAULTS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.brown,
                  side: BorderSide(color: Colors.brown.shade300),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(width: 10),
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
                    _isSaving ? 'SYNCING TO PORTAL...' : 'SAVE & SYNC TO PORTAL',
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
                'Last synced: ${_lastSyncedTime!.hour.toString().padLeft(2, '0')}:${_lastSyncedTime!.minute.toString().padLeft(2, '0')}:${_lastSyncedTime!.second.toString().padLeft(2, '0')} • Site banners & images active live on pcm-wayanad-portal.vercel.app',
                style: TextStyle(fontSize: 10, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
