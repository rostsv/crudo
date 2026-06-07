import 'package:checks/checks.dart';
import 'package:crudo/config/di.dart';
import 'package:crudo/domain/food/food.dart';
import 'package:crudo/domain/shared/enums.dart';
import 'package:crudo/ui/features/foods/view_models/food_library.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _chicken = Food(
  id: 'seed-chicken-breast',
  name: 'Chicken breast',
  category: FoodCategory.meat,
  protein: 31,
  carbs: 0,
  fats: 3.6,
  kcalPer100g: 156.4,
);
const _turkey = Food(
  id: 'seed-turkey',
  name: 'Turkey',
  category: FoodCategory.meat,
  protein: 29,
  carbs: 0,
  fats: 1,
  kcalPer100g: 125,
);
const _broccoli = Food(
  id: 'seed-broccoli',
  name: 'Broccoli',
  category: FoodCategory.veg,
  protein: 2.8,
  carbs: 7,
  fats: 0.4,
  kcalPer100g: 42.8,
);
const _shake = Food(
  id: 'c1',
  name: 'My shake',
  category: FoodCategory.custom,
  protein: 30,
  carbs: 10,
  fats: 5,
  kcalPer100g: 205,
  isCustom: true,
);
const _soup = Food(
  id: 'c2',
  name: 'Mom soup',
  kind: FoodKind.dish,
  category: FoodCategory.custom,
  protein: 5,
  carbs: 8,
  fats: 3,
  kcalPer100g: 79,
  isCustom: true,
);

void main() {
  ProviderContainer container() {
    final c = ProviderContainer(
      overrides: [
        seedFoodsProvider.overrideWithValue(const [
          _chicken,
          _turkey,
          _broccoli,
          _shake,
          _soup,
        ]),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  test(
    'groups: category enum order, dishes last, empty groups omitted',
    () async {
      final c = container();
      c.listen(foodLibraryProvider, (_, _) {});
      final groups = await c.read(foodLibraryProvider.future);
      check(
        groups.map((g) => g.label).toList(),
      ).deepEquals(['Meat', 'Vegetables', 'Custom', 'Dishes']);
    },
  );

  test('alphabetical within a group (case-insensitive)', () async {
    final c = container();
    c.listen(foodLibraryProvider, (_, _) {});
    final groups = await c.read(foodLibraryProvider.future);
    check(
      groups.first.foods.map((f) => f.name).toList(),
    ).deepEquals(['Chicken breast', 'Turkey']);
  });

  test('search: case-insensitive contains', () async {
    final c = container();
    c.listen(foodLibraryProvider, (_, _) {});
    c.read(foodSearchQueryProvider.notifier).setQuery('  BROC');
    // note: leading whitespace trimmed, case ignored
    final groups = await c.read(foodLibraryProvider.future);
    check(groups.map((g) => g.label).toList()).deepEquals(['Vegetables']);
    check(groups.single.foods.single.name).equals('Broccoli');
  });

  test('no match → empty list', () async {
    final c = container();
    c.listen(foodLibraryProvider, (_, _) {});
    c.read(foodSearchQueryProvider.notifier).setQuery('zzz');
    check(await c.read(foodLibraryProvider.future)).isEmpty();
  });

  test('repo save re-emits: a new custom food appears', () async {
    final c = container();
    c.listen(foodLibraryProvider, (_, _) {}); // keep alive across emissions
    await c.read(foodLibraryProvider.future);
    await c
        .read(foodRepositoryProvider)
        .save(
          const Food(
            id: 'c3',
            name: 'Bar',
            category: FoodCategory.custom,
            protein: 20,
            carbs: 30,
            fats: 10,
            kcalPer100g: 290,
            isCustom: true,
          ),
        );
    await Future<void>.delayed(Duration.zero); // let the stream emit
    final groups = await c.read(foodLibraryProvider.future);
    final custom = groups.singleWhere((g) => g.label == 'Custom');
    check(
      custom.foods.map((f) => f.name).toList(),
    ).deepEquals(['Bar', 'My shake']);
  });
}
