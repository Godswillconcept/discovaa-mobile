import 'package:dio/dio.dart';
import 'package:discovaa/core/constants/api_endpoints.dart';
import 'package:discovaa/core/network/api_helpers.dart';
import 'package:discovaa/core/network/dio_client.dart';
import 'package:discovaa/core/network/network_info.dart';
import 'package:discovaa/core/storage/hive_service.dart';
import 'package:discovaa/features/profile/data/models/artisan_detail_dto.dart';
import 'package:discovaa/features/profile/domain/entities/artisan_entity.dart';
import 'package:discovaa/features/profile/domain/repositories/artisan_detail_repository.dart';

class ArtisanDetailRepositoryImpl implements ArtisanDetailRepository {
  final DioClient _dioClient;
  final HiveService _hiveService;
  final NetworkInfo _networkInfo;

  ArtisanDetailRepositoryImpl({
    required DioClient dioClient,
    required HiveService hiveService,
    required NetworkInfo networkInfo,
  }) : _dioClient = dioClient,
       _hiveService = hiveService,
       _networkInfo = networkInfo;

  String _cacheKey(String artisanId) => 'artisan.detail.$artisanId';
  String _servicesCacheKey(String artisanId) => 'artisan.services.$artisanId';
  String _reviewsCacheKey(String artisanId) => 'artisan.reviews.$artisanId';
  String _availabilityCacheKey(String artisanId) =>
      'artisan.availability.$artisanId';

  @override
  Future<Artisan> getArtisanDetail(String artisanId) async {
    try {
      if (!await _networkInfo.isConnected) {
        final cached = _readCachedArtisan(artisanId);
        if (cached != null) return cached;
      }

      final response = await _dioClient.get(
        '${ApiEndpoints.providers}$artisanId/',
        options: Options(headers: {'X-Skip-Auth': 'true'}),
      );

      final envelope = decodeEnvelope(
        response,
        (raw) => ProviderDetailDto.fromJson(raw as Map<String, dynamic>),
      );

      final artisan = _mapDetailDtoToArtisan(envelope.data);
      await _cacheArtisan(artisanId, artisan);
      return artisan;
    } catch (_) {
      final cached = _readCachedArtisan(artisanId);
      if (cached != null) return cached;
      rethrow;
    }
  }

  @override
  Future<List<ArtisanService>> getArtisanServices(String artisanId) async {
    try {
      if (!await _networkInfo.isConnected) {
        final cached = _readCachedServices(artisanId);
        if (cached.isNotEmpty) return cached;
      }

      final response = await _dioClient.get(
        ApiEndpoints.services,
        queryParameters: {'provider': artisanId},
        options: Options(headers: {'X-Skip-Auth': 'true'}),
      );

      final envelope = decodeListEnvelope(response, ServiceDto.fromJson);

      final services = envelope.data
          .map(_mapServiceDtoToArtisanService)
          .toList();
      await _cacheServices(artisanId, services);
      return services;
    } catch (_) {
      final cached = _readCachedServices(artisanId);
      if (cached.isNotEmpty) return cached;
      return const [];
    }
  }

  @override
  Future<List<Review>> getArtisanReviews(String artisanId) async {
    try {
      if (!await _networkInfo.isConnected) {
        final cached = _readCachedReviews(artisanId);
        if (cached.isNotEmpty) return cached;
      }

      final response = await _dioClient.get(
        ApiEndpoints.reviewsV1,
        queryParameters: {'provider': artisanId},
        options: Options(headers: {'X-Skip-Auth': 'true'}),
      );

      final envelope = decodeListEnvelope(response, ReviewDto.fromJson);

      final reviews = envelope.data.map(_mapReviewDtoToReview).toList();
      await _cacheReviews(artisanId, reviews);
      return reviews;
    } catch (_) {
      final cached = _readCachedReviews(artisanId);
      if (cached.isNotEmpty) return cached;
      return const [];
    }
  }

  @override
  Future<Map<String, String>> getArtisanAvailability(String artisanId) async {
    try {
      if (!await _networkInfo.isConnected) {
        final cached = _readCachedAvailability(artisanId);
        if (cached.isNotEmpty) return cached;
      }

      final response = await _dioClient.get(
        '${ApiEndpoints.providers}$artisanId/availability/',
        options: Options(headers: {'X-Skip-Auth': 'true'}),
      );

      final envelope = decodeListEnvelope(
        response,
        ProviderAvailabilityRuleDto.fromJson,
      );

      final availability = <String, String>{};
      for (final rule in envelope.data) {
        availability[rule.weekdayName] = rule.displayTimeRange;
      }

      await _cacheAvailability(artisanId, availability);
      return availability;
    } catch (_) {
      final cached = _readCachedAvailability(artisanId);
      if (cached.isNotEmpty) return cached;
      return const {};
    }
  }

  @override
  Future<void> clearCache(String artisanId) async {
    await _hiveService.remove(_cacheKey(artisanId));
    await _hiveService.remove(_servicesCacheKey(artisanId));
    await _hiveService.remove(_reviewsCacheKey(artisanId));
    await _hiveService.remove(_availabilityCacheKey(artisanId));
  }

  // Mapping functions

  Artisan _mapDetailDtoToArtisan(ProviderDetailDto dto) {
    final location = dto.locations.isNotEmpty
        ? dto.locations.first.displayLocation
        : 'Unknown';

    final certifications = dto.certifications
        .map((c) => c.displayTitle)
        .toList();

    final availability = <String, String>{};
    for (final rule in dto.availabilityRules) {
      availability[rule.weekdayName] = rule.displayTimeRange;
    }

    final galleryImages = dto.galleryUrls.isNotEmpty
        ? dto.galleryUrls
        : _getPlaceholderGallery(dto.id);

    return Artisan(
      id: dto.id,
      name: dto.displayName,
      category: dto.serviceCategories.isNotEmpty
          ? dto.serviceCategories.first
          : 'General',
      rating: dto.avgRating,
      reviewsCount: dto.reviewCount,
      location: location,
      profileImage: dto.profilePhoto ?? _getArtisanPlaceholder(dto.id),
      bio: dto.bio ?? '',
      services: const [], // Will be populated separately
      hourlyRate: 0, // Will be calculated from services
      priceRange: '', // Will be calculated from services
      certifications: certifications,
      availability: availability,
      isVerified: dto.isVerified,
      galleryImages: galleryImages,
      reviews: const [], // Will be populated separately
      hiresCount: dto.hiresCount,
      yearsInBusiness: 0, // Not available in public API
      lastSeen: null,
    );
  }

  ArtisanService _mapServiceDtoToArtisanService(ServiceDto dto) {
    return ArtisanService(
      id: dto.id,
      title: dto.title,
      description: dto.description,
      hourlyRate: dto.isHourly ? dto.priceAmount : null,
      priceRange: dto.displayPrice,
      mediaUrls: dto.media,
    );
  }

  Review _mapReviewDtoToReview(ReviewDto dto) {
    return Review(
      userName: dto.authorName ?? 'Anonymous',
      userAvatar:
          dto.authorAvatar ?? 'assets/images/placeholders/user_avatar.png',
      rating: dto.rating.clamp(0.0, 5.0),
      date: dto.displayDate,
      comment: dto.comment ?? '',
    );
  }

  // Cache helpers

  Future<void> _cacheArtisan(String artisanId, Artisan artisan) async {
    final json = {
      'id': artisan.id,
      'name': artisan.name,
      'category': artisan.category,
      'rating': artisan.rating,
      'reviewsCount': artisan.reviewsCount,
      'location': artisan.location,
      'profileImage': artisan.profileImage,
      'bio': artisan.bio,
      'isVerified': artisan.isVerified,
      'hiresCount': artisan.hiresCount,
      'galleryImages': artisan.galleryImages,
      'certifications': artisan.certifications,
      'availability': artisan.availability,
    };
    await _hiveService.setMap(_cacheKey(artisanId), json);
  }

  Artisan? _readCachedArtisan(String artisanId) {
    final cached = _hiveService.getMap(_cacheKey(artisanId));
    if (cached == null) return null;

    return Artisan(
      id: cached['id']?.toString() ?? '',
      name: cached['name']?.toString() ?? '',
      category: cached['category']?.toString() ?? 'General',
      rating: (cached['rating'] as num?)?.toDouble() ?? 0,
      reviewsCount: (cached['reviewsCount'] as num?)?.toInt() ?? 0,
      location: cached['location']?.toString() ?? 'Unknown',
      profileImage: cached['profileImage']?.toString() ?? '',
      bio: cached['bio']?.toString() ?? '',
      services: const [],
      hourlyRate: 0,
      priceRange: '',
      certifications:
          (cached['certifications'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      availability:
          (cached['availability'] as Map<dynamic, dynamic>?)?.map(
            (k, v) => MapEntry(k.toString(), v.toString()),
          ) ??
          const {},
      isVerified: cached['isVerified'] == true,
      galleryImages:
          (cached['galleryImages'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      reviews: const [],
      hiresCount: (cached['hiresCount'] as num?)?.toInt() ?? 0,
      yearsInBusiness: 0,
      lastSeen: null,
    );
  }

  Future<void> _cacheServices(
    String artisanId,
    List<ArtisanService> services,
  ) async {
    final json = services
        .map(
          (s) => {
            'id': s.id,
            'title': s.title,
            'description': s.description,
            'hourlyRate': s.hourlyRate,
            'priceRange': s.priceRange,
            'mediaUrls': s.mediaUrls,
          },
        )
        .toList();
    await _hiveService.setList(_servicesCacheKey(artisanId), json);
  }

  List<ArtisanService> _readCachedServices(String artisanId) {
    final cached = _hiveService.getList<dynamic>(_servicesCacheKey(artisanId));
    if (cached == null) return const [];

    return cached.whereType<Map>().map((item) {
      final map = item.cast<String, dynamic>();
      return ArtisanService(
        id: map['id']?.toString() ?? '',
        title: map['title']?.toString() ?? '',
        description: map['description']?.toString(),
        hourlyRate: (map['hourlyRate'] as num?)?.toDouble(),
        priceRange: map['priceRange']?.toString() ?? '',
        mediaUrls:
            (map['mediaUrls'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
      );
    }).toList();
  }

  Future<void> _cacheReviews(String artisanId, List<Review> reviews) async {
    final json = reviews
        .map(
          (r) => {
            'userName': r.userName,
            'userAvatar': r.userAvatar,
            'rating': r.rating,
            'comment': r.comment,
            'date': r.date,
          },
        )
        .toList();
    await _hiveService.setList(_reviewsCacheKey(artisanId), json);
  }

  List<Review> _readCachedReviews(String artisanId) {
    final cached = _hiveService.getList<dynamic>(_reviewsCacheKey(artisanId));
    if (cached == null) return const [];

    return cached.whereType<Map>().map((item) {
      final map = item.cast<String, dynamic>();
      return Review(
        userName: map['userName']?.toString() ?? 'Anonymous',
        userAvatar:
            map['userAvatar']?.toString() ??
            'assets/images/placeholders/user_avatar.png',
        rating: (map['rating'] as num?)?.toDouble() ?? 0,
        comment: map['comment']?.toString() ?? '',
        date: map['date']?.toString() ?? '',
      );
    }).toList();
  }

  Future<void> _cacheAvailability(
    String artisanId,
    Map<String, String> availability,
  ) async {
    await _hiveService.setMap(_availabilityCacheKey(artisanId), availability);
  }

  Map<String, String> _readCachedAvailability(String artisanId) {
    final cached = _hiveService.getMap(_availabilityCacheKey(artisanId));
    if (cached == null) return const {};

    return cached.map((k, v) => MapEntry(k.toString(), v.toString()));
  }

  // Placeholder helpers

  String _getArtisanPlaceholder(String seed) {
    final count = 8;
    final sum = seed.codeUnits.fold<int>(0, (a, b) => a + b);
    final index = (sum % count) + 1;
    final two = index.toString().padLeft(2, '0');
    return 'assets/images/placeholders/artisan_$two.png';
  }

  List<String> _getPlaceholderGallery(String seed) {
    return [
      'assets/images/placeholders/gallery.png',
      'assets/images/placeholders/gallery-2.png',
      'assets/images/placeholders/gallery-3.png',
      'assets/images/placeholders/gallery-4.png',
      'assets/images/placeholders/gallery-5.png',
    ];
  }
}
