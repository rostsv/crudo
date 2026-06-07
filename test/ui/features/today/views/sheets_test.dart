import 'package:checks/checks.dart';
import 'package:crudo/config/app_config.dart';
import 'package:crudo/config/di.dart';
import 'package:crudo/data/services/id_generator.dart';
import 'package:crudo/data/services/seed_service.dart';
import 'package:crudo/domain/food/food.dart';
import 'package:crudo/ui/core/themes/colors.dart';
import 'package:crudo/ui/core/themes/theme.dart';
import 'package:crudo/ui/core/widgets/primary_cta.dart';
import 'package:crudo/ui/features/today/view_models/day_controller.dart';
import 'package:crudo/ui/features/today/view_models/today_providers.dart';
import 'package:crudo/ui/features/today/views/meal_sheet.dart';
import 'package:crudo/ui/features/today/views/snooze_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/fake_id_generator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late List<Food> seedFoods;
  setUpAll(() async => seedFoods = await SeedService().loadFoods());

  // Mutable fake clock — set per test BEFORE building the container.
  var now = DateTime(2026, 6, 4, 9, 30); // local Thursday
  final today = DateTime.utc(2026, 6, 4);

  late ProviderContainer container;

  Widget app(Widget Function(BuildContext context) sheetOpener) {
    container = ProviderContainer(
      overrides: [
        appConfigProvider.overrideWithValue(AppConfig(flavor: Flavor.dev)),
        seedFoodsProvider.overrideWithValue(seedFoods),
        clockProvider.overrideWithValue(() => now),
        idGeneratorProvider.overrideWithValue(FakeIdGenerator()),
      ],
    );
    addTearDown(container.dispose);
    return UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: crudoTheme,
        home: Scaffold(
          backgroundColor: CrudoColors.light.surface,
          body: Builder(
            builder: (context) => Center(child: sheetOpener(context)),
          ),
        ),
      ),
    );
  }

  /// Pumps the harness, eagerly materializes today (mints sm-0..sm-3), then
  /// taps the opener button.
  Future<void> open(
    WidgetTester tester,
    Widget Function(BuildContext) opener,
  ) async {
    await tester.pumpWidget(app(opener));
    // Keep the auto-dispose controller alive across the await — without a
    // listener the provider disposes mid-build and the future never resolves.
    container.listen(dayControllerProvider(today), (_, _) {});
    await container.read(dayControllerProvider(today).future);
    await tester.pumpAndSettle();
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  Widget mealSheetOpener(
    BuildContext context, {
    String mealId = 'sm-0',
    bool readOnly = false,
  }) => TextButton(
    onPressed: () =>
        showMealSheet(context, date: today, mealId: mealId, readOnly: readOnly),
    child: const Text('open'),
  );

  group('MealSheet', () {
    setUp(() => now = DateTime(2026, 6, 4, 9, 30));

    testWidgets(
      'opens for an auto-skipped meal and shows the 4-ingredient checklist '
      '(lenient missed meals — loggable all day)',
      (tester) async {
        // 09:30 — breakfast (08:00) window has passed → derived skipped.
        await open(tester, (c) => mealSheetOpener(c));
        expect(find.text('Protein Oats Bowl'), findsOneWidget);
        expect(find.textContaining('08:00'), findsOneWidget);
        expect(find.byKey(const ValueKey('item-check-0')), findsOneWidget);
        expect(find.byKey(const ValueKey('item-check-3')), findsOneWidget);
        expect(find.text('Mark Done'), findsOneWidget);
      },
    );

    testWidgets('tapping an item checks it; status label flips to partial '
        'and a second tap unchecks (live state)', (tester) async {
      await open(tester, (c) => mealSheetOpener(c));
      await tester.tap(find.byKey(const ValueKey('item-check-0')));
      // Wait for controller to finish loading before pumping UI
      var day = await container.read(dayControllerProvider(today).future);
      await tester.pumpAndSettle();
      // SheetScaffold renders the label uppercased (sheet.dart).
      expect(find.textContaining('PARTIAL'), findsOneWidget);
      check(day.meals.first.meal.items.first.checked).isTrue();

      // Second tap on the SAME row must uncheck (no stale snapshot).
      await tester.tap(find.byKey(const ValueKey('item-check-0')));
      day = await container.read(dayControllerProvider(today).future);
      await tester.pumpAndSettle();
      check(day.meals.first.meal.items.first.checked).isFalse();
    });

    testWidgets('Mark Done with 0 checked marks all and closes', (
      tester,
    ) async {
      await open(tester, (c) => mealSheetOpener(c));
      await tester.tap(find.text('Mark Done'));
      await tester.pumpAndSettle();
      expect(find.text('Mark Done'), findsNothing); // sheet closed
      final day = await container.read(dayControllerProvider(today).future);
      check(day.meals.first.meal.allChecked).isTrue();
    });

    testWidgets('Save Partial with some checked just closes, keeps state', (
      tester,
    ) async {
      await open(tester, (c) => mealSheetOpener(c));
      // Check one item → partial
      await tester.tap(find.byKey(const ValueKey('item-check-0')));
      await tester.pumpAndSettle();
      expect(find.text('Save Partial'), findsOneWidget);
      await tester.tap(find.text('Save Partial'));
      await tester.pumpAndSettle();
      expect(find.text('Save Partial'), findsNothing); // sheet closed
      final day = await container.read(dayControllerProvider(today).future);
      check(day.meals.first.meal.items.first.checked).isTrue();
      check(day.meals.first.meal.allChecked).isFalse();
    });

    testWidgets('Mark Done with all checked just closes, no re-mark', (
      tester,
    ) async {
      await open(tester, (c) => mealSheetOpener(c));
      // Mark all via controller so the sheet opens with all checked.
      final day0 = await container.read(dayControllerProvider(today).future);
      final id = day0.meals.first.id;
      await container
          .read(dayControllerProvider(today).notifier)
          .markAllEaten(id);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Mark Done'));
      await tester.pumpAndSettle();
      expect(find.text('Mark Done'), findsNothing);
    });

    testWidgets('Skip skips and closes', (tester) async {
      await open(tester, (c) => mealSheetOpener(c));
      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();
      final day = await container.read(dayControllerProvider(today).future);
      check(day.meals.first.skippedAt).isNotNull();
    });

    testWidgets('readOnly hides tiles and footer; item taps are inert', (
      tester,
    ) async {
      await open(tester, (c) => mealSheetOpener(c, readOnly: true));
      expect(find.text('Mark Done'), findsNothing);
      expect(find.text('Skip'), findsNothing);
      expect(find.byKey(const ValueKey('tile-snooze')), findsNothing);
      expect(find.byKey(const ValueKey('tile-swap')), findsNothing);
      await tester.tap(find.byKey(const ValueKey('item-check-0')));
      await tester.pumpAndSettle();
      final day = await container.read(dayControllerProvider(today).future);
      check(day.meals.first.meal.anyChecked).isFalse();
    });

    testWidgets('snooze tile opens SnoozeSheet; disabled when guard fails', (
      tester,
    ) async {
      await open(tester, (c) => mealSheetOpener(c));
      await tester.tap(find.byKey(const ValueKey('tile-snooze')));
      await tester.pumpAndSettle();
      expect(find.text('Snooze, then eat.'), findsOneWidget);
    });

    testWidgets('swap tile renders and tap is a no-op', (tester) async {
      await open(tester, (c) => mealSheetOpener(c));
      expect(find.byKey(const ValueKey('tile-swap')), findsOneWidget);
      // Tapping the swap tile should be a no-op (null onTap).
      await tester.tap(find.byKey(const ValueKey('tile-swap')));
      await tester.pumpAndSettle();
      // Sheet stays open, nothing changed.
      expect(find.text('Protein Oats Bowl'), findsOneWidget);
    });

    testWidgets(
      'disabled snooze tile tap on a done meal toasts "Meal is done"',
      (tester) async {
        await open(tester, (c) => mealSheetOpener(c));
        final day0 = await container.read(dayControllerProvider(today).future);
        await container
            .read(dayControllerProvider(today).notifier)
            .markAllEaten(day0.meals.first.id);
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('tile-snooze')));
        await tester.pump(); // toast entrance
        expect(find.text('Meal is done'), findsOneWidget);
        expect(
          find.text('Snooze, then eat.'),
          findsNothing,
        ); // sheet didn't open
        await tester.pump(const Duration(seconds: 5)); // let the toast expire
      },
    );

    testWidgets(
      'disabled snooze tile tap on a skipped meal toasts "Meal is skipped"',
      (tester) async {
        await open(tester, (c) => mealSheetOpener(c));
        await tester.tap(find.text('Skip'));
        await tester.pumpAndSettle();
        // Skip pops the sheet — reopen on the now-skipped meal.
        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('tile-snooze')));
        await tester.pump();
        expect(find.text('Meal is skipped'), findsOneWidget);
        await tester.pump(const Duration(seconds: 5));
      },
    );
  });

  group('SnoozeSheet', () {
    Widget snoozeOpener(BuildContext context, {String mealId = 'sm-2'}) =>
        TextButton(
          onPressed: () => showCrudoSheetForTest(context, today, mealId),
          child: const Text('open'),
        );

    testWidgets('renders 10/15/20/30; all enabled well before the next slot', (
      tester,
    ) async {
      // Snack is 16:00, next slot 19:00. At 15:55 even +30 (16:25) fits.
      now = DateTime(2026, 6, 4, 15, 55);
      await open(tester, (c) => snoozeOpener(c));
      for (final m in snoozePresetMinutes) {
        expect(find.byKey(ValueKey('snooze-preset-$m')), findsOneWidget);
      }
      expect(find.text('Snooze 15m'), findsOneWidget); // default selection
      // Confirm 15 → snoozedUntil = 16:15 local (base = scheduled 16:00), stored UTC.
      await tester.tap(find.byType(PrimaryCta));
      await tester.pumpAndSettle();
      final day = await container.read(dayControllerProvider(today).future);
      final snack = day.meals.firstWhere((m) => m.id == 'sm-2');
      check(snack.snoozedUntil).equals(DateTime(2026, 6, 4, 16, 15).toUtc());
    });

    testWidgets(
      'presets past the next-meal bound are disabled; bound itself allowed',
      (tester) async {
        // 18:45 — next slot (dinner) is 19:00. +15 = 19:00 == bound (allowed,
        // snoozeMeal uses isAfter); +20/+30 exceed it.
        now = DateTime(2026, 6, 4, 18, 45);
        await open(tester, (c) => snoozeOpener(c));
        // Tapping a disabled preset does not change the selection.
        await tester.tap(find.byKey(const ValueKey('snooze-preset-30')));
        await tester.pumpAndSettle();
        expect(find.text('Snooze 15m'), findsOneWidget);
        // Confirming the bound-exact 15m succeeds and closes the sheet.
        await tester.tap(find.byType(PrimaryCta));
        await tester.pumpAndSettle();
        final day = await container.read(dayControllerProvider(today).future);
        final snack = day.meals.firstWhere((m) => m.id == 'sm-2');
        check(snack.snoozedUntil).equals(DateTime(2026, 6, 4, 19, 0).toUtc());
      },
    );

    testWidgets('Cancel closes the sheet without snoozing', (tester) async {
      now = DateTime(2026, 6, 4, 15, 55);
      await open(tester, (c) => snoozeOpener(c));
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Cancel'), findsNothing); // sheet closed
      final day = await container.read(dayControllerProvider(today).future);
      check(day.meals.firstWhere((m) => m.id == 'sm-2').snoozedUntil).isNull();
    });

    testWidgets('future meal: presets offset from scheduled time', (
      tester,
    ) async {
      now = DateTime(2026, 6, 4, 15, 55);
      await open(tester, (c) => snoozeOpener(c));
      // base = scheduled 16:00; +15m → 16:15
      await tester.tap(find.text('Snooze 15m'));
      await tester.pumpAndSettle();
      final day = await container.read(dayControllerProvider(today).future);
      final snack = day.meals.firstWhere((m) => m.id == 'sm-2');
      check(snack.snoozedUntil).equals(DateTime(2026, 6, 4, 16, 15).toUtc());
    });

    testWidgets('past-due meal: presets offset from now', (tester) async {
      now = DateTime(2026, 6, 4, 16, 40);
      await open(tester, (c) => snoozeOpener(c));
      // base = now 16:40; +15m → 16:55
      await tester.tap(find.text('Snooze 15m'));
      await tester.pumpAndSettle();
      final day = await container.read(dayControllerProvider(today).future);
      final snack = day.meals.firstWhere((m) => m.id == 'sm-2');
      check(snack.snoozedUntil).equals(DateTime(2026, 6, 4, 16, 55).toUtc());
    });

    testWidgets('MealSheet header shows snoozed time after commit', (
      tester,
    ) async {
      now = DateTime(2026, 6, 4, 15, 55);
      await open(tester, (c) => mealSheetOpener(c, mealId: 'sm-2'));
      await tester.tap(find.byKey(const ValueKey('tile-snooze')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Snooze 15m'));
      await tester.pumpAndSettle();
      // Back on MealSheet: header shows the snoozed time (16:00 → 16:15).
      expect(find.textContaining('16:00 → 16:15'), findsOneWidget);
    });

    testWidgets('future meal: presets offset from scheduled time', (
      tester,
    ) async {
      now = DateTime(2026, 6, 4, 15, 55);
      await open(tester, (c) => snoozeOpener(c));
      // base = scheduled 16:00; +15m → 16:15
      await tester.tap(find.byType(PrimaryCta));
      await tester.pumpAndSettle();
      final day = await container.read(dayControllerProvider(today).future);
      final snack = day.meals.firstWhere((m) => m.id == 'sm-2');
      check(snack.snoozedUntil).equals(DateTime(2026, 6, 4, 16, 15).toUtc());
    });

    testWidgets('past-due meal: presets offset from now', (tester) async {
      now = DateTime(2026, 6, 4, 16, 40);
      await open(tester, (c) => snoozeOpener(c));
      // base = now 16:40; +15m → 16:55
      await tester.tap(find.byType(PrimaryCta));
      await tester.pumpAndSettle();
      final day = await container.read(dayControllerProvider(today).future);
      final snack = day.meals.firstWhere((m) => m.id == 'sm-2');
      check(snack.snoozedUntil).equals(DateTime(2026, 6, 4, 16, 55).toUtc());
    });

    testWidgets('preset tiles show resulting local times', (tester) async {
      now = DateTime(2026, 6, 4, 15, 55);
      await open(tester, (c) => snoozeOpener(c));
      // base = 16:00; tiles should show 16:10, 16:15, 16:20, 16:30
      expect(find.text('16:10'), findsOneWidget);
      expect(find.text('16:15'), findsOneWidget);
      expect(find.text('16:20'), findsOneWidget);
      expect(find.text('16:30'), findsOneWidget);
    });

    testWidgets(
      'bound 20 min away: 10/15/20 enabled (bound inclusive), 30 reasoned '
      '"Past Dinner"',
      (tester) async {
        // 18:40 — snack base = now (16:00 passed); dinner bound 19:00.
        // +20 = 19:00 == bound → enabled; +30 = 19:10 → disabled with reason.
        now = DateTime(2026, 6, 4, 18, 40);
        await open(tester, (c) => snoozeOpener(c));
        expect(find.text('Past Dinner'), findsOneWidget);
        expect(find.text('19:00'), findsOneWidget); // +20 result label, enabled
      },
    );

    testWidgets('last meal: late presets reasoned "Past midnight"', (
      tester,
    ) async {
      // 23:46 — dinner (sm-3) is last → bound is midnight. +10 = 23:56 fits;
      // +15/+20/+30 cross it.
      now = DateTime(2026, 6, 4, 23, 46);
      await open(tester, (c) => snoozeOpener(c, mealId: 'sm-3'));
      expect(find.text('Past midnight'), findsNWidgets(3));
    });

    testWidgets('all presets disabled → empty-state message + disabled CTA', (
      tester,
    ) async {
      // 18:56 — snack base = now; +10 = 19:06 already past dinner 19:00.
      now = DateTime(2026, 6, 4, 18, 56);
      await open(tester, (c) => snoozeOpener(c));
      expect(
        find.text('No room to snooze — your next meal is too soon'),
        findsOneWidget,
      );
      expect(find.text('Past Dinner'), findsNWidgets(4));
      final cta = tester.widget<PrimaryCta>(find.byType(PrimaryCta));
      check(cta.enabled).isFalse();
    });
  });
}

/// Test helper: opens the SnoozeSheet directly (production entry is the
/// MealSheet footer).
void showCrudoSheetForTest(BuildContext context, DateTime date, String mealId) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => SnoozeSheet(date: date, mealId: mealId),
  );
}
