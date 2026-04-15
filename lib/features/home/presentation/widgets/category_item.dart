import 'package:discovaa/features/profile/presentation/providers/artisan_provider.dart';
import 'package:flutter/material.dart';

class CategoryItem extends StatelessWidget {
  final ArtisanCategory category;
  final bool isSelected;
  final VoidCallback onTap;

  const CategoryItem({
    super.key,
    required this.category,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: double.infinity,
            height: 70,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: isSelected
                  ? Border.all(color: Colors.black, width: 2)
                  : null,
              image: DecorationImage(
                image: AssetImage(category.image),
                fit: BoxFit.cover,
                onError: (exception, stackTrace) => Container(
                  color: Colors.grey.shade200,
                  child: const Icon(Icons.image, color: Colors.grey),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            category.name,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? Colors.black : Colors.black87,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
