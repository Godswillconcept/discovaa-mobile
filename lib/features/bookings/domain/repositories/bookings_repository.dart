import 'package:discovaa/features/bookings/data/models/booking_model.dart';
import 'package:discovaa/features/services/data/models/service_model.dart';
import 'package:flutter/material.dart';

abstract class BookingsRepository {
  List<BookingModel> getCachedBookings();
  Future<List<BookingModel>> listBookings();
  Future<BookingModel> placeBooking({
    required ServiceModel service,
    required DateTime scheduledDate,
    required TimeOfDay scheduledTime,
    String clientName = 'You',
    String? note,
  });
  Future<BookingModel> cancelBooking(BookingModel booking);
  Future<BookingModel> confirmBooking(BookingModel booking);
  Future<BookingModel> completeBooking(BookingModel booking);
  Future<BookingModel> submitReview(
    BookingModel booking, {
    required int rating,
    String? review,
  });
}
