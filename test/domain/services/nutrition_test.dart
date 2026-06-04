// test/domain/services/nutrition_test.dart
import 'package:checks/checks.dart';
import 'package:crudo/domain/food/food.dart';
import 'package:crudo/domain/food/food_ref.dart';
import 'package:crudo/domain/meal/food_snapshot.dart';
import 'package:crudo/domain/meal/meal_item.dart';
import 'package:crudo/domain/meal/meal_snapshot.dart';
import 'package:crudo/domain/meal/meal_template.dart';
import 'package:crudo/domain/services/nutrition.dart';
import 'package:crudo/domain/shared/enums.dart';
import 'package:crudo/domain/shared/grams.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('calculatedKcal applies 4/4/9', () {
    check(calculatedKcal(protein: 20, carbs: 30, fats: 10)).equals(290);
    check(calculatedKcal(protein: 0, carbs: 0, fats: 0)).equals(0);
  });

  test('isExplicitKcalValid: ±10% boundaries', () {
    check(isExplicitKcalValid(calculated: 100, explicit: 110)).isTrue();
    check(isExplicitKcalValid(calculated: 100, explicit: 111)).isFalse();
    check(isExplicitKcalValid(calculated: 100, explicit: 90)).isTrue();
    check(isExplicitKcalValid(calculated: 100, explicit: 89)).isFalse();
    check(isExplicitKcalValid(calculated: 0, explicit: 0)).isTrue();
    check(isExplicitKcalValid(calculated: 0, explicit: 1)).isFalse();
  });

  group('macrosForFood', () {
    final egg = Food(
      id: 'f1',
      name: 'Egg',
      category: FoodCategory.eggs,
      protein: 13,
      carbs: 1.1,
      fats: 11,
      kcalPer100g: 155,
    );

    test('scales per-100g values by grams/100', () {
      final m = macrosForFood(egg, 60);
      check(m.protein).isCloseTo(7.8, 1e-9);
      check(m.kcal).isCloseTo(93.0, 1e-9);
    });

    test('zero food × any grams = 0', () {
      final m = macrosForFood(
        Food(
          id: 'z',
          name: 'Z',
          category: FoodCategory.custom,
          protein: 0,
          carbs: 0,
          fats: 0,
          kcalPer100g: 0,
        ),
        250,
      );
      check(m.kcal).equals(0);
    });
  });

  group('isExplicitKcalValid', () {
    test('accepts within ±10% of formula', () {
      final calc = calculatedKcal(protein: 13, carbs: 1.1, fats: 11);
      check(
        isExplicitKcalValid(calculated: calc, explicit: calc * 1.09),
      ).isTrue();
      check(
        isExplicitKcalValid(calculated: calc, explicit: calc * 1.11),
      ).isFalse();
    });
  });

  test('mealTemplateMacros resolves via map, skips unresolved ids', () {
    const foods = {
      'p1': Food(
        id: 'p1',
        name: 'Chicken',
        category: FoodCategory.meat,
        protein: 31,
        carbs: 0,
        fats: 4,
        kcalPer100g: 160,
      ),
    };
    const template = MealTemplate(
      id: 'mt1',
      name: 'Lunch',
      foods: [
        FoodRef(foodId: 'p1', grams: Grams(100)),
        FoodRef(foodId: 'missing', grams: Grams(100)),
      ],
    );
    final m = mealTemplateMacros(template, foods);
    check(m.protein).equals(31);
    check(m.kcal).isCloseTo(160, 1e-9);
  });

  group('instance fns (S05 Task 3)', () {
    const egg = Food(
      id: 'f',
      name: 'Egg',
      kind: FoodKind.product,
      category: FoodCategory.eggs,
      protein: 13,
      carbs: 1.1,
      fats: 11,
      kcalPer100g: 155,
    );

    test('macrosOfSnapshot is a plain unpack', () {
      final s = FoodSnapshot.from(egg, const Grams(100));
      final m = macrosOfSnapshot(s);
      check(m.protein).equals(13);
      check(m.kcal).isCloseTo(155, 1e-9);
    });

    test(
      'mealSnapshotMacros sums all; consumedMealMacros sums checked only',
      () {
        final snap = FoodSnapshot.from(egg, const Grams(100));
        final m = MealSnapshot(
          name: 'Lunch',
          items: [
            MealItem(checkedAt: DateTime.utc(2026, 6, 4, 10), food: snap),
            MealItem(food: snap),
          ],
        );
        check(mealSnapshotMacros(m).protein).equals(26);
        check(consumedMealMacros(m).protein).equals(13);
      },
    );
  });
}
