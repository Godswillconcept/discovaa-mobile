import 'package:discovaa/app/router/route_names.dart';
import 'package:discovaa/features/messaging/domain/entities/conversation.dart';
import 'package:discovaa/features/messaging/presentation/providers/messaging_provider.dart';
import 'package:discovaa/features/profile/presentation/providers/artisan_provider.dart';
import 'package:discovaa/features/profile/presentation/widgets/booking_flow_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:go_router/go_router.dart';

/// Helper widget to display an image from URL with asset fallback
class NetworkImageWithFallback extends StatelessWidget {
  final String? imageUrl;
  final String fallbackAsset;
  final BoxFit fit;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  const NetworkImageWithFallback({
    super.key,
    required this.imageUrl,
    required this.fallbackAsset,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    Widget image;

    if (imageUrl != null && imageUrl!.isNotEmpty && _isValidUrl(imageUrl!)) {
      image = Image.network(
        imageUrl!,
        fit: fit,
        width: width,
        height: height,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return _buildPlaceholder();
        },
        errorBuilder: (context, error, stackTrace) {
          return Image.asset(
            fallbackAsset,
            fit: fit,
            width: width,
            height: height,
          );
        },
      );
    } else {
      image = Image.asset(
        fallbackAsset,
        fit: fit,
        width: width,
        height: height,
      );
    }

    if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius!, child: image);
    }

    return image;
  }

  bool _isValidUrl(String url) {
    return url.startsWith('http://') || url.startsWith('https://');
  }

  Widget _buildPlaceholder() {
    return Container(
      width: width,
      height: height,
      color: Colors.grey.shade200,
      child: const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}

/// Get a deterministic placeholder asset path for an artisan
String getArtisanPlaceholder(String seed) {
  const count = 8;
  final sum = seed.codeUnits.fold<int>(0, (a, b) => a + b);
  final index = (sum % count) + 1;
  final two = index.toString().padLeft(2, '0');
  return 'assets/images/placeholders/artisan_$two.png';
}

class ArtisanProfileHeader extends ConsumerWidget {
  final Artisan artisan;

  const ArtisanProfileHeader({super.key, required this.artisan});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    artisan.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (artisan.isVerified)
                    const Icon(
                      Icons.verified_user,
                      color: Colors.amber,
                      size: 20,
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  RatingBarIndicator(
                    rating: artisan.rating,
                    itemBuilder: (context, index) =>
                        const Icon(Icons.star, color: Colors.amber),
                    itemCount: 5,
                    itemSize: 18.0,
                    unratedColor: Colors.amber.withValues(alpha: 0.2),
                    direction: Axis.horizontal,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${artisan.rating} (${artisan.reviewsCount} Reviews)',
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${artisan.location} • ISV${artisan.id}12345',
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ],
          ),
        ),
        Column(
          children: [
            ElevatedButton(
              onPressed: () => _showBookingModal(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24),
              ),
              child: const Text('Book Now'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () {
                final messagingState = ref.read(messagingProvider);
                final conversation = messagingState.conversations.firstWhere(
                  (c) => c.artisanId == artisan.id,
                  orElse: () => Conversation(
                    id: 'temp_${artisan.id}',
                    artisanId: artisan.id,
                    artisanName: artisan.name,
                    artisanAvatar: artisan.profileImage,
                    lastMessage: '',
                    lastMessageTime: DateTime.now(),
                    yearsInBusiness: artisan.yearsInBusiness,
                    hiresCount: artisan.hiresCount,
                  ),
                );
                context.push(
                  '${RouteNames.messages}/chat',
                  extra: conversation,
                );
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.black),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24),
              ),
              child: const Text(
                'Message',
                style: TextStyle(color: Colors.black),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showBookingModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const Dialog(
        backgroundColor: Colors.transparent,
        child: BookingFlowModal(),
      ),
    );
  }
}

class ArtisanGallery extends StatelessWidget {
  final Artisan artisan;

  const ArtisanGallery({super.key, required this.artisan});

  @override
  Widget build(BuildContext context) {
    final images = artisan.galleryImages;
    if (images.isEmpty) return const SizedBox.shrink();

    final imageCount = images.length;
    final crossAxisCount = imageCount == 1
        ? 1
        : imageCount == 2
        ? 2
        : 3;

    return StaggeredGrid.count(
      crossAxisCount: crossAxisCount,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      children: [
        if (imageCount == 1)
          StaggeredGridTile.count(
            crossAxisCellCount: 1,
            mainAxisCellCount: 1,
            child: _buildGalleryImage(images[0]),
          )
        else if (imageCount == 2) ...[
          StaggeredGridTile.count(
            crossAxisCellCount: 1,
            mainAxisCellCount: 1,
            child: _buildGalleryImage(images[0]),
          ),
          StaggeredGridTile.count(
            crossAxisCellCount: 1,
            mainAxisCellCount: 1,
            child: _buildGalleryImage(images[1]),
          ),
        ] else ...[
          // 3 or more images: 2x2 for the first, 1x1 for the rest
          StaggeredGridTile.count(
            crossAxisCellCount: 2,
            mainAxisCellCount: 2,
            child: _buildGalleryImage(images[0]),
          ),
          ...images
              .skip(1)
              .map(
                (image) => StaggeredGridTile.count(
                  crossAxisCellCount: 1,
                  mainAxisCellCount: 1,
                  child: _buildGalleryImage(image),
                ),
              ),
        ],
      ],
    );
  }

  Widget _buildGalleryImage(String imagePath) {
    final fallbackAsset = imagePath.startsWith('assets/')
        ? imagePath
        : 'assets/images/placeholders/gallery.png';

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: NetworkImageWithFallback(
        imageUrl: imagePath.startsWith('http') ? imagePath : null,
        fallbackAsset: fallbackAsset,
        fit: BoxFit.cover,
      ),
    );
  }
}

class ArtisanBusinessInfo extends StatelessWidget {
  final Artisan artisan;

  const ArtisanBusinessInfo({super.key, required this.artisan});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBFF),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Flexible(
                child: Text(
                  'ISV ${artisan.category} Services : ${artisan.name}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    overflow: TextOverflow.ellipsis,
                  ),
                  maxLines: 1,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.verified_user, color: Colors.amber, size: 16),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${artisan.yearsInBusiness} years in business',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const Text(' • ', style: TextStyle(color: Colors.grey)),
              Text(
                '${artisan.hiresCount} hires on Discovaa',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
          const Divider(),
        ],
      ),
    );
  }
}

class ArtisanServicesSection extends StatelessWidget {
  final Artisan artisan;

  const ArtisanServicesSection({super.key, required this.artisan});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Services',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 30,
          runSpacing: 10,
          children: artisan.services
              .map(
                (s) => Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.circle, size: 6, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      s,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              )
              .toList(),
        ),
        const Divider(),
      ],
    );
  }
}

class ArtisanPricesDropdown extends StatefulWidget {
  final Artisan artisan;
  const ArtisanPricesDropdown({super.key, required this.artisan});

  @override
  State<ArtisanPricesDropdown> createState() => _ArtisanPricesDropdownState();
}

class _ArtisanPricesDropdownState extends State<ArtisanPricesDropdown> {
  bool _isExpanded = false;
  final Set<String> _selectedServices = {'Plumbing', 'Water heater'};

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Prices',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: () => setState(() => _isExpanded = !_isExpanded),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _selectedServices.isEmpty
                      ? 'Select services'
                      : _selectedServices.join(', '),
                  style: const TextStyle(color: Colors.black87),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Icon(
                  _isExpanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: Colors.black,
                ),
              ],
            ),
          ),
        ),
        if (_isExpanded)
          Container(
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: widget.artisan.services.map((service) {
                final isSelected = _selectedServices.contains(service);
                return InkWell(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selectedServices.remove(service);
                      } else {
                        _selectedServices.add(service);
                      }
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: isSelected ? Colors.black : Colors.grey,
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: isSelected
                              ? const Icon(
                                  Icons.check,
                                  size: 14,
                                  color: Colors.black,
                                )
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Text(service, style: const TextStyle(fontSize: 14)),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Hourly rate', style: TextStyle(color: Colors.grey)),
            Text(
              '€${widget.artisan.hourlyRate.toInt()}/hour',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Price range for a project',
              style: TextStyle(color: Colors.grey),
            ),
            Text(
              widget.artisan.priceRange,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Divider(),
      ],
    );
  }
}

class ArtisanQualificationsSection extends StatelessWidget {
  final Artisan artisan;

  const ArtisanQualificationsSection({super.key, required this.artisan});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Certifications and Qualifications',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 20,
          runSpacing: 10,
          children: artisan.certifications
              .map(
                (c) => Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.circle, size: 6, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      c,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 16),
        const Divider(),
      ],
    );
  }
}

class ArtisanAvailabilitySection extends StatelessWidget {
  final Artisan artisan;

  const ArtisanAvailabilitySection({super.key, required this.artisan});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Available Dates and Time',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ...artisan.availability.entries.map(
          (e) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                const Icon(Icons.circle, size: 6, color: Colors.grey),
                const SizedBox(width: 8),
                Text(e.key, style: const TextStyle(color: Colors.grey)),
                const SizedBox(width: 12),
                Text(e.value, style: const TextStyle(color: Colors.black87)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Divider(),
      ],
    );
  }
}

class ArtisanReviewsSection extends StatefulWidget {
  final Artisan artisan;

  const ArtisanReviewsSection({super.key, required this.artisan});

  @override
  State<ArtisanReviewsSection> createState() => _ArtisanReviewsSectionState();
}

class _ArtisanReviewsSectionState extends State<ArtisanReviewsSection> {
  int _currentReviewIndex = 0;
  late PageController _reviewPageController;

  @override
  void initState() {
    super.initState();
    _reviewPageController = PageController(viewportFraction: 0.9);
  }

  @override
  void dispose() {
    _reviewPageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.artisan.reviews.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Ratings and Reviews',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Row(
              children: [
                RatingBarIndicator(
                  rating: widget.artisan.rating,
                  itemBuilder: (context, index) =>
                      const Icon(Icons.star, color: Colors.amber),
                  itemCount: 5,
                  itemSize: 16.0,
                  unratedColor: Colors.amber.withValues(alpha: 0.2),
                  direction: Axis.horizontal,
                ),
                const SizedBox(width: 4),
                Text(
                  '${widget.artisan.rating} (${widget.artisan.reviewsCount})',
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 180,
          child: PageView.builder(
            controller: _reviewPageController,
            itemCount: widget.artisan.reviews.length,
            onPageChanged: (index) {
              setState(() {
                _currentReviewIndex = index;
              });
            },
            itemBuilder: (context, index) {
              final review = widget.artisan.reviews[index];
              return Padding(
                padding: const EdgeInsets.only(right: 16),
                child: _buildReviewCard(context, review),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        if (widget.artisan.reviews.length > 1)
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(
                widget.artisan.reviews.length,
                (index) => Container(
                  width: _currentReviewIndex == index ? 20 : 8,
                  height: 4,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: _currentReviewIndex == index
                        ? Colors.black
                        : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildReviewCard(BuildContext context, Review review) {
    return Container(
      width: 300,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(32),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipOval(
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: NetworkImageWithFallback(
                    imageUrl: review.userAvatar.startsWith('http')
                        ? review.userAvatar
                        : null,
                    fallbackAsset: review.userAvatar.startsWith('assets/')
                        ? review.userAvatar
                        : 'assets/images/placeholders/user_avatar.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.userName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    RatingBarIndicator(
                      rating: review.rating,
                      itemBuilder: (context, index) =>
                          const Icon(Icons.star, color: Colors.amber),
                      itemCount: 5,
                      itemSize: 14.0,
                      unratedColor: Colors.amber.withValues(alpha: 0.2),
                      direction: Axis.horizontal,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    review.date,
                    style: const TextStyle(color: Colors.grey, fontSize: 11),
                  ),
                  const SizedBox(height: 15),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            review.comment,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.black87,
              height: 1.4,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
