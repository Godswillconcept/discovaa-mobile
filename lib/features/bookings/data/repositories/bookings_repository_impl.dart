import 'package:discovaa/core/constants/api_endpoints.dart';
import 'package:discovaa/core/network/api_helpers.dart';
import 'package:discovaa/core/network/dio_client.dart';
import 'package:discovaa/core/network/network_info.dart';
import 'package:discovaa/core/storage/hive_service.dart';
import 'package:discovaa/features/bookings/data/models/booking_api_models.dart';
import 'package:discovaa/features/bookings/data/models/booking_model.dart';
import 'package:discovaa/features/bookings/domain/repositories/bookings_repository.dart';
import 'package:discovaa/features/services/data/models/service_model.dart';
import 'package:discovaa/features/services/domain/repositories/services_repository.dart';

// Import the helper function from booking_api_models.dart
// Note: _bookingStatus is a private function, so we need to handle this differently

class BookingsRepositoryImpl implements BookingsRepository {
  final DioClient _dioClient;
  final ServicesRepository _servicesRepository;
  final HiveService _hiveService;
  final NetworkInfo _networkInfo;

  BookingsRepositoryImpl({
    required DioClient dioClient,
    required ServicesRepository servicesRepository,
    required HiveService hiveService,
    required NetworkInfo networkInfo,
  }) : _dioClient = dioClient,
       _servicesRepository = servicesRepository,
       _hiveService = hiveService,
       _networkInfo = networkInfo;

  static const _bookingsCacheKey = 'bookings.cache.list';

  /// Get cache key based on user role to avoid mixing client/provider data
  String _getCacheKey(String? userRole) {
    if (isProviderRole(userRole)) {
      return 'bookings.cache.provider';
    } else if (isClientRole(userRole)) {
      return 'bookings.cache.client';
    }
    return _bookingsCacheKey;
  }

  @override
  List<BookingModel> getCachedBookings({String? userRole}) =>
      _readCachedBookings(_getCacheKey(userRole));

  @override
  Future<List<BookingModel>> listBookings({
    String? userRole,
    String? providerId,
  }) async {
    final cacheKey = _getCacheKey(userRole);
    try {
      if (!await _networkInfo.isConnected) {
        final cached = _readCachedBookings(cacheKey);
        if (cached.isNotEmpty) {
          return cached;
        }
      }

      // Determine query parameters based on role
      Map<String, dynamic>? queryParameters;
      if (isProviderRole(userRole) && providerId != null) {
        queryParameters = {'provider': providerId};
      }
      // Add expand parameter to fetch nested data
      queryParameters ??= {};
      queryParameters['expand'] = 'provider,items.service,payment,user';

      // Run API calls in parallel to reduce total loading time
      final results = await Future.wait([
        _servicesRepository.listServices(),
        _dioClient.get(ApiEndpoints.bookings, queryParameters: queryParameters),
      ]);

      final services = results[0] as List<ServiceModel>;
      final serviceMap = {for (final service in services) service.id: service};
      final response = results[1] as dynamic;

      final envelope = decodeListEnvelope(
        response,
        (item) => BookingDto.fromJson(item),
      );

      // Fetch reviews for completed bookings
      final bookingDTOs = envelope.data;
      final reviewsMap = <String, ReviewDto>{};
      for (final dto in bookingDTOs) {
        final status = bookingStatusFromString(dto.status);
        if (status == BookingStatus.completed) {
          final review = await fetchBookingReview(dto.id);
          if (review != null) {
            reviewsMap[dto.id] = review;
          }
        }
      }

      final bookings = bookingDTOs
          .map(
            (dto) => mapBookingDto(dto, serviceMap, review: reviewsMap[dto.id]),
          )
          .toList(growable: false);
      await _cacheBookings(bookings, cacheKey);
      return bookings;
    } catch (_) {
      final cached = _readCachedBookings(cacheKey);
      if (cached.isNotEmpty) {
        return cached;
      }
      rethrow;
    }
  }

  @override
  Future<({bool available, List<String> reasons})> checkAvailability({
    required String providerId,
    required DateTime start,
    required DateTime end,
  }) async {
    final response = await _dioClient.get(
      ApiEndpoints.providerAvailabilityCheck(providerId),
      queryParameters: {
        'start': start.toUtc().toIso8601String(),
        'end': end.toUtc().toIso8601String(),
      },
    );
    final envelope = decodeEnvelope(response, (raw) => asMap(raw));
    final data = envelope.data;
    final available = data['available'] as bool? ?? false;
    final reasons = (data['reasons'] as List<dynamic>? ?? const [])
        .whereType<String>()
        .toList(growable: false);
    return (available: available, reasons: reasons);
  }

  @override
  Future<BookingModel> placeBooking({
    required String providerId,
    required DateTime scheduledStart,
    required DateTime scheduledEnd,
    required String serviceType,
    required String currency,
    String? addressText,
    String? notes,
    required List<Map<String, dynamic>> items,
  }) async {
    final response = await _dioClient.post(
      ApiEndpoints.bookings,
      data: BookingWriteDto(
        providerId: providerId,
        scheduledStart: scheduledStart.toUtc(),
        scheduledEnd: scheduledEnd.toUtc(),
        serviceType: serviceType,
        currency: currency,
        addressText: addressText,
        notes: notes,
        items: items,
      ).toJson(),
    );
    final dto = decodeEnvelope(
      response,
      (raw) => BookingDto.fromJson(asMap(raw)),
    ).data;

    // Fetch the associated services to build the service snapshot
    final services = await _servicesRepository.listServices();
    final serviceMap = {for (final s in services) s.id: s};

    final booking = mapBookingDto(dto, serviceMap);
    await _upsertCachedBooking(booking, insertAtStart: true);
    return booking;
  }

  @override
  Future<BookingModel> cancelBooking(BookingModel booking) async {
    await _dioClient.post(ApiEndpoints.bookingCancel(booking.id));
    final updated = booking.copyWith(
      status: BookingStatus.cancelled,
      updatedAt: DateTime.now(),
    );
    await _upsertCachedBooking(updated);
    return updated;
  }

  @override
  Future<BookingModel> confirmBooking(BookingModel booking) async {
    await _dioClient.post(ApiEndpoints.bookingConfirm(booking.id));
    final updated = booking.copyWith(
      status: BookingStatus.confirmed,
      updatedAt: DateTime.now(),
    );
    await _upsertCachedBooking(updated);
    return updated;
  }

  @override
  Future<BookingModel> completeBooking(BookingModel booking) async {
    await _dioClient.post(ApiEndpoints.bookingComplete(booking.id));
    final updated = booking.copyWith(
      status: BookingStatus.completed,
      updatedAt: DateTime.now(),
    );
    await _upsertCachedBooking(updated);
    return updated;
  }

  @override
  Future<BookingModel> submitReview(
    BookingModel booking, {
    required int rating,
    String? review,
  }) async {
    await _dioClient.post(
      ApiEndpoints.reviewsV1,
      data: {
        'booking': booking.id,
        'rating': rating.toString(),
        if (review != null && review.isNotEmpty) 'comment': review,
        'is_public': true,
      },
    );
    final updated = booking.copyWith(
      rating: rating,
      review: review,
      updatedAt: DateTime.now(),
    );
    await _upsertCachedBooking(updated);
    return updated;
  }

  @override
  Future<BookingModel> rescheduleBooking(
    BookingModel booking, {
    required DateTime newStart,
    DateTime? newEnd,
  }) async {
    final data = <String, dynamic>{
      'scheduled_start': newStart.toUtc().toIso8601String(),
    };
    if (newEnd != null) {
      data['scheduled_end'] = newEnd.toUtc().toIso8601String();
    }
    final response = await _dioClient.patch(
      ApiEndpoints.bookingReschedule(booking.id),
      data: data,
    );
    final dto = decodeEnvelope(
      response,
      (raw) => BookingDto.fromJson(asMap(raw)),
    ).data;

    final services = await _servicesRepository.listServices();
    final serviceMap = {for (final s in services) s.id: s};

    final updated = mapBookingDto(dto, serviceMap);
    await _upsertCachedBooking(updated);
    return updated;
  }

  @override
  Future<BookingModel> updateConcludedPrice(
    BookingModel booking, {
    required String unitPriceAmount,
  }) async {
    final response = await _dioClient.patch(
      ApiEndpoints.bookingUpdatePrice(booking.id),
      data: {
        'items': [
          {
            'id': booking.service.serviceId,
            'unit_price_amount': unitPriceAmount,
          },
        ],
      },
    );
    final dto = decodeEnvelope(
      response,
      (raw) => BookingDto.fromJson(asMap(raw)),
    ).data;

    final services = await _servicesRepository.listServices();
    final serviceMap = {for (final s in services) s.id: s};

    final updated = mapBookingDto(dto, serviceMap);
    await _upsertCachedBooking(updated);
    return updated;
  }

  @override
  Future<UserProfileDto?> fetchUserProfile() async {
    try {
      final response = await _dioClient.get(ApiEndpoints.accountsMe);
      final envelope = decodeEnvelope(
        response,
        (raw) => UserProfileDto.fromJson(asMap(raw)),
      );
      return envelope.data;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<ProviderProfileDto?> fetchProviderProfile() async {
    try {
      final response = await _dioClient.get(ApiEndpoints.providersMeProfile);
      final envelope = decodeEnvelope(
        response,
        (raw) => ProviderProfileDto.fromJson(asMap(raw)),
      );
      return envelope.data;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<ReviewDto?> fetchBookingReview(String bookingId) async {
    try {
      final response = await _dioClient.get(
        ApiEndpoints.reviewsV1,
        queryParameters: {'booking': bookingId},
      );
      final envelope = decodeListEnvelope(
        response,
        (item) => ReviewDto.fromJson(item),
      );
      // Return the first review if any
      return envelope.data.isNotEmpty ? envelope.data.first : null;
    } catch (_) {
      return null;
    }
  }

  Future<void> _cacheBookings(
    List<BookingModel> bookings, [
    String? cacheKey,
  ]) async {
    await _hiveService.setList(
      cacheKey ?? _bookingsCacheKey,
      bookings.map((booking) => booking.toJson()).toList(growable: false),
    );
  }

  List<BookingModel> _readCachedBookings([String? cacheKey]) {
    final cached =
        _hiveService.getList<dynamic>(cacheKey ?? _bookingsCacheKey) ??
        const [];
    return cached
        .whereType<Map>()
        .map((item) => BookingModel.fromJson(item.cast<String, dynamic>()))
        .toList(growable: false);
  }

  Future<void> _upsertCachedBooking(
    BookingModel booking, {
    bool insertAtStart = false,
    String? cacheKey,
  }) async {
    final current = _readCachedBookings(cacheKey).toList();
    final index = current.indexWhere((item) => item.id == booking.id);
    if (index == -1) {
      if (insertAtStart) {
        current.insert(0, booking);
      } else {
        current.add(booking);
      }
    } else {
      current[index] = booking;
    }
    await _cacheBookings(current, cacheKey);
  }
}
