// test/domain/services/nutrition_test.dart
import 'package:checks/checks.dart';
import 'package:crudo/domain/meal/meal.dart';
import 'package:crudo/domain/meal/meal_product.dart';
import 'package:crudo/domain/meal/meal_template.dart';
import 'package:crudo/domain/product/product.dart';
import 'package:crudo/domain/product/product_ref.dart';
import 'package:crudo/domain/services/nutrition.dart';
import 'package:crudo/domain/shared/enums.dart';
import 'package:crudo/domain/shared/grams.dart';
import 'package:crudo/domain/shared/meal_time.dart';
import 'package:flutter_test/flutter_test.dart';

MealProduct _snap(
  String name, {
  double p = 0,
  double c = 0,
  double f = 0,
  double? kcal,
  double g = 100,
  bool checked = false,
}) => MealProduct(
  name: name,
  category: ProductCategory.custom,
  protein: p,
  carbs: c,
  fats: f,
  kcalOverride: kcal,
  grams: Grams(g),
  checked: checked,
);

void main() {
  test('calculatedKcal applies 4/4/9', () {
    check(calculatedKcal(protein: 20, carbs: 30, fats: 10)).equals(290);
    check(calculatedKcal(protein: 0, carbs: 0, fats: 0)).equals(0);
  });

  test('isKcalOverrideValid: ±10% boundaries', () {
    check(isKcalOverrideValid(calculated: 100, override: 110)).isTrue();
    check(isKcalOverrideValid(calculated: 100, override: 111)).isFalse();
    check(isKcalOverrideValid(calculated: 100, override: 90)).isTrue();
    check(isKcalOverrideValid(calculated: 100, override: 89)).isFalse();
    check(isKcalOverrideValid(calculated: 0, override: 0)).isTrue();
    check(isKcalOverrideValid(calculated: 0, override: 1)).isFalse();
  });

  test('effectiveKcalPer100g: valid override honored, invalid ignored', () {
    // calc = 20*4 + 30*4 + 10*9 = 290
    check(
      effectiveKcalPer100g(protein: 20, carbs: 30, fats: 10, kcalOverride: 300),
    ).equals(300);
    check(
      effectiveKcalPer100g(protein: 20, carbs: 30, fats: 10, kcalOverride: 400),
    ).equals(290);
    check(effectiveKcalPer100g(protein: 20, carbs: 30, fats: 10)).equals(290);
  });

  test('macrosForProduct scales by grams/100 (integer-clean → exact)', () {
    final m = macrosForProduct(_snap('a', p: 30, c: 0, f: 10, g: 200));
    check(m.protein).equals(60);
    check(m.fats).equals(20);
    check(m.kcal).equals(420); // (30*4 + 10*9) * 2
  });

  test('mealMacros sums all; consumedMacros sums checked only', () {
    final meal = Meal(
      id: 'm1',
      time: const MealTime(720),
      name: 'Lunch',
      products: [
        _snap('chicken', p: 31, f: 4, checked: true),
        _snap('rice', c: 23),
      ],
    );
    check(mealMacros(meal).protein).equals(31);
    check(mealMacros(meal).carbs).equals(23);
    check(consumedMacros(meal).protein).equals(31);
    check(consumedMacros(meal).carbs).equals(0);
  });

  test('mealTemplateMacros resolves via map, skips unresolved ids', () {
    const products = {
      'p1': Product(
        id: 'p1',
        name: 'Chicken',
        category: ProductCategory.meat,
        protein: 31,
        carbs: 0,
        fats: 4,
      ),
    };
    const template = MealTemplate(
      id: 'mt1',
      name: 'Lunch',
      products: [
        ProductRef(productId: 'p1', grams: Grams(100)),
        ProductRef(productId: 'missing', grams: Grams(100)),
      ],
    );
    final m = mealTemplateMacros(template, products);
    check(m.protein).equals(31);
    check(m.kcal).equals(160); // 31*4 + 4*9
  });
}
