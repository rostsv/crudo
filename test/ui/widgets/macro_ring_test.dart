import 'package:crudo/ui/core/themes/theme.dart';
import 'package:crudo/ui/core/widgets/macro_ring.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) => MaterialApp(
  theme: crudoTheme,
  home: Scaffold(body: Center(child: child)),
);

void main() {
  testWidgets('paints and shows center label', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const MacroRing(
          protein: 120,
          carbs: 200,
          fats: 60,
          centerLabel: '2 040',
        ),
      ),
    );
    expect(find.byType(CustomPaint), findsWidgets);
    expect(find.text('2 040'), findsOneWidget);
  });

  testWidgets('all-zero input still renders (track only)', (tester) async {
    await tester.pumpWidget(
      _wrap(const MacroRing(protein: 0, carbs: 0, fats: 0)),
    );
    expect(find.byType(MacroRing), findsOneWidget);
  });
}
