import 'package:checks/checks.dart';
import 'package:crudo/ui/core/themes/theme.dart';
import 'package:crudo/ui/core/widgets/primary_cta.dart';
import 'package:crudo/ui/features/onboarding/views/pages/awareness_page.dart';
import 'package:crudo/ui/features/onboarding/views/pages/structure_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pump(WidgetTester t, Widget c) =>
      t.pumpWidget(MaterialApp(theme: crudoTheme, home: c));

  testWidgets('awareness renders copy + continue/back fire', (t) async {
    var cont = false, back = false;
    await pump(
      t,
      AwarenessPage(onContinue: () => cont = true, onBack: () => back = true),
    );
    check(find.text('You already know the plan.').evaluate()).isNotEmpty();
    check(find.text('Decision Fatigue').evaluate()).isNotEmpty();
    await t.tap(find.widgetWithText(PrimaryCta, 'Continue'));
    check(cont).isTrue();
    await t.tap(find.byIcon(Icons.arrow_back_ios_new));
    check(back).isTrue();
  });

  testWidgets('structure renders both columns', (t) async {
    await pump(t, StructurePage(onContinue: () {}, onBack: () {}));
    check(find.text('Structure beats willpower.').evaluate()).isNotEmpty();
    check(find.text('WITHOUT STRUCTURE').evaluate()).isNotEmpty();
    check(find.text('WITH CRUDO').evaluate()).isNotEmpty();
  });
}
