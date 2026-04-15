import 'package:discovaa/features/bookings/data/models/booking_model.dart';
import 'package:discovaa/features/services/data/models/service_model.dart';
import 'package:flutter/material.dart';

/// Simulates a remote API call for bookings.
/// Replace [fetchBookings] with a real HTTP call when the backend is ready.
class BookingsMockDatasource {
  /// Mimics network latency with a 500ms delay then returns mock bookings.
  static Future<List<BookingModel>> fetchBookings() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _mockBookings;
  }

  static final List<BookingModel> _mockBookings = [
    // ── Upcoming ──────────────────────────────────────────────────────────
    BookingModel(
      id: 'bk-001',
      service: BookedServiceSnapshot(
        serviceId: 'svc-001',
        title: 'Full Electrical Inspection',
        category: 'Electrician',
        imagePath: 'assets/images/placeholders/service_1.png',
        formattedPrice: 'NGN 15000',
        pricingModel: PricingModel.fixed,
        durationMinutes: 90,
      ),
      clientName: 'Amara Nwosu',
      clientAvatarPath: 'assets/images/placeholders/artisan_01.png',
      scheduledDate: DateTime.now().add(const Duration(days: 3)),
      scheduledTime: const TimeOfDay(hour: 10, minute: 0),
      status: BookingStatus.upcoming,
      note: 'Please bring a voltage tester. Access via the back gate.',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    BookingModel(
      id: 'bk-002',
      service: BookedServiceSnapshot(
        serviceId: 'svc-003',
        title: 'Interior Wall Painting',
        category: 'Painting',
        imagePath: 'assets/images/placeholders/service_13.png',
        formattedPrice: 'NGN 45000 / pkg',
        pricingModel: PricingModel.package,
        durationMinutes: 480,
      ),
      clientName: 'Chukwuemeka Obi',
      clientAvatarPath: 'assets/images/placeholders/artisan_02.png',
      scheduledDate: DateTime.now().add(const Duration(days: 7)),
      scheduledTime: const TimeOfDay(hour: 8, minute: 0),
      status: BookingStatus.upcoming,
      note: 'Three bedrooms — cream and white palette.',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),

    // ── Pending ───────────────────────────────────────────────────────────
    BookingModel(
      id: 'bk-003',
      service: BookedServiceSnapshot(
        serviceId: 'svc-005',
        title: 'Deep Home Cleaning',
        category: 'Cleaning',
        imagePath: 'assets/images/placeholders/service_19.png',
        formattedPrice: 'NGN 25000 / pkg',
        pricingModel: PricingModel.package,
        durationMinutes: 300,
      ),
      clientName: 'Fatima Bello',
      clientAvatarPath: 'assets/images/placeholders/artisan_03.png',
      scheduledDate: DateTime.now().add(const Duration(days: 1)),
      scheduledTime: const TimeOfDay(hour: 9, minute: 0),
      status: BookingStatus.pending,
      note: 'Focus on kitchen and bathrooms. Eco-friendly products preferred.',
      createdAt: DateTime.now().subtract(const Duration(hours: 5)),
    ),
    BookingModel(
      id: 'bk-004',
      service: BookedServiceSnapshot(
        serviceId: 'svc-009',
        title: 'Event Photography',
        category: 'Photography',
        imagePath: 'assets/images/placeholders/artisan_01.png',
        formattedPrice: 'NGN 120000 / pkg',
        pricingModel: PricingModel.package,
        durationMinutes: 360,
      ),
      clientName: 'Ngozi Eze',
      clientAvatarPath: 'assets/images/placeholders/artisan_04.png',
      scheduledDate: DateTime.now().add(const Duration(days: 14)),
      scheduledTime: const TimeOfDay(hour: 14, minute: 0),
      status: BookingStatus.pending,
      note: 'Wedding reception. 200 guests expected.',
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),

    // ── Ongoing ───────────────────────────────────────────────────────────
    BookingModel(
      id: 'bk-005',
      service: BookedServiceSnapshot(
        serviceId: 'svc-002',
        title: 'Pipe Repair & Leak Fix',
        category: 'Plumbing',
        imagePath: 'assets/images/placeholders/service_2.png',
        formattedPrice: 'NGN 8000/hr',
        pricingModel: PricingModel.hourly,
        durationMinutes: 60,
      ),
      clientName: 'Usman Garba',
      clientAvatarPath: 'assets/images/placeholders/artisan_05.png',
      scheduledDate: DateTime.now(),
      scheduledTime: TimeOfDay(hour: DateTime.now().hour - 1, minute: 0),
      status: BookingStatus.ongoing,
      note: 'Kitchen sink and master bathroom tap.',
      createdAt: DateTime.now().subtract(const Duration(days: 0)),
    ),

    // ── Completed ─────────────────────────────────────────────────────────
    BookingModel(
      id: 'bk-006',
      service: BookedServiceSnapshot(
        serviceId: 'svc-004',
        title: 'Custom Furniture Assembly',
        category: 'Carpentry',
        imagePath: 'assets/images/placeholders/service_18.png',
        formattedPrice: 'NGN 12000',
        pricingModel: PricingModel.fixed,
        durationMinutes: 120,
      ),
      clientName: 'Blessing Adeyemi',
      clientAvatarPath: 'assets/images/placeholders/artisan_06.png',
      scheduledDate: DateTime.now().subtract(const Duration(days: 5)),
      scheduledTime: const TimeOfDay(hour: 10, minute: 0),
      status: BookingStatus.completed,
      createdAt: DateTime.now().subtract(const Duration(days: 7)),
      updatedAt: DateTime.now().subtract(const Duration(days: 5)),
      rating: 5,
      review: 'Excellent work! Very professional and on time.',
    ),
    BookingModel(
      id: 'bk-007',
      service: BookedServiceSnapshot(
        serviceId: 'svc-007',
        title: 'PC & Laptop Repair',
        category: 'IT & Tech Support',
        imagePath: 'assets/images/placeholders/service_21.png',
        formattedPrice: 'NGN 5000/hr',
        pricingModel: PricingModel.hourly,
        durationMinutes: 60,
      ),
      clientName: 'Tunde Fashola',
      clientAvatarPath: 'assets/images/placeholders/artisan_07.png',
      scheduledDate: DateTime.now().subtract(const Duration(days: 10)),
      scheduledTime: const TimeOfDay(hour: 11, minute: 0),
      status: BookingStatus.completed,
      createdAt: DateTime.now().subtract(const Duration(days: 12)),
      updatedAt: DateTime.now().subtract(const Duration(days: 10)),
      rating: 4,
      review: 'Good service, laptop is working perfectly.',
    ),
    BookingModel(
      id: 'bk-008',
      service: BookedServiceSnapshot(
        serviceId: 'svc-012',
        title: 'AC Service & Gas Refill',
        category: 'Home Maintenance',
        imagePath: 'assets/images/placeholders/artisan_04.png',
        formattedPrice: 'NGN 20000',
        pricingModel: PricingModel.fixed,
        durationMinutes: 90,
      ),
      clientName: 'Chiamaka Okeke',
      clientAvatarPath: 'assets/images/placeholders/artisan_08.png',
      scheduledDate: DateTime.now().subtract(const Duration(days: 20)),
      scheduledTime: const TimeOfDay(hour: 9, minute: 30),
      status: BookingStatus.completed,
      createdAt: DateTime.now().subtract(const Duration(days: 22)),
      updatedAt: DateTime.now().subtract(const Duration(days: 20)),
      rating: 5,
      review: 'AC is ice cold now. Will definitely book again.',
    ),

    // ── Cancelled ─────────────────────────────────────────────────────────
    BookingModel(
      id: 'bk-009',
      service: BookedServiceSnapshot(
        serviceId: 'svc-008',
        title: 'Lawn Mowing & Garden Care',
        category: 'Landscaping',
        imagePath: 'assets/images/placeholders/service_22.png',
        formattedPrice: 'NGN 18000 / pkg',
        pricingModel: PricingModel.package,
        durationMinutes: 180,
      ),
      clientName: 'Emeka Dike',
      clientAvatarPath: 'assets/images/placeholders/artisan_01.png',
      scheduledDate: DateTime.now().subtract(const Duration(days: 3)),
      scheduledTime: const TimeOfDay(hour: 7, minute: 0),
      status: BookingStatus.cancelled,
      note: 'Cancelled due to rain.',
      createdAt: DateTime.now().subtract(const Duration(days: 6)),
      updatedAt: DateTime.now().subtract(const Duration(days: 3)),
    ),
  ];
}
