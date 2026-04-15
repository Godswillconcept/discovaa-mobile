import 'package:discovaa/app/router/route_names.dart';
import 'package:discovaa/core/utils/text_formatter.dart';
import 'package:discovaa/features/profile/presentation/providers/artisan_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ArtisanCard extends ConsumerWidget {
  final Artisan artisan;

  const ArtisanCard({super.key, required this.artisan});

  // Generate a fallback bio when API returns empty bio
  String _getFallbackBio(String name, String category) {
    final formattedName = TextFormatter.capitalizeWords(name.split(' ').first);
    final formattedCategory = TextFormatter.capitalizeWords(category);
    return '$formattedName offers professional $formattedCategory services with expertise and dedication. Contact now for quality workmanship.';
  }

  String get _displayBio {
    final bio = artisan.bio.trim();
    return bio.isEmpty ? _getFallbackBio(artisan.name, artisan.category) : bio;
  }

  String get _displayName => TextFormatter.capitalizeWords(artisan.name);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              Container(
                height: 100.0,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  image: DecorationImage(
                    image: AssetImage(artisan.profileImage),
                    fit: BoxFit.cover,
                    onError: (exception, stackTrace) {
                      // Handle error
                    },
                  ),
                ),
              ),
              if (artisan.isVerified)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.verified_user,
                      color: Colors.amber,
                      size: 16,
                    ),
                  ),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _displayName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        artisan.category,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Text(' • ', style: TextStyle(color: Colors.grey)),
                    RatingBarIndicator(
                      rating: artisan.rating,
                      itemBuilder: (context, index) =>
                          const Icon(Icons.star, color: Colors.amber),
                      itemCount: 5,
                      itemSize: 12.0,
                      unratedColor: Colors.amber.withValues(alpha: 0.2),
                      direction: Axis.horizontal,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      artisan.rating.toString(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _displayBio,
                  style: const TextStyle(color: Colors.black54, fontSize: 11),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 14,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        artisan.location,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 11,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 38,
                  child: ElevatedButton(
                    onPressed: () {
                      ref.read(bookingProvider.notifier).selectArtisan(artisan);
                      context.push(RouteNames.artisanProfile);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'View',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
