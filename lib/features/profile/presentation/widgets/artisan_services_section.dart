import 'package:flutter/material.dart';
import 'package:discovaa/features/profile/domain/entities/artisan_entity.dart';
import 'package:discovaa/features/profile/domain/repositories/artisan_detail_repository.dart'
    show ArtisanService;

class ArtisanServicesSection extends StatelessWidget {
  final Artisan artisan;
  final List<ArtisanService> services;

  const ArtisanServicesSection({
    super.key,
    required this.artisan,
    this.services = const [],
  });

  @override
  Widget build(BuildContext context) {
    // Use API services if available, otherwise fall back to base artisan services.
    final serviceTitles = services.isNotEmpty
        ? services.map((s) => s.title).toList()
        : artisan.services;

    if (serviceTitles.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Text('No services listed', style: TextStyle(color: Colors.grey)),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Services',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 30,
          runSpacing: 10,
          children: serviceTitles
              .map(
                (s) => Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.circle, size: 6, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      s,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              )
              .toList(),
        ),
        const Divider(),
      ],
    );
  }
}
