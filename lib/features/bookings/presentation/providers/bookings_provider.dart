import 'package:discovaa/app/dependency_injection/service_locator.dart';
import 'package:discovaa/core/network/dio_client.dart';
import 'package:discovaa/core/network/network_info.dart';
import 'package:discovaa/core/storage/hive_service.dart';
import 'package:discovaa/features/authentication/presentation/providers/auth_provider.dart';
import 'package:discovaa/features/bookings/data/models/booking_api_models.dart';
import 'package:discovaa/features/bookings/data/models/booking_model.dart';
import 'package:discovaa/features/bookings/data/repositories/bookings_repository_impl.dart';
import 'package:discovaa/features/bookings/domain/repositories/bookings_repository.dart';
import 'package:discovaa/features/profile/presentation/providers/user_profile_provider.dart';
import 'package:discovaa/features/services/presentation/providers/services_provider.dart';
import 'package:flutter/foundation.dart';
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
  final int currentPage;
  final int pageSize;
  final bool hasMore;

  const BookingsState({
    this.bookings = const [],
    this.status = BookingsLoadStatus.idle,
    this.errorMessage,
    this.searchQuery = '',
    this.currentPage = 1,
    this.pageSize = 20,
    this.hasMore = true,
  });

  BookingsState copyWith({
    List<BookingModel>? bookings,
    BookingsLoadStatus? status,
    String? errorMessage,
    String? searchQuery,
    int? currentPage,
    int? pageSize,
    bool? hasMore,
  }) {
    return BookingsState(
      bookings: bookings ?? this.bookings,
      status: status ?? this.status,
      errorMessage: errorMessage,
      searchQuery: searchQuery ?? this.searchQuery,
      currentPage: currentPage ?? this.currentPage,
      pageSize: pageSize ?? this.pageSize,
      hasMore: hasMore ?? this.hasMore,
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
                b.clientName.toLowerCase().contains(q) ||
                (b.providerName?.toLowerCase().contains(q) ?? false);
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
  BookingsNotifier(this._repository, this._ref) : super(const BookingsState());

  final BookingsRepository _repository;
  final Ref _ref;

  // Track pending operations to prevent double charges
  final Set<String> _pendingChargeOperations = {};
  // Loading flag to prevent concurrent state mutations
  bool _isLoading = false;

  String? _providerIdForBookings(String? userRole) {
    if (!isProviderRole(userRole)) return null;

    final providerId = _ref.read(userProfileProvider).profile?.providerId;
    if (providerId == null || providerId.isEmpty) {
      debugPrint(
        '[Bookings] Provider role detected, but providerId is missing. '
        'Skipping provider booking fetch.',
      );
      return null;
    }
    return providerId;
  }

  bool _shouldSkipProviderFetch(String? userRole, String? providerId) {
    return isProviderRole(userRole) && (providerId == null || providerId.isEmpty);
  }

  Future<void> loadBookings() async {
    // Prevent concurrent execution
    if (_isLoading) return;
    _isLoading = true;

    final authState = _ref.read(authProvider);
    final user = authState.value?.user;
    final userRole = user?.role;

    final cached = _repository.getCachedBookings(userRole: userRole);

    // Show cached data immediately if available
    if (cached.isNotEmpty && state.bookings.isEmpty) {
      if (mounted) {
        state = state.copyWith(
          bookings: cached,
          status: BookingsLoadStatus.success,
        );
      }
    } else if (state.bookings.isEmpty) {
      if (mounted) {
        state = state.copyWith(status: BookingsLoadStatus.loading);
      }
    }

    try {
      final providerId = _providerIdForBookings(userRole);
      if (_shouldSkipProviderFetch(userRole, providerId)) {
        if (mounted) {
          state = state.copyWith(
            bookings: [],
            status: BookingsLoadStatus.success,
            currentPage: 1,
            hasMore: false,
          );
        }
        return;
      }

      final data = await _repository.listBookings(
        userRole: userRole,
        providerId: providerId,
      );
      if (mounted) {
        state = state.copyWith(
          bookings: data,
          status: BookingsLoadStatus.success,
        );
      }
    } catch (e) {
      if (mounted) {
        // If we have cached data, show it even if API fails
        if (cached.isNotEmpty) {
          state = state.copyWith(
            bookings: cached,
            status: BookingsLoadStatus.success,
          );
        } else if (state.bookings.isEmpty) {
          // Only show error state if it's a genuine network/API error
          // Empty data should be treated as success (no bookings yet)
          state = state.copyWith(
            bookings: [],
            status: BookingsLoadStatus.success,
          );
        }
      }
    } finally {
      _isLoading = false;
    }
  }

  /// Force reload bookings from server (ignores cache check)
  Future<void> refreshBookings() async {
    // Prevent concurrent execution
    if (_isLoading) return;
    _isLoading = true;

    if (mounted) {
      state = state.copyWith(status: BookingsLoadStatus.loading);
    }
    try {
      final authState = _ref.read(authProvider);
      final user = authState.value?.user;
      final userRole = user?.role;
      final providerId = _providerIdForBookings(userRole);
      if (_shouldSkipProviderFetch(userRole, providerId)) {
        if (mounted) {
          state = state.copyWith(
            bookings: [],
            status: BookingsLoadStatus.success,
            currentPage: 1,
            hasMore: false,
          );
        }
        return;
      }

      final data = await _repository.listBookings(
        userRole: userRole,
        providerId: providerId,
        page: 1,
        pageSize: state.pageSize,
      );
      if (mounted) {
        state = state.copyWith(
          bookings: data,
          status: BookingsLoadStatus.success,
          currentPage: 1,
          hasMore: data.length >= state.pageSize,
        );
      }
    } catch (e) {
      // On refresh failure, keep existing bookings and show error
      // Empty data should still be treated as success
      if (mounted) {
        state = state.copyWith(
          bookings: state.bookings,
          status: BookingsLoadStatus.success,
        );
      }
    } finally {
      _isLoading = false;
    }
  }

  /// Load more bookings (pagination)
  Future<void> loadMoreBookings() async {
    // Prevent concurrent execution
    if (_isLoading) return;
    if (!state.hasMore) return;

    _isLoading = true;

    if (mounted) {
      state = state.copyWith(status: BookingsLoadStatus.loading);
    }
    try {
      final authState = _ref.read(authProvider);
      final user = authState.value?.user;
      final userRole = user?.role;
      final providerId = _providerIdForBookings(userRole);
      if (_shouldSkipProviderFetch(userRole, providerId)) {
        if (mounted) {
          state = state.copyWith(
            status: BookingsLoadStatus.success,
            hasMore: false,
          );
        }
        return;
      }

      final nextPage = state.currentPage + 1;
      final data = await _repository.listBookings(
        userRole: userRole,
        providerId: providerId,
        page: nextPage,
        pageSize: state.pageSize,
      );

      if (mounted) {
        state = state.copyWith(
          bookings: [...state.bookings, ...data],
          status: BookingsLoadStatus.success,
          currentPage: nextPage,
          hasMore: data.length >= state.pageSize,
        );
      }
    } catch (e) {
      if (mounted) {
        state = state.copyWith(status: BookingsLoadStatus.success);
      }
    } finally {
      _isLoading = false;
    }
  }

  /// Retrieve a single booking by ID from server and update local state.
  Future<BookingModel> retrieveBooking(String bookingId) async {
    final booking = await _repository.retrieveBooking(bookingId);
    _replaceBooking(booking);
    return booking;
  }

  /// Create a new booking matching the web app API contract.
  Future<BookingModel> placeBooking({
    required String providerId,
    required DateTime scheduledStart,
    required DateTime scheduledEnd,
    required String serviceType,
    required String currency,
    String? addressText,
    String? notes,
    double? latitude,
    double? longitude,
    required List<Map<String, dynamic>> items,
  }) async {
    // Create booking on server first (safer approach to avoid complex BookingModel construction)
    final booking = await _repository.placeBooking(
      providerId: providerId,
      scheduledStart: scheduledStart,
      scheduledEnd: scheduledEnd,
      serviceType: serviceType,
      currency: currency,
      addressText: addressText,
      notes: notes,
      latitude: latitude,
      longitude: longitude,
      items: items,
    );

    // Add to state after successful server confirmation
    if (mounted) {
      state = state.copyWith(
        bookings: [booking, ...state.bookings],
        status: BookingsLoadStatus.success,
      );
    }
    return booking;
  }

  /// Cancel a booking by id.
  Future<void> cancelBooking(String id) async {
    final matches = state.bookings.where((b) => b.id == id);
    final current = matches.isEmpty ? null : matches.first;
    if (current == null) return;
    await _repository.cancelBooking(current);
    // Refresh from server to get server-truth status
    try {
      final updated = await _repository.retrieveBooking(id);
      if (mounted) {
        _replaceBooking(updated);
      }
    } catch (e) {
      // Fallback to optimistic update if refresh fails
      if (mounted) {
        final updated = current.copyWith(
          status: BookingStatus.cancelled,
          updatedAt: DateTime.now(),
        );
        _replaceBooking(updated);
      }
    }
  }

  /// Delete a booking by id.
  Future<void> deleteBooking(String id) async {
    final matches = state.bookings.where((b) => b.id == id);
    final current = matches.isEmpty ? null : matches.first;
    if (current == null) return;
    await _repository.deleteBooking(current);
    if (mounted) {
      state = state.copyWith(
        bookings: state.bookings.where((b) => b.id != id).toList(),
      );
    }
  }

  /// Charge a booking for payment.
  Future<void> chargeBooking(String id) async {
    // Prevent double charge - check if already processing
    if (_pendingChargeOperations.contains(id)) {
      debugPrint('[chargeBooking] Charge already in progress for booking: $id');
      return;
    }

    final matches = state.bookings.where((b) => b.id == id);
    final current = matches.isEmpty ? null : matches.first;
    if (current == null) return;

    // Track pending charge operation
    _pendingChargeOperations.add(id);

    try {
      await _repository.chargeBooking(current);
      // Refresh from server to get server-truth status
      try {
        final updated = await _repository.retrieveBooking(id);
        _replaceBooking(updated);
      } catch (e) {
        // Fallback to optimistic update if refresh fails
        final updated = current.copyWith(
          status: BookingStatus.confirmed,
          updatedAt: DateTime.now(),
        );
        _replaceBooking(updated);
      }
    } finally {
      // Remove from pending operations
      _pendingChargeOperations.remove(id);
    }
  }

  /// Authorize payment for a booking via Paystack.
  /// Returns the authorization URL to open in WebView.
  Future<String> authorizePayment(String bookingId) async {
    return await _repository.authorizePayment(bookingId);
  }

  /// Mark a booking as ongoing.
  Future<void> startBooking(String id) async {
    final matches = state.bookings.where((b) => b.id == id);
    final current = matches.isEmpty ? null : matches.first;
    if (current == null) return;
    await _repository.startBooking(current);
    // Refresh from server to get server-truth status
    try {
      final updated = await _repository.retrieveBooking(id);
      _replaceBooking(updated);
    } catch (e) {
      // Fallback to optimistic update if refresh fails
      final updated = current.copyWith(
        status: BookingStatus.ongoing,
        updatedAt: DateTime.now(),
      );
      _replaceBooking(updated);
    }
  }

  /// Mark a booking as completed.
  Future<void> completeBooking(String id) async {
    final matches = state.bookings.where((b) => b.id == id);
    final current = matches.isEmpty ? null : matches.first;
    if (current == null) return;
    await _repository.completeBooking(current);
    // Refresh from server to get server-truth status
    try {
      final updated = await _repository.retrieveBooking(id);
      _replaceBooking(updated);
    } catch (e) {
      // Fallback to optimistic update if refresh fails
      final updated = current.copyWith(
        status: BookingStatus.completed,
        updatedAt: DateTime.now(),
      );
      _replaceBooking(updated);
    }
  }

  /// Confirm a pending booking → upcoming.
  Future<void> confirmBooking(String id) async {
    final matches = state.bookings.where((b) => b.id == id);
    final current = matches.isEmpty ? null : matches.first;
    if (current == null) {
      debugPrint('[confirmBooking] Booking not found: $id');
      return;
    }
    try {
      debugPrint('[confirmBooking] Calling repository for booking: $id');
      await _repository.confirmBooking(current);
      debugPrint('[confirmBooking] Repository call successful');
      // Refresh from server to get server-truth status
      try {
        final updated = await _repository.retrieveBooking(id);
        _replaceBooking(updated);
        debugPrint('[confirmBooking] Booking refreshed from server');
      } catch (e) {
        debugPrint(
          '[confirmBooking] Refresh failed, using optimistic update: $e',
        );
        // Fallback to optimistic update if refresh fails
        final updated = current.copyWith(
          status: BookingStatus.confirmed,
          updatedAt: DateTime.now(),
        );
        _replaceBooking(updated);
      }
    } catch (e, stackTrace) {
      debugPrint('[confirmBooking] Error confirming booking: $e');
      debugPrint('[confirmBooking] StackTrace: $stackTrace');
      rethrow;
    }
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
    await _repository.submitReview(booking, rating: rating, review: review);
    // Refresh from server to get server-truth status
    try {
      final updated = await _repository.retrieveBooking(id);
      _replaceBooking(updated);
    } catch (e) {
      // Fallback to optimistic update if refresh fails
      final updatedBooking = booking.copyWith(
        rating: rating,
        review: review,
        updatedAt: DateTime.now(),
      );
      _replaceBooking(updatedBooking);
    }
  }

  /// Reschedule a booking by updating start and end times.
  Future<void> rescheduleBooking(
    String id, {
    required DateTime newStart,
    DateTime? newEnd,
  }) async {
    final matches = state.bookings.where((b) => b.id == id);
    final current = matches.isEmpty ? null : matches.first;
    if (current == null) return;
    await _repository.rescheduleBooking(
      current,
      newStart: newStart,
      newEnd: newEnd,
    );
    // Refresh from server to get server-truth status
    try {
      final updated = await _repository.retrieveBooking(id);
      _replaceBooking(updated);
    } catch (e) {
      // Fallback to optimistic update if refresh fails
      final updated = await _repository.rescheduleBooking(
        current,
        newStart: newStart,
        newEnd: newEnd,
      );
      _replaceBooking(updated);
    }
  }

  /// Update the concluded unit price for a variable-price booking.
  Future<void> updateConcludedPrice(
    String id, {
    required String unitPriceAmount,
  }) async {
    final matches = state.bookings.where((b) => b.id == id);
    final current = matches.isEmpty ? null : matches.first;
    if (current == null) return;
    final updated = await _repository.updateConcludedPrice(
      current,
      unitPriceAmount: unitPriceAmount,
    );
    _replaceBooking(updated);
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
  (ref) => BookingsNotifier(ref.watch(bookingsRepositoryProvider), ref),
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
