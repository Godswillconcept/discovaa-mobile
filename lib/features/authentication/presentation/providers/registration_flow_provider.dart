import 'package:flutter_riverpod/flutter_riverpod.dart';

/// User role enumeration
enum UserRole { user, individualProvider, businessProvider }

/// Helper extension to handle display logic for UserRole
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

  String get name {
    switch (this) {
      case UserRole.user:
        return "USER";
      case UserRole.individualProvider:
        return "INDIVIDUAL";
      case UserRole.businessProvider:
        return "BUSINESS";
    }
  }

  bool get isProvider => this != UserRole.user;
}

/// OTP verification state
enum OtpState { neutral, error, success }

/// Registration steps for tracking progress
enum RegistrationStep {
  initial,
  roleSelection,
  credentials,
  otpVerification,
  profileCompletion,
  identification,
}

/// Temporary state for registration flow only
/// Cleared immediately after successful registration
class RegistrationFlowState {
  final String? email;
  final UserRole? selectedRole;
  final String? otpEmail; // Email being verified
  final RegistrationStep currentStep;

  const RegistrationFlowState({
    this.email,
    this.selectedRole,
    this.otpEmail,
    this.currentStep = RegistrationStep.initial,
  });

  RegistrationFlowState copyWith({
    String? email,
    UserRole? selectedRole,
    String? otpEmail,
    RegistrationStep? currentStep,
  }) {
    return RegistrationFlowState(
      email: email ?? this.email,
      selectedRole: selectedRole ?? this.selectedRole,
      otpEmail: otpEmail ?? this.otpEmail,
      currentStep: currentStep ?? this.currentStep,
    );
  }

  @override
  String toString() {
    return 'RegistrationFlowState(step: $currentStep, email: $email, role: $selectedRole)';
  }
}

/// Notifier for managing temporary registration flow state
class RegistrationFlowNotifier extends StateNotifier<RegistrationFlowState> {
  RegistrationFlowNotifier() : super(const RegistrationFlowState());

  /// Set the selected role and move to credentials step
  void setRole(UserRole role) {
    state = state.copyWith(
      selectedRole: role,
      currentStep: RegistrationStep.credentials,
    );
  }

  /// Set email for registration and OTP verification
  void setEmail(String email) {
    state = state.copyWith(email: email, otpEmail: email);
  }

  /// Move to OTP verification step
  void moveToOtpVerification() {
    state = state.copyWith(currentStep: RegistrationStep.otpVerification);
  }

  /// Move to profile completion step
  void moveToProfileCompletion() {
    state = state.copyWith(currentStep: RegistrationStep.profileCompletion);
  }

  /// Move to identification step (for providers)
  void moveToIdentification() {
    state = state.copyWith(currentStep: RegistrationStep.identification);
  }

  /// Reset to initial step
  void reset() {
    state = const RegistrationFlowState();
  }

  /// Clear all registration flow state
  void clear() {
    state = const RegistrationFlowState();
  }
}

/// Provider that auto-disposes after registration
/// This ensures temporary registration data is cleared when the provider is disposed
final registrationFlowProvider =
    StateNotifierProvider.autoDispose<
      RegistrationFlowNotifier,
      RegistrationFlowState
    >((ref) => RegistrationFlowNotifier());
