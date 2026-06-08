// test/ui/features/plans/view_models/plans_list_test.dart
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
import 'package:crudo/domain/shared/enums.dart';
import 'package:crudo/domain/shared/grams.dart';
import 'package:crudo/domain/shared/meal_time.dart';
import 'package:crudo/ui/features/plans/view_models/plans_list.dart';
import 'package:crudo/ui/features/today/view_models/today_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Expected kcal for planA: macros of mt1 + mt2 at 100g each.
double expectedKcalA() {
  // f1: Chicken  30p 0c 5f → 165 kcal
  // f2: Rice     2.5p 30c 0.5f → 135 kcal
  return 165 + 135; // 300
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Food food1;
  late Food food2;
  late MealTemplate mt1;
  late MealTemplate mt2;
  late PlanTemplate planA;
  late PlanTemplate planB;
  // Wednesday = DateTime.weekday 3 → weekday index 2.
  // Plan A claims weekday 2 (Wed), Plan B does not.
  late DateTime wednesday;
  // Tuesday = DateTime.weekday 2 → weekday index 1.
  // Neither A ([0,2,4]) nor B ([5,6]) claims index 1.
  late DateTime tuesday;

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
    food2 = Food(
      id: 'f2',
      name: 'Rice',
      category: FoodCategory.grain,
      protein: 2.5,
      carbs: 30,
      fats: 0.5,
      kcalPer100g: 135,
    );
    mt1 = MealTemplate(
      id: 'mt1',
      name: 'Breakfast',
      foods: [FoodRef(foodId: 'f1', grams: const Grams(100))],
    );
    mt2 = MealTemplate(
      id: 'mt2',
      name: 'Lunch',
      foods: [FoodRef(foodId: 'f2', grams: const Grams(100))],
    );
    planA = PlanTemplate(
      id: 'A',
      name: 'Active Plan',
      days: [0, 2, 4],
      active: true,
      slots: [
        PlanSlot(id: 's1', mealTemplateId: 'mt1', time: const MealTime(480)),
        PlanSlot(id: 's2', mealTemplateId: 'mt2', time: const MealTime(720)),
      ],
    );
    planB = PlanTemplate(
      id: 'B',
      name: 'Weekend Plan',
      days: [5, 6],
      active: true,
      slots: [],
    );
    wednesday = DateTime.utc(2026, 6, 10); // Wednesday
    tuesday = DateTime.utc(2026, 6, 9); // Tuesday
  });

  /// Build a ProviderContainer with in-memory repo overrides seeded with the
  /// given plans and profile goal. The repo is wrapped inside a MaterialApp so
  /// stream-emissions propagate to the derived plansList provider.
  Future<ProviderContainer> createContainer({
    required DateTime today,
    required List<PlanTemplate> plans,
    Goal goal = Goal.cut,
  }) async {
    final profileRepo = InMemoryProfileRepository();
    await profileRepo.save(
      UserProfile(
        id: 'test',
        prefs: Prefs(goal: goal),
      ),
    );

    return ProviderContainer(
      overrides: [
        foodRepositoryProvider.overrideWithValue(
          InMemoryFoodRepository(seed: [food1, food2]),
        ),
        mealTemplateRepositoryProvider.overrideWithValue(
          InMemoryMealTemplateRepository(seed: [mt1, mt2]),
        ),
        planTemplateRepositoryProvider.overrideWithValue(
          InMemoryPlanTemplateRepository(seed: plans),
        ),
        profileRepositoryProvider.overrideWithValue(profileRepo),
        todayProvider.overrideWithValue(today),
      ],
    );
  }

  /// Pump the container into a MaterialApp with a Consumer that watches
  /// plansListProvider to keep it alive and let stream emissions propagate.
  /// Returns after TWO pumps — the first pump processes the initial stream
  /// emission (which triggers a partial re-evaluation), the second pump
  /// processes any remaining stream emissions from other providers so that
  /// all upstream data (plans, meal templates, foods, profile) is available.
  Future<void> pumpContainer(WidgetTester tester, ProviderContainer container) {
    return tester.pumpWidget(
      MaterialApp(
        home: UncontrolledProviderScope(
          container: container,
          child: Consumer(
            builder: (context, ref, child) {
              ref.watch(plansListProvider);
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
  }

  group('plansListProvider', () {
    testWidgets('row count == 2', (tester) async {
      final container = await createContainer(
        today: wednesday,
        plans: [planA, planB],
      );
      addTearDown(container.dispose);

      await pumpContainer(tester, container);
      // pumpAndSettle lets all stream emissions propagate through the
      // provider graph before we read the final derived value.
      await tester.pumpAndSettle();

      final rows = container.read(plansListProvider);
      check(rows).length.equals(2);
    });

    testWidgets('row A properties (kcal, mealCount, goal, days, isToday)', (
      tester,
    ) async {
      final container = await createContainer(
        today: wednesday,
        plans: [planA, planB],
      );
      addTearDown(container.dispose);

      await pumpContainer(tester, container);
      await tester.pumpAndSettle();

      final rows = container.read(plansListProvider);
      check(rows).length.equals(2);

      final a = rows.firstWhere((r) => r.id == 'A');
      check(a.kcal).equals(expectedKcalA().round());
      check(a.mealCount).equals(2);
      check(a.goal).equals(Goal.cut);
      check(a.days).deepEquals([0, 2, 4]);
      check(a.isToday).isTrue();
    });

    testWidgets('today not covered by any plan → all isToday false', (
      tester,
    ) async {
      final container = await createContainer(
        today: tuesday,
        plans: [planA, planB],
      );
      addTearDown(container.dispose);

      await pumpContainer(tester, container);
      await tester.pumpAndSettle();

      final rows = container.read(plansListProvider);
      check(rows.every((r) => !r.isToday)).isTrue();
    });

    testWidgets('inactive plan still present with active: false', (
      tester,
    ) async {
      final inactivePlan = planA.copyWith(active: false);
      final container = await createContainer(
        today: wednesday,
        plans: [inactivePlan],
      );
      addTearDown(container.dispose);

      await pumpContainer(tester, container);
      await tester.pumpAndSettle();

      final rows = container.read(plansListProvider);
      check(rows).length.equals(1);
      check(rows.first.active).isFalse();
    });
  });
}
