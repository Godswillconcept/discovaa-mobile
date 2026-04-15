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
import 'package:flutter/material.dart';

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

  @override
  Future<List<BookingModel>> listBookings() async {
    try {
      if (!await _networkInfo.isConnected) {
        final cached = _readCachedBookings();
        if (cached.isNotEmpty) {
          return cached;
        }
      }
      final services = await _servicesRepository.listServices();
      final serviceMap = {for (final service in services) service.id: service};

      final response = await _dioClient.get(ApiEndpoints.bookings);
      final envelope = decodeListEnvelope(
        response,
        (item) => BookingDto.fromJson(item),
      );
      final bookings = envelope.data
          .map((dto) => mapBookingDto(dto, serviceMap))
          .toList(growable: false);
      await _cacheBookings(bookings);
      return bookings;
    } catch (_) {
      final cached = _readCachedBookings();
      if (cached.isNotEmpty) {
        return cached;
      }
      rethrow;
    }
  }

  @override
  Future<BookingModel> placeBooking({
    required ServiceModel service,
    required DateTime scheduledDate,
    required TimeOfDay scheduledTime,
    String clientName = 'You',
    String? note,
  }) async {
    final start = DateTime(
      scheduledDate.year,
      scheduledDate.month,
      scheduledDate.day,
      scheduledTime.hour,
      scheduledTime.minute,
    );
    final end = service.durationMinutes == null
        ? null
        : start.add(Duration(minutes: service.durationMinutes!));
    final response = await _dioClient.post(
      ApiEndpoints.bookings,
      data: BookingWriteDto(
        providerId: service.id,
        scheduledStart: start,
        scheduledEnd: end,
        currency: service.currency,
        notes: note,
        items: [
          {'service': service.id, 'quantity': 1},
        ],
      ).toJson(),
    );
    final dto = decodeEnvelope(
      response,
      (raw) => BookingDto.fromJson(asMap(raw)),
    ).data;
    final booking = mapBookingDto(dto, {service.id: service});
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
      status: BookingStatus.upcoming,
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

  Future<void> _cacheBookings(List<BookingModel> bookings) async {
    await _hiveService.setList(
      _bookingsCacheKey,
      bookings.map((booking) => booking.toJson()).toList(growable: false),
    );
  }

  List<BookingModel> _readCachedBookings() {
    final cached = _hiveService.getList<dynamic>(_bookingsCacheKey) ?? const [];
    return cached
        .whereType<Map>()
        .map((item) => BookingModel.fromJson(item.cast<String, dynamic>()))
        .toList(growable: false);
  }

  Future<void> _upsertCachedBooking(
    BookingModel booking, {
    bool insertAtStart = false,
  }) async {
    final current = _readCachedBookings().toList();
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
    await _cacheBookings(current);
  }
}
