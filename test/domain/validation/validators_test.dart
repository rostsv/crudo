// test/domain/validation/validators_test.dart
import 'package:checks/checks.dart';
import 'package:crudo/domain/day/day.dart';
import 'package:crudo/domain/meal/meal.dart';
import 'package:crudo/domain/meal/meal_product.dart';
import 'package:crudo/domain/meal/meal_template.dart';
import 'package:crudo/domain/plan/plan_slot.dart';
import 'package:crudo/domain/plan/plan_template.dart';
import 'package:crudo/domain/product/product.dart';
import 'package:crudo/domain/profile/prefs.dart';
import 'package:crudo/domain/profile/user_profile.dart';
import 'package:crudo/domain/shared/enums.dart';
import 'package:crudo/domain/shared/grams.dart';
import 'package:crudo/domain/shared/meal_time.dart';
import 'package:crudo/domain/validation/validation_issue.dart';
import 'package:crudo/domain/validation/validators.dart';
import 'package:flutter_test/flutter_test.dart';

Product _product({
  String name = 'Chicken',
  double p = 20,
  double c = 30,
  double f = 10,
  double? kcal,
}) => Product(
  id: 'x',
  name: name,
  category: ProductCategory.meat,
  protein: p,
  carbs: c,
  fats: f,
  kcalOverride: kcal,
);

Meal _meal({
  String id = 'm1',
  String name = 'Lunch',
  List<MealProduct> products = const [],
}) => Meal(id: id, time: const MealTime(720), name: name, products: products);

const _snap = MealProduct(
  name: 'Eggs',
  category: ProductCategory.eggs,
  protein: 13,
  carbs: 1,
  fats: 11,
  grams: Grams(100),
);

void main() {
  List<ValidationCode> codes(List<ValidationIssue> issues) =>
      issues.map((i) => i.code).toList();

  test('valid product → no issues', () {
    check(_product(kcal: 300).validate()).isEmpty(); // calc 290, within 10%
  });

  test('product: blank name', () {
    check(
      codes(_product(name: '  ').validate()),
    ).contains(ValidationCode.blankName);
  });

  test('product: kcal override out of ±10%', () {
    check(
      codes(_product(kcal: 400).validate()),
    ).contains(ValidationCode.kcalOverrideOutOfRange);
    check(
      codes(_product(kcal: -5).validate()),
    ).contains(ValidationCode.kcalOverrideOutOfRange);
  });

  test('product: macro mass > 100g per 100g (±1g tolerance)', () {
    check(
      codes(_product(p: 60, c: 50, f: 0).validate()),
    ).contains(ValidationCode.macroMassExceeded);
    check(
      _product(p: 60, c: 40, f: 0.9).validate(),
    ).isEmpty(); // 100.9 ≤ 101 ok
  });

  test('meal product snapshot: same rules apply', () {
    final bad = _snap.copyWith(name: '', kcalOverride: 999);
    check(codes(bad.validate()))
      ..contains(ValidationCode.blankName)
      ..contains(ValidationCode.kcalOverrideOutOfRange);
  });

  test('meal template / instance meal: blank name + empty products', () {
    check(codes(const MealTemplate(id: 't', name: '').validate()))
      ..contains(ValidationCode.blankName)
      ..contains(ValidationCode.emptyMeal);
    check(codes(_meal(name: ' ').validate()))
      ..contains(ValidationCode.blankName)
      ..contains(ValidationCode.emptyMeal);
    check(_meal(products: [_snap]).validate()).isEmpty();
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
        _meal(products: [_snap]),
        _meal(products: [_snap]),
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
