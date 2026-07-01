import 'package:checks/checks.dart';
import 'package:crudo/domain/shared/meal_time.dart';
import 'package:crudo/ui/core/themes/theme.dart';
import 'package:crudo/ui/features/today/views/day_strip.dart';
import 'package:crudo/ui/features/today/views/formatting.dart';
import 'package:crudo/ui/features/today/views/nudge_card.dart';
import 'package:crudo/ui/features/today/views/streak_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) => MaterialApp(
  theme: crudoTheme,
  home: Scaffold(body: child),
);

void main() {
  group('formatting', () {
    test('mealTimeLabel pads', () {
      check(mealTimeLabel(const MealTime(8 * 60))).equals('08:00');
      check(mealTimeLabel(const MealTime(12 * 60 + 30))).equals('12:30');
    });
    test('dateHeadline', () {
      check(dateHeadline(DateTime.utc(2026, 6, 4))).equals('Thursday, June 4');
    });
    test('greeting buckets + nameless fallback', () {
      check(
        greetingFor(DateTime(2026, 6, 4, 9), 'Mark'),
      ).equals('Good morning, Mark');
      check(
        greetingFor(DateTime(2026, 6, 4, 14), 'Mark'),
      ).equals('Good afternoon, Mark');
      check(greetingFor(DateTime(2026, 6, 4, 20), null)).equals('Good evening');
    });
    test('weekOf returns Mon..Sun containing the label', () {
      final week = weekOf(DateTime.utc(2026, 6, 4)); // Thursday
      check(week.length).equals(7);
      check(week.first).equals(DateTime.utc(2026, 6, 1)); // Monday
      check(week.last).equals(DateTime.utc(2026, 6, 7)); // Sunday
    });
  });

  testWidgets('DayStrip renders 7 pills, fires onSelect', (tester) async {
    DateTime? tapped;
    final week = weekOf(DateTime.utc(2026, 6, 4));
    await tester.pumpWidget(
      _wrap(
        DayStrip(
          dates: week,
          selected: DateTime.utc(2026, 6, 4),
          today: DateTime.utc(2026, 6, 4),
          onSelect: (d) => tapped = d,
        ),
      ),
    );
    expect(find.byKey(const ValueKey('day-pill-2026-06-06')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('day-pill-2026-06-06')));
    check(tapped).equals(DateTime.utc(2026, 6, 6));
  });

  testWidgets('StreakChip renders count', (tester) async {
    await tester.pumpWidget(_wrap(const StreakChip(count: 12)));
    expect(find.text('12-day streak'), findsOneWidget);
  });

  testWidgets('NudgeCard renders copy', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const NudgeCard(
          title: "You're 60% of the way there.",
          body: '2 meals remain. A done day keeps the streak.',
        ),
      ),
    );
    expect(find.text("You're 60% of the way there."), findsOneWidget);
  });
}
