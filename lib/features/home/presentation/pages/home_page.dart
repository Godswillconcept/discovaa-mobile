import 'package:discovaa/core/constants/app_constants.dart';
import 'package:discovaa/features/authentication/presentation/widgets/identity_verification_reminder_widget.dart';
import 'package:discovaa/features/home/presentation/widgets/artisan_card.dart';
import 'package:discovaa/features/home/presentation/widgets/category_item.dart';
import 'package:discovaa/features/home/presentation/widgets/pagination_button.dart';
import 'package:discovaa/features/home/presentation/widgets/sort_dropdown.dart';
import 'package:discovaa/features/profile/presentation/providers/artisan_provider.dart';
import 'package:discovaa/shared/presentation/widgets/main_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light, // Light icons on dark header
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            const MainHeader(),
            // Identity verification reminder banner (shows if verification pending)
            const IdentityVerificationReminderWidget(),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(categoriesProvider);
                  ref.invalidate(filteredArtisansProvider);
                  // Allow states to reload safely
                  await Future.delayed(const Duration(milliseconds: 100));
                },
                child: const SingleChildScrollView(
                  physics: AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 20),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: _ExploreSearchField(),
                      ),
                      SizedBox(height: 32),
                      // Browse by Category
                      _BrowseByCategorySection(),
                      // Service Providers Section
                      _ServiceProvidersSection(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeProvidersSkeleton extends StatelessWidget {
  const _HomeProvidersSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            mainAxisExtent: 300,
          ),
          itemCount: 4,
          itemBuilder: (context, index) => Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (index) {
            return Container(
              margin: EdgeInsets.only(right: index == 2 ? 0 : 12),
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _BrowseByCategorySection extends ConsumerWidget {
  const _BrowseByCategorySection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesProvider);
    final filter = ref.watch(artisanFilterProvider);
    final hasActiveFilter = filter.selectedCategory != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Browse by Category',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              if (hasActiveFilter)
                GestureDetector(
                  onTap: () {
                    ref.read(artisanFilterProvider.notifier).setCategory(null);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.clear, size: 16, color: Colors.black),
                        SizedBox(width: 4),
                        Text(
                          'Clear filter',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 100,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            separatorBuilder: (context, index) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              final cat = categories[index];
              final isSelected = filter.selectedCategory == cat.name;
              return SizedBox(
                width: 160,
                child: CategoryItem(
                  category: cat,
                  isSelected: isSelected,
                  onTap: () {
                    ref
                        .read(artisanFilterProvider.notifier)
                        .setCategory(isSelected ? null : cat.name);
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _Pagination extends ConsumerWidget {
  final int currentPage;
  final int totalPages;

  const _Pagination({required this.currentPage, required this.totalPages});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        PaginationButton(
          onTap: currentPage > 1
              ? () => ref.read(categoryPageProvider.notifier).state--
              : null,
          icon: Icons.arrow_back_ios_new,
        ),
        const SizedBox(width: 12),
        Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '$currentPage',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Colors.black,
            ),
          ),
        ),
        const SizedBox(width: 12),
        PaginationButton(
          onTap: currentPage < totalPages
              ? () => ref.read(categoryPageProvider.notifier).state++
              : null,
          icon: Icons.arrow_forward_ios,
        ),
      ],
    );
  }
}

class _ServiceProvidersSection extends ConsumerWidget {
  const _ServiceProvidersSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final artisansAsync = ref.watch(filteredArtisansProvider);
    final filter = ref.watch(artisanFilterProvider);
    final currentPage = ref.watch(artisanPageProvider);

    const int itemsPerPage = 10;

    return Container(
      width: double.infinity,
      color: const Color(0xFFF8FBFF),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Service Providers',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SortDropdown(filter: filter),
            ],
          ),
          const SizedBox(height: 20),
          artisansAsync.when(
            data: (artisans) {
              if (artisans.isEmpty) {
                return const Center(
                  child: Text("No providers found matching your search."),
                );
              }

              final totalPages = (artisans.length / itemsPerPage).ceil();
              final displayedArtisans = artisans
                  .skip((currentPage - 1) * itemsPerPage)
                  .take(itemsPerPage)
                  .toList();

              return Column(
                children: [
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          mainAxisExtent: 300,
                        ),
                    itemCount: displayedArtisans.length,
                    itemBuilder: (context, index) =>
                        ArtisanCard(artisan: displayedArtisans[index]),
                  ),
                  if (artisans.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _Pagination(
                      currentPage: currentPage,
                      totalPages: totalPages,
                    ),
                  ],
                ],
              );
            },
            loading: () => const _HomeProvidersSkeleton(),
            error: (e, s) => Center(child: Text("Error loading providers: $e")),
          ),
        ],
      ),
    );
  }
}

class _ExploreSearchField extends ConsumerWidget {
  const _ExploreSearchField();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final TextEditingController searchController = TextEditingController();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ValueListenableBuilder<TextEditingValue>(
        valueListenable: searchController,
        builder: (context, value, child) {
          return TextField(
            controller: searchController,
            onChanged: (val) {
              ref.read(artisanFilterProvider.notifier).setSearchQuery(val);
            },
            decoration: InputDecoration(
              hintText: "What service are you looking for?",
              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
              prefixIcon: const Icon(Icons.search, color: AppColors.primary),
              suffixIcon: value.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: Colors.grey),
                      onPressed: () {
                        searchController.clear();
                        ref
                            .read(artisanFilterProvider.notifier)
                            .setSearchQuery('');
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 15),
            ),
          );
        },
      ),
    );
  }
}
