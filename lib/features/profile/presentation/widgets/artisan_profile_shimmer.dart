import 'package:flutter/material.dart';
import 'package:discovaa/core/widgets/shimmer_loading.dart';

/// A pixel-accurate shimmer placeholder for the entire artisan profile page.
/// Matches the exact layout structure to prevent layout shifts when real data loads.
class ArtisanProfileShimmer extends StatelessWidget {
  const ArtisanProfileShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _ShimmerMainHeader(),
            const SizedBox(height: 16),
            const _ShimmerCustomHeader(),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ArtisanProfileHeaderShimmer(),
                  const SizedBox(height: 24),
                  const ArtisanGalleryShimmer(),
                ],
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
              decoration: const BoxDecoration(
                color: Color(0xFFF8FBFF),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  const ArtisanBusinessInfoShimmer(),
                  const SizedBox(height: 24),
                  const ArtisanServicesShimmer(),
                  const SizedBox(height: 24),
                  const ArtisanPricesDropdownShimmer(),
                  const SizedBox(height: 24),
                  const ArtisanQualificationsShimmer(),
                  const SizedBox(height: 24),
                  const ArtisanAvailabilityShimmer(),
                  const SizedBox(height: 24),
                  const ArtisanReviewsShimmer(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shimmer for MainHeader (simplified version)
class _ShimmerMainHeader extends StatelessWidget {
  const _ShimmerMainHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ShimmerCircle(size: 40, color: Colors.grey.shade300),
          Row(
            children: [
              ShimmerBox(width: 24, height: 24, color: Colors.grey.shade300),
              const SizedBox(width: 16),
              ShimmerBox(width: 24, height: 24, color: Colors.grey.shade300),
            ],
          ),
        ],
      ),
    );
  }
}

/// Shimmer for CustomHeader (simplified version)
class _ShimmerCustomHeader extends StatelessWidget {
  const _ShimmerCustomHeader();

  @override
  Widget build(BuildContext context) {
    return Container(height: 120, color: Colors.grey.shade300);
  }
}

/// Shimmer for ArtisanProfileHeader section
class ArtisanProfileHeaderShimmer extends StatelessWidget {
  const ArtisanProfileHeaderShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Profile image shimmer
        ShimmerCircle(size: 80, color: Colors.grey.shade300),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Name shimmer
              ShimmerTextLine(
                width: 200,
                height: 20,
                color: Colors.grey.shade300,
              ),
              const SizedBox(height: 8),
              // Rating shimmer
              Row(
                children: List.generate(
                  5,
                  (index) => Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: ShimmerBox(
                      width: 18,
                      height: 18,
                      color: Colors.grey.shade300,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Location shimmer
              ShimmerTextLine(
                width: 150,
                height: 14,
                color: Colors.grey.shade300,
              ),
              const SizedBox(height: 4),
              // Address shimmer
              ShimmerTextLine(
                width: 180,
                height: 14,
                color: Colors.grey.shade300,
              ),
              const SizedBox(height: 12),
              // Action buttons shimmer
              Row(
                children: [
                  Expanded(
                    child: ShimmerBox(
                      height: 40,
                      borderRadius: 8,
                      color: Colors.grey.shade300,
                    ),
                  ),
                  const SizedBox(width: 12),
                  ShimmerBox(
                    width: 48,
                    height: 40,
                    borderRadius: 8,
                    color: Colors.grey.shade300,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Shimmer for ArtisanGallery section
class ArtisanGalleryShimmer extends StatelessWidget {
  const ArtisanGalleryShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: 4,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) => ShimmerBox(
          width: 100,
          height: 100,
          borderRadius: 12,
          color: Colors.grey.shade300,
        ),
      ),
    );
  }
}

/// Shimmer for ArtisanBusinessInfo section
class ArtisanBusinessInfoShimmer extends StatelessWidget {
  const ArtisanBusinessInfoShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ShimmerTextLine(width: 120, height: 16, color: Colors.grey.shade300),
        const SizedBox(height: 12),
        ShimmerTextLine(
          width: double.infinity,
          height: 14,
          color: Colors.grey.shade300,
        ),
        const SizedBox(height: 8),
        ShimmerTextLine(
          width: double.infinity,
          height: 14,
          color: Colors.grey.shade300,
        ),
        const SizedBox(height: 8),
        ShimmerTextLine(width: 250, height: 14, color: Colors.grey.shade300),
        const SizedBox(height: 16),
        // Stats row shimmer
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(
            3,
            (index) => Column(
              children: [
                ShimmerTextLine(
                  width: 40,
                  height: 20,
                  color: Colors.grey.shade300,
                ),
                const SizedBox(height: 4),
                ShimmerTextLine(
                  width: 60,
                  height: 12,
                  color: Colors.grey.shade300,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Shimmer for ArtisanServicesSection
class ArtisanServicesShimmer extends StatelessWidget {
  const ArtisanServicesShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ShimmerTextLine(width: 100, height: 16, color: Colors.grey.shade300),
        const SizedBox(height: 12),
        Wrap(
          spacing: 30,
          runSpacing: 10,
          children: List.generate(
            4,
            (index) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ShimmerBox(width: 6, height: 6, color: Colors.grey.shade300),
                const SizedBox(width: 8),
                ShimmerTextLine(
                  width: 80 + (index * 20),
                  height: 14,
                  color: Colors.grey.shade300,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        const Divider(),
      ],
    );
  }
}

/// Shimmer for ArtisanPricesDropdown
class ArtisanPricesDropdownShimmer extends StatelessWidget {
  const ArtisanPricesDropdownShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ShimmerTextLine(width: 80, height: 16, color: Colors.grey.shade300),
        const SizedBox(height: 12),
        ShimmerBox(
          width: double.infinity,
          height: 48,
          borderRadius: 8,
          color: Colors.grey.shade300,
        ),
      ],
    );
  }
}

/// Shimmer for ArtisanQualificationsSection
class ArtisanQualificationsShimmer extends StatelessWidget {
  const ArtisanQualificationsShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ShimmerTextLine(width: 140, height: 16, color: Colors.grey.shade300),
        const SizedBox(height: 12),
        Column(
          children: List.generate(
            2,
            (index) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  ShimmerBox(
                    width: 24,
                    height: 24,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ShimmerTextLine(
                          width: 150,
                          height: 14,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 4),
                        ShimmerTextLine(
                          width: 100,
                          height: 12,
                          color: Colors.grey.shade300,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Shimmer for ArtisanAvailabilitySection
class ArtisanAvailabilityShimmer extends StatelessWidget {
  const ArtisanAvailabilityShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ShimmerTextLine(width: 120, height: 16, color: Colors.grey.shade300),
        const SizedBox(height: 12),
        Column(
          children: List.generate(
            5,
            (index) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ShimmerTextLine(
                    width: 80,
                    height: 14,
                    color: Colors.grey.shade300,
                  ),
                  ShimmerTextLine(
                    width: 100,
                    height: 14,
                    color: Colors.grey.shade300,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Shimmer for ArtisanReviewsSection
class ArtisanReviewsShimmer extends StatelessWidget {
  const ArtisanReviewsShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ShimmerTextLine(
              width: 160,
              height: 16,
              color: Colors.grey.shade300,
            ),
            ShimmerTextLine(width: 80, height: 14, color: Colors.grey.shade300),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 180,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: 2,
            separatorBuilder: (context, index) => const SizedBox(width: 16),
            itemBuilder: (context, index) => ShimmerBox(
              width: MediaQuery.of(context).size.width * 0.8,
              height: 180,
              borderRadius: 12,
              color: Colors.grey.shade300,
            ),
          ),
        ),
      ],
    );
  }
}
