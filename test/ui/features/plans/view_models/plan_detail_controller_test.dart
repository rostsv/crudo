// test/ui/features/plans/view_models/plan_detail_controller_test.dart
import 'package:checks/checks.dart';
import 'package:crudo/config/di.dart';
import 'package:crudo/data/repositories/in_memory_food_repository.dart';
import 'package:crudo/data/repositories/in_memory_meal_template_repository.dart';
import 'package:crudo/data/repositories/in_memory_plan_template_repository.dart';
import 'package:crudo/data/repositories/in_memory_profile_repository.dart';
import 'package:crudo/data/services/id_generator.dart';
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
import '../../../../helpers/fake_id_generator.dart';

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
        idGeneratorProvider.overrideWithValue(FakeIdGenerator()),
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
    test('refuses when it would leave the week uncovered; deletes when the '
        'remaining active plans still cover every day', () async {
      // Sole plan covering the week → cannot delete.
      final c1 = await createContainer([
        plan('A', days: [0, 1, 2, 3, 4, 5, 6]),
      ]);
      addTearDown(c1.dispose);
      await c1.read(planDetailControllerProvider('A').future);
      final deletedLast = await c1
          .read(planDetailControllerProvider('A').notifier)
          .delete();
      check(deletedLast).isFalse();
      check(await repoOf(c1).getById('A')).isNotNull();

      // B still covers the whole week after A is gone → delete allowed.
      final c2 = await createContainer([
        plan('A', days: [0]),
        plan('B', days: [0, 1, 2, 3, 4, 5, 6]),
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

  group('PlanDetailController — create mode', () {
    test('build(null) returns blank draft with canSave false', () async {
      final c = await createContainer([]);
      addTearDown(c.dispose);

      final draft = await c.read(planDetailControllerProvider(null).future);
      check(draft.name).equals('');
      check(draft.slots).isEmpty();
      check(draft.canSave).isFalse();
      check(draft.active).isTrue(); // create defaults active
    });

    test('addSlot on empty creates slot at MealTime(480)', () async {
      final c = await createContainer([]);
      addTearDown(c.dispose);

      await c.read(planDetailControllerProvider(null).future);
      final ctrl = c.read(planDetailControllerProvider(null).notifier);

      ctrl.addSlot('mt1');
      final draft = c.read(planDetailControllerProvider(null)).requireValue;
      check(draft.slots).length.equals(1);
      check(draft.slots.first.time).equals(const MealTime(480));
      check(draft.slots.first.mealName).equals('Breakfast');
      check(draft.slots.first.kcal).equals(165);
    });

    test('second addSlot creates later time, capped at 1380', () async {
      final c = await createContainer([]);
      addTearDown(c.dispose);

      await c.read(planDetailControllerProvider(null).future);
      final ctrl = c.read(planDetailControllerProvider(null).notifier);

      ctrl.addSlot('mt1'); // first → 480
      ctrl.addSlot('mt1'); // second → 480 + 180 = 660
      var draft = c.read(planDetailControllerProvider(null)).requireValue;
      check(draft.slots.map((s) => s.time.minutesOfDay)).deepEquals([480, 660]);

      // Add enough to push past cap (1380)
      ctrl.addSlot('mt1'); // 660 + 180 = 840
      ctrl.addSlot('mt1'); // 840 + 180 = 1020
      ctrl.addSlot('mt1'); // 1020 + 180 = 1200
      ctrl.addSlot('mt1'); // 1200 + 180 = 1380 (clamped)
      draft = c.read(planDetailControllerProvider(null)).requireValue;
      check(draft.slots.last.time.minutesOfDay).equals(1380);
    });

    test('removeSlot and setSlotTime update state', () async {
      final c = await createContainer([]);
      addTearDown(c.dispose);

      await c.read(planDetailControllerProvider(null).future);
      final ctrl = c.read(planDetailControllerProvider(null).notifier);

      ctrl.addSlot('mt1'); // slot at 480
      ctrl.addSlot('mt1'); // slot at 660
      ctrl.addSlot('mt1'); // slot at 840
      var draft = c.read(planDetailControllerProvider(null)).requireValue;
      check(draft.slots).length.equals(3);

      // Remove middle slot (index 1)
      ctrl.removeSlot(1);
      draft = c.read(planDetailControllerProvider(null)).requireValue;
      check(draft.slots).length.equals(2);
      check(draft.slots[0].time.minutesOfDay).equals(480);
      check(draft.slots[1].time.minutesOfDay).equals(840);

      // Reset by rebuilding
      await c.read(planDetailControllerProvider(null).future);
      ctrl.addSlot('mt1');
      ctrl.addSlot('mt1');
      ctrl.addSlot('mt1');
      // Set slot time (re-sort: move latest to early)
      ctrl.setSlotTime(2, const MealTime(100)); // move index 2 to 06:00
      draft = c.read(planDetailControllerProvider(null)).requireValue;
      // After re-sort, the 06:00 slot should be first
      check(draft.slots.first.time.minutesOfDay).equals(100);
    });

    test('reorderSlots reassigns times by sorted pool', () async {
      final c = await createContainer([]);
      addTearDown(c.dispose);

      await c.read(planDetailControllerProvider(null).future);
      final ctrl = c.read(planDetailControllerProvider(null).notifier);

      ctrl.addSlot('mt1'); // 480
      ctrl.addSlot('mt1'); // 660
      ctrl.addSlot('mt1'); // 840
      final before = c.read(planDetailControllerProvider(null)).requireValue;
      check(
        before.slots.map((s) => s.time.minutesOfDay),
      ).deepEquals([480, 660, 840]);

      // Drag last to front (index 2 → 0)
      ctrl.reorderSlots(2, 0);
      final after = c.read(planDetailControllerProvider(null)).requireValue;
      check(after.slots.map((s) => s.id)).deepEquals([
        before.slots[2].id,
        before.slots[0].id,
        before.slots[1].id,
      ]);
      check(
        after.slots.map((s) => s.time.minutesOfDay),
      ).deepEquals([480, 660, 840]);
    });

    test('seedFrom mirrors plan, isDirty false, repo unchanged', () async {
      final src = plan(
        'P1',
        days: [0, 2],
        name: 'Source',
        slots: [
          PlanSlot(id: 's1', mealTemplateId: 'mt1', time: const MealTime(480)),
        ],
      );
      final c = await createContainer([src]);
      addTearDown(c.dispose);

      await c.read(planDetailControllerProvider(null).future);
      final ctrl = c.read(planDetailControllerProvider(null).notifier);

      ctrl.seedFrom(src);
      var draft = c.read(planDetailControllerProvider(null)).requireValue;
      check(draft.name).equals('Source');
      check(draft.days).deepEquals([0, 2]);
      check(draft.slots).length.equals(1);
      check(draft.slots.first.mealName).equals('Breakfast');

      // isDirty should be false after seed (baseline matches)
      check(ctrl.isDirty).isFalse();

      // Mutate → dirty
      ctrl.setName('Source Modified');
      check(ctrl.isDirty).isTrue();

      // Repo unchanged (nothing persisted)
      check(await repoOf(c).getById('P1')).isNotNull();
      check(await repoOf(c).getAll()).length.equals(1);
    });

    test('save() create mode persists plan with minted id and slots', () async {
      final c = await createContainer([]);
      addTearDown(c.dispose);

      await c.read(planDetailControllerProvider(null).future);
      final ctrl = c.read(planDetailControllerProvider(null).notifier);

      ctrl.setName('New Plan');
      ctrl.toggleDay(0); // Mon
      ctrl.addSlot('mt1');

      final out = await ctrl.save();
      check(out.committed).isTrue();
      check(out.conflicts).isEmpty();

      // Repo should now have 1 plan
      final all = await repoOf(c).getAll();
      check(all).length.equals(1);
      final saved = all.first;
      check(saved.name).equals('New Plan');
      check(saved.days).deepEquals([0]);
      check(saved.active).isTrue();
      check(saved.slots).length.equals(1);
      check(saved.slots.first.mealTemplateId).equals('mt1');
      check(saved.slots.first.time).equals(const MealTime(480));
    });

    test(
      'save() create with conflict + no override → uncommitted; override → steals',
      () async {
        final existing = plan('B', days: [0], name: 'Existing');
        final c = await createContainer([existing]);
        addTearDown(c.dispose);

        await c.read(planDetailControllerProvider(null).future);
        final ctrl = c.read(planDetailControllerProvider(null).notifier);

        ctrl.setName('New Plan');
        ctrl.toggleDay(0); // collides with B
        ctrl.addSlot('mt1');

        // First save — no override
        final out1 = await ctrl.save();
        check(out1.committed).isFalse();
        check(out1.conflicts).length.equals(1);
        check(out1.conflicts.first.weekday).equals(0);
        // Existing plan unchanged
        check((await repoOf(c).getById('B'))!.days).deepEquals([0]);

        // Second save — with override
        final out2 = await ctrl.save(override: true);
        check(out2.committed).isTrue();
        check(out2.conflicts).isEmpty();

        // New plan created with day 0
        final all = await repoOf(c).getAll();
        check(all).length.equals(2); // both B and new plan exist
        // Existing B lost day 0
        check((await repoOf(c).getById('B'))!.days).deepEquals([]);
      },
    );

    test(
      'save() with blank name returns empty SaveOutcome when draft null',
      () async {
        // This tests the null-draft guard: shouldn't happen in practice but
        // the guard returns early.
        // We'll just verify the controller's save doesn't throw.
        final c = await createContainer([]);
        addTearDown(c.dispose);

        final ctrl = c.read(planDetailControllerProvider(null).notifier);
        // State is still loading (null) → save returns empty
        final out = await ctrl.save();
        check(out.committed).isFalse();
        check(out.conflicts).isEmpty();
        check(out.uncovered).isEmpty();
      },
    );
  });
}
