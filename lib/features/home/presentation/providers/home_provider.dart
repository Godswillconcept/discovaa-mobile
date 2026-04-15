import 'package:flutter_riverpod/flutter_riverpod.dart';

enum VerificationStatus { none, pending, verified }

class HomeState {
  final int bottomNavIndex;
  final VerificationStatus verificationStatus;
  final bool isConfirmed;

  HomeState({
    this.bottomNavIndex = 0,
    this.verificationStatus = VerificationStatus.none,
    this.isConfirmed = false,
  });

  HomeState copyWith({
    int? bottomNavIndex,
    VerificationStatus? verificationStatus,
    bool? isConfirmed,
  }) {
    return HomeState(
      bottomNavIndex: bottomNavIndex ?? this.bottomNavIndex,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      isConfirmed: isConfirmed ?? this.isConfirmed,
    );
  }
}

final homeProvider = StateNotifierProvider<HomeNotifier, HomeState>(
  (ref) => HomeNotifier(),
);

class HomeNotifier extends StateNotifier<HomeState> {
  HomeNotifier() : super(HomeState());

  void setNavIndex(int index) => state = state.copyWith(bottomNavIndex: index);
  void updateIsConfirmed(bool value) =>
      state = state.copyWith(isConfirmed: value);
  void completeVerification() =>
      state = state.copyWith(verificationStatus: VerificationStatus.verified);
}
