import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:discovaa/core/network/network_info.dart';
import 'package:discovaa/core/storage/hive_service.dart';
import 'package:discovaa/features/authentication/domain/entities/identification_entity.dart';
import 'package:discovaa/features/authentication/presentation/providers/auth_provider.dart';

/// Form validation state for ID number input
enum IdNumberValidationState { valid, empty, tooLong, invalidCharacters }

/// Connectivity state for network operations
enum ConnectivityState { connected, disconnected, unknown }

/// Form field error messages
class IdNumberValidationResult {
  final IdNumberValidationState state;
  final String? errorMessage;

  const IdNumberValidationResult._(this.state, this.errorMessage);

  factory IdNumberValidationResult.valid() {
    return const IdNumberValidationResult._(
      IdNumberValidationState.valid,
      null,
    );
  }

  factory IdNumberValidationResult.empty() {
    return const IdNumberValidationResult._(
      IdNumberValidationState.empty,
      'ID number is required.',
    );
  }

  factory IdNumberValidationResult.tooLong() {
    return const IdNumberValidationResult._(
      IdNumberValidationState.tooLong,
      'ID number must be 30 characters or less.',
    );
  }

  factory IdNumberValidationResult.invalidCharacters() {
    return const IdNumberValidationResult._(
      IdNumberValidationState.invalidCharacters,
      'Only letters and numbers are allowed.',
    );
  }

  bool get isValid => state == IdNumberValidationState.valid;
}

/// State for identification page
class IdentificationPageState {
  final IdentificationEntity identification;
  final String? idNumberInput;
  final String? idTypeInput; // e.g., 'NIN', 'Passport', 'Driver License'
  final bool isLoading;
  final String? errorMessage;
  final ConnectivityState connectivityState;
  final bool isFormSubmitted;

  const IdentificationPageState({
    this.identification = const IdentificationEntity(),
    this.idNumberInput,
    this.idTypeInput,
    this.isLoading = false,
    this.errorMessage,
    this.connectivityState = ConnectivityState.unknown,
    this.isFormSubmitted = false,
  });

  IdentificationPageState copyWith({
    IdentificationEntity? identification,
    String? idNumberInput,
    String? idTypeInput,
    bool? isLoading,
    String? errorMessage,
    ConnectivityState? connectivityState,
    bool? isFormSubmitted,
  }) {
    return IdentificationPageState(
      identification: identification ?? this.identification,
      idNumberInput: idNumberInput ?? this.idNumberInput,
      idTypeInput: idTypeInput ?? this.idTypeInput,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      connectivityState: connectivityState ?? this.connectivityState,
      isFormSubmitted: isFormSubmitted ?? this.isFormSubmitted,
    );
  }

  /// Validates the current ID number input
  IdNumberValidationResult validateIdNumber() {
    if (idNumberInput == null || idNumberInput!.isEmpty) {
      return IdNumberValidationResult.empty();
    }

    if (idNumberInput!.length > 30) {
      return IdNumberValidationResult.tooLong();
    }

    // Alphanumeric validation: letters, numbers, and spaces allowed
    final alphanumericRegex = RegExp(r'^[a-zA-Z0-9\s]+$');
    if (!alphanumericRegex.hasMatch(idNumberInput!)) {
      return IdNumberValidationResult.invalidCharacters();
    }

    return IdNumberValidationResult.valid();
  }

  /// Checks if the form can be submitted
  bool get canSubmit {
    final idValid = validateIdNumber().isValid;
    final hasFrontImage = identification.frontImagePath != null;
    final hasBackImage = identification.backImagePath != null;
    final isConnected = connectivityState == ConnectivityState.connected;

    return idValid && hasFrontImage && hasBackImage && isConnected;
  }

  /// Checks if the ID number field has an error
  bool get hasIdNumberError {
    if (!isFormSubmitted && (idNumberInput == null || idNumberInput!.isEmpty)) {
      return false;
    }
    return !validateIdNumber().isValid;
  }

  /// Gets the ID number error message if any
  String? get idNumberErrorMessage {
    if (!isFormSubmitted && (idNumberInput == null || idNumberInput!.isEmpty)) {
      return null;
    }
    return validateIdNumber().errorMessage;
  }
}

/// Notifier for identification page state management
class IdentificationNotifier extends StateNotifier<IdentificationPageState> {
  final NetworkInfo? networkInfo;
  final Ref ref;
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;

  IdentificationNotifier({this.networkInfo, required this.ref})
    : super(const IdentificationPageState()) {
    _initConnectivity();
  }

  /// Initialize connectivity monitoring
  void _initConnectivity() {
    _checkConnectivity();

    // Listen to connectivity changes if networkInfo is available
    if (networkInfo != null) {
      _connectivitySubscription = networkInfo!.onConnectivityChanged.listen((
        result,
      ) {
        _updateConnectivityState(result);
      });
    }
  }

  /// Check current connectivity status
  Future<void> _checkConnectivity() async {
    if (networkInfo != null) {
      final result = await networkInfo!.connectivityResult;
      _updateConnectivityState(result);
    } else {
      // Default to connected if no network info available
      state = state.copyWith(connectivityState: ConnectivityState.connected);
    }
  }

  /// Update connectivity state based on result
  void _updateConnectivityState(ConnectivityResult result) {
    final hasConnection = result != ConnectivityResult.none;
    final connectivityState = hasConnection
        ? ConnectivityState.connected
        : ConnectivityState.disconnected;

    state = state.copyWith(connectivityState: connectivityState);
  }

  /// Update ID number input
  void updateIdNumber(String value) {
    state = state.copyWith(idNumberInput: value);
  }

  /// Update ID type input (NIN, Passport, etc.)
  void updateIdType(String value) {
    state = state.copyWith(idTypeInput: value);
  }

  /// Update front image path
  void updateFrontImage(String path) {
    final updatedIdentification = state.identification.copyWith(
      frontImagePath: path,
    );
    state = state.copyWith(identification: updatedIdentification);
  }

  /// Update back image path
  void updateBackImage(String path) {
    final updatedIdentification = state.identification.copyWith(
      backImagePath: path,
    );
    state = state.copyWith(identification: updatedIdentification);
  }

  /// Mark ID verification as complete
  void markIdVerified() {
    final updatedIdentification = state.identification.copyWith(
      isIdVerified: true,
      isIdentityVerified: true,
      idType: state.idTypeInput,
      idNumber: state.idNumberInput,
    );
    state = state.copyWith(identification: updatedIdentification);
    // Persist the verified status
    _persistVerificationStatus();
  }

  /// Persist verification status to local storage
  Future<void> _persistVerificationStatus() async {
    try {
      final hiveService = HiveService.instance;
      await hiveService.setMap('identity_verification', {
        'isIdentityVerified': state.identification.isIdentityVerified,
        'skippedVerification': state.identification.skippedVerification,
        'skippedAt': state.identification.skippedAt?.toIso8601String(),
        'idType': state.identification.idType,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      // Silently fail - local storage is best effort
      debugPrint('Failed to persist verification status: $e');
    }
  }

  /// Load persisted verification status
  Future<void> loadPersistedVerificationStatus() async {
    try {
      final hiveService = HiveService.instance;
      final data = hiveService.getMap('identity_verification');
      if (data != null) {
        final skippedAt = data['skippedAt'] != null
            ? DateTime.tryParse(data['skippedAt'] as String)
            : null;
        final updatedIdentification = state.identification.copyWith(
          isIdentityVerified: data['isIdentityVerified'] as bool? ?? false,
          skippedVerification: data['skippedVerification'] as bool? ?? false,
          skippedAt: skippedAt,
          idType: data['idType'] as String?,
        );
        state = state.copyWith(identification: updatedIdentification);
      }
    } catch (e) {
      // Silently fail
      debugPrint('Failed to load verification status: $e');
    }
  }

  /// Mark business verification as complete (for providers)
  void markBusinessVerified() {
    final updatedIdentification = state.identification.copyWith(
      isBusinessVerified: true,
    );
    state = state.copyWith(identification: updatedIdentification);
  }

  /// Set loading state
  void setLoading(bool isLoading) {
    state = state.copyWith(isLoading: isLoading);
  }

  /// Set error message
  void setError(String? error) {
    state = state.copyWith(errorMessage: error);
  }

  /// Mark form as submitted (triggers validation display)
  void markFormSubmitted() {
    state = state.copyWith(isFormSubmitted: true);
  }

  /// Submit identification form
  Future<bool> submit() async {
    markFormSubmitted();

    // Check connectivity first
    if (state.connectivityState == ConnectivityState.disconnected) {
      setError(
        'No internet connection. Please check your network and try again.',
      );
      return false;
    }

    // Validate ID number
    final validationResult = state.validateIdNumber();
    if (!validationResult.isValid) {
      return false;
    }

    // Check if images are uploaded
    if (state.identification.frontImagePath == null ||
        state.identification.backImagePath == null) {
      setError('Please upload both front and back of your ID document.');
      return false;
    }

    setLoading(true);
    setError(null);

    try {
      // Upload front document
      final frontSuccess = await ref
          .read(authProvider.notifier)
          .uploadIdDocumentFront(
            idNumber: state.idNumberInput!,
            documentFront: File(state.identification.frontImagePath!),
          );

      if (!frontSuccess) {
        setError('Failed to upload front ID document.');
        setLoading(false);
        return false;
      }

      // Upload back document
      final backSuccess = await ref
          .read(authProvider.notifier)
          .uploadIdDocumentBack(
            idNumber: state.idNumberInput!,
            documentBack: File(state.identification.backImagePath!),
          );

      if (!backSuccess) {
        setError('Failed to upload back ID document.');
        setLoading(false);
        return false;
      }

      // Update identification with ID number and submission time
      final updatedIdentification = state.identification.copyWith(
        idNumber: state.idNumberInput,
        submittedAt: DateTime.now(),
        isIdVerified: true,
      );

      state = state.copyWith(
        identification: updatedIdentification,
        isLoading: false,
      );

      return true;
    } catch (e) {
      setError('Failed to submit identification. Please try again.');
      setLoading(false);
      return false;
    }
  }

  /// Skip verification for now (temporarily)
  void skipVerification() {
    state = state.copyWith(isFormSubmitted: false, errorMessage: null);
  }

  /// Permanently skip verification (user chose to skip)
  Future<void> permanentlySkipVerification() async {
    final updatedIdentification = state.identification.copyWith(
      skippedVerification: true,
      skippedAt: DateTime.now(),
    );
    state = state.copyWith(
      identification: updatedIdentification,
      isFormSubmitted: false,
      errorMessage: null,
    );
    await _persistVerificationStatus();
  }

  /// Check if user should be reminded about pending verification
  bool shouldRemindVerification() {
    // Don't remind if:
    // 1. Already verified
    if (state.identification.isIdentityVerified) return false;

    // 2. User chose to permanently skip
    if (state.identification.skippedVerification) return false;

    // 3. User temporarily skipped (show reminder)
    return true;
  }

  /// Reset state to initial
  void reset() {
    state = const IdentificationPageState();
    _initConnectivity();
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }
}

/// Provider for identification page state
final identificationProvider =
    StateNotifierProvider<IdentificationNotifier, IdentificationPageState>((
      ref,
    ) {
      // Try to get network info from service locator if available
      NetworkInfo? networkInfo;
      try {
        // This would typically come from your dependency injection
        // For now, we'll create a default instance
        networkInfo = NetworkInfoImpl(connectivity: Connectivity());
      } catch (e) {
        networkInfo = null;
      }

      return IdentificationNotifier(networkInfo: networkInfo, ref: ref);
    });
