import 'package:checks/checks.dart';
import 'package:crudo/config/app_config.dart';
import 'package:crudo/config/di.dart';
import 'package:crudo/data/services/id_generator.dart';
import 'package:crudo/data/services/seed_service.dart';
import 'package:crudo/domain/food/food.dart';
import 'package:crudo/domain/meal/food_snapshot.dart';
import 'package:crudo/domain/shared/grams.dart';
import 'package:crudo/ui/core/formatting.dart';
import 'package:crudo/ui/core/themes/theme.dart';
import 'package:crudo/ui/features/meals/view_models/meal_draft_controller.dart';
import 'package:crudo/ui/features/meals/views/formatting.dart';
import 'package:crudo/ui/features/meals/views/meal_editor_screen.dart';
import 'package:crudo/ui/features/today/view_models/day_controller.dart';
import 'package:crudo/ui/features/today/view_models/today_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../../../helpers/fake_id_generator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<Food> seedFoods;
  setUpAll(() async => seedFoods = await SeedService().loadFoods());

  var now = DateTime(
    2026,
    6,
    4,
    7,
    0,
  ); // 7 AM — before all meals (breakfast=8AM, so all upcoming)
  final today = DateTime.utc(2026, 6, 4);
  final tomorrow = DateTime.utc(2026, 6, 5);

  ProviderContainer container({DateTime? date}) {
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

  // fakeSnap is computed lazily after seedFoods is loaded.
  FoodSnapshot fakeSnap() => FoodSnapshot.from(
    seedFoods.firstWhere((f) => f.name == 'Chicken breast'),
    const Grams(80),
  );

  /// GoRouter harness: '/' → launcher; '/meal/:date/:mealId/edit' → MealEditorScreen;
  /// '/meal/:date/:mealId/edit/add-ingredient' → fake that pops the known snapshot.
  Widget app(ProviderContainer c) {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () =>
                    context.push('/meal/${dayParam(today)}/sm-0/edit'),
                child: const Text('open-today'),
              ),
            ),
          ),
        ),
        GoRoute(
          path: '/meal/:date/:mealId/edit',
          builder: (context, state) => MealEditorScreen(
            date: parseDayParam(state.pathParameters['date']!),
            mealId: state.pathParameters['mealId']!,
          ),
          routes: [
            GoRoute(
              path: 'add-ingredient',
              builder: (context, state) => Scaffold(
                body: ElevatedButton(
                  key: const ValueKey('fake-add-ingredient'),
                  onPressed: () => context.pop(fakeSnap()),
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

  /// Open the editor for 'today' (sm-0 = first meal, Protein Oats Bowl).
  Future<ProviderContainer> pump(WidgetTester t, {DateTime? date}) async {
    final c = container(date: date ?? today);
    t.view.physicalSize = const Size(800, 1800);
    t.view.devicePixelRatio = 1.0;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    // Materialize today's day first so the draft can load it.
    c.listen(dayControllerProvider(today), (_, _) {});
    await c.read(dayControllerProvider(today).future);
    await t.pumpWidget(app(c));
    await t.pumpAndSettle();
    await t.tap(find.text('open-today'));
    await t.pumpAndSettle();
    return c;
  }

  group('MealEditorScreen', () {
    // 7 AM — before breakfast (08:00), so the meal is `upcoming` and editable
    // (replaceMeal's content-edit guard only allows upcoming). The earlier
    // 09:30 override made breakfast auto-skipped → every save-path test failed.
    setUp(() => now = DateTime(2026, 6, 4, 7, 0));

    testWidgets('renders prefilled name, tag chip, ingredient rows, kcal', (
      t,
    ) async {
      await pump(t);
      expect(find.byKey(const ValueKey('meal-name')), findsOneWidget);
      // Protein Oats Bowl is loaded as the name
      final nameWidget = t.widget<TextField>(
        find.byKey(const ValueKey('meal-name')),
      );
      expect(nameWidget.controller?.text, equals('Protein Oats Bowl'));
      // Breakfast tag selected
      expect(find.byKey(const ValueKey('tag-breakfast')), findsOneWidget);
      // SAVE is enabled (4 items, non-empty name)
      expect(find.byKey(const ValueKey('save-meal')), findsOneWidget);
      // Scroll down to see ingredients
      await t.drag(find.byType(ListView), const Offset(0, -400));
      await t.pumpAndSettle();
      // 4 ingredients (may need scroll to reveal)
      expect(find.byKey(const ValueKey('ingredient-0')), findsOneWidget);
      // macro preview kcal widget visible (scroll further if needed)
      await t.drag(find.byType(ListView), const Offset(0, -400));
      await t.pumpAndSettle();
      expect(find.byKey(const ValueKey('editor-preview-kcal')), findsOneWidget);
    });

    testWidgets('clear name → SAVE dim-disabled; type name → re-enabled', (
      t,
    ) async {
      await pump(t);
      // Clear the name via UI (clears it to empty)
      await t.enterText(find.byKey(const ValueKey('meal-name')), '');
      await t.pumpAndSettle();
      // SAVE button should be disabled (blank name fails canSave)
      final btn = t.widget<TextButton>(find.byKey(const ValueKey('save-meal')));
      expect(btn.onPressed, isNull);

      await t.enterText(find.byKey(const ValueKey('meal-name')), 'New name');
      await t.pumpAndSettle();
      final btn2 = t.widget<TextButton>(
        find.byKey(const ValueKey('save-meal')),
      );
      expect(btn2.onPressed, isNotNull);
    });

    testWidgets('remove row → item count drops + preview kcal changes', (
      t,
    ) async {
      await pump(t);
      // Scroll down to see ingredients + preview
      await t.drag(find.byType(ListView), const Offset(0, -400));
      await t.pumpAndSettle();
      expect(find.byKey(const ValueKey('ingredient-3')), findsOneWidget);

      // Get initial preview kcal text (scroll further if needed)
      await t.drag(find.byType(ListView), const Offset(0, -400));
      await t.pumpAndSettle();
      final initialKcal = t
          .widget<Text>(find.byKey(const ValueKey('editor-preview-kcal')))
          .data;

      // Scroll back up to see ingredient rows
      await t.drag(find.byType(ListView), const Offset(0, 400));
      await t.pumpAndSettle();

      // Remove first item using its remove button (first close icon)
      await t.tap(find.byIcon(Icons.close).first);
      await t.pumpAndSettle();

      // Now 3 items → ingredient-3 key no longer present
      expect(find.byKey(const ValueKey('ingredient-3')), findsNothing);
      // Preview kcal has changed (scroll down to see it)
      await t.drag(find.byType(ListView), const Offset(0, -600));
      await t.pumpAndSettle();
      final newKcal = t
          .widget<Text>(find.byKey(const ValueKey('editor-preview-kcal')))
          .data;
      expect(newKcal, isNot(equals(initialKcal)));
    });

    testWidgets('ADD INGREDIENT → fake picker pops snapshot → 5 items', (
      t,
    ) async {
      await pump(t);
      await t.tap(find.byKey(const ValueKey('add-ingredient')));
      await t.pumpAndSettle();
      // On the fake add-ingredient route
      expect(find.byKey(const ValueKey('fake-add-ingredient')), findsOneWidget);
      await t.tap(find.byKey(const ValueKey('fake-add-ingredient')));
      await t.pumpAndSettle();
      // Back on editor with 5 items
      expect(find.byKey(const ValueKey('ingredient-4')), findsOneWidget);
    });

    testWidgets('row tap → GramsSheet → set-grams → row + preview updates', (
      t,
    ) async {
      await pump(t);
      // Tap the first ingredient row to open grams sheet
      await t.tap(find.byKey(const ValueKey('ingredient-0')));
      await t.pumpAndSettle();
      // GramsSheet is open — shows set-grams button
      expect(find.byKey(const ValueKey('set-grams')), findsOneWidget);
      // Tap 200g preset
      await t.tap(find.byKey(const ValueKey('grams-preset-200')));
      await t.pumpAndSettle();
      // Confirm with Set quantity
      await t.tap(find.byKey(const ValueKey('set-grams')));
      await t.pumpAndSettle();
      // Row updated — expect '200g' in the ingredient row
      expect(find.textContaining('200g'), findsOneWidget);
    });

    testWidgets('SAVE → route pops + repo has new content, items unchecked', (
      t,
    ) async {
      final c = await pump(t);
      // Rename the meal
      final ctrl = c.read(mealDraftControllerProvider(today, 'sm-0').notifier);
      ctrl.setName('Updated Bowl');
      await t.pumpAndSettle();

      await t.tap(find.byKey(const ValueKey('save-meal')));
      await t.pumpAndSettle();

      // Popped back to launcher
      expect(find.text('open-today'), findsOneWidget);

      // Repo has the updated name
      final day = await c.read(dayControllerProvider(today).future);
      final meal = day.meals.firstWhere((m) => m.id == 'sm-0');
      check(meal.meal.name).equals('Updated Bowl');
      check(meal.meal.anyChecked).isFalse();
    });

    testWidgets('back pristine → pops silently, no write', (t) async {
      final c = await pump(t);
      // No changes made — back should pop silently
      await t.tap(find.byIcon(Icons.arrow_back));
      await t.pumpAndSettle();
      // Back on launcher
      expect(find.text('open-today'), findsOneWidget);
      // Repo has no persisted change (or same as loaded)
      final day = await c.read(dayControllerProvider(today).future);
      check(day.meals.first.meal.name).equals('Protein Oats Bowl');
    });

    testWidgets('back dirty → "Discard changes?"; Keep editing stays', (
      t,
    ) async {
      await pump(t);
      // Type into the FIELD (not the provider): this dirties both the
      // TextField text and the draft. Setting the name via the controller
      // notifier alone would not update the field — the field controller is
      // created once from the initial snapshot (S07 controllers-once pattern).
      await t.enterText(find.byKey(const ValueKey('meal-name')), 'Dirty Name');
      await t.pumpAndSettle();

      // Tap back
      await t.tap(find.byIcon(Icons.arrow_back));
      await t.pumpAndSettle();

      // Confirm sheet shown
      expect(find.text('Discard changes?'), findsOneWidget);
      // Tap "Keep editing"
      await t.tap(find.byKey(const ValueKey('keep-editing')));
      await t.pumpAndSettle();

      // Still on editor, field text preserved
      final nameWidget = t.widget<TextField>(
        find.byKey(const ValueKey('meal-name')),
      );
      expect(nameWidget.controller?.text, equals('Dirty Name'));
    });

    testWidgets('back dirty → Discard → pops, repo content unchanged', (
      t,
    ) async {
      final c = await pump(t);
      final ctrl = c.read(mealDraftControllerProvider(today, 'sm-0').notifier);
      ctrl.setName('Dirty Name');
      await t.pumpAndSettle();

      await t.tap(find.byIcon(Icons.arrow_back));
      await t.pumpAndSettle();

      expect(find.text('Discard changes?'), findsOneWidget);
      await t.tap(find.text('Discard'));
      await t.pumpAndSettle();

      // Back on launcher
      expect(find.text('open-today'), findsOneWidget);
      // Repo unchanged
      final day = await c.read(dayControllerProvider(today).future);
      check(day.meals.first.meal.name).equals('Protein Oats Bowl');
    });

    testWidgets('SAVE on today → no detach toast', (t) async {
      final c = await pump(t);
      final ctrl = c.read(mealDraftControllerProvider(today, 'sm-0').notifier);
      ctrl.setName('Updated Today');
      await t.pumpAndSettle();

      await t.tap(find.byKey(const ValueKey('save-meal')));
      await t.pumpAndSettle();

      // No detach toast
      expect(find.text(detachToastMessage), findsNothing);
      // Popped
      expect(find.text('open-today'), findsOneWidget);
    });

    testWidgets(
      'detach toast: editor opened for tomorrow, rename, SAVE → detachToastMessage',
      (t) async {
        // Build a separate harness for tomorrow
        final c = container();
        t.view.physicalSize = const Size(800, 1800);
        t.view.devicePixelRatio = 1.0;
        addTearDown(t.view.resetPhysicalSize);
        addTearDown(t.view.resetDevicePixelRatio);

        // Materialize tomorrow as a preview (not persisted)
        c.listen(dayControllerProvider(tomorrow), (_, _) {});
        final preview = await c.read(dayControllerProvider(tomorrow).future);
        final tomorrowMealId = preview.meals.first.id;
        // Confirm it's not yet persisted
        check(await c.read(dayRepositoryProvider).getByDate(tomorrow)).isNull();

        final tomorrowRouter = GoRouter(
          initialLocation: '/',
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () => context.push(
                      '/meal/${dayParam(tomorrow)}/$tomorrowMealId/edit',
                    ),
                    child: const Text('open-tomorrow'),
                  ),
                ),
              ),
            ),
            GoRoute(
              path: '/meal/:date/:mealId/edit',
              builder: (context, state) => MealEditorScreen(
                date: parseDayParam(state.pathParameters['date']!),
                mealId: state.pathParameters['mealId']!,
              ),
              routes: [
                GoRoute(
                  path: 'add-ingredient',
                  builder: (_, _) => const Scaffold(body: Text('fake-picker')),
                ),
              ],
            ),
          ],
        );
        await t.pumpWidget(
          UncontrolledProviderScope(
            container: c,
            child: MaterialApp.router(
              theme: crudoTheme,
              routerConfig: tomorrowRouter,
            ),
          ),
        );
        await t.pumpAndSettle();
        await t.tap(find.text('open-tomorrow'));
        await t.pumpAndSettle();

        // Rename the meal
        final ctrl = c.read(
          mealDraftControllerProvider(tomorrow, tomorrowMealId).notifier,
        );
        ctrl.setName('Future Bowl');
        await t.pumpAndSettle();

        await t.tap(find.byKey(const ValueKey('save-meal')));
        await t.pumpAndSettle();

        // Detach toast shown
        expect(find.text(detachToastMessage), findsOneWidget);
        await t.pump(const Duration(seconds: 5));
      },
    );

    // NOTE: the "save rejected when the meal flips to checked mid-edit"
    // contract is covered at the unit level by
    // meal_draft_controller_test.dart → 'save on a checked meal surfaces the
    // domain guard' (asserts save() throws StateError). A widget-level
    // variant was removed: it raced a live repo write against a mounted
    // editor + the toast's 4.5s OverlayEntry timer and hung the suite
    // without adding logic coverage beyond the controller test.
  });
}
