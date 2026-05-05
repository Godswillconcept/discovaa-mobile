import 'package:flutter/material.dart';
import 'package:discovaa/features/profile/domain/entities/artisan_entity.dart';

class ArtisanAvailabilitySection extends StatelessWidget {
  final Artisan artisan;

  const ArtisanAvailabilitySection({super.key, required this.artisan});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Available Dates and Time',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ...artisan.availability.entries.map(
          (e) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                const Icon(Icons.circle, size: 6, color: Colors.grey),
                const SizedBox(width: 8),
                Text(e.key, style: const TextStyle(color: Colors.grey)),
                const SizedBox(width: 12),
                Text(e.value, style: const TextStyle(color: Colors.black87)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Divider(),
      ],
    );
  }
}
