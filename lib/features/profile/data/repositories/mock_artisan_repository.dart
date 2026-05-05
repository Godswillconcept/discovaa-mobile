import '../../domain/entities/artisan_entity.dart';
import '../../domain/repositories/artisan_repository.dart';

class MockArtisanRepository implements ArtisanRepository {
  final List<Artisan> _artisans = [
    Artisan(
      id: '1',
      name: 'Jason Doe',
      category: 'Car Maintenance',
      rating: 4.5,
      reviewsCount: 10,
      location: 'Tartu, 50050',
      profileImage: 'assets/images/placeholders/artisan_01.png',
      bio:
          'Skilled Mechanic - Approachable, Committed, Honesty, and Reliability. Providing Quality Service...',
      services: [
        'Oil Change',
        'Brake Repair',
        'Engine Diagnostics',
        'Tire Rotation',
      ],
      hourlyRate: 35.0,
      priceRange: '€30 - €500',
      certifications: ['Certified Master Tech', 'ASE Certified'],
      availability: {
        'Weekdays': '08:00 - 17:30',
        'Saturdays': '12:00 - 17:30',
        'Sundays': 'Closed',
      },
      galleryImages: [
        'assets/images/placeholders/artisan_01.png',
        'assets/images/placeholders/artisan_02.png',
        'assets/images/placeholders/artisan_03.png',
      ],
      reviews: [
        Review(
          userName: 'Tõnis Toomas',
          userAvatar: 'assets/images/placeholders/user_avatar.png',
          rating: 5.0,
          date: 'January 2024',
          comment:
              'Friendly service and top-notch workmanship. Jason Doe exceeded my expectations. Very professional.',
        ),
        Review(
          userName: 'Mari Tamm',
          userAvatar: 'assets/images/placeholders/user_avatar.png',
          rating: 4.0,
          date: 'December 2023',
          comment:
              'Jason Doe is my go-to for any car maintenance needs – reliable and professional! Friendly service and top-notch workmanship.',
        ),
      ],
      lastSeen: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    Artisan(
      id: '2',
      name: 'Plum Plumbing Services',
      category: 'Plumbing and Pipes',
      rating: 5.0,
      reviewsCount: 10,
      location: 'Narva, 20303',
      profileImage: 'assets/images/placeholders/artisan_02.png',
      bio:
          'Professional plumbing services for your home and business. We handle everything from leaks to full installations.',
      services: ['Plumbing', 'Water heater', 'Pipes', 'Handyman'],
      hourlyRate: 40.0,
      priceRange: '€40 - €10,000',
      certifications: ['Qualified Plumber', 'Certified Plumber'],
      availability: {
        'Weekdays': '08:00 - 17:30',
        'Saturdays': '12:00 - 17:30',
        'Sundays': 'Closed',
      },
      galleryImages: [
        'assets/images/placeholders/artisan_04.png',
        'assets/images/placeholders/artisan_05.png',
        'assets/images/placeholders/artisan_06.png',
      ],
      reviews: [
        Review(
          userName: 'Kalle Kask',
          userAvatar: 'assets/images/placeholders/user_avatar.png',
          rating: 5.0,
          date: 'February 2024',
          comment:
              'Plum Plumbing Services is my go-to for any plumbing needs – reliable and professional!',
        ),
      ],
      hiresCount: 10,
      yearsInBusiness: 4,
    ),
    Artisan(
      id: '10',
      name: 'Kristjan Tõnis',
      category: 'Electrical Maintenance',
      rating: 4.8,
      reviewsCount: 15,
      location: 'Tallinn, 10111',
      profileImage: 'assets/images/placeholders/user_avatar.png',
      bio: 'Expert electrician.',
      services: ['Wiring'],
      hourlyRate: 40,
      priceRange: '€40 - €100',
      certifications: [],
      availability: {},
      galleryImages: [],
      reviews: [],
    ),
    // ... adding more for discovery feel
    Artisan(
      id: '4',
      name: 'Sarah Miller',
      category: 'Hair Saloon',
      rating: 4.8,
      reviewsCount: 25,
      location: 'Tallinn, 10111',
      profileImage: 'assets/images/placeholders/artisan_01.png',
      bio: 'Professional hair stylist with 10 years of experience.',
      services: ['Haircut', 'Hair Coloring', 'Styling'],
      hourlyRate: 50.0,
      priceRange: '€20 - €150',
      certifications: ['Licensed Cosmetologist'],
      availability: {'Weekdays': '09:00 - 18:00'},
      galleryImages: [],
      reviews: [],
      hiresCount: 45,
      yearsInBusiness: 10,
      lastSeen: DateTime.now().subtract(const Duration(hours: 5)),
    ),
  ];

  @override
  Future<List<Artisan>> getArtisans() async {
    await Future.delayed(
      const Duration(milliseconds: 800),
    ); // Mimic API latency
    return _artisans;
  }

  @override
  List<Artisan> getCachedArtisans({
    String? search,
    String? category,
    String? ordering,
    double? minRating,
    double? minPrice,
    double? maxPrice,
    String? location,
    bool? isAvailableOnly,
    String? providerType,
    bool? isVerifiedOnly,
    double? radiusKm,
  }) {
    // Basic in-memory filtering for cache
    return _artisans;
  }

  @override
  Future<List<Artisan>> searchArtisans({
    String? search,
    String? category,
    String? ordering,
    double? minRating,
    double? minPrice,
    double? maxPrice,
    String? location,
    bool? isAvailableOnly,
    String? providerType,
    bool? isVerifiedOnly,
    double? radiusKm,
  }) async {
    // Basic in-memory filtering to mimic backend search
    await Future.delayed(const Duration(milliseconds: 300));
    Iterable<Artisan> results = _artisans;

    if (category != null && category.trim().isNotEmpty) {
      final catLower = category.toLowerCase();
      results = results.where((a) => a.category.toLowerCase() == catLower);
    }

    if (search != null && search.trim().isNotEmpty) {
      final q = search.toLowerCase();
      results = results.where(
        (a) =>
            a.name.toLowerCase().contains(q) ||
            a.category.toLowerCase().contains(q) ||
            a.bio.toLowerCase().contains(q),
      );
    }

    if (minRating != null && minRating > 0) {
      results = results.where((a) => a.rating >= minRating);
    }

    if (minPrice != null && minPrice > 0) {
      results = results.where((a) => a.hourlyRate >= minPrice);
    }

    if (maxPrice != null && maxPrice > 0) {
      results = results.where((a) => a.hourlyRate <= maxPrice);
    }

    if (location != null && location.trim().isNotEmpty) {
      final locLower = location.toLowerCase();
      results = results.where(
        (a) => a.location.toLowerCase().contains(locLower),
      );
    }

    if (isAvailableOnly == true) {
      // For mock, just filter by having some availability data
      results = results.where((a) => a.availability.isNotEmpty);
    }

    final list = results.toList();
    switch (ordering) {
      case '-avg_rating':
        list.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case '-hires_count':
        list.sort((a, b) => b.hiresCount.compareTo(a.hiresCount));
        break;
      default:
        break;
    }

    return list;
  }
}
