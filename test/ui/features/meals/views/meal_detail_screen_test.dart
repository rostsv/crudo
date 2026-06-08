import 'package:checks/checks.dart';
import 'package:crudo/config/app_config.dart';
import 'package:crudo/config/di.dart';
import 'package:crudo/data/services/id_generator.dart';
import 'package:crudo/data/services/seed_service.dart';
import 'package:crudo/domain/food/food.dart';
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

  /// GoRouter harness — for tests that trigger context.pop() (Mark Done,
  /// Save Partial, Skip, edit push, swap/done guard).
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
        expect(find.byKey(const ValueKey('eaten-count')), findsOneWidget);
        expect(find.byKey(const ValueKey('item-check-0')), findsWidgets);
        expect(find.byKey(const ValueKey('item-check-3')), findsWidgets);
        expect(find.byKey(const ValueKey('tile-snooze')), findsOneWidget);
        expect(find.byKey(const ValueKey('tile-swap')), findsOneWidget);
        expect(find.text('Mark Done'), findsOneWidget);
        expect(find.text('Skip'), findsOneWidget);
      },
    );

    testWidgets('today: item tap checks/unchecks; eaten-count updates', (
      tester,
    ) async {
      await open(tester, date: today);
      await tester.tap(find.byKey(const ValueKey('item-check-0')));
      await tester.pumpAndSettle();
      expect(find.text('1 OF 4 EATEN'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('item-check-0')));
      await tester.pumpAndSettle();
      expect(find.text('0 OF 4 EATEN'), findsOneWidget);
    });

    testWidgets('today: Mark Done marks all and pops', (tester) async {
      await openWithRouter(tester, date: today);
      await tester.tap(find.text('Mark Done'));
      await tester.pumpAndSettle();
      // After pop, we're back on the launcher — Mark Done gone.
      expect(find.text('Mark Done'), findsNothing);
      final day = await container.read(dayControllerProvider(today).future);
      check(day.meals.first.meal.allChecked).isTrue();
    });

    testWidgets('today: Save Partial pops, keeps checked state', (
      tester,
    ) async {
      await openWithRouter(tester, date: today);
      await tester.tap(find.byKey(const ValueKey('item-check-0')));
      await tester.pumpAndSettle();
      expect(find.text('Save Partial'), findsOneWidget);
      await tester.tap(find.text('Save Partial'));
      await tester.pumpAndSettle();
      expect(find.text('Save Partial'), findsNothing);
      final day = await container.read(dayControllerProvider(today).future);
      check(day.meals.first.meal.items.first.checked).isTrue();
    });

    testWidgets('today: Mark Done when all checked pops', (tester) async {
      await openWithRouter(tester, date: today);
      final day0 = await container.read(dayControllerProvider(today).future);
      await container
          .read(dayControllerProvider(today).notifier)
          .markAllEaten(day0.meals.first.id);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Mark Done'));
      await tester.pumpAndSettle();
      expect(find.text('Mark Done'), findsNothing);
    });

    testWidgets('today: Skip skips and pops', (tester) async {
      await openWithRouter(tester, date: today);
      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();
      final day = await container.read(dayControllerProvider(today).future);
      check(day.meals.first.skippedAt).isNotNull();
    });

    testWidgets('today: snooze tile opens SnoozeSheet for upcoming meal', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      await open(tester, date: today, mealId: 'sm-2');
      await tester.drag(find.byType(ListView), const Offset(0, -300));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('tile-snooze')));
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

    testWidgets('today: swap tile opens SwapSheet for upcoming meal', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      await open(tester, date: today, mealId: 'sm-2');
      await tester.drag(find.byType(ListView), const Offset(0, -300));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('tile-swap')));
      await tester.pumpAndSettle();
      // The SwapSheet is open — its "From your library" kicker is now visible.
      expect(find.text('FROM YOUR LIBRARY'), findsOneWidget);
    });

    testWidgets('today: swap tile on done meal toasts guard, no sheet', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      await openWithRouter(tester, date: today);
      final day0 = await container.read(dayControllerProvider(today).future);
      await container
          .read(dayControllerProvider(today).notifier)
          .markAllEaten(day0.meals.first.id);
      await tester.pumpAndSettle();
      await tester.drag(find.byType(ListView), const Offset(0, -300));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('tile-swap')));
      await tester.pumpAndSettle();
      expect(find.text("That can't be changed anymore."), findsOneWidget);
      await tester.pump(const Duration(seconds: 5));
    });

    testWidgets('today: disabled snooze tile on done meal toasts reason', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      await open(tester, date: today);
      final day0 = await container.read(dayControllerProvider(today).future);
      await container
          .read(dayControllerProvider(today).notifier)
          .markAllEaten(day0.meals.first.id);
      await tester.pumpAndSettle();
      await tester.drag(find.byType(ListView), const Offset(0, -300));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('tile-snooze')));
      await tester.pumpAndSettle();
      expect(find.text('Meal is done'), findsOneWidget);
      await tester.pump(const Duration(seconds: 5));
    });

    // ── Meal gone ───────────────────────────────────────────────

    testWidgets('unknown mealId shows meal-gone state', (tester) async {
      await open(tester, date: today, mealId: 'nonexistent');
      expect(find.byKey(const ValueKey('meal-gone')), findsOneWidget);
    });
  });
}
