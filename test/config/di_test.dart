import 'package:checks/checks.dart';
import 'package:crudo/config/di.dart';
import 'package:crudo/domain/food/food.dart';
import 'package:crudo/domain/shared/enums.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('all repo providers resolve against an overridden seed', () async {
    const seed = [
      Food(
        id: 's1',
        name: 'Egg',
        kind: FoodKind.product,
        category: FoodCategory.eggs,
        protein: 13,
        carbs: 1.1,
        fats: 11,
        kcalPer100g: 155,
      ),
    ];
    final container = ProviderContainer(
      overrides: [seedFoodsProvider.overrideWithValue(seed)],
    );
    addTearDown(container.dispose);

    check(
      (await container.read(foodRepositoryProvider).getAll()).length,
    ).equals(1);
    check(
      await container.read(mealTemplateRepositoryProvider).getAll(),
    ).isEmpty();
    check(
      await container.read(planTemplateRepositoryProvider).getAll(),
    ).isEmpty();
    check(
      await container
          .read(dayRepositoryProvider)
          .getByDate(DateTime.utc(2026, 6, 3)),
    ).isNull();
    check(
      (await container.read(profileRepositoryProvider).get()).id,
    ).equals('local');
    check(
      (await container.read(streakRepositoryProvider).get()).current,
    ).equals(0);
  });

  test('seedFoodsProvider throws when not overridden', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    check(() => container.read(seedFoodsProvider)).throws<Object>();
  });
}
