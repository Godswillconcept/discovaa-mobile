import 'package:flutter/material.dart';
import 'package:discovaa/features/profile/domain/entities/artisan_entity.dart';

class ArtisanQualificationsSection extends StatelessWidget {
  final Artisan artisan;

  const ArtisanQualificationsSection({super.key, required this.artisan});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Certifications and Qualifications',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 12),
        if (artisan.certifications.isEmpty)
          const Text(
            'No certifications listed',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          )
        else
          Wrap(
            spacing: 20,
            runSpacing: 10,
            children: artisan.certifications
                .map(
                  (c) => Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.circle, size: 6, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text(
                        c,
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
        const SizedBox(height: 16),
        const Divider(),
      ],
    );
  }
}
