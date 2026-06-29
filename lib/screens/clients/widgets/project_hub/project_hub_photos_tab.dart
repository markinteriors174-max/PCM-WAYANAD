import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';

class ProjectHubPhotosTab extends StatelessWidget {
  final List<String> photos;
  final bool isLoading;
  final bool isUploading;
  final Future<void> Function() onRefresh;
  final VoidCallback onShowUploadOptions;
  final Function(String) onViewImage;
  final bool canUpload;

  const ProjectHubPhotosTab({
    super.key,
    required this.photos,
    required this.isLoading,
    required this.isUploading,
    required this.onRefresh,
    required this.onShowUploadOptions,
    required this.onViewImage,
    required this.canUpload,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading && photos.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: AppColors.border));
    }

    return Stack(
      children: [
        photos.isEmpty
            ? _buildEmptyPhotosState()
            : RefreshIndicator(
                onRefresh: onRefresh,
                color: AppColors.border,
                child: GridView.builder(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 80),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 1.0,
                  ),
                  itemCount: photos.length,
                  itemBuilder: (context, index) {
                    final url = photos[index];
                    final isGalleryRef = url.toLowerCase().contains('/gallery_');
                    final isSelfie = url.toLowerCase().contains('/profile_');
                    
                    return GestureDetector(
                      onTap: () => onViewImage(url),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          color: Colors.white,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.network(
                                url,
                                fit: BoxFit.cover,
                                loadingBuilder: (context, child, progress) {
                                  if (progress == null) return child;
                                  return const Center(
                                    child: SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.border),
                                    ),
                                  );
                                },
                                errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, color: Colors.grey),
                              ),
                              Positioned(
                                top: 4,
                                right: 4,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.black54,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    isSelfie
                                        ? 'SELFIE'
                                        : (isGalleryRef ? 'REF' : 'SITE'),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 7.5,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              
        // Upload Overlay Loader
        if (isUploading)
          Container(
            color: Colors.black54,
            child: const Center(
              child: Card(
                color: Colors.white,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: AppColors.border),
                      SizedBox(width: 16),
                      Text(
                        'Uploading site progress image...',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.labelColor),
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),
          
        // Floating Action Button to Add/Upload photo (Restricted to Workers/Admin)
        if (canUpload)
          Positioned(
            bottom: 16,
            right: 16,
            child: FloatingActionButton.extended(
              backgroundColor: AppColors.border,
              foregroundColor: Colors.white,
              onPressed: onShowUploadOptions,
              icon: const Icon(Icons.add_a_photo),
              label: const Text('ADD PROGRESS', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11)),
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyPhotosState() {
    return Stack(
      children: [
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.photo_library_outlined, size: 48, color: Colors.black26),
              const SizedBox(height: 12),
              const Text(
                'No photos in vault',
                style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.labelColor, fontSize: 14),
              ),
              const SizedBox(height: 6),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  'Upload progress photos from the job site to share them instantly with the client.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black45, fontSize: 11),
                ),
              ),
            ],
          ),
        ),
        if (canUpload)
          Positioned(
            bottom: 16,
            right: 16,
            child: FloatingActionButton.extended(
              backgroundColor: AppColors.border,
              foregroundColor: Colors.white,
              onPressed: onShowUploadOptions,
              icon: const Icon(Icons.add_a_photo),
              label: const Text('ADD PROGRESS', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11)),
            ),
          ),
      ],
    );
  }
}
