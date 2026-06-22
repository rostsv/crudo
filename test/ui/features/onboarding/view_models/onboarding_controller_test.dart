import 'package:checks/checks.dart';
import 'package:crudo/ui/features/onboarding/view_models/onboarding_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late ProviderContainer container;
  setUp(() => container = ProviderContainer());
  tearDown(() => container.dispose());

  OnboardingController ctrl() =>
      container.read(onboardingControllerProvider.notifier);
  OnboardingState state() => container.read(onboardingControllerProvider);

  test('initial state is page 0 with no selections', () {
    check(state().pageIndex).equals(0);
    check(state().source).isNull();
    check(state().tried).isNull();
  });

  test('next / back move pageIndex', () {
    ctrl().next();
    check(state().pageIndex).equals(1);
    ctrl().next();
    ctrl().back();
    check(state().pageIndex).equals(1);
  });

  test('setSource / setTried record ids', () {
    ctrl().setSource('tiktok');
    ctrl().setTried('mfp');
    check(state().source).equals('tiktok');
    check(state().tried).equals('mfp');
  });
}
