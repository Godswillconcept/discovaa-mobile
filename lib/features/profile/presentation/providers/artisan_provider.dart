import 'package:discovaa/features/bookings/presentation/providers/bookings_provider.dart';
import 'package:discovaa/features/home/presentation/providers/dashboard_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:logger/logger.dart';
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

final _logger = Logger();

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
  static const Object _unset = Object();

  final ArtisanSort sortBy;
  final String? selectedCategory;
  final String searchQuery;
  final double? minRating;
  final double? minPrice;
  final double? maxPrice;
  final String? location;
  final bool isAvailableOnly;
  final String providerType; // 'All', 'Individual', 'Business'
  final bool isVerifiedOnly;
  final double? radiusKm;

  ArtisanFilterState({
    this.sortBy = ArtisanSort.categories,
    this.selectedCategory,
    this.searchQuery = '',
    this.minRating,
    this.minPrice,
    this.maxPrice,
    this.location,
    this.isAvailableOnly = false,
    this.providerType = 'All',
    this.isVerifiedOnly = false,
    this.radiusKm,
  });

  int get activeFilterCount {
    int count = 0;
    if (selectedCategory != null) count++;
    if (minRating != null) count++;
    if (minPrice != null || maxPrice != null) count++;
    if (location != null && location!.isNotEmpty) count++;
    if (isAvailableOnly) count++;
    if (providerType != 'All') count++;
    if (isVerifiedOnly) count++;
    if (radiusKm != null) count++;
    return count;
  }

  ArtisanFilterState copyWith({
    Object? sortBy = _unset,
    Object? selectedCategory = _unset,
    Object? searchQuery = _unset,
    Object? minRating = _unset,
    Object? minPrice = _unset,
    Object? maxPrice = _unset,
    Object? location = _unset,
    bool? isAvailableOnly,
    Object? providerType = _unset,
    Object? isVerifiedOnly = _unset,
    Object? radiusKm = _unset,
  }) {
    return ArtisanFilterState(
      sortBy: identical(sortBy, _unset) ? this.sortBy : sortBy as ArtisanSort,
      selectedCategory: identical(selectedCategory, _unset)
          ? this.selectedCategory
          : selectedCategory as String?,
      searchQuery: identical(searchQuery, _unset)
          ? this.searchQuery
          : searchQuery as String,
      minRating: identical(minRating, _unset)
          ? this.minRating
          : minRating as double?,
      minPrice: identical(minPrice, _unset)
          ? this.minPrice
          : minPrice as double?,
      maxPrice: identical(maxPrice, _unset)
          ? this.maxPrice
          : maxPrice as double?,
      location: identical(location, _unset)
          ? this.location
          : location as String?,
      isAvailableOnly: isAvailableOnly ?? this.isAvailableOnly,
      providerType: identical(providerType, _unset)
          ? this.providerType
          : providerType as String,
      isVerifiedOnly: identical(isVerifiedOnly, _unset)
          ? this.isVerifiedOnly
          : isVerifiedOnly as bool,
      radiusKm: identical(radiusKm, _unset)
          ? this.radiusKm
          : radiusKm as double?,
    );
  }
}

class ArtisanFilterNotifier extends StateNotifier<ArtisanFilterState> {
  final Ref _ref;
  final HiveService _hiveService;
  static const _filtersCacheKey = 'artisans.cache.filters';

  ArtisanFilterNotifier(this._ref, this._hiveService)
    : super(_loadFilters(_hiveService));

  static bool _parseBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is int) return value != 0;
    if (value is String) return value.toLowerCase() == 'true';
    return false;
  }

  static ArtisanFilterState _loadFilters(HiveService hiveService) {
    try {
      final cached = hiveService.getMap(_filtersCacheKey);
      if (cached != null) {
        return ArtisanFilterState(
          sortBy: cached['sortBy'] != null
              ? ArtisanSort.values.firstWhere(
                  (e) => e.name == cached['sortBy'],
                  orElse: () => ArtisanSort.categories,
                )
              : ArtisanSort.categories,
          selectedCategory: cached['selectedCategory'] as String?,
          searchQuery: cached['searchQuery'] as String? ?? '',
          minRating: (cached['minRating'] as num?)?.toDouble(),
          minPrice: (cached['minPrice'] as num?)?.toDouble(),
          maxPrice: (cached['maxPrice'] as num?)?.toDouble(),
          location: cached['location'] as String?,
          isAvailableOnly: _parseBool(cached['isAvailableOnly']),
          providerType: cached['providerType'] as String? ?? 'All',
          isVerifiedOnly: _parseBool(cached['isVerifiedOnly']),
          radiusKm: (cached['radiusKm'] as num?)?.toDouble(),
        );
      }
    } catch (_) {
      // Ignore cache errors, use defaults
    }
    return ArtisanFilterState();
  }

  void _saveFilters() {
    try {
      _hiveService.setMap(_filtersCacheKey, {
        'sortBy': state.sortBy.name,
        'selectedCategory': state.selectedCategory,
        'searchQuery': state.searchQuery,
        'minRating': state.minRating,
        'minPrice': state.minPrice,
        'maxPrice': state.maxPrice,
        'location': state.location,
        'isAvailableOnly': state.isAvailableOnly,
        'providerType': state.providerType,
        'isVerifiedOnly': state.isVerifiedOnly,
        'radiusKm': state.radiusKm,
      });
    } catch (_) {
      // Ignore save errors
    }
  }

  @override
  set state(ArtisanFilterState value) {
    super.state = value;
    _saveFilters();
  }

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

  void setMinRating(double? rating) {
    state = state.copyWith(minRating: rating);
    _resetPage();
  }

  void setPriceRange(double? min, double? max) {
    state = state.copyWith(minPrice: min, maxPrice: max);
    _resetPage();
  }

  void setLocation(String? location) {
    state = state.copyWith(location: location);
    _resetPage();
  }

  void setAvailableOnly(bool value) {
    state = state.copyWith(isAvailableOnly: value);
    _resetPage();
  }

  void setProviderType(String type) {
    state = state.copyWith(providerType: type);
    _resetPage();
  }

  void setVerifiedOnly(bool value) {
    state = state.copyWith(isVerifiedOnly: value);
    _resetPage();
  }

  void setRadiusKm(double? value) {
    state = state.copyWith(radiusKm: value);
    _resetPage();
  }

  void clearAdvancedFilters() {
    state = state.copyWith(
      minRating: null,
      minPrice: null,
      maxPrice: null,
      location: null,
      isAvailableOnly: false,
      providerType: 'All',
      isVerifiedOnly: false,
      radiusKm: null,
    );
    _resetPage();
  }

  void _resetPage() {
    _ref.read(artisanPageProvider.notifier).state = 1;
  }
}

final artisanFilterProvider =
    StateNotifierProvider<ArtisanFilterNotifier, ArtisanFilterState>((ref) {
      return ArtisanFilterNotifier(ref, sl<HiveService>());
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
  final String? errorMessage;

  /// Full service data with pricing information
  final List<BookingService> availableServices;

  /// Memoized pricing calculations
  final String? calculatedPriceRange;
  final double? calculatedHourlyRate;

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
    this.errorMessage,
    this.availableServices = const [],
    this.calculatedPriceRange,
    this.calculatedHourlyRate,
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
    Object? errorMessage = _unset,
    List<BookingService>? availableServices,
    Object? calculatedPriceRange = _unset,
    Object? calculatedHourlyRate = _unset,
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
      errorMessage: identical(errorMessage, _unset)
          ? this.errorMessage
          : errorMessage as String?,
      availableServices: availableServices ?? this.availableServices,
      calculatedPriceRange: identical(calculatedPriceRange, _unset)
          ? this.calculatedPriceRange
          : calculatedPriceRange as String?,
      calculatedHourlyRate: identical(calculatedHourlyRate, _unset)
          ? this.calculatedHourlyRate
          : calculatedHourlyRate as double?,
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
    if (bookingType == BookingType.onsite) {
      if (address == null || address!.isEmpty) return false;
      if (address!.length < 10) return false; // Minimum address length
    }
    if (selectedServices.isEmpty) return false;

    final startMinutes = startTime!.hour * 60 + startTime!.minute;
    final endMinutes = endTime!.hour * 60 + endTime!.minute;
    if (endMinutes <= startMinutes) return false;

    final totalMinutes = endMinutes - startMinutes;
    if (totalMinutes > 8 * 60) return false; // 8 hour max

    return true;
  }

  /// Get validation error message if any
  String? get validationError {
    if (selectedDate == null) return 'Please select a date';
    if (startTime == null || endTime == null) {
      return 'Please select start and end time';
    }
    if (bookingType == BookingType.onsite &&
        (address == null || address!.isEmpty)) {
      return 'Please enter an address for onsite booking';
    }
    if (selectedServices.isEmpty) return 'Please select at least one service';

    final startMinutes = startTime!.hour * 60 + startTime!.minute;
    final endMinutes = endTime!.hour * 60 + endTime!.minute;
    if (endMinutes <= startMinutes) return 'End time must be after start time';

    final totalMinutes = endMinutes - startMinutes;
    if (totalMinutes > 8 * 60) return 'Booking duration cannot exceed 8 hours';

    return null;
  }
}

class BookingNotifier extends StateNotifier<BookingState> {
  final BookingsRepository _bookingsRepository;
  final Ref _ref;

  BookingNotifier({
    required BookingsRepository bookingsRepository,
    required Ref ref,
  }) : _bookingsRepository = bookingsRepository,
       _ref = ref,
       super(BookingState());

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

    // Calculate pricing when services change
    final pricing = _calculatePricing(currentServices);

    state = state.copyWith(
      selectedServices: currentServices,
      calculatedPriceRange: pricing['priceRange'],
      calculatedHourlyRate: pricing['hourlyRate'],
    );
  }

  void clearServices() => state = state.copyWith(
    selectedServices: const {},
    calculatedPriceRange: null,
    calculatedHourlyRate: null,
  );

  /// Helper method to calculate pricing based on selected services
  Map<String, dynamic> _calculatePricing(Set<String> selectedServices) {
    if (selectedServices.isEmpty || state.availableServices.isEmpty) {
      return {'priceRange': null, 'hourlyRate': null};
    }

    // Calculate hourly rate (lowest rate if multiple)
    final selectedServiceData = state.availableServices
        .where(
          (s) => selectedServices.contains(s.title) && s.hourlyRate != null,
        )
        .toList();

    double? hourlyRate;
    if (selectedServiceData.isNotEmpty) {
      hourlyRate = selectedServiceData
          .map((s) => s.hourlyRate!)
          .reduce((a, b) => a < b ? a : b);
    }

    // Calculate price ranges
    final priceRanges = state.availableServices
        .where(
          (s) => selectedServices.contains(s.title) && s.priceRange.isNotEmpty,
        )
        .map((s) => s.priceRange)
        .toList();

    String? priceRange;
    if (priceRanges.isNotEmpty) {
      priceRange = priceRanges.join(', ');
    }

    return {'priceRange': priceRange, 'hourlyRate': hourlyRate};
  }

  /// Set available services with pricing data (called when opening booking modal)
  void setAvailableServices(List<BookingService> services) {
    // Calculate initial pricing for currently selected services
    final pricing = _calculatePricing(state.selectedServices);

    state = state.copyWith(
      availableServices: services,
      calculatedPriceRange: pricing['priceRange'],
      calculatedHourlyRate: pricing['hourlyRate'],
    );
  }

  Future<void> confirmBooking() async {
    // Clear any previous error
    state = state.copyWith(isConfirming: true, errorMessage: null);

    try {
      final artisan = state.selectedArtisan;

      if (artisan == null ||
          state.selectedDate == null ||
          state.startTime == null ||
          state.endTime == null) {
        state = state.copyWith(
          isConfirming: false,
          errorMessage: 'Missing required booking details.',
        );
        return;
      }

      // Build full ISO datetime objects from date + time selections
      // Use proper timezone handling for Africa/Lagos
      final lagos = tz.getLocation('Africa/Lagos');
      final scheduledStart = tz.TZDateTime(
        lagos,
        state.selectedDate!.year,
        state.selectedDate!.month,
        state.selectedDate!.day,
        state.startTime!.hour,
        state.startTime!.minute,
      );
      final scheduledEnd = tz.TZDateTime(
        lagos,
        state.selectedDate!.year,
        state.selectedDate!.month,
        state.selectedDate!.day,
        state.endTime!.hour,
        state.endTime!.minute,
      );

      // Convert to UTC only when sending to backend
      final scheduledStartUtc = scheduledStart.toUtc();
      final scheduledEndUtc = scheduledEnd.toUtc();

      _logger.d('=== TIMEZONE CONVERSION DEBUG ===');
      _logger.d('Selected start (Lagos): $scheduledStart');
      _logger.d('Selected end (Lagos): $scheduledEnd');
      _logger.d('Start UTC: $scheduledStartUtc');
      _logger.d('End UTC: $scheduledEndUtc');
      _logger.d('===============================');

      // 1. Check provider availability first (web app approach)
      // Pass UTC times to ensure backend receives consistent timezone-aware timestamps
      final availability = await _bookingsRepository.checkAvailability(
        providerId: artisan.id,
        start: scheduledStartUtc,
        end: scheduledEndUtc,
      );

      _logger.d('=== Availability Result ===');
      _logger.d('Available: ${availability.available}');
      if (availability.reasons.isNotEmpty) {
        _logger.d('Reasons: ${availability.reasons}');
      }
      _logger.d('==========================');

      if (!availability.available) {
        final reason = availability.reasons.isNotEmpty
            ? availability.reasons.join(', ')
            : 'Provider is not available at the selected time.';
        state = state.copyWith(
          isConfirming: false,
          isConfirmed: false,
          errorMessage: reason,
        );
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

      // Validate that service mapping succeeded
      if (items.isEmpty) {
        state = state.copyWith(
          errorMessage: 'Unable to map selected services. Please try again.',
        );
        return;
      }

      final payloadItems = items;

      _logger.d('=== BOOKING SUBMISSION DEBUG ===');
      _logger.d('providerId: ${artisan.id}');
      _logger.d('scheduledStart: $scheduledStart');
      _logger.d('scheduledEnd: $scheduledEnd');
      _logger.d('serviceType: ${state.bookingType.name.toUpperCase()}');
      _logger.d('currency: NGN');
      _logger.d(
        'addressText: ${state.bookingType == BookingType.onsite ? state.address : null}',
      );
      _logger.d('notes: ${state.notes}');
      _logger.d('items: $payloadItems');
      _logger.d('================================');

      // 3. Create the booking using the global bookingsProvider to ensure state synchronization
      await _ref
          .read(bookingsProvider.notifier)
          .placeBooking(
            providerId: artisan.id,
            scheduledStart: scheduledStartUtc,
            scheduledEnd: scheduledEndUtc,
            serviceType: state.bookingType.name.toUpperCase(),
            currency: 'NGN',
            addressText: state.bookingType == BookingType.onsite
                ? state.address
                : null,
            notes: state.notes,
            latitude: state.latitude,
            longitude: state.longitude,
            items: payloadItems,
          );

      // 4. Invalidate dashboard to ensure it reflects the new booking and KPIs
      _ref.invalidate(dashboardProvider);

      _logger.d('Booking submitted successfully!');
      state = state.copyWith(
        isConfirming: false,
        isConfirmed: true,
        errorMessage: null,
      );
    } catch (e) {
      _logger.e('Booking failed with error: $e');
      if (e is DioException) {
        _logger.e('DioException response: ${e.response?.data}');
      }
      state = state.copyWith(isConfirming: false, isConfirmed: false);
      // Extract error message from exceptions if possible, otherwise use generic message
      String errorMsg = 'Failed to create booking. Please try again.';
      if (e is DioException) {
        if (e.response?.data != null) {
          final data = e.response?.data;
          if (data is Map) {
            if (data.containsKey('message')) {
              errorMsg = data['message'].toString();
            } else if (data.containsKey('detail')) {
              errorMsg = data['detail'].toString();
            } else if (data.containsKey('non_field_errors')) {
              errorMsg = (data['non_field_errors'] as List).join('\n');
            } else {
              // Parse field-level validation errors
              final List<String> errors = [];
              data.forEach((key, value) {
                if (value is List) {
                  errors.add('$key: ${value.join(', ')}');
                } else if (value is Map) {
                  errors.add('$key: $value');
                } else {
                  errors.add('$key: $value');
                }
              });
              if (errors.isNotEmpty) {
                errorMsg = errors.join('\n');
              } else {
                errorMsg = data.toString();
              }
            }
          } else {
            errorMsg = data.toString();
          }
        } else {
          errorMsg = e.message ?? e.toString();
        }
      } else {
        errorMsg = e.toString();
      }
      state = state.copyWith(errorMessage: errorMsg);
    }
  }

  void reset() => state = BookingState();
}

final bookingProvider = StateNotifierProvider<BookingNotifier, BookingState>((
  ref,
) {
  return BookingNotifier(
    bookingsRepository: ref.read(bookingsRepositoryProvider),
    ref: ref,
  );
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
    _logger.i('[FilteredArtisansNotifier] build() called');
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

    // Map provider type filter
    String? providerTypeParam;
    if (filter.providerType != 'All') {
      providerTypeParam = filter.providerType.toUpperCase();
    }

    _logger.i('[FilteredArtisansNotifier] Checking cache...');
    final cached = repo.getCachedArtisans(
      search: filter.searchQuery.isNotEmpty ? filter.searchQuery : null,
      category: filter.selectedCategory,
      ordering: ordering,
      minRating: filter.minRating,
      minPrice: filter.minPrice,
      maxPrice: filter.maxPrice,
      location: filter.location,
      isAvailableOnly: filter.isAvailableOnly,
      providerType: providerTypeParam,
      isVerifiedOnly: filter.isVerifiedOnly ? true : null,
      radiusKm: filter.radiusKm,
    );

    // Return cached data immediately if available
    if (cached.isNotEmpty) {
      _logger.i(
        '[FilteredArtisansNotifier] Cache hit, returning ${cached.length} items',
      );
      // Trigger background refresh
      _refreshInBackground(repo, filter, ordering);
      return cached;
    }

    _logger.i('[FilteredArtisansNotifier] No cache, fetching from network...');
    // No cache, fetch from network
    try {
      final results = await repo.searchArtisans(
        search: filter.searchQuery.isNotEmpty ? filter.searchQuery : null,
        category: filter.selectedCategory,
        ordering: ordering,
        minRating: filter.minRating,
        minPrice: filter.minPrice,
        maxPrice: filter.maxPrice,
        location: filter.location,
        isAvailableOnly: filter.isAvailableOnly,
        providerType: providerTypeParam,
        isVerifiedOnly: filter.isVerifiedOnly ? true : null,
        radiusKm: filter.radiusKm,
      );
      _logger.i(
        '[FilteredArtisansNotifier] Network fetch successful, got ${results.length} items',
      );
      return results;
    } catch (e, s) {
      _logger.e('[FilteredArtisansNotifier] Network fetch failed: $e\n$s');
      rethrow;
    }
  }

  Future<void> _refreshInBackground(
    ArtisanRepository repo,
    ArtisanFilterState filter,
    String? ordering,
  ) async {
    try {
      final results = await repo.searchArtisans(
        search: filter.searchQuery.isNotEmpty ? filter.searchQuery : null,
        category: filter.selectedCategory,
        ordering: ordering,
        minRating: filter.minRating,
        minPrice: filter.minPrice,
        maxPrice: filter.maxPrice,
        location: filter.location,
        isAvailableOnly: filter.isAvailableOnly,
        providerType: filter.providerType != 'All'
            ? filter.providerType.toUpperCase()
            : null,
        isVerifiedOnly: filter.isVerifiedOnly ? true : null,
        radiusKm: filter.radiusKm,
      );
      state = AsyncData(results);
    } catch (_) {
      // Silently fail on background refresh errors
    }
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
