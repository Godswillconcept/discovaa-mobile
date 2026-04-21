class ArtisanCategory {
  final String name;
  final String image;

  ArtisanCategory({required this.name, required this.image});
}

class Review {
  final String userName;
  final String userAvatar;
  final double rating;
  final String date;
  final String comment;

  Review({
    required this.userName,
    required this.userAvatar,
    required this.rating,
    required this.date,
    required this.comment,
  });
}

class Artisan {
  final String id;
  final String name;
  final String category;
  final double rating;
  final int reviewsCount;
  final String location;
  final String profileImage;
  final String bio;
  final List<String> services;
  final double hourlyRate;
  final String priceRange;
  final List<String> certifications;
  final Map<String, String> availability;
  final bool isVerified;
  final List<String> galleryImages;
  final List<Review> reviews;
  final int hiresCount;
  final int yearsInBusiness;
  final DateTime? lastSeen;
  final String? registrationNumber;
  final String? address;

  Artisan({
    required this.id,
    required this.name,
    required this.category,
    required this.rating,
    required this.reviewsCount,
    required this.location,
    required this.profileImage,
    required this.bio,
    required this.services,
    required this.hourlyRate,
    required this.priceRange,
    required this.certifications,
    required this.availability,
    this.isVerified = true,
    required this.galleryImages,
    required this.reviews,
    this.hiresCount = 0,
    this.yearsInBusiness = 0,
    this.lastSeen,
    this.registrationNumber,
    this.address,
  });
}
