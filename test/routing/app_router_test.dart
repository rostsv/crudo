import 'package:checks/checks.dart';
import 'package:crudo/app.dart';
import 'package:crudo/config/app_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app({Flavor flavor = Flavor.prod}) => ProviderScope(
  overrides: [appConfigProvider.overrideWithValue(AppConfig(flavor: flavor))],
  child: const CrudoApp(),
);

void main() {
  testWidgets('boots into Today tab', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    expect(find.text('Today'), findsWidgets); // title + nav label
  });

  testWidgets('bottom nav switches all four branches', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    for (final label in ['Plans', 'History', 'Profile', 'Today']) {
      await tester.tap(find.byKey(ValueKey('nav-$label')));
      await tester.pumpAndSettle();
      expect(find.text(label), findsWidgets);
    }
  });

  testWidgets('dev marker only on dev flavor', (tester) async {
    await tester.pumpWidget(_app(flavor: Flavor.dev));
    await tester.pumpAndSettle();
    expect(find.text('Crudo Dev'), findsOneWidget);

    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    expect(find.text('Crudo Dev'), findsNothing);
  });

  testWidgets('no 1px border on the nav bar', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    final containers = tester.widgetList<Container>(find.byType(Container));
    for (final c in containers) {
      final deco = c.decoration;
      if (deco is BoxDecoration && deco.border != null) {
        fail('found a Border in the shell — no-line rule violated');
      }
    }
    check(true).isTrue();
  });

  testWidgets('tab state is preserved across branch switches', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('nav-History')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('demo-counter')));
    await tester.tap(find.byKey(const ValueKey('demo-counter')));
    await tester.pumpAndSettle();
    expect(find.text('Taps: 2'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('nav-Today')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('nav-History')));
    await tester.pumpAndSettle();
    expect(find.text('Taps: 2'), findsOneWidget); // survived the round-trip
  });
}
