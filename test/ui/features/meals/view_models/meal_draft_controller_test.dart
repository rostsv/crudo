import 'package:checks/checks.dart';
import 'package:crudo/config/app_config.dart';
import 'package:crudo/config/di.dart';
import 'package:crudo/data/services/id_generator.dart';
import 'package:crudo/data/services/seed_service.dart';
import 'package:crudo/domain/food/food.dart';
import 'package:crudo/domain/meal/food_snapshot.dart';
import 'package:crudo/domain/shared/enums.dart';
import 'package:crudo/domain/shared/grams.dart';
import 'package:crudo/ui/features/meals/view_models/meal_draft_controller.dart';
import 'package:crudo/ui/features/today/view_models/day_controller.dart';
import 'package:crudo/ui/features/today/view_models/today_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/fake_id_generator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late List<Food> seedFoods;
  setUpAll(() async => seedFoods = await SeedService().loadFoods());

  var now = DateTime(2026, 6, 4, 9, 30);
  final today = DateTime.utc(2026, 6, 4);

  ProviderContainer container() {
    final c = ProviderContainer(
      overrides: [
        appConfigProvider.overrideWithValue(AppConfig(flavor: Flavor.dev)),
        seedFoodsProvider.overrideWithValue(seedFoods),
        clockProvider.overrideWithValue(() => now),
        idGeneratorProvider.overrideWithValue(FakeIdGenerator()),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  test('build loads the snapshot into a draft', () async {
    final c = container();
    final sub = c.listen(dayControllerProvider(today), (p, n) {});
    final day = await c.read(dayControllerProvider(today).future);
    final id = day.meals.first.id;
    final draft = await c.read(mealDraftControllerProvider(today, id).future);
    check(draft.name).equals('Protein Oats Bowl');
    check(draft.tags).deepEquals([MealTag.breakfast]);
    check(draft.items.length).equals(4);
    check(draft.sourceMealTemplateId).equals('demo-meal-breakfast');
    check(draft.canSave).isTrue();
    sub.close();
  });

  test('mutations: name, tag toggle, remove, grams rescale, add', () async {
    final c = container();
    final sub = c.listen(dayControllerProvider(today), (p, n) {});
    final day = await c.read(dayControllerProvider(today).future);
    final id = day.meals.first.id;
    await c.read(mealDraftControllerProvider(today, id).future);
    final ctrl = c.read(mealDraftControllerProvider(today, id).notifier);

    ctrl.setName('Big Bowl');
    ctrl.toggleTag(MealTag.snack); // add
    ctrl.toggleTag(MealTag.breakfast); // remove
    final before = c.read(mealDraftControllerProvider(today, id)).requireValue;
    final oatsKcal = before.items.first.kcal; // 80g oats
    ctrl.setItemGrams(0, const Grams(160)); // double it
    ctrl.removeItem(3);
    final oats = seedFoods.firstWhere((f) => f.id == 'seed-oats');
    ctrl.addItem(FoodSnapshot.from(oats, const Grams(40)));

    final d = c.read(mealDraftControllerProvider(today, id)).requireValue;
    check(d.name).equals('Big Bowl');
    check(d.tags).deepEquals([MealTag.snack]);
    check(d.items.length).equals(4); // 4 - 1 + 1
    check(d.items.first.kcal).equals(oatsKcal * 2);
    sub.close();
  });

  test('canSave gates: blank name, zero items', () async {
    final c = container();
    final sub = c.listen(dayControllerProvider(today), (p, n) {});
    final day = await c.read(dayControllerProvider(today).future);
    final id = day.meals.first.id;
    await c.read(mealDraftControllerProvider(today, id).future);
    final ctrl = c.read(mealDraftControllerProvider(today, id).notifier);
    ctrl.setName('   ');
    check(
      c.read(mealDraftControllerProvider(today, id)).requireValue.canSave,
    ).isFalse();
    ctrl.setName('Ok');
    for (var i = 3; i >= 0; i--) {
      ctrl.removeItem(i);
    }
    check(
      c.read(mealDraftControllerProvider(today, id)).requireValue.canSave,
    ).isFalse();
    await check(ctrl.save()).throws<StateError>();
    sub.close();
  });

  test('save commits once via replaceMeal: persisted, all unchecked', () async {
    final c = container();
    final sub = c.listen(dayControllerProvider(today), (p, n) {});
    final day = await c.read(dayControllerProvider(today).future);
    final id = day.meals[1].id; // lunch, upcoming at 09:30
    final draftSub = c.listen(
      mealDraftControllerProvider(today, id),
      (p, n) {},
    );
    await c.read(mealDraftControllerProvider(today, id).future);
    final ctrl = c.read(mealDraftControllerProvider(today, id).notifier);
    ctrl.setName('Big Bowl');
    await ctrl.save();
    await Future<void>.delayed(Duration.zero);
    final persisted = await c.read(dayRepositoryProvider).getByDate(today);
    final meal = persisted!.meals.firstWhere((m) => m.id == id);
    check(meal.meal.name).equals('Big Bowl');
    check(meal.meal.anyChecked).isFalse();
    check(meal.meal.sourceMealTemplateId).equals('demo-meal-lunch');
    draftSub.close();
    sub.close();
  });

  test('save on a checked meal surfaces the domain guard', () async {
    final c = container();
    final sub = c.listen(dayControllerProvider(today), (p, n) {});
    final day = await c.read(dayControllerProvider(today).future);
    final id = day.meals[1].id; // lunch, upcoming at 09:30
    final draftSub = c.listen(
      mealDraftControllerProvider(today, id),
      (p, n) {},
    );
    await c.read(mealDraftControllerProvider(today, id).future);
    await c.read(dayControllerProvider(today).notifier).checkItem(id, 0);
    await Future<void>.delayed(Duration.zero);
    await check(
      c.read(mealDraftControllerProvider(today, id).notifier).save(),
    ).throws<StateError>();
    draftSub.close();
    sub.close();
  });

  test(
    'external day write does NOT reset an in-progress draft (load-once)',
    () async {
      final c = container();
      final sub = c.listen(dayControllerProvider(today), (p, n) {});
      final day = await c.read(dayControllerProvider(today).future);
      final id = day.meals.first.id;
      final otherId = day.meals[1].id;
      final subDraft = c.listen(
        mealDraftControllerProvider(today, id),
        (p, n) {},
      );
      await c.read(mealDraftControllerProvider(today, id).future);
      final ctrl = c.read(mealDraftControllerProvider(today, id).notifier);
      ctrl.setName('Edited Name');
      // Simulate an S14-style background write while the editor is open:
      await c.read(dayControllerProvider(today).notifier).markAllEaten(otherId);
      await Future<void>.delayed(Duration.zero);
      check(
        c.read(mealDraftControllerProvider(today, id)).requireValue.name,
      ).equals('Edited Name'); // draft survived
      subDraft.close();
      sub.close();
    },
  );

  test(
    'isDirty: false on load, true after a mutation, false after revert',
    () async {
      final c = container();
      final sub = c.listen(dayControllerProvider(today), (p, n) {});
      final day = await c.read(dayControllerProvider(today).future);
      final id = day.meals.first.id;
      await c.read(mealDraftControllerProvider(today, id).future);
      final ctrl = c.read(mealDraftControllerProvider(today, id).notifier);
      check(ctrl.isDirty).isFalse();
      ctrl.setName('Changed');
      check(ctrl.isDirty).isTrue();
      ctrl.setName('Protein Oats Bowl'); // back to the loaded name
      check(ctrl.isDirty).isFalse();
      sub.close();
    },
  );
}
