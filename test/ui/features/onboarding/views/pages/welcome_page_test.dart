import 'package:checks/checks.dart';
import 'package:crudo/ui/core/themes/theme.dart';
import 'package:crudo/ui/core/widgets/primary_cta.dart';
import 'package:crudo/ui/features/onboarding/views/pages/welcome_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders headline and fires both callbacks', (t) async {
    var setUp = false, signIn = false;
    await t.pumpWidget(
      MaterialApp(
        theme: crudoTheme,
        home: WelcomePage(
          onSetUp: () => setUp = true,
          onSignIn: () => signIn = true,
        ),
      ),
    );
    check(find.textContaining('Follow your meal plan').evaluate()).isNotEmpty();

    await t.tap(find.widgetWithText(PrimaryCta, 'Set up my plan'));
    check(setUp).isTrue();

    await t.tap(find.text('I already have an account'));
    check(signIn).isTrue();
  });
}
