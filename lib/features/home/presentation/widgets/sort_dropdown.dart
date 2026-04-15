import 'package:discovaa/features/profile/presentation/providers/artisan_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SortDropdown extends ConsumerWidget {
  final ArtisanFilterState filter;

  const SortDropdown({super.key, required this.filter});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<ArtisanSort>(
      initialValue: filter.sortBy,
      offset: const Offset(0, 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (sort) =>
          ref.read(artisanFilterProvider.notifier).setSortBy(sort),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Text(
              'Sort by: ${getSortName(filter.sortBy)}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 18),
          ],
        ),
      ),
      itemBuilder: (context) => ArtisanSort.values.map((sort) {
        final isSelected = filter.sortBy == sort;
        return PopupMenuItem<ArtisanSort>(
          value: sort,
          child: Row(
            children: [
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? Colors.black : Colors.grey.shade400,
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? Center(
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            color: Colors.black,
                            shape: BoxShape.circle,
                          ),
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Text(
                getSortName(sort),
                style: TextStyle(
                  color: isSelected ? Colors.black : Colors.black87,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  String getSortName(ArtisanSort sort) {
    switch (sort) {
      case ArtisanSort.categories:
        return 'Categories';
      case ArtisanSort.popularity:
        return 'Popularity';
      case ArtisanSort.ratings:
        return 'Ratings';
      case ArtisanSort.proximity:
        return 'Proximity';
    }
  }
}
