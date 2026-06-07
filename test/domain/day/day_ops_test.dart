import 'package:checks/checks.dart';
import 'package:crudo/domain/day/day.dart';
import 'package:crudo/domain/day/scheduled_meal.dart';
import 'package:crudo/domain/food/food.dart';
import 'package:crudo/domain/meal/food_snapshot.dart';
import 'package:crudo/domain/meal/meal_item.dart';
import 'package:crudo/domain/meal/meal_snapshot.dart';
import 'package:crudo/domain/services/meal_lifecycle.dart';
import 'package:crudo/domain/services/meal_status.dart';
import 'package:crudo/domain/shared/grams.dart';
import 'package:crudo/domain/shared/meal_time.dart';
import 'package:crudo/domain/shared/enums.dart';
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

MealItem _item([DateTime? checkedAt]) => MealItem(
  checkedAt: checkedAt,
  food: FoodSnapshot.from(_food, const Grams(100)),
);

ScheduledMeal _meal(String id, int minutes, {int checkedOf2 = 0}) =>
    ScheduledMeal(
      id: id,
      time: MealTime(minutes),
      meal: MealSnapshot(
        name: 'M$id',
        items: [
          _item(checkedOf2 >= 1 ? DateTime.utc(2026, 6, 4, 9) : null),
          _item(checkedOf2 >= 2 ? DateTime.utc(2026, 6, 4, 9) : null),
        ],
      ),
    );

void main() {
  final today = DateTime.utc(2026, 6, 4);
  final now = DateTime(2026, 6, 4, 12); // local noon
  Day day({int checkedOf2 = 0}) => Day(
    date: today,
    meals: [
      _meal('breakfast', 8 * 60),
      _meal('lunch', 13 * 60, checkedOf2: checkedOf2),
      _meal('dinner', 19 * 60),
    ],
  );

  group('universal lock guard', () {
    final tomorrow = DateTime.utc(2026, 6, 5);
    test('every op rejects on a locked day', () {
      final d = day();
      check(() => d.checkItem('lunch', 0, now, tomorrow)).throws<StateError>();
      check(
        () => d.uncheckItem('lunch', 0, now, tomorrow),
      ).throws<StateError>();
      check(() => d.markAllEaten('lunch', now, tomorrow)).throws<StateError>();
      check(() => d.skipMeal('lunch', now, tomorrow)).throws<StateError>();
      check(
        () => d.snoozeMeal(
          'lunch',
          now.add(const Duration(minutes: 30)),
          now,
          tomorrow,
        ),
      ).throws<StateError>();
      check(
        () => d.replaceMeal(
          'lunch',
          MealSnapshot(name: 'N', items: [_item()]),
          now,
          tomorrow,
        ),
      ).throws<StateError>();
      check(isDayLocked(d, tomorrow)).isTrue();
      check(isDayLocked(d, today)).isFalse();
    });
  });

  group('checkItem / uncheckItem / markAllEaten', () {
    test('checkItem stamps UTC now on the item', () {
      final d = day().checkItem('lunch', 0, now, today);
      final stamped = d.meals
          .singleWhere((m) => m.id == 'lunch')
          .meal
          .items[0]
          .checkedAt;
      check(stamped).isNotNull();
      check(stamped!.isUtc).isTrue();
      check(stamped).equals(now.toUtc());
    });
    test('out-of-range index throws', () {
      check(() => day().checkItem('lunch', 2, now, today)).throws<StateError>();
      check(
        () => day().checkItem('lunch', -1, now, today),
      ).throws<StateError>();
    });
    test('unknown meal id throws', () {
      check(() => day().checkItem('nope', 0, now, today)).throws<StateError>();
    });
    test('uncheckItem clears the stamp', () {
      final d = day(checkedOf2: 1).uncheckItem('lunch', 0, now, today);
      check(d.meals[1].meal.items[0].checkedAt).isNull();
    });
    test('markAllEaten stamps unchecked, preserves existing stamps', () {
      final before = day(checkedOf2: 1);
      final original = before.meals[1].meal.items[0].checkedAt;
      final d = before.markAllEaten('lunch', now, today);
      check(d.meals[1].meal.items[0].checkedAt).equals(original);
      check(d.meals[1].meal.items[1].checkedAt).equals(now.toUtc());
    });
    test('marking never touches skippedAt/snoozedUntil', () {
      final skipped = day().skipMeal('lunch', now, today);
      final d = skipped.markAllEaten('lunch', now, today);
      final lunch = d.meals.singleWhere((m) => m.id == 'lunch');
      check(lunch.skippedAt).isNotNull(); // stamp survives — analytics keep
    });
  });

  group('skipMeal', () {
    test('stamps UTC; re-skip overwrites', () {
      final d1 = day().skipMeal('lunch', now, today);
      final later = now.add(const Duration(hours: 1));
      final d2 = d1.skipMeal('lunch', later, today);
      check(d2.meals[1].skippedAt).equals(later.toUtc());
    });
    test('rejects when any item checked', () {
      check(
        () => day(checkedOf2: 1).skipMeal('lunch', now, today),
      ).throws<StateError>();
      check(canSkipMeal(day(checkedOf2: 1), 'lunch', today)).isFalse();
      check(canSkipMeal(day(), 'lunch', today)).isTrue();
    });
  });

  group('snoozeMeal + maxSnoozeUntil', () {
    test('bound is next meal by time (lunch → dinner 19:00)', () {
      final bound = maxSnoozeUntil(day(), 'lunch', now);
      check(bound).equals(DateTime(2026, 6, 4, 19).toUtc());
    });
    test('last meal bounds at end-of-day midnight', () {
      final bound = maxSnoozeUntil(day(), 'dinner', now);
      check(bound).equals(DateTime(2026, 6, 5).toUtc());
    });
    test('same-time meals do not bound each other', () {
      final d = Day(
        date: today,
        meals: [_meal('a', 13 * 60), _meal('b', 13 * 60)],
      );
      check(maxSnoozeUntil(d, 'a', now)).equals(DateTime(2026, 6, 5).toUtc());
    });
    test('MealTime(0) meal can snooze into its whole day (edge 18)', () {
      final d = Day(date: today, meals: [_meal('mid', 0)]);
      check(maxSnoozeUntil(d, 'mid', now)).equals(DateTime(2026, 6, 5).toUtc());
    });
    test(
      'accepts within bound, repeatable; rejects past bound or non-future',
      () {
        final d1 = day().snoozeMeal(
          'lunch',
          DateTime(2026, 6, 4, 13, 30).toUtc(),
          now,
          today,
        );
        final d2 = d1.snoozeMeal(
          'lunch',
          DateTime(2026, 6, 4, 14, 15).toUtc(),
          now,
          today,
        );
        check(
          d2.meals[1].snoozedUntil,
        ).equals(DateTime(2026, 6, 4, 14, 15).toUtc());
        check(
          () => day().snoozeMeal(
            'lunch',
            DateTime(2026, 6, 4, 19, 1).toUtc(),
            now,
            today,
          ),
        ).throws<StateError>(); // past next meal
        check(
          () => day().snoozeMeal('lunch', now.toUtc(), now, today),
        ).throws<StateError>(); // not strictly future
      },
    );
    test('rejects when done; canSnoozeMeal mirrors', () {
      check(
        () => day(
          checkedOf2: 2,
        ).snoozeMeal('lunch', DateTime(2026, 6, 4, 14).toUtc(), now, today),
      ).throws<StateError>();
      check(canSnoozeMeal(day(checkedOf2: 2), 'lunch', now, today)).isFalse();
      check(canSnoozeMeal(day(), 'lunch', now, today)).isTrue();
    });
  });

  group('replaceMeal (content-edit guard)', () {
    final newMeal = MealSnapshot(name: 'Swap', items: [_item()]);
    test('swaps content; id + time survive', () {
      final d = day().replaceMeal('lunch', newMeal, now, today);
      final lunch = d.meals[1];
      check(lunch.id).equals('lunch');
      check(lunch.time).equals(const MealTime(13 * 60));
      check(lunch.meal.name).equals('Swap');
    });
    test('rejects on every non-upcoming status', () {
      // partial / done
      check(
        () => day(checkedOf2: 1).replaceMeal('lunch', newMeal, now, today),
      ).throws<StateError>();
      check(
        () => day(checkedOf2: 2).replaceMeal('lunch', newMeal, now, today),
      ).throws<StateError>();
      // explicitly skipped
      final skipped = day().skipMeal('lunch', now, today);
      check(
        () => skipped.replaceMeal('lunch', newMeal, now, today),
      ).throws<StateError>();
      // auto-skipped (window passed, 14:00 > 13:00)
      final after = DateTime(2026, 6, 4, 14);
      check(
        () => day().replaceMeal('lunch', newMeal, after, today),
      ).throws<StateError>();
      // predicate mirrors
      check(canEditMealContent(day().meals[1], today, after)).isFalse();
      check(canEditMealContent(day().meals[1], today, now)).isTrue();
    });
  });

  group('unmarkAll', () {
    test('clears every checkedAt', () {
      final d = day(checkedOf2: 2).unmarkAll('lunch', today);
      check(d.meals[1].meal.items[0].checkedAt).isNull();
      check(d.meals[1].meal.items[1].checkedAt).isNull();
    });
    test('preserves skippedAt and snoozedUntil', () {
      final skipped = day().skipMeal('lunch', now, today);
      final done = skipped.markAllEaten('lunch', now, today);
      final undone = done.unmarkAll('lunch', today);
      check(undone.meals[1].skippedAt).isNotNull();
    });
    test('round-trip: skipped → done → skipped derivation', () {
      final skipped = day().skipMeal('lunch', now, today);
      final done = skipped.markAllEaten('lunch', now, today);
      check(
        deriveMealStatus(done.meals[1], today, now, now),
      ).equals(MealStatus.done);
      final undone = done.unmarkAll('lunch', today);
      check(
        deriveMealStatus(undone.meals[1], today, now, now),
      ).equals(MealStatus.skipped);
    });
    test('throws when nothing is checked', () {
      check(() => day().unmarkAll('lunch', today)).throws<StateError>();
    });
    test('throws on a locked day', () {
      check(
        () => day(checkedOf2: 1).unmarkAll('lunch', DateTime.utc(2026, 6, 5)),
      ).throws<StateError>();
    });
    test('throws on unknown meal id', () {
      check(() => day().unmarkAll('nope', today)).throws<StateError>();
    });
  });
}
