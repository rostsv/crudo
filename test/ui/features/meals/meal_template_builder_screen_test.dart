import 'package:checks/checks.dart';
import 'package:crudo/config/di.dart';
import 'package:crudo/data/repositories/in_memory_food_repository.dart';
import 'package:crudo/data/repositories/in_memory_meal_template_repository.dart';
import 'package:crudo/data/repositories/in_memory_plan_template_repository.dart';
import 'package:crudo/data/services/id_generator.dart';
import 'package:crudo/domain/food/food.dart';
import 'package:crudo/domain/food/food_ref.dart';
import 'package:crudo/domain/meal/meal_template.dart';
import 'package:crudo/domain/plan/plan_slot.dart';
import 'package:crudo/domain/plan/plan_template.dart';
import 'package:crudo/domain/shared/enums.dart';
import 'package:crudo/domain/shared/grams.dart';
import 'package:crudo/domain/shared/meal_time.dart';
import 'package:crudo/ui/core/themes/theme.dart';
import 'package:crudo/ui/core/widgets/pill.dart';
import 'package:crudo/ui/features/meals/views/meal_template_builder_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../../helpers/fake_id_generator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Food food1;
  late Food food2;
  late MealTemplate existingTemplate;
  late PlanTemplate planMulti;
  late PlanTemplate planSingle;

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
    existingTemplate = MealTemplate(
      id: 'mt1',
      name: 'Breakfast',
      tags: [MealTag.breakfast],
      foods: [FoodRef(foodId: 'f1', grams: const Grams(100))],
    );
    // Plan with multiple slots (mt1 is one of them)
    planMulti = PlanTemplate(
      id: 'p-multi',
      name: 'Muscle Plan',
      slots: [
        PlanSlot(id: 's1', mealTemplateId: 'mt1', time: const MealTime(480)),
        PlanSlot(id: 's2', mealTemplateId: 'mt2', time: const MealTime(720)),
      ],
    );
    // Plan with only mt1
    planSingle = PlanTemplate(
      id: 'p-single',
      name: 'Solo Plan',
      slots: [
        PlanSlot(id: 's3', mealTemplateId: 'mt1', time: const MealTime(480)),
      ],
    );
  });

  ProviderContainer createContainer({
    List<Food>? foods,
    List<MealTemplate>? templates,
    List<PlanTemplate>? plans,
  }) {
    return ProviderContainer(
      overrides: [
        foodRepositoryProvider.overrideWithValue(
          InMemoryFoodRepository(seed: foods ?? [food1, food2]),
        ),
        mealTemplateRepositoryProvider.overrideWithValue(
          InMemoryMealTemplateRepository(seed: templates ?? [existingTemplate]),
        ),
        planTemplateRepositoryProvider.overrideWithValue(
          InMemoryPlanTemplateRepository(
            seed: plans ?? [planMulti, planSingle],
          ),
        ),
        idGeneratorProvider.overrideWithValue(FakeIdGenerator()),
      ],
    );
  }

  Widget app(ProviderContainer c) {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => context.push('/meal-templates/new'),
                child: const Text('open-create'),
              ),
            ),
          ),
        ),
        GoRoute(
          path: '/meal-templates/new',
          builder: (context, state) =>
              const MealTemplateBuilderScreen(templateId: null),
          routes: [
            GoRoute(
              path: 'add-ingredient',
              builder: (context, state) => Scaffold(
                body: ElevatedButton(
                  key: const ValueKey('fake-add-ingredient'),
                  onPressed: () =>
                      context.pop((food: food1, grams: const Grams(100))),
                  child: const Text('add'),
                ),
              ),
            ),
          ],
        ),
        GoRoute(
          path: '/meal-templates/:id',
          builder: (context, state) => MealTemplateBuilderScreen(
            templateId: state.pathParameters['id']!,
          ),
          routes: [
            GoRoute(
              path: 'add-ingredient',
              builder: (context, state) => Scaffold(
                body: ElevatedButton(
                  key: const ValueKey('fake-add-ingredient'),
                  onPressed: () =>
                      context.pop((food: food1, grams: const Grams(100))),
                  child: const Text('add'),
                ),
              ),
            ),
          ],
        ),
      ],
    );
    return UncontrolledProviderScope(
      container: c,
      child: MaterialApp.router(theme: crudoTheme, routerConfig: router),
    );
  }

  Future<ProviderContainer> pumpCreate(WidgetTester t) async {
    final c = createContainer();
    addTearDown(c.dispose);
    t.view.physicalSize = const Size(800, 1800);
    t.view.devicePixelRatio = 1.0;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    await t.pumpWidget(app(c));
    await t.pumpAndSettle();
    await t.tap(find.text('open-create'));
    await t.pumpAndSettle();
    return c;
  }

  Future<ProviderContainer> pumpEdit(
    WidgetTester t, {
    List<Food>? foods,
    List<MealTemplate>? templates,
    List<PlanTemplate>? plans,
    String templateId = 'mt1',
  }) async {
    final c = createContainer(foods: foods, templates: templates, plans: plans);
    addTearDown(c.dispose);
    t.view.physicalSize = const Size(800, 1800);
    t.view.devicePixelRatio = 1.0;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);

    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => context.push('/meal-templates/$templateId'),
                child: const Text('open-edit'),
              ),
            ),
          ),
        ),
        GoRoute(
          path: '/meal-templates/:id',
          builder: (context, state) => MealTemplateBuilderScreen(
            templateId: state.pathParameters['id']!,
          ),
          routes: [
            GoRoute(
              path: 'add-ingredient',
              builder: (context, state) => Scaffold(
                body: ElevatedButton(
                  key: const ValueKey('fake-add-ingredient'),
                  onPressed: () =>
                      context.pop((food: food1, grams: const Grams(100))),
                  child: const Text('add'),
                ),
              ),
            ),
          ],
        ),
      ],
    );

    await t.pumpWidget(
      UncontrolledProviderScope(
        container: c,
        child: MaterialApp.router(theme: crudoTheme, routerConfig: router),
      ),
    );
    await t.pumpAndSettle();
    await t.tap(find.text('open-edit'));
    await t.pumpAndSettle();
    return c;
  }

  group('MealTemplateBuilderScreen — create', () {
    testWidgets(
      'empty form; SAVE disabled; name + ingredient → SAVE enabled; SAVE → repo + pop',
      (t) async {
        final c = await pumpCreate(t);

        // SAVE is dimmed (disabled)
        final btn = t.widget<TextButton>(
          find.byKey(const ValueKey('save-meal')),
        );
        expect(btn.onPressed, isNull);

        // Enter name
        await t.enterText(
          find.byKey(const ValueKey('template-name')),
          'My Bowl',
        );
        await t.pumpAndSettle();

        // Add ingredient via fake picker
        await t.tap(find.byKey(const ValueKey('add-ingredient')));
        await t.pumpAndSettle();
        await t.tap(find.byKey(const ValueKey('fake-add-ingredient')));
        await t.pumpAndSettle();

        // Now SAVE is enabled
        final btn2 = t.widget<TextButton>(
          find.byKey(const ValueKey('save-meal')),
        );
        expect(btn2.onPressed, isNotNull);

        // Tap SAVE
        await t.tap(find.byKey(const ValueKey('save-meal')));
        await t.pumpAndSettle();

        // Popped back
        expect(find.text('open-create'), findsOneWidget);

        // Repo has the new template
        final repo = c.read(mealTemplateRepositoryProvider);
        final all = await repo.getAll();
        final created = all.firstWhere((m) => m.name == 'My Bowl');
        check(created.name).equals('My Bowl');
        check(created.foods.length).equals(1);
        check(created.foods.first.foodId).equals('f1');
      },
    );

    testWidgets('tag toggle selects and deselects a Pill', (t) async {
      await pumpCreate(t);

      final pillFinder = find.byKey(const ValueKey('tag-breakfast'));
      expect(pillFinder, findsOneWidget);

      // Tap to select
      await t.tap(pillFinder);
      await t.pumpAndSettle();

      final pill = t.widget<Pill>(pillFinder);
      check(pill.selected).isTrue();

      // Tap again to deselect
      await t.tap(pillFinder);
      await t.pumpAndSettle();
      final pill2 = t.widget<Pill>(pillFinder);
      check(pill2.selected).isFalse();
    });

    testWidgets('remove ingredient drops row; macro preview updates', (
      t,
    ) async {
      await pumpCreate(t);

      // Add name + ingredient
      await t.enterText(find.byKey(const ValueKey('template-name')), 'My Bowl');
      await t.pumpAndSettle();
      await t.tap(find.byKey(const ValueKey('add-ingredient')));
      await t.pumpAndSettle();
      await t.tap(find.byKey(const ValueKey('fake-add-ingredient')));
      await t.pumpAndSettle();

      expect(find.byKey(const ValueKey('ingredient-0')), findsOneWidget);

      // Add second ingredient
      await t.tap(find.byKey(const ValueKey('add-ingredient')));
      await t.pumpAndSettle();
      await t.tap(find.byKey(const ValueKey('fake-add-ingredient')));
      await t.pumpAndSettle();

      expect(find.byKey(const ValueKey('ingredient-1')), findsOneWidget);

      // Get kcal with 2 ingredients
      final kcalWithTwo = t
          .widget<Text>(find.byKey(const ValueKey('template-preview-kcal')))
          .data;

      // Remove first
      await t.tap(find.byIcon(Icons.close).first);
      await t.pumpAndSettle();

      // ingredient-1 is gone
      expect(find.byKey(const ValueKey('ingredient-1')), findsNothing);

      // Kcal changed after removal
      final kcalAfterRemove = t
          .widget<Text>(find.byKey(const ValueKey('template-preview-kcal')))
          .data;
      expect(kcalAfterRemove, isNot(equals(kcalWithTwo)));
    });
  });

  group('MealTemplateBuilderScreen — edit', () {
    testWidgets('shows Used in N plans', (t) async {
      await pumpEdit(t, plans: [planMulti]);
      expect(find.textContaining('Used in 1 plan'), findsOneWidget);
    });

    testWidgets('delete unused → confirm sheet → deletes', (t) async {
      final c = await pumpEdit(t, plans: []);

      await t.tap(find.text('Delete meal'));
      await t.pumpAndSettle();

      // Confirm sheet
      expect(find.text('Delete meal?'), findsOneWidget);
      await t.tap(find.text('Delete'));
      await t.pumpAndSettle();

      // Popped back
      expect(find.text('open-edit'), findsOneWidget);

      // Template gone
      final repo = c.read(mealTemplateRepositoryProvider);
      check(await repo.getById('mt1')).isNull();
    });

    testWidgets(
      'delete referenced-non-empty → warn sheet names plan → confirm strips',
      (t) async {
        final c = await pumpEdit(t, plans: [planMulti]);

        await t.tap(find.text('Delete meal'));
        await t.pumpAndSettle();

        // Warn sheet references the plan
        expect(find.text('Delete meal?'), findsOneWidget);
        expect(find.textContaining('Muscle Plan'), findsOneWidget);
        await t.tap(find.text('Delete'));
        await t.pumpAndSettle();

        // Popped back
        expect(find.text('open-edit'), findsOneWidget);

        // Template gone
        final repo = c.read(mealTemplateRepositoryProvider);
        check(await repo.getById('mt1')).isNull();

        // Plan stripped
        final planRepo = c.read(planTemplateRepositoryProvider);
        final plan = await planRepo.getById('p-multi');
        check(plan).isNotNull();
        check(plan!.slots.length).equals(1);
        check(plan.slots.first.mealTemplateId).equals('mt2');
      },
    );

    testWidgets('delete sole-meal → warn toast, no delete', (t) async {
      final c = await pumpEdit(t, plans: [planSingle]);

      await t.tap(find.text('Delete meal'));
      await t.pumpAndSettle();

      // Toast shown
      expect(find.textContaining('only meal'), findsOneWidget);

      // Template still present
      final repo = c.read(mealTemplateRepositoryProvider);
      check(await repo.getById('mt1')).isNotNull();

      // Dismiss toast
      await t.pump(const Duration(seconds: 5));
    });
  });

  group('MealTemplateBuilderScreen — back guard', () {
    testWidgets('dirty back shows discard sheet; pristine back pops', (
      t,
    ) async {
      await pumpCreate(t);

      // Pristine back
      await t.tap(find.byIcon(Icons.arrow_back));
      await t.pumpAndSettle();
      expect(find.text('Discard changes?'), findsNothing);
      expect(find.text('open-create'), findsOneWidget);

      // Reopen
      await t.tap(find.text('open-create'));
      await t.pumpAndSettle();

      // Make dirty
      await t.enterText(find.byKey(const ValueKey('template-name')), 'Dirty');
      await t.pumpAndSettle();

      // Back
      await t.tap(find.byIcon(Icons.arrow_back));
      await t.pumpAndSettle();
      expect(find.text('Discard changes?'), findsOneWidget);

      // Keep editing
      await t.tap(find.byKey(const ValueKey('keep-editing')));
      await t.pumpAndSettle();
      expect(find.text('Discard changes?'), findsNothing);

      // Discard
      await t.tap(find.byIcon(Icons.arrow_back));
      await t.pumpAndSettle();
      await t.tap(find.text('Discard'));
      await t.pumpAndSettle();
      expect(find.text('open-create'), findsOneWidget);
    });
  });
}
