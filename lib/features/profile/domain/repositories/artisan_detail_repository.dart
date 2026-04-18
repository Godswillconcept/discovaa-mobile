import '../entities/artisan_entity.dart';

/// Repository for fetching detailed artisan profile data
abstract class ArtisanDetailRepository {
  /// Get detailed artisan profile by ID
  /// Fetches from /api/providers/{id}/
  Future<Artisan> getArtisanDetail(String artisanId);

  /// Get services offered by an artisan
  /// Fetches from /api/services/?provider={id}
  Future<List<ArtisanService>> getArtisanServices(String artisanId);

  /// Get reviews for an artisan
  /// Fetches from /api/reviews/?provider={id}
  Future<List<Review>> getArtisanReviews(String artisanId);

  /// Get availability schedule for an artisan
  /// Fetches from /api/providers/{id}/availability/
  Future<Map<String, String>> getArtisanAvailability(String artisanId);

  /// Clear cache for a specific artisan
  Future<void> clearCache(String artisanId);

  // Synchronous cache retrievals
  Artisan? getCachedArtisanDetail(String artisanId);
  List<ArtisanService> getCachedArtisanServices(String artisanId);
  List<Review> getCachedArtisanReviews(String artisanId);
  Map<String, String> getCachedArtisanAvailability(String artisanId);
}

/// Extended service information for an artisan
class ArtisanService {
  final String id;
  final String title;
  final String? description;
  final double? hourlyRate;
  final String priceRange;
  final List<String> mediaUrls;

  const ArtisanService({
    required this.id,
    required this.title,
    this.description,
    this.hourlyRate,
    required this.priceRange,
    required this.mediaUrls,
  });
}

/// Review with user information
class ArtisanReview {
  final String id;
  final String userName;
  final String? userAvatar;
  final double rating;
  final String comment;
  final String date;

  const ArtisanReview({
    required this.id,
    required this.userName,
    this.userAvatar,
    required this.rating,
    required this.comment,
    required this.date,
  });
}
