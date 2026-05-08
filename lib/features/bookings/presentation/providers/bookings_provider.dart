import 'dart:async';
import 'package:discovaa/app/dependency_injection/service_locator.dart';
import 'package:discovaa/core/network/dio_client.dart';
import 'package:discovaa/core/network/network_info.dart';
import 'package:discovaa/core/network/websocket_client.dart';
import 'package:discovaa/core/network/websocket_service.dart';
import 'package:discovaa/core/storage/hive_service.dart';
import 'package:discovaa/features/authentication/presentation/providers/auth_provider.dart';
import 'package:discovaa/features/bookings/data/models/booking_api_models.dart';
import 'package:discovaa/features/bookings/data/models/booking_model.dart';
import 'package:discovaa/features/bookings/data/repositories/bookings_repository_impl.dart';
import 'package:discovaa/features/bookings/domain/repositories/bookings_repository.dart';
import 'package:discovaa/features/notifications/presentation/providers/email_preferences_provider.dart';
import 'package:discovaa/features/payments/domain/repositories/payment_repository.dart';
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
  final DateTime? lastPolledAt;

  const BookingsState({
    this.bookings = const [],
    this.status = BookingsLoadStatus.idle,
    this.errorMessage,
    this.searchQuery = '',
    this.currentPage = 1,
    this.pageSize = 20,
    this.hasMore = true,
    this.lastPolledAt,
  });

  BookingsState copyWith({
    List<BookingModel>? bookings,
    BookingsLoadStatus? status,
    String? errorMessage,
    String? searchQuery,
    int? currentPage,
    int? pageSize,
    bool? hasMore,
    DateTime? lastPolledAt,
  }) {
    return BookingsState(
      bookings: bookings ?? this.bookings,
      status: status ?? this.status,
      errorMessage: errorMessage,
      searchQuery: searchQuery ?? this.searchQuery,
      currentPage: currentPage ?? this.currentPage,
      pageSize: pageSize ?? this.pageSize,
      hasMore: hasMore ?? this.hasMore,
      lastPolledAt: lastPolledAt ?? this.lastPolledAt,
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
  BookingsNotifier(this._repository, this._ref, this._webSocketService)
    : super(const BookingsState()) {
    _initWebSocket();
  }

  final BookingsRepository _repository;
  final Ref _ref;
  final WebSocketService _webSocketService;

  // WebSocket subscriptions
  StreamSubscription? _bookingStatusSubscription;
  StreamSubscription? _paymentStatusSubscription;

  // Track pending operations to prevent double charges
  final Set<String> _pendingChargeOperations = {};
  // Loading flag to prevent concurrent state mutations
  bool _isLoading = false;

  // Polling mechanism for when WebSocket is disconnected
  StreamSubscription? _connectionStateSubscription;
  Timer? _pollingTimer;
  DateTime? _lastPolledAt;

  /// Initialize WebSocket listeners for booking updates
  void _initWebSocket() {
    // Listen to booking status changes
    _bookingStatusSubscription = _webSocketService.bookingStatusStream.listen(
      _handleBookingStatusUpdate,
    );

    // Listen to payment status changes
    _paymentStatusSubscription = _webSocketService.paymentStatusStream.listen(
      _handlePaymentStatusUpdate,
    );

    // Listen to WebSocket connection state for polling fallback
    _connectionStateSubscription = _webSocketService.connectionStateStream
        .listen(_handleConnectionStateChange);
  }

  /// Handle WebSocket connection state changes
  void _handleConnectionStateChange(WebSocketConnectionState state) {
    debugPrint('[Bookings] WebSocket connection state: $state');

    if (state == WebSocketConnectionState.disconnected) {
      _startPolling();
    } else if (state == WebSocketConnectionState.connected) {
      _stopPolling();
      // Re-subscribe to WebSocket events is handled by WebSocketService
    }
  }

  /// Start polling for booking updates (fallback when WebSocket is disconnected)
  void _startPolling() {
    // Don't start polling if already polling
    if (_pollingTimer != null) return;

    // Don't poll if all bookings are in terminal state
    if (_allBookingsTerminal()) {
      debugPrint('[Bookings] All bookings terminal, skipping polling');
      return;
    }

    debugPrint('[Bookings] Starting polling fallback (30s interval)');
    _pollingTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _pollBookings(),
    );

    // Poll immediately
    _pollBookings();
  }

  /// Stop polling for booking updates
  void _stopPolling() {
    if (_pollingTimer != null) {
      debugPrint('[Bookings] Stopping polling fallback');
      _pollingTimer?.cancel();
      _pollingTimer = null;
    }
  }

  /// Poll bookings from REST API
  Future<void> _pollBookings() async {
    try {
      // Only poll for non-terminal statuses (REQUESTED, CONFIRMED)
      final bookings = await _repository.getBookings(
        status: 'REQUESTED,CONFIRMED',
        page: 1,
      );

      _lastPolledAt = DateTime.now();

      if (!mounted) return;

      // Update state with polled data, preserving terminal bookings
      final currentBookings = List<BookingModel>.from(state.bookings);
      final terminalBookings = currentBookings
          .where((b) => _isTerminalStatus(b.status))
          .toList();

      // Merge: keep terminal bookings from current state, add/update polled bookings
      final updatedBookings = [...terminalBookings, ...bookings];

      // Remove duplicates by keeping the latest version
      final uniqueBookings = <String, BookingModel>{};
      for (final booking in updatedBookings) {
        uniqueBookings[booking.id] = booking;
      }

      state = state.copyWith(
        bookings: uniqueBookings.values.toList(),
        lastPolledAt: _lastPolledAt,
      );

      debugPrint(
        '[Bookings] Polling update: ${bookings.length} active bookings',
      );
    } catch (e) {
      debugPrint('[Bookings] Polling error: $e');
    }
  }

  /// Check if all current bookings are in terminal state
  bool _allBookingsTerminal() {
    return state.bookings.every((b) => _isTerminalStatus(b.status));
  }

  /// Check if a booking status is terminal (no further updates expected)
  bool _isTerminalStatus(BookingStatus status) {
    return status == BookingStatus.cancelled ||
        status == BookingStatus.completed;
  }

  /// Handle booking status updates from WebSocket
  void _handleBookingStatusUpdate(Map<String, dynamic> event) {
    final bookingId = event['booking_id'] as String?;
    final newStatusStr = event['new_status'] as String?;

    if (bookingId == null || newStatusStr == null) return;

    debugPrint(
      '[Bookings] WebSocket: Booking $bookingId status changed to $newStatusStr',
    );

    // Parse new status
    final newStatus = BookingStatus.values.firstWhere(
      (s) => s.name.toUpperCase() == newStatusStr.toUpperCase(),
      orElse: () {
        debugPrint('[Bookings] Invalid status from WebSocket: $newStatusStr');
        return BookingStatus
            .requested; // Fallback, will be caught by validation
      },
    );

    // Find the booking in state
    final currentBookings = List<BookingModel>.from(state.bookings);
    final bookingIndex = currentBookings.indexWhere((b) => b.id == bookingId);

    if (bookingIndex != -1) {
      final booking = currentBookings[bookingIndex];

      // VALIDATE TRANSITION
      if (!booking.status.canTransitionTo(newStatus)) {
        debugPrint(
          '[Bookings] Invalid status transition rejected: '
          '${booking.status.name} → ${newStatus.name} for booking $bookingId',
        );
        // Set error state to notify UI
        state = state.copyWith(
          errorMessage:
              'Invalid status transition: '
              '${booking.status.displayName} → ${newStatus.displayName}',
        );
        return; // Reject invalid transition
      }

      // Valid transition - update state
      final updatedBooking = booking.copyWith(status: newStatus);
      currentBookings[bookingIndex] = updatedBooking;
      state = state.copyWith(
        bookings: currentBookings,
        errorMessage: null, // Clear any previous error
      );

      // Send transactional email based on status
      _sendBookingStatusEmail(bookingId, newStatus.name);
    }
  }

  /// Send transactional email for booking status changes
  void _sendBookingStatusEmail(String bookingId, String newStatus) {
    try {
      final emailRepo = _ref.read(emailRepositoryProvider);
      String emailType;
      switch (newStatus) {
        case 'CONFIRMED':
        case 'COMPLETED':
        case 'CANCELLED':
          emailType = 'BOOKING_STATUS';
          break;
        default:
          emailType = 'BOOKING_UPDATED';
      }

      emailRepo.sendTransactionalEmail(
        type: emailType,
        context: {'booking_id': bookingId, 'status': newStatus},
      );
    } catch (e) {
      debugPrint('Failed to send booking status email: $e');
    }
  }

  /// Handle payment status updates from WebSocket
  void _handlePaymentStatusUpdate(Map<String, dynamic> event) {
    final bookingId = event['booking_id'] as String?;
    final paymentStatus = event['payment_status'] as String?;

    if (bookingId == null || paymentStatus == null) return;

    debugPrint(
      '[Bookings] WebSocket: Booking $bookingId payment status changed to $paymentStatus',
    );

    // Find and update the booking in state
    final currentBookings = List<BookingModel>.from(state.bookings);
    final bookingIndex = currentBookings.indexWhere((b) => b.id == bookingId);

    if (bookingIndex != -1) {
      final booking = currentBookings[bookingIndex];
      final updatedBooking = booking.copyWith(paymentStatus: paymentStatus);

      currentBookings[bookingIndex] = updatedBooking;
      state = state.copyWith(bookings: currentBookings);

      // Send transactional email for payment status changes
      _sendPaymentStatusEmail(bookingId, paymentStatus);
    }
  }

  /// Send transactional email for payment status changes
  void _sendPaymentStatusEmail(String bookingId, String paymentStatus) {
    try {
      final emailRepo = _ref.read(emailRepositoryProvider);
      emailRepo.sendTransactionalEmail(
        type: 'PAYMENT_STATUS',
        context: {'booking_id': bookingId, 'payment_status': paymentStatus},
      );
    } catch (e) {
      debugPrint('Failed to send payment status email: $e');
    }
  }

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
    return isProviderRole(userRole) &&
        (providerId == null || providerId.isEmpty);
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

    // Send BOOKING_CREATED email
    try {
      final emailRepo = _ref.read(emailRepositoryProvider);
      await emailRepo.sendTransactionalEmail(
        type: 'BOOKING_CREATED',
        context: {'booking_id': booking.id, 'status': booking.status.name},
      );
    } catch (e) {
      debugPrint('Failed to send booking created email: $e');
    }

    return booking;
  }

  /// Cancel a booking by id.
  Future<void> cancelBooking(String id) async {
    final matches = state.bookings.where((b) => b.id == id);
    final current = matches.isEmpty ? null : matches.first;
    if (current == null) return;

    // Validate transition
    if (!current.status.canTransitionTo(BookingStatus.cancelled)) {
      debugPrint(
        '[cancelBooking] Invalid transition: '
        '${current.status.name} → cancelled for booking $id',
      );
      if (mounted) {
        state = state.copyWith(
          errorMessage:
              'Cannot cancel booking from status: ${current.status.displayName}',
        );
      }
      return;
    }

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

    // Send email notification for cancellation
    try {
      final emailRepo = _ref.read(emailRepositoryProvider);
      await emailRepo.sendTransactionalEmail(
        type: 'BOOKING_STATUS',
        context: {'booking_id': id, 'status': 'CANCELLED'},
      );
    } catch (e) {
      debugPrint('Failed to send cancellation email: $e');
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

    // Validate transition
    if (!current.status.canTransitionTo(BookingStatus.completed)) {
      debugPrint(
        '[completeBooking] Invalid transition: '
        '${current.status.name} → completed for booking $id',
      );
      if (mounted) {
        state = state.copyWith(
          errorMessage:
              'Cannot complete booking from status: ${current.status.displayName}',
        );
      }
      return;
    }

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

    // NEW: Capture payment (release funds) when booking is completed
    if (current.paymentId != null) {
      try {
        final paymentRepo = _ref.read(paymentRepositoryProvider);
        await paymentRepo.capturePayment(current.paymentId!);
        debugPrint('[completeBooking] Payment captured for booking: $id');
      } catch (e) {
        debugPrint('[completeBooking] Payment capture failed: $e');
        // Don't fail booking completion if payment capture fails
      }
    }

    // Send email notification for completion
    try {
      final emailRepo = _ref.read(emailRepositoryProvider);
      await emailRepo.sendTransactionalEmail(
        type: 'BOOKING_STATUS',
        context: {'booking_id': id, 'status': 'COMPLETED'},
      );
    } catch (e) {
      debugPrint('Failed to send completion email: $e');
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

    // Validate transition
    if (!current.status.canTransitionTo(BookingStatus.confirmed)) {
      debugPrint(
        '[confirmBooking] Invalid transition: '
        '${current.status.name} → confirmed for booking $id',
      );
      if (mounted) {
        state = state.copyWith(
          errorMessage:
              'Cannot confirm booking from status: ${current.status.displayName}',
        );
      }
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

      // NEW: Authorize payment (hold funds) when booking is confirmed
      if (current.paymentId != null) {
        try {
          final paymentRepo = _ref.read(paymentRepositoryProvider);
          await paymentRepo.authorizePayment(
            current.id,
            'default', // payment method - can be enhanced later
          );
          debugPrint('[confirmBooking] Payment authorized for booking: $id');
        } catch (e) {
          debugPrint('[confirmBooking] Payment authorization failed: $e');
          // Don't fail booking confirmation if payment auth fails
        }
      }

      // Send email notification for confirmation
      try {
        final emailRepo = _ref.read(emailRepositoryProvider);
        await emailRepo.sendTransactionalEmail(
          type: 'BOOKING_STATUS',
          context: {'booking_id': id, 'status': 'CONFIRMED'},
        );
      } catch (e) {
        debugPrint('Failed to send confirmation email: $e');
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

  @override
  void dispose() {
    _bookingStatusSubscription?.cancel();
    _paymentStatusSubscription?.cancel();
    _connectionStateSubscription?.cancel();
    _stopPolling();
    super.dispose();
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
  (ref) => BookingsNotifier(
    ref.watch(bookingsRepositoryProvider),
    ref,
    sl<WebSocketService>(),
  ),
);

/// Payment repository provider
final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  return sl<PaymentRepository>();
});

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
