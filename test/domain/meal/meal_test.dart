// test/domain/meal/meal_test.dart
import 'package:checks/checks.dart';
import 'package:crudo/domain/food/food.dart';
import 'package:crudo/domain/meal/food_snapshot.dart';
import 'package:crudo/domain/meal/meal_item.dart';
import 'package:crudo/domain/meal/meal_snapshot.dart';
import 'package:crudo/domain/meal/meal_template.dart';
import 'package:crudo/domain/shared/enums.dart';
import 'package:crudo/domain/shared/grams.dart';
import 'package:flutter_test/flutter_test.dart';

const _egg = Food(
  id: 'f1',
  name: 'Egg',
  kind: FoodKind.product,
  category: FoodCategory.eggs,
  protein: 13,
  carbs: 1.1,
  fats: 11,
  kcalPer100g: 155,
);

void main() {
  group('FoodSnapshot', () {
    group('scaledTo', () {
      const oats = Food(
        id: 'f-oats',
        name: 'Oats',
        kind: FoodKind.product,
        category: FoodCategory.grain,
        protein: 13,
        carbs: 60,
        fats: 7,
        kcalPer100g: 370,
      );

      test('scales absolutes linearly and replaces grams', () {
        final base = FoodSnapshot.from(oats, const Grams(100));
        final scaled = base.scaledTo(const Grams(150));
        check(scaled.grams).equals(const Grams(150));
        check(scaled.protein).equals(19.5);
        check(scaled.carbs).equals(90);
        check(scaled.fats).equals(10.5);
        check(scaled.kcal).equals(555);
        check(scaled.sourceFoodId).equals('f-oats');
        check(scaled.name).equals('Oats');
      });

      test('zero-macro food stays zero at any weight', () {
        const water = Food(
          id: 'f-water',
          name: 'Water',
          kind: FoodKind.product,
          category: FoodCategory.custom,
          protein: 0,
          carbs: 0,
          fats: 0,
          kcalPer100g: 0,
        );
        final scaled = FoodSnapshot.from(
          water,
          const Grams(100),
        ).scaledTo(const Grams(250));
        check(scaled.kcal).equals(0);
      });
    });

    test('from() bakes absolutes (per-100g × grams / 100)', () {
      final s = FoodSnapshot.from(_egg, const Grams(60));
      check(s.kcal).isCloseTo(93.0, 1e-9);
      check(s.protein).isCloseTo(7.8, 1e-9);
      check(s.carbs).isCloseTo(0.66, 1e-9);
      check(s.fats).isCloseTo(6.6, 1e-9);
      check(s.sourceFoodId).equals('f1');
      check(s.kind).equals(FoodKind.product);
      check(s.category).equals(FoodCategory.eggs);
    });

    test('from() rounds: 7 g of oil', () {
      const oil = Food(
        id: 'o',
        name: 'Oil',
        kind: FoodKind.product,
        category: FoodCategory.oil,
        protein: 0,
        carbs: 0,
        fats: 100,
        kcalPer100g: 884,
      );
      final s = FoodSnapshot.from(oil, const Grams(7));
      check(s.kcal).isCloseTo(61.88, 1e-9);
    });

    test('value equality + copyWith', () {
      final s = FoodSnapshot.from(_egg, const Grams(60));
      check(s.copyWith(name: 'Renamed').name).equals('Renamed');
      check(s).equals(FoodSnapshot.from(_egg, const Grams(60)));
    });

    test('asserts non-negative absolutes', () {
      check(
        () => FoodSnapshot(
          name: 'Bad',
          category: FoodCategory.custom,
          grams: const Grams(10),
          protein: 0,
          carbs: 0,
          fats: 0,
          kcal: -1,
        ),
      ).throws<AssertionError>();
    });
  });

  group('MealItem', () {
    FoodSnapshot snap() => FoodSnapshot.from(_egg, const Grams(100));

    test('unchecked by default; getter is `checked`', () {
      final it = MealItem(food: snap());
      check(it.checked).isFalse();
      check(it.checkedAt).isNull();
    });

    test('checkedAt non-null → checked', () {
      final it = MealItem(
        checkedAt: DateTime.utc(2026, 6, 4, 10),
        food: snap(),
      );
      check(it.checked).isTrue();
      check(it.checkedAt).equals(DateTime.utc(2026, 6, 4, 10));
    });

    test('rejects non-UTC checkedAt', () {
      check(
        () => MealItem(checkedAt: DateTime(2026, 6, 4, 12), food: snap()),
      ).throws<AssertionError>();
    });

    test('uncheck via copyWith(checkedAt: null)', () {
      final it = MealItem(
        checkedAt: DateTime.utc(2026, 6, 4, 10),
        food: snap(),
      );
      check(it.copyWith(checkedAt: null).checked).isFalse();
    });
  });

  group('MealSnapshot', () {
    FoodSnapshot snap() => FoodSnapshot.from(_egg, const Grams(100));

    test('defaults: empty items, no source', () {
      const m = MealSnapshot(name: 'Lunch');
      check(m.items).isEmpty();
      check(m.sourceMealTemplateId).isNull();
      check(m.anyChecked).isFalse();
      check(m.allChecked).isFalse();
    });

    test(
      'anyChecked true when at least one item checked; allChecked false',
      () {
        final m = MealSnapshot(
          name: 'Lunch',
          items: [
            MealItem(checkedAt: DateTime.utc(2026, 6, 4, 10), food: snap()),
            MealItem(food: snap()),
          ],
        );
        check(m.anyChecked).isTrue();
        check(m.allChecked).isFalse();
      },
    );

    test('allChecked true only when every item checked', () {
      final m = MealSnapshot(
        name: 'Lunch',
        items: [
          MealItem(checkedAt: DateTime.utc(2026, 6, 4, 10), food: snap()),
          MealItem(checkedAt: DateTime.utc(2026, 6, 4, 10), food: snap()),
        ],
      );
      check(m.allChecked).isTrue();
    });

    test('allChecked false when items list is empty (no implicit done)', () {
      const m = MealSnapshot(name: 'Empty');
      check(m.allChecked).isFalse();
    });
  });

  test('MealTemplate: time-free, defaults empty (foods field)', () {
    const t = MealTemplate(id: 'mt1', name: 'Breakfast');
    check(t.tags).isEmpty();
    check(t.foods).isEmpty();
  });
}
