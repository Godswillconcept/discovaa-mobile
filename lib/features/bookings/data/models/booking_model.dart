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
  final PriceType? priceType;
  final int? durationMinutes;

  const BookedServiceSnapshot({
    required this.serviceId,
    required this.title,
    required this.category,
    this.imagePath,
    required this.formattedPrice,
    required this.pricingModel,
    this.priceType,
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
        priceType: s.priceType,
        durationMinutes: s.durationMinutes,
      );

  Map<String, dynamic> toJson() => {
    'serviceId': serviceId,
    'title': title,
    'category': category,
    'imagePath': imagePath,
    'formattedPrice': formattedPrice,
    'pricingModel': pricingModel.name,
    'priceType': priceType?.name,
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
        priceType: json['priceType'] != null
            ? PriceType.values.firstWhere(
                (e) => e.name == json['priceType'],
                orElse: () => PriceType.fixed,
              )
            : null,
        durationMinutes: json['durationMinutes'] as int?,
      );
}

/// Core booking entity. Immutable value object.
class BookingModel {
  final String id;

  /// Snapshot of the booked service (title, price, image, etc.)
  final BookedServiceSnapshot service;

  /// Client who placed the booking (user side)
  final String clientId; // NEW: User ID of the client
  final String clientName;
  final String? clientAvatarPath;
  final String? userDisplayName;
  final String? userProfilePhoto;

  /// Provider who will perform the service (provider side)
  final String providerId;
  final String? providerName;
  final String? providerAvatarPath;
  final String? providerEmail;
  final String? providerPhone;
  final String? providerBio;
  final String? providerCountry;
  final double? providerAvgRating;
  final int? providerReviewCount;
  final int? providerHiresCount;

  /// Scheduled date and start time
  final DateTime scheduledDate;
  final TimeOfDay scheduledTime;
  final DateTime? scheduledEnd;

  /// Current lifecycle status
  final BookingStatus status;

  /// Service type (ONSITE or WORKSHOP)
  final String? serviceType;

  /// Address for the booking
  final String? addressText;

  /// Optional note from the client
  final String? note;

  /// Timestamps
  final DateTime createdAt;
  final DateTime? updatedAt;

  /// Optional rating once completed (1–5)
  final int? rating;

  /// Optional review text
  final String? review;

  /// Concluded unit price set by provider for variable-price services
  final String? concludedUnitPrice;

  /// Payment information
  final String? paymentStatus;
  final String? paymentAmount;
  final String? paymentAuthorizationUrl;
  final String? paymentProviderReference;

  const BookingModel({
    required this.id,
    required this.service,
    required this.clientId, // NEW
    required this.clientName,
    this.clientAvatarPath,
    this.userDisplayName,
    this.userProfilePhoto,
    required this.providerId,
    this.providerName,
    this.providerAvatarPath,
    this.providerEmail,
    this.providerPhone,
    this.providerBio,
    this.providerCountry,
    this.providerAvgRating,
    this.providerReviewCount,
    this.providerHiresCount,
    required this.scheduledDate,
    required this.scheduledTime,
    this.scheduledEnd,
    required this.status,
    this.serviceType,
    this.addressText,
    this.note,
    required this.createdAt,
    this.updatedAt,
    this.rating,
    this.review,
    this.concludedUnitPrice,
    this.paymentStatus,
    this.paymentAmount,
    this.paymentAuthorizationUrl,
    this.paymentProviderReference,
  });

  BookingModel copyWith({
    String? id,
    BookedServiceSnapshot? service,
    String? clientId,
    String? clientName,
    String? clientAvatarPath,
    String? userDisplayName,
    String? userProfilePhoto,
    String? providerId,
    String? providerName,
    String? providerAvatarPath,
    String? providerEmail,
    String? providerPhone,
    String? providerBio,
    String? providerCountry,
    double? providerAvgRating,
    int? providerReviewCount,
    int? providerHiresCount,
    DateTime? scheduledDate,
    TimeOfDay? scheduledTime,
    DateTime? scheduledEnd,
    BookingStatus? status,
    String? serviceType,
    String? addressText,
    String? note,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? rating,
    String? review,
    String? concludedUnitPrice,
    String? paymentStatus,
    String? paymentAmount,
    String? paymentAuthorizationUrl,
    String? paymentProviderReference,
  }) {
    return BookingModel(
      id: id ?? this.id,
      service: service ?? this.service,
      clientId: clientId ?? this.clientId,
      clientName: clientName ?? this.clientName,
      clientAvatarPath: clientAvatarPath ?? this.clientAvatarPath,
      userDisplayName: userDisplayName ?? this.userDisplayName,
      userProfilePhoto: userProfilePhoto ?? this.userProfilePhoto,
      providerId: providerId ?? this.providerId,
      providerName: providerName ?? this.providerName,
      providerAvatarPath: providerAvatarPath ?? this.providerAvatarPath,
      providerEmail: providerEmail ?? this.providerEmail,
      providerPhone: providerPhone ?? this.providerPhone,
      providerBio: providerBio ?? this.providerBio,
      providerCountry: providerCountry ?? this.providerCountry,
      providerAvgRating: providerAvgRating ?? this.providerAvgRating,
      providerReviewCount: providerReviewCount ?? this.providerReviewCount,
      providerHiresCount: providerHiresCount ?? this.providerHiresCount,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      scheduledEnd: scheduledEnd ?? this.scheduledEnd,
      status: status ?? this.status,
      serviceType: serviceType ?? this.serviceType,
      addressText: addressText ?? this.addressText,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rating: rating ?? this.rating,
      review: review ?? this.review,
      concludedUnitPrice: concludedUnitPrice ?? this.concludedUnitPrice,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentAmount: paymentAmount ?? this.paymentAmount,
      paymentAuthorizationUrl:
          paymentAuthorizationUrl ?? this.paymentAuthorizationUrl,
      paymentProviderReference:
          paymentProviderReference ?? this.paymentProviderReference,
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
    'clientId': clientId,
    'clientName': clientName,
    'clientAvatarPath': clientAvatarPath,
    'userDisplayName': userDisplayName,
    'userProfilePhoto': userProfilePhoto,
    'providerId': providerId,
    'providerName': providerName,
    'providerAvatarPath': providerAvatarPath,
    'providerEmail': providerEmail,
    'providerPhone': providerPhone,
    'providerBio': providerBio,
    'providerCountry': providerCountry,
    'providerAvgRating': providerAvgRating,
    'providerReviewCount': providerReviewCount,
    'providerHiresCount': providerHiresCount,
    'scheduledDate': scheduledDate.toIso8601String(),
    'scheduledHour': scheduledTime.hour,
    'scheduledMinute': scheduledTime.minute,
    'scheduledEnd': scheduledEnd?.toIso8601String(),
    'status': status.name,
    'serviceType': serviceType,
    'addressText': addressText,
    'note': note,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt?.toIso8601String(),
    'rating': rating,
    'review': review,
    'concludedUnitPrice': concludedUnitPrice,
    'paymentStatus': paymentStatus,
    'paymentAmount': paymentAmount,
    'paymentAuthorizationUrl': paymentAuthorizationUrl,
    'paymentProviderReference': paymentProviderReference,
  };

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    try {
      return BookingModel(
        id: json['id']?.toString() ?? '',
        service: json['service'] is Map<String, dynamic>
            ? BookedServiceSnapshot.fromJson(
                json['service'] as Map<String, dynamic>,
              )
            : BookedServiceSnapshot(
                serviceId: json['id']?.toString() ?? '',
                title: 'Service',
                category: 'General',
                formattedPrice: '\$0.00',
                pricingModel: PricingModel.fixed,
              ),
        clientId: json['clientId']?.toString() ?? '',
        clientName: json['clientName']?.toString() ?? 'Client',
        clientAvatarPath: json['clientAvatarPath'] as String?,
        userDisplayName: json['userDisplayName'] as String?,
        userProfilePhoto: json['userProfilePhoto'] as String?,
        providerId: json['providerId']?.toString() ?? '',
        providerName: json['providerName'] as String?,
        providerAvatarPath: json['providerAvatarPath'] as String?,
        providerEmail: json['providerEmail'] as String?,
        providerPhone: json['providerPhone'] as String?,
        providerBio: json['providerBio'] as String?,
        providerCountry: json['providerCountry'] as String?,
        providerAvgRating: json['providerAvgRating'] as double?,
        providerReviewCount: json['providerReviewCount'] as int?,
        providerHiresCount: json['providerHiresCount'] as int?,
        scheduledDate: json['scheduledDate'] != null
            ? DateTime.parse(json['scheduledDate'] as String)
            : DateTime.now(),
        scheduledTime: TimeOfDay(
          hour: json['scheduledHour'] as int? ?? 0,
          minute: json['scheduledMinute'] as int? ?? 0,
        ),
        scheduledEnd: json['scheduledEnd'] != null
            ? DateTime.parse(json['scheduledEnd'] as String)
            : null,
        status: BookingStatus.values.firstWhere(
          (e) => e.name == json['status']?.toString().toLowerCase(),
          orElse: () => BookingStatus.requested,
        ),
        serviceType: json['serviceType'] as String?,
        addressText: json['addressText'] as String?,
        note: json['note'] as String?,
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'] as String)
            : DateTime.now(),
        updatedAt: json['updatedAt'] != null
            ? DateTime.parse(json['updatedAt'] as String)
            : null,
        rating: json['rating'] as int?,
        review: json['review'] as String?,
        concludedUnitPrice: json['concludedUnitPrice'] as String?,
        paymentStatus: json['paymentStatus'] as String?,
        paymentAmount: json['paymentAmount'] as String?,
        paymentAuthorizationUrl: json['paymentAuthorizationUrl'] as String?,
        paymentProviderReference: json['paymentProviderReference'] as String?,
      );
    } catch (_) {
      // Return a minimal valid booking if parsing fails
      return BookingModel(
        id: json['id']?.toString() ?? '',
        service: BookedServiceSnapshot(
          serviceId: json['id']?.toString() ?? '',
          title: 'Service',
          category: 'General',
          formattedPrice: '\$0.00',
          pricingModel: PricingModel.fixed,
          priceType: PriceType.fixed,
        ),
        clientId: json['clientId']?.toString() ?? '',
        clientName: 'Client',
        providerId: json['providerId']?.toString() ?? '',
        scheduledDate: DateTime.now(),
        scheduledTime: const TimeOfDay(hour: 0, minute: 0),
        status: BookingStatus.requested,
        createdAt: DateTime.now(),
      );
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is BookingModel && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
