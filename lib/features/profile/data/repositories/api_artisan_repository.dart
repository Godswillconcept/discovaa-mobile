import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:discovaa/core/constants/api_endpoints.dart';
import 'package:discovaa/core/network/api_helpers.dart';
import 'package:discovaa/core/network/dio_client.dart';
import 'package:discovaa/core/network/network_info.dart';
import 'package:discovaa/core/storage/hive_service.dart';
import 'package:discovaa/features/profile/domain/entities/artisan_entity.dart';
import 'package:discovaa/features/profile/domain/repositories/artisan_repository.dart';

class ApiArtisanRepository implements ArtisanRepository {
  final DioClient _dioClient;
  final HiveService _hiveService;
  final NetworkInfo _networkInfo;

  ApiArtisanRepository({
    required DioClient dioClient,
    required HiveService hiveService,
    required NetworkInfo networkInfo,
  }) : _dioClient = dioClient,
       _hiveService = hiveService,
       _networkInfo = networkInfo;

  Map<String, String>? _categoryNameToId; // lowercased name -> id
  static const _artisansCacheKey = 'artisans.cache.all';
  static const _categoriesCacheKey = 'artisans.cache.categories';

  @override
  Future<List<Artisan>> getArtisans() async {
    return _loadArtisans(cacheKey: _artisansCacheKey, queryParameters: null);
  }

  @override
  List<Artisan> getCachedArtisans({
    String? search,
    String? category,
    String? ordering,
    double? minRating,
    double? minPrice,
    double? maxPrice,
    String? location,
    bool? isAvailableOnly,
    String? providerType,
    bool? isVerifiedOnly,
    double? radiusKm,
  }) {
    final query = <String, dynamic>{};
    if (search != null && search.trim().isNotEmpty) {
      query['search'] = search.trim();
    }
    if (ordering != null && ordering.trim().isNotEmpty) {
      query['ordering'] = ordering.trim();
    }
    if (minRating != null && minRating > 0) {
      query['min_avg_rating'] = minRating;
    }
    if (minPrice != null && minPrice > 0) {
      query['min_hourly_rate'] = minPrice;
    }
    if (maxPrice != null && maxPrice > 0) {
      query['max_hourly_rate'] = maxPrice;
    }
    if (location != null && location.trim().isNotEmpty) {
      query['location'] = location.trim();
    }
    if (isAvailableOnly == true) {
      query['is_available'] = true;
    }
    if (providerType != null && providerType != 'All') {
      query['provider_type'] = providerType;
    }
    if (isVerifiedOnly == true) {
      query['is_verified'] = true;
    }
    if (radiusKm != null && radiusKm > 0) {
      query['radius_km'] = radiusKm;
    }

    if (category != null && category.trim().isNotEmpty) {
      final input = category.trim();
      final uuid = maybeUuidCategoryId(input);
      if (uuid != null) {
        query['category_id'] = uuid;
      } else if (_categoryNameToId?.containsKey(input.toLowerCase()) == true) {
        query['category_id'] = _categoryNameToId![input.toLowerCase()];
      } else {
        query['category'] = input.toLowerCase().replaceAll(RegExp(r'\s+'), '-');
      }
    }

    final cacheKey = _searchCacheKey(query);
    return _readCachedArtisans(cacheKey);
  }

  @override
  Future<List<Artisan>> searchArtisans({
    String? search,
    String? category,
    String? ordering,
    double? minRating,
    double? minPrice,
    double? maxPrice,
    String? location,
    bool? isAvailableOnly,
    String? providerType,
    bool? isVerifiedOnly,
    double? radiusKm,
  }) async {
    final query = <String, dynamic>{};
    if (search != null && search.trim().isNotEmpty) {
      query['search'] = search.trim();
    }
    if (ordering != null && ordering.trim().isNotEmpty) {
      query['ordering'] = ordering.trim();
    }
    if (minRating != null && minRating > 0) {
      query['min_avg_rating'] = minRating;
    }
    if (minPrice != null && minPrice > 0) {
      query['min_hourly_rate'] = minPrice;
    }
    if (maxPrice != null && maxPrice > 0) {
      query['max_hourly_rate'] = maxPrice;
    }
    if (location != null && location.trim().isNotEmpty) {
      query['location'] = location.trim();
    }
    if (isAvailableOnly == true) {
      query['is_available'] = true;
    }
    if (providerType != null && providerType != 'All') {
      query['provider_type'] = providerType;
    }
    if (isVerifiedOnly == true) {
      query['is_verified'] = true;
    }
    if (radiusKm != null && radiusKm > 0) {
      query['radius_km'] = radiusKm;
    }

    if (category != null && category.trim().isNotEmpty) {
      final resolved = await _resolveCategoryIdOrSlug(category.trim());
      if (resolved.key == 'category_id') {
        query['category_id'] = resolved.value;
      } else if (resolved.key == 'category') {
        query['category'] = resolved.value;
      }
    }

    final cacheKey = _searchCacheKey(query);
    return _loadArtisans(
      cacheKey: cacheKey,
      queryParameters: query.isEmpty ? null : query,
    );
  }

  Future<MapEntry<String, String>> _resolveCategoryIdOrSlug(
    String input,
  ) async {
    // If input looks like a UUID, use category_id
    final uuid = maybeUuidCategoryId(input);
    if (uuid != null) return MapEntry('category_id', uuid);

    // Ensure categories cache
    _categoryNameToId ??= await _loadCategoriesByName();
    final id = _categoryNameToId![input.toLowerCase()];
    if (id != null) return MapEntry('category_id', id);

    // As a fallback, send as slug (best-effort lowercased hyphenated)
    final slug = input.toLowerCase().replaceAll(RegExp(r'\s+'), '-');
    return MapEntry('category', slug);
  }

  Future<Map<String, String>> _loadCategoriesByName() async {
    try {
      if (!await _networkInfo.isConnected) {
        final cached = _readCachedCategories();
        if (cached.isNotEmpty) {
          return cached;
        }
      }
      final response = await _dioClient.get(
        ApiEndpoints.serviceCategories,
        options: Options(headers: {'X-Skip-Auth': 'true'}),
      );
      final envelope = decodeListEnvelope(
        response,
        (item) => _ServiceCategoryLite.fromJson(item),
      );
      await _hiveService.setList(
        _categoriesCacheKey,
        envelope.data
            .map((item) => {'id': item.id, 'name': item.name})
            .toList(growable: false),
      );
      return {for (final c in envelope.data) c.name.toLowerCase(): c.id};
    } catch (_) {
      final cached = _readCachedCategories();
      if (cached.isNotEmpty) {
        return cached;
      }
      rethrow;
    }
  }

  Future<List<Artisan>> _loadArtisans({
    required String cacheKey,
    required Map<String, dynamic>? queryParameters,
  }) async {
    try {
      if (!await _networkInfo.isConnected) {
        final cached = _readCachedArtisans(cacheKey);
        if (cached.isNotEmpty) {
          return cached;
        }
      }
      final response = await _dioClient.get(
        ApiEndpoints.providers,
        queryParameters: queryParameters,
        options: Options(headers: {'X-Skip-Auth': 'true'}),
      );
      final envelope = decodeListEnvelope(
        response,
        (item) => _ProviderPublicDto.fromJson(item),
      );
      final artisans = envelope.data
          .map(_mapProviderToArtisan)
          .toList(growable: false);
      await _hiveService.setList(
        cacheKey,
        artisans
            .map((artisan) => _artisanToJson(artisan))
            .toList(growable: false),
      );
      return artisans;
    } catch (_) {
      final cached = _readCachedArtisans(cacheKey);
      if (cached.isNotEmpty) {
        return cached;
      }
      rethrow;
    }
  }

  List<Artisan> _readCachedArtisans(String cacheKey) {
    final cached = _hiveService.getList<dynamic>(cacheKey) ?? const [];
    return cached
        .whereType<Map>()
        .map((item) => _artisanFromJson(item.cast<String, dynamic>()))
        .toList(growable: false);
  }

  Map<String, String> _readCachedCategories() {
    final cached =
        _hiveService.getList<dynamic>(_categoriesCacheKey) ?? const [];
    final categories = cached
        .whereType<Map>()
        .map(
          (item) => _ServiceCategoryLite.fromJson(item.cast<String, dynamic>()),
        )
        .toList(growable: false);
    return {for (final c in categories) c.name.toLowerCase(): c.id};
  }

  String _searchCacheKey(Map<String, dynamic> query) {
    final entries = query.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final suffix = entries
        .map((entry) => '${entry.key}=${entry.value}')
        .join('&');
    return suffix.isEmpty ? _artisansCacheKey : '$_artisansCacheKey.$suffix';
  }

  Map<String, dynamic> _artisanToJson(Artisan artisan) {
    return {
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
    };
  }

  Artisan _artisanFromJson(Map<String, dynamic> json) {
    return Artisan(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      category: json['category']?.toString() ?? 'General',
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      reviewsCount: (json['reviewsCount'] as num?)?.toInt() ?? 0,
      location: json['location']?.toString() ?? 'Unknown',
      profileImage:
          json['profileImage']?.toString() ??
          _artisanPlaceholder(json['id']?.toString() ?? ''),
      bio: json['bio']?.toString() ?? '',
      services: const [],
      hourlyRate: 0,
      priceRange: '',
      certifications: const [],
      availability: const {},
      isVerified: json['isVerified'] as bool? ?? false,
      galleryImages: const [],
      reviews: const [],
      hiresCount: (json['hiresCount'] as num?)?.toInt() ?? 0,
      yearsInBusiness: 0,
      lastSeen: null,
    );
  }

  Artisan _mapProviderToArtisan(_ProviderPublicDto dto) {
    return Artisan(
      id: dto.id,
      name: dto.displayName,
      category: _firstCategory(dto.serviceCategories) ?? 'General',
      rating: dto.avgRating ?? 0,
      reviewsCount: dto.reviewCount ?? 0,
      location: _firstLocation(dto.locations) ?? 'Unknown',
      profileImage: dto.profilePhoto ?? _artisanPlaceholder(dto.id),
      bio: dto.bio ?? '',
      services: const [],
      hourlyRate: 0,
      priceRange: '',
      certifications: const [],
      availability: const {},
      isVerified: dto.isVerified ?? false,
      galleryImages: const [],
      reviews: const [],
      hiresCount: dto.hiresCount ?? 0,
      yearsInBusiness: 0,
      lastSeen: null,
    );
  }

  String? _firstCategory(List<String> categories) {
    if (categories.isEmpty) return null;
    final first = categories.first.trim();
    return first.isEmpty ? null : first;
  }

  String? _firstLocation(List<_ProviderLocationPublicDto> locations) {
    if (locations.isEmpty) return null;
    return locations.first.displayLocation;
  }

  String _artisanPlaceholder(String seed) {
    // There are artisan_01.._08 placeholders
    final count = 8;
    final sum = seed.codeUnits.fold<int>(0, (a, b) => a + b);
    final index = (sum % count) + 1;
    final two = index.toString().padLeft(2, '0');
    return 'assets/images/placeholders/artisan_$two.png';
  }
}

class _ProviderPublicDto {
  final String id;
  final String displayName;
  final String? bio;
  final bool? isVerified;
  final String? profilePhoto;
  final double? avgRating;
  final int? reviewCount;
  final int? hiresCount;
  final List<String> serviceCategories;
  final List<_ProviderLocationPublicDto> locations;

  _ProviderPublicDto({
    required this.id,
    required this.displayName,
    this.bio,
    this.isVerified,
    this.profilePhoto,
    this.avgRating,
    this.reviewCount,
    this.hiresCount,
    required this.serviceCategories,
    required this.locations,
  });

  factory _ProviderPublicDto.fromJson(Map<String, dynamic> json) {
    final raw = json['service_categories'];
    List<String> categories;
    if (raw is List) {
      categories = raw
          .map((e) {
            if (e is Map<String, dynamic>) {
              return e['name']?.toString() ?? '';
            }
            return e.toString();
          })
          .where((s) => s.isNotEmpty)
          .toList(growable: false);
    } else if (raw is String) {
      final trimmed = raw.trim();
      if (trimmed.startsWith('[') && trimmed.endsWith(']')) {
        try {
          final parsed = jsonDecode(trimmed);
          if (parsed is List) {
            categories = parsed
                .map((e) {
                  if (e is Map<String, dynamic>) {
                    return e['name']?.toString() ?? '';
                  }
                  return e.toString();
                })
                .where((s) => s.isNotEmpty)
                .toList(growable: false);
          } else {
            categories = trimmed.isEmpty ? const [] : [trimmed];
          }
        } catch (_) {
          categories = trimmed.isEmpty ? const [] : [trimmed];
        }
      } else if (trimmed.contains(',')) {
        categories = trimmed
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList(growable: false);
      } else {
        categories = trimmed.isEmpty ? const [] : [trimmed];
      }
    } else {
      categories = const [];
    }

    return _ProviderPublicDto(
      id: json['id']?.toString() ?? '',
      displayName: json['display_name']?.toString() ?? '',
      bio: json['bio']?.toString(),
      isVerified: json['is_verified'] as bool?,
      profilePhoto: json['profile_photo']?.toString(),
      avgRating: (json['avg_rating'] is num)
          ? (json['avg_rating'] as num).toDouble()
          : double.tryParse(json['avg_rating']?.toString() ?? ''),
      reviewCount: (json['review_count'] is num)
          ? (json['review_count'] as num).toInt()
          : int.tryParse(json['review_count']?.toString() ?? ''),
      hiresCount: (json['hires_count'] is num)
          ? (json['hires_count'] as num).toInt()
          : int.tryParse(json['hires_count']?.toString() ?? ''),
      serviceCategories: categories,
      locations: (json['locations'] as List<dynamic>? ?? const [])
          .map(
            (e) => _ProviderLocationPublicDto.fromJson(
              (e as Map).cast<String, dynamic>(),
            ),
          )
          .toList(growable: false),
    );
  }
}

class _ProviderLocationPublicDto {
  final String? name;
  final String? address;
  final String? city;
  final String? state;
  final String? country;

  _ProviderLocationPublicDto({
    this.name,
    this.address,
    this.city,
    this.state,
    this.country,
  });

  factory _ProviderLocationPublicDto.fromJson(Map<String, dynamic> json) {
    return _ProviderLocationPublicDto(
      name: json['name']?.toString(),
      address: json['address']?.toString(),
      city: json['city']?.toString(),
      state: json['state']?.toString(),
      country: json['country']?.toString(),
    );
  }

  /// Returns a short display location (City, State) or falls back to address/name
  String get displayLocation {
    final parts = <String>[];
    if ((city ?? '').trim().isNotEmpty) parts.add(city!.trim());
    if ((state ?? '').trim().isNotEmpty) parts.add(state!.trim());
    if (parts.isNotEmpty) return parts.join(', ');
    if ((address ?? '').trim().isNotEmpty) return address!.trim();
    if ((name ?? '').trim().isNotEmpty) return name!.trim();
    return 'Unknown';
  }
}

class _ServiceCategoryLite {
  final String id;
  final String name;

  _ServiceCategoryLite({required this.id, required this.name});

  factory _ServiceCategoryLite.fromJson(Map<String, dynamic> json) {
    return _ServiceCategoryLite(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
    );
  }
}
