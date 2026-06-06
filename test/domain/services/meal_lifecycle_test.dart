import 'package:checks/checks.dart';
import 'package:crudo/domain/day/day.dart';
import 'package:crudo/domain/food/food.dart';
import 'package:crudo/domain/food/food_ref.dart';
import 'package:crudo/domain/meal/meal_template.dart';
import 'package:crudo/domain/plan/plan_slot.dart';
import 'package:crudo/domain/plan/plan_template.dart';
import 'package:crudo/domain/services/meal_lifecycle.dart';
import 'package:crudo/domain/services/meal_status.dart';
import 'package:crudo/domain/shared/enums.dart';
import 'package:crudo/domain/shared/grams.dart';
import 'package:crudo/domain/shared/meal_time.dart';
import 'package:flutter_test/flutter_test.dart';

class _SeqIds {
  int _n = 0;
  String newId() => 'id-${_n++}';
}

final _egg = Food(
  id: 'egg',
  name: 'Egg',
  kind: FoodKind.product,
  category: FoodCategory.eggs,
  protein: 13,
  carbs: 1.1,
  fats: 11,
  kcalPer100g: 155,
);
final _rice = Food(
  id: 'rice',
  name: 'Rice',
  kind: FoodKind.product,
  category: FoodCategory.grain,
  protein: 2.7,
  carbs: 28,
  fats: 0.3,
  kcalPer100g: 130,
);

final _breakfastTpl = MealTemplate(
  id: 'tpl-b',
  name: 'Eggs',
  foods: [FoodRef(foodId: 'egg', grams: const Grams(120))],
);
final _lunchTpl = MealTemplate(
  id: 'tpl-l',
  name: 'Rice bowl',
  foods: [
    FoodRef(foodId: 'rice', grams: const Grams(150)),
    FoodRef(foodId: 'egg', grams: const Grams(60)),
  ],
);

PlanTemplate _plan({
  String id = 'p1',
  List<int> days = const [0, 1, 2, 3, 4], // Mon–Fri
  bool active = true,
}) => PlanTemplate(
  id: id,
  name: 'Cut',
  days: days,
  active: active,
  slots: [
    // deliberately unsorted — materialization must sort by time
    PlanSlot(id: 's2', mealTemplateId: 'tpl-l', time: const MealTime(13 * 60)),
    PlanSlot(id: 's1', mealTemplateId: 'tpl-b', time: const MealTime(8 * 60)),
  ],
);

void main() {
  final thursday = DateTime.utc(2026, 6, 4); // 2026-06-04 is a Thursday
  final sunday = DateTime.utc(2026, 6, 7);

  group('selectPlanForDate', () {
    test('picks the active plan covering the weekday', () {
      check(selectPlanForDate([_plan()], thursday)).isNotNull();
    });
    test('null when no plan covers the weekday (rest day)', () {
      check(selectPlanForDate([_plan()], sunday)).isNull();
    });
    test('ignores inactive plans', () {
      check(selectPlanForDate([_plan(active: false)], thursday)).isNull();
    });
    test('defensive tie-break: lowest id wins', () {
      final picked = selectPlanForDate([
        _plan(id: 'p2'),
        _plan(id: 'p1'),
      ], thursday);
      check(picked!.id).equals('p1');
    });
  });

  group('buildDayFromPlan', () {
    Day build({PlanTemplate? plan}) => buildDayFromPlan(
      plan,
      thursday,
      _SeqIds().newId,
      [_breakfastTpl, _lunchTpl],
      [_egg, _rice],
    );

    test('null plan → empty rest day, no plan refs', () {
      final d = build(plan: null);
      check(d.date).equals(thursday);
      check(d.sourcePlanId).isNull();
      check(d.meals).isEmpty();
    });

    test(
      'one ScheduledMeal per slot, sorted by time, fresh ids, unchecked',
      () {
        final d = build(plan: _plan());
        check(d.sourcePlanId).equals('p1');
        check(d.planName).equals('Cut');
        check(d.meals.length).equals(2);
        check(d.meals[0].time).equals(const MealTime(8 * 60)); // sorted
        check(d.meals[0].id).equals('id-0');
        check(d.meals[1].id).equals('id-1');
        check(d.meals[0].meal.sourceMealTemplateId).equals('tpl-b');
        check(d.meals[0].meal.items.every((i) => !i.checked)).isTrue();
      },
    );

    test('items carry computed absolutes from FoodSnapshot.from', () {
      final d = build(plan: _plan());
      final eggs120 = d.meals[0].meal.items.single;
      check(eggs120.food.kcal).isCloseTo(155 * 1.2, 1e-9);
      check(eggs120.food.sourceFoodId).equals('egg');
    });

    test(
      'dangling food ref drops the item; dangling template drops the slot',
      () {
        final d = buildDayFromPlan(
          _plan(),
          thursday,
          _SeqIds().newId,
          [_lunchTpl], // tpl-b missing → breakfast slot dropped
          [_rice], // egg missing → lunch keeps only rice
        );
        check(d.meals.length).equals(1);
        check(d.meals.single.meal.items.length).equals(1);
        check(
          d.meals.single.meal.items.single.food.sourceFoodId,
        ).equals('rice');
      },
    );

    test('slot whose items ALL dangle is dropped entirely', () {
      final d = buildDayFromPlan(
        _plan(),
        thursday,
        _SeqIds().newId,
        [_breakfastTpl, _lunchTpl],
        [_rice], // egg missing → breakfast (egg-only) drops; lunch keeps rice
      );
      check(d.meals.length).equals(1);
      check(d.meals.single.meal.name).equals('Rice bowl');
    });
  });

  group('day kcal/macros', () {
    test(
      'planned sums all items; consumed sums checked only; empty day 0/0',
      () {
        final now = DateTime(2026, 6, 4, 12);
        final today = thursday;
        var d = buildDayFromPlan(
          _plan(),
          thursday,
          _SeqIds().newId,
          [_breakfastTpl, _lunchTpl],
          [_egg, _rice],
        );
        final expectedPlanned =
            155 * 1.2 + 130 * 1.5 + 155 * 0.6; // eggs120 + rice150 + egg60
        check(plannedKcal(d)).isCloseTo(expectedPlanned, 1e-9);
        check(consumedKcal(d)).equals(0);

        d = d.markAllEaten(d.meals[0].id, now, today); // breakfast done
        d = d.checkItem(d.meals[1].id, 0, now, today); // lunch: rice only
        check(consumedKcal(d)).isCloseTo(155 * 1.2 + 130 * 1.5, 1e-9);
        check(consumedKcal(d) <= plannedKcal(d)).isTrue();

        final rest = Day(date: thursday);
        check(plannedKcal(rest)).equals(0);
        check(consumedKcal(rest)).equals(0);
        check(plannedMacros(d).kcal).isCloseTo(plannedKcal(d), 1e-9);
        check(consumedMacros(d).kcal).isCloseTo(consumedKcal(d), 1e-9);
      },
    );
  });

  group('snoozeBaseFor', () {
    Day d() => buildDayFromPlan(
      _plan(),
      thursday,
      _SeqIds().newId,
      [_breakfastTpl, _lunchTpl],
      [_egg, _rice],
    );

    test('future meal → its scheduled instant (UTC)', () {
      // now = local 10:00, lunch scheduled 13:00
      final base = snoozeBaseFor(d(), 'id-1', DateTime(2026, 6, 4, 10));
      check(base).equals(
        localInstantAt(
          DateTime.utc(2026, 6, 4),
          const MealTime(13 * 60),
        ).toUtc(),
      );
      check(base.isUtc).isTrue();
    });
    test('past-due meal → now', () {
      final now = DateTime(2026, 6, 4, 15, 40); // breakfast 08:00 long passed
      check(snoozeBaseFor(d(), 'id-0', now)).equals(now.toUtc());
    });
    test('unknown meal throws', () {
      check(
        () => snoozeBaseFor(d(), 'nope', DateTime(2026, 6, 4, 10)),
      ).throws<StateError>();
    });
  });

  group('canUnmarkMeal', () {
    final now = DateTime(2026, 6, 4, 12);
    final today = thursday;
    final dayChecked = buildDayFromPlan(
      _plan(),
      thursday,
      _SeqIds().newId,
      [_breakfastTpl, _lunchTpl],
      [_egg, _rice],
    ).markAllEaten('id-1', now, today);
    final dayUnchecked = buildDayFromPlan(
      _plan(),
      thursday,
      _SeqIds().newId,
      [_breakfastTpl, _lunchTpl],
      [_egg, _rice],
    );

    test('true only when unlocked and any item checked', () {
      check(canUnmarkMeal(dayChecked, 'id-1', today)).isTrue();
      check(canUnmarkMeal(dayUnchecked, 'id-1', today)).isFalse();
      check(
        canUnmarkMeal(dayChecked, 'id-1', DateTime.utc(2026, 6, 5)),
      ).isFalse(); // locked
      check(canUnmarkMeal(dayChecked, 'nope', today)).isFalse();
    });
  });
}
