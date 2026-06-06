import 'package:checks/checks.dart';
import 'package:crudo/config/app_config.dart';
import 'package:crudo/config/di.dart';
import 'package:crudo/data/services/demo_seed.dart';
import 'package:crudo/data/services/id_generator.dart';
import 'package:crudo/data/services/seed_service.dart';
import 'package:crudo/domain/day/day.dart';
import 'package:crudo/domain/food/food.dart';
import 'package:crudo/domain/services/meal_lifecycle.dart';
import 'package:crudo/ui/features/today/view_models/day_controller.dart';
import 'package:crudo/ui/features/today/view_models/today_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/fake_id_generator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  // Demo templates reference seed-food ids — load the real bundled seed
  // once so buildDayFromPlan can resolve them.
  late List<Food> seedFoods;
  setUpAll(() async => seedFoods = await SeedService().loadFoods());

  var now = DateTime(2026, 6, 4, 9, 30); // local Thursday
  final today = DateTime.utc(2026, 6, 4);
  final tomorrow = DateTime.utc(2026, 6, 5);
  final yesterday = DateTime.utc(2026, 6, 3);

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

  test(
    'today: repo miss → materializes from plan and eager-persists once',
    () async {
      final c = container();
      final sub = c.listen(dayControllerProvider(today), (prev, next) {});
      final day = await c.read(dayControllerProvider(today).future);

      check(day.meals.length).equals(4);
      check(day.sourcePlanId).equals('demo-plan-everyday');
      // persisted eagerly:
      final persisted = await c.read(dayRepositoryProvider).getByDate(today);
      check(persisted).isNotNull();
      // ids minted exactly once — invalidate and re-read, ids stable:
      final idsFirst = day.meals.map((m) => m.id).toList();
      c.invalidate(dayControllerProvider(today));
      final again = await c.read(dayControllerProvider(today).future);
      check(again.meals.map((m) => m.id).toList()).deepEquals(idsFirst);
      sub.close();
    },
  );

  test('persisted snapshot wins over the template', () async {
    final c = container();
    final sub = c.listen(dayControllerProvider(today), (prev, next) {});
    await c
        .read(dayRepositoryProvider)
        .save(Day(date: today, planName: 'hand-made'));
    final day = await c.read(dayControllerProvider(today).future);
    check(day.planName).equals('hand-made');
    check(day.meals).isEmpty(); // not re-materialized
    sub.close();
  });

  test('future date: preview built, NOT persisted', () async {
    final c = container();
    final sub = c.listen(dayControllerProvider(tomorrow), (prev, next) {});
    final day = await c.read(dayControllerProvider(tomorrow).future);
    check(day.meals.length).equals(4);
    check(await c.read(dayRepositoryProvider).getByDate(tomorrow)).isNull();
    sub.close();
  });

  test(
    'future preview follows template edits; persisted today does not',
    () async {
      final c = container();
      final subToday = c.listen(dayControllerProvider(today), (prev, next) {});
      final subTomorrow = c.listen(
        dayControllerProvider(tomorrow),
        (prev, next) {},
      );
      await c.read(dayControllerProvider(today).future); // persist today
      // deactivate the plan:
      final plans = c.read(planTemplateRepositoryProvider);
      await plans.save(demoPlanTemplate.copyWith(active: false));
      await Future<void>.delayed(Duration.zero);
      final future = await c.read(dayControllerProvider(tomorrow).future);
      check(future.meals).isEmpty(); // preview re-built — now a rest day
      final todayDay = await c.read(dayControllerProvider(today).future);
      check(todayDay.meals.length).equals(4); // snapshot untouched
      subToday.close();
      subTomorrow.close();
    },
  );

  test('past repo miss → empty locked day', () async {
    final c = container();
    final sub = c.listen(dayControllerProvider(yesterday), (prev, next) {});
    final day = await c.read(dayControllerProvider(yesterday).future);
    check(day.meals).isEmpty();
    check(isDayLocked(day, today)).isTrue();
    check(await c.read(dayRepositoryProvider).getByDate(yesterday)).isNull();
    sub.close();
  });

  test('markAllEaten persists; stream rebuild reflects it', () async {
    final c = container();
    final sub = c.listen(dayControllerProvider(today), (prev, next) {});
    final day = await c.read(dayControllerProvider(today).future);
    final mealId = day.meals.first.id;
    await c.read(dayControllerProvider(today).notifier).markAllEaten(mealId);
    await Future<void>.delayed(Duration.zero);
    final updated = await c.read(dayControllerProvider(today).future);
    check(updated.meals.first.meal.allChecked).isTrue();
    check(consumedKcal(updated)).equals(
      // breakfast only
      updated.meals.first.meal.items.fold<double>(0, (s, i) => s + i.food.kcal),
    );
    sub.close();
  });

  test('ops on a non-today date throw StateError and write nothing', () async {
    final c = container();
    final sub = c.listen(dayControllerProvider(tomorrow), (prev, next) {});
    final day = await c.read(dayControllerProvider(tomorrow).future);
    await check(
      c
          .read(dayControllerProvider(tomorrow).notifier)
          .markAllEaten(day.meals.first.id),
    ).throws<StateError>();
    check(await c.read(dayRepositoryProvider).getByDate(tomorrow)).isNull();
    sub.close();
  });

  test(
    'skip on a checked meal throws (guard surfaces, nothing saved)',
    () async {
      final c = container();
      final sub = c.listen(dayControllerProvider(today), (prev, next) {});
      final day = await c.read(dayControllerProvider(today).future);
      final id = day.meals.first.id;
      final ctrl = c.read(dayControllerProvider(today).notifier);
      await ctrl.checkItem(id, 0);
      await Future<void>.delayed(Duration.zero);
      await check(ctrl.skipMeal(id)).throws<StateError>();
      sub.close();
    },
  );

  test('snooze persists snoozedUntil', () async {
    final c = container();
    final sub = c.listen(dayControllerProvider(today), (prev, next) {});
    final day = await c.read(dayControllerProvider(today).future);
    final id = day.meals.first.id; // 08:00 breakfast; next slot 12:30
    final until = DateTime(2026, 6, 4, 9, 45);
    await c.read(dayControllerProvider(today).notifier).snooze(id, until);
    await Future<void>.delayed(Duration.zero);
    final updated = await c.read(dayControllerProvider(today).future);
    check(updated.meals.first.snoozedUntil).equals(until.toUtc());
    sub.close();
  });

  test('unmarkAll clears checks, persists and re-emits', () async {
    final c = container();
    final sub = c.listen(dayControllerProvider(today), (prev, next) {});
    final day = await c.read(dayControllerProvider(today).future);
    final mealId = day.meals.first.id;
    await c.read(dayControllerProvider(today).notifier).markAllEaten(mealId);
    await Future<void>.delayed(Duration.zero);
    await c.read(dayControllerProvider(today).notifier).unmarkAll(mealId);
    await Future<void>.delayed(Duration.zero);
    final updated = await c.read(dayControllerProvider(today).future);
    final meal = updated.meals.firstWhere((m) => m.id == mealId);
    check(meal.meal.items.every((i) => !i.checked)).isTrue();
    // persisted: repo snapshot agrees
    final persisted = await c.read(dayRepositoryProvider).getByDate(today);
    check(
      persisted!.meals.firstWhere((m) => m.id == mealId).meal.anyChecked,
    ).isFalse();
    sub.close();
  });

  test('unmarkAll guard: nothing checked → StateError, no write', () async {
    final c = container();
    final sub = c.listen(dayControllerProvider(today), (prev, next) {});
    final day = await c.read(dayControllerProvider(today).future);
    final mealId = day.meals.first.id;
    await check(
      c.read(dayControllerProvider(today).notifier).unmarkAll(mealId),
    ).throws<StateError>();
    sub.close();
  });

  test(
    'rollover: refresh() locks yesterday and re-materializes new today',
    () async {
      final c = container();
      final subToday = c.listen(dayControllerProvider(today), (prev, next) {});
      final subTomorrow = c.listen(
        dayControllerProvider(tomorrow),
        (prev, next) {},
      );
      await c.read(dayControllerProvider(today).future); // persist 06-04
      now = DateTime(2026, 6, 5, 7, 0);
      c.read(todayProvider.notifier).refresh();
      await Future<void>.delayed(Duration.zero);
      final newToday = c.read(todayProvider);
      check(newToday).equals(tomorrow);
      final fresh = await c.read(dayControllerProvider(tomorrow).future);
      check(fresh.meals.length).equals(4); // eager-materialized now
      final old = await c.read(dayControllerProvider(today).future);
      check(isDayLocked(old, newToday)).isTrue();
      subToday.close();
      subTomorrow.close();
    },
  );
}
