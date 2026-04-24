import 'package:discovaa/features/profile/presentation/providers/artisan_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provides the list of favorited artisans by filtering cached artisans
/// from Hive storage against the IDs stored in [favoriteArtisansProvider].
/// This avoids making API calls when viewing favorites.
final favoritesProvider = Provider<List<Artisan>>((ref) {
  final repository = ref.watch(artisanRepositoryProvider);
  final favoriteIds = ref.watch(favoriteArtisansProvider);

  // Use getCachedArtisans to get artisans from Hive storage without API calls
  final allArtisans = repository.getCachedArtisans();

  return allArtisans.where((a) => favoriteIds.contains(a.id)).toList();
});
