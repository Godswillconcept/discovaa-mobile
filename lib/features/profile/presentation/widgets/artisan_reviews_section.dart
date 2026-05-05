import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:discovaa/features/profile/domain/entities/artisan_entity.dart';
import 'package:discovaa/features/profile/presentation/widgets/network_image_with_fallback.dart';

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
        if (widget.artisan.reviews.isNotEmpty)
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
        const SizedBox(height: 8),
        TextButton(
          onPressed: () {},
          child: Text('See all ${widget.artisan.reviewsCount} Reviews'),
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
