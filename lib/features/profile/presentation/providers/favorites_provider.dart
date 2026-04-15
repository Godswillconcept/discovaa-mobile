import 'package:discovaa/features/profile/presentation/providers/artisan_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final favoritesProvider = Provider<AsyncValue<List<Artisan>>>((ref) {
  final allArtisansAsync = ref.watch(artisansProvider);
  
  return allArtisansAsync.whenData((artisans) {
    // Filter artisans who have a lastSeen value (our mock for favorites/recent connections)
    return artisans.where((a) => a.lastSeen != null).toList()
      ..sort((a, b) => b.lastSeen!.compareTo(a.lastSeen!));
  });
});
