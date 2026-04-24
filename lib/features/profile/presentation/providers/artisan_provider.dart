import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:discovaa/app/dependency_injection/service_locator.dart';
import 'package:discovaa/core/constants/api_endpoints.dart';
import 'package:discovaa/core/network/api_helpers.dart';
import 'package:discovaa/core/network/dio_client.dart';
import 'package:discovaa/core/network/network_info.dart';
import 'package:discovaa/core/storage/hive_service.dart';
import 'package:discovaa/features/bookings/domain/repositories/bookings_repository.dart';
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

enum BookingType { onsite, workshop }

/// Extended service information for booking (imported from artisan_detail_repository)
/// We use a simplified version here to avoid circular imports
class BookingService {
  final String id;
  final String title;
  final double? hourlyRate;
  final String priceRange;

  const BookingService({
    required this.id,
    required this.title,
    this.hourlyRate,
    required this.priceRange,
  });
}

class BookingState {
  static const Object _unset = Object();

  final DateTime? selectedDate;
  final String? selectedTime;
  final bool isConfirming;
  final bool isConfirmed;
  final Artisan? selectedArtisan;
  final Set<String> selectedServices;
  final BookingType bookingType;
  final TimeOfDay? startTime;
  final TimeOfDay? endTime;
  final String? address;
  final bool useCurrentLocation;
  final double? latitude;
  final double? longitude;
  final String? notes;

  /// Full service data with pricing information
  final List<BookingService> availableServices;

  BookingState({
    this.selectedDate,
    this.selectedTime,
    this.isConfirming = false,
    this.isConfirmed = false,
    this.selectedArtisan,
    this.selectedServices = const {},
    this.bookingType = BookingType.onsite,
    this.startTime,
    this.endTime,
    this.address,
    this.useCurrentLocation = false,
    this.latitude,
    this.longitude,
    this.notes,
    this.availableServices = const [],
  });

  BookingState copyWith({
    Object? selectedDate = _unset,
    Object? selectedTime = _unset,
    bool? isConfirming,
    bool? isConfirmed,
    Object? selectedArtisan = _unset,
    Set<String>? selectedServices,
    BookingType? bookingType,
    Object? startTime = _unset,
    Object? endTime = _unset,
    Object? address = _unset,
    bool? useCurrentLocation,
    Object? latitude = _unset,
    Object? longitude = _unset,
    Object? notes = _unset,
    List<BookingService>? availableServices,
  }) {
    return BookingState(
      selectedDate: identical(selectedDate, _unset)
          ? this.selectedDate
          : selectedDate as DateTime?,
      selectedTime: identical(selectedTime, _unset)
          ? this.selectedTime
          : selectedTime as String?,
      isConfirming: isConfirming ?? this.isConfirming,
      isConfirmed: isConfirmed ?? this.isConfirmed,
      selectedArtisan: identical(selectedArtisan, _unset)
          ? this.selectedArtisan
          : selectedArtisan as Artisan?,
      selectedServices: selectedServices ?? this.selectedServices,
      bookingType: bookingType ?? this.bookingType,
      startTime: identical(startTime, _unset)
          ? this.startTime
          : startTime as TimeOfDay?,
      endTime: identical(endTime, _unset)
          ? this.endTime
          : endTime as TimeOfDay?,
      address: identical(address, _unset) ? this.address : address as String?,
      useCurrentLocation: useCurrentLocation ?? this.useCurrentLocation,
      latitude: identical(latitude, _unset)
          ? this.latitude
          : latitude as double?,
      longitude: identical(longitude, _unset)
          ? this.longitude
          : longitude as double?,
      notes: identical(notes, _unset) ? this.notes : notes as String?,
      availableServices: availableServices ?? this.availableServices,
    );
  }

  String get durationDisplay {
    if (startTime == null || endTime == null) return '';

    final startMinutes = startTime!.hour * 60 + startTime!.minute;
    final endMinutes = endTime!.hour * 60 + endTime!.minute;
    final totalMinutes = endMinutes - startMinutes;

    if (totalMinutes <= 0) return '';

    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;

    if (hours > 0 && minutes > 0) {
      return '$hours hrs $minutes mins';
    } else if (hours > 0) {
      return '$hours hrs';
    } else {
      return '$minutes mins';
    }
  }

  /// Get the hourly rate for selected services (lowest rate if multiple)
  double? get hourlyRateForSelectedServices {
    if (selectedServices.isEmpty || availableServices.isEmpty) return null;

    final selectedServiceData = availableServices
        .where(
          (s) => selectedServices.contains(s.title) && s.hourlyRate != null,
        )
        .toList();

    if (selectedServiceData.isEmpty) return null;

    return selectedServiceData
        .map((s) => s.hourlyRate!)
        .reduce((a, b) => a < b ? a : b);
  }

  /// Get price ranges for selected services
  List<String> get priceRangesForSelectedServices {
    if (selectedServices.isEmpty || availableServices.isEmpty) return const [];

    return availableServices
        .where(
          (s) => selectedServices.contains(s.title) && s.priceRange.isNotEmpty,
        )
        .map((s) => s.priceRange)
        .toList();
  }

  /// Calculate estimated cost based on duration and hourly rate
  String get estimatedCostDisplay {
    final rate = hourlyRateForSelectedServices;
    if (rate == null || startTime == null || endTime == null) {
      // Show price range if no hourly rate
      final ranges = priceRangesForSelectedServices;
      if (ranges.isNotEmpty) {
        return ranges.length == 1
            ? ranges.first
            : '${ranges.first} - ${ranges.last}';
      }
      return 'Contact for pricing';
    }

    final startMinutes = startTime!.hour * 60 + startTime!.minute;
    final endMinutes = endTime!.hour * 60 + endTime!.minute;
    final totalHours = (endMinutes - startMinutes) / 60.0;

    if (totalHours <= 0) return 'Contact for pricing';

    final estimatedCost = rate * totalHours;
    return '₦${estimatedCost.toInt()} - ₦${(estimatedCost * 1.2).toInt()}';
  }

  bool get isValid {
    if (selectedDate == null) return false;
    if (startTime == null || endTime == null) return false;
    // Only require address for onsite bookings
    if (bookingType == BookingType.onsite &&
        (address == null || address!.isEmpty)) {
      return false;
    }
    if (selectedServices.isEmpty) return false;

    final startMinutes = startTime!.hour * 60 + startTime!.minute;
    final endMinutes = endTime!.hour * 60 + endTime!.minute;
    if (endMinutes <= startMinutes) return false;

    return true;
  }
}

class BookingNotifier extends StateNotifier<BookingState> {
  BookingNotifier() : super(BookingState());

  void selectArtisan(Artisan artisan) =>
      state = state.copyWith(selectedArtisan: artisan);
  void selectDate(DateTime date) => state = state.copyWith(selectedDate: date);
  void selectTime(String time) => state = state.copyWith(selectedTime: time);

  void selectBookingType(BookingType type) =>
      state = state.copyWith(bookingType: type);

  void selectStartTime(TimeOfDay? time) =>
      state = state.copyWith(startTime: time);

  void selectEndTime(TimeOfDay? time) => state = state.copyWith(endTime: time);

  void setAddress(String address) => state = state.copyWith(address: address);

  void toggleUseCurrentLocation(bool value) =>
      state = state.copyWith(useCurrentLocation: value);

  void setLocation(double? lat, double? lng) {
    state = state.copyWith(latitude: lat, longitude: lng);
  }

  void setNotes(String notes) => state = state.copyWith(notes: notes);

  void toggleService(String service) {
    final currentServices = Set<String>.from(state.selectedServices);
    if (currentServices.contains(service)) {
      currentServices.remove(service);
    } else {
      currentServices.add(service);
    }
    state = state.copyWith(selectedServices: currentServices);
  }

  void clearServices() => state = state.copyWith(selectedServices: const {});

  /// Set available services with pricing data (called when opening booking modal)
  void setAvailableServices(List<BookingService> services) {
    state = state.copyWith(availableServices: services);
  }

  Future<void> confirmBooking() async {
    state = state.copyWith(isConfirming: true);

    try {
      final bookingsRepository = sl<BookingsRepository>();
      final artisan = state.selectedArtisan;

      if (artisan == null ||
          state.selectedDate == null ||
          state.startTime == null ||
          state.endTime == null) {
        state = state.copyWith(isConfirming: false);
        return;
      }

      // Build full ISO datetime objects from date + time selections
      final scheduledStart = DateTime(
        state.selectedDate!.year,
        state.selectedDate!.month,
        state.selectedDate!.day,
        state.startTime!.hour,
        state.startTime!.minute,
      );
      final scheduledEnd = DateTime(
        state.selectedDate!.year,
        state.selectedDate!.month,
        state.selectedDate!.day,
        state.endTime!.hour,
        state.endTime!.minute,
      );

      // 1. Check provider availability first (web app approach)
      final availability = await bookingsRepository.checkAvailability(
        providerId: artisan.id,
        start: scheduledStart,
        end: scheduledEnd,
      );

      if (!availability.available) {
        state = state.copyWith(isConfirming: false, isConfirmed: false);
        return;
      }

      // 2. Map selected services to items using their UUIDs
      final serviceDataMap = <String, BookingService>{};
      for (final s in state.availableServices) {
        serviceDataMap[s.title] = s;
      }

      final items = state.selectedServices
          .where((name) => serviceDataMap.containsKey(name))
          .map((name) => {'service': serviceDataMap[name]!.id, 'quantity': 1})
          .toList(growable: true);

      // If no matching service IDs found, fall back to using artisan id
      // (legacy fallback until all services have proper IDs)
      if (items.isEmpty) {
        items.add({'service': artisan.id, 'quantity': 1});
      }

      // 3. Create the booking matching the web app payload shape
      await bookingsRepository.placeBooking(
        providerId: artisan.id,
        scheduledStart: scheduledStart,
        scheduledEnd: scheduledEnd,
        serviceType: state.bookingType.name.toUpperCase(),
        currency: 'NGN',
        addressText: state.bookingType == BookingType.onsite
            ? state.address
            : null,
        notes: state.notes,
        items: items,
      );

      state = state.copyWith(isConfirming: false, isConfirmed: true);
    } catch (e) {
      state = state.copyWith(isConfirming: false, isConfirmed: false);
    }
  }

  void reset() => state = BookingState();
}

final bookingProvider = StateNotifierProvider<BookingNotifier, BookingState>((
  ref,
) {
  return BookingNotifier();
});

/// Hive key for persisting favorite artisan IDs.
const _favoriteArtisansHiveKey = 'favorites.artisan_ids';

/// Manages the set of favorite artisan/provider IDs with Hive persistence.
/// - Loads saved IDs from Hive on construction.
/// - Persists changes to Hive on every toggle.
/// - Provides [clearAll] to wipe favorites and Hive cache.
class FavoriteArtisansNotifier extends StateNotifier<Set<String>> {
  final HiveService _hiveService;

  FavoriteArtisansNotifier({required HiveService hiveService})
    : _hiveService = hiveService,
      super(const {}) {
    _loadFromHive();
  }

  void _loadFromHive() {
    final cached = _hiveService.getList<String>(_favoriteArtisansHiveKey);
    if (cached != null && cached.isNotEmpty) {
      state = cached.toSet();
    }
  }

  void _saveToHive() {
    _hiveService.setList<String>(_favoriteArtisansHiveKey, state.toList());
  }

  void toggleFavorite(String artisanId) {
    final current = Set<String>.from(state);
    if (current.contains(artisanId)) {
      current.remove(artisanId);
    } else {
      current.add(artisanId);
    }
    state = current;
    _saveToHive();
  }

  bool isFavorite(String artisanId) => state.contains(artisanId);

  void clearAll() {
    state = const {};
    _hiveService.remove(_favoriteArtisansHiveKey);
  }
}

final favoriteArtisansProvider =
    StateNotifierProvider<FavoriteArtisansNotifier, Set<String>>((ref) {
      return FavoriteArtisansNotifier(hiveService: sl<HiveService>());
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

final filteredArtisansProvider =
    AsyncNotifierProvider<FilteredArtisansNotifier, List<Artisan>>(() {
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
