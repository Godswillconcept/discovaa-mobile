import 'package:discovaa/core/constants/app_constants.dart';
import 'package:discovaa/features/authentication/presentation/widgets/identity_verification_reminder_widget.dart';
import 'package:discovaa/features/home/presentation/widgets/artisan_card.dart';
import 'package:discovaa/features/home/presentation/widgets/category_item.dart';
import 'package:discovaa/features/home/presentation/widgets/filter_bottom_sheet.dart';
import 'package:discovaa/features/home/presentation/widgets/pagination_button.dart';
import 'package:discovaa/features/home/presentation/widgets/sort_dropdown.dart';
import 'package:discovaa/features/profile/presentation/providers/artisan_provider.dart';
import 'package:discovaa/shared/presentation/widgets/main_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

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
                  // Note: We don't invalidate artisanFilterProvider to preserve filter state
                  // Allow states to reload safely
                  await Future.delayed(const Duration(milliseconds: 100));
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 20.h),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20.w),
                        child: _ExploreSearchField(),
                      ),
                      SizedBox(height: 32.h),
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
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16.w,
            mainAxisSpacing: 16.h,
            mainAxisExtent: 300.h,
          ),
          itemCount: 4,
          itemBuilder: (context, index) => Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(20.r),
            ),
          ),
        ),
        SizedBox(height: 16.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (index) {
            return Container(
              margin: EdgeInsets.only(right: index == 2 ? 0 : 12.w),
              width: 32.w,
              height: 32.h,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8.r),
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Text(
            'Browse by Category',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),
        SizedBox(height: 20.h),
        SizedBox(
          height: 100.h,
          child: ListView.separated(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            separatorBuilder: (context, index) => SizedBox(width: 16.w),
            itemBuilder: (context, index) {
              final cat = categories[index];
              final isSelected = filter.selectedCategory == cat.name;
              return SizedBox(
                width: 160.w,
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
        SizedBox(width: 12.w),
        Container(
          width: 32.w,
          height: 32.h,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Text(
            '$currentPage',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14.sp,
              color: Colors.black,
            ),
          ),
        ),
        SizedBox(width: 12.w),
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
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              Text(
                'Service Providers',
                style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 8.h),
              Row(
                children: [
                  _FilterButton(filter: filter),
                  SizedBox(width: 8.w),
                  SortDropdown(filter: filter),
                ],
              ),
            ],
          ),
          SizedBox(height: 10.h),
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
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16.w,
                      mainAxisSpacing: 16.h,
                      mainAxisExtent: 300.h,
                    ),
                    itemCount: displayedArtisans.length,
                    itemBuilder: (context, index) =>
                        ArtisanCard(artisan: displayedArtisans[index]),
                  ),
                  if (artisans.isNotEmpty) ...[
                    SizedBox(height: 16.h),
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
        borderRadius: BorderRadius.circular(15.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15.r,
            offset: Offset(0, 5.h),
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
              hintStyle: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 14.sp,
              ),
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
              contentPadding: EdgeInsets.symmetric(vertical: 15.h),
            ),
          );
        },
      ),
    );
  }
}

class _FilterButton extends ConsumerWidget {
  final ArtisanFilterState filter;

  const _FilterButton({required this.filter});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeFilterCount = filter.activeFilterCount;
    final hasActiveFilters = activeFilterCount > 0;

    return GestureDetector(
      onTap: () => FilterBottomSheet.show(context),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: hasActiveFilters ? Colors.white : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(
            color: hasActiveFilters ? Colors.black : Colors.grey.shade300,
            width: hasActiveFilters ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.tune,
              color: hasActiveFilters ? Colors.black : Colors.grey.shade600,
              size: 18.sp,
            ),
            SizedBox(width: 6.w),
            Text(
              'Filters${activeFilterCount > 0 ? ' ($activeFilterCount)' : ''}',
              style: TextStyle(
                color: hasActiveFilters ? Colors.black : Colors.grey.shade600,
                fontSize: 12.sp,
                fontWeight: hasActiveFilters
                    ? FontWeight.w600
                    : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
