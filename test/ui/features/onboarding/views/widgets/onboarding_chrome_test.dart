import 'package:checks/checks.dart';
import 'package:crudo/ui/core/themes/theme.dart';
import 'package:crudo/ui/features/onboarding/views/widgets/onboarding_progress.dart';
import 'package:crudo/ui/features/onboarding/views/widgets/onboarding_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pump(WidgetTester t, Widget child) =>
      t.pumpWidget(MaterialApp(theme: crudoTheme, home: child));

  testWidgets('progress renders `total` dots', (t) async {
    await pump(t, const Scaffold(body: OnboardingProgress(step: 2, total: 6)));
    check(find.byType(AnimatedContainer).evaluate().length).equals(6);
  });

  testWidgets('scaffold shows wordmark when step is null, no back button', (
    t,
  ) async {
    await pump(
      t,
      const OnboardingScaffold(
        step: null,
        body: SizedBox(),
        footer: SizedBox(),
      ),
    );
    check(find.text('Crudo').evaluate()).isNotEmpty();
    check(find.byIcon(Icons.arrow_back_ios_new).evaluate()).isEmpty();
  });

  testWidgets(
    'scaffold shows back button + dots when step set and onBack given',
    (t) async {
      var backed = false;
      await pump(
        t,
        OnboardingScaffold(
          step: 1,
          onBack: () => backed = true,
          body: const SizedBox(),
          footer: const SizedBox(),
        ),
      );
      check(find.byType(OnboardingProgress).evaluate()).isNotEmpty();
      await t.tap(find.byIcon(Icons.arrow_back_ios_new));
      check(backed).isTrue();
    },
  );
}
