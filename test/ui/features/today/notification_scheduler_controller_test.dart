import 'package:checks/checks.dart';
import 'package:crudo/config/app_config.dart';
import 'package:crudo/config/di.dart';
import 'package:crudo/data/services/id_generator.dart';
import 'package:crudo/data/services/seed_service.dart';
import 'package:crudo/domain/food/food.dart';
import 'package:crudo/domain/repositories/notification_service.dart';
import 'package:crudo/domain/services/notification_spec.dart';
import 'package:crudo/ui/features/today/view_models/day_controller.dart';
import 'package:crudo/ui/features/today/view_models/notification_scheduler_controller.dart';
import 'package:crudo/ui/features/today/view_models/today_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fake_notification_service.dart';
import '../../../helpers/fake_id_generator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late List<Food> seedFoods;
  setUpAll(() async => seedFoods = await SeedService().loadFoods());

  // Clock frozen at 2026-06-10 07:00 local → today label = 2026-06-10.
  final now = DateTime(2026, 6, 10, 7, 0);
  final todayLabel = DateTime.utc(2026, 6, 10);

  ProviderContainer container({required FakeNotificationService fakeService}) {
    final c = ProviderContainer(
      overrides: [
        appConfigProvider.overrideWithValue(AppConfig(flavor: Flavor.dev)),
        seedFoodsProvider.overrideWithValue(seedFoods),
        clockProvider.overrideWithValue(() => now),
        notificationServiceProvider.overrideWithValue(fakeService),
        idGeneratorProvider.overrideWithValue(FakeIdGenerator()),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  group('NotificationScheduler', () {
    test('schedules non-empty specs when meals are upcoming', () async {
      final fake = FakeNotificationService();
      final c = container(fakeService: fake);

      // Keep the day controller alive with a listener (avoids auto-dispose
      // of persistedDayProvider during the StreamProvider loading window).
      final sub = c.listen(dayControllerProvider(todayLabel), (_, _) {});
      await c.read(dayControllerProvider(todayLabel).future);
      await c.read(notificationSchedulerProvider.future);
      sub.close();

      check(fake.scheduled).isNotEmpty();
      check(fake.scheduled.first).isNotEmpty();
    });

    test('mutedRiskDayProvider strips risk specs', () async {
      final fake = FakeNotificationService();
      final c = container(fakeService: fake);

      // Keep the day controller alive with a listener.
      final sub = c.listen(dayControllerProvider(todayLabel), (_, _) {});
      await c.read(dayControllerProvider(todayLabel).future);

      // First build — risk should be present.
      await c.read(notificationSchedulerProvider.future);
      check(
        fake.scheduled.last.any((s) => s.kind == NotificationKind.risk),
      ).isTrue();

      // Mute today.
      c.read(mutedRiskDayProvider.notifier).set(todayLabel);
      await c.read(notificationSchedulerProvider.future);

      final specs = fake.scheduled.last;
      check(specs.any((s) => s.kind == NotificationKind.risk)).isFalse();
      sub.close();
    });

    test('reschedules on a prefs change (no day mutation) — Task 7', () async {
      final fake = FakeNotificationService();
      final c = container(fakeService: fake);

      final sub = c.listen(dayControllerProvider(todayLabel), (_, _) {});
      await c.read(dayControllerProvider(todayLabel).future);
      // Keep the scheduler alive so a prefs emission re-runs its build.
      final schedSub = c.listen(notificationSchedulerProvider, (_, _) {});
      await c.read(notificationSchedulerProvider.future);
      check(fake.scheduled.last).isNotEmpty();

      // Turn every notification off — pure prefs edit, no day change. The
      // scheduler watches profileProvider, so it must re-arm to an empty set.
      final repo = c.read(profileRepositoryProvider);
      final p = await repo.get();
      await repo.save(
        p.copyWith(
          prefs: p.prefs.copyWith(
            preOn: false,
            atOn: false,
            eodOn: false,
            riskOn: false,
          ),
        ),
      );
      // Let the profileProvider stream emission propagate to the scheduler's
      // watch before reading its re-armed result.
      await Future<void>.delayed(const Duration(milliseconds: 20));
      await c.read(notificationSchedulerProvider.future);

      check(fake.scheduled.last).isEmpty();
      schedSub.close();
      sub.close();
    });
  });

  group('NotificationActionRouter', () {
    test('ateIt action marks all items checked', () async {
      final fake = FakeNotificationService();
      final c = container(fakeService: fake);

      // Keep the day controller alive with a listener.
      final sub = c.listen(dayControllerProvider(todayLabel), (_, _) {});
      await c.read(dayControllerProvider(todayLabel).future);
      final day = await c.read(dayControllerProvider(todayLabel).future);
      // Use the first meal's actual id from the built day.
      final mealId = day.meals.first.id;
      check(day.meals.first.meal.anyChecked).isFalse();

      // Build the action router.
      await c.read(notificationActionRouterProvider.future);

      // Emit an ateIt action.
      fake.emitAction((mealId: mealId, kind: NotificationActionKind.ateIt));
      await Future<void>.delayed(Duration.zero);

      // Verify the meal's items are now checked.
      c.invalidate(dayControllerProvider(todayLabel));
      final updated = await c.read(dayControllerProvider(todayLabel).future);
      final updatedMeal = updated.meals.firstWhere((m) => m.id == mealId);
      check(updatedMeal.meal.allChecked).isTrue();
      sub.close();
    });

    test('stale action is swallowed (no throw, no state change)', () async {
      final fake = FakeNotificationService();
      final c = container(fakeService: fake);

      final sub = c.listen(dayControllerProvider(todayLabel), (_, _) {});
      final day = await c.read(dayControllerProvider(todayLabel).future);
      final mealId = day.meals.first.id;

      // Make the meal done so a later skip is ineligible (Day.skipMeal throws
      // StateError 'cannot skip: items are checked').
      await c
          .read(dayControllerProvider(todayLabel).notifier)
          .markAllEaten(mealId);

      await c.read(notificationActionRouterProvider.future);

      // A stale skip must be a no-op, not a crash.
      fake.emitAction((mealId: mealId, kind: NotificationActionKind.skip));
      await Future<void>.delayed(Duration.zero);

      // Router is still healthy and the meal stays done.
      check(
        c.read(notificationActionRouterProvider),
      ).has((v) => v.hasError, 'hasError').isFalse();
      c.invalidate(dayControllerProvider(todayLabel));
      final updated = await c.read(dayControllerProvider(todayLabel).future);
      final updatedMeal = updated.meals.firstWhere((m) => m.id == mealId);
      check(updatedMeal.meal.allChecked).isTrue();
      check(updatedMeal.skippedAt).isNull();
      sub.close();
    });

    test('preset launch action is routed once on build', () async {
      final fake = FakeNotificationService();
      final c = container(fakeService: fake);

      // Keep the day controller alive with a listener.
      final sub = c.listen(dayControllerProvider(todayLabel), (_, _) {});
      await c.read(dayControllerProvider(todayLabel).future);
      final day = await c.read(dayControllerProvider(todayLabel).future);
      // Use the first meal's actual id from the built day.
      final mealId = day.meals.first.id;
      fake.launchAction = (mealId: mealId, kind: NotificationActionKind.ateIt);

      // Build the router — should consume and route the launch action.
      await c.read(notificationActionRouterProvider.future);
      await Future<void>.delayed(Duration.zero);

      // Verify the meal's items are now checked.
      c.invalidate(dayControllerProvider(todayLabel));
      final updated = await c.read(dayControllerProvider(todayLabel).future);
      final updatedMeal = updated.meals.firstWhere((m) => m.id == mealId);
      check(updatedMeal.meal.allChecked).isTrue();

      // Launch action consumed.
      final consumed = await fake.consumeLaunchAction();
      check(consumed).isNull();
      sub.close();
    });
  });
}
