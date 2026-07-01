import 'package:checks/checks.dart';
import 'package:crudo/ui/core/themes/theme.dart';
import 'package:crudo/ui/core/widgets/macro_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) => MaterialApp(
  theme: crudoTheme,
  home: Scaffold(body: child),
);

void main() {
  testWidgets('renders a dot in the given color and rounded grams text', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(const MacroChip(grams: 32.4, color: Colors.red)),
    );

    expect(find.text('32g'), findsOneWidget);

    final dot = tester
        .widgetList<Container>(find.byType(Container))
        .firstWhere(
          (c) =>
              c.decoration is BoxDecoration &&
              (c.decoration as BoxDecoration).shape == BoxShape.circle,
        );
    check((dot.decoration as BoxDecoration).color).equals(Colors.red);
  });
}
