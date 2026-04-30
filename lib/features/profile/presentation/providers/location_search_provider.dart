import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_places_flutter/model/prediction.dart';

/// Represents a selected location from search
class LocationResult {
  final String address;
  final String? placeId;
  final double? latitude;
  final double? longitude;

  const LocationResult({
    required this.address,
    this.placeId,
    this.latitude,
    this.longitude,
  });

  LocationResult copyWith({
    String? address,
    String? placeId,
    double? latitude,
    double? longitude,
  }) {
    return LocationResult(
      address: address ?? this.address,
      placeId: placeId ?? this.placeId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }
}

class LocationSearchState {
  final List<Prediction> predictions;
  final bool isLoading;
  final String? errorMessage;
  final LocationResult? selectedLocation;

  const LocationSearchState({
    this.predictions = const [],
    this.isLoading = false,
    this.errorMessage,
    this.selectedLocation,
  });

  LocationSearchState copyWith({
    List<Prediction>? predictions,
    bool? isLoading,
    String? errorMessage,
    LocationResult? selectedLocation,
  }) {
    return LocationSearchState(
      predictions: predictions ?? this.predictions,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      selectedLocation: selectedLocation ?? this.selectedLocation,
    );
  }
}

class LocationSearchNotifier extends StateNotifier<LocationSearchState> {
  LocationSearchNotifier() : super(const LocationSearchState());

  static const String _googleApiKey = 'YOUR_GOOGLE_PLACES_API_KEY';

  /// Search for places using Google Places Autocomplete
  Future<void> searchPlaces(String query) async {
    if (query.isEmpty) {
      state = state.copyWith(predictions: []);
      return;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      // Note: Replace 'YOUR_GOOGLE_PLACES_API_KEY' with actual API key
      // For now, this is a placeholder implementation
      if (_googleApiKey == 'YOUR_GOOGLE_PLACES_API_KEY') {
        // Fallback: return empty predictions when API key is not configured
        state = state.copyWith(
          predictions: [],
          isLoading: false,
          errorMessage: 'Google Places API key not configured',
        );
        return;
      }

      // Actual implementation would use GooglePlacesAutocomplete
      // For now, we'll simulate the response structure
      state = state.copyWith(predictions: [], isLoading: false);
    } catch (e) {
      state = state.copyWith(
        predictions: [],
        isLoading: false,
        errorMessage: 'Failed to search places: $e',
      );
    }
  }

  /// Select a location from predictions
  void selectLocation(Prediction prediction) {
    state = state.copyWith(
      selectedLocation: LocationResult(
        address: prediction.description ?? '',
        placeId: prediction.placeId,
      ),
      predictions: [],
    );
  }

  /// Set location directly (e.g., from current location)
  void setLocation(LocationResult location) {
    state = state.copyWith(selectedLocation: location, predictions: []);
  }

  /// Clear selected location
  void clearLocation() {
    state = state.copyWith(selectedLocation: null);
  }

  /// Clear error message
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

final locationSearchProvider =
    StateNotifierProvider<LocationSearchNotifier, LocationSearchState>(
      (ref) => LocationSearchNotifier(),
    );
