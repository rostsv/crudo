import 'package:crudo/config/app_config.dart';
import 'package:crudo/config/di.dart';
import 'package:crudo/data/services/id_generator.dart';
import 'package:crudo/data/services/seed_service.dart';
import 'package:crudo/domain/food/food.dart';
import 'package:crudo/domain/services/meal_lifecycle.dart';
import 'package:crudo/ui/core/formatting.dart';
import 'package:crudo/ui/core/themes/theme.dart';
import 'package:crudo/ui/core/widgets/meal_card.dart';
import 'package:crudo/ui/features/meals/views/meal_detail_screen.dart';
import 'package:crudo/ui/features/today/view_models/day_controller.dart';
import 'package:crudo/ui/features/today/view_models/today_providers.dart';
import 'package:crudo/ui/features/today/views/intake_card.dart';
import 'package:crudo/ui/features/today/views/today_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../../../helpers/fake_id_generator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late List<Food> seedFoods;
  setUpAll(() async => seedFoods = await SeedService().loadFoods());

  var now = DateTime(2026, 6, 4, 9, 30); // local Thursday
  final today = DateTime.utc(2026, 6, 4);

  setUp(() => now = DateTime(2026, 6, 4, 9, 30));

  ProviderContainer container() {
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

  GoRouter router(ProviderContainer c) => GoRouter(
    initialLocation: '/today',
    routes: [
      GoRoute(path: '/today', builder: (context, state) => const TodayScreen()),
      GoRoute(
        path: '/meal/:date/:mealId',
        builder: (context, state) => MealDetailScreen(
          date: parseDayParam(state.pathParameters['date']!),
          mealId: state.pathParameters['mealId']!,
        ),
      ),
    ],
  );

  Future<ProviderContainer> pumpToday(WidgetTester tester) async {
    final c = container();
    c.listen(dayControllerProvider(today), (_, _) {});
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: c,
        child: MaterialApp.router(theme: crudoTheme, routerConfig: router(c)),
      ),
    );
    await tester.pumpAndSettle();
    return c;
  }

  testWidgets('renders date label + greeting + Mon–Sun strip', (tester) async {
    await pumpToday(tester);
    expect(find.text('THURSDAY, JUNE 4'), findsOneWidget);
    expect(find.text('Good morning'), findsOneWidget); // 09:30, no name
    for (final letter in ['M', 'T', 'W', 'T', 'F', 'S', 'S']) {
      expect(find.text(letter), findsWidgets);
    }
  });

  testWidgets('renders intake card, streak chip and spec nudge copy', (
    tester,
  ) async {
    await pumpToday(tester);
    expect(find.text("TODAY'S INTAKE"), findsOneWidget);
    expect(find.text('0-day streak'), findsOneWidget);
    // Nothing consumed yet; breakfast auto-skipped at 09:30 → 3 upcoming.
    expect(find.text("You're 0% of the way there."), findsOneWidget);
    expect(
      find.text('3 meals remain. A done day keeps the streak.'),
      findsOneWidget,
    );
  });

  testWidgets('meal cards render the 4 demo meals + counts header', (
    tester,
  ) async {
    await pumpToday(tester);
    expect(find.byType(MealCard), findsNWidgets(4));
    expect(find.text('Protein Oats Bowl'), findsOneWidget);
    expect(find.text('Chicken Rice Bowl'), findsOneWidget);
    expect(find.text('Yogurt & Banana'), findsOneWidget);
    expect(find.text('Salmon & Sweet Potato'), findsOneWidget);
    expect(find.text('0/4 complete'), findsOneWidget);
  });

  testWidgets(
    'today: tapping a meal card pushes MealDetailScreen; Mark Done works',
    (tester) async {
      final c = await pumpToday(tester);
      // Breakfast (08:00) is derived skipped at 09:30 — tap it anyway.
      await tester.tap(find.text('Protein Oats Bowl'), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(find.byType(MealDetailScreen), findsOneWidget);
      expect(find.text('Mark Done'), findsOneWidget);
      await tester.tap(find.text('Mark Done'));
      await tester.pumpAndSettle();
      // Popped back to TodayScreen.
      expect(find.byType(TodayScreen), findsOneWidget);
      final day = await c.read(dayControllerProvider(today).future);
      expect(day.meals.first.meal.allChecked, isTrue);
      expect(find.text('1/4 complete'), findsOneWidget);
    },
  );

  testWidgets('today: Skip from detail marks the meal skipped', (tester) async {
    final c = await pumpToday(tester);
    await tester.tap(find.text('Chicken Rice Bowl'), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.byType(MealDetailScreen), findsOneWidget);
    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();
    // Popped back.
    expect(find.byType(TodayScreen), findsOneWidget);
    final day = await c.read(dayControllerProvider(today).future);
    expect(day.meals.firstWhere((m) => m.id == 'sm-1').skippedAt, isNotNull);
  });

  testWidgets('Snooze flows from the detail tile; card shows both times', (
    tester,
  ) async {
    final c = await pumpToday(tester);
    await tester.tap(find.text('Chicken Rice Bowl'), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.byType(MealDetailScreen), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('tile-snooze')));
    await tester.pumpAndSettle();
    expect(find.text('Snooze, then eat.'), findsOneWidget);
    await tester.tap(find.text('Snooze 15m'));
    await tester.pumpAndSettle();
    final day = await c.read(dayControllerProvider(today).future);
    // Lunch at 12:30, snoozed at 09:30 → base = scheduled 12:30, +15m = 12:45.
    expect(
      day.meals.firstWhere((m) => m.id == 'sm-1').snoozedUntil,
      DateTime(2026, 6, 4, 12, 45).toUtc(),
    );
    // Close the detail screen and verify the card renders the snoozed time.
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    expect(find.textContaining('12:45'), findsOneWidget);
  });

  testWidgets('past day with no data shows the locked empty state', (
    tester,
  ) async {
    await pumpToday(tester);
    await tester.tap(find.text('2')); // Tuesday June 2 — repo miss
    await tester.pumpAndSettle();
    expect(find.text('TUESDAY, JUNE 2'), findsOneWidget);
    expect(find.text('No data for this day.'), findsOneWidget);
    expect(find.text("You're 0% of the way there."), findsNothing); // no nudge
  });

  testWidgets('future day: cards are tappable and push MealDetailScreen', (
    tester,
  ) async {
    final c = await pumpToday(tester);
    await tester.tap(find.text('5')); // Friday June 5 — future preview
    await tester.pumpAndSettle();
    expect(find.byType(MealCard), findsNWidgets(4));
    await tester.tap(find.text('Protein Oats Bowl'), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.byType(MealDetailScreen), findsOneWidget);
    // No footer (Mark Done/Skip) on future days.
    expect(find.text('Mark Done'), findsNothing);
    // Preview was never persisted.
    final repo = c.read(dayRepositoryProvider);
    expect(await repo.getByDate(DateTime.utc(2026, 6, 5)), isNull);
  });

  testWidgets('calendar button shows the coming-soon toast', (tester) async {
    await pumpToday(tester);
    await tester.tap(find.byIcon(Icons.calendar_today_outlined));
    await tester.pump();
    expect(find.text('Calendar — coming soon'), findsOneWidget);
    // Flush the toast's auto-dismiss timer so the test ends clean.
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('hero freezes while route open, settles after pop', (
    tester,
  ) async {
    final c = await pumpToday(tester);
    // Open the first meal detail (full-screen route, hero hidden behind it).
    await tester.tap(find.text('Protein Oats Bowl'), warnIfMissed: false);
    await tester.pumpAndSettle();
    // Toggle a single item (does not close the route).
    await tester.tap(find.byKey(const ValueKey('item-check-0')));
    await tester.pumpAndSettle();
    // Pop the route — freeze clears in .whenComplete.
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    // Now the hero should show the updated kcal.
    final day = await c.read(dayControllerProvider(today).future);
    final consumed = consumedKcal(day).round();
    expect(find.text('$consumed'), findsOneWidget);
  });

  testWidgets('hero animates to new value after state change', (tester) async {
    final c = await pumpToday(tester);
    // Mark the first meal as eaten via the controller directly (no route).
    final day = await c.read(dayControllerProvider(today).future);
    final mealId = day.meals.first.id;
    await c.read(dayControllerProvider(today).notifier).markAllEaten(mealId);
    // Wait for the async state change and the 500 ms animation to complete.
    await tester.pumpAndSettle();
    // After the animation completes, the final value should be visible.
    final updatedDay = await c.read(dayControllerProvider(today).future);
    final consumed = consumedKcal(updatedDay).round();
    final consumedFinder = find.descendant(
      of: find.byType(IntakeCard),
      matching: find.text('$consumed'),
    );
    expect(consumedFinder, findsOneWidget);
  });

  Finder statusCircle(String mealName, String statusName) {
    final card = find.ancestor(
      of: find.text(mealName),
      matching: find.byType(MealCard),
    );
    return find.descendant(
      of: card,
      matching: find.byKey(ValueKey('meal-status-$statusName')),
    );
  }

  testWidgets(
    'circle tap completes an upcoming meal (status → done, hero updates)',
    (tester) async {
      final c = await pumpToday(tester);
      // Lunch (sm-1) is upcoming at 09:30.
      await tester.tap(statusCircle('Chicken Rice Bowl', 'upcoming'));
      await tester.pumpAndSettle();
      final day = await c.read(dayControllerProvider(today).future);
      final lunch = day.meals.firstWhere((m) => m.id == 'sm-1');
      expect(lunch.meal.allChecked, isTrue);
      expect(statusCircle('Chicken Rice Bowl', 'done'), findsOneWidget);
    },
  );

  testWidgets('second circle tap undoes a done meal (status back)', (
    tester,
  ) async {
    final c = await pumpToday(tester);
    // Complete then undo the first meal.
    await tester.tap(statusCircle('Protein Oats Bowl', 'skipped'));
    await tester.pumpAndSettle();
    final day1 = await c.read(dayControllerProvider(today).future);
    expect(day1.meals.first.meal.allChecked, isTrue);

    await tester.tap(statusCircle('Protein Oats Bowl', 'done'));
    await tester.pumpAndSettle();
    final day2 = await c.read(dayControllerProvider(today).future);
    expect(day2.meals.first.meal.anyChecked, isFalse);
  });

  testWidgets('circle tap on a skipped meal completes it', (tester) async {
    final c = await pumpToday(tester);
    // Breakfast is derived skipped at 09:30.
    await tester.tap(statusCircle('Protein Oats Bowl', 'skipped'));
    await tester.pumpAndSettle();
    final day = await c.read(dayControllerProvider(today).future);
    expect(day.meals.first.meal.allChecked, isTrue);
  });

  testWidgets('status circle is inert on past and future days', (tester) async {
    final c = await pumpToday(tester);
    // Past day — tapping the first card's circle should not change state.
    await tester.tap(find.text('2'));
    await tester.pumpAndSettle();
    final dayPastBefore = await c.read(
      dayControllerProvider(DateTime.utc(2026, 6, 2)).future,
    );
    if (dayPastBefore.meals.isNotEmpty) {
      await tester.tap(
        statusCircle(dayPastBefore.meals.first.meal.name, 'skipped'),
      );
      await tester.pumpAndSettle();
      final dayPastAfter = await c.read(
        dayControllerProvider(DateTime.utc(2026, 6, 2)).future,
      );
      expect(dayPastAfter.meals.first.meal.anyChecked, isFalse);
    }

    // Future day — same: circle tap does nothing.
    await tester.tap(find.text('5'));
    await tester.pumpAndSettle();
    final dayFutureBefore = await c.read(
      dayControllerProvider(DateTime.utc(2026, 6, 5)).future,
    );
    if (dayFutureBefore.meals.isNotEmpty) {
      await tester.tap(
        statusCircle(dayFutureBefore.meals.first.meal.name, 'upcoming'),
      );
      await tester.pumpAndSettle();
      final dayFutureAfter = await c.read(
        dayControllerProvider(DateTime.utc(2026, 6, 5)).future,
      );
      expect(dayFutureAfter.meals.first.meal.anyChecked, isFalse);
    }
  });

  testWidgets(
    'overdue meal: OVERDUE label + snoozed time persist on the card',
    (tester) async {
      now = DateTime(2026, 6, 4, 15, 55);
      final c = await pumpToday(tester);
      await c
          .read(dayControllerProvider(today).notifier)
          .snooze('sm-2', DateTime(2026, 6, 4, 16, 15));
      // Cross into the grace window: 16:15 + 15m → 16:30 (dinner 19:00 no cap).
      now = DateTime(2026, 6, 4, 16, 20);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: c,
          child: MaterialApp.router(theme: crudoTheme, routerConfig: router(c)),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('OVERDUE'), findsOneWidget);
      // The card's time row is a Text.rich — match the span, not a Text widget.
      expect(
        find.textContaining('16:15', findRichText: true),
        findsOneWidget,
      ); // snoozed label persists
    },
  );

  testWidgets('nudge counts an overdue meal as remaining', (tester) async {
    now = DateTime(2026, 6, 4, 15, 55);
    final c = await pumpToday(tester);
    await c
        .read(dayControllerProvider(today).notifier)
        .snooze('sm-2', DateTime(2026, 6, 4, 16, 15));
    now = DateTime(2026, 6, 4, 16, 20);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: c,
        child: MaterialApp.router(theme: crudoTheme, routerConfig: router(c)),
      ),
    );
    await tester.pumpAndSettle();
    // snack overdue + dinner upcoming = 2 (breakfast/lunch auto-skipped).
    expect(
      find.text('2 meals remain. A done day keeps the streak.'),
      findsOneWidget,
    );
  });

  testWidgets('circle tap on an overdue meal completes it', (tester) async {
    now = DateTime(2026, 6, 4, 15, 55);
    final c = await pumpToday(tester);
    await c
        .read(dayControllerProvider(today).notifier)
        .snooze('sm-2', DateTime(2026, 6, 4, 16, 15));
    now = DateTime(2026, 6, 4, 16, 20);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: c,
        child: MaterialApp.router(theme: crudoTheme, routerConfig: router(c)),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('meal-status-overdue')),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();
    final day = await c.read(dayControllerProvider(today).future);
    expect(day.meals.firstWhere((m) => m.id == 'sm-2').meal.allChecked, isTrue);
  });
}
