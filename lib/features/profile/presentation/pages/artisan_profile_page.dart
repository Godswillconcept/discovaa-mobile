import 'package:discovaa/features/profile/domain/entities/artisan_entity.dart';
import 'package:discovaa/features/profile/presentation/providers/artisan_detail_provider.dart';
import 'package:discovaa/features/profile/presentation/widgets/artisan_profile_sections.dart';
import 'package:discovaa/features/profile/presentation/widgets/artisan_profile_shimmer.dart';
import 'package:discovaa/shared/presentation/widgets/main_header.dart';
import 'package:discovaa/shared/presentation/widgets/custom_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ArtisanProfilePage extends ConsumerStatefulWidget {
  final String? artisanId;

  const ArtisanProfilePage({super.key, this.artisanId});

  @override
  ConsumerState<ArtisanProfilePage> createState() => _ArtisanProfilePageState();
}

class _ArtisanProfilePageState extends ConsumerState<ArtisanProfilePage> {
  @override
  Widget build(BuildContext context) {
    // Determine which artisan ID to use
    final String? targetArtisanId = widget.artisanId;

    if (targetArtisanId == null) {
      return const Scaffold(body: Center(child: Text('No artisan selected')));
    }

    // Watch detailed artisan data
    final detailAsync = ref.watch(artisanDetailProvider(targetArtisanId));

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: RefreshIndicator(
          onRefresh: () async {
            await ref
                .read(artisanDetailProvider(targetArtisanId).notifier)
                .refresh();
          },
          child: detailAsync.when(
            data: (detailState) {
              // Check if we have complete data
              if (!detailState.isComplete && detailState.error == null) {
                // Data is not complete, show shimmer
                return const ArtisanProfileShimmer();
              }

              // Use populated artisan data
              final artisan = detailState.populatedArtisan;
              return _buildProfileContent(
                artisan,
                services: detailState.services,
                errorMessage: detailState.error,
              );
            },
            loading: () {
              // Show shimmer while loading (no partial content)
              return const ArtisanProfileShimmer();
            },
            error: (error, stack) {
              return _buildErrorView(
                context,
                ref,
                targetArtisanId,
                error.toString(),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildProfileContent(
    Artisan artisan, {
    List<ArtisanService> services = const [],
    String? errorMessage,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const MainHeader(),
        if (errorMessage != null)
          Container(
            width: double.infinity,
            color: Colors.orange.shade100,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    errorMessage,
                    style: TextStyle(
                      color: Colors.orange.shade800,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    ref.invalidate(
                      artisanDetailProvider(widget.artisanId ?? ''),
                    );
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        Expanded(
          child: SingleChildScrollView(
            key: PageStorageKey<String>('artisan_profile_${artisan.id}'),
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                const CustomHeader(),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ArtisanProfileHeader(
                        artisan: artisan,
                        services: services,
                      ),
                      const SizedBox(height: 24),
                      ArtisanGallery(artisan: artisan),
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
                  child: SingleChildScrollView(
                    physics: const NeverScrollableScrollPhysics(),
                    child: Column(
                      children: [
                        ArtisanBusinessInfo(artisan: artisan),
                        const SizedBox(height: 24),
                        ArtisanServicesSection(
                          artisan: artisan,
                          services: services,
                        ),
                        const SizedBox(height: 24),
                        ArtisanPricesDropdown(
                          artisan: artisan,
                          services: services,
                        ),
                        const SizedBox(height: 24),
                        ArtisanQualificationsSection(artisan: artisan),
                        const SizedBox(height: 24),
                        ArtisanAvailabilitySection(artisan: artisan),
                        const SizedBox(height: 24),
                        ArtisanReviewsSection(artisan: artisan),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorView(
    BuildContext context,
    WidgetRef ref,
    String artisanId,
    String error,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Failed to load profile',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: const TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                ref.invalidate(artisanDetailProvider(artisanId));
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
