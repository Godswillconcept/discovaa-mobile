import 'package:discovaa/app/dependency_injection/service_locator.dart';
import 'package:discovaa/core/network/dio_client.dart';
import 'package:discovaa/core/network/network_info.dart';
import 'package:discovaa/core/storage/hive_service.dart';
import 'package:discovaa/features/services/data/models/service_api_models.dart';
import 'package:discovaa/features/services/data/models/service_model.dart';
import 'package:discovaa/features/services/data/repositories/services_repository_impl.dart';
import 'package:discovaa/features/services/domain/repositories/services_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

/// Represents the connectivity / loading status for the services feature
enum ServicesStatus { idle, loading, success, failure }

class ServicesState {
  final List<ServiceModel> services;
  final List<ServiceModel> ownServices;
  final List<ServiceModel> featuredServices;
  final List<ServiceMediaDto> serviceMedia;
  final ServicesStatus status;
  final ServicesStatus featuredStatus;
  final ServicesStatus mediaUploadStatus;
  final String? errorMessage;
  final String? mediaUploadError;
  final String searchQuery;

  const ServicesState({
    this.services = const [],
    this.ownServices = const [],
    this.featuredServices = const [],
    this.serviceMedia = const [],
    this.status = ServicesStatus.idle,
    this.featuredStatus = ServicesStatus.idle,
    this.mediaUploadStatus = ServicesStatus.idle,
    this.errorMessage,
    this.mediaUploadError,
    this.searchQuery = '',
  });

  ServicesState copyWith({
    List<ServiceModel>? services,
    List<ServiceModel>? ownServices,
    List<ServiceModel>? featuredServices,
    List<ServiceMediaDto>? serviceMedia,
    ServicesStatus? status,
    ServicesStatus? featuredStatus,
    ServicesStatus? mediaUploadStatus,
    String? errorMessage,
    String? mediaUploadError,
    String? searchQuery,
  }) {
    return ServicesState(
      services: services ?? this.services,
      ownServices: ownServices ?? this.ownServices,
      featuredServices: featuredServices ?? this.featuredServices,
      serviceMedia: serviceMedia ?? this.serviceMedia,
      status: status ?? this.status,
      featuredStatus: featuredStatus ?? this.featuredStatus,
      mediaUploadStatus: mediaUploadStatus ?? this.mediaUploadStatus,
      errorMessage: errorMessage,
      mediaUploadError: mediaUploadError,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  /// Filtered services based on current search query
  List<ServiceModel> get filtered {
    if (searchQuery.isEmpty) return services;
    final q = searchQuery.toLowerCase();
    return services
        .where(
          (s) =>
              s.title.toLowerCase().contains(q) ||
              (s.category?.toLowerCase().contains(q) ?? false),
        )
        .toList();
  }

  /// Filtered own services based on current search query
  List<ServiceModel> get filteredOwn {
    if (searchQuery.isEmpty) return ownServices;
    final q = searchQuery.toLowerCase();
    return ownServices
        .where(
          (s) =>
              s.title.toLowerCase().contains(q) ||
              (s.category?.toLowerCase().contains(q) ?? false),
        )
        .toList();
  }
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class ServicesNotifier extends StateNotifier<ServicesState> {
  ServicesNotifier(this._repository) : super(const ServicesState());

  final ServicesRepository _repository;

  static const _uuid = Uuid();

  /// Add a new service to the catalog
  Future<ServiceModel?> addService({
    required String title,
    String? category,
    String? categoryId,
    required String description,
    required PricingModel pricingModel,
    required PriceType priceType,
    required String currency,
    double? amount,
    double? priceMinAmount,
    double? priceMaxAmount,
    int? durationMinutes,
    Map<WeekDay, List<ServiceTimeSlot>> weeklySchedule = const {},
    bool isActive = true,
  }) async {
    final service = ServiceModel(
      id: _uuid.v4(),
      title: title.trim(),
      category: category?.trim(),
      categoryId: categoryId?.trim(),
      description: description.trim(),
      pricingModel: pricingModel,
      priceType: priceType,
      currency: currency.trim(),
      amount: amount,
      priceMinAmount: priceMinAmount,
      priceMaxAmount: priceMaxAmount,
      durationMinutes: durationMinutes,
      weeklySchedule: weeklySchedule,
      isActive: isActive,
      createdAt: DateTime.now(),
    );

    state = state.copyWith(
      services: [...state.services, service],
      ownServices: [...state.ownServices, service],
      status: ServicesStatus.success,
    );
    try {
      final created = await _repository.createService(service);
      
      // Update services list
      final updatedServices = [...state.services];
      final sIndex = updatedServices.indexWhere((item) => item.id == service.id);
      if (sIndex != -1) updatedServices[sIndex] = created;
      
      // Update ownServices list
      final updatedOwn = [...state.ownServices];
      final oIndex = updatedOwn.indexWhere((item) => item.id == service.id);
      if (oIndex != -1) updatedOwn[oIndex] = created;

      state = state.copyWith(
        services: updatedServices,
        ownServices: updatedOwn,
      );
      return created;
    } catch (e) {
      state = state.copyWith(
        status: ServicesStatus.failure,
        errorMessage: 'Failed to create service. Please try again.',
      );
      return null;
    }
  }

  /// Update an existing service by id
  Future<ServiceModel?> updateService(ServiceModel service) async {
    state = state.copyWith(status: ServicesStatus.loading);
    try {
      final updated = await _repository.updateService(service);
      
      final updatedServices = [...state.services];
      final sIndex = updatedServices.indexWhere((item) => item.id == service.id);
      if (sIndex != -1) updatedServices[sIndex] = updated;

      final updatedOwn = [...state.ownServices];
      final oIndex = updatedOwn.indexWhere((item) => item.id == service.id);
      if (oIndex != -1) updatedOwn[oIndex] = updated;

      state = state.copyWith(
        services: updatedServices,
        ownServices: updatedOwn,
        status: ServicesStatus.success,
      );
      return updated;
    } catch (e) {
      state = state.copyWith(
        status: ServicesStatus.failure,
        errorMessage: 'Failed to update service. Please try again.',
      );
      return null;
    }
  }

  /// Toggle the active/inactive status of a service
  Future<bool> toggleServiceStatus(ServiceModel service) async {
    final updated = service.copyWith(isActive: !service.isActive);
    try {
      final saved = await _repository.updateService(updated);
      
      final updatedServices = [...state.services];
      final sIndex = updatedServices.indexWhere((item) => item.id == service.id);
      if (sIndex != -1) updatedServices[sIndex] = saved;

      final updatedOwn = [...state.ownServices];
      final oIndex = updatedOwn.indexWhere((item) => item.id == service.id);
      if (oIndex != -1) updatedOwn[oIndex] = saved;

      state = state.copyWith(
        services: updatedServices,
        ownServices: updatedOwn,
        status: ServicesStatus.success,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        status: ServicesStatus.failure,
        errorMessage: 'Failed to update service status.',
      );
      return false;
    }
  }

  /// Remove a service by id
  Future<bool> deleteService(String id) async {
    state = state.copyWith(status: ServicesStatus.loading);
    try {
      await _repository.deleteService(id);
      state = state.copyWith(
        services: state.services.where((item) => item.id != id).toList(),
        ownServices: state.ownServices.where((item) => item.id != id).toList(),
        status: ServicesStatus.success,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        mediaUploadStatus: ServicesStatus.failure,
        mediaUploadError: 'Failed to delete media. Please try again.',
      );
      return false;
    }
  }

  /// Update the search query for filtering
  void updateSearch(String query) {
    state = state.copyWith(searchQuery: query);
  }

  /// Clear any error state
  void clearError() {
    state = state.copyWith(errorMessage: null, status: ServicesStatus.idle);
  }

  /// Load featured services for home screen carousel
  Future<void> loadFeaturedServices({int? limit}) async {
    if (state.featuredServices.isNotEmpty) return;
    state = state.copyWith(featuredStatus: ServicesStatus.loading);
    try {
      final data = await _repository.fetchFeaturedServices(limit: limit);
      state = state.copyWith(
        featuredServices: data,
        featuredStatus: ServicesStatus.success,
      );
    } catch (e) {
      state = state.copyWith(
        featuredStatus: ServicesStatus.failure,
        errorMessage: 'Failed to load featured services.',
      );
    }
  }

  /// Upload media to a service
  Future<bool> uploadMedia({
    required String serviceId,
    required String filePath,
    String fileType = 'image',
    String? description,
  }) async {
    state = state.copyWith(
      mediaUploadStatus: ServicesStatus.loading,
      mediaUploadError: null,
    );
    try {
      final uploaded = await _repository.uploadServiceMedia(
        serviceId: serviceId,
        filePath: filePath,
        fileType: fileType,
        description: description,
      );
      state = state.copyWith(
        mediaUploadStatus: ServicesStatus.success,
        serviceMedia: [...state.serviceMedia, uploaded],
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        mediaUploadStatus: ServicesStatus.failure,
        mediaUploadError: 'Failed to upload media. Please try again.',
      );
      return false;
    }
  }

  /// Clear media upload error
  void clearMediaUploadError() {
    state = state.copyWith(
      mediaUploadError: null,
      mediaUploadStatus: ServicesStatus.idle,
    );
  }

  Future<List<ServiceMediaDto>> loadServiceMediaForService(
    String serviceId,
  ) async {
    try {
      final media = await _repository.listServiceMedia();
      final filtered = media
          .where((item) => item.serviceId == serviceId)
          .toList(growable: false);
      state = state.copyWith(serviceMedia: media);
      return filtered;
    } catch (e) {
      state = state.copyWith(
        mediaUploadStatus: ServicesStatus.failure,
        mediaUploadError: 'Failed to load service media. Please try again.',
      );
      return const [];
    }
  }

  Future<bool> deleteMedia(String mediaId) async {
    try {
      await _repository.deleteServiceMedia(mediaId);
      state = state.copyWith(
        serviceMedia: state.serviceMedia
            .where((item) => item.id != mediaId)
            .toList(growable: false),
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        mediaUploadStatus: ServicesStatus.failure,
        mediaUploadError: 'Failed to delete media. Please try again.',
      );
      return false;
    }
  }

  /// Load services from the API
  Future<void> loadServices() async {
    if (state.services.isNotEmpty) return;
    state = state.copyWith(status: ServicesStatus.loading);
    try {
      final data = await _repository.listServices();
      state = state.copyWith(services: data, status: ServicesStatus.success);
    } catch (e) {
      state = state.copyWith(
        status: ServicesStatus.failure,
        errorMessage: 'Failed to load services. Please try again.',
      );
    }
  }

  /// Load provider's own services from the management API
  Future<void> loadOwnServices({bool forceRefresh = false}) async {
    if (!forceRefresh && state.ownServices.isNotEmpty) return;
    state = state.copyWith(status: ServicesStatus.loading);
    try {
      final data = await _repository.listOwnServices();
      state = state.copyWith(ownServices: data, status: ServicesStatus.success);
    } catch (e) {
      state = state.copyWith(
        status: ServicesStatus.failure,
        errorMessage: 'Failed to load your services. Please try again.',
      );
    }
  }
}

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

/// Primary services state provider
final servicesRepositoryProvider = Provider<ServicesRepository>((ref) {
  return ServicesRepositoryImpl(
    dioClient: sl<DioClient>(),
    hiveService: sl<HiveService>(),
    networkInfo: sl<NetworkInfo>(),
  );
});

final servicesProvider = StateNotifierProvider<ServicesNotifier, ServicesState>(
  (ref) => ServicesNotifier(ref.watch(servicesRepositoryProvider)),
);

/// Convenience provider for the list of filtered services
final filteredServicesProvider = Provider<List<ServiceModel>>((ref) {
  return ref.watch(servicesProvider).filtered;
});

/// Convenience provider for service count
final serviceCountProvider = Provider<int>((ref) {
  return ref.watch(servicesProvider).services.length;
});

/// Convenience provider for featured services
final featuredServicesProvider = Provider<List<ServiceModel>>((ref) {
  return ref.watch(servicesProvider).featuredServices;
});

/// Provider for featured services loading status
final featuredServicesStatusProvider = Provider<ServicesStatus>((ref) {
  return ref.watch(servicesProvider).featuredStatus;
});

/// Provider for media upload status
final mediaUploadStatusProvider = Provider<ServicesStatus>((ref) {
  return ref.watch(servicesProvider).mediaUploadStatus;
});

/// Provider for media upload error
final mediaUploadErrorProvider = Provider<String?>((ref) {
  return ref.watch(servicesProvider).mediaUploadError;
});

// ---------------------------------------------------------------------------
// Service Categories State
// ---------------------------------------------------------------------------

class ServiceCategoriesState {
  final List<ServiceCategoryDto> categories;
  final ServicesStatus status;
  final String? errorMessage;

  const ServiceCategoriesState({
    this.categories = const [],
    this.status = ServicesStatus.idle,
    this.errorMessage,
  });

  ServiceCategoriesState copyWith({
    List<ServiceCategoryDto>? categories,
    ServicesStatus? status,
    String? errorMessage,
  }) {
    return ServiceCategoriesState(
      categories: categories ?? this.categories,
      status: status ?? this.status,
      errorMessage: errorMessage,
    );
  }
}

class ServiceCategoriesNotifier extends StateNotifier<ServiceCategoriesState> {
  ServiceCategoriesNotifier(this._repository)
    : super(const ServiceCategoriesState());

  final ServicesRepository _repository;

  Future<void> loadCategories() async {
    if (state.status == ServicesStatus.loading) return;

    state = state.copyWith(status: ServicesStatus.loading);
    try {
      final categoryNames = await _repository.listCategoryNames();
      // Convert names to DTOs with generated IDs for UI use
      // The actual category IDs will be resolved by the repository on submit
      final categories = categoryNames
          .map(
            (name) => ServiceCategoryDto(
              id: name.toLowerCase().replaceAll(' ', '-'),
              name: name,
            ),
          )
          .toList();

      state = state.copyWith(
        categories: categories,
        status: ServicesStatus.success,
      );
    } catch (e) {
      state = state.copyWith(
        status: ServicesStatus.failure,
        errorMessage: 'Failed to load categories. Please try again.',
      );
    }
  }

  /// Get category name by ID
  String? getCategoryName(String id) {
    try {
      return state.categories.firstWhere((c) => c.id == id).name;
    } catch (_) {
      return null;
    }
  }

  /// Get category ID by name
  String? getCategoryId(String name) {
    try {
      return state.categories.firstWhere((c) => c.name == name).id;
    } catch (_) {
      return null;
    }
  }
}

final serviceCategoriesProvider =
    StateNotifierProvider.autoDispose<
      ServiceCategoriesNotifier,
      ServiceCategoriesState
    >((ref) {
      final repository = ref.watch(servicesRepositoryProvider);
      return ServiceCategoriesNotifier(repository);
    });

// ---------------------------------------------------------------------------
// Form state for AddServiceSheet
// ---------------------------------------------------------------------------

class AddServiceFormState {
  final String title;
  final String category; // Display name
  final String categoryId; // UUID for API
  final String description;
  final PricingModel pricingModel;
  final PriceType priceType;
  final String currency;
  final String amountRaw;
  final String minAmountRaw;
  final String maxAmountRaw;
  final String durationRaw;

  /// Weekly availability: day → ordered list of time slots
  final Map<WeekDay, List<ServiceTimeSlot>> weeklySchedule;
  final bool isActive;
  final bool submitted;

  /// Pending media files to upload after service creation (local file paths)
  final List<String> pendingMediaPaths;

  /// Existing media objects (for edit mode display and deletion)
  final List<ServiceMediaDto> existingMedia;

  const AddServiceFormState({
    this.title = '',
    this.category = '',
    this.categoryId = '',
    this.description = '',
    this.pricingModel = PricingModel.fixed,
    this.priceType = PriceType.fixed,
    this.currency = 'NGN',
    this.amountRaw = '',
    this.minAmountRaw = '',
    this.maxAmountRaw = '',
    this.durationRaw = '',
    this.weeklySchedule = const {},
    this.isActive = true,
    this.submitted = false,
    this.pendingMediaPaths = const [],
    this.existingMedia = const [],
  });

  AddServiceFormState copyWith({
    String? title,
    String? category,
    String? categoryId,
    String? description,
    PricingModel? pricingModel,
    PriceType? priceType,
    String? currency,
    String? amountRaw,
    String? minAmountRaw,
    String? maxAmountRaw,
    String? durationRaw,
    Map<WeekDay, List<ServiceTimeSlot>>? weeklySchedule,
    bool? isActive,
    bool? submitted,
    List<String>? pendingMediaPaths,
    List<ServiceMediaDto>? existingMedia,
  }) {
    return AddServiceFormState(
      title: title ?? this.title,
      category: category ?? this.category,
      categoryId: categoryId ?? this.categoryId,
      description: description ?? this.description,
      pricingModel: pricingModel ?? this.pricingModel,
      priceType: priceType ?? this.priceType,
      currency: currency ?? this.currency,
      amountRaw: amountRaw ?? this.amountRaw,
      minAmountRaw: minAmountRaw ?? this.minAmountRaw,
      maxAmountRaw: maxAmountRaw ?? this.maxAmountRaw,
      durationRaw: durationRaw ?? this.durationRaw,
      weeklySchedule: weeklySchedule ?? this.weeklySchedule,
      isActive: isActive ?? this.isActive,
      submitted: submitted ?? this.submitted,
      pendingMediaPaths: pendingMediaPaths ?? this.pendingMediaPaths,
      existingMedia: existingMedia ?? this.existingMedia,
    );
  }

  bool get isTitleValid => title.trim().isNotEmpty;
  bool get isCategoryValid => category.trim().isNotEmpty;
  bool get isAmountValid =>
      amountRaw.isEmpty || double.tryParse(amountRaw) != null;
  bool get isMinAmountValid =>
      minAmountRaw.isEmpty || double.tryParse(minAmountRaw) != null;
  bool get isMaxAmountValid =>
      maxAmountRaw.isEmpty || double.tryParse(maxAmountRaw) != null;
  bool get isDurationValid =>
      durationRaw.isEmpty || int.tryParse(durationRaw) != null;

  bool get isFormValid =>
      isTitleValid && isCategoryValid && isAmountValid && isDurationValid;

  /// Total number of media items (existing + pending)
  int get totalMediaCount => existingMedia.length + pendingMediaPaths.length;

  /// Maximum allowed media items
  static const int maxMediaCount = 5;

  bool get canAddMoreMedia => totalMediaCount < maxMediaCount;
}

class AddServiceFormNotifier extends StateNotifier<AddServiceFormState> {
  AddServiceFormNotifier() : super(const AddServiceFormState());

  void updateTitle(String v) => state = state.copyWith(title: v);

  /// Update category with both name and ID
  void updateCategory({required String name, required String id}) =>
      state = state.copyWith(category: name, categoryId: id);

  void updateDescription(String v) => state = state.copyWith(description: v);
  void updatePricingModel(PricingModel v) =>
      state = state.copyWith(pricingModel: v);
  void updatePriceType(PriceType v) => state = state.copyWith(priceType: v);
  void updateCurrency(String v) => state = state.copyWith(currency: v);
  void updateAmount(String v) => state = state.copyWith(amountRaw: v);
  void updateMinAmount(String v) => state = state.copyWith(minAmountRaw: v);
  void updateMaxAmount(String v) => state = state.copyWith(maxAmountRaw: v);
  void updateDuration(String v) => state = state.copyWith(durationRaw: v);
  void updateIsActive(bool v) => state = state.copyWith(isActive: v);

  /// Toggle a day on/off. Removing a day clears its slots.
  void toggleDay(WeekDay day) {
    final schedule = Map<WeekDay, List<ServiceTimeSlot>>.from(
      state.weeklySchedule,
    );
    if (schedule.containsKey(day)) {
      schedule.remove(day);
    } else {
      schedule[day] = [];
    }
    state = state.copyWith(weeklySchedule: schedule);
  }

  /// Add a time slot to a specific day.
  void addSlot(WeekDay day, ServiceTimeSlot slot) {
    final schedule = Map<WeekDay, List<ServiceTimeSlot>>.from(
      state.weeklySchedule.map(
        (k, v) => MapEntry(k, List<ServiceTimeSlot>.from(v)),
      ),
    );
    schedule.putIfAbsent(day, () => []).add(slot);
    state = state.copyWith(weeklySchedule: schedule);
  }

  /// Remove a specific slot from a day.
  void removeSlot(WeekDay day, int index) {
    final schedule = Map<WeekDay, List<ServiceTimeSlot>>.from(
      state.weeklySchedule.map(
        (k, v) => MapEntry(k, List<ServiceTimeSlot>.from(v)),
      ),
    );
    schedule[day]?.removeAt(index);
    state = state.copyWith(weeklySchedule: schedule);
  }

  /// Load a full schedule (used when editing an existing service).
  void loadSchedule(Map<WeekDay, List<ServiceTimeSlot>> schedule) {
    state = state.copyWith(weeklySchedule: Map.from(schedule));
  }

  void markSubmitted() => state = state.copyWith(submitted: true);
  void reset() => state = const AddServiceFormState();

  /// Add a pending media file path (selected but not yet uploaded)
  void addPendingMedia(String filePath) {
    if (!state.canAddMoreMedia) return;
    final updated = [...state.pendingMediaPaths, filePath];
    state = state.copyWith(pendingMediaPaths: updated);
  }

  /// Remove a pending media file at the given index
  void removePendingMedia(int index) {
    if (index < 0 || index >= state.pendingMediaPaths.length) return;
    final updated = [...state.pendingMediaPaths];
    updated.removeAt(index);
    state = state.copyWith(pendingMediaPaths: updated);
  }

  /// Clear all pending media files
  void clearPendingMedia() {
    state = state.copyWith(pendingMediaPaths: const []);
  }

  /// Set existing media URLs (for edit mode)
  void setExistingMedia(List<ServiceMediaDto> media) {
    state = state.copyWith(existingMedia: media);
  }

  void removeExistingMedia(String mediaId) {
    state = state.copyWith(
      existingMedia: state.existingMedia
          .where((item) => item.id != mediaId)
          .toList(growable: false),
    );
  }
}

final addServiceFormProvider =
    StateNotifierProvider.autoDispose<
      AddServiceFormNotifier,
      AddServiceFormState
    >((ref) => AddServiceFormNotifier());
