import 'package:checks/checks.dart';
import 'package:crudo/domain/shared/enums.dart';
import 'package:crudo/ui/core/themes/theme.dart';
import 'package:crudo/ui/core/widgets/meal_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) => MaterialApp(
  theme: crudoTheme,
  home: Scaffold(body: child),
);

void main() {
  testWidgets('renders content for every status without "½" text', (
    tester,
  ) async {
    for (final status in MealStatus.values) {
      await tester.pumpWidget(
        _wrap(
          MealCard(
            title: 'Breakfast',
            timeLabel: '08:00',
            kcalLabel: '420 kcal',
            status: status,
          ),
        ),
      );
      expect(find.text('Breakfast'), findsOneWidget);
      expect(find.text('08:00 · 420 kcal'), findsOneWidget);
      expect(find.textContaining('½'), findsNothing);
      expect(
        find.byKey(ValueKey('meal-status-${status.name}')),
        findsOneWidget,
      );
    }
  });

  testWidgets('tap fires when provided', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      _wrap(
        MealCard(
          title: 'Lunch',
          timeLabel: '12:30',
          kcalLabel: '650 kcal',
          status: MealStatus.upcoming,
          onTap: () => taps++,
        ),
      ),
    );
    await tester.tap(find.text('Lunch'));
    check(taps).equals(1);
  });
}
