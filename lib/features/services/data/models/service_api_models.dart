import 'package:dio/dio.dart';
import 'package:discovaa/core/constants/app_constants.dart';
import 'package:discovaa/features/services/data/models/service_model.dart';

class ServiceCategoryDto {
  final String id;
  final String name;
  final String? picture;

  const ServiceCategoryDto({
    required this.id,
    required this.name,
    this.picture,
  });

  factory ServiceCategoryDto.fromJson(Map<String, dynamic> json) {
    return ServiceCategoryDto(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      picture: json['picture']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'picture': picture};
  }
}

class ServiceDto {
  final String id;
  final String? providerId;
  final String? categoryId;
  final String title;
  final String description;
  final String? pricingModel;
  final String? priceType;
  final String? priceAmount;
  final String? priceMinAmount;
  final String? priceMaxAmount;
  final String currency;
  final int? durationMinutes;
  final bool isActive;
  final List<String> media;
  final String? imagePath;
  final DateTime createdAt;

  const ServiceDto({
    required this.id,
    this.providerId,
    this.categoryId,
    required this.title,
    required this.description,
    this.pricingModel,
    this.priceType,
    this.priceAmount,
    this.priceMinAmount,
    this.priceMaxAmount,
    required this.currency,
    this.durationMinutes,
    required this.isActive,
    required this.media,
    this.imagePath,
    required this.createdAt,
  });

  factory ServiceDto.fromJson(Map<String, dynamic> json) {
    return ServiceDto(
      id: json['id']?.toString() ?? '',
      providerId: json['provider']?.toString(),
      categoryId: json['category']?.toString(),
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      pricingModel: json['pricing_model']?.toString(),
      priceType: json['price_type']?.toString(),
      priceAmount: json['price_amount']?.toString(),
      priceMinAmount: json['price_min_amount']?.toString(),
      priceMaxAmount: json['price_max_amount']?.toString(),
      currency: json['currency']?.toString() ?? 'NGN',
      durationMinutes: json['duration_minutes'] as int?,
      isActive: json['is_active'] != false,
      media: (json['media'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .toList(growable: false),
      imagePath: _extractImagePath(json),
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}

String? _extractImagePath(Map<String, dynamic> json) {
  final candidates = <String?>[
    json['imagePath']?.toString(),
    json['image_path']?.toString(),
    json['image_url']?.toString(),
    json['cover_image']?.toString(),
    json['cover_image_url']?.toString(),
  ];

  for (final candidate in candidates) {
    if (_isRenderableImagePath(candidate)) {
      return candidate;
    }
  }
  return null;
}

bool _isRenderableImagePath(String? value) {
  if (value == null || value.isEmpty) {
    return false;
  }
  return value.startsWith('http://') ||
      value.startsWith('https://') ||
      value.startsWith('assets/');
}

class ServiceWriteDto {
  final String? categoryId;
  final String title;
  final String description;
  final String pricingModel;
  final String priceType;
  final double? amount;
  final double? minAmount;
  final double? maxAmount;
  final String currency;
  final int? durationMinutes;
  final bool isActive;

  const ServiceWriteDto({
    this.categoryId,
    required this.title,
    required this.description,
    required this.pricingModel,
    required this.priceType,
    this.amount,
    this.minAmount,
    this.maxAmount,
    required this.currency,
    this.durationMinutes,
    required this.isActive,
  });

  Map<String, dynamic> toJson() {
    return {
      if (categoryId != null && categoryId!.isNotEmpty) 'category': categoryId,
      'title': title,
      'description': description,
      'pricing_model': pricingModel,
      'price_type': priceType,
      if (amount != null) 'price_amount': amount!.toStringAsFixed(2),
      if (minAmount != null) 'price_min_amount': minAmount!.toStringAsFixed(2),
      if (maxAmount != null) 'price_max_amount': maxAmount!.toStringAsFixed(2),
      'currency': currency,
      if (durationMinutes != null) 'duration_minutes': durationMinutes,
      'is_active': isActive,
    };
  }
}

ServiceModel mapServiceDto(
  ServiceDto dto,
  Map<String, ServiceCategoryDto> categoriesById,
) {
  return ServiceModel(
    id: dto.id,
    title: dto.title,
    category:
        categoriesById[dto.categoryId]?.name ?? dto.categoryId ?? 'General',
    categoryId: dto.categoryId,
    description: dto.description,
    pricingModel: _pricingModel(dto.pricingModel),
    priceType: _priceType(dto.priceType),
    currency: dto.currency,
    amount: _pickAmount(dto),
    priceMinAmount: double.tryParse(dto.priceMinAmount ?? ''),
    priceMaxAmount: double.tryParse(dto.priceMaxAmount ?? ''),
    durationMinutes: dto.durationMinutes,
    providerId: dto.providerId ?? '',
    imagePath: dto.imagePath ?? AppAssets.servicePlaceholder(dto.id),
    media: dto.media,
    isActive: dto.isActive,
    createdAt: dto.createdAt,
  );
}

ServiceWriteDto mapServiceWriteDto(
  ServiceModel model, {
  required String? categoryId,
}) {
  final isVariable = model.priceType == PriceType.variable;
  return ServiceWriteDto(
    categoryId: categoryId,
    title: model.title,
    description: model.description,
    pricingModel: model.pricingModel.name.toUpperCase(),
    priceType: model.priceType.name.toUpperCase(),
    amount: isVariable ? null : model.amount,
    minAmount: isVariable ? model.priceMinAmount : null,
    maxAmount: isVariable ? model.priceMaxAmount : null,
    currency: model.currency,
    durationMinutes: model.durationMinutes,
    isActive: model.isActive,
  );
}

PricingModel _pricingModel(String? raw) {
  switch ((raw ?? '').toUpperCase()) {
    case 'HOURLY':
      return PricingModel.hourly;
    case 'PACKAGE':
      return PricingModel.package;
    default:
      return PricingModel.fixed;
  }
}

PriceType _priceType(String? raw) {
  switch ((raw ?? '').toUpperCase()) {
    case 'VARIABLE':
      return PriceType.variable;
    default:
      return PriceType.fixed;
  }
}

double? _pickAmount(ServiceDto dto) {
  final amount = double.tryParse(dto.priceAmount ?? '');
  if (amount != null) return amount;
  final min = double.tryParse(dto.priceMinAmount ?? '');
  final max = double.tryParse(dto.priceMaxAmount ?? '');
  if (min != null && max != null) return (min + max) / 2;
  return min ?? max;
}

class ServiceMediaDto {
  final String id;
  final String serviceId;
  final String url;
  final String fileType;
  final String? description;
  final DateTime uploadedAt;

  const ServiceMediaDto({
    required this.id,
    required this.serviceId,
    required this.url,
    required this.fileType,
    this.description,
    required this.uploadedAt,
  });

  factory ServiceMediaDto.fromJson(Map<String, dynamic> json) {
    return ServiceMediaDto(
      id: json['id']?.toString() ?? '',
      serviceId: json['service']?.toString() ?? '',
      url: json['url']?.toString() ?? '',
      fileType: json['file_type']?.toString() ?? 'image',
      description: json['description']?.toString(),
      uploadedAt:
          DateTime.tryParse(json['uploaded_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}

class ServiceMediaUploadDto {
  final String serviceId;
  final String filePath;
  final String fileType;
  final String? description;

  const ServiceMediaUploadDto({
    required this.serviceId,
    required this.filePath,
    this.fileType = 'image',
    this.description,
  });

  Future<Map<String, dynamic>> toMultipartFields() async {
    final file = await MultipartFile.fromFile(filePath);
    return {
      'service': serviceId,
      'file': file,
      'file_type': fileType,
      if (description != null && description!.isNotEmpty)
        'description': description,
    };
  }
}
