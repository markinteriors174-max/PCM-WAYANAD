import 'package:flutter/material.dart';
import '../models/promo_banner_model.dart';
import 'brand_logo_overlay_widget.dart';

class PromoBannerCarouselWidget extends StatefulWidget {
  final bool isAdminMode;
  final VoidCallback? onBannersUpdated;

  const PromoBannerCarouselWidget({
    super.key,
    this.isAdminMode = true,
    this.onBannersUpdated,
  });

  @override
  State<PromoBannerCarouselWidget> createState() => _PromoBannerCarouselWidgetState();
}

class _PromoBannerCarouselWidgetState extends State<PromoBannerCarouselWidget> {
  List<PromoBannerModel> _banners = [];
  int _currentPage = 0;
  final PageController _pageController = PageController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBanners();
  }

  Future<void> _loadBanners() async {
    final loaded = await PromoBannerService.instance.loadBanners();
    if (mounted) {
      setState(() {
        _banners = loaded;
        _isLoading = false;
      });
    }
  }

  void _showAddEditBannerDialog({PromoBannerModel? existingBanner}) {
    final isEdit = existingBanner != null;
    final tagCtrl = TextEditingController(text: existingBanner?.tag ?? 'PCM WAYANAD SPECIAL');
    final titleCtrl = TextEditingController(text: existingBanner?.title ?? '');
    final subtitleCtrl = TextEditingController(text: existingBanner?.subtitle ?? '');
    final actionCtrl = TextEditingController(text: existingBanner?.actionText ?? 'EXPLORE');
    final targetCtrl = TextEditingController(text: existingBanner?.targetUrl ?? '');
    bool isActive = existingBanner?.isActive ?? true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF0F172A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFF38BDF8), width: 1.5),
          ),
          title: Row(
            children: [
              const Icon(Icons.campaign, color: Color(0xFF38BDF8), size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isEdit ? 'Edit Promotional Ad' : '+ Add Unlimited Ad / Banner',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
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
                const Text('Tag / Badge Label:', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                const SizedBox(height: 4),
                TextField(
                  controller: tagCtrl,
                  decoration: _inputDeco('e.g. PCM WAYANAD SPECIAL'),
                ),
                const SizedBox(height: 10),
                const Text('Main Headline / Title:', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                const SizedBox(height: 4),
                TextField(
                  controller: titleCtrl,
                  decoration: _inputDeco('e.g. New Residential Project Live'),
                ),
                const SizedBox(height: 10),
                const Text('Subtitle / Description:', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                const SizedBox(height: 4),
                TextField(
                  controller: subtitleCtrl,
                  maxLines: 2,
                  decoration: _inputDeco('e.g. Track your ceiling progress in real-time.'),
                ),
                const SizedBox(height: 10),
                const Text('Action Button Label (Optional):', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                const SizedBox(height: 4),
                TextField(
                  controller: actionCtrl,
                  decoration: _inputDeco('e.g. EXPLORE NOW'),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Text('Active Banner:', style: TextStyle(fontSize: 12, color: Colors.white)),
                    const Spacer(),
                    Switch(
                      value: isActive,
                      activeColor: const Color(0xFF38BDF8),
                      onChanged: (val) => setDialogState(() => isActive = val),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('CANCEL', style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF38BDF8),
                foregroundColor: Colors.black,
              ),
              icon: Icon(isEdit ? Icons.save : Icons.add, size: 16),
              label: Text(isEdit ? 'SAVE CHANGES' : 'ADD AD', style: const TextStyle(fontWeight: FontWeight.bold)),
              onPressed: () async {
                final tag = tagCtrl.text.trim();
                final title = titleCtrl.text.trim();
                final subtitle = subtitleCtrl.text.trim();
                if (title.isNotEmpty) {
                  final newBanner = PromoBannerModel(
                    id: isEdit ? existingBanner.id : 'banner_${DateTime.now().millisecondsSinceEpoch}',
                    tag: tag.isNotEmpty ? tag : 'PCM WAYANAD SPECIAL',
                    title: title,
                    subtitle: subtitle.isNotEmpty ? subtitle : 'Special offer for your ceiling project.',
                    actionText: actionCtrl.text.trim().isNotEmpty ? actionCtrl.text.trim() : null,
                    targetUrl: targetCtrl.text.trim().isNotEmpty ? targetCtrl.text.trim() : null,
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
                    if (widget.onBannersUpdated != null) widget.onBannersUpdated!();
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showBannerManagerModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          height: MediaQuery.of(ctx).size.height * 0.75,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.campaign, color: Color(0xFFF59E0B), size: 22),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Promotional Ads & Banners Manager',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle, color: Color(0xFF38BDF8), size: 26),
                    tooltip: 'Add Unlimited Banner',
                    onPressed: () {
                      Navigator.pop(ctx);
                      _showAddEditBannerDialog();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Divider(color: Colors.white24),
              Expanded(
                child: _banners.isEmpty
                    ? const Center(child: Text('No banners added yet. Tap + to add one!', style: TextStyle(color: Colors.white54)))
                    : ListView.builder(
                        itemCount: _banners.length,
                        itemBuilder: (ctx, index) {
                          final b = _banners[index];
                          return Card(
                            color: const Color(0xFF1E293B),
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: Icon(
                                b.isActive ? Icons.visibility : Icons.visibility_off,
                                color: b.isActive ? const Color(0xFF38BDF8) : Colors.white38,
                              ),
                              title: Text(
                                b.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              subtitle: Text(
                                '${b.tag} • ${b.subtitle}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Color(0xFFF59E0B), size: 18),
                                    onPressed: () {
                                      Navigator.pop(ctx);
                                      _showAddEditBannerDialog(existingBanner: b);
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.redAccent, size: 18),
                                    onPressed: () async {
                                      await PromoBannerService.instance.deleteBanner(b.id);
                                      await _loadBanners();
                                      setModalState(() {});
                                      if (widget.onBannersUpdated != null) widget.onBannersUpdated!();
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDeco(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white38, fontSize: 11),
      filled: true,
      fillColor: const Color(0xFF1E293B),
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(height: 120, child: Center(child: CircularProgressIndicator(color: Color(0xFF38BDF8))));
    }

    final activeList = _banners.where((b) => b.isActive).toList();
    final displayList = activeList.isNotEmpty ? activeList : _banners;

    if (displayList.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Expanded(
              child: Text(
                'PROMOTIONAL ANNOUNCEMENTS',
                style: TextStyle(color: Color(0xFF38BDF8), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (widget.isAdminMode)
              InkWell(
                onTap: _showBannerManagerModal,
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  child: Row(
                    children: [
                      Icon(Icons.tune, color: Color(0xFFF59E0B), size: 14),
                      SizedBox(width: 4),
                      Text('Manage Ads', style: TextStyle(color: Color(0xFFF59E0B), fontSize: 10, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 115,
          child: PageView.builder(
            controller: _pageController,
            itemCount: displayList.length,
            onPageChanged: (idx) => setState(() => _currentPage = idx),
            itemBuilder: (context, index) {
              final banner = displayList[index];
              return BrandLogoOverlayWidget(
                brandText: 'PCM WAYANAD',
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1E3A8A), Color(0xFF0F172A)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.6), width: 1.2),
                    boxShadow: const [
                      BoxShadow(color: Colors.black45, blurRadius: 8, offset: Offset(0, 3))
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF38BDF8).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: const Color(0xFF38BDF8), width: 0.8),
                            ),
                            child: Text(
                              banner.tag.toUpperCase(),
                              style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 8.5, fontWeight: FontWeight.w900),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        banner.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      Text(
                        banner.subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10.5),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        if (displayList.length > 1) ...[
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(displayList.length, (i) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: _currentPage == i ? 14 : 6,
                height: 5,
                decoration: BoxDecoration(
                  color: _currentPage == i ? const Color(0xFF38BDF8) : Colors.white24,
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }),
          ),
        ],
      ],
    );
  }
}
