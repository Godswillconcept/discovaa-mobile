import 'package:discovaa/features/profile/presentation/providers/artisan_provider.dart';
import 'package:discovaa/features/profile/presentation/providers/artisan_detail_provider.dart';
import 'package:discovaa/features/profile/presentation/widgets/artisan_profile_sections.dart';
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
    // Read booking provider once to get base artisan ID (no continuous watch)
    final baseArtisan = ref.read(bookingProvider).selectedArtisan;

    // Determine which artisan ID to use
    final String? targetArtisanId = widget.artisanId ?? baseArtisan?.id;

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
        body: detailAsync.when(
          data: (detailState) {
            // Use populated artisan data
            final artisan = detailState.populatedArtisan;
            return _buildProfileContent(
              artisan,
              services: detailState.services,
            );
          },
          loading: () {
            // Show base artisan data while loading details
            if (baseArtisan != null) {
              return _buildProfileContent(
                baseArtisan,
                isLoading: true,
                services: const [],
              );
            }
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          },
          error: (error, stack) {
            // Show base artisan data on error, with retry option
            if (baseArtisan != null) {
              return _buildProfileContent(
                baseArtisan,
                errorMessage: 'Failed to load full profile. Pull to retry.',
                services: const [],
              );
            }
            return Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Failed to load profile'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        ref.invalidate(artisanDetailProvider(targetArtisanId));
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildProfileContent(
    Artisan artisan, {
    bool isLoading = false,
    String? errorMessage,
    List<ArtisanService> services = const [],
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const MainHeader(),
        if (isLoading) const LinearProgressIndicator(minHeight: 2),
        if (errorMessage != null)
          Container(
            width: double.infinity,
            color: Colors.orange.shade100,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: Text(
              errorMessage,
              style: TextStyle(color: Colors.orange.shade800, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ),
        Expanded(
          child: SingleChildScrollView(
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
}
