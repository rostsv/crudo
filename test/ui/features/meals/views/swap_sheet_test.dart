import 'package:checks/checks.dart';
import 'package:crudo/config/app_config.dart';
import 'package:crudo/config/di.dart';
import 'package:crudo/data/repositories/in_memory_meal_template_repository.dart';
import 'package:crudo/data/services/id_generator.dart';
import 'package:crudo/data/services/seed_service.dart';
import 'package:crudo/domain/food/food.dart';
import 'package:crudo/domain/food/food_ref.dart';
import 'package:crudo/domain/meal/meal_template.dart';
import 'package:crudo/domain/shared/grams.dart';
import 'package:crudo/ui/core/themes/theme.dart';
import 'package:crudo/ui/features/meals/views/swap_sheet.dart';
import 'package:crudo/ui/features/today/view_models/day_controller.dart';
import 'package:crudo/ui/features/today/view_models/today_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/fake_id_generator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<Food> seedFoods;
  setUpAll(() async => seedFoods = await SeedService().loadFoods());

  var now = DateTime(2026, 6, 4, 7, 0);
  final today = DateTime.utc(2026, 6, 4);
  final tomorrow = DateTime.utc(2026, 6, 5);

  ProviderContainer container() {
    return ProviderContainer(
      overrides: [
        appConfigProvider.overrideWithValue(AppConfig(flavor: Flavor.dev)),
        seedFoodsProvider.overrideWithValue(seedFoods),
        clockProvider.overrideWithValue(() => now),
        idGeneratorProvider.overrideWithValue(FakeIdGenerator()),
      ],
    );
  }

  group('SwapSheet', () {
    setUp(() => now = DateTime(2026, 6, 4, 7, 0));

    testWidgets('renders one row per demo template with name + summary', (
      t,
    ) async {
      final c = container();
      t.view.physicalSize = const Size(800, 1600);
      t.view.devicePixelRatio = 1.0;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      final sub = c.listen(dayControllerProvider(today), (_, _) {});
      await c.read(dayControllerProvider(today).future);
      await t.pumpWidget(
        UncontrolledProviderScope(
          container: c,
          child: MaterialApp(
            theme: crudoTheme,
            home: Scaffold(
              body: SwapSheet(date: today, mealId: 'sm-0'),
            ),
          ),
        ),
      );
      await t.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('swap-demo-meal-breakfast')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('swap-demo-meal-lunch')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('swap-demo-meal-snack')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('swap-demo-meal-dinner')),
        findsOneWidget,
      );
      expect(find.text('Protein Oats Bowl'), findsOneWidget);
      expect(find.text('Chicken Rice Bowl'), findsOneWidget);
      expect(find.text('Yogurt & Banana'), findsOneWidget);
      expect(find.text('Salmon & Sweet Potato'), findsOneWidget);
      // Dispose widget tree before container to avoid overlay/timer races.
      await t.pumpWidget(Container());
      await t.pumpAndSettle();
      sub.close();
      c.dispose();
    });

    testWidgets('dangling-ref template renders disabled, tap is a no-op', (
      t,
    ) async {
      final c = container();
      await c
          .read(mealTemplateRepositoryProvider)
          .save(
            const MealTemplate(
              id: 'swap-ghost-meal',
              name: 'Ghost Meal',
              foods: [FoodRef(foodId: 'nope', grams: Grams(100))],
            ),
          );
      t.view.physicalSize = const Size(800, 1600);
      t.view.devicePixelRatio = 1.0;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      final sub = c.listen(dayControllerProvider(today), (_, _) {});
      await c.read(dayControllerProvider(today).future);
      await t.pumpWidget(
        UncontrolledProviderScope(
          container: c,
          child: MaterialApp(
            theme: crudoTheme,
            home: Scaffold(
              body: SwapSheet(date: today, mealId: 'sm-0'),
            ),
          ),
        ),
      );
      await t.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('swap-swap-ghost-meal')),
        findsOneWidget,
      );
      // Repo snapshot before tap
      final dayBefore = await c.read(dayControllerProvider(today).future);
      final before = dayBefore.meals.first;

      await t.tap(find.byKey(const ValueKey('swap-swap-ghost-meal')));
      await t.pump();
      await t.pump(const Duration(milliseconds: 200));

      // State unchanged
      final dayAfter = await c.read(dayControllerProvider(today).future);
      final after = dayAfter.meals.first;
      check(after.id).equals(before.id);
      check(after.meal.name).equals(before.meal.name);

      await t.pumpWidget(Container());
      await t.pumpAndSettle();
      sub.close();
      c.dispose();
    });

    testWidgets('empty template repo → swap-empty state', (t) async {
      final c = ProviderContainer(
        overrides: [
          appConfigProvider.overrideWithValue(AppConfig(flavor: Flavor.dev)),
          seedFoodsProvider.overrideWithValue(seedFoods),
          clockProvider.overrideWithValue(() => now),
          idGeneratorProvider.overrideWithValue(FakeIdGenerator()),
          mealTemplateRepositoryProvider.overrideWithValue(
            InMemoryMealTemplateRepository(),
          ),
        ],
      );
      t.view.physicalSize = const Size(800, 1600);
      t.view.devicePixelRatio = 1.0;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      final sub = c.listen(dayControllerProvider(today), (_, _) {});
      await c.read(dayControllerProvider(today).future);
      await t.pumpWidget(
        UncontrolledProviderScope(
          container: c,
          child: MaterialApp(
            theme: crudoTheme,
            home: Scaffold(
              body: SwapSheet(date: today, mealId: 'sm-0'),
            ),
          ),
        ),
      );
      await t.pumpAndSettle();
      expect(find.byKey(const ValueKey('swap-empty')), findsOneWidget);

      await t.pumpWidget(Container());
      await t.pumpAndSettle();
      sub.close();
      c.dispose();
    });

    testWidgets('tap a row → replaces meal content, slot id + time survive', (
      t,
    ) async {
      final c = container();
      t.view.physicalSize = const Size(800, 1600);
      t.view.devicePixelRatio = 1.0;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      final sub = c.listen(dayControllerProvider(today), (_, _) {});
      await c.read(dayControllerProvider(today).future);
      await t.pumpWidget(
        UncontrolledProviderScope(
          container: c,
          child: MaterialApp(
            theme: crudoTheme,
            home: Scaffold(
              body: SwapSheet(date: today, mealId: 'sm-2'),
            ),
          ),
        ),
      );
      await t.pumpAndSettle();

      // sm-2 is the snack meal (Yogurt & Banana)
      final dayBefore = await c.read(dayControllerProvider(today).future);
      final before = dayBefore.meals.firstWhere((m) => m.id == 'sm-2');
      check(before.meal.name).equals('Yogurt & Banana');

      await t.tap(find.byKey(const ValueKey('swap-demo-meal-dinner')));
      await t.pump();
      await t.pump(const Duration(milliseconds: 200));

      final dayAfter = await c.read(dayControllerProvider(today).future);
      final after = dayAfter.meals.firstWhere((m) => m.id == 'sm-2');
      check(after.id).equals(before.id); // slot id survives
      check(after.time).equals(before.time); // time survives
      check(after.meal.name).equals('Salmon & Sweet Potato');
      check(after.meal.anyChecked).isFalse();

      await t.pumpWidget(Container());
      await t.pumpAndSettle();
      sub.close();
      c.dispose();
    });

    testWidgets('future day first swap → detaches the day', (t) async {
      final c = container();
      t.view.physicalSize = const Size(800, 1600);
      t.view.devicePixelRatio = 1.0;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      final sub = c.listen(dayControllerProvider(tomorrow), (_, _) {});
      final dayPreview = await c.read(dayControllerProvider(tomorrow).future);
      final mealId = dayPreview.meals.first.id;

      // Confirm tomorrow is not yet persisted
      check(await c.read(dayRepositoryProvider).getByDate(tomorrow)).isNull();

      await t.pumpWidget(
        UncontrolledProviderScope(
          container: c,
          child: MaterialApp(
            theme: crudoTheme,
            home: Scaffold(
              body: SwapSheet(date: tomorrow, mealId: mealId),
            ),
          ),
        ),
      );
      await t.pumpAndSettle();

      await t.tap(find.byKey(const ValueKey('swap-demo-meal-dinner')));
      await t.pump();
      await t.pump(const Duration(milliseconds: 200));
      // The toast timer (4.5s) is active; pump it out before teardown.
      await t.pump(const Duration(seconds: 5));

      // Day should now be persisted (detached)
      check(
        await c.read(dayRepositoryProvider).getByDate(tomorrow),
      ).isNotNull();

      // Remove widget tree before container disposal so overlay/timer
      // teardown doesn't race provider disposal.
      await t.pumpWidget(Container());
      await t.pumpAndSettle();
      sub.close();
      c.dispose();
    });

    testWidgets('already-detached day second swap → still works', (t) async {
      final c = container();
      t.view.physicalSize = const Size(800, 1600);
      t.view.devicePixelRatio = 1.0;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      final sub = c.listen(dayControllerProvider(tomorrow), (_, _) {});
      final dayPreview = await c.read(dayControllerProvider(tomorrow).future);
      final mealId = dayPreview.meals.first.id;

      // First swap: detach the day with a different meal
      await c
          .read(dayControllerProvider(tomorrow).notifier)
          .replaceMeal(mealId, dayPreview.meals[1].meal);
      // Let the async save + stream broadcast fully settle.
      await t.pumpAndSettle();

      // Confirm the day is now persisted
      final dayAfterFirst = await c
          .read(dayRepositoryProvider)
          .getByDate(tomorrow);
      check(dayAfterFirst).isNotNull();
      check(
        dayAfterFirst!.meals.firstWhere((m) => m.id == mealId).meal.name,
      ).equals('Chicken Rice Bowl');

      await t.pumpWidget(
        UncontrolledProviderScope(
          container: c,
          child: MaterialApp(
            theme: crudoTheme,
            home: Scaffold(
              body: SwapSheet(date: tomorrow, mealId: mealId),
            ),
          ),
        ),
      );
      await t.pumpAndSettle();

      // Second swap to a different meal
      await t.tap(find.byKey(const ValueKey('swap-demo-meal-dinner')));
      await t.pump();
      await t.pump(const Duration(milliseconds: 200));

      final dayAfterSecond = await c
          .read(dayRepositoryProvider)
          .getByDate(tomorrow);
      check(dayAfterSecond).isNotNull();
      check(
        dayAfterSecond!.meals.firstWhere((m) => m.id == mealId).meal.name,
      ).equals('Salmon & Sweet Potato');

      // Remove widget tree before container disposal.
      await t.pumpWidget(Container());
      await t.pumpAndSettle();
      sub.close();
      c.dispose();
    });
  });
}
