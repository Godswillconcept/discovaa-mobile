import 'package:discovaa/features/services/data/models/service_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ---------------------------------------------------------------------------
// Saved services state
// ---------------------------------------------------------------------------

class SavedServicesState {
  /// Set of saved service IDs for O(1) lookup.
  final Set<String> savedIds;

  /// Full service snapshots for the Saved tab display.
  final List<ServiceModel> savedServices;

  const SavedServicesState({
    this.savedIds = const {},
    this.savedServices = const [],
  });

  bool isSaved(String id) => savedIds.contains(id);

  SavedServicesState copyWith({
    Set<String>? savedIds,
    List<ServiceModel>? savedServices,
  }) {
    return SavedServicesState(
      savedIds: savedIds ?? this.savedIds,
      savedServices: savedServices ?? this.savedServices,
    );
  }
}

class SavedServicesNotifier extends StateNotifier<SavedServicesState> {
  SavedServicesNotifier() : super(const SavedServicesState()) {
    _initializeMockData();
  }

  /// Initialize with mock data for development/demo
  void _initializeMockData() {
    final mockServices = [
      ServiceModel(
        id: 'svc_001',
        title: 'Full House Cleaning',
        category: 'Laundry and Cleaning',
        description:
            'Complete house cleaning service including dusting, vacuuming, and sanitization.',
        pricingModel: PricingModel.fixed,
        priceType: PriceType.fixed,
        currency: '€',
        amount: 120.0,
        durationMinutes: 180,
        providerId: 'provider_001',
        imagePath: 'assets/images/placeholders/category_04.png',
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        updatedAt: DateTime.now(),
      ),
      ServiceModel(
        id: 'svc_002',
        title: 'Laptop Repair & Diagnostics',
        category: 'Computer Mobile and IT',
        description:
            'Hardware and software diagnostics, virus removal, and system optimization.',
        pricingModel: PricingModel.hourly,
        priceType: PriceType.fixed,
        currency: '€',
        amount: 45.0,
        durationMinutes: 60,
        providerId: 'provider_002',
        imagePath: 'assets/images/placeholders/category_02.png',
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
        updatedAt: DateTime.now(),
      ),
      ServiceModel(
        id: 'svc_003',
        title: 'Event Photography Package',
        category: 'Photographer',
        description:
            'Professional event photography with edited photos delivered within 48 hours.',
        pricingModel: PricingModel.package,
        priceType: PriceType.fixed,
        currency: '€',
        amount: 350.0,
        durationMinutes: 240,
        providerId: 'provider_003',
        imagePath: 'assets/images/placeholders/category_03.png',
        createdAt: DateTime.now().subtract(const Duration(days: 7)),
        updatedAt: DateTime.now(),
      ),
      ServiceModel(
        id: 'svc_004',
        title: 'Emergency Plumbing Fix',
        category: 'Plumbing and Pipes',
        description:
            'Quick response plumbing repair for leaks, clogs, and pipe issues.',
        pricingModel: PricingModel.hourly,
        priceType: PriceType.variable,
        currency: '€',
        amount: 60.0,
        durationMinutes: 90,
        providerId: 'provider_004',
        imagePath: 'assets/images/placeholders/category_01.png',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        updatedAt: DateTime.now(),
      ),
    ];

    final ids = mockServices.map((s) => s.id).toSet();
    state = SavedServicesState(savedIds: ids, savedServices: mockServices);
  }

  /// Toggle saved/unsaved. Returns true if now saved.
  bool toggle(ServiceModel service) {
    final ids = Set<String>.from(state.savedIds);
    final services = List<ServiceModel>.from(state.savedServices);

    if (ids.contains(service.id)) {
      ids.remove(service.id);
      services.removeWhere((s) => s.id == service.id);
      state = state.copyWith(savedIds: ids, savedServices: services);
      return false;
    } else {
      ids.add(service.id);
      services.add(service);
      state = state.copyWith(savedIds: ids, savedServices: services);
      return true;
    }
  }

  /// Remove a service from saved list by ID
  void remove(String serviceId) {
    final ids = Set<String>.from(state.savedIds);
    final services = List<ServiceModel>.from(state.savedServices);

    ids.remove(serviceId);
    services.removeWhere((s) => s.id == serviceId);
    state = state.copyWith(savedIds: ids, savedServices: services);
  }

  /// Add a service to saved list
  void add(ServiceModel service) {
    if (state.isSaved(service.id)) return;

    final ids = Set<String>.from(state.savedIds)..add(service.id);
    final services = List<ServiceModel>.from(state.savedServices)..add(service);
    state = state.copyWith(savedIds: ids, savedServices: services);
  }

  bool isSaved(String id) => state.isSaved(id);

  /// Get saved service by ID
  ServiceModel? getById(String id) {
    try {
      return state.savedServices.firstWhere((s) => s.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Clear all saved services
  void clear() {
    state = const SavedServicesState();
  }
}

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

/// Saved services provider — moved from bookings to profile feature
final savedServicesProvider =
    StateNotifierProvider<SavedServicesNotifier, SavedServicesState>(
      (ref) => SavedServicesNotifier(),
    );

/// Convenience: is a specific service saved?
final isServiceSavedProvider = Provider.family<bool, String>((ref, serviceId) {
  return ref.watch(savedServicesProvider).isSaved(serviceId);
});

/// Convenience: get count of saved services
final savedServicesCountProvider = Provider<int>((ref) {
  return ref.watch(savedServicesProvider).savedServices.length;
});
