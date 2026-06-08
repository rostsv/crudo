// test/ui/features/plans/view_models/plan_detail_controller_test.dart
import 'package:checks/checks.dart';
import 'package:crudo/config/di.dart';
import 'package:crudo/data/repositories/in_memory_food_repository.dart';
import 'package:crudo/data/repositories/in_memory_meal_template_repository.dart';
import 'package:crudo/data/repositories/in_memory_plan_template_repository.dart';
import 'package:crudo/data/repositories/in_memory_profile_repository.dart';
import 'package:crudo/domain/food/food.dart';
import 'package:crudo/domain/food/food_ref.dart';
import 'package:crudo/domain/meal/meal_template.dart';
import 'package:crudo/domain/plan/plan_slot.dart';
import 'package:crudo/domain/plan/plan_template.dart';
import 'package:crudo/domain/profile/prefs.dart';
import 'package:crudo/domain/profile/user_profile.dart';
import 'package:crudo/domain/repositories/plan_template_repository.dart';
import 'package:crudo/domain/shared/enums.dart';
import 'package:crudo/domain/shared/grams.dart';
import 'package:crudo/domain/shared/meal_time.dart';
import 'package:crudo/ui/features/plans/view_models/plan_detail_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Food food1;
  late MealTemplate mt1;

  setUp(() {
    food1 = Food(
      id: 'f1',
      name: 'Chicken',
      category: FoodCategory.meat,
      protein: 30,
      carbs: 0,
      fats: 5,
      kcalPer100g: 165,
    );
    mt1 = MealTemplate(
      id: 'mt1',
      name: 'Breakfast',
      foods: [FoodRef(foodId: 'f1', grams: const Grams(100))],
    );
  });

  PlanTemplate plan(
    String id, {
    required List<int> days,
    bool active = true,
    List<PlanSlot> slots = const [],
    String name = 'Plan',
  }) => PlanTemplate(
    id: id,
    name: name,
    days: days,
    active: active,
    slots: slots,
  );

  Future<ProviderContainer> createContainer(List<PlanTemplate> plans) async {
    final profileRepo = InMemoryProfileRepository();
    await profileRepo.save(const UserProfile(id: 'test', prefs: Prefs()));
    return ProviderContainer(
      overrides: [
        foodRepositoryProvider.overrideWithValue(
          InMemoryFoodRepository(seed: [food1]),
        ),
        mealTemplateRepositoryProvider.overrideWithValue(
          InMemoryMealTemplateRepository(seed: [mt1]),
        ),
        planTemplateRepositoryProvider.overrideWithValue(
          InMemoryPlanTemplateRepository(seed: plans),
        ),
        profileRepositoryProvider.overrideWithValue(profileRepo),
      ],
    );
  }

  PlanTemplateRepository repoOf(ProviderContainer c) =>
      c.read(planTemplateRepositoryProvider);

  group('PlanDetailController.build', () {
    test('resolves draft fields + slot VMs; unknown id throws', () async {
      final a = plan(
        'A',
        days: [0, 2],
        name: 'Cut',
        slots: [
          PlanSlot(id: 's1', mealTemplateId: 'mt1', time: const MealTime(480)),
        ],
      );
      final c = await createContainer([a]);
      addTearDown(c.dispose);

      final draft = await c.read(planDetailControllerProvider('A').future);
      check(draft.name).equals('Cut');
      check(draft.days).deepEquals([0, 2]);
      check(draft.active).isTrue();
      check(draft.slots).length.equals(1);
      check(draft.slots.first.mealName).equals('Breakfast');
      check(draft.slots.first.kcal).equals(165);

      await expectLater(
        c.read(planDetailControllerProvider('nope').future),
        throwsA(isA<StateError>()),
      );
    });
  });

  group('PlanDetailController.save', () {
    test(
      'no conflict → persists only self with new name/days/active',
      () async {
        final c = await createContainer([
          plan('A', days: [0], name: 'Cut'),
          plan('B', days: [5], name: 'Weekend'),
        ]);
        addTearDown(c.dispose);

        await c.read(planDetailControllerProvider('A').future);
        final ctrl = c.read(planDetailControllerProvider('A').notifier);
        ctrl.setName('Cut2');
        ctrl.toggleDay(2);

        final out = await ctrl.save();
        check(out.committed).isTrue();
        check(out.conflicts).isEmpty();

        final a = (await repoOf(c).getById('A'))!;
        check(a.name).equals('Cut2');
        check(a.days).deepEquals([0, 2]);
        final b = (await repoOf(c).getById('B'))!;
        check(b.days).deepEquals([5]); // untouched
      },
    );

    test('conflict + override:false → no write, conflicts reported', () async {
      final c = await createContainer([
        plan('A', days: [0], name: 'Cut'),
        plan('B', days: [2], name: 'Rest Day'),
      ]);
      addTearDown(c.dispose);

      await c.read(planDetailControllerProvider('A').future);
      final ctrl = c.read(planDetailControllerProvider('A').notifier);
      ctrl.toggleDay(2); // collides with B

      final out = await ctrl.save();
      check(out.committed).isFalse();
      check(out.conflicts).length.equals(1);
      check(out.conflicts.first.weekday).equals(2);
      check(out.conflicts.first.otherPlanId).equals('B');
      check(out.conflicts.first.otherPlanName).equals('Rest Day');

      // Repo unchanged.
      check((await repoOf(c).getById('A'))!.days).deepEquals([0]);
      check((await repoOf(c).getById('B'))!.days).deepEquals([2]);
    });

    test('conflict + override:true → steals weekday from other plan', () async {
      final c = await createContainer([
        plan('A', days: [0], name: 'Cut'),
        plan('B', days: [2], name: 'Rest Day'),
      ]);
      addTearDown(c.dispose);

      await c.read(planDetailControllerProvider('A').future);
      final ctrl = c.read(planDetailControllerProvider('A').notifier);
      ctrl.toggleDay(2);

      final out = await ctrl.save(override: true);
      check(out.committed).isTrue();
      check((await repoOf(c).getById('A'))!.days).deepEquals([0, 2]);
      check((await repoOf(c).getById('B'))!.days).deepEquals([]); // stolen
    });

    test('inactive draft → no conflict; days kept dormant', () async {
      final c = await createContainer([
        plan('A', days: [2], name: 'Cut'),
        plan('B', days: [2], name: 'Rest Day'),
      ]);
      addTearDown(c.dispose);

      await c.read(planDetailControllerProvider('A').future);
      final ctrl = c.read(planDetailControllerProvider('A').notifier);
      ctrl.setActive(false); // claimedDays == []

      final out = await ctrl.save();
      check(out.committed).isTrue();
      check(out.conflicts).isEmpty();

      final a = (await repoOf(c).getById('A'))!;
      check(a.active).isFalse();
      check(a.days).deepEquals([2]); // dormant, not wiped
      check((await repoOf(c).getById('B'))!.days).deepEquals([2]); // untouched
    });

    test('reactivate into a taken weekday → conflict surfaces', () async {
      final c = await createContainer([
        plan('A', days: [2], active: false, name: 'Cut'),
        plan('B', days: [2], name: 'Rest Day'),
      ]);
      addTearDown(c.dispose);

      await c.read(planDetailControllerProvider('A').future);
      final ctrl = c.read(planDetailControllerProvider('A').notifier);
      ctrl.setActive(true); // now claims [2], collides with B

      final out = await ctrl.save();
      check(out.committed).isFalse();
      check(out.conflicts.map((x) => x.weekday).toList()).deepEquals([2]);
    });

    test('reports post-save uncovered weekdays', () async {
      final c = await createContainer([
        plan('A', days: [0, 1, 2, 3, 4], name: 'Weekday'),
      ]);
      addTearDown(c.dispose);

      await c.read(planDetailControllerProvider('A').future);
      final ctrl = c.read(planDetailControllerProvider('A').notifier);

      final out = await ctrl.save();
      check(out.committed).isTrue();
      check(out.uncovered).deepEquals([5, 6]);
    });
  });

  group('PlanDetailController.delete', () {
    test('refuses the last plan; deletes when more than one', () async {
      final c1 = await createContainer([
        plan('A', days: [0]),
      ]);
      addTearDown(c1.dispose);
      await c1.read(planDetailControllerProvider('A').future);
      final deletedLast = await c1
          .read(planDetailControllerProvider('A').notifier)
          .delete();
      check(deletedLast).isFalse();
      check(await repoOf(c1).getById('A')).isNotNull();

      final c2 = await createContainer([
        plan('A', days: [0]),
        plan('B', days: [2]),
      ]);
      addTearDown(c2.dispose);
      await c2.read(planDetailControllerProvider('A').future);
      final deleted = await c2
          .read(planDetailControllerProvider('A').notifier)
          .delete();
      check(deleted).isTrue();
      check(await repoOf(c2).getById('A')).isNull();
    });
  });

  group('PlanDetailController.isDirty', () {
    test('false after build; true after each mutation', () async {
      final c = await createContainer([
        plan('A', days: [0], name: 'Cut'),
      ]);
      addTearDown(c.dispose);

      await c.read(planDetailControllerProvider('A').future);
      final ctrl = c.read(planDetailControllerProvider('A').notifier);
      check(ctrl.isDirty).isFalse();

      ctrl.setName('Cut2');
      check(ctrl.isDirty).isTrue();
    });
  });
}
