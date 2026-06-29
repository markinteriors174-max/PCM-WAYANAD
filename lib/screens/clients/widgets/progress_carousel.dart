import 'package:flutter/material.dart';
import '../../../services/client_service.dart';
import '../../../theme/app_theme.dart';

class ProgressCarousel extends StatefulWidget {
  final String siteId;

  const ProgressCarousel({super.key, required this.siteId});

  @override
  State<ProgressCarousel> createState() => _ProgressCarouselState();
}

class _ProgressCarouselState extends State<ProgressCarousel> {
  List<String> _photos = [];
  bool _isLoading = true;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadPhotos();
  }

  Future<void> _loadPhotos() async {
    try {
      final list = await ClientService.instance.fetchProjectPhotos(widget.siteId);
      if (mounted) {
        setState(() {
          _photos = list;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(height: 120, child: Center(child: CircularProgressIndicator(color: AppColors.border)));
    }
    if (_photos.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        SizedBox(
          height: 120,
          child: PageView.builder(
            itemCount: _photos.length,
            onPageChanged: (index) {
              setState(() => _currentIndex = index);
            },
            itemBuilder: (context, index) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.black12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    _photos[index],
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return const Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.border));
                    },
                    errorBuilder: (context, error, stackTrace) => const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _photos.length,
            (index) => Container(
              width: 6,
              height: 6,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _currentIndex == index ? AppColors.border : Colors.black12,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }
}
