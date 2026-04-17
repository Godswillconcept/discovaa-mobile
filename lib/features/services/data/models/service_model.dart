import 'package:discovaa/core/constants/app_constants.dart';
import 'package:flutter/material.dart';

/// Days of the week used for weekly schedule
enum WeekDay {
  monday,
  tuesday,
  wednesday,
  thursday,
  friday,
  saturday,
  sunday;

  String get shortName {
    switch (this) {
      case WeekDay.monday:
        return 'Mon';
      case WeekDay.tuesday:
        return 'Tue';
      case WeekDay.wednesday:
        return 'Wed';
      case WeekDay.thursday:
        return 'Thu';
      case WeekDay.friday:
        return 'Fri';
      case WeekDay.saturday:
        return 'Sat';
      case WeekDay.sunday:
        return 'Sun';
    }
  }
}

/// A single time window (start → end) within a day
class ServiceTimeSlot {
  final TimeOfDay start;
  final TimeOfDay end;

  const ServiceTimeSlot({required this.start, required this.end});

  /// Returns true if start is strictly before end
  bool get isValid =>
      start.hour < end.hour ||
      (start.hour == end.hour && start.minute < end.minute);

  String get displayLabel => '${_fmt(start)} – ${_fmt(end)}';

  String _fmt(TimeOfDay t) {
    final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final m = t.minute.toString().padLeft(2, '0');
    final period = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$h:$m $period';
  }

  Map<String, dynamic> toJson() => {
    'startHour': start.hour,
    'startMinute': start.minute,
    'endHour': end.hour,
    'endMinute': end.minute,
  };

  factory ServiceTimeSlot.fromJson(Map<String, dynamic> json) =>
      ServiceTimeSlot(
        start: TimeOfDay(
          hour: json['startHour'] as int,
          minute: json['startMinute'] as int,
        ),
        end: TimeOfDay(
          hour: json['endHour'] as int,
          minute: json['endMinute'] as int,
        ),
      );

  @override
  bool operator ==(Object other) =>
      other is ServiceTimeSlot &&
      start.hour == other.start.hour &&
      start.minute == other.start.minute &&
      end.hour == other.end.hour &&
      end.minute == other.end.minute;

  @override
  int get hashCode =>
      Object.hash(start.hour, start.minute, end.hour, end.minute);
}

/// Pricing model for a service offering
enum PricingModel {
  fixed,
  hourly,
  package;

  String get displayName {
    switch (this) {
      case PricingModel.fixed:
        return 'Fixed';
      case PricingModel.hourly:
        return 'Hourly';
      case PricingModel.package:
        return 'Package';
    }
  }
}

/// Price type determines if the price is fixed or can vary
enum PriceType {
  fixed,
  variable;

  String get displayName {
    switch (this) {
      case PriceType.fixed:
        return 'Fixed';
      case PriceType.variable:
        return 'Variable';
    }
  }
}

/// Immutable service data model
class ServiceModel {
  final String id;
  final String title;
  final String? category;
  final String? categoryId;
  final String description;
  final PricingModel pricingModel;
  final PriceType priceType;
  final String currency;
  final double? amount;
  final double? priceMinAmount;
  final double? priceMaxAmount;
  final int? durationMinutes;
  final String providerId;

  /// Asset path or remote URL for the service cover image
  final String? imagePath;

  /// Media IDs from API
  final List<String> media;

  /// Weekly availability schedule: day → list of time slots
  final Map<WeekDay, List<ServiceTimeSlot>> weeklySchedule;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ServiceModel({
    required this.id,
    required this.title,
    this.category,
    this.categoryId,
    required this.description,
    required this.pricingModel,
    required this.priceType,
    required this.currency,
    this.amount,
    this.priceMinAmount,
    this.priceMaxAmount,
    this.durationMinutes,
    this.providerId = '',
    this.imagePath,
    this.media = const [],
    this.weeklySchedule = const {},
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  /// Formatted price display string
  String get formattedPrice {
    // For variable pricing, show range
    if (priceType == PriceType.variable) {
      if (priceMinAmount != null && priceMaxAmount != null) {
        final sym = currency.isNotEmpty ? '$currency ' : '';
        return '$sym${priceMinAmount!.toStringAsFixed(0)} - $sym${priceMaxAmount!.toStringAsFixed(0)}';
      }
      if (priceMinAmount != null) {
        final sym = currency.isNotEmpty ? '$currency ' : '';
        return 'From $sym${priceMinAmount!.toStringAsFixed(0)}';
      }
      if (priceMaxAmount != null) {
        final sym = currency.isNotEmpty ? '$currency ' : '';
        return 'Up to $sym${priceMaxAmount!.toStringAsFixed(0)}';
      }
    }

    // Fixed pricing
    if (amount == null || amount == 0) return 'Price on request';
    final sym = currency.isNotEmpty ? '$currency ' : '';
    final base = '$sym${amount!.toStringAsFixed(0)}';
    switch (pricingModel) {
      case PricingModel.hourly:
        return '$base/hr';
      case PricingModel.package:
        return '$base / pkg';
      case PricingModel.fixed:
        return base;
    }
  }

  ServiceModel copyWith({
    String? id,
    String? title,
    String? category,
    String? categoryId,
    String? description,
    PricingModel? pricingModel,
    PriceType? priceType,
    String? currency,
    double? amount,
    double? priceMinAmount,
    double? priceMaxAmount,
    int? durationMinutes,
    String? providerId,
    String? imagePath,
    List<String>? media,
    Map<WeekDay, List<ServiceTimeSlot>>? weeklySchedule,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ServiceModel(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      categoryId: categoryId ?? this.categoryId,
      description: description ?? this.description,
      pricingModel: pricingModel ?? this.pricingModel,
      priceType: priceType ?? this.priceType,
      currency: currency ?? this.currency,
      amount: amount ?? this.amount,
      priceMinAmount: priceMinAmount ?? this.priceMinAmount,
      priceMaxAmount: priceMaxAmount ?? this.priceMaxAmount,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      providerId: providerId ?? this.providerId,
      imagePath: imagePath ?? this.imagePath,
      media: media ?? this.media,
      weeklySchedule: weeklySchedule ?? this.weeklySchedule,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Convert to JSON-compatible map
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'category': category,
    'category_id': categoryId,
    'description': description,
    'pricing_model': pricingModel.name,
    'price_type': priceType.name,
    'currency': currency,
    'price_amount': amount,
    'price_min_amount': priceMinAmount,
    'price_max_amount': priceMaxAmount,
    'duration_minutes': durationMinutes,
    'provider': providerId,
    'media': media,
    'imagePath': imagePath,
    'weeklySchedule': weeklySchedule.map(
      (day, slots) => MapEntry(day.name, slots.map((s) => s.toJson()).toList()),
    ),
    'is_active': isActive,
    'created_at': createdAt?.toIso8601String(),
    'updated_at': updatedAt?.toIso8601String(),
  };

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    final rawSchedule = json['weeklySchedule'] as Map<String, dynamic>? ?? {};
    final weeklySchedule = <WeekDay, List<ServiceTimeSlot>>{};
    for (final entry in rawSchedule.entries) {
      final day = WeekDay.values.firstWhere(
        (d) => d.name == entry.key,
        orElse: () => WeekDay.monday,
      );
      final slots = (entry.value as List<dynamic>)
          .map((s) => ServiceTimeSlot.fromJson(s as Map<String, dynamic>))
          .toList();
      weeklySchedule[day] = slots;
    }

    // Parse media array
    final rawMedia = json['media'] as List<dynamic>? ?? [];
    final mediaList = rawMedia.map((m) => m.toString()).toList();

    final seed = json['id']?.toString() ?? 'service';

    // Handle pricing model (API uses snake_case)
    final pricingModelStr =
        json['pricing_model'] as String? ??
        json['pricingModel'] as String? ??
        'fixed';

    // Handle price type (API uses snake_case)
    final priceTypeStr =
        json['price_type'] as String? ??
        json['priceType'] as String? ??
        'fixed';

    // Parse category - API returns null or UUID, handle both
    final categoryVal = json['category'];
    String? categoryStr;
    if (categoryVal is String) {
      categoryStr = categoryVal;
    }

    return ServiceModel(
      id: json['id'] as String,
      title: json['title'] as String,
      category: categoryStr,
      categoryId: json['category_id'] as String? ?? json['category'] as String?,
      description: json['description'] as String? ?? '',
      pricingModel: PricingModel.values.firstWhere(
        (e) => e.name.toLowerCase() == pricingModelStr.toLowerCase(),
        orElse: () => PricingModel.fixed,
      ),
      priceType: PriceType.values.firstWhere(
        (e) => e.name.toLowerCase() == priceTypeStr.toLowerCase(),
        orElse: () => PriceType.fixed,
      ),
      currency: json['currency'] as String? ?? 'NGN',
      amount:
          (json['price_amount'] as num?)?.toDouble() ??
          (json['amount'] as num?)?.toDouble(),
      priceMinAmount: (json['price_min_amount'] as num?)?.toDouble(),
      priceMaxAmount: (json['price_max_amount'] as num?)?.toDouble(),
      durationMinutes:
          json['duration_minutes'] as int? ?? json['durationMinutes'] as int?,
      providerId: json['provider'] as String? ?? '',
      media: mediaList,
      imagePath: _resolveImagePath(
        json['imagePath']?.toString() ?? json['image_path']?.toString(),
        mediaList,
        seed,
      ),
      weeklySchedule: weeklySchedule,
      isActive: json['is_active'] as bool? ?? json['isActive'] as bool? ?? true,
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      updatedAt:
          DateTime.tryParse(json['updated_at'] as String? ?? '') ??
          DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  static String? _resolveImagePath(
    String? rawImagePath,
    List<String> media,
    String seed,
  ) {
    if (_isRenderableImagePath(rawImagePath)) {
      return rawImagePath;
    }

    for (final item in media) {
      if (_isRenderableImagePath(item)) {
        return item;
      }
    }

    return AppAssets.servicePlaceholder(seed);
  }

  static bool _isRenderableImagePath(String? value) {
    if (value == null || value.isEmpty) {
      return false;
    }
    return value.startsWith('http://') ||
        value.startsWith('https://') ||
        value.startsWith('assets/');
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is ServiceModel && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
