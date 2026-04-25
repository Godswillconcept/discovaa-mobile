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
class ArtisanDetailState {
  final Artisan artisan;
  final List<ArtisanService> services;
  final List<Review> reviews;
  final Map<String, String> availability;
  final bool isLoadingServices;
  final bool isLoadingReviews;
  final bool isLoadingAvailability;
  final String? error;

  const ArtisanDetailState({
    required this.artisan,
    this.services = const [],
    this.reviews = const [],
    this.availability = const {},
    this.isLoadingServices = false,
    this.isLoadingReviews = false,
    this.isLoadingAvailability = false,
    this.error,
  });

  ArtisanDetailState copyWith({
    Artisan? artisan,
    List<ArtisanService>? services,
    List<Review>? reviews,
    Map<String, String>? availability,
    bool? isLoadingServices,
    bool? isLoadingReviews,
    bool? isLoadingAvailability,
    String? error,
  }) {
    return ArtisanDetailState(
      artisan: artisan ?? this.artisan,
      services: services ?? this.services,
      reviews: reviews ?? this.reviews,
      availability: availability ?? this.availability,
      isLoadingServices: isLoadingServices ?? this.isLoadingServices,
      isLoadingReviews: isLoadingReviews ?? this.isLoadingReviews,
      isLoadingAvailability:
          isLoadingAvailability ?? this.isLoadingAvailability,
      error: error ?? this.error,
    );
  }

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

    // Hydrate from cache and return early if present to avoid redundant network calls
    final cachedArtisan = repository.getCachedArtisanDetail(artisanId);
    if (cachedArtisan != null) {
      final cachedServices = repository.getCachedArtisanServices(artisanId);
      final cachedReviews = repository.getCachedArtisanReviews(artisanId);
      final cachedAvailability = repository.getCachedArtisanAvailability(
        artisanId,
      );
      state = AsyncData(
        ArtisanDetailState(
          artisan: cachedArtisan,
          services: cachedServices,
          reviews: cachedReviews,
          availability: cachedAvailability,
        ),
      );
      // No need to refetch; return early
      return ArtisanDetailState(
        artisan: cachedArtisan,
        services: cachedServices,
        reviews: cachedReviews,
        availability: cachedAvailability,
      );
    }
    // If no cache, proceed to fetch fresh data
    final artisan = await repository.getArtisanDetail(artisanId);

    // Initialize AsyncValue state with base data before loading extras
    final baseState = ArtisanDetailState(artisan: artisan);
    state = AsyncData(baseState);

    // Load additional data in parallel (updates state incrementally)
    await Future.wait([
      _loadServices(artisanId),
      _loadReviews(artisanId),
      _loadAvailability(artisanId),
    ]);

    return state.requireValue;
  }

  Future<void> _loadServices(String artisanId) async {
    try {
      state = AsyncData(
        state.value?.copyWith(isLoadingServices: true) ??
            ArtisanDetailState(
              artisan: state.value!.artisan,
              isLoadingServices: true,
            ),
      );

      final repository = ref.read(artisanDetailRepositoryProvider);
      final services = await repository.getArtisanServices(artisanId);

      state = AsyncData(
        state.value?.copyWith(services: services, isLoadingServices: false) ??
            ArtisanDetailState(
              artisan: state.value!.artisan,
              services: services,
            ),
      );
    } catch (e) {
      state = AsyncData(
        state.value?.copyWith(
              isLoadingServices: false,
              error: 'Failed to load services',
            ) ??
            ArtisanDetailState(
              artisan: state.value!.artisan,
              error: 'Failed to load services',
            ),
      );
    }
  }

  Future<void> _loadReviews(String artisanId) async {
    try {
      state = AsyncData(
        state.value?.copyWith(isLoadingReviews: true) ??
            ArtisanDetailState(
              artisan: state.value!.artisan,
              isLoadingReviews: true,
            ),
      );

      final repository = ref.read(artisanDetailRepositoryProvider);
      final reviews = await repository.getArtisanReviews(artisanId);

      state = AsyncData(
        state.value?.copyWith(reviews: reviews, isLoadingReviews: false) ??
            ArtisanDetailState(artisan: state.value!.artisan, reviews: reviews),
      );
    } catch (e) {
      state = AsyncData(
        state.value?.copyWith(
              isLoadingReviews: false,
              error: 'Failed to load reviews',
            ) ??
            ArtisanDetailState(
              artisan: state.value!.artisan,
              error: 'Failed to load reviews',
            ),
      );
    }
  }

  Future<void> _loadAvailability(String artisanId) async {
    try {
      state = AsyncData(
        state.value?.copyWith(isLoadingAvailability: true) ??
            ArtisanDetailState(
              artisan: state.value!.artisan,
              isLoadingAvailability: true,
            ),
      );

      final repository = ref.read(artisanDetailRepositoryProvider);
      final availability = await repository.getArtisanAvailability(artisanId);

      state = AsyncData(
        state.value?.copyWith(
              availability: availability,
              isLoadingAvailability: false,
            ) ??
            ArtisanDetailState(
              artisan: state.value!.artisan,
              availability: availability,
            ),
      );
    } catch (e) {
      state = AsyncData(
        state.value?.copyWith(
              isLoadingAvailability: false,
              error: 'Failed to load availability',
            ) ??
            ArtisanDetailState(
              artisan: state.value!.artisan,
              error: 'Failed to load availability',
            ),
      );
    }
  }

  Future<void> refresh() async {
    final artisanId = arg;
    final repository = ref.read(artisanDetailRepositoryProvider);

    await repository.clearCache(artisanId);

    state = const AsyncLoading();

    try {
      final artisan = await repository.getArtisanDetail(artisanId);
      final newState = ArtisanDetailState(artisan: artisan);

      // Set base state first to avoid null access during section loads
      state = AsyncData(newState);

      await Future.wait([
        _loadServices(artisanId),
        _loadReviews(artisanId),
        _loadAvailability(artisanId),
      ]);
    } catch (e, stackTrace) {
      state = AsyncError(e, stackTrace);
    }
  }
}
