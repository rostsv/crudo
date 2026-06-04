// test/domain/day/day_test.dart
import 'package:checks/checks.dart';
import 'package:crudo/domain/day/day.dart';
import 'package:crudo/domain/day/scheduled_meal.dart';
import 'package:crudo/domain/meal/meal_snapshot.dart';
import 'package:crudo/domain/shared/meal_time.dart';
import 'package:flutter_test/flutter_test.dart';

final _sm = ScheduledMeal(
  id: 'm1',
  time: MealTime(8 * 60),
  meal: MealSnapshot(name: 'Breakfast'),
);

void main() {
  test('open day: no verdict, defaults empty', () {
    final d = Day(date: DateTime.utc(2026, 6, 3));
    check(d.adherence).isNull();
    check(d.thresholdUsed).isNull();
    check(d.lockedAt).isNull();
    check(d.meals).isEmpty();
    check(d.sourcePlanId).isNull();
  });

  test('locked day carries frozen verdict trio', () {
    final d = Day(
      date: DateTime.utc(2026, 6, 2),
      adherence: 0.85,
      thresholdUsed: 80,
      lockedAt: DateTime.utc(2026, 6, 3, 0, 0, 1),
    );
    check(d.adherence).equals(0.85);
    check(d.thresholdUsed).equals(80);
    check(d.lockedAt).isNotNull();
  });

  test('asserts date is a UTC-midnight label', () {
    check(() => Day(date: DateTime(2026, 6, 3))).throws<AssertionError>();
    check(
      () => Day(date: DateTime.utc(2026, 6, 3, 14)),
    ).throws<AssertionError>();
  });

  test('asserts frozen trio must be set together', () {
    check(
      () => Day(date: DateTime.utc(2026, 6, 2), adherence: 0.5),
    ).throws<AssertionError>();
    check(
      () => Day(date: DateTime.utc(2026, 6, 2), thresholdUsed: 80),
    ).throws<AssertionError>();
    check(
      () => Day(
        date: DateTime.utc(2026, 6, 2),
        adherence: 1.2,
        thresholdUsed: 80,
        lockedAt: DateTime.utc(2026, 6, 3),
      ),
    ).throws<AssertionError>();
    // all three together works
    final locked = Day(
      date: DateTime.utc(2026, 6, 2),
      adherence: 0.8,
      thresholdUsed: 80,
      lockedAt: DateTime.utc(2026, 6, 3, 0, 0, 1),
    );
    check(locked.thresholdUsed).equals(80);
  });

  test('holds ScheduledMeal meals by id (identity ≠ list order)', () {
    final d = Day(date: DateTime.utc(2026, 6, 4), meals: [_sm]);
    check(d.meals.single.id).equals('m1');
    check(d.meals.single.time).equals(const MealTime(8 * 60));
  });
}
