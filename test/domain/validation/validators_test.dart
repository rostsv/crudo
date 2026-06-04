// test/domain/validation/validators_test.dart
import 'package:checks/checks.dart';
import 'package:crudo/domain/day/day.dart';
import 'package:crudo/domain/day/scheduled_meal.dart';
import 'package:crudo/domain/food/food.dart';
import 'package:crudo/domain/meal/food_snapshot.dart';
import 'package:crudo/domain/meal/meal_item.dart';
import 'package:crudo/domain/meal/meal_snapshot.dart';
import 'package:crudo/domain/meal/meal_template.dart';
import 'package:crudo/domain/plan/plan_slot.dart';
import 'package:crudo/domain/plan/plan_template.dart';
import 'package:crudo/domain/profile/prefs.dart';
import 'package:crudo/domain/profile/user_profile.dart';
import 'package:crudo/domain/shared/enums.dart';
import 'package:crudo/domain/shared/grams.dart';
import 'package:crudo/domain/shared/meal_time.dart';
import 'package:crudo/domain/validation/validation_issue.dart';
import 'package:crudo/domain/validation/validators.dart';
import 'package:flutter_test/flutter_test.dart';

Food _food({
  String name = 'Chicken',
  double p = 20,
  double c = 30,
  double f = 10,
  double kcal = 290,
}) => Food(
  id: 'x',
  name: name,
  kind: FoodKind.product,
  category: FoodCategory.meat,
  protein: p,
  carbs: c,
  fats: f,
  kcalPer100g: kcal,
);

const _egg = Food(
  id: 'e',
  name: 'Eggs',
  kind: FoodKind.product,
  category: FoodCategory.eggs,
  protein: 13,
  carbs: 1,
  fats: 11,
  kcalPer100g: 155,
);

FoodSnapshot _snap() => FoodSnapshot.from(_egg, const Grams(100));

MealSnapshot _mealSnap({
  String name = 'Lunch',
  List<MealItem> items = const [],
}) => MealSnapshot(name: name, items: items);

ScheduledMeal _sm({String id = 'm1', String name = 'Lunch'}) => ScheduledMeal(
  id: id,
  time: const MealTime(12 * 60),
  meal: _mealSnap(name: name),
);

void main() {
  List<ValidationCode> codes(List<ValidationIssue> issues) =>
      issues.map((i) => i.code).toList();

  test('valid food → no issues', () {
    check(_food().validate()).isEmpty();
  });

  test('food: blank name', () {
    check(
      codes(_food(name: '  ').validate()),
    ).contains(ValidationCode.blankName);
  });

  test('food: macro mass > 100g per 100g (±1g tolerance)', () {
    check(
      codes(_food(p: 60, c: 50, f: 0).validate()),
    ).contains(ValidationCode.macroMassExceeded);
    check(_food(p: 60, c: 40, f: 0.9).validate()).isEmpty(); // 100.9 ≤ 101 ok
  });

  test('food: stored kcalPer100g is not validated against formula', () {
    // the ±10% rule is enforced at INPUT time (S07) — stored value is trusted
    check(_food(p: 20, c: 30, f: 10, kcal: 1000).validate()).isEmpty();
  });

  test('meal template: blank name + empty foods', () {
    check(codes(const MealTemplate(id: 't', name: '').validate()))
      ..contains(ValidationCode.blankName)
      ..contains(ValidationCode.emptyMeal);
    check(_mealSnap(items: [MealItem(food: _snap())]).validate()).isEmpty();
  });

  test('MealSnapshot: blank name + empty items', () {
    check(codes(_mealSnap(name: ' ').validate()))
      ..contains(ValidationCode.blankName)
      ..contains(ValidationCode.emptyMeal);
  });

  test('plan slot: blank meal template id', () {
    check(
      codes(
        const PlanSlot(
          id: 's',
          mealTemplateId: '',
          time: MealTime(480),
        ).validate(),
      ),
    ).contains(ValidationCode.blankMealTemplateId);
  });

  test('plan template: duplicates + empty active plan', () {
    const slot = PlanSlot(id: 's', mealTemplateId: 'mt', time: MealTime(480));
    check(
      codes(const PlanTemplate(id: 'p', name: 'Cut', days: [1, 1]).validate()),
    ).contains(ValidationCode.duplicateWeekday);
    check(
      codes(const PlanTemplate(id: 'p', name: 'Cut').validate()),
    ).contains(ValidationCode.emptyActivePlan);
    check(
      const PlanTemplate(id: 'p', name: 'Cut', active: false).validate(),
    ).isEmpty(); // inactive may be slotless
    check(
      const PlanTemplate(
        id: 'p',
        name: 'Cut',
        days: [0, 1],
        slots: [slot],
      ).validate(),
    ).isEmpty();
  });

  test('plan template: invalid weekday range', () {
    check(
      codes(const PlanTemplate(id: 'p', name: 'Cut', days: [7]).validate()),
    ).contains(ValidationCode.invalidWeekday);
    check(
      codes(const PlanTemplate(id: 'p', name: 'Cut', days: [-1]).validate()),
    ).contains(ValidationCode.invalidWeekday);
  });

  test('day: duplicate meal ids', () {
    final d = Day(
      date: DateTime.utc(2026, 6, 3),
      meals: [
        _sm(id: 'm1'),
        _sm(id: 'm1'),
      ],
    );
    check(codes(d.validate())).contains(ValidationCode.duplicateMealId);
  });

  test('prefs: threshold set, target, preMin cap', () {
    check(
      codes(const Prefs(streakThreshold: 75).validate()),
    ).contains(ValidationCode.invalidThreshold);
    check(
      codes(const Prefs(dailyKcalTarget: 0).validate()),
    ).contains(ValidationCode.nonPositiveTarget);
    check(
      codes(const Prefs(preMin: 500).validate()),
    ).contains(ValidationCode.preMinTooLarge);
    check(const Prefs(dailyKcalTarget: 2200).validate()).isEmpty();
  });

  test('user profile: blank id', () {
    check(
      codes(const UserProfile(id: ' ').validate()),
    ).contains(ValidationCode.blankId);
  });
}
