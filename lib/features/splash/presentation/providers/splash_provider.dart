import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'splash_provider.g.dart';

@riverpod
class SplashNotifier extends _$SplashNotifier {
  @override
  FutureOr<void> build() async {
    // Initial delay for the first logo size
    await Future.delayed(const Duration(milliseconds: 800));
    // The screen itself will handle the animation/scaling
  }
}
