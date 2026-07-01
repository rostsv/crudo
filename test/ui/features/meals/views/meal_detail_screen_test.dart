import 'package:checks/checks.dart';
import 'package:crudo/config/app_config.dart';
import 'package:crudo/config/di.dart';
import 'package:crudo/data/services/id_generator.dart';
import 'package:crudo/data/services/seed_service.dart';
import 'package:crudo/domain/food/food.dart';
import 'package:crudo/ui/core/themes/colors.dart';
import 'package:crudo/ui/core/themes/theme.dart';
import 'package:crudo/ui/core/formatting.dart';
import 'package:crudo/ui/features/today/view_models/day_controller.dart';
import 'package:crudo/ui/features/today/view_models/today_providers.dart';
import 'package:crudo/ui/features/meals/views/meal_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../../../helpers/fake_id_generator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late List<Food> seedFoods;
  setUpAll(() async => seedFoods = await SeedService().loadFoods());

  var now = DateTime(2026, 6, 4, 9, 30);
  final today = DateTime.utc(2026, 6, 4);

  late ProviderContainer container;
  var editPushedMealId = '';

  /// Simple MaterialApp — for tests that don't trigger context.pop().
  Future<void> open(
    WidgetTester tester, {
    required DateTime date,
    String mealId = 'sm-0',
  }) async {
    container = ProviderContainer(
      overrides: [
        appConfigProvider.overrideWithValue(AppConfig(flavor: Flavor.dev)),
        seedFoodsProvider.overrideWithValue(seedFoods),
        clockProvider.overrideWithValue(() => now),
        idGeneratorProvider.overrideWithValue(FakeIdGenerator()),
      ],
    );
    addTearDown(container.dispose);
    container.listen(dayControllerProvider(date), (prev, next) {});
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: crudoTheme,
          home: MealDetailScreen(date: date, mealId: mealId),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// GoRouter harness — for tests that trigger context.pop() (Log meal,
  /// Skip, edit push, swap/done guard).
  Future<void> openWithRouter(
    WidgetTester tester, {
    required DateTime date,
    String mealId = 'sm-0',
  }) async {
    editPushedMealId = '';
    container = ProviderContainer(
      overrides: [
        appConfigProvider.overrideWithValue(AppConfig(flavor: Flavor.dev)),
        seedFoodsProvider.overrideWithValue(seedFoods),
        clockProvider.overrideWithValue(() => now),
        idGeneratorProvider.overrideWithValue(FakeIdGenerator()),
      ],
    );
    addTearDown(container.dispose);
    container.listen(dayControllerProvider(date), (prev, next) {});
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () =>
                    context.push('/meal/${dayParam(date)}/$mealId'),
                child: const Text('open'),
              ),
            ),
          ),
        ),
        GoRoute(
          path: '/meal/:date/:mealId',
          builder: (context, state) => MealDetailScreen(
            date: parseDayParam(state.pathParameters['date']!),
            mealId: state.pathParameters['mealId']!,
          ),
          routes: [
            GoRoute(
              path: 'edit',
              builder: (context, state) {
                editPushedMealId = state.pathParameters['mealId']!;
                return Scaffold(
                  body: Text('edit-probe-${state.pathParameters['mealId']}'),
                );
              },
            ),
          ],
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

  group('MealDetailScreen', () {
    setUp(() => now = DateTime(2026, 6, 4, 9, 30));

    // ── Today mode ──────────────────────────────────────────────

    testWidgets(
      'today: opens for breakfast with meal name, macro summary, items, footer',
      (tester) async {
        await open(tester, date: today);
        expect(find.text('Protein Oats Bowl'), findsOneWidget);
        expect(find.text('TOTAL INTAKE'), findsOneWidget);
        expect(find.byKey(const ValueKey('detail-kcal')), findsOneWidget);
        expect(find.text('Ingredients'), findsOneWidget);
        expect(find.byKey(const ValueKey('eaten-count')), findsNothing);
        expect(find.byKey(const ValueKey('item-check-0')), findsWidgets);
        expect(find.byKey(const ValueKey('item-check-3')), findsWidgets);
        expect(find.text('Log meal'), findsOneWidget);
        expect(find.byKey(const ValueKey('meal-actions')), findsOneWidget);
        // Skip is no longer an inline bottom-bar button; it lives in the
        // actions sheet opened by the kebab.
        expect(find.text('Skip'), findsNothing);
      },
    );

    testWidgets(
      'today: TOTAL INTAKE shows kcal hero, macro tiles, and a green tag pill',
      (tester) async {
        await open(tester, date: today);
        final colors = CrudoColors.light;

        expect(find.text('Protein'), findsOneWidget);
        expect(find.text('Carbs'), findsOneWidget);
        expect(find.text('Fats'), findsOneWidget);
        expect(find.text('32g'), findsOneWidget);
        expect(find.text('77g'), findsOneWidget);
        expect(find.text('17g'), findsOneWidget);

        // Protein Oats Bowl has a single tag: breakfast → green pill, caps.
        expect(find.text('BREAKFAST'), findsOneWidget);
        final pill = tester.widget<Container>(
          find
              .ancestor(
                of: find.text('BREAKFAST'),
                matching: find.byType(Container),
              )
              .first,
        );
        check((pill.decoration as BoxDecoration).color).equals(colors.primary);
        final pillText = tester.widget<Text>(find.text('BREAKFAST'));
        check(pillText.style?.color).equals(colors.surfaceLowest);
      },
    );

    testWidgets('today: item tap toggles draft without persisting', (
      tester,
    ) async {
      await open(tester, date: today);
      final before = await container.read(dayControllerProvider(today).future);
      check(before.meals.first.meal.anyChecked).isFalse();

      await tester.tap(find.byKey(const ValueKey('item-check-0')));
      await tester.pumpAndSettle();

      // The circle animates to checked and the progress line fills.
      final row = find.byKey(const ValueKey('item-check-0'));
      expect(
        find.descendant(
          of: row,
          matching: find.byKey(const ValueKey('check-icon')),
        ),
        findsOneWidget,
      );

      // Nothing persisted yet: the controller still sees an unchecked meal.
      final afterTap = await container.read(
        dayControllerProvider(today).future,
      );
      check(afterTap.meals.first.meal.anyChecked).isFalse();

      // Tap again: draft clears.
      await tester.tap(find.byKey(const ValueKey('item-check-0')));
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: row,
          matching: find.byKey(const ValueKey('check-icon')),
        ),
        findsNothing,
      );
    });

    testWidgets(
      'today: item row shows no category icon, still has three macro dots, still toggles',
      (tester) async {
        await open(tester, date: today);
        final row = find.byKey(const ValueKey('item-check-0'));

        // No per-category icon on ingredient rows anymore.
        expect(
          find.descendant(of: row, matching: find.byIcon(Icons.grain)),
          findsNothing,
        );

        final dots = tester
            .widgetList<Container>(
              find.descendant(of: row, matching: find.byType(Container)),
            )
            .where(
              (c) =>
                  c.decoration is BoxDecoration &&
                  (c.decoration as BoxDecoration).shape == BoxShape.circle,
            );
        expect(dots.length, greaterThanOrEqualTo(3));

        await tester.tap(row);
        await tester.pumpAndSettle();
        expect(
          find.descendant(
            of: row,
            matching: find.byKey(const ValueKey('check-icon')),
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'today: ingredient rows alternate surface/surfaceLow (zebra split, no lines)',
      (tester) async {
        await open(tester, date: today);
        final colors = CrudoColors.light;

        Color? colorOf(int i) => tester
            .widget<ColoredBox>(find.byKey(ValueKey('item-row-$i')))
            .color;

        check(colorOf(0)).equals(colors.surface);
        check(colorOf(1)).equals(colors.surfaceLow);
        check(colorOf(2)).equals(colors.surface);
        check(colorOf(3)).equals(colors.surfaceLow);
      },
    );

    testWidgets(
      'today: check-circle ring paints on top of the fill so it stays visible',
      (tester) async {
        await open(tester, date: today);
        final row = find.byKey(const ValueKey('item-check-0'));
        final customPaint = tester.widget<CustomPaint>(
          find.descendant(of: row, matching: find.byType(CustomPaint)).first,
        );
        // A `painter` (background) layer is fully hidden behind the opaque
        // same-size filled circle; the ring must be a `foregroundPainter`.
        expect(customPaint.foregroundPainter, isNotNull);
        expect(customPaint.painter, isNull);
      },
    );

    testWidgets('today: eaten bar fills by kcal share, not item count', (
      tester,
    ) async {
      await open(tester, date: today);

      // Checking item 0 (oats, ~308 kcal of ~582.5 total) should fill the
      // bar to ~53%, not 1/4 = 25% (item-count share).
      await tester.tap(find.byKey(const ValueKey('item-check-0')));
      await tester.pumpAndSettle();

      final trackWidth = tester
          .getSize(find.byKey(const ValueKey('eaten-progress-track')))
          .width;
      final fillWidth = tester
          .getSize(find.byKey(const ValueKey('eaten-progress-fill')))
          .width;
      final ratio = fillWidth / trackWidth;
      check(ratio).isGreaterThan(0.45);
      check(ratio).isLessThan(0.60);
    });

    testWidgets(
      'today: Log meal disabled at zero-checked, enabled after a check, commits on tap',
      (tester) async {
        await openWithRouter(tester, date: today);
        // Zero checked → disabled, tap is a no-op (still on detail screen).
        await tester.tap(find.text('Log meal'), warnIfMissed: false);
        await tester.pumpAndSettle();
        expect(find.text('Log meal'), findsOneWidget);

        await tester.tap(find.byKey(const ValueKey('item-check-0')));
        await tester.pumpAndSettle();

        // Enabled now — tap commits the draft {0} and pops.
        await tester.tap(find.text('Log meal'));
        await tester.pumpAndSettle();
        expect(find.text('Log meal'), findsNothing);
        final day = await container.read(dayControllerProvider(today).future);
        check(day.meals.first.meal.items[0].checked).isTrue();
        check(day.meals.first.meal.items[1].checked).isFalse();
        check(day.meals.first.meal.allChecked).isFalse();
      },
    );

    testWidgets(
      'today: Log meal disabled when draft matches persisted, enabled on change',
      (tester) async {
        await openWithRouter(tester, date: today);
        final day0 = await container.read(dayControllerProvider(today).future);
        final mealId = day0.meals.first.id;
        await container
            .read(dayControllerProvider(today).notifier)
            .markAllEaten(mealId);
        await tester.pumpAndSettle();

        // Re-opened a done meal: draft equals persisted → disabled.
        await tester.tap(find.text('Log meal'), warnIfMissed: false);
        await tester.pumpAndSettle();
        expect(find.text('Log meal'), findsOneWidget);

        // Uncheck one box: draft differs from persisted → enabled.
        await tester.tap(find.byKey(const ValueKey('item-check-0')));
        await tester.pumpAndSettle();

        // Reducing a done meal prompts for confirmation.
        await tester.tap(find.text('Log meal'));
        await tester.pumpAndSettle();
        expect(find.text('Modify this meal?'), findsOneWidget);
        await tester.tap(find.text('Modify'));
        await tester.pumpAndSettle();
        expect(find.text('Log meal'), findsNothing);
        final day1 = await container.read(dayControllerProvider(today).future);
        final meal = day1.meals.firstWhere((m) => m.id == mealId);
        check(meal.meal.items[0].checked).isFalse();
        check(meal.meal.items[1].checked).isTrue();
      },
    );

    testWidgets(
      'today: undo confirm on detail Cancel aborts and leaves meal done',
      (tester) async {
        await openWithRouter(tester, date: today);
        final day0 = await container.read(dayControllerProvider(today).future);
        final mealId = day0.meals.first.id;
        await container
            .read(dayControllerProvider(today).notifier)
            .markAllEaten(mealId);
        await tester.pumpAndSettle();

        // Reduce the draft.
        await tester.tap(find.byKey(const ValueKey('item-check-0')));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Log meal'));
        await tester.pumpAndSettle();
        expect(find.text('Modify this meal?'), findsOneWidget);

        // Cancel: stay on detail, persisted state untouched.
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();
        expect(find.text('Modify this meal?'), findsNothing);
        expect(find.text('Log meal'), findsOneWidget);
        final day1 = await container.read(dayControllerProvider(today).future);
        final meal = day1.meals.firstWhere((m) => m.id == mealId);
        check(meal.meal.allChecked).isTrue();
      },
    );

    testWidgets(
      'today: Check-all toggle fills/clears draft only; Log meal commits',
      (tester) async {
        await openWithRouter(tester, date: today);
        final day0 = await container.read(dayControllerProvider(today).future);
        check(day0.meals.first.meal.anyChecked).isFalse();

        await tester.tap(find.byKey(const ValueKey('check-all-toggle')));
        await tester.pumpAndSettle();

        // UI reflects the full draft.
        expect(
          find.descendant(
            of: find.byType(ListView),
            matching: find.byKey(const ValueKey('check-icon')),
          ),
          findsNWidgets(4),
        );
        // Controller is still untouched.
        final afterCheck = await container.read(
          dayControllerProvider(today).future,
        );
        check(afterCheck.meals.first.meal.anyChecked).isFalse();

        await tester.tap(find.byKey(const ValueKey('check-all-toggle')));
        await tester.pumpAndSettle();

        // Draft cleared.
        expect(
          find.descendant(
            of: find.byType(ListView),
            matching: find.byKey(const ValueKey('check-icon')),
          ),
          findsNothing,
        );

        // Check all again, then log to commit.
        await tester.tap(find.byKey(const ValueKey('check-all-toggle')));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Log meal'));
        await tester.pumpAndSettle();
        final afterLog = await container.read(
          dayControllerProvider(today).future,
        );
        check(afterLog.meals.first.meal.allChecked).isTrue();
      },
    );

    testWidgets('today: Skip from actions sheet skips and pops', (
      tester,
    ) async {
      // Before breakfast's 08:00 slot — status is upcoming, so Skip is a
      // real (not already-auto-skipped) action here.
      now = DateTime(2026, 6, 4, 7, 30);
      await openWithRouter(tester, date: today);
      await tester.tap(find.byKey(const ValueKey('meal-actions')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('action-skip')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('action-skip')));
      await tester.pumpAndSettle();
      final day = await container.read(dayControllerProvider(today).future);
      check(day.meals.first.skippedAt).isNotNull();
    });

    testWidgets(
      'today: kebab actions all disabled with an explanatory message once the meal is skipped',
      (tester) async {
        await openWithRouter(tester, date: today);
        await container
            .read(dayControllerProvider(today).notifier)
            .skipMeal('sm-0');
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const ValueKey('meal-actions')));
        await tester.pumpAndSettle();

        expect(
          find.text("This meal was skipped and can't be changed."),
          findsOneWidget,
        );

        for (final key in ['action-snooze', 'action-swap', 'action-skip']) {
          final opacity = tester.widget<Opacity>(
            find
                .descendant(
                  of: find.byKey(ValueKey(key)),
                  matching: find.byType(Opacity),
                )
                .first,
          );
          check(opacity.opacity).isLessThan(1);

          // Tapping a disabled row on a skipped meal must be silent — the
          // explanatory message above already covers it; no toast noise.
          await tester.tap(find.byKey(ValueKey(key)), warnIfMissed: false);
          await tester.pumpAndSettle();
        }
        expect(find.text("Can't snooze"), findsNothing);
        expect(find.text("That can't be changed anymore."), findsNothing);
      },
    );

    testWidgets(
      'today: kebab is also locked for a meal auto-shown as skipped (time passed, never explicitly skipped)',
      (tester) async {
        // Default `now` (09:30) is already past breakfast's 08:00 slot and
        // sm-0 was never snoozed or explicitly skipped — the header shows
        // SKIPPED purely from elapsed time. The kebab must match that.
        await openWithRouter(tester, date: today);
        final day = await container.read(dayControllerProvider(today).future);
        check(day.meals.first.skippedAt).isNull();

        await tester.tap(find.byKey(const ValueKey('meal-actions')));
        await tester.pumpAndSettle();

        expect(
          find.text("This meal was skipped and can't be changed."),
          findsOneWidget,
        );
        for (final key in ['action-snooze', 'action-swap', 'action-skip']) {
          await tester.tap(find.byKey(ValueKey(key)), warnIfMissed: false);
          await tester.pumpAndSettle();
        }
        expect(find.text("Can't snooze"), findsNothing);
        expect(find.text("That can't be changed anymore."), findsNothing);
      },
    );

    testWidgets(
      'today: kebab shows a "already logged" message for a skipped-then-logged meal (partial)',
      (tester) async {
        // Explicitly skip, then check + log one item. `logMeal` never clears
        // skippedAt, so the meal ends up skippedAt != null AND partial —
        // status is no longer "skipped" (checked wins), so the sheet must
        // fall back to a distinct "already logged" message, not go blank.
        await openWithRouter(tester, date: today);
        final notifier = container.read(dayControllerProvider(today).notifier);
        await notifier.skipMeal('sm-0');
        await tester.pumpAndSettle();
        await notifier.logMeal('sm-0', {0});
        await tester.pumpAndSettle();

        final day = await container.read(dayControllerProvider(today).future);
        check(day.meals.first.skippedAt).isNotNull();
        check(day.meals.first.meal.anyChecked).isTrue();
        check(day.meals.first.meal.allChecked).isFalse();

        await tester.tap(find.byKey(const ValueKey('meal-actions')));
        await tester.pumpAndSettle();

        expect(
          find.text("This meal is already logged and can't be changed."),
          findsOneWidget,
        );
        // The stale "skipped" copy must not leak through for this case.
        expect(
          find.text("This meal was skipped and can't be changed."),
          findsNothing,
        );

        for (final key in ['action-snooze', 'action-swap', 'action-skip']) {
          await tester.tap(find.byKey(ValueKey(key)), warnIfMissed: false);
          await tester.pumpAndSettle();
        }
        expect(find.text("Can't snooze"), findsNothing);
        expect(find.text("That can't be changed anymore."), findsNothing);
      },
    );

    testWidgets('today: snooze action opens SnoozeSheet for upcoming meal', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      await open(tester, date: today, mealId: 'sm-2');
      await tester.tap(find.byKey(const ValueKey('meal-actions')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('action-snooze')));
      await tester.pumpAndSettle();
      expect(find.text('Snooze, then eat.'), findsOneWidget);
    });

    testWidgets('today: edit icon pushes edit route for upcoming meal', (
      tester,
    ) async {
      await openWithRouter(tester, date: today, mealId: 'sm-1');
      await tester.tap(find.byKey(const ValueKey('edit-meal')));
      await tester.pumpAndSettle();
      expect(editPushedMealId, equals('sm-1'));
      expect(find.textContaining('edit-probe-'), findsOneWidget);
    });

    testWidgets('today: edit icon on done meal toasts guard, no push', (
      tester,
    ) async {
      await openWithRouter(tester, date: today);
      final day0 = await container.read(dayControllerProvider(today).future);
      await container
          .read(dayControllerProvider(today).notifier)
          .markAllEaten(day0.meals.first.id);
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('edit-meal')),
        warnIfMissed: false,
      );
      await tester.pumpAndSettle();
      expect(find.text("That can't be changed anymore."), findsOneWidget);
      expect(editPushedMealId, isEmpty);
      // Let the toast timer expire to avoid pending timer error.
      await tester.pump(const Duration(seconds: 5));
    });

    testWidgets('today: swap action opens SwapSheet for upcoming meal', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      await open(tester, date: today, mealId: 'sm-2');
      await tester.tap(find.byKey(const ValueKey('meal-actions')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('action-swap')));
      await tester.pumpAndSettle();
      // The SwapSheet is open — its "From your library" kicker is now visible.
      expect(find.text('FROM YOUR LIBRARY'), findsOneWidget);
    });

    testWidgets(
      'today: swap action on done meal is locked with a message, no sheet, no toast',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        await openWithRouter(tester, date: today);
        final day0 = await container.read(dayControllerProvider(today).future);
        await container
            .read(dayControllerProvider(today).notifier)
            .markAllEaten(day0.meals.first.id);
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('meal-actions')));
        await tester.pumpAndSettle();
        expect(
          find.text("This meal is already logged and can't be changed."),
          findsOneWidget,
        );
        await tester.tap(
          find.byKey(const ValueKey('action-swap')),
          warnIfMissed: false,
        );
        await tester.pumpAndSettle();
        expect(find.text("That can't be changed anymore."), findsNothing);
      },
    );

    testWidgets(
      'today: disabled snooze action on done meal is locked with a message, no toast',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        await open(tester, date: today);
        final day0 = await container.read(dayControllerProvider(today).future);
        await container
            .read(dayControllerProvider(today).notifier)
            .markAllEaten(day0.meals.first.id);
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('meal-actions')));
        await tester.pumpAndSettle();
        await tester.tap(
          find.byKey(const ValueKey('action-snooze')),
          warnIfMissed: false,
        );
        await tester.pumpAndSettle();
        expect(find.text('Meal is done'), findsNothing);
        expect(
          find.text("This meal is already logged and can't be changed."),
          findsOneWidget,
        );
      },
    );

    // ── Meal gone ───────────────────────────────────────────────

    testWidgets('unknown mealId shows meal-gone state', (tester) async {
      await open(tester, date: today, mealId: 'nonexistent');
      expect(find.byKey(const ValueKey('meal-gone')), findsOneWidget);
    });

    // ── Swap sheet tag grouping + search (S08) ──────────────────────

    testWidgets('swap: tag grouping visible for breakfast meal (sm-0)', (
      tester,
    ) async {
      // Use a time before breakfast (8:00) so the meal is upcoming.
      now = DateTime(2026, 6, 4, 7, 0);
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      await open(tester, date: today, mealId: 'sm-0');
      await tester.tap(find.byKey(const ValueKey('meal-actions')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('action-swap')));
      await tester.pumpAndSettle();

      // Section headers
      expect(find.text('SAME TYPE'), findsOneWidget);
      expect(find.text('OTHER MEALS'), findsOneWidget);

      // Breakfast template (Protein Oats Bowl) — matches sm-0's breakfast tag
      expect(
        find.byKey(const ValueKey('swap-demo-meal-breakfast')),
        findsOneWidget,
      );
      // Other templates present in OTHER MEALS section
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

      // Partition ordering: breakfast under SAME TYPE, lunch under OTHER MEALS.
      final sameType = tester.getTopLeft(find.text('SAME TYPE')).dy;
      final otherMeals = tester.getTopLeft(find.text('OTHER MEALS')).dy;
      final breakfast = tester
          .getTopLeft(find.byKey(const ValueKey('swap-demo-meal-breakfast')))
          .dy;
      final lunch = tester
          .getTopLeft(find.byKey(const ValueKey('swap-demo-meal-lunch')))
          .dy;
      expect(sameType, lessThan(breakfast));
      expect(breakfast, lessThan(otherMeals));
      expect(otherMeals, lessThan(lunch));
    });

    testWidgets('swap: grouping for snack meal (sm-2)', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      await open(tester, date: today, mealId: 'sm-2');
      await tester.tap(find.byKey(const ValueKey('meal-actions')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('action-swap')));
      await tester.pumpAndSettle();

      // sm-2 is snack-tagged → SAME TYPE section includes Yogurt & Banana
      expect(find.text('SAME TYPE'), findsOneWidget);
      expect(find.text('OTHER MEALS'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('swap-demo-meal-snack')),
        findsOneWidget,
      );
    });

    testWidgets('swap: search flattens sections; clear restores them', (
      tester,
    ) async {
      // Use a time before breakfast (8:00) so sm-0 is upcoming.
      now = DateTime(2026, 6, 4, 7, 0);
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      await open(tester, date: today, mealId: 'sm-0');
      await tester.tap(find.byKey(const ValueKey('meal-actions')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('action-swap')));
      await tester.pumpAndSettle();

      // Confirm sections visible before search
      expect(find.text('SAME TYPE'), findsOneWidget);

      // Type "chicken" to filter
      await tester.enterText(
        find.byKey(const ValueKey('swap-search')),
        'chicken',
      );
      await tester.pumpAndSettle();

      // Sections gone, only Chicken Rice Bowl visible
      expect(find.text('SAME TYPE'), findsNothing);
      expect(find.text('OTHER MEALS'), findsNothing);
      expect(
        find.byKey(const ValueKey('swap-demo-meal-lunch')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('swap-demo-meal-breakfast')),
        findsNothing,
      );
      expect(find.byKey(const ValueKey('swap-demo-meal-snack')), findsNothing);
      expect(find.byKey(const ValueKey('swap-demo-meal-dinner')), findsNothing);

      // Clear search → sections return
      await tester.enterText(find.byKey(const ValueKey('swap-search')), '');
      await tester.pumpAndSettle();

      expect(find.text('SAME TYPE'), findsOneWidget);
      expect(find.text('OTHER MEALS'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('swap-demo-meal-breakfast')),
        findsOneWidget,
      );
    });

    testWidgets('swap: search zero matches shows no rows', (tester) async {
      // Use a time before breakfast (8:00) so sm-0 is upcoming.
      now = DateTime(2026, 6, 4, 7, 0);
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      await open(tester, date: today, mealId: 'sm-0');
      await tester.tap(find.byKey(const ValueKey('meal-actions')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('action-swap')));
      await tester.pumpAndSettle();

      // Type a query that matches nothing
      await tester.enterText(
        find.byKey(const ValueKey('swap-search')),
        'xyzzy',
      );
      await tester.pumpAndSettle();

      // No templates visible
      expect(
        find.byKey(const ValueKey('swap-demo-meal-breakfast')),
        findsNothing,
      );
      expect(find.byKey(const ValueKey('swap-demo-meal-lunch')), findsNothing);
      expect(find.byKey(const ValueKey('swap-demo-meal-snack')), findsNothing);
      expect(find.byKey(const ValueKey('swap-demo-meal-dinner')), findsNothing);
      // Search field still present
      expect(find.byKey(const ValueKey('swap-search')), findsOneWidget);
    });
  });
}
