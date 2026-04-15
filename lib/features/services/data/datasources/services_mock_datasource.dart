import 'package:discovaa/features/services/data/models/service_model.dart';
import 'package:flutter/material.dart';

/// Simulates a remote API call for services.
/// Replace [fetchServices] with a real HTTP call when the backend is ready.
/// Returns a realistic catalog of artisan/home-service listings.
class ServicesMockDatasource {
  /// Mimics network latency with a 600ms delay then returns mock data.
  static Future<List<ServiceModel>> fetchServices() async {
    await Future.delayed(const Duration(milliseconds: 600));
    return _mockServices;
  }

  static final List<ServiceModel> _mockServices = [
    // 1 ─ Electrical
    ServiceModel(
      id: 'svc-001',
      title: 'Full Electrical Inspection',
      category: 'Electrician',
      description:
          'Complete home or office wiring inspection, fault detection, circuit breaker testing, and safety compliance check.',
      pricingModel: PricingModel.fixed,
      priceType: PriceType.fixed,
      currency: 'NGN',
      amount: 15000,
      durationMinutes: 90,
      imagePath: 'assets/images/placeholders/service_1.png',
      weeklySchedule: {
        WeekDay.monday: [
          const ServiceTimeSlot(
            start: TimeOfDay(hour: 8, minute: 0),
            end: TimeOfDay(hour: 17, minute: 0),
          ),
        ],
        WeekDay.wednesday: [
          const ServiceTimeSlot(
            start: TimeOfDay(hour: 8, minute: 0),
            end: TimeOfDay(hour: 17, minute: 0),
          ),
        ],
        WeekDay.friday: [
          const ServiceTimeSlot(
            start: TimeOfDay(hour: 8, minute: 0),
            end: TimeOfDay(hour: 14, minute: 0),
          ),
        ],
      },
      isActive: true,
      createdAt: DateTime(2025, 3, 10),
    ),

    // 2 ─ Plumbing
    ServiceModel(
      id: 'svc-002',
      title: 'Pipe Repair & Leak Fix',
      category: 'Plumbing',
      description:
          'Diagnosis and repair of burst pipes, leaking taps, drainage blockages, and water pressure issues.',
      pricingModel: PricingModel.hourly,
      priceType: PriceType.variable,
      currency: 'NGN',
      amount: 8000,
      durationMinutes: 60,
      imagePath: 'assets/images/placeholders/service_2.png',
      weeklySchedule: {
        WeekDay.tuesday: [
          const ServiceTimeSlot(
            start: TimeOfDay(hour: 7, minute: 0),
            end: TimeOfDay(hour: 16, minute: 0),
          ),
        ],
        WeekDay.thursday: [
          const ServiceTimeSlot(
            start: TimeOfDay(hour: 7, minute: 0),
            end: TimeOfDay(hour: 16, minute: 0),
          ),
        ],
        WeekDay.saturday: [
          const ServiceTimeSlot(
            start: TimeOfDay(hour: 9, minute: 0),
            end: TimeOfDay(hour: 13, minute: 0),
          ),
        ],
      },
      isActive: true,
      createdAt: DateTime(2025, 3, 12),
    ),

    // 3 ─ Painting
    ServiceModel(
      id: 'svc-003',
      title: 'Interior Wall Painting',
      category: 'Painting',
      description:
          'Professional interior painting — wall prep, priming, and two-coat finish in your choice of colour. Per room pricing available.',
      pricingModel: PricingModel.package,
      priceType: PriceType.fixed,
      currency: 'NGN',
      amount: 45000,
      durationMinutes: 480,
      imagePath: 'assets/images/placeholders/service_13.png',
      weeklySchedule: {
        WeekDay.monday: [
          const ServiceTimeSlot(
            start: TimeOfDay(hour: 8, minute: 0),
            end: TimeOfDay(hour: 18, minute: 0),
          ),
        ],
        WeekDay.tuesday: [
          const ServiceTimeSlot(
            start: TimeOfDay(hour: 8, minute: 0),
            end: TimeOfDay(hour: 18, minute: 0),
          ),
        ],
        WeekDay.wednesday: [
          const ServiceTimeSlot(
            start: TimeOfDay(hour: 8, minute: 0),
            end: TimeOfDay(hour: 18, minute: 0),
          ),
        ],
        WeekDay.thursday: [
          const ServiceTimeSlot(
            start: TimeOfDay(hour: 8, minute: 0),
            end: TimeOfDay(hour: 18, minute: 0),
          ),
        ],
        WeekDay.friday: [
          const ServiceTimeSlot(
            start: TimeOfDay(hour: 8, minute: 0),
            end: TimeOfDay(hour: 18, minute: 0),
          ),
        ],
      },
      isActive: true,
      createdAt: DateTime(2025, 3, 15),
    ),

    // 4 ─ Carpentry
    ServiceModel(
      id: 'svc-004',
      title: 'Custom Furniture Assembly',
      category: 'Carpentry',
      description:
          'Flat-pack and custom furniture assembly, wardrobe fitting, shelving installation, and door hanging.',
      pricingModel: PricingModel.fixed,
      priceType: PriceType.variable,
      currency: 'NGN',
      amount: 12000,
      durationMinutes: 120,
      imagePath: 'assets/images/placeholders/service_18.png',
      weeklySchedule: {
        WeekDay.monday: [
          const ServiceTimeSlot(
            start: TimeOfDay(hour: 9, minute: 0),
            end: TimeOfDay(hour: 17, minute: 0),
          ),
        ],
        WeekDay.wednesday: [
          const ServiceTimeSlot(
            start: TimeOfDay(hour: 9, minute: 0),
            end: TimeOfDay(hour: 17, minute: 0),
          ),
        ],
        WeekDay.saturday: [
          const ServiceTimeSlot(
            start: TimeOfDay(hour: 10, minute: 0),
            end: TimeOfDay(hour: 15, minute: 0),
          ),
        ],
      },
      isActive: true,
      createdAt: DateTime(2025, 3, 18),
    ),

    // 5 ─ Cleaning
    ServiceModel(
      id: 'svc-005',
      title: 'Deep Home Cleaning',
      category: 'Cleaning',
      description:
          'Full deep-clean including kitchen, bathrooms, bedrooms, and living areas. Eco-friendly products used on request.',
      pricingModel: PricingModel.package,
      priceType: PriceType.fixed,
      currency: 'NGN',
      amount: 25000,
      durationMinutes: 300,
      imagePath: 'assets/images/placeholders/service_19.png',
      weeklySchedule: {
        WeekDay.tuesday: [
          const ServiceTimeSlot(
            start: TimeOfDay(hour: 8, minute: 0),
            end: TimeOfDay(hour: 16, minute: 0),
          ),
          const ServiceTimeSlot(
            start: TimeOfDay(hour: 16, minute: 30),
            end: TimeOfDay(hour: 20, minute: 0),
          ),
        ],
        WeekDay.thursday: [
          const ServiceTimeSlot(
            start: TimeOfDay(hour: 8, minute: 0),
            end: TimeOfDay(hour: 16, minute: 0),
          ),
        ],
        WeekDay.saturday: [
          const ServiceTimeSlot(
            start: TimeOfDay(hour: 9, minute: 0),
            end: TimeOfDay(hour: 14, minute: 0),
          ),
        ],
      },
      isActive: true,
      createdAt: DateTime(2025, 3, 20),
    ),

    // 6 ─ Beauty & Wellness (inactive)
    ServiceModel(
      id: 'svc-006',
      title: 'Haircut + Beard Trim',
      category: 'Beauty & Wellness',
      description:
          'Professional barber service at your location. Includes haircut, lineup, beard sculpt, and hot towel finish.',
      pricingModel: PricingModel.fixed,
      priceType: PriceType.fixed,
      currency: 'NGN',
      amount: 6500,
      durationMinutes: 45,
      imagePath: 'assets/images/placeholders/service_20.png',
      weeklySchedule: {
        WeekDay.monday: [
          const ServiceTimeSlot(
            start: TimeOfDay(hour: 9, minute: 0),
            end: TimeOfDay(hour: 19, minute: 0),
          ),
        ],
        WeekDay.wednesday: [
          const ServiceTimeSlot(
            start: TimeOfDay(hour: 9, minute: 0),
            end: TimeOfDay(hour: 19, minute: 0),
          ),
        ],
        WeekDay.friday: [
          const ServiceTimeSlot(
            start: TimeOfDay(hour: 9, minute: 0),
            end: TimeOfDay(hour: 19, minute: 0),
          ),
        ],
        WeekDay.saturday: [
          const ServiceTimeSlot(
            start: TimeOfDay(hour: 10, minute: 0),
            end: TimeOfDay(hour: 17, minute: 0),
          ),
        ],
      },
      isActive: false,
      createdAt: DateTime(2025, 3, 22),
    ),

    // 7 ─ IT & Tech Support
    ServiceModel(
      id: 'svc-007',
      title: 'PC & Laptop Repair',
      category: 'IT & Tech Support',
      description:
          'Hardware diagnostics, OS reinstall, virus removal, RAM/SSD upgrades, screen replacement, and data recovery.',
      pricingModel: PricingModel.hourly,
      priceType: PriceType.fixed,
      currency: 'NGN',
      amount: 5000,
      durationMinutes: 60,
      imagePath: 'assets/images/placeholders/service_21.png',
      weeklySchedule: {
        WeekDay.monday: [
          const ServiceTimeSlot(
            start: TimeOfDay(hour: 10, minute: 0),
            end: TimeOfDay(hour: 18, minute: 0),
          ),
        ],
        WeekDay.tuesday: [
          const ServiceTimeSlot(
            start: TimeOfDay(hour: 10, minute: 0),
            end: TimeOfDay(hour: 18, minute: 0),
          ),
        ],
        WeekDay.thursday: [
          const ServiceTimeSlot(
            start: TimeOfDay(hour: 10, minute: 0),
            end: TimeOfDay(hour: 18, minute: 0),
          ),
        ],
        WeekDay.friday: [
          const ServiceTimeSlot(
            start: TimeOfDay(hour: 10, minute: 0),
            end: TimeOfDay(hour: 18, minute: 0),
          ),
        ],
      },
      isActive: true,
      createdAt: DateTime(2025, 3, 25),
    ),

    // 8 ─ Landscaping
    ServiceModel(
      id: 'svc-008',
      title: 'Lawn Mowing & Garden Care',
      category: 'Landscaping',
      description:
          'Weekly or fortnightly lawn mowing, hedge trimming, flower bed weeding, and general garden maintenance.',
      pricingModel: PricingModel.package,
      priceType: PriceType.variable,
      currency: 'NGN',
      amount: 18000,
      durationMinutes: 180,
      imagePath: 'assets/images/placeholders/service_22.png',
      weeklySchedule: {
        WeekDay.wednesday: [
          const ServiceTimeSlot(
            start: TimeOfDay(hour: 7, minute: 0),
            end: TimeOfDay(hour: 13, minute: 0),
          ),
        ],
        WeekDay.saturday: [
          const ServiceTimeSlot(
            start: TimeOfDay(hour: 7, minute: 0),
            end: TimeOfDay(hour: 12, minute: 0),
          ),
        ],
      },
      isActive: true,
      createdAt: DateTime(2025, 4, 1),
    ),

    // 9 ─ Photography
    ServiceModel(
      id: 'svc-009',
      title: 'Event Photography',
      category: 'Photography',
      description:
          'Professional event photography for weddings, birthdays, and corporate events. Includes 200+ edited photos delivered digitally.',
      pricingModel: PricingModel.package,
      priceType: PriceType.fixed,
      currency: 'NGN',
      amount: 120000,
      durationMinutes: 360,
      imagePath: 'assets/images/placeholders/artisan_01.png',
      weeklySchedule: {
        WeekDay.friday: [
          const ServiceTimeSlot(
            start: TimeOfDay(hour: 10, minute: 0),
            end: TimeOfDay(hour: 22, minute: 0),
          ),
        ],
        WeekDay.saturday: [
          const ServiceTimeSlot(
            start: TimeOfDay(hour: 8, minute: 0),
            end: TimeOfDay(hour: 22, minute: 0),
          ),
        ],
        WeekDay.sunday: [
          const ServiceTimeSlot(
            start: TimeOfDay(hour: 10, minute: 0),
            end: TimeOfDay(hour: 20, minute: 0),
          ),
        ],
      },
      isActive: true,
      createdAt: DateTime(2025, 4, 3),
    ),

    // 10 ─ Catering
    ServiceModel(
      id: 'svc-010',
      title: 'Party & Event Catering',
      category: 'Catering',
      description:
          'Full-service catering for up to 200 guests. Menu planning, cooking, and serving staff included. Buffet and plated options available.',
      pricingModel: PricingModel.package,
      priceType: PriceType.variable,
      currency: 'NGN',
      amount: 250000,
      durationMinutes: 480,
      imagePath: 'assets/images/placeholders/artisan_02.png',
      weeklySchedule: {
        WeekDay.friday: [
          const ServiceTimeSlot(
            start: TimeOfDay(hour: 8, minute: 0),
            end: TimeOfDay(hour: 23, minute: 0),
          ),
        ],
        WeekDay.saturday: [
          const ServiceTimeSlot(
            start: TimeOfDay(hour: 8, minute: 0),
            end: TimeOfDay(hour: 23, minute: 0),
          ),
        ],
        WeekDay.sunday: [
          const ServiceTimeSlot(
            start: TimeOfDay(hour: 10, minute: 0),
            end: TimeOfDay(hour: 20, minute: 0),
          ),
        ],
      },
      isActive: true,
      createdAt: DateTime(2025, 4, 5),
    ),

    // 11 ─ Security
    ServiceModel(
      id: 'svc-011',
      title: 'CCTV Installation',
      category: 'Security',
      description:
          'Supply and installation of IP and analogue CCTV systems. Includes 4–16 camera setup, DVR/NVR config, and remote viewing setup.',
      pricingModel: PricingModel.fixed,
      priceType: PriceType.fixed,
      currency: 'NGN',
      amount: 85000,
      durationMinutes: 240,
      imagePath: 'assets/images/placeholders/artisan_03.png',
      weeklySchedule: {
        WeekDay.monday: [
          const ServiceTimeSlot(
            start: TimeOfDay(hour: 8, minute: 0),
            end: TimeOfDay(hour: 17, minute: 0),
          ),
        ],
        WeekDay.wednesday: [
          const ServiceTimeSlot(
            start: TimeOfDay(hour: 8, minute: 0),
            end: TimeOfDay(hour: 17, minute: 0),
          ),
        ],
        WeekDay.friday: [
          const ServiceTimeSlot(
            start: TimeOfDay(hour: 8, minute: 0),
            end: TimeOfDay(hour: 17, minute: 0),
          ),
        ],
      },
      isActive: true,
      createdAt: DateTime(2025, 4, 7),
    ),

    // 12 ─ Home Maintenance (inactive)
    ServiceModel(
      id: 'svc-012',
      title: 'AC Service & Gas Refill',
      category: 'Home Maintenance',
      description:
          'Split and window AC servicing — coil cleaning, gas top-up, drainage flush, and electrical check.',
      pricingModel: PricingModel.fixed,
      priceType: PriceType.fixed,
      currency: 'NGN',
      amount: 20000,
      durationMinutes: 90,
      imagePath: 'assets/images/placeholders/artisan_04.png',
      weeklySchedule: {
        WeekDay.tuesday: [
          const ServiceTimeSlot(
            start: TimeOfDay(hour: 9, minute: 0),
            end: TimeOfDay(hour: 18, minute: 0),
          ),
        ],
        WeekDay.thursday: [
          const ServiceTimeSlot(
            start: TimeOfDay(hour: 9, minute: 0),
            end: TimeOfDay(hour: 18, minute: 0),
          ),
        ],
        WeekDay.saturday: [
          const ServiceTimeSlot(
            start: TimeOfDay(hour: 10, minute: 0),
            end: TimeOfDay(hour: 15, minute: 0),
          ),
        ],
      },
      isActive: false,
      createdAt: DateTime(2025, 4, 10),
    ),
  ];
}
