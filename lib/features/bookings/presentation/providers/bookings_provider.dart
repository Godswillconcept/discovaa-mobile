import 'package:discovaa/app/dependency_injection/service_locator.dart';
import 'package:discovaa/core/network/dio_client.dart';
import 'package:discovaa/core/network/network_info.dart';
import 'package:discovaa/core/storage/hive_service.dart';
import 'package:discovaa/features/bookings/data/models/booking_model.dart';
import 'package:discovaa/features/bookings/data/repositories/bookings_repository_impl.dart';
import 'package:discovaa/features/bookings/domain/repositories/bookings_repository.dart';
import 'package:discovaa/features/services/data/models/service_model.dart';
import 'package:discovaa/features/services/presentation/providers/services_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ---------------------------------------------------------------------------
// Bookings state
// ---------------------------------------------------------------------------

enum BookingsLoadStatus { idle, loading, success, failure }

class BookingsState {
  final List<BookingModel> bookings;
  final BookingsLoadStatus status;
  final String? errorMessage;
  final String searchQuery;

  const BookingsState({
    this.bookings = const [],
    this.status = BookingsLoadStatus.idle,
    this.errorMessage,
    this.searchQuery = '',
  });

  BookingsState copyWith({
    List<BookingModel>? bookings,
    BookingsLoadStatus? status,
    String? errorMessage,
    String? searchQuery,
  }) {
    return BookingsState(
      bookings: bookings ?? this.bookings,
      status: status ?? this.status,
      errorMessage: errorMessage,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  /// Returns bookings for a given status, filtered by searchQuery.
  List<BookingModel> byStatus(BookingStatus s) {
    final filtered = searchQuery.isEmpty
        ? bookings
        : bookings.where((b) {
            final q = searchQuery.toLowerCase();
            return b.service.title.toLowerCase().contains(q) ||
                b.service.category.toLowerCase().contains(q) ||
                b.clientName.toLowerCase().contains(q);
          }).toList();
    return filtered.where((b) => b.status == s).toList();
  }

  int countByStatus(BookingStatus s) =>
      bookings.where((b) => b.status == s).length;
}

// ---------------------------------------------------------------------------
// Bookings notifier
// ---------------------------------------------------------------------------

class BookingsNotifier extends StateNotifier<BookingsState> {
  BookingsNotifier(this._repository) : super(const BookingsState());

  final BookingsRepository _repository;

  Future<void> loadBookings() async {
    if (state.bookings.isNotEmpty) return;
    
    final cached = _repository.getCachedBookings();
    if (cached.isNotEmpty) {
      state = state.copyWith(bookings: cached, status: BookingsLoadStatus.success);
    } else {
      state = state.copyWith(status: BookingsLoadStatus.loading);
    }
    
    try {
      final data = await _repository.listBookings();
      if (mounted) {
        state = state.copyWith(
          bookings: data,
          status: BookingsLoadStatus.success,
        );
      }
    } catch (e) {
      if (mounted && cached.isEmpty) {
        state = state.copyWith(
          status: BookingsLoadStatus.failure,
          errorMessage: 'Failed to load bookings. Please try again.',
        );
      }
    }
  }

  /// Force reload bookings from server (ignores cache check)
  Future<void> refreshBookings() async {
    state = state.copyWith(status: BookingsLoadStatus.loading);
    try {
      final data = await _repository.listBookings();
      state = state.copyWith(
        bookings: data,
        status: BookingsLoadStatus.success,
      );
    } catch (e) {
      state = state.copyWith(
        status: BookingsLoadStatus.failure,
        errorMessage: 'Failed to refresh bookings. Please try again.',
      );
    }
  }

  /// Create a new booking from a [ServiceModel] and scheduled date/time.
  Future<BookingModel> placeBooking({
    required ServiceModel service,
    required DateTime scheduledDate,
    required TimeOfDay scheduledTime,
    String clientName = 'You',
    String? note,
  }) async {
    final booking = await _repository.placeBooking(
      service: service,
      scheduledDate: scheduledDate,
      scheduledTime: scheduledTime,
      clientName: clientName,
      note: note,
    );
    state = state.copyWith(
      bookings: [booking, ...state.bookings],
      status: BookingsLoadStatus.success,
    );
    return booking;
  }

  /// Cancel a booking by id.
  Future<void> cancelBooking(String id) async {
    final matches = state.bookings.where((b) => b.id == id);
    final current = matches.isEmpty ? null : matches.first;
    if (current == null) return;
    final updated = await _repository.cancelBooking(current);
    _replaceBooking(updated);
  }

  /// Mark a booking as ongoing.
  void startBooking(String id) {
    final idx = state.bookings.indexWhere((b) => b.id == id);
    if (idx == -1) return;
    final updated = [...state.bookings];
    updated[idx] = updated[idx].copyWith(
      status: BookingStatus.ongoing,
      updatedAt: DateTime.now(),
    );
    state = state.copyWith(bookings: updated);
  }

  /// Mark a booking as completed.
  Future<void> completeBooking(String id) async {
    final matches = state.bookings.where((b) => b.id == id);
    final current = matches.isEmpty ? null : matches.first;
    if (current == null) return;
    final updated = await _repository.completeBooking(current);
    _replaceBooking(updated);
  }

  /// Confirm a pending booking → upcoming.
  Future<void> confirmBooking(String id) async {
    final matches = state.bookings.where((b) => b.id == id);
    final current = matches.isEmpty ? null : matches.first;
    if (current == null) return;
    final updated = await _repository.confirmBooking(current);
    _replaceBooking(updated);
  }

  /// Add or update a rating + review on a completed booking.
  Future<void> submitReview(
    String id, {
    required int rating,
    String? review,
  }) async {
    final matches = state.bookings.where((b) => b.id == id);
    final booking = matches.isEmpty ? null : matches.first;
    if (booking == null) return;
    final updatedBooking = await _repository.submitReview(
      booking,
      rating: rating,
      review: review,
    );
    _replaceBooking(updatedBooking);
  }

  void _replaceBooking(BookingModel updatedBooking) {
    final idx = state.bookings.indexWhere((b) => b.id == updatedBooking.id);
    if (idx == -1) return;
    final updated = [...state.bookings];
    updated[idx] = updatedBooking;
    state = state.copyWith(bookings: updated);
  }

  /// Update search query.
  void updateSearch(String query) {
    state = state.copyWith(searchQuery: query);
  }
}

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

/// Primary bookings state provider
final bookingsRepositoryProvider = Provider<BookingsRepository>((ref) {
  return BookingsRepositoryImpl(
    dioClient: sl<DioClient>(),
    servicesRepository: ref.watch(servicesRepositoryProvider),
    hiveService: sl<HiveService>(),
    networkInfo: sl<NetworkInfo>(),
  );
});

final bookingsProvider = StateNotifierProvider<BookingsNotifier, BookingsState>(
  (ref) => BookingsNotifier(ref.watch(bookingsRepositoryProvider)),
);

/// Convenience: bookings for a specific status
final bookingsByStatusProvider =
    Provider.family<List<BookingModel>, BookingStatus>((ref, status) {
      return ref.watch(bookingsProvider).byStatus(status);
    });

/// Count of active (pending + upcoming + ongoing) bookings — useful for badges
final activeBookingCountProvider = Provider<int>((ref) {
  final state = ref.watch(bookingsProvider);
  return state.countByStatus(BookingStatus.requested) +
      state.countByStatus(BookingStatus.confirmed) +
      state.countByStatus(BookingStatus.ongoing);
});
