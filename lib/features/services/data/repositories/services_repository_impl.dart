import 'package:dio/dio.dart';
import 'package:discovaa/core/constants/api_endpoints.dart';
import 'package:discovaa/core/network/network_info.dart';
import 'package:discovaa/core/network/api_helpers.dart';
import 'package:discovaa/core/network/dio_client.dart';
import 'package:discovaa/core/storage/hive_service.dart';
import 'package:discovaa/features/services/data/models/service_api_models.dart';
import 'package:discovaa/features/services/data/models/service_model.dart';
import 'package:discovaa/features/services/domain/repositories/services_repository.dart';

class ServicesRepositoryImpl implements ServicesRepository {
  final DioClient _dioClient;
  final HiveService _hiveService;
  // ignore: unused_field
  final NetworkInfo _networkInfo;

  ServicesRepositoryImpl({
    required DioClient dioClient,
    required HiveService hiveService,
    required NetworkInfo networkInfo,
  }) : _dioClient = dioClient,
       _hiveService = hiveService,
       _networkInfo = networkInfo;

  static const _servicesCacheKey = 'services.cache.list';
  static const _featuredServicesCacheKey = 'services.cache.featured';
  static const _categoriesCacheKey = 'services.cache.categories';

  @override
  Future<List<ServiceModel>> listServices() async {
    try {
      final categories = await _categoryMap();
      final response = await _dioClient.get(ApiEndpoints.services);
      final envelope = decodeListEnvelope(
        response,
        (item) => ServiceDto.fromJson(item),
      );
      final services = envelope.data
          .map((dto) => mapServiceDto(dto, categories))
          .toList(growable: false);
      await _cacheServices(_servicesCacheKey, services);
      return services;
    } catch (_) {
      final cached = _readCachedServices(_servicesCacheKey);
      if (cached.isNotEmpty) {
        return cached;
      }
      rethrow;
    }
  }

  @override
  Future<List<ServiceModel>> listOwnServices({String? providerId}) async {
    try {
      final categories = await _categoryMap();
      // Use public API endpoint with provider filtering
      // Pass providerId as query parameter to filter by the authenticated user's provider ID
      final response = await _dioClient.get(
        ApiEndpoints.services,
        queryParameters: providerId != null ? {'provider': providerId} : null,
      );
      final envelope = decodeListEnvelope(
        response,
        (item) => ServiceDto.fromJson(item),
      );
      final services = envelope.data
          .map((dto) => mapServiceDto(dto, categories))
          .toList(growable: false);
      // We don't necessarily want to overwrite the main cache with own services,
      // or maybe we do if the main cache should only show own services for providers.
      // For now, let's keep it separate or just return.
      return services;
    } catch (_) {
      rethrow;
    }
  }

  @override
  Future<List<String>> listCategoryNames() async {
    final categories = await _categoryMap();
    return categories.values.map((item) => item.name).toList(growable: false);
  }

  @override
  Future<ServiceModel> createService(ServiceModel service) async {
    final categories = await _categoryMap();
    final categoryId = _resolveCategoryId(categories, service.category);
    final response = await _dioClient.post(
      ApiEndpoints.services,
      data: mapServiceWriteDto(service, categoryId: categoryId).toJson(),
    );
    final dto = decodeEnvelope(
      response,
      (raw) => ServiceDto.fromJson(asMap(raw)),
    ).data;
    final updated = mapServiceDto(dto, categories);
    await _upsertCachedService(updated);
    return updated;
  }

  @override
  Future<ServiceModel> updateService(ServiceModel service) async {
    final categories = await _categoryMap();
    final categoryId = _resolveCategoryId(categories, service.category);
    final response = await _dioClient.patch(
      '${ApiEndpoints.services}${service.id}/',
      data: mapServiceWriteDto(service, categoryId: categoryId).toJson(),
    );
    final dto = decodeEnvelope(
      response,
      (raw) => ServiceDto.fromJson(asMap(raw)),
    ).data;
    final updated = mapServiceDto(dto, categories);
    await _upsertCachedService(updated);
    return updated;
  }

  @override
  Future<void> deleteService(String id) async {
    await _dioClient.delete('${ApiEndpoints.services}$id/');
    await _removeCachedService(id);
  }

  @override
  Future<List<ServiceMediaDto>> listServiceMedia() async {
    final response = await _dioClient.get(ApiEndpoints.serviceMedia);
    final envelope = decodeListEnvelope(
      response,
      (item) => ServiceMediaDto.fromJson(item),
    );
    return envelope.data;
  }

  @override
  Future<ServiceMediaDto> uploadServiceMedia({
    required String serviceId,
    required String filePath,
    String fileType = 'image',
    String? description,
  }) async {
    final formData = FormData.fromMap({
      'service': serviceId,
      'file': await MultipartFile.fromFile(filePath),
      'file_type': fileType,
      if (description != null && description.isNotEmpty)
        'description': description,
    });

    final response = await _dioClient.post(
      ApiEndpoints.serviceMedia,
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );

    return decodeEnvelope(
      response,
      (raw) => ServiceMediaDto.fromJson(asMap(raw)),
    ).data;
  }

  @override
  Future<void> deleteServiceMedia(String id) async {
    await _dioClient.delete('${ApiEndpoints.serviceMedia}$id/');
  }

  @override
  Future<List<ServiceModel>> fetchFeaturedServices({int? limit}) async {
    final cacheKey = limit == null
        ? _featuredServicesCacheKey
        : '$_featuredServicesCacheKey.$limit';
    try {
      final categories = await _categoryMap();
      final response = await _dioClient.get(
        ApiEndpoints.servicesFeatured,
        queryParameters: limit != null ? {'limit': limit} : null,
      );
      final envelope = decodeListEnvelope(
        response,
        (item) => ServiceDto.fromJson(item),
      );
      final services = envelope.data
          .map((dto) => mapServiceDto(dto, categories))
          .toList(growable: false);
      await _cacheServices(cacheKey, services);
      return services;
    } catch (_) {
      final cached = _readCachedServices(cacheKey);
      if (cached.isNotEmpty) {
        return cached;
      }
      rethrow;
    }
  }

  Map<String, ServiceCategoryDto>? _inMemoryCategories;

  Future<Map<String, ServiceCategoryDto>> _categoryMap() async {
    if (_inMemoryCategories != null) {
      return _inMemoryCategories!;
    }

    final cached = _readCachedCategories();
    if (cached.isNotEmpty) {
      _inMemoryCategories = cached;
      // Fetch in background to keep data fresh without blocking UI
      _fetchCategoriesSilent();
      return cached;
    }

    return await _fetchCategoriesSilent();
  }

  Future<Map<String, ServiceCategoryDto>> _fetchCategoriesSilent() async {
    try {
      final response = await _dioClient.get(ApiEndpoints.serviceCategories);
      final envelope = decodeListEnvelope(
        response,
        (item) => ServiceCategoryDto.fromJson(item),
      );
      final categories = {
        for (final category in envelope.data) category.id: category,
      };
      await _hiveService.setList(
        _categoriesCacheKey,
        envelope.data.map((category) => category.toJson()).toList(),
      );
      _inMemoryCategories = categories;
      return categories;
    } catch (_) {
      final cached = _readCachedCategories();
      if (cached.isNotEmpty) {
        _inMemoryCategories = cached;
        return cached;
      }
      rethrow;
    }
  }

  Future<void> _cacheServices(String key, List<ServiceModel> services) async {
    await _hiveService.setList(
      key,
      services.map((service) => service.toJson()).toList(growable: false),
    );
  }

  List<ServiceModel> _readCachedServices(String key) {
    final cached = _hiveService.getList<dynamic>(key) ?? const [];
    return cached
        .whereType<Map>()
        .map((item) => ServiceModel.fromJson(item.cast<String, dynamic>()))
        .toList(growable: false);
  }

  Map<String, ServiceCategoryDto> _readCachedCategories() {
    final cached =
        _hiveService.getList<dynamic>(_categoriesCacheKey) ?? const [];
    final categories = cached
        .whereType<Map>()
        .map(
          (item) => ServiceCategoryDto.fromJson(item.cast<String, dynamic>()),
        )
        .toList(growable: false);
    return {for (final category in categories) category.id: category};
  }

  Future<void> _upsertCachedService(ServiceModel service) async {
    final current = _readCachedServices(_servicesCacheKey).toList();
    final index = current.indexWhere((item) => item.id == service.id);
    if (index == -1) {
      current.insert(0, service);
    } else {
      current[index] = service;
    }
    await _cacheServices(_servicesCacheKey, current);
  }

  Future<void> _removeCachedService(String id) async {
    final current = _readCachedServices(
      _servicesCacheKey,
    ).where((item) => item.id != id).toList(growable: false);
    await _cacheServices(_servicesCacheKey, current);
  }

  String? _resolveCategoryId(
    Map<String, ServiceCategoryDto> categories,
    String? categoryName,
  ) {
    if (categoryName == null) return null;
    final direct = maybeUuidCategoryId(categoryName);
    if (direct != null) return direct;
    for (final category in categories.values) {
      if (category.name.toLowerCase() == categoryName.toLowerCase()) {
        return category.id;
      }
    }
    return null;
  }
}
