import 'package:flutter_riverpod/flutter_riverpod.dart';

// Export ConnectivityState from identification_provider for shared use
export 'identification_provider.dart' show ConnectivityState;

enum UserRole { user, individualProvider, businessProvider }

enum OtpState { neutral, error, success }

// Helper extension to handle display logic
extension UserRoleX on UserRole {
  String get displayName {
    switch (this) {
      case UserRole.user:
        return "Register User Account";
      case UserRole.individualProvider:
        return "Individual Service Provider";
      case UserRole.businessProvider:
        return "Business Service Provider";
    }
  }

  bool get isProvider => this != UserRole.user;
}

enum SignupSelectionLevel { initial, providerType, registration, otp, profile }

class SignupState {
  final UserRole selectedRole;
  final SignupSelectionLevel currentLevel;
  final OtpState otpState;
  final String? email;
  final String? password;
  final String? displayName;
  final String? phone;
  final String? address;
  final String? businessName;
  final String? businessDescription;
  final String? country;
  final bool isLoading;
  final String? errorMessage;

  SignupState({
    this.selectedRole = UserRole.user,
    this.currentLevel = SignupSelectionLevel.initial,
    this.otpState = OtpState.neutral,
    this.email,
    this.password,
    this.displayName,
    this.phone,
    this.address,
    this.businessName,
    this.businessDescription,
    this.country,
    this.isLoading = false,
    this.errorMessage,
  });

  SignupState copyWith({
    UserRole? selectedRole,
    SignupSelectionLevel? currentLevel,
    OtpState? otpState,
    String? email,
    String? password,
    String? displayName,
    String? phone,
    String? address,
    String? businessName,
    String? businessDescription,
    String? country,
    bool? isLoading,
    String? errorMessage,
  }) {
    return SignupState(
      selectedRole: selectedRole ?? this.selectedRole,
      currentLevel: currentLevel ?? this.currentLevel,
      otpState: otpState ?? this.otpState,
      email: email ?? this.email,
      password: password ?? this.password,
      displayName: displayName ?? this.displayName,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      businessName: businessName ?? this.businessName,
      businessDescription: businessDescription ?? this.businessDescription,
      country: country ?? this.country,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }

  /// Check if the signup state has valid registration data
  bool get hasValidRegistrationData {
    return email != null &&
        email!.isNotEmpty &&
        password != null &&
        password!.isNotEmpty;
  }

  /// Check if the signup state has valid profile data
  bool get hasValidProfileData {
    return displayName != null &&
        displayName!.isNotEmpty &&
        phone != null &&
        phone!.isNotEmpty &&
        address != null &&
        address!.isNotEmpty &&
        country != null &&
        country!.isNotEmpty;
  }
}

class SignupNotifier extends StateNotifier<SignupState> {
  SignupNotifier() : super(SignupState());

  void selectRole(UserRole role) {
    state = state.copyWith(selectedRole: role);
  }

  void goToProviderSelection() {
    state = state.copyWith(
      currentLevel: SignupSelectionLevel.providerType,
      selectedRole: UserRole.individualProvider,
    );
  }

  void goBackToInitial() {
    state = state.copyWith(
      currentLevel: SignupSelectionLevel.initial,
      selectedRole: UserRole.user,
    );
  }

  void updateOtpState(OtpState otpState) {
    state = state.copyWith(otpState: otpState);
  }

  void updateRegistrationInfo({
    required String email,
    required String password,
  }) {
    state = state.copyWith(email: email, password: password);
  }

  void updateProfileInfo({
    String? displayName,
    String? phone,
    String? address,
    String? businessName,
    String? businessDescription,
    String? country,
  }) {
    state = state.copyWith(
      displayName: displayName,
      phone: phone,
      address: address,
      businessName: businessName,
      businessDescription: businessDescription,
      country: country,
    );
  }

  void goToRegistration() {
    state = state.copyWith(currentLevel: SignupSelectionLevel.registration);
  }

  void goBackFromRegistration() {
    if (state.selectedRole == UserRole.user) {
      state = state.copyWith(currentLevel: SignupSelectionLevel.initial);
    } else {
      state = state.copyWith(currentLevel: SignupSelectionLevel.providerType);
    }
  }

  void goToProfile() {
    state = state.copyWith(currentLevel: SignupSelectionLevel.profile);
  }

  void goToOtp() {
    state = state.copyWith(currentLevel: SignupSelectionLevel.otp);
  }

  void resetToInitial() {
    state = SignupState();
  }

  void signOut() {
    state = SignupState();
  }

  /// Set loading state
  void setLoading(bool isLoading) {
    state = state.copyWith(isLoading: isLoading);
  }

  /// Set error message
  void setError(String? error) {
    state = state.copyWith(errorMessage: error);
  }

  /// Clear error message
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  /// Validate registration data
  bool validateRegistrationData() {
    if (!state.hasValidRegistrationData) {
      setError('Please provide both email and password');
      return false;
    }
    clearError();
    return true;
  }

  /// Validate profile data
  bool validateProfileData() {
    if (!state.hasValidProfileData) {
      setError('Please complete all required profile fields');
      return false;
    }
    clearError();
    return true;
  }
}

final signupProvider = StateNotifierProvider<SignupNotifier, SignupState>(
  (ref) => SignupNotifier(),
);
