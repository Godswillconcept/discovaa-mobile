import 'package:flutter/material.dart';
import 'package:discovaa/features/profile/domain/entities/artisan_entity.dart';

class ArtisanBusinessInfo extends StatelessWidget {
  final Artisan artisan;

  const ArtisanBusinessInfo({super.key, required this.artisan});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBFF),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Flexible(
                child: Text(
                  '${artisan.category} : ${artisan.name}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              if (artisan.isVerified)
                const Icon(Icons.verified_user, color: Colors.amber, size: 16),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${artisan.yearsInBusiness} years in business',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const Text(' • ', style: TextStyle(color: Colors.grey)),
              Text(
                '${artisan.hiresCount} hires on Discovaa',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
          const Divider(),
        ],
      ),
    );
  }
}
