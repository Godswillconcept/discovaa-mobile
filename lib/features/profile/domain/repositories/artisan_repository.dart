import '../entities/artisan_entity.dart';

abstract class ArtisanRepository {
  Future<List<Artisan>> getArtisans();

  /// Retrieve artisans symmetrically from local Hive cache instantly
  List<Artisan> getCachedArtisans({
    String? search,
    String? category,
    String? ordering,
  });

  /// Search or filter artisans from the backend.
  ///
  /// - [search]: free-text search across provider name/bio.
  /// - [category]: category identifier to filter by. Can be a slug, UUID, or display name; repository will resolve appropriately.
  /// - [ordering]: backend ordering key (e.g. '-avg_rating', '-hires_count', 'distance').
  Future<List<Artisan>> searchArtisans({
    String? search,
    String? category,
    String? ordering,
  });
}
