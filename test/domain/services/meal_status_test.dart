import 'package:checks/checks.dart';
import 'package:crudo/domain/day/scheduled_meal.dart';
import 'package:crudo/domain/food/food.dart';
import 'package:crudo/domain/meal/food_snapshot.dart';
import 'package:crudo/domain/meal/meal_item.dart';
import 'package:crudo/domain/meal/meal_snapshot.dart';
import 'package:crudo/domain/services/meal_status.dart';
import 'package:crudo/domain/shared/enums.dart';
import 'package:crudo/domain/shared/grams.dart';
import 'package:crudo/domain/shared/meal_time.dart';
import 'package:flutter_test/flutter_test.dart';

final _food = Food(
  id: 'f',
  name: 'X',
  kind: FoodKind.product,
  category: FoodCategory.custom,
  protein: 10,
  carbs: 10,
  fats: 10,
  kcalPer100g: 170,
);

FoodSnapshot _snap() => FoodSnapshot.from(_food, const Grams(100));

ScheduledMeal _meal({
  int timeMinutes = 13 * 60, // 13:00
  int checkedOf2 = 0,
  DateTime? skippedAt,
  DateTime? snoozedUntil,
}) => ScheduledMeal(
  id: 'm1',
  time: MealTime(timeMinutes),
  skippedAt: skippedAt,
  snoozedUntil: snoozedUntil,
  meal: MealSnapshot(
    name: 'Lunch',
    items: [
      MealItem(
        checkedAt: checkedOf2 >= 1 ? DateTime.utc(2026, 6, 4, 10) : null,
        food: _snap(),
      ),
      MealItem(
        checkedAt: checkedOf2 >= 2 ? DateTime.utc(2026, 6, 4, 10) : null,
        food: _snap(),
      ),
    ],
  ),
);

void main() {
  // The day under test, as a local-date label, and `now` instants built in
  // LOCAL time on that date so "today" cases hold in any test timezone.
  final dayDate = DateTime.utc(2026, 6, 4);
  DateTime nowAt(int hour, [int minute = 0]) =>
      DateTime(2026, 6, 4, hour, minute);

  // Sentinel helper — `now` as graceEnd is the safe default for callers that
  // only check `== upcoming`. Overdue tests pass an explicit graceEnd.
  MealStatus derive(
    ScheduledMeal m,
    DateTime date,
    DateTime now, {
    DateTime? graceEnd,
  }) => deriveMealStatus(m, date, now, graceEnd ?? now);

  group('checked wins (rule 1) on any day', () {
    for (final (label, date) in [
      ('past', DateTime.utc(2026, 6, 3)),
      ('today', dayDate),
      ('future', DateTime.utc(2026, 6, 5)),
    ]) {
      test('partial on $label day', () {
        check(
          derive(_meal(checkedOf2: 1), date, nowAt(9)),
        ).equals(MealStatus.partial);
      });
      test('done on $label day', () {
        check(
          derive(_meal(checkedOf2: 2), date, nowAt(9)),
        ).equals(MealStatus.done);
      });
    }
    test('checked beats explicit skip AND elapsed clock', () {
      final m = _meal(
        checkedOf2: 2,
        skippedAt: DateTime.utc(2026, 6, 4, 9),
        snoozedUntil: DateTime.utc(2026, 6, 4, 11),
      );
      check(derive(m, dayDate, nowAt(23))).equals(MealStatus.done);
    });
  });

  group('non-today, unchecked', () {
    test('past day freezes to skipped (rule 2)', () {
      check(
        derive(_meal(), DateTime.utc(2026, 6, 3), nowAt(9)),
      ).equals(MealStatus.skipped);
    });
    test('future day is upcoming (rule 3) even past meal time', () {
      check(
        derive(_meal(), DateTime.utc(2026, 6, 5), nowAt(23)),
      ).equals(MealStatus.upcoming);
    });
  });

  group('today chain', () {
    test('explicit skip shows immediately, pre-window (rule 4)', () {
      final m = _meal(skippedAt: DateTime.utc(2026, 6, 4, 9));
      check(derive(m, dayDate, nowAt(9, 30))).equals(MealStatus.skipped);
    });
    test('skip beats pending snooze (rule 4 over 5)', () {
      final m = _meal(
        skippedAt: DateTime.utc(2026, 6, 4, 9),
        snoozedUntil: nowAt(18).toUtc(),
      );
      check(derive(m, dayDate, nowAt(14))).equals(MealStatus.skipped);
    });
    test('pending snooze holds upcoming past meal time (rule 5 over 6)', () {
      final m = _meal(snoozedUntil: nowAt(14, 30).toUtc());
      check(derive(m, dayDate, nowAt(14))).equals(MealStatus.upcoming);
    });
    test('auto-skip flips at meal time exactly, no grace (rule 7)', () {
      check(
        derive(_meal(), dayDate, nowAt(12, 59)),
      ).equals(MealStatus.upcoming);
      check(derive(_meal(), dayDate, nowAt(13))).equals(MealStatus.skipped);
    });
    test('MealTime(0) auto-skips from day start (edge 18)', () {
      check(
        derive(_meal(timeMinutes: 0), dayDate, nowAt(0)),
      ).equals(MealStatus.skipped);
    });
    test('upcoming before meal time (rule 8)', () {
      check(derive(_meal(), dayDate, nowAt(8))).equals(MealStatus.upcoming);
    });
  });

  group('overdue (rule 6)', () {
    test('elapsed snooze within grace → overdue', () {
      final m = _meal(snoozedUntil: nowAt(13, 30).toUtc());
      check(
        derive(m, dayDate, nowAt(13, 40), graceEnd: nowAt(13, 45).toUtc()),
      ).equals(MealStatus.overdue);
    });
    test('elapsed snooze past grace → skipped (rule 7)', () {
      final m = _meal(snoozedUntil: nowAt(13, 30).toUtc());
      check(
        derive(m, dayDate, nowAt(14), graceEnd: nowAt(13, 45).toUtc()),
      ).equals(MealStatus.skipped);
    });
    test('grace = 0 (graceEnd == snoozedUntil) → skipped immediately', () {
      final m = _meal(snoozedUntil: nowAt(13, 30).toUtc());
      check(
        derive(m, dayDate, nowAt(13, 31), graceEnd: nowAt(13, 30).toUtc()),
      ).equals(MealStatus.skipped);
    });
    test('checked wins over overdue (rule 1)', () {
      final m = _meal(checkedOf2: 2, snoozedUntil: nowAt(13, 30).toUtc());
      check(
        derive(m, dayDate, nowAt(13, 40), graceEnd: nowAt(13, 45).toUtc()),
      ).equals(MealStatus.done);
    });
    test('explicit skip beats overdue (rule 4 over 6)', () {
      final m = _meal(
        skippedAt: DateTime.utc(2026, 6, 4, 9),
        snoozedUntil: nowAt(13, 30).toUtc(),
      );
      check(
        derive(m, dayDate, nowAt(13, 40), graceEnd: nowAt(13, 45).toUtc()),
      ).equals(MealStatus.skipped);
    });
    test('pre-window snooze expired, grace over, meal time not reached → '
        'upcoming (rule 8)', () {
      // Meal at 14:00 snoozed (domain allows until < scheduled) to 12:30;
      // grace over at 12:45; 12:50 < 14:00 → rule 7 dead → upcoming.
      final m = _meal(
        timeMinutes: 14 * 60,
        snoozedUntil: nowAt(12, 30).toUtc(),
      );
      check(
        derive(m, dayDate, nowAt(12, 50), graceEnd: nowAt(12, 45).toUtc()),
      ).equals(MealStatus.upcoming);
    });
    test('MealTime(0) snoozed: overdue within grace, skipped after', () {
      final m = _meal(timeMinutes: 0, snoozedUntil: nowAt(0, 20).toUtc());
      check(
        derive(m, dayDate, nowAt(0, 25), graceEnd: nowAt(0, 35).toUtc()),
      ).equals(MealStatus.overdue);
      check(
        derive(m, dayDate, nowAt(0, 40), graceEnd: nowAt(0, 35).toUtc()),
      ).equals(MealStatus.skipped);
    });
  });

  group('time helpers', () {
    test('localDateLabel encodes local date as UTC label', () {
      final label = localDateLabel(DateTime(2026, 6, 4, 23, 59));
      check(label).equals(DateTime.utc(2026, 6, 4));
      check(label.isUtc).isTrue();
    });
    test('localInstantAt builds local wall-clock instant on label date', () {
      final inst = localInstantAt(dayDate, const MealTime(13 * 60));
      check(inst).equals(DateTime(2026, 6, 4, 13));
      check(inst.isUtc).isFalse();
    });
    test('endOfDayLocal is start of next local day', () {
      check(endOfDayLocal(dayDate)).equals(DateTime(2026, 6, 5));
    });
  });
}
