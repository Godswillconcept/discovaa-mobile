export 'package:discovaa/features/profile/domain/repositories/artisan_detail_repository.dart';

import 'package:discovaa/app/dependency_injection/service_locator.dart';
import 'package:discovaa/core/network/dio_client.dart';
import 'package:discovaa/core/network/network_info.dart';
import 'package:discovaa/core/storage/hive_service.dart';
import 'package:discovaa/features/profile/data/repositories/artisan_detail_repository_impl.dart';
import 'package:discovaa/features/profile/domain/entities/artisan_entity.dart';
import 'package:discovaa/features/profile/domain/repositories/artisan_detail_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Repository provider
final artisanDetailRepositoryProvider = Provider<ArtisanDetailRepository>((
  ref,
) {
  return ArtisanDetailRepositoryImpl(
    dioClient: sl<DioClient>(),
    hiveService: sl<HiveService>(),
    networkInfo: sl<NetworkInfo>(),
  );
});

/// Provider for detailed artisan data including services, reviews, and availability
final artisanDetailProvider =
    AsyncNotifierProvider.family<
      ArtisanDetailNotifier,
      ArtisanDetailState,
      String
    >(() => ArtisanDetailNotifier());

/// State class for artisan detail
/// Uses unified loading - all data is fetched before state is emitted
class ArtisanDetailState {
  final Artisan artisan;
  final List<ArtisanService> services;
  final List<Review> reviews;
  final Map<String, String> availability;
  final String? error;

  const ArtisanDetailState({
    required this.artisan,
    this.services = const [],
    this.reviews = const [],
    this.availability = const {},
    this.error,
  });

  ArtisanDetailState copyWith({
    Artisan? artisan,
    List<ArtisanService>? services,
    List<Review>? reviews,
    Map<String, String>? availability,
    String? error,
  }) {
    return ArtisanDetailState(
      artisan: artisan ?? this.artisan,
      services: services ?? this.services,
      reviews: reviews ?? this.reviews,
      availability: availability ?? this.availability,
      error: error ?? this.error,
    );
  }

  /// Check if all required data is loaded
  /// We check that artisan data exists (fetched) rather than checking non-empty lists
  /// (an artisan may legitimately have no reviews or empty availability)
  bool get isComplete => artisan.id.isNotEmpty;

  /// Get combined artisan with populated services, reviews, and availability
  Artisan get populatedArtisan {
    double? hourlyRate;
    String priceRange = '';

    // Calculate pricing from services
    if (services.isNotEmpty) {
      final hourlyServices = services
          .where((s) => s.hourlyRate != null)
          .toList();
      if (hourlyServices.isNotEmpty) {
        hourlyRate = hourlyServices
            .map((s) => s.hourlyRate!)
            .reduce((a, b) => a < b ? a : b);
      }

      // Get price range display
      final ranges = services.map((s) => s.priceRange).toSet().toList();
      if (ranges.length == 1) {
        priceRange = ranges.first;
      } else if (ranges.length > 1) {
        priceRange = '${ranges.first} - ${ranges.last}';
      }
    }

    return Artisan(
      id: artisan.id,
      name: artisan.name,
      category: artisan.category,
      rating: artisan.rating,
      reviewsCount: artisan.reviewsCount,
      location: artisan.location,
      profileImage: artisan.profileImage,
      bio: artisan.bio,
      services: services.map((s) => s.title).toList(),
      hourlyRate: hourlyRate ?? 0,
      priceRange: priceRange,
      certifications: artisan.certifications,
      availability: availability.isNotEmpty
          ? availability
          : artisan.availability,
      isVerified: artisan.isVerified,
      galleryImages: artisan.galleryImages,
      reviews: reviews,
      hiresCount: artisan.hiresCount,
      yearsInBusiness: artisan.yearsInBusiness,
      lastSeen: artisan.lastSeen,
    );
  }
}

class ArtisanDetailNotifier
    extends FamilyAsyncNotifier<ArtisanDetailState, String> {
  @override
  Future<ArtisanDetailState> build(String artisanId) async {
    final repository = ref.read(artisanDetailRepositoryProvider);

    // Try to load from cache first
    final cachedArtisan = repository.getCachedArtisanDetail(artisanId);
    final cachedServices = repository.getCachedArtisanServices(artisanId);
    final cachedReviews = repository.getCachedArtisanReviews(artisanId);
    final cachedAvailability = repository.getCachedArtisanAvailability(
      artisanId,
    );

    // If we have complete cached data, return it immediately
    // Cache will be validated - if data is stale, it will be refreshed below
    if (cachedArtisan != null &&
        cachedServices.isNotEmpty &&
        cachedReviews.isNotEmpty) {
      final cachedState = ArtisanDetailState(
        artisan: cachedArtisan,
        services: cachedServices,
        reviews: cachedReviews,
        availability: cachedAvailability,
      );

      // Emit cached data immediately
      state = AsyncData(cachedState);

      // Continue to fetch fresh data in background (will update state when complete)
      _fetchAllData(artisanId, useCache: false);
      return cachedState;
    }

    // No valid cache, fetch all data
    return _fetchAllData(artisanId, useCache: true);
  }

  /// Fetch all required data in parallel using Future.wait()
  /// This ensures all-or-nothing loading - state is only emitted when ALL data is ready
  Future<ArtisanDetailState> _fetchAllData(
    String artisanId, {
    required bool useCache,
  }) async {
    final repository = ref.read(artisanDetailRepositoryProvider);

    try {
      // Fetch all data in parallel
      final results = await Future.wait([
        repository.getArtisanDetail(artisanId),
        repository.getArtisanServices(artisanId),
        repository.getArtisanReviews(artisanId),
        repository.getArtisanAvailability(artisanId),
      ]);

      final artisan = results[0] as Artisan;
      final services = results[1] as List<ArtisanService>;
      final reviews = results[2] as List<Review>;
      final availability = results[3] as Map<String, String>;

      final state = ArtisanDetailState(
        artisan: artisan,
        services: services,
        reviews: reviews,
        availability: availability,
      );

      return state;
    } catch (e) {
      // If we have cached data, return it with error
      final cachedArtisan = repository.getCachedArtisanDetail(artisanId);
      if (cachedArtisan != null) {
        return ArtisanDetailState(
          artisan: cachedArtisan,
          services: repository.getCachedArtisanServices(artisanId),
          reviews: repository.getCachedArtisanReviews(artisanId),
          availability: repository.getCachedArtisanAvailability(artisanId),
          error: 'Failed to refresh data. Showing cached version.',
        );
      }

      // No cache available, rethrow to let AsyncNotifier handle the error state
      rethrow;
    }
  }

  /// Refresh data by clearing cache and refetching all data
  Future<void> refresh() async {
    final artisanId = arg;

    // Clear cache to force fresh fetch
    final repository = ref.read(artisanDetailRepositoryProvider);
    await repository.clearCache(artisanId);

    // Set loading state
    state = const AsyncLoading();

    try {
      final newState = await _fetchAllData(artisanId, useCache: false);
      state = AsyncData(newState);
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
    }
  }
}
