import 'package:flutter_riverpod/flutter_riverpod.dart';

enum VerificationStep {
  idFront,
  idFrontSuccess,
  idBack,
  idBackSuccess,
  businessFront,
  businessFrontSuccess,
  completed,
}

class VerificationState {
  final bool idVerified;
  final bool businessVerified;
  final VerificationStep currentStep;

  const VerificationState({
    this.idVerified = false,
    this.businessVerified = false,
    this.currentStep = VerificationStep.idFront,
  });

  VerificationState copyWith({
    bool? idVerified,
    bool? businessVerified,
    VerificationStep? currentStep,
  }) {
    return VerificationState(
      idVerified: idVerified ?? this.idVerified,
      businessVerified: businessVerified ?? this.businessVerified,
      currentStep: currentStep ?? this.currentStep,
    );
  }
}

class VerificationNotifier extends StateNotifier<VerificationState> {
  VerificationNotifier() : super(const VerificationState());

  void next() {
    switch (state.currentStep) {
      case VerificationStep.idFront:
        state = state.copyWith(currentStep: VerificationStep.idFrontSuccess);
        break;
      case VerificationStep.idFrontSuccess:
        state = state.copyWith(currentStep: VerificationStep.idBack);
        break;
      case VerificationStep.idBack:
        state = state.copyWith(currentStep: VerificationStep.idBackSuccess);
        break;
      case VerificationStep.idBackSuccess:
        state = state.copyWith(
          idVerified: true,
          currentStep: VerificationStep.completed,
        );
        break;
      case VerificationStep.businessFront:
        state = state.copyWith(
          currentStep: VerificationStep.businessFrontSuccess,
        );
        break;
      case VerificationStep.businessFrontSuccess:
        state = state.copyWith(
          businessVerified: true,
          currentStep: VerificationStep.completed,
        );
        break;
      default:
        break;
    }
  }

  void startIdVerification() =>
      state = state.copyWith(currentStep: VerificationStep.idFront);
  void startBusinessVerification() =>
      state = state.copyWith(currentStep: VerificationStep.businessFront);
  void reset() => state = state.copyWith(currentStep: VerificationStep.idFront);
}

final verificationProvider =
    StateNotifierProvider<VerificationNotifier, VerificationState>(
      (ref) => VerificationNotifier(),
    );
