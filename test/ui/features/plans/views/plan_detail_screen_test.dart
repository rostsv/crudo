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
import 'package:crudo/domain/shared/enums.dart';
import 'package:crudo/domain/shared/grams.dart';
import 'package:crudo/domain/shared/meal_time.dart';
import 'package:crudo/ui/core/themes/theme.dart';
import 'package:crudo/ui/core/widgets/primary_cta.dart';
import 'package:crudo/ui/features/plans/view_models/plan_detail_controller.dart';
import 'package:crudo/ui/features/plans/views/plan_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import '../../../../helpers/fake_id_generator.dart';

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
        profileRepositoryProvider.overrideWithValue(
          InMemoryProfileRepository(),
        ),
        idGeneratorProvider.overrideWithValue(FakeIdGenerator()),
      ],
    );
  }

  /// Open the detail screen via a GoRouter harness so context.pop() works.
  /// [planId] null = create mode (/plans/new), else edit mode (/plans/:id).
  Future<void> openWithRouter(
    WidgetTester tester, {
    required List<PlanTemplate> plans,
    String? planId = 'A',
  }) async {
    // Use a tall viewport so off-screen widgets can be tapped.
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final container = createContainer(plans: plans);
    addTearDown(container.dispose);
    container.listen(planDetailControllerProvider(planId), (prev, next) {});

    final path = planId == null ? '/plans/new' : '/plans/$planId';
    final router = GoRouter(
      initialLocation: '/',
      routes: <GoRoute>[
        GoRoute(
          path: '/',
          builder: (context, state) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => context.push(path),
                child: const Text('open'),
              ),
            ),
          ),
        ),
        GoRoute(
          path: '/plans/new',
          builder: (context, state) => PlanDetailScreen(
            planId: null,
            seed: state.extra as PlanTemplate?,
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
    testWidgets('renders name, 7 chips, slot rows', (tester) async {
      await openWithRouter(tester, plans: [planA, planB]);

      // Name lives in the TextField now (header shows the static title).
      expect(find.text('Workout Plan'), findsWidgets);
      expect(find.byKey(const ValueKey('day-chip-0')), findsOneWidget);
      expect(find.byKey(const ValueKey('day-chip-6')), findsOneWidget);
      expect(find.byKey(const ValueKey('s1')), findsOneWidget);
      expect(find.text('Breakfast'), findsOneWidget);
      expect(find.text('08:00'), findsOneWidget);

      // Active/pause moved to the Plans card — no switch in the editor.
      expect(find.byKey(const ValueKey('active-switch')), findsNothing);
    });

    testWidgets('selecting a day just toggles it — no conflict banner', (
      tester,
    ) async {
      await openWithRouter(tester, plans: [planA, planB]);

      // Tap Wed (index 2) — clashes with Rest Day, but nothing surfaces here.
      await tester.tap(find.byKey(const ValueKey('day-chip-2')));
      await tester.pumpAndSettle();

      final chip = tester.widget<PlanDayChip>(
        find.byKey(const ValueKey('day-chip-2')),
      );
      check(chip.selected).isTrue();

      // Collisions are validated on Save, not on day-select.
      expect(find.textContaining('Rest Day'), findsNothing);
      expect(find.text('Weekday conflict'), findsNothing);
    });

    testWidgets('Save with clash opens the conflict sheet; Cancel is a no-op', (
      tester,
    ) async {
      await openWithRouter(tester, plans: [planA, planB]);

      // Select Wed (clashes with B on save).
      await tester.tap(find.byKey(const ValueKey('day-chip-2')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('save-plan')));
      await tester.pumpAndSettle();

      // Conflict sheet with both resolution options.
      expect(find.text('Weekday conflict'), findsOneWidget);
      expect(find.textContaining('Rest Day loses Wed'), findsOneWidget);
      expect(find.text('Resolve conflict'), findsOneWidget);
      expect(find.text('Save as paused'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Weekday conflict'), findsNothing);

      // B still claims Wednesday (nothing committed).
      final container = tester.widget<UncontrolledProviderScope>(
        find.byType(UncontrolledProviderScope),
      );
      final repo = container.container.read(planTemplateRepositoryProvider);
      final all = await repo.getAll();
      final b = all.firstWhere((p) => p.id == 'B');
      check(b.days).deepEquals([2]);
    });

    testWidgets('Resolve conflict steals the day from the other plan', (
      tester,
    ) async {
      await openWithRouter(tester, plans: [planA, planB]);

      await tester.tap(find.byKey(const ValueKey('day-chip-2')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('save-plan')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Resolve conflict'));
      await tester.pumpAndSettle();

      final container = tester.widget<UncontrolledProviderScope>(
        find.byType(UncontrolledProviderScope),
      );
      final repo = container.container.read(planTemplateRepositoryProvider);
      final all = await repo.getAll();
      // A committed active with Wed; B lost Wed.
      final b = all.firstWhere((p) => p.id == 'B');
      check(b.days).deepEquals(const []);
    });

    testWidgets('Save as paused commits the plan inactive', (tester) async {
      await openWithRouter(tester, plans: [planA, planB]);

      await tester.tap(find.byKey(const ValueKey('day-chip-2')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('save-plan')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save as paused'));
      await tester.pumpAndSettle();

      final container = tester.widget<UncontrolledProviderScope>(
        find.byType(UncontrolledProviderScope),
      );
      final repo = container.container.read(planTemplateRepositoryProvider);
      final all = await repo.getAll();
      final a = all.firstWhere((p) => p.id == 'A');
      check(a.active).isFalse();
      // B keeps Wed — the paused plan claims nothing.
      final b = all.firstWhere((p) => p.id == 'B');
      check(b.days).deepEquals([2]);
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

  group('PlanDetailScreen — create mode', () {
    testWidgets('create mode: New plan title, blank name, no active/actions', (
      tester,
    ) async {
      await openWithRouter(tester, plans: [], planId: null);

      // Title shows "New plan"
      expect(find.text('New plan'), findsOneWidget);

      // Name field is blank
      final nameField = tester.widget<TextField>(
        find.byKey(const ValueKey('plan-name-field')),
      );
      check(nameField.controller?.text).equals('');

      // Save button is always present (validation happens on tap).
      final saveBtn = tester.widget<PrimaryCta>(
        find.byKey(const ValueKey('save-plan')),
      );
      check(saveBtn.onPressed).isNotNull();

      // No active switch, no delete/duplicate.
      expect(find.byKey(const ValueKey('active-switch')), findsNothing);
      expect(find.text('Delete plan'), findsNothing);
      expect(find.text('Duplicate'), findsNothing);

      // No meals text
      expect(find.text('No meals scheduled'), findsOneWidget);

      // No errors before a save attempt.
      expect(find.text('Add a plan name'), findsNothing);
      expect(find.text('Add at least one meal'), findsNothing);
    });

    testWidgets('Save with empty name + no meals surfaces inline errors', (
      tester,
    ) async {
      await openWithRouter(tester, plans: [], planId: null);

      await tester.tap(find.byKey(const ValueKey('save-plan')));
      await tester.pumpAndSettle();

      expect(find.text('Add a plan name'), findsOneWidget);
      expect(find.text('Add at least one meal'), findsOneWidget);
    });

    testWidgets('name error clears once a name is entered', (tester) async {
      await openWithRouter(tester, plans: [], planId: null);

      await tester.tap(find.byKey(const ValueKey('save-plan')));
      await tester.pumpAndSettle();
      expect(find.text('Add a plan name'), findsOneWidget);

      await tester.enterText(
        find.byKey(const ValueKey('plan-name-field')),
        'My Plan',
      );
      await tester.pumpAndSettle();
      expect(find.text('Add a plan name'), findsNothing);
      // Meals error still stands (no slots yet).
      expect(find.text('Add at least one meal'), findsOneWidget);
    });

    testWidgets('add slot via controller adds a slot row with default time', (
      tester,
    ) async {
      await openWithRouter(tester, plans: [], planId: null);

      // Access the controller directly to add a slot
      final container = tester.widget<UncontrolledProviderScope>(
        find.byType(UncontrolledProviderScope),
      );
      final ctrl = container.container.read(
        planDetailControllerProvider(null).notifier,
      );
      ctrl.addSlot('mt1');
      await tester.pump();

      // Slot row appears (keyed by minted slot id)
      // Since slot id is generated via FakeIdGenerator, check for the template name
      expect(find.text('Breakfast'), findsOneWidget);
      expect(find.text('08:00'), findsOneWidget);

      // Remove via controller
      ctrl.removeSlot(0);
      await tester.pump();
      expect(find.text('No meals scheduled'), findsOneWidget);
    });

    testWidgets('ADD MEAL button is present', (tester) async {
      await openWithRouter(tester, plans: [], planId: null);
      expect(find.byKey(const ValueKey('add-meal')), findsOneWidget);
    });

    testWidgets('name + a slot + full week saves and pops', (tester) async {
      await openWithRouter(tester, plans: [], planId: null);

      await tester.enterText(
        find.byKey(const ValueKey('plan-name-field')),
        'My Plan',
      );
      await tester.pumpAndSettle();

      final container = tester.widget<UncontrolledProviderScope>(
        find.byType(UncontrolledProviderScope),
      );
      final ctrl = container.container.read(
        planDetailControllerProvider(null).notifier,
      );
      ctrl.addSlot('mt1');
      // Cover the whole week so the "uncovered days" advisory doesn't fire.
      for (var i = 0; i < 7; i++) {
        await tester.tap(find.byKey(ValueKey('day-chip-$i')));
      }
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('save-plan')));
      await tester.pumpAndSettle();

      // Committed with no conflict → popped back to the launcher.
      expect(find.text('open'), findsOneWidget);
      final all = await container.container
          .read(planTemplateRepositoryProvider)
          .getAll();
      final int count = all.where((p) => p.name == 'My Plan').length;
      check(count).equals(1);
    });

    testWidgets('DAILY TARGET card shows summed kcal', (tester) async {
      await openWithRouter(tester, plans: [], planId: null);

      // Add a slot so there's macro data
      final container = tester.widget<UncontrolledProviderScope>(
        find.byType(UncontrolledProviderScope),
      );
      final ctrl = container.container.read(
        planDetailControllerProvider(null).notifier,
      );
      ctrl.addSlot('mt1');
      await tester.pump();

      // The tonal DAILY TARGET card shows the summed kcal.
      // mt1 = Chicken 100g = 165 kcal
      expect(find.text('DAILY TARGET'), findsOneWidget);
      expect(find.text('165'), findsOneWidget);
    });
  });
}
