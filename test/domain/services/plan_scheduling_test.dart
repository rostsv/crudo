import 'package:checks/checks.dart';
import 'package:crudo/domain/food/food_ref.dart';
import 'package:crudo/domain/meal/meal_template.dart';
import 'package:crudo/domain/plan/plan_slot.dart';
import 'package:crudo/domain/plan/plan_template.dart';
import 'package:crudo/domain/services/plan_scheduling.dart';
import 'package:crudo/domain/shared/enums.dart';
import 'package:crudo/domain/shared/grams.dart';
import 'package:crudo/domain/shared/meal_time.dart';
import 'package:flutter_test/flutter_test.dart';

// Tasks 2–4 add imports as their tests need them (meal_time, grams, enums,
// food_ref, meal_template). Keep the import list minimal per task to stay
// `flutter analyze`-clean between reviews.

PlanTemplate _plan({
  String id = 'p1',
  bool active = true,
  List<int> days = const [0, 1, 2, 3, 4], // Mon–Fri
  List<PlanSlot> slots = const [],
}) => PlanTemplate(
  id: id,
  name: 'Plan $id',
  days: days,
  active: active,
  slots: slots,
);

class _SeqIds {
  int _n = 0;
  String next() => 'gen-${_n++}';
}

void main() {
  final thursday = DateTime.utc(2026, 6, 4); // Thursday
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

  group('detectConflicts', () {
    test('no overlap → empty', () {
      final plans = [
        _plan(id: 'a', days: [0, 1]),
      ];
      check(
        detectConflicts(plans, forPlanId: 'b', proposedDays: [2, 3]),
      ).isEmpty();
    });
    test('one other plan claims a proposed day → one entry', () {
      final plans = [
        _plan(id: 'a', days: [0, 1, 2]),
      ];
      final c = detectConflicts(plans, forPlanId: 'b', proposedDays: [2, 5]);
      check(
        c,
      ).deepEquals([(weekday: 2, otherPlanId: 'a', otherPlanName: 'Plan a')]);
    });
    test('forPlanId own days are not a conflict', () {
      final plans = [
        _plan(id: 'a', days: [0, 1, 2]),
      ];
      check(
        detectConflicts(plans, forPlanId: 'a', proposedDays: [0, 1]),
      ).isEmpty();
    });
    test('inactive conflicting plan ignored', () {
      final plans = [
        _plan(id: 'a', active: false, days: [2]),
      ];
      check(
        detectConflicts(plans, forPlanId: 'b', proposedDays: [2]),
      ).isEmpty();
    });
    test('two plans conflicting on different days → two entries', () {
      final plans = [
        _plan(id: 'a', days: [1]),
        _plan(id: 'c', days: [3]),
      ];
      final c = detectConflicts(plans, forPlanId: 'b', proposedDays: [1, 3]);
      check(c.length).equals(2);
      check(
        c,
      ).contains((weekday: 1, otherPlanId: 'a', otherPlanName: 'Plan a'));
      check(
        c,
      ).contains((weekday: 3, otherPlanId: 'c', otherPlanName: 'Plan c'));
    });
  });

  group('applyOverride', () {
    test('steals the contested weekday from the other plan', () {
      final plans = [
        _plan(id: 'a', days: [0, 1, 2]),
        _plan(id: 'b', days: []),
      ];
      final changed = applyOverride(plans, forPlanId: 'b', proposedDays: [2]);
      final a = changed.firstWhere((p) => p.id == 'a');
      final b = changed.firstWhere((p) => p.id == 'b');
      check(a.days).deepEquals([0, 1]);
      check(b.days).deepEquals([2]);
    });
    test('returns only changed plans', () {
      final plans = [
        _plan(id: 'a', days: [0]),
        _plan(id: 'b', days: []),
        _plan(id: 'c', days: [5]), // untouched
      ];
      final changed = applyOverride(plans, forPlanId: 'b', proposedDays: [0]);
      check(changed.map((p) => p.id).toList()).deepEquals(['a', 'b']);
    });
    test('other plan emptied when it only held the stolen day', () {
      final plans = [
        _plan(id: 'a', days: [2]),
        _plan(id: 'b', days: []),
      ];
      final a = applyOverride(
        plans,
        forPlanId: 'b',
        proposedDays: [2],
      ).firstWhere((p) => p.id == 'a');
      check(a.days).isEmpty();
    });
    test('no real change → empty result', () {
      final plans = [
        _plan(id: 'b', days: [3]),
      ];
      check(applyOverride(plans, forPlanId: 'b', proposedDays: [3])).isEmpty();
    });
  });

  group('canDeletePlan', () {
    test('zero plans → false', () => check(canDeletePlan([])).isFalse());
    test('one plan → false', () => check(canDeletePlan([_plan()])).isFalse());
    test('two plans → true', () {
      check(canDeletePlan([_plan(id: 'a'), _plan(id: 'b')])).isTrue();
    });
    test('inactive plans still count toward the floor', () {
      check(
        canDeletePlan([_plan(id: 'a'), _plan(id: 'b', active: false)]),
      ).isTrue();
    });
  });

  group('uncoveredWeekdays', () {
    test('full coverage → empty', () {
      check(
        uncoveredWeekdays([
          _plan(days: [0, 1, 2, 3, 4, 5, 6]),
        ]),
      ).isEmpty();
    });
    test('Mon–Fri plan → weekend uncovered', () {
      check(
        uncoveredWeekdays([
          _plan(days: [0, 1, 2, 3, 4]),
        ]),
      ).deepEquals([5, 6]);
    });
    test('no active plans → all seven uncovered', () {
      check(
        uncoveredWeekdays([
          _plan(active: false, days: [0, 1, 2, 3, 4]),
        ]),
      ).deepEquals([0, 1, 2, 3, 4, 5, 6]);
    });
    test('overlapping plans dedupe coverage', () {
      final plans = [
        _plan(id: 'a', days: [0, 1, 2]),
        _plan(id: 'b', days: [2, 3]),
      ];
      check(uncoveredWeekdays(plans)).deepEquals([4, 5, 6]);
    });
  });

  group('clonePlan', () {
    test('clears days and copies name with suffix', () {
      final ids = _SeqIds();
      final src = _plan(id: 'p1', days: [0, 1, 2]);
      final clone = clonePlan(src, newId: ids.next);
      check(clone.days).isEmpty();
      check(clone.name).equals('Plan p1 copy');
      check(clone.id == 'p1').isFalse();
      check(clone.active).equals(src.active);
    });
    test('re-mints fresh slot ids, preserves mealTemplateId + time', () {
      final ids = _SeqIds();
      final src = _plan(
        id: 'p1',
        slots: const [
          PlanSlot(id: 's1', mealTemplateId: 'm1', time: MealTime(480)),
        ],
      );
      final clone = clonePlan(src, newId: ids.next);
      check(clone.slots.single.id == 's1').isFalse();
      check(clone.slots.single.mealTemplateId).equals('m1');
      check(clone.slots.single.time).equals(const MealTime(480));
    });
  });

  group('cloneMeal', () {
    test('new id, suffixed name, copies tags + foods', () {
      final ids = _SeqIds();
      const src = MealTemplate(
        id: 'm1',
        name: 'Breakfast',
        tags: [MealTag.breakfast],
        foods: [FoodRef(foodId: 'egg', grams: Grams(100))],
      );
      final clone = cloneMeal(src, newId: ids.next);
      check(clone.id == 'm1').isFalse();
      check(clone.name).equals('Breakfast copy');
      check(clone.tags).deepEquals([MealTag.breakfast]);
      check(
        clone.foods,
      ).deepEquals([const FoodRef(foodId: 'egg', grams: Grams(100))]);
    });
  });
}
