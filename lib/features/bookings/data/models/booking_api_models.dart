import 'package:discovaa/features/bookings/data/models/booking_model.dart';
import 'package:discovaa/features/services/data/models/service_model.dart';
import 'package:flutter/material.dart';

class BookingItemDto {
  final String id;
  final String serviceId;
  final int quantity;
  final String? unitPriceAmount;
  final String? currency;

  const BookingItemDto({
    required this.id,
    required this.serviceId,
    required this.quantity,
    this.unitPriceAmount,
    this.currency,
  });

  factory BookingItemDto.fromJson(Map<String, dynamic> json) {
    return BookingItemDto(
      id: json['id']?.toString() ?? '',
      serviceId: json['service']?.toString() ?? '',
      quantity: json['quantity'] as int? ?? 1,
      unitPriceAmount: json['unit_price_amount']?.toString(),
      currency: json['currency']?.toString(),
    );
  }
}

class BookingDto {
  final String id;
  final String providerId;
  final String status;
  final DateTime scheduledStart;
  final DateTime? scheduledEnd;
  final String? currency;
  final String? totalAmount;
  final String? notes;
  final List<BookingItemDto> items;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const BookingDto({
    required this.id,
    required this.providerId,
    required this.status,
    required this.scheduledStart,
    this.scheduledEnd,
    this.currency,
    this.totalAmount,
    this.notes,
    required this.items,
    required this.createdAt,
    this.updatedAt,
  });

  factory BookingDto.fromJson(Map<String, dynamic> json) {
    return BookingDto(
      id: json['id']?.toString() ?? '',
      providerId: json['provider']?.toString() ?? '',
      status: json['status']?.toString() ?? 'REQUESTED',
      scheduledStart:
          DateTime.tryParse(json['scheduled_start']?.toString() ?? '') ??
          DateTime.now(),
      scheduledEnd: DateTime.tryParse(json['scheduled_end']?.toString() ?? ''),
      currency: json['currency']?.toString(),
      totalAmount: json['total_amount']?.toString(),
      notes: json['notes']?.toString(),
      items: (json['items'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(BookingItemDto.fromJson)
          .toList(growable: false),
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? ''),
    );
  }
}

class BookingWriteDto {
  final String providerId;
  final DateTime scheduledStart;
  final DateTime? scheduledEnd;
  final String serviceType;
  final String? currency;
  final String? notes;
  final List<Map<String, dynamic>> items;

  const BookingWriteDto({
    required this.providerId,
    required this.scheduledStart,
    this.scheduledEnd,
    this.serviceType = 'ONSITE',
    this.currency,
    this.notes,
    this.items = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'provider': providerId,
      'scheduled_start': scheduledStart.toIso8601String(),
      if (scheduledEnd != null)
        'scheduled_end': scheduledEnd!.toIso8601String(),
      'service_type': serviceType,
      if (currency != null) 'currency': currency,
      if (notes != null && notes!.isNotEmpty) 'notes': notes,
      if (items.isNotEmpty) 'items': items,
    };
  }
}

BookingModel mapBookingDto(
  BookingDto dto,
  Map<String, ServiceModel> serviceMap,
) {
  final bookedService = dto.items.isNotEmpty
      ? serviceMap[dto.items.first.serviceId]
      : null;
  final snapshot = bookedService != null
      ? BookedServiceSnapshot.fromService(bookedService)
      : BookedServiceSnapshot(
          serviceId: dto.items.isNotEmpty ? dto.items.first.serviceId : dto.id,
          title: 'Booked Service',
          category: 'General',
          formattedPrice: _formatAmount(dto.totalAmount, dto.currency),
          pricingModel: PricingModel.fixed,
          durationMinutes: dto.scheduledEnd
              ?.difference(dto.scheduledStart)
              .inMinutes,
        );

  return BookingModel(
    id: dto.id,
    service: snapshot,
    clientName: 'Client',
    scheduledDate: dto.scheduledStart,
    scheduledTime: TimeOfDay.fromDateTime(dto.scheduledStart),
    status: _bookingStatus(dto.status),
    note: dto.notes,
    createdAt: dto.createdAt,
    updatedAt: dto.updatedAt,
  );
}

String _formatAmount(String? amount, String? currency) {
  final parsed = double.tryParse(amount ?? '');
  if (parsed == null) return 'Price on request';
  return '${currency ?? 'NGN'} ${parsed.toStringAsFixed(0)}';
}

BookingStatus _bookingStatus(String raw) {
  switch (raw.toUpperCase()) {
    case 'CONFIRMED':
      return BookingStatus.confirmed;
    case 'COMPLETED':
      return BookingStatus.completed;
    case 'CANCELLED':
      return BookingStatus.cancelled;
    default:
      return BookingStatus.requested;
  }
}
