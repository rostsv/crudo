import 'package:checks/checks.dart';
import 'package:crudo/ui/core/themes/theme.dart';
import 'package:crudo/ui/core/widgets/primary_cta.dart';
import 'package:crudo/ui/features/onboarding/views/onboarding_flow_screen.dart';
import 'package:crudo/ui/features/onboarding/views/pages/awareness_page.dart';
import 'package:crudo/ui/features/onboarding/views/pages/heard_about_page.dart';
import 'package:crudo/ui/features/onboarding/views/pages/structure_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pump(WidgetTester t) => t.pumpWidget(
    ProviderScope(
      child: MaterialApp(theme: crudoTheme, home: const OnboardingFlowScreen()),
    ),
  );

  // A PageView builds the cached neighbour page too, so several pages can hold
  // a "Continue" PrimaryCta at once. Scope the tap to the visible page's type
  // rather than a bare find.widgetWithText(PrimaryCta, 'Continue') (matches >1
  // once the flow grows in S17).
  Finder ctaOn(Type page, String label) => find.descendant(
    of: find.byType(page),
    matching: find.widgetWithText(PrimaryCta, label),
  );

  testWidgets('advances Welcome → … → terminal via CTAs', (t) async {
    await pump(t);
    check(find.textContaining('Follow your meal plan').evaluate()).isNotEmpty();

    await t.tap(find.widgetWithText(PrimaryCta, 'Set up my plan'));
    await t.pumpAndSettle();
    check(find.text('You already know the plan.').evaluate()).isNotEmpty();

    await t.tap(ctaOn(AwarenessPage, 'Continue'));
    await t.pumpAndSettle();
    check(find.text('Structure beats willpower.').evaluate()).isNotEmpty();

    await t.tap(ctaOn(StructurePage, 'Continue'));
    await t.pumpAndSettle();
    check(find.text('See how Crudo works').evaluate()).isNotEmpty();

    await t.tap(find.widgetWithText(PrimaryCta, 'Watch & Continue'));
    await t.pumpAndSettle();
    check(find.text('Turn your plan into a routine.').evaluate()).isNotEmpty();

    await t.tap(find.widgetWithText(PrimaryCta, 'Build my plan'));
    await t.pumpAndSettle();
    check(find.text('Where did you hear about Crudo?').evaluate()).isNotEmpty();

    await t.tap(find.text('TikTok'));
    await t.pumpAndSettle();
    await t.tap(ctaOn(HeardAboutPage, 'Continue'));
    await t.pumpAndSettle();
    check(
      find.text('Tried something like this before?').evaluate(),
    ).isNotEmpty();
  });

  testWidgets('back from Awareness returns to Welcome', (t) async {
    await pump(t);
    await t.tap(find.widgetWithText(PrimaryCta, 'Set up my plan'));
    await t.pumpAndSettle();
    await t.tap(find.byIcon(Icons.arrow_back_ios_new));
    await t.pumpAndSettle();
    check(find.textContaining('Follow your meal plan').evaluate()).isNotEmpty();
  });

  testWidgets('heard-about Continue gated until a selection', (t) async {
    await pump(t);
    // jump to heard-about
    await t.tap(find.widgetWithText(PrimaryCta, 'Set up my plan'));
    await t.pumpAndSettle();
    await t.tap(ctaOn(AwarenessPage, 'Continue'));
    await t.pumpAndSettle();
    await t.tap(ctaOn(StructurePage, 'Continue'));
    await t.pumpAndSettle();
    await t.tap(find.widgetWithText(PrimaryCta, 'Watch & Continue'));
    await t.pumpAndSettle();
    await t.tap(find.widgetWithText(PrimaryCta, 'Build my plan'));
    await t.pumpAndSettle();
    // no selection → Continue does nothing
    await t.tap(ctaOn(HeardAboutPage, 'Continue'));
    await t.pumpAndSettle();
    check(
      find.text('Where did you hear about Crudo?').evaluate(),
    ).isNotEmpty(); // still here
    await t.tap(find.text('Reddit'));
    await t.pumpAndSettle();
    await t.tap(ctaOn(HeardAboutPage, 'Continue'));
    await t.pumpAndSettle();
    check(
      find.text('Tried something like this before?').evaluate(),
    ).isNotEmpty();
  });

  testWidgets('sign-in stub shows a toast without navigating', (t) async {
    await pump(t);
    await t.tap(find.text('I already have an account'));
    await t.pump(); // toast inserts on the overlay
    check(find.text('Sign-in coming soon').evaluate()).isNotEmpty();
    // still on Welcome — the stub must not navigate
    check(find.textContaining('Follow your meal plan').evaluate()).isNotEmpty();
    // flush the toast auto-dismiss timer so the test ends clean
    await t.pump(const Duration(seconds: 5));
  });
}
