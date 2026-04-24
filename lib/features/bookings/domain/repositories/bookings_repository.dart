import 'package:discovaa/features/bookings/data/models/booking_api_models.dart';
import 'package:discovaa/features/bookings/data/models/booking_model.dart';

abstract class BookingsRepository {
  List<BookingModel> getCachedBookings({String? userRole});
  Future<List<BookingModel>> listBookings({
    String? userRole,
    String? providerId,
  });

  /// Check if a provider is available for the given time slot.
  Future<({bool available, List<String> reasons})> checkAvailability({
    required String providerId,
    required DateTime start,
    required DateTime end,
  });

  Future<BookingModel> placeBooking({
    required String providerId,
    required DateTime scheduledStart,
    required DateTime scheduledEnd,
    required String serviceType,
    required String currency,
    String? addressText,
    String? notes,
    required List<Map<String, dynamic>> items,
  });
  Future<BookingModel> cancelBooking(BookingModel booking);
  Future<BookingModel> confirmBooking(BookingModel booking);
  Future<BookingModel> completeBooking(BookingModel booking);
  Future<BookingModel> submitReview(
    BookingModel booking, {
    required int rating,
    String? review,
  });

  /// Reschedule a booking by updating start and end times.
  Future<BookingModel> rescheduleBooking(
    BookingModel booking, {
    required DateTime newStart,
    DateTime? newEnd,
  });

  /// Update the concluded unit price for a variable-price booking.
  Future<BookingModel> updateConcludedPrice(
    BookingModel booking, {
    required String unitPriceAmount,
  });

  /// Fetch user profile from /api/accounts/me/
  Future<UserProfileDto?> fetchUserProfile();

  /// Fetch provider profile from /api/providers/me/profile/
  Future<ProviderProfileDto?> fetchProviderProfile();

  /// Fetch reviews for a specific booking from /api/reviews/
  Future<ReviewDto?> fetchBookingReview(String bookingId);
}
