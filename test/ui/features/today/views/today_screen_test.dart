import 'package:crudo/config/app_config.dart';
import 'package:crudo/config/di.dart';
import 'package:crudo/data/services/id_generator.dart';
import 'package:crudo/data/services/seed_service.dart';
import 'package:crudo/domain/food/food.dart';
import 'package:crudo/ui/core/themes/colors.dart';
import 'package:crudo/ui/core/themes/theme.dart';
import 'package:crudo/ui/core/widgets/meal_card.dart';
import 'package:crudo/ui/features/today/view_models/day_controller.dart';
import 'package:crudo/ui/features/today/view_models/today_providers.dart';
import 'package:crudo/ui/features/today/views/today_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

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

  Widget app(ProviderContainer c) => UncontrolledProviderScope(
    container: c,
    child: MaterialApp(
      theme: crudoTheme,
      home: Scaffold(
        backgroundColor: CrudoColors.light.surface,
        body: const TodayScreen(),
      ),
    ),
  );

  Future<ProviderContainer> pumpToday(WidgetTester tester) async {
    final c = container();
    c.listen(dayControllerProvider(today), (_, _) {});
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(app(c));
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

  testWidgets('auto-skipped meal still opens the sheet and can be marked eaten '
      '(lenient missed meals)', (tester) async {
    final c = await pumpToday(tester);
    // Breakfast (08:00) is derived skipped at 09:30 — tap it anyway.
    await tester.tap(find.text('Protein Oats Bowl'), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.text('Ate it'), findsOneWidget);
    await tester.tap(find.text('Ate it'));
    await tester.pumpAndSettle();
    final day = await c.read(dayControllerProvider(today).future);
    expect(day.meals.first.meal.allChecked, isTrue);
    expect(find.text('1/4 complete'), findsOneWidget);
  });

  testWidgets('Skip from the sheet marks the meal skipped', (tester) async {
    final c = await pumpToday(tester);
    await tester.tap(find.text('Chicken Rice Bowl'), warnIfMissed: false);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();
    final day = await c.read(dayControllerProvider(today).future);
    expect(day.meals.firstWhere((m) => m.id == 'sm-1').skippedAt, isNotNull);
  });

  testWidgets('Snooze flows from the sheet footer; card shows both times', (
    tester,
  ) async {
    final c = await pumpToday(tester);
    await tester.tap(find.text('Chicken Rice Bowl'), warnIfMissed: false);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Snooze'));
    await tester.pumpAndSettle();
    expect(find.text('Snooze, then eat.'), findsOneWidget);
    await tester.tap(find.text('Snooze 15m'));
    await tester.pumpAndSettle();
    final day = await c.read(dayControllerProvider(today).future);
    expect(
      day.meals.firstWhere((m) => m.id == 'sm-1').snoozedUntil,
      DateTime(2026, 6, 4, 9, 45).toUtc(),
    );
    // Close the meal sheet and verify the card renders the snoozed time.
    await tester.tapAt(const Offset(20, 20));
    await tester.pumpAndSettle();
    expect(find.textContaining('09:45'), findsOneWidget);
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

  testWidgets('future day is a read-only preview — cards not tappable', (
    tester,
  ) async {
    final c = await pumpToday(tester);
    await tester.tap(find.text('5')); // Friday June 5 — future preview
    await tester.pumpAndSettle();
    expect(find.byType(MealCard), findsNWidgets(4));
    await tester.tap(find.text('Protein Oats Bowl'), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.text('Ate it'), findsNothing); // no sheet
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
}
