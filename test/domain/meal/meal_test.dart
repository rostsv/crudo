// test/domain/meal/meal_test.dart
import 'package:checks/checks.dart';
import 'package:crudo/domain/meal/meal.dart';
import 'package:crudo/domain/meal/meal_product.dart';
import 'package:crudo/domain/meal/meal_template.dart';
import 'package:crudo/domain/shared/enums.dart';
import 'package:crudo/domain/shared/grams.dart';
import 'package:crudo/domain/shared/meal_time.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const eggs = MealProduct(
    sourceProductId: '0197-eggs',
    name: 'Eggs',
    category: ProductCategory.eggs,
    protein: 13,
    carbs: 1,
    fats: 11,
    grams: Grams(120),
  );

  test('meal template: time-free, defaults empty', () {
    const t = MealTemplate(id: 'mt1', name: 'Breakfast');
    check(t.tags).isEmpty();
    check(t.products).isEmpty();
  });

  test('meal product snapshot: defaults unchecked, keeps back-ref', () {
    check(eggs.checked).isFalse();
    check(eggs.sourceProductId).equals('0197-eggs');
    check(eggs.copyWith(checked: true).checked).isTrue();
  });

  test('meal product: detached snapshot may have no source', () {
    check(eggs.copyWith(sourceProductId: null).sourceProductId).isNull();
  });

  test('instance meal wraps time + snapshot products, no status field', () {
    const meal = Meal(
      id: 'm1',
      time: MealTime(480),
      sourceMealTemplateId: 'mt1',
      name: 'Breakfast',
      tags: [MealTag.breakfast],
      products: [eggs],
    );
    check(meal.time.hour).equals(8);
    check(meal.products.single.name).equals('Eggs');
    // content swap keeps the slot id (notifications key off it):
    final swapped = meal.copyWith(
      name: 'Restaurant',
      sourceMealTemplateId: null,
      products: [],
    );
    check(swapped.id).equals('m1');
    check(swapped.time).equals(const MealTime(480));
  });

  test('asserts non-negative snapshot macros', () {
    check(
      () => MealProduct(
        name: 'Bad',
        category: ProductCategory.custom,
        protein: 0,
        carbs: -2,
        fats: 0,
        grams: Grams(10),
      ),
    ).throws<AssertionError>();
  });
}
