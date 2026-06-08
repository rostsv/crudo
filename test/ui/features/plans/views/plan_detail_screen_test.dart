import 'package:checks/checks.dart';
import 'package:crudo/config/di.dart';
import 'package:crudo/data/repositories/in_memory_food_repository.dart';
import 'package:crudo/data/repositories/in_memory_meal_template_repository.dart';
import 'package:crudo/data/repositories/in_memory_plan_template_repository.dart';
import 'package:crudo/domain/food/food.dart';
import 'package:crudo/domain/food/food_ref.dart';
import 'package:crudo/domain/meal/meal_template.dart';
import 'package:crudo/domain/plan/plan_slot.dart';
import 'package:crudo/domain/plan/plan_template.dart';
import 'package:crudo/domain/shared/enums.dart';
import 'package:crudo/domain/shared/grams.dart';
import 'package:crudo/domain/shared/meal_time.dart';
import 'package:crudo/ui/core/themes/theme.dart';
import 'package:crudo/ui/features/plans/view_models/plan_detail_controller.dart';
import 'package:crudo/ui/features/plans/views/plan_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Food food1;
  late MealTemplate mt1;
  late PlanTemplate planA;
  late PlanTemplate planB;

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
    planA = PlanTemplate(
      id: 'A',
      name: 'Workout Plan',
      days: const [0], // Monday
      active: true,
      slots: [
        PlanSlot(id: 's1', mealTemplateId: 'mt1', time: const MealTime(480)),
      ],
    );
    planB = PlanTemplate(
      id: 'B',
      name: 'Rest Day',
      days: const [2], // Wednesday
      active: true,
      slots: const [],
    );
  });

  /// Build a ProviderContainer with in-memory repos seeded with the given
  /// plans (and the single meal template + food).
  ProviderContainer createContainer({required List<PlanTemplate> plans}) {
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
      ],
    );
  }

  /// Open the detail screen via a GoRouter harness so context.pop() works.
  Future<void> openWithRouter(
    WidgetTester tester, {
    required List<PlanTemplate> plans,
    String planId = 'A',
  }) async {
    final container = createContainer(plans: plans);
    addTearDown(container.dispose);
    container.listen(planDetailControllerProvider(planId), (prev, next) {});

    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => context.push('/plans/$planId'),
                child: const Text('open'),
              ),
            ),
          ),
        ),
        GoRoute(
          path: '/plans/:id',
          builder: (context, state) =>
              PlanDetailScreen(planId: state.pathParameters['id']!),
        ),
      ],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(theme: crudoTheme, routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  group('PlanDetailScreen', () {
    testWidgets('renders name, 7 chips, active switch, slot rows', (
      tester,
    ) async {
      await openWithRouter(tester, plans: [planA, planB]);

      // Name appears in both the header Text and the TextField;
      // assert at least one visible widget.
      expect(find.text('Workout Plan'), findsWidgets);
      expect(find.byKey(const ValueKey('day-chip-0')), findsOneWidget);
      expect(find.byKey(const ValueKey('day-chip-6')), findsOneWidget);
      expect(find.byKey(const ValueKey('active-switch')), findsOneWidget);
      expect(find.byKey(const ValueKey('slot-row-0')), findsOneWidget);
      expect(find.text('Breakfast'), findsOneWidget);
      expect(find.text('08:00'), findsOneWidget);

      // Active switch should be on
      final switchWidget = tester.widget<Switch>(
        find.byKey(const ValueKey('active-switch')),
      );
      check(switchWidget.value).isTrue();
    });

    testWidgets(
      'tapping Wed chip selects it and shows conflict + banner with Rest Day',
      (tester) async {
        await openWithRouter(tester, plans: [planA, planB]);

        // Tap Wed (index 2)
        await tester.tap(find.byKey(const ValueKey('day-chip-2')));
        await tester.pumpAndSettle();

        // Chip should be selected
        final chip = tester.widget<PlanDayChip>(
          find.byKey(const ValueKey('day-chip-2')),
        );
        check(chip.selected).isTrue();

        // Banner should show conflict with Rest Day
        expect(find.textContaining('Rest Day'), findsOneWidget);
      },
    );

    testWidgets(
      'Save with conflict opens Override sheet; Cancel leaves B unchanged',
      (tester) async {
        await openWithRouter(tester, plans: [planA, planB]);

        // Select Wed (conflicts with B)
        await tester.tap(find.byKey(const ValueKey('day-chip-2')));
        await tester.pumpAndSettle();

        // Tap Save
        await tester.tap(find.byKey(const ValueKey('save-plan')));
        await tester.pumpAndSettle();

        // Override sheet should appear
        expect(find.text('Override existing plans?'), findsOneWidget);
        expect(find.textContaining('Rest Day loses Wed'), findsOneWidget);

        // Tap Cancel
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();

        // Sheet dismissed, back on detail screen
        expect(find.text('Override existing plans?'), findsNothing);

        // Verify B still claims Wednesday
        final container = tester.widget<UncontrolledProviderScope>(
          find.byType(UncontrolledProviderScope),
        );
        final repo = container.container.read(planTemplateRepositoryProvider);
        final all = await repo.getAll();
        final b = all.firstWhere((p) => p.id == 'B');
        check(b.days).deepEquals([2]);
      },
    );

    testWidgets(
      'turning active switch off clears conflict outline while Wed stays selected',
      (tester) async {
        await openWithRouter(tester, plans: [planA, planB]);

        // Select Wed
        await tester.tap(find.byKey(const ValueKey('day-chip-2')));
        await tester.pumpAndSettle();

        // Conflict banner should be visible
        expect(find.textContaining('Rest Day'), findsOneWidget);

        // Turn active switch off
        await tester.tap(find.byKey(const ValueKey('active-switch')));
        await tester.pumpAndSettle();

        // Banner should be gone (no active conflicts)
        expect(find.textContaining('Rest Day'), findsNothing);

        // Wed chip should still be selected
        final chip = tester.widget<PlanDayChip>(
          find.byKey(const ValueKey('day-chip-2')),
        );
        check(chip.selected).isTrue();
      },
    );

    testWidgets('delete with only one plan shows toast guard', (tester) async {
      await openWithRouter(tester, plans: [planA]);
      await tester.tap(find.text('Delete plan'));
      await tester.pumpAndSettle();

      expect(find.text("Can't delete your only plan"), findsOneWidget);
      // Dismiss toast timer to avoid pending-timer failure
      await tester.pump(const Duration(seconds: 5));
    });

    testWidgets('delete with two plans shows confirm sheet', (tester) async {
      await openWithRouter(tester, plans: [planA, planB]);
      await tester.tap(find.text('Delete plan'));
      await tester.pumpAndSettle();

      expect(find.text('Delete plan?'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);

      // Cancel the delete
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Delete plan?'), findsNothing);
    });

    testWidgets(
      'back after edits shows discard confirm; clean draft pops without confirm',
      (tester) async {
        await openWithRouter(tester, plans: [planA, planB]);

        // Make an edit: change name
        await tester.enterText(
          find.byKey(const ValueKey('plan-name-field')),
          'New Name',
        );
        await tester.pumpAndSettle();

        // Trigger back via the back button
        await tester.tap(find.byIcon(Icons.arrow_back));
        await tester.pumpAndSettle();

        // Discard sheet should appear
        expect(find.text('Discard changes?'), findsOneWidget);

        // Keep editing
        await tester.tap(find.byKey(const ValueKey('keep-editing')));
        await tester.pumpAndSettle();
        expect(find.text('Discard changes?'), findsNothing);

        // Now restore the name and go back — should pop without confirm
        await tester.enterText(
          find.byKey(const ValueKey('plan-name-field')),
          'Workout Plan',
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.arrow_back));
        await tester.pumpAndSettle();

        // Should be back on the launcher (no discard confirm)
        expect(find.text('Discard changes?'), findsNothing);
        expect(find.text('open'), findsOneWidget);
      },
    );
  });
}
