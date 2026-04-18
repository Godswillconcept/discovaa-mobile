import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:discovaa/app/dependency_injection/service_locator.dart';
import 'package:discovaa/core/constants/api_endpoints.dart';
import 'package:discovaa/core/network/api_helpers.dart';
import 'package:discovaa/core/network/dio_client.dart';
import 'package:discovaa/core/network/network_info.dart';
import 'package:discovaa/core/storage/hive_service.dart';
import '../../domain/entities/artisan_entity.dart';
import '../../domain/repositories/artisan_repository.dart';
import '../../data/repositories/api_artisan_repository.dart';

export '../../domain/entities/artisan_entity.dart';

final artisanRepositoryProvider = Provider<ArtisanRepository>((ref) {
  return ApiArtisanRepository(
    dioClient: sl<DioClient>(),
    hiveService: sl<HiveService>(),
    networkInfo: sl<NetworkInfo>(),
  );
});

final artisansProvider = AsyncNotifierProvider<ArtisansNotifier, List<Artisan>>(
  () {
    return ArtisansNotifier();
  },
);

class ArtisansNotifier extends AsyncNotifier<List<Artisan>> {
  @override
  Future<List<Artisan>> build() async {
    return ref.watch(artisanRepositoryProvider).getArtisans();
  }
}

class CategoriesNotifier extends StateNotifier<List<ArtisanCategory>> {
  CategoriesNotifier(this._dio, this._hiveService, this._networkInfo)
    : super(const []) {
    _load();
  }

  final DioClient _dio;
  final HiveService _hiveService;
  // ignore: unused_field
  final NetworkInfo _networkInfo;
  static const _categoriesCacheKey = 'artisans.cache.categories.ui';

  Future<void> _load() async {
    final cached = _readCachedCategories();
    if (cached.isNotEmpty) {
      state = cached;
    }
    
    try {
      final response = await _dio.get(
        ApiEndpoints.serviceCategories,
        options: Options(headers: {'X-Skip-Auth': 'true'}),
      );
      final envelope = decodeListEnvelope(
        response,
        (item) => _CategoryLite.fromJson(item),
      );
      final items = envelope.data
          .map(
            (c) => ArtisanCategory(
              name: c.name,
              image: _categoryPlaceholder(c.name),
            ),
          )
          .toList(growable: false);
      await _hiveService.setList(
        _categoriesCacheKey,
        items.map((item) => {'name': item.name, 'image': item.image}).toList(),
      );
      if (mounted) {
        state = items;
      }
    } catch (_) {
      if (cached.isEmpty && mounted) {
        final fallbackCached = _readCachedCategories();
        state = fallbackCached;
      }
    }
  }

  List<ArtisanCategory> _readCachedCategories() {
    final cached =
        _hiveService.getList<dynamic>(_categoriesCacheKey) ?? const [];
    return cached
        .whereType<Map>()
        .map(
          (item) => ArtisanCategory(
            name: item['name']?.toString() ?? '',
            image: item['image']?.toString() ?? _categoryPlaceholder('general'),
          ),
        )
        .where((item) => item.name.isNotEmpty)
        .toList(growable: false);
  }

  String _categoryPlaceholder(String seed) {
    // Available placeholders: 01,02,03,04,05,07
    const variants = [1, 2, 3, 4, 5, 7];
    final sum = seed.codeUnits.fold<int>(0, (a, b) => a + b);
    final index = variants[sum % variants.length];
    final two = index.toString().padLeft(2, '0');
    return 'assets/images/placeholders/category_$two.png';
  }
}

final categoriesProvider =
    StateNotifierProvider<CategoriesNotifier, List<ArtisanCategory>>(
      (ref) => CategoriesNotifier(
        sl<DioClient>(),
        sl<HiveService>(),
        sl<NetworkInfo>(),
      ),
    );

final showAllCategoriesProvider = StateProvider<bool>((ref) => false);
final categoryPageProvider = StateProvider<int>((ref) => 1);
final artisanPageProvider = StateProvider<int>((ref) => 1);

enum ArtisanSort { categories, popularity, ratings, proximity }

class ArtisanFilterState {
  final ArtisanSort sortBy;
  final String? selectedCategory;
  final String searchQuery;

  ArtisanFilterState({
    this.sortBy = ArtisanSort.categories,
    this.selectedCategory,
    this.searchQuery = '',
  });

  ArtisanFilterState copyWith({
    ArtisanSort? sortBy,
    String? selectedCategory,
    String? searchQuery,
  }) {
    return ArtisanFilterState(
      sortBy: sortBy ?? this.sortBy,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

class ArtisanFilterNotifier extends StateNotifier<ArtisanFilterState> {
  final Ref _ref;

  ArtisanFilterNotifier(this._ref) : super(ArtisanFilterState());

  void setSortBy(ArtisanSort sort) {
    state = state.copyWith(sortBy: sort);
    _resetPage();
  }

  void setCategory(String? category) {
    state = state.copyWith(selectedCategory: category);
    _resetPage();
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
    _resetPage();
  }

  void _resetPage() {
    _ref.read(artisanPageProvider.notifier).state = 1;
  }
}

final artisanFilterProvider =
    StateNotifierProvider<ArtisanFilterNotifier, ArtisanFilterState>((ref) {
      return ArtisanFilterNotifier(ref);
    });

class BookingState {
  final DateTime? selectedDate;
  final String? selectedTime;
  final bool isConfirming;
  final bool isConfirmed;
  final Artisan? selectedArtisan;

  BookingState({
    this.selectedDate,
    this.selectedTime,
    this.isConfirming = false,
    this.isConfirmed = false,
    this.selectedArtisan,
  });

  BookingState copyWith({
    DateTime? selectedDate,
    String? selectedTime,
    bool? isConfirming,
    bool? isConfirmed,
    Artisan? selectedArtisan,
  }) {
    return BookingState(
      selectedDate: selectedDate ?? this.selectedDate,
      selectedTime: selectedTime ?? this.selectedTime,
      isConfirming: isConfirming ?? this.isConfirming,
      isConfirmed: isConfirmed ?? this.isConfirmed,
      selectedArtisan: selectedArtisan ?? this.selectedArtisan,
    );
  }
}

class BookingNotifier extends StateNotifier<BookingState> {
  BookingNotifier() : super(BookingState());

  void selectArtisan(Artisan artisan) =>
      state = state.copyWith(selectedArtisan: artisan);
  void selectDate(DateTime date) => state = state.copyWith(selectedDate: date);
  void selectTime(String time) => state = state.copyWith(selectedTime: time);

  Future<void> confirmBooking() async {
    state = state.copyWith(isConfirming: true);
    await Future.delayed(const Duration(seconds: 2));
    state = state.copyWith(isConfirming: false, isConfirmed: true);
  }

  void reset() => state = BookingState();
}

final bookingProvider = StateNotifierProvider<BookingNotifier, BookingState>((
  ref,
) {
  return BookingNotifier();
});

class FilteredArtisansNotifier extends AsyncNotifier<List<Artisan>> {
  @override
  Future<List<Artisan>> build() async {
    final filter = ref.watch(artisanFilterProvider);
    final repo = ref.watch(artisanRepositoryProvider);

    String? ordering;
    switch (filter.sortBy) {
      case ArtisanSort.ratings:
        ordering = '-avg_rating';
        break;
      case ArtisanSort.popularity:
        ordering = '-hires_count';
        break;
      case ArtisanSort.proximity:
        // Requires geo context; default to none for now
        ordering = null;
        break;
      case ArtisanSort.categories:
        ordering = null;
        break;
    }

    final cached = repo.getCachedArtisans(
      search: filter.searchQuery.isNotEmpty ? filter.searchQuery : null,
      category: filter.selectedCategory,
      ordering: ordering,
    );
    if (cached.isNotEmpty) {
      state = AsyncData(cached);
    }

    final results = await repo.searchArtisans(
      search: filter.searchQuery.isNotEmpty ? filter.searchQuery : null,
      category: filter.selectedCategory,
      ordering: ordering,
    );
    return results;
  }
}

final filteredArtisansProvider = AsyncNotifierProvider<FilteredArtisansNotifier, List<Artisan>>(() {
  return FilteredArtisansNotifier();
});

class _CategoryLite {
  final String id;
  final String name;
  const _CategoryLite({required this.id, required this.name});
  factory _CategoryLite.fromJson(Map<String, dynamic> json) {
    return _CategoryLite(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
    );
  }
}
