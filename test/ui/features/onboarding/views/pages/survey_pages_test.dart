import 'package:checks/checks.dart';
import 'package:crudo/ui/core/themes/theme.dart';
import 'package:crudo/ui/core/widgets/primary_cta.dart';
import 'package:crudo/ui/features/onboarding/views/pages/heard_about_page.dart';
import 'package:crudo/ui/features/onboarding/views/pages/tried_apps_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pump(WidgetTester t, Widget c) =>
      t.pumpWidget(MaterialApp(theme: crudoTheme, home: c));

  testWidgets('heard-about: select fires onSelect; continue gated then fires', (
    t,
  ) async {
    String? picked;
    var cont = false;
    // initially unselected -> continue disabled (no callback on tap)
    await pump(
      t,
      HeardAboutPage(
        selected: null,
        onSelect: (id) => picked = id,
        onContinue: () => cont = true,
        onBack: () {},
      ),
    );
    await t.tap(find.widgetWithText(PrimaryCta, 'Continue'));
    check(cont).isFalse();
    await t.tap(find.text('TikTok'));
    check(picked).equals('tiktok');

    // re-pump as if host passed the new selection -> continue now enabled
    await pump(
      t,
      HeardAboutPage(
        selected: 'tiktok',
        onSelect: (_) {},
        onContinue: () => cont = true,
        onBack: () {},
      ),
    );
    await t.tap(find.widgetWithText(PrimaryCta, 'Continue'));
    check(cont).isTrue();
  });

  testWidgets('tried-apps renders options with subs', (t) async {
    String? picked;
    await pump(
      t,
      TriedAppsPage(
        selected: null,
        onSelect: (id) => picked = id,
        onContinue: () {},
        onBack: () {},
      ),
    );
    check(find.text('MyFitnessPal').evaluate()).isNotEmpty();
    check(find.text('Calorie & macro logger').evaluate()).isNotEmpty();
    await t.tap(find.text('Noom'));
    check(picked).equals('noom');
  });
}
