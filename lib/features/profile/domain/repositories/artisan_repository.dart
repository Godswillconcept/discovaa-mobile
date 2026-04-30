import '../entities/artisan_entity.dart';

abstract class ArtisanRepository {
  Future<List<Artisan>> getArtisans();

  /// Retrieve artisans symmetrically from local Hive cache instantly
  List<Artisan> getCachedArtisans({
    String? search,
    String? category,
    String? ordering,
    double? minRating,
    double? minPrice,
    double? maxPrice,
    String? location,
    bool? isAvailableOnly,
  });

  /// Search or filter artisans from the backend.
  ///
  /// - [search]: free-text search across provider name/bio.
  /// - [category]: category identifier to filter by. Can be a slug, UUID, or display name; repository will resolve appropriately.
  /// - [ordering]: backend ordering key (e.g. '-avg_rating', '-hires_count', 'distance').
  /// - [minRating]: minimum average rating filter (0-5).
  /// - [minPrice]: minimum hourly rate filter.
  /// - [maxPrice]: maximum hourly rate filter.
  /// - [location]: location search string (city/state).
  /// - [isAvailableOnly]: filter for available providers only.
  Future<List<Artisan>> searchArtisans({
    String? search,
    String? category,
    String? ordering,
    double? minRating,
    double? minPrice,
    double? maxPrice,
    String? location,
    bool? isAvailableOnly,
  });
}
