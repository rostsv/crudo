// test/domain/food/food_test.dart
import 'package:checks/checks.dart';
import 'package:crudo/domain/food/food.dart';
import 'package:crudo/domain/food/food_ref.dart';
import 'package:crudo/domain/shared/enums.dart';
import 'package:crudo/domain/shared/grams.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const chicken = Food(
    id: '0197-aaaa',
    name: 'Chicken breast',
    kind: FoodKind.product,
    category: FoodCategory.meat,
    protein: 31,
    carbs: 0,
    fats: 3.6,
    kcalPer100g: 165,
  );

  test('defaults: kind=product, not custom', () {
    check(chicken.kind).equals(FoodKind.product);
    check(chicken.isCustom).isFalse();
  });

  test('value equality + copyWith', () {
    check(chicken.copyWith(name: 'Chicken thigh').name).equals('Chicken thigh');
    check(chicken.copyWith(name: 'Chicken thigh').protein).equals(31);
  });

  test('asserts non-negative macros + kcal', () {
    check(
      () => Food(
        id: 'x',
        name: 'Bad',
        kind: FoodKind.product,
        category: FoodCategory.custom,
        protein: -1,
        carbs: 0,
        fats: 0,
        kcalPer100g: 0,
      ),
    ).throws<AssertionError>();
    check(
      () => Food(
        id: 'x',
        name: 'Bad',
        kind: FoodKind.product,
        category: FoodCategory.custom,
        protein: 0,
        carbs: 0,
        fats: 0,
        kcalPer100g: -5,
      ),
    ).throws<AssertionError>();
  });

  test('food ref holds Grams VO', () {
    const ref = FoodRef(foodId: '0197-aaaa', grams: Grams(150));
    check(ref.foodId).equals('0197-aaaa');
    check(ref.grams.value).equals(150);
    check(ref).equals(const FoodRef(foodId: '0197-aaaa', grams: Grams(150)));
  });

  test('FoodKind has product and dish values', () {
    // the engine never reads it, but the enum must exist for library display
    check(FoodKind.values).deepEquals([FoodKind.product, FoodKind.dish]);
  });
}
