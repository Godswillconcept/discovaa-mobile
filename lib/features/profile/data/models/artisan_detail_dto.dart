import 'dart:convert';

/// DTO for detailed provider data from /api/providers/{id}/
class ProviderDetailDto {
  final String id;
  final String displayName;
  final String? bio;
  final bool isVerified;
  final String? profilePhoto;
  final double avgRating;
  final int reviewCount;
  final int hiresCount;
  final List<String> serviceCategories;
  final List<ProviderLocationDto> locations;
  final List<ProviderCertificationDto> certifications;
  final List<ProviderAvailabilityRuleDto> availabilityRules;
  final List<dynamic> media;
  final String? registrationNumber;

  const ProviderDetailDto({
    required this.id,
    required this.displayName,
    this.bio,
    required this.isVerified,
    this.profilePhoto,
    required this.avgRating,
    required this.reviewCount,
    required this.hiresCount,
    required this.serviceCategories,
    required this.locations,
    required this.certifications,
    required this.availabilityRules,
    required this.media,
    this.registrationNumber,
  });

  factory ProviderDetailDto.fromJson(Map<String, dynamic> json) {
    final locationsRaw = json['locations'] as List<dynamic>? ?? const [];
    final certificationsRaw =
        json['certifications'] as List<dynamic>? ?? const [];
    final availabilityRulesRaw =
        json['availability_rules'] as List<dynamic>? ?? const [];
    final mediaRaw = json['media'] as List<dynamic>? ?? const [];

    return ProviderDetailDto(
      id: json['id']?.toString() ?? '',
      displayName: json['display_name']?.toString() ?? '',
      bio: json['bio']?.toString(),
      isVerified: json['is_verified'] == true,
      profilePhoto: json['profile_photo']?.toString(),
      avgRating: _asDouble(json['avg_rating']),
      reviewCount: _asInt(json['review_count']),
      hiresCount: _asInt(json['hires_count']),
      serviceCategories: _parseServiceCategories(json['service_categories']),
      locations: locationsRaw
          .whereType<Map<String, dynamic>>()
          .map(ProviderLocationDto.fromJson)
          .toList(),
      certifications: certificationsRaw
          .whereType<Map<String, dynamic>>()
          .map(ProviderCertificationDto.fromJson)
          .toList(),
      availabilityRules: availabilityRulesRaw
          .whereType<Map<String, dynamic>>()
          .map(ProviderAvailabilityRuleDto.fromJson)
          .toList(),
      media: mediaRaw,
      registrationNumber: json['registration_number']?.toString(),
    );
  }

  /// Parse gallery media URLs from the media field
  /// Media is returned as an array of objects with 'url' fields
  List<String> get galleryUrls {
    if (media.isEmpty) return const [];
    try {
      return media
          .whereType<Map<String, dynamic>>()
          .map((m) => m['url']?.toString())
          .where((url) => url != null && url.isNotEmpty)
          .cast<String>()
          .toList();
    } catch (_) {}
    return const [];
  }
}

class ProviderLocationDto {
  final String id;
  final String name;
  final String? address;
  final String? city;
  final String? state;
  final String? country;

  const ProviderLocationDto({
    required this.id,
    required this.name,
    this.address,
    this.city,
    this.state,
    this.country,
  });

  factory ProviderLocationDto.fromJson(Map<String, dynamic> json) {
    return ProviderLocationDto(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      address: json['address']?.toString(),
      city: json['city']?.toString(),
      state: json['state']?.toString(),
      country: json['country']?.toString(),
    );
  }

  String get displayLocation {
    final parts = <String>[];
    if ((city ?? '').trim().isNotEmpty) parts.add(city!.trim());
    if ((state ?? '').trim().isNotEmpty) parts.add(state!.trim());
    if (parts.isNotEmpty) return parts.join(', ');
    if ((address ?? '').trim().isNotEmpty) return address!.trim();
    return name;
  }
}

class ProviderCertificationDto {
  final String id;
  final String title;
  final String? issuer;
  final String? document;

  const ProviderCertificationDto({
    required this.id,
    required this.title,
    this.issuer,
    this.document,
  });

  factory ProviderCertificationDto.fromJson(Map<String, dynamic> json) {
    return ProviderCertificationDto(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      issuer: json['issuer']?.toString(),
      document: json['document']?.toString(),
    );
  }

  String get displayTitle =>
      issuer != null && issuer!.isNotEmpty ? '$title (${issuer!})' : title;
}

class ProviderAvailabilityRuleDto {
  final String id;
  final int weekday;
  final String? startTime;
  final String? endTime;
  final bool isClosed;

  const ProviderAvailabilityRuleDto({
    required this.id,
    required this.weekday,
    this.startTime,
    this.endTime,
    this.isClosed = false,
  });

  factory ProviderAvailabilityRuleDto.fromJson(Map<String, dynamic> json) {
    return ProviderAvailabilityRuleDto(
      id: json['id']?.toString() ?? '',
      weekday: _asInt(json['weekday']),
      startTime: json['start_time']?.toString(),
      endTime: json['end_time']?.toString(),
      isClosed: json['is_closed'] == true,
    );
  }

  static const _weekdayNames = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  String get weekdayName => _weekdayNames[weekday.clamp(0, 6)];

  String get displayTimeRange {
    if (isClosed) return 'Closed';
    if (startTime != null && endTime != null) {
      return '${_formatTime(startTime!)} - ${_formatTime(endTime!)}';
    }
    return 'Available';
  }

  String _formatTime(String time) {
    // Convert "09:00:00" to "9:00AM"
    final parts = time.split(':');
    if (parts.length >= 2) {
      final hour = int.tryParse(parts[0]) ?? 0;
      final minute = parts[1];
      final period = hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      return '$displayHour:$minute$period';
    }
    return time;
  }
}

/// DTO for Service data from /api/services/
class ServiceDto {
  final String id;
  final String title;
  final String? description;
  final String pricingModel;
  final String? priceType;
  final double? priceAmount;
  final double? priceMinAmount;
  final double? priceMaxAmount;
  final String currency;
  final int? durationMinutes;
  final List<String> media;

  const ServiceDto({
    required this.id,
    required this.title,
    this.description,
    required this.pricingModel,
    this.priceType,
    this.priceAmount,
    this.priceMinAmount,
    this.priceMaxAmount,
    required this.currency,
    this.durationMinutes,
    required this.media,
  });

  factory ServiceDto.fromJson(Map<String, dynamic> json) {
    return ServiceDto(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString(),
      pricingModel: json['pricing_model']?.toString() ?? 'FIXED',
      priceType: json['price_type']?.toString(),
      priceAmount: _asDouble(json['price_amount']),
      priceMinAmount: _asDouble(json['price_min_amount']),
      priceMaxAmount: _asDouble(json['price_max_amount']),
      currency: json['currency']?.toString() ?? 'NGN',
      durationMinutes: _asInt(json['duration_minutes']),
      media: _mapList(json['media'], (item) => item.toString()),
    );
  }

  bool get isHourly => pricingModel.toUpperCase() == 'HOURLY';

  bool get hasVariablePrice => priceType?.toUpperCase() == 'VARIABLE';

  String get displayPrice {
    if (isHourly && priceAmount != null) {
      return '${_formatCurrency(priceAmount!)}/hour';
    }
    if (hasVariablePrice && priceMinAmount != null && priceMaxAmount != null) {
      return '${_formatCurrency(priceMinAmount!)} - ${_formatCurrency(priceMaxAmount!)}';
    }
    if (priceAmount != null) {
      return _formatCurrency(priceAmount!);
    }
    return 'Contact for pricing';
  }

  String _formatCurrency(double amount) {
    final symbol = currency == 'NGN'
        ? '₦'
        : currency == 'EUR'
        ? '€'
        : '\$';
    return '$symbol${amount.toStringAsFixed(0)}';
  }
}

/// DTO for Review data from /api/reviews/
class ReviewDto {
  final String id;
  final String? authorName;
  final String? authorAvatar;
  final double rating;
  final String? comment;
  final DateTime createdAt;

  const ReviewDto({
    required this.id,
    this.authorName,
    this.authorAvatar,
    required this.rating,
    this.comment,
    required this.createdAt,
  });

  factory ReviewDto.fromJson(Map<String, dynamic> json) {
    return ReviewDto(
      id: json['id']?.toString() ?? '',
      authorName:
          json['author_display_name']?.toString() ??
          json['author_user']?.toString() ??
          'Anonymous',
      authorAvatar: json['author_avatar']?.toString(),
      rating: _asDouble(json['rating']),
      comment: json['comment']?.toString(),
      createdAt: _parseDateTime(json['created_at']) ?? DateTime.now(),
    );
  }

  String get displayDate {
    final now = DateTime.now();
    final diff = now.difference(createdAt);
    if (diff.inDays < 1) return 'Today';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()} weeks ago';
    if (diff.inDays < 365) return '${(diff.inDays / 30).floor()} months ago';
    return '${(diff.inDays / 365).floor()} years ago';
  }
}

// Helper functions

List<T> _mapList<T>(dynamic source, T Function(dynamic) mapper) {
  if (source is! List) return const [];
  return source.map(mapper).toList();
}

double _asDouble(dynamic value) {
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0.0;
}

int _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

DateTime? _parseDateTime(dynamic value) {
  final raw = value?.toString();
  if (raw == null || raw.isEmpty) return null;
  return DateTime.tryParse(raw);
}

List<String> _parseServiceCategories(dynamic raw) {
  if (raw is List) {
    return raw
        .map((e) {
          if (e is Map<String, dynamic>) {
            return e['name']?.toString() ?? '';
          }
          return e.toString();
        })
        .where((s) => s.isNotEmpty)
        .toList();
  } else if (raw is String) {
    final trimmed = raw.trim();
    if (trimmed.startsWith('[') && trimmed.endsWith(']')) {
      try {
        final parsed = jsonDecode(trimmed);
        if (parsed is List) {
          return parsed
              .map(
                (e) => e is Map<String, dynamic>
                    ? e['name']?.toString() ?? ''
                    : e.toString(),
              )
              .where((s) => s.isNotEmpty)
              .toList();
        }
      } catch (_) {}
    }
    if (trimmed.contains(',')) {
      return trimmed
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    return trimmed.isEmpty ? const [] : [trimmed];
  }
  return const [];
}
