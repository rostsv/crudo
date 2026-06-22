import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'onboarding_controller.freezed.dart';
part 'onboarding_controller.g.dart';

@freezed
abstract class OnboardingState with _$OnboardingState {
  const factory OnboardingState({
    @Default(0) int pageIndex,
    String? source,
    String? tried,
  }) = _OnboardingState;
}

@riverpod
class OnboardingController extends _$OnboardingController {
  @override
  OnboardingState build() => const OnboardingState();

  void next() => state = state.copyWith(pageIndex: state.pageIndex + 1);
  void back() => state = state.copyWith(pageIndex: state.pageIndex - 1);
  void setSource(String id) => state = state.copyWith(source: id);
  void setTried(String id) => state = state.copyWith(tried: id);
}
