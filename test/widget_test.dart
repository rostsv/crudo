import 'package:checks/checks.dart';
import 'package:crudo/app.dart';
import 'package:crudo/config/app_config.dart';
import 'package:crudo/ui/core/themes/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Flavor flavor) => ProviderScope(
  overrides: [appConfigProvider.overrideWithValue(AppConfig(flavor: flavor))],
  child: const CrudoApp(),
);

void main() {
  testWidgets('boots into Today tab', (tester) async {
    await tester.pumpWidget(_wrap(Flavor.prod));
    await tester.pumpAndSettle();

    expect(find.text('Today'), findsWidgets);

    final ctx = tester.element(find.text('Today').first);
    check(Theme.of(ctx).colorScheme.primary).equals(const Color(0xFF004D49));
    check(Theme.of(ctx).extension<CrudoColors>()).isNotNull();
  });

  testWidgets('prod build shows no dev marker', (tester) async {
    await tester.pumpWidget(_wrap(Flavor.prod));
    await tester.pumpAndSettle();
    expect(find.text('Crudo Dev'), findsNothing);
  });

  testWidgets('dev build shows the dev marker', (tester) async {
    await tester.pumpWidget(_wrap(Flavor.dev));
    await tester.pumpAndSettle();
    expect(find.text('Crudo Dev'), findsOneWidget);
  });
}
