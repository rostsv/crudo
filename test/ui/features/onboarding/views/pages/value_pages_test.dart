import 'package:checks/checks.dart';
import 'package:crudo/ui/core/themes/theme.dart';
import 'package:crudo/ui/core/widgets/primary_cta.dart';
import 'package:crudo/ui/features/onboarding/views/pages/transformation_page.dart';
import 'package:crudo/ui/features/onboarding/views/pages/video_demo_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pump(WidgetTester t, Widget c) =>
      t.pumpWidget(MaterialApp(theme: crudoTheme, home: c));

  testWidgets('video demo play tap fires onPlay, continue fires', (t) async {
    var played = false, cont = false;
    await pump(
      t,
      VideoDemoPage(
        onPlay: () => played = true,
        onContinue: () => cont = true,
        onBack: () {},
      ),
    );
    check(find.text('See how Crudo works').evaluate()).isNotEmpty();
    await t.ensureVisible(find.byKey(const ValueKey('demo-play')));
    await t.tap(find.byKey(const ValueKey('demo-play')));
    check(played).isTrue();
    await t.tap(find.widgetWithText(PrimaryCta, 'Watch & Continue'));
    check(cont).isTrue();
  });

  testWidgets('transformation renders stats + features', (t) async {
    await pump(t, TransformationPage(onContinue: () {}, onBack: () {}));
    check(find.text('Turn your plan into a routine.').evaluate()).isNotEmpty();
    check(find.text('Smart reminders').evaluate()).isNotEmpty();
    check(find.textContaining('87%').evaluate()).isNotEmpty();
  });
}
