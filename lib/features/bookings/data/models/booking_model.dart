import 'package:discovaa/features/services/data/models/service_model.dart';
import 'package:flutter/material.dart';

/// Lifecycle status of a booking
enum BookingStatus {
  requested,
  confirmed,
  cancelled,
  completed,
  ongoing; // Kept for internal UI state if needed, but primary tabs use the 4 above.

  String get displayName {
    switch (this) {
      case BookingStatus.requested:
        return 'Requested';
      case BookingStatus.confirmed:
        return 'Confirmed';
      case BookingStatus.cancelled:
        return 'Cancelled';
      case BookingStatus.completed:
        return 'Completed';
      case BookingStatus.ongoing:
        return 'Ongoing';
    }
  }

  Color get color {
    switch (this) {
      case BookingStatus.requested:
        return const Color(0xFFF59E0B); // amber
      case BookingStatus.confirmed:
        return const Color(0xFF3B82F6); // blue
      case BookingStatus.cancelled:
        return const Color(0xFFE2211D); // red
      case BookingStatus.completed:
        return const Color(0xFF10B981); // green
      case BookingStatus.ongoing:
        return const Color(0xFF8B5CF6); // purple
    }
  }

  bool get isActive =>
      this == BookingStatus.requested ||
      this == BookingStatus.confirmed ||
      this == BookingStatus.ongoing;
}

/// Snapshot of the service details captured at booking time.
/// Stored inside [BookingModel] so bookings remain accurate even if
/// the live [ServiceModel] is later edited or deleted.
class BookedServiceSnapshot {
  final String serviceId;
  final String title;
  final String category;
  final String? imagePath;
  final String formattedPrice;
  final PricingModel pricingModel;
  final int? durationMinutes;

  const BookedServiceSnapshot({
    required this.serviceId,
    required this.title,
    required this.category,
    this.imagePath,
    required this.formattedPrice,
    required this.pricingModel,
    this.durationMinutes,
  });

  factory BookedServiceSnapshot.fromService(ServiceModel s) =>
      BookedServiceSnapshot(
        serviceId: s.id,
        title: s.title,
        category: s.category ?? 'Service',
        imagePath: s.imagePath,
        formattedPrice: s.formattedPrice,
        pricingModel: s.pricingModel,
        durationMinutes: s.durationMinutes,
      );

  Map<String, dynamic> toJson() => {
    'serviceId': serviceId,
    'title': title,
    'category': category,
    'imagePath': imagePath,
    'formattedPrice': formattedPrice,
    'pricingModel': pricingModel.name,
    'durationMinutes': durationMinutes,
  };

  factory BookedServiceSnapshot.fromJson(Map<String, dynamic> json) =>
      BookedServiceSnapshot(
        serviceId: json['serviceId'] as String,
        title: json['title'] as String,
        category: json['category'] as String,
        imagePath: json['imagePath'] as String?,
        formattedPrice: json['formattedPrice'] as String,
        pricingModel: PricingModel.values.firstWhere(
          (e) => e.name == json['pricingModel'],
          orElse: () => PricingModel.fixed,
        ),
        durationMinutes: json['durationMinutes'] as int?,
      );
}

/// Core booking entity. Immutable value object.
class BookingModel {
  final String id;

  /// Snapshot of the booked service (title, price, image, etc.)
  final BookedServiceSnapshot service;

  /// Client who placed the booking (user side)
  final String clientName;
  final String? clientAvatarPath;

  /// Scheduled date and start time
  final DateTime scheduledDate;
  final TimeOfDay scheduledTime;

  /// Current lifecycle status
  final BookingStatus status;

  /// Optional note from the client
  final String? note;

  /// Timestamps
  final DateTime createdAt;
  final DateTime? updatedAt;

  /// Optional rating once completed (1–5)
  final int? rating;

  /// Optional review text
  final String? review;

  const BookingModel({
    required this.id,
    required this.service,
    required this.clientName,
    this.clientAvatarPath,
    required this.scheduledDate,
    required this.scheduledTime,
    required this.status,
    this.note,
    required this.createdAt,
    this.updatedAt,
    this.rating,
    this.review,
  });

  BookingModel copyWith({
    String? id,
    BookedServiceSnapshot? service,
    String? clientName,
    String? clientAvatarPath,
    DateTime? scheduledDate,
    TimeOfDay? scheduledTime,
    BookingStatus? status,
    String? note,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? rating,
    String? review,
  }) {
    return BookingModel(
      id: id ?? this.id,
      service: service ?? this.service,
      clientName: clientName ?? this.clientName,
      clientAvatarPath: clientAvatarPath ?? this.clientAvatarPath,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      status: status ?? this.status,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rating: rating ?? this.rating,
      review: review ?? this.review,
    );
  }

  /// Human-readable scheduled date + time string
  String get scheduledDisplayDate {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[scheduledDate.month - 1]} ${scheduledDate.day}, ${scheduledDate.year}';
  }

  String get scheduledDisplayTime {
    final h = scheduledTime.hourOfPeriod == 0 ? 12 : scheduledTime.hourOfPeriod;
    final m = scheduledTime.minute.toString().padLeft(2, '0');
    final p = scheduledTime.period == DayPeriod.am ? 'AM' : 'PM';
    return '$h:$m $p';
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'service': service.toJson(),
    'clientName': clientName,
    'clientAvatarPath': clientAvatarPath,
    'scheduledDate': scheduledDate.toIso8601String(),
    'scheduledHour': scheduledTime.hour,
    'scheduledMinute': scheduledTime.minute,
    'status': status.name,
    'note': note,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt?.toIso8601String(),
    'rating': rating,
    'review': review,
  };

  factory BookingModel.fromJson(Map<String, dynamic> json) => BookingModel(
    id: json['id'] as String,
    service: BookedServiceSnapshot.fromJson(
      json['service'] as Map<String, dynamic>,
    ),
    clientName: json['clientName'] as String,
    clientAvatarPath: json['clientAvatarPath'] as String?,
    scheduledDate: DateTime.parse(json['scheduledDate'] as String),
    scheduledTime: TimeOfDay(
      hour: json['scheduledHour'] as int,
      minute: json['scheduledMinute'] as int,
    ),
    status: BookingStatus.values.firstWhere(
      (e) => e.name == json['status'].toString().toLowerCase(),
      orElse: () => BookingStatus.requested,
    ),
    note: json['note'] as String?,
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: json['updatedAt'] != null
        ? DateTime.parse(json['updatedAt'] as String)
        : null,
    rating: json['rating'] as int?,
    review: json['review'] as String?,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is BookingModel && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
