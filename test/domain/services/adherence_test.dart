import 'package:checks/checks.dart';
import 'package:crudo/domain/day/day.dart';
import 'package:crudo/domain/day/scheduled_meal.dart';
import 'package:crudo/domain/food/food.dart';
import 'package:crudo/domain/food/food_ref.dart';
import 'package:crudo/domain/meal/food_snapshot.dart';
import 'package:crudo/domain/meal/meal_item.dart';
import 'package:crudo/domain/meal/meal_snapshot.dart';
import 'package:crudo/domain/meal/meal_template.dart';
import 'package:crudo/domain/plan/plan_slot.dart';
import 'package:crudo/domain/plan/plan_template.dart';
import 'package:crudo/domain/services/adherence.dart';
import 'package:crudo/domain/services/meal_status.dart' show endOfDayLocal;
import 'package:crudo/domain/shared/enums.dart';
import 'package:crudo/domain/shared/grams.dart';
import 'package:crudo/domain/shared/meal_time.dart';
import 'package:crudo/domain/streak/streak.dart';
import 'package:flutter_test/flutter_test.dart';

/// Build a Day whose planned kcal sum equals [planned] and whose checked-item
/// kcal sum equals [consumed]. Uses a single meal carrying however many items
/// are needed to represent the two sums.
Day _dayWithKcal({
  required double planned,
  required double consumed,
  DateTime? date,
}) {
  final defaultDate = DateTime.utc(2026, 6, 10);

  if (planned == 0 && consumed == 0) {
    return Day(date: date ?? defaultDate);
  }

  final items = <MealItem>[];
  if (planned > consumed) {
    items.add(
      MealItem(
        food: FoodSnapshot(
          sourceFoodId: 'f-unchecked',
          name: 'Unchecked',
          kind: FoodKind.product,
          category: FoodCategory.custom,
          grams: const Grams(100),
          protein: 0,
          carbs: 0,
          fats: 0,
          kcal: planned - consumed,
        ),
      ),
    );
  }
  if (consumed > 0) {
    items.add(
      MealItem(
        checkedAt: DateTime.utc(2026, 6, 10, 12),
        food: FoodSnapshot(
          sourceFoodId: 'f-checked',
          name: 'Checked',
          kind: FoodKind.product,
          category: FoodCategory.custom,
          grams: const Grams(100),
          protein: 0,
          carbs: 0,
          fats: 0,
          kcal: consumed,
        ),
      ),
    );
  }

  return Day(
    date: date ?? defaultDate,
    meals: [
      ScheduledMeal(
        id: 'm1',
        time: const MealTime(12 * 60),
        meal: MealSnapshot(name: 'Test meal', items: items),
      ),
    ],
  );
}

void main() {
  group('dayAdherence', () {
    test('consumed 800 of planned 1000 → 0.8', () {
      final d = _dayWithKcal(planned: 1000, consumed: 800);
      check(dayAdherence(d)).equals(0.8);
    });

    test('overeaten (consumed > planned) → clamps to 1.0', () {
      final d = _dayWithKcal(planned: 1000, consumed: 1200);
      check(dayAdherence(d)).equals(1.0);
    });

    test('planned 0 (empty Day) → 0.0', () {
      final d = Day(date: DateTime.utc(2026, 6, 10));
      check(dayAdherence(d)).equals(0.0);
    });

    test('nothing checked → 0.0', () {
      final d = _dayWithKcal(planned: 1000, consumed: 0);
      check(dayAdherence(d)).equals(0.0);
    });
  });

  group('classifyDayState', () {
    test('(0.80, 80) → green', () {
      check(classifyDayState(0.80, 80)).equals(DayState.green);
    });
    test('(0.79, 80) → yellow', () {
      check(classifyDayState(0.79, 80)).equals(DayState.yellow);
    });
    test('(0.50, 80) → yellow', () {
      check(classifyDayState(0.50, 80)).equals(DayState.yellow);
    });
    test('(0.49, 80) → red', () {
      check(classifyDayState(0.49, 80)).equals(DayState.red);
    });
    test('(1.0, 100) → green', () {
      check(classifyDayState(1.0, 100)).equals(DayState.green);
    });
    test('(0.99, 100) → yellow', () {
      check(classifyDayState(0.99, 100)).equals(DayState.yellow);
    });
    // Sweep the remaining selectable thresholds (spec: 70/80/90/100).
    test('(0.70, 70) → green', () {
      check(classifyDayState(0.70, 70)).equals(DayState.green);
    });
    test('(0.69, 70) → yellow', () {
      check(classifyDayState(0.69, 70)).equals(DayState.yellow);
    });
    test('(0.90, 90) → green', () {
      check(classifyDayState(0.90, 90)).equals(DayState.green);
    });
    test('(0.85, 90) → yellow', () {
      check(classifyDayState(0.85, 90)).equals(DayState.yellow);
    });
  });

  group('lockDay', () {
    test('sets all three trio fields on an open day', () {
      final open = _dayWithKcal(planned: 1000, consumed: 800);
      final now = DateTime.utc(2026, 6, 11, 0, 0, 0);
      final locked = lockDay(open, 80, now);

      check(locked.adherence).isNotNull();
      check(locked.adherence!).equals(0.8);
      check(locked.thresholdUsed).isNotNull();
      check(locked.thresholdUsed!).equals(80);
      check(locked.lockedAt).isNotNull();
    });

    test('lockedAt is UTC', () {
      final open = _dayWithKcal(planned: 1000, consumed: 800);
      final now = DateTime.utc(2026, 6, 11, 0, 0, 0);
      final locked = lockDay(open, 80, now);

      check(locked.lockedAt!.isUtc).equals(true);
    });

    test('thresholdUsed equals the passed value', () {
      final open = _dayWithKcal(planned: 1000, consumed: 800);
      final locked = lockDay(open, 70, DateTime.utc(2026, 6, 11));

      check(locked.thresholdUsed!).equals(70);
    });

    test('idempotent: second call returns identical instance', () {
      final open = _dayWithKcal(planned: 1000, consumed: 800);
      final now = DateTime.utc(2026, 6, 11, 0, 0, 0);
      final locked1 = lockDay(open, 80, now);
      final locked2 = lockDay(locked1, 90, DateTime.utc(2026, 6, 12));

      // lockedAt unchanged from first freeze
      check(locked2.lockedAt).equals(locked1.lockedAt);
      check(locked2.adherence).equals(locked1.adherence);
      check(locked2.thresholdUsed).equals(locked1.thresholdUsed);
    });
  });

  group('frozenDayState', () {
    test('locked 0.80 day at threshold 80 → green', () {
      final d = _dayWithKcal(planned: 1000, consumed: 800);
      final locked = lockDay(d, 80, DateTime.utc(2026, 6, 11));

      check(frozenDayState(locked)).equals(DayState.green);
    });

    test('stored thresholdUsed governs — history does not recolor', () {
      // Same 0.85 adherence, two different stored thresholds. The day locked at
      // 80 stays green forever; the one locked at 90 stays yellow forever —
      // proving frozenDayState reads the FROZEN threshold, never a live one.
      // A later prefs change (80→90 or back) can never reclassify either day.
      final at80 = lockDay(
        _dayWithKcal(planned: 1000, consumed: 850),
        80,
        DateTime.utc(2026, 6, 11),
      );
      final at90 = lockDay(
        _dayWithKcal(planned: 1000, consumed: 850),
        90,
        DateTime.utc(2026, 6, 11),
      );
      check(frozenDayState(at80)).equals(DayState.green); // 85 ≥ 80
      check(frozenDayState(at90)).equals(DayState.yellow); // 85 < 90
    });

    test('on an open day throws StateError', () {
      final open = _dayWithKcal(planned: 1000, consumed: 800);

      check(() => frozenDayState(open)).throws<StateError>();
    });
  });

  group('advanceStreak', () {
    /// Build a locked Day with given adherence ratio (consumed/planned).
    Day lockedDay(
      DateTime date,
      double adherence, {
      int threshold = 80,
      double planned = 1000,
    }) {
      final consumed = adherence * planned;
      final day = _dayWithKcal(
        planned: planned,
        consumed: consumed,
        date: date,
      );
      return lockDay(day, threshold, DateTime.utc(2026, 6, 11, 0, 0, 0));
    }

    test('three green days from empty Streak -> current 3, personalBest 3', () {
      final d1 = lockedDay(DateTime.utc(2026, 6, 1), 0.85);
      final d2 = lockedDay(DateTime.utc(2026, 6, 2), 0.90);
      final d3 = lockedDay(DateTime.utc(2026, 6, 3), 0.80);
      final result = advanceStreak(const Streak(), [d1, d2, d3]);
      check(result.next.current).equals(3);
      check(result.next.personalBest).equals(3);
      check(result.next.lastCountedDay).equals(DateTime.utc(2026, 6, 3));
    });

    test('yellow holds streak, advances lastCountedDay', () {
      final d1 = lockedDay(DateTime.utc(2026, 6, 1), 0.85);
      final d2 = lockedDay(DateTime.utc(2026, 6, 2), 0.90);
      final d3 = lockedDay(
        DateTime.utc(2026, 6, 3),
        0.60,
      ); // yellow at threshold 80
      final result = advanceStreak(const Streak(), [d1, d2, d3]);
      check(result.next.current).equals(2);
      check(result.next.lastCountedDay).equals(DateTime.utc(2026, 6, 3));
    });

    test('red resets streak', () {
      final d1 = lockedDay(DateTime.utc(2026, 6, 1), 0.85);
      final d2 = lockedDay(DateTime.utc(2026, 6, 2), 0.90);
      final d3 = lockedDay(DateTime.utc(2026, 6, 3), 0.80);
      final d4 = lockedDay(DateTime.utc(2026, 6, 4), 0.40); // red
      final result = advanceStreak(const Streak(), [d1, d2, d3, d4]);
      check(result.next.current).equals(0);
      check(result.next.personalBest).equals(3);
    });

    test('plannedKcal==0 day holds, does not reset', () {
      final d1 = lockedDay(DateTime.utc(2026, 6, 1), 0.85);
      final d2 = lockedDay(DateTime.utc(2026, 6, 2), 0.0, planned: 0);
      final result = advanceStreak(const Streak(), [d1, d2]);
      check(result.next.current).equals(1);
    });

    test('idempotent re-fold with caught-up streak -> no changes', () {
      final d1 = lockedDay(DateTime.utc(2026, 6, 1), 0.85);
      final d2 = lockedDay(DateTime.utc(2026, 6, 2), 0.90);
      final result1 = advanceStreak(const Streak(), [d1, d2]);

      // Re-fold with same dates but using result1.next as prev
      final result2 = advanceStreak(result1.next, [d1, d2]);
      check(result2.next.current).equals(result1.next.current);
      check(result2.next.personalBest).equals(result1.next.personalBest);
      check(result2.next.lastCountedDay).equals(result1.next.lastCountedDay);
      final List<int> emptyMilestones = result2.milestonesCrossed;
      check(emptyMilestones).isEmpty();
    });

    test('unlocked day throws StateError', () {
      final open = Day(date: DateTime.utc(2026, 6, 1));
      check(() => advanceStreak(const Streak(), [open])).throws<StateError>();
    });

    test('milestone 6->7 emits [7]', () {
      final prev = const Streak(current: 6, personalBest: 6);
      final d = lockedDay(DateTime.utc(2026, 6, 1), 0.85);
      final result = advanceStreak(prev, [d]);
      final List<int> ms = result.milestonesCrossed;
      check(ms).deepEquals([7]);
      check(result.next.current).equals(7);
    });

    test('staying 7->8 emits no milestones', () {
      final prev = const Streak(current: 7, personalBest: 7);
      final d = lockedDay(DateTime.utc(2026, 6, 1), 0.85);
      final result = advanceStreak(prev, [d]);
      final List<int> ms = result.milestonesCrossed;
      check(ms).isEmpty();
      check(result.next.current).equals(8);
    });

    test('0->30 emits [7, 30] in order', () {
      final days = List.generate(
        30,
        (i) => lockedDay(DateTime.utc(2026, 6, 1 + i), 0.85),
      );
      final result = advanceStreak(const Streak(), days);
      final List<int> ms = result.milestonesCrossed;
      check(ms).deepEquals([7, 30]);
      check(result.next.current).equals(30);
    });

    test('reset to 0 then climb past 7 re-emits [7]', () {
      // Start at 8, one red day resets to 0, then 7 greens
      final prev = const Streak(current: 8, personalBest: 8);
      final red = lockedDay(DateTime.utc(2026, 6, 1), 0.40);
      final greens = List.generate(
        7,
        (i) => lockedDay(DateTime.utc(2026, 6, 2 + i), 0.85),
      );
      final result = advanceStreak(prev, [red, ...greens]);
      final List<int> ms = result.milestonesCrossed;
      check(ms).deepEquals([7]);
      check(result.next.current).equals(7);
    });

    test('0->100 emits [7, 30, 100] in order', () {
      final days = List.generate(
        100,
        (i) => lockedDay(DateTime.utc(2026, 6, 1).add(Duration(days: i)), 0.85),
      );
      final result = advanceStreak(const Streak(), days);
      final List<int> ms = result.milestonesCrossed;
      check(ms).deepEquals([7, 30, 100]);
      check(result.next.current).equals(100);
      check(result.next.personalBest).equals(100);
    });
  });

  group('catchUp', () {
    final today = DateTime.utc(2026, 6, 10);

    // Domain objects for back-materializing unopened days
    final food = Food(
      id: 'f-catchup',
      name: 'Test Food',
      protein: 0,
      carbs: 0,
      fats: 0,
      kcalPer100g: 1000,
      category: FoodCategory.custom,
    );
    final mealTemplate = MealTemplate(
      id: 'mt-catchup',
      name: 'Test Meal',
      foods: [FoodRef(foodId: 'f-catchup', grams: const Grams(100))],
    );
    final plan = PlanTemplate(
      id: 'p-catchup',
      name: 'Test Plan',
      active: true,
      days: [0, 1, 2, 3, 4, 5, 6],
      slots: [
        PlanSlot(
          id: 'ps-catchup',
          mealTemplateId: 'mt-catchup',
          time: const MealTime(12 * 60),
        ),
      ],
    );

    test('empty range: lastCountedDay = today - 1, no persisted days', () {
      final prev = Streak(lastCountedDay: DateTime.utc(2026, 6, 9));
      var idSeq = 0;
      String newId() => 'id-${++idSeq}';

      final result = catchUp(
        todayLabel: today,
        prevStreak: prev,
        threshold: 80,
        persistedDays: const [],
        plans: [plan],
        mealTemplates: [mealTemplate],
        foods: [food],
        newId: newId,
      );

      check(result.lockedDays).isEmpty();
      check(result.streak).equals(prev);
      check(result.milestones).isEmpty();
    });

    test(
      'first run: lastCountedDay == null → seeds one day back, no locked days',
      () {
        var idSeq = 0;
        String newId() => 'id-${++idSeq}';

        final result = catchUp(
          todayLabel: today,
          prevStreak: const Streak(),
          threshold: 80,
          persistedDays: const [],
          plans: [plan],
          mealTemplates: [mealTemplate],
          foods: [food],
          newId: newId,
        );

        check(result.lockedDays).isEmpty();
        check(
          result.streak.lastCountedDay,
        ).equals(DateTime.utc(2026, 6, 9)); // today - 1
        check(result.streak.current).equals(0);
        check(result.milestones).isEmpty();
      },
    );

    test(
      'one unopened gap day → back-materialized, adherence 0, red reset',
      () {
        final prev = Streak(lastCountedDay: DateTime.utc(2026, 6, 8));
        var idSeq = 0;
        String newId() => 'id-${++idSeq}';

        final result = catchUp(
          todayLabel: today,
          prevStreak: prev,
          threshold: 80,
          persistedDays: const [],
          plans: [plan],
          mealTemplates: [mealTemplate],
          foods: [food],
          newId: newId,
        );

        check(result.lockedDays).length.equals(1);
        final locked = result.lockedDays[0];
        check(locked.date).equals(DateTime.utc(2026, 6, 9));
        check(locked.lockedAt).isNotNull();
        check(
          locked.lockedAt!,
        ).equals(endOfDayLocal(DateTime.utc(2026, 6, 9)).toUtc());
        check(locked.adherence!).equals(0.0);
        // Red reset
        check(result.streak.current).equals(0);
        check(result.milestones).isEmpty();
      },
    );

    test(
      'persisted OPEN day with full consumption → locked in place, streak +1',
      () {
        final prev = Streak(lastCountedDay: DateTime.utc(2026, 6, 8));
        final openDay = _dayWithKcal(
          date: DateTime.utc(2026, 6, 9),
          planned: 1000,
          consumed: 1000,
        );
        check(openDay.lockedAt).isNull();

        var idSeq = 0;
        String newId() => 'id-${++idSeq}';

        final result = catchUp(
          todayLabel: today,
          prevStreak: prev,
          threshold: 80,
          persistedDays: [openDay],
          plans: [plan],
          mealTemplates: [mealTemplate],
          foods: [food],
          newId: newId,
        );

        check(result.lockedDays).length.equals(1);
        final locked = result.lockedDays[0];
        check(locked.date).equals(DateTime.utc(2026, 6, 9));
        check(locked.lockedAt).isNotNull();
        check(locked.adherence!).equals(1.0);
        // Same meals as openDay (not rebuilt)
        check(locked.meals.length).equals(openDay.meals.length);
        // Green day → streak incremented
        check(result.streak.current).equals(1);
        check(result.streak.lastCountedDay).equals(DateTime.utc(2026, 6, 9));
      },
    );

    test(
      'persisted ALREADY-LOCKED day → not in lockedDays, but folded in streak',
      () {
        final prev = Streak(lastCountedDay: DateTime.utc(2026, 6, 8));
        final lockedDay = lockDay(
          _dayWithKcal(
            date: DateTime.utc(2026, 6, 9),
            planned: 1000,
            consumed: 850,
          ),
          80,
          DateTime.utc(2026, 6, 9, 23, 59),
        );

        var idSeq = 0;
        String newId() => 'id-${++idSeq}';

        final result = catchUp(
          todayLabel: today,
          prevStreak: prev,
          threshold: 80,
          persistedDays: [lockedDay],
          plans: [plan],
          mealTemplates: [mealTemplate],
          foods: [food],
          newId: newId,
        );

        check(result.lockedDays).isEmpty(); // not re-saved
        // Still folded (green → +1)
        check(result.streak.current).equals(1);
        check(result.streak.lastCountedDay).equals(DateTime.utc(2026, 6, 9));
      },
    );

    test('multi-day range with a red in the middle → resets then climbs', () {
      final prev = Streak(lastCountedDay: DateTime.utc(2026, 6, 6));
      // 6/7 = green (persisted open, newly locked)
      final d7 = _dayWithKcal(
        date: DateTime.utc(2026, 6, 7),
        planned: 1000,
        consumed: 850,
      );
      // 6/8 = red (persisted open, newly locked) → resets
      final d8 = _dayWithKcal(
        date: DateTime.utc(2026, 6, 8),
        planned: 1000,
        consumed: 400,
      );
      // 6/9 = green (persisted open, newly locked) → climbs
      final d9 = _dayWithKcal(
        date: DateTime.utc(2026, 6, 9),
        planned: 1000,
        consumed: 850,
      );

      var idSeq = 0;
      String newId() => 'id-${++idSeq}';

      final result = catchUp(
        todayLabel: today,
        prevStreak: prev,
        threshold: 80,
        persistedDays: [d7, d8, d9],
        plans: [plan],
        mealTemplates: [mealTemplate],
        foods: [food],
        newId: newId,
      );

      // All three were open → all three newly locked
      check(result.lockedDays).length.equals(3);
      // After red reset then green climb: current = 1
      check(result.streak.current).equals(1);
      check(result.streak.personalBest).equals(1);
      check(result.streak.lastCountedDay).equals(DateTime.utc(2026, 6, 9));
    });

    test('mixed range: persisted-open day + unopened day both locked', () {
      final prev = Streak(lastCountedDay: DateTime.utc(2026, 6, 7));
      // 6/8 persisted OPEN green (locked in place); 6/9 has NO row → rebuilt
      // from the plan with 0 consumed → red → resets the climb.
      final d8 = _dayWithKcal(
        date: DateTime.utc(2026, 6, 8),
        planned: 1000,
        consumed: 850,
      );
      check(d8.lockedAt).isNull();

      var idSeq = 0;
      String newId() => 'id-${++idSeq}';

      final result = catchUp(
        todayLabel: today,
        prevStreak: prev,
        threshold: 80,
        persistedDays: [d8], // only 6/8 persisted; 6/9 absent
        plans: [plan],
        mealTemplates: [mealTemplate],
        foods: [food],
        newId: newId,
      );

      // Both 6/8 (open-locked) and 6/9 (rebuilt) are newly frozen.
      check(result.lockedDays).length.equals(2);
      final dates = result.lockedDays.map((d) => d.date).toList();
      check(
        dates,
      ).deepEquals([DateTime.utc(2026, 6, 8), DateTime.utc(2026, 6, 9)]);
      // 6/9 rebuilt from plan → planned>0, 0 consumed → adherence 0 (red).
      final rebuilt = result.lockedDays[1];
      check(rebuilt.adherence!).equals(0.0);
      check(rebuilt.meals).isNotEmpty(); // came from the plan, not an empty day
      // green (6/8) → 1, then red (6/9) → 0.
      check(result.streak.current).equals(0);
      check(result.streak.personalBest).equals(1);
    });
  });
}
