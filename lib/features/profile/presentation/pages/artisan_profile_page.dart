import 'package:discovaa/features/profile/domain/entities/artisan_entity.dart';
import 'package:discovaa/features/profile/presentation/providers/artisan_detail_provider.dart';
import 'package:discovaa/features/profile/presentation/widgets/artisan_profile_sections.dart';
import 'package:discovaa/features/profile/presentation/widgets/artisan_profile_shimmer.dart';
import 'package:discovaa/shared/presentation/widgets/main_header.dart';
import 'package:discovaa/shared/presentation/widgets/custom_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

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
            padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 16.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    errorMessage,
                    style: TextStyle(
                      color: Colors.orange.shade800,
                      fontSize: 12.sp,
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
                  padding: EdgeInsets.all(20.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ArtisanProfileHeader(
                        artisan: artisan,
                        services: services,
                      ),
                      SizedBox(height: 24.h),
                      ArtisanGallery(artisan: artisan),
                    ],
                  ),
                ),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.fromLTRB(16.w, 24.w, 16.w, 16.w),
                  decoration: BoxDecoration(
                    color: Color(0xFFF8FBFF),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30.r),
                      topRight: Radius.circular(30.r),
                    ),
                  ),
                  child: SingleChildScrollView(
                    physics: const NeverScrollableScrollPhysics(),
                    child: Column(
                      children: [
                        ArtisanBusinessInfo(artisan: artisan),
                        SizedBox(height: 24.h),
                        ArtisanServicesSection(
                          artisan: artisan,
                          services: services,
                        ),
                        SizedBox(height: 24.h),
                        ArtisanPricesDropdown(
                          artisan: artisan,
                          services: services,
                        ),
                        SizedBox(height: 24.h),
                        ArtisanQualificationsSection(artisan: artisan),
                        SizedBox(height: 24.h),
                        ArtisanAvailabilitySection(artisan: artisan),
                        SizedBox(height: 24.h),
                        ArtisanReviewsSection(artisan: artisan),
                        SizedBox(height: 40.h),
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
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64.sp, color: Colors.grey),
            SizedBox(height: 16.h),
            Text(
              'Failed to load profile',
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8.h),
            Text(
              error,
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24.h),
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
