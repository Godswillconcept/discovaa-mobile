import 'package:discovaa/features/profile/domain/entities/artisan_entity.dart';
import 'package:discovaa/features/profile/presentation/widgets/network_image_with_fallback.dart';
import 'package:flutter/material.dart';

class ArtisanGallery extends StatelessWidget {
  final Artisan artisan;

  const ArtisanGallery({super.key, required this.artisan});

  @override
  Widget build(BuildContext context) {
    final images = artisan.galleryImages;
    if (images.isEmpty) return const SizedBox.shrink();

    final imageCount = images.length;

    // Single image: display full width
    if (imageCount == 1) {
      return _buildGalleryImage(images[0]);
    }

    // Multiple images: 50/50 split layout
    final remainingImages = images.skip(1).toList();
    return Row(
      children: [
        // Left side: First image (50% width)
        Expanded(child: _buildGalleryImage(images[0])),
        const SizedBox(width: 10),
        // Right side: Grid of remaining images (50% width)
        Expanded(child: _buildRemainingImagesGrid(remainingImages)),
      ],
    );
  }

  Widget _buildRemainingImagesGrid(List<String> images) {
    final count = images.length;
    final columns = _calculateGridColumns(count);

    return GridView.count(
      crossAxisCount: columns,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.0,
      children: images.map((image) => _buildGalleryImage(image)).toList(),
    );
  }

  int _calculateGridColumns(int imageCount) {
    if (imageCount <= 1) return 1;
    if (imageCount <= 2) return 2;
    if (imageCount <= 4) return 2;
    // For 5+ images, calculate dynamically to fit all
    // Aim for roughly square aspect ratio
    return ((imageCount + 1) / 2).ceil();
  }

  Widget _buildGalleryImage(String imagePath) {
    final fallbackAsset = imagePath.startsWith('assets/')
        ? imagePath
        : 'assets/images/placeholders/gallery.png';

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: AspectRatio(
        aspectRatio: 1.0,
        child: NetworkImageWithFallback(
          imageUrl: imagePath,
          fallbackAsset: fallbackAsset,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
