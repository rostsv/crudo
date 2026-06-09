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
import 'package:crudo/ui/features/meals/views/meal_template_library_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../../helpers/fake_id_generator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Food food1;
  late Food food2;
  late MealTemplate template1;
  late MealTemplate template2;
  late PlanTemplate plan1;

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
    // Referenced by plan1
    template1 = MealTemplate(
      id: 'mt1',
      name: 'Breakfast Bowl',
      tags: [MealTag.breakfast],
      foods: [FoodRef(foodId: 'f1', grams: const Grams(100))],
    );
    // Not referenced by any plan
    template2 = MealTemplate(
      id: 'mt2',
      name: 'Lunch Salad',
      tags: [MealTag.lunch, MealTag.snack],
      foods: [FoodRef(foodId: 'f2', grams: const Grams(200))],
    );
    plan1 = PlanTemplate(
      id: 'p1',
      name: 'My Plan',
      slots: [
        PlanSlot(id: 's1', mealTemplateId: 'mt1', time: const MealTime(480)),
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
          InMemoryMealTemplateRepository(
            seed: templates ?? [template1, template2],
          ),
        ),
        planTemplateRepositoryProvider.overrideWithValue(
          InMemoryPlanTemplateRepository(seed: plans ?? [plan1]),
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
                onPressed: () => context.push('/meal-templates'),
                child: const Text('open-library'),
              ),
            ),
          ),
        ),
        GoRoute(
          path: '/meal-templates',
          builder: (context, state) => const MealTemplateLibraryScreen(),
        ),
        GoRoute(
          path: '/meal-templates/new',
          builder: (context, state) =>
              const Scaffold(body: Center(child: Text('new-template'))),
        ),
        GoRoute(
          path: '/meal-templates/:id',
          builder: (context, state) => Scaffold(
            body: Center(child: Text('edit-${state.pathParameters["id"]}')),
          ),
        ),
      ],
    );
    return UncontrolledProviderScope(
      container: c,
      child: MaterialApp.router(theme: crudoTheme, routerConfig: router),
    );
  }

  Future<ProviderContainer> pumpLibrary(WidgetTester t) async {
    final c = createContainer();
    addTearDown(c.dispose);
    t.view.physicalSize = const Size(800, 1800);
    t.view.devicePixelRatio = 1.0;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    await t.pumpWidget(app(c));
    await t.pumpAndSettle();
    await t.tap(find.text('open-library'));
    await t.pumpAndSettle();
    return c;
  }

  group('MealTemplateLibraryScreen', () {
    testWidgets('shows one card per template', (t) async {
      await pumpLibrary(t);

      expect(find.byKey(const ValueKey('template-row-mt1')), findsOneWidget);
      expect(find.byKey(const ValueKey('template-row-mt2')), findsOneWidget);
    });

    testWidgets('subtitle shows kcal and tags', (t) async {
      await pumpLibrary(t);

      // template1: 165 kcal · Breakfast
      expect(find.textContaining('165 kcal'), findsOneWidget);
      expect(find.text('165 kcal · Breakfast'), findsOneWidget);

      // template2: 270 kcal · Lunch · Snack
      expect(find.textContaining('270 kcal'), findsOneWidget);
      expect(find.text('270 kcal · Lunch · Snack'), findsOneWidget);
    });

    testWidgets('shows Used in N plans / Unused', (t) async {
      await pumpLibrary(t);

      // template1 is referenced by plan1
      expect(find.textContaining('Used in 1 plan'), findsOneWidget);

      // template2 is not referenced
      expect(find.textContaining('Unused'), findsOneWidget);
    });

    testWidgets('tapping a card pushes /meal-templates/:id', (t) async {
      await pumpLibrary(t);

      await t.tap(find.byKey(const ValueKey('template-row-mt1')));
      await t.pumpAndSettle();

      expect(find.text('edit-mt1'), findsOneWidget);
    });

    testWidgets('New action pushes /meal-templates/new', (t) async {
      await pumpLibrary(t);

      await t.tap(find.byKey(const ValueKey('add-template')));
      await t.pumpAndSettle();

      expect(find.text('new-template'), findsOneWidget);
    });

    testWidgets('empty rows shows No meals yet', (t) async {
      final c = createContainer(
        foods: [food1, food2],
        templates: [],
        plans: [],
      );
      addTearDown(c.dispose);
      t.view.physicalSize = const Size(800, 1800);
      t.view.devicePixelRatio = 1.0;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      await t.pumpWidget(app(c));
      await t.pumpAndSettle();
      await t.tap(find.text('open-library'));
      await t.pumpAndSettle();

      expect(find.byKey(const ValueKey('templates-empty')), findsOneWidget);
      expect(find.text('No meals yet'), findsOneWidget);
    });
  });
}
