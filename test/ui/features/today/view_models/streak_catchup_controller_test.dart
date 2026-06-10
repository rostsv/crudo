import 'package:checks/checks.dart';
import 'package:crudo/config/di.dart';
import 'package:crudo/data/repositories/in_memory_day_repository.dart';
import 'package:crudo/data/repositories/in_memory_food_repository.dart';
import 'package:crudo/data/repositories/in_memory_meal_template_repository.dart';
import 'package:crudo/data/repositories/in_memory_plan_template_repository.dart';
import 'package:crudo/data/repositories/in_memory_profile_repository.dart';
import 'package:crudo/data/repositories/in_memory_streak_repository.dart';
import 'package:crudo/data/services/id_generator.dart';
import 'package:crudo/domain/day/day.dart';
import 'package:crudo/domain/day/scheduled_meal.dart';
import 'package:crudo/domain/food/food.dart';
import 'package:crudo/domain/food/food_ref.dart';
import 'package:crudo/domain/meal/food_snapshot.dart';
import 'package:crudo/domain/meal/meal_item.dart';
import 'package:crudo/domain/meal/meal_snapshot.dart';
import 'package:crudo/domain/meal/meal_template.dart';
import 'package:crudo/domain/plan/plan_slot.dart';
import 'package:crudo/domain/plan/plan_template.dart';
import 'package:crudo/domain/profile/prefs.dart';
import 'package:crudo/domain/profile/user_profile.dart';
import 'package:crudo/domain/shared/enums.dart';
import 'package:crudo/domain/shared/grams.dart';
import 'package:crudo/domain/shared/meal_time.dart';
import 'package:crudo/domain/streak/streak.dart';
import 'package:crudo/ui/features/today/view_models/streak_catchup_controller.dart';
import 'package:crudo/ui/features/today/view_models/today_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Create [MealItem] with a food snapshot that totals [kcal] (all from protein
/// for simplicity, which is unnecessary — we just need the kcal number).
MealItem _mealItem(double kcal, {DateTime? checkedAt}) {
  return MealItem(
    checkedAt: checkedAt,
    food: FoodSnapshot(
      sourceFoodId: 'f1',
      name: 'Eggs',
      kind: FoodKind.product,
      category: FoodCategory.eggs,
      grams: const Grams(100),
      protein: kcal / 4,
      carbs: 0,
      fats: 0,
      kcal: kcal,
    ),
  );
}

void main() {
  // Clock frozen at 2026-06-10 09:30 local → today label is 2026-06-10.
  var now = DateTime(2026, 6, 10, 9, 30);
  final todayLabel = DateTime.utc(2026, 6, 10);
  final yesterday = DateTime.utc(2026, 6, 9);
  final twoDaysAgo = DateTime.utc(2026, 6, 8);

  // Shared seed data for back-materialization (covers Tue 2026-06-09).
  const food = Food(
    id: 'f1',
    name: 'Eggs',
    kind: FoodKind.product,
    category: FoodCategory.eggs,
    protein: 25,
    carbs: 2,
    fats: 18,
    kcalPer100g: 270,
  );
  final foodRef = FoodRef(foodId: 'f1', grams: const Grams(100));
  final mealTemplate = MealTemplate(
    id: 'mt1',
    name: 'Omelette',
    foods: [foodRef],
  );
  final planSlot = PlanSlot(
    id: 'ps1',
    mealTemplateId: 'mt1',
    time: const MealTime(480), // 8:00
  );
  final planTemplate = PlanTemplate(
    id: 'p1',
    name: 'Test Plan',
    days: [1], // Tuesday
    slots: [planSlot],
  );

  ProviderContainer container({
    Streak? streak,
    Map<DateTime, Day>? days,
    UserProfile? profile,
    List<PlanTemplate>? plans,
    List<MealTemplate>? templates,
    List<Food>? foods,
  }) {
    final streakRepo = InMemoryStreakRepository();
    if (streak != null) {
      streakRepo.save(streak); // sync in memory; ignore returned Future.
    }

    final dayRepo = InMemoryDayRepository();
    if (days != null) {
      for (final d in days.values) {
        dayRepo.save(d);
      }
    }

    final profileRepo = InMemoryProfileRepository();
    if (profile != null) {
      profileRepo.save(profile);
    }

    final planRepo = InMemoryPlanTemplateRepository();
    if (plans != null) {
      for (final p in plans) {
        planRepo.save(p);
      }
    }

    final mealRepo = InMemoryMealTemplateRepository();
    if (templates != null) {
      for (final t in templates) {
        mealRepo.save(t);
      }
    }

    final foodRepo = InMemoryFoodRepository();
    if (foods != null) {
      for (final f in foods) {
        foodRepo.save(f);
      }
    }

    final c = ProviderContainer(
      overrides: [
        clockProvider.overrideWithValue(() => now),
        streakRepositoryProvider.overrideWithValue(streakRepo),
        dayRepositoryProvider.overrideWithValue(dayRepo),
        profileRepositoryProvider.overrideWithValue(profileRepo),
        planTemplateRepositoryProvider.overrideWithValue(planRepo),
        mealTemplateRepositoryProvider.overrideWithValue(mealRepo),
        foodRepositoryProvider.overrideWithValue(foodRepo),
        idGeneratorProvider.overrideWithValue(const IdGenerator()),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  group('StreakCatchUp', () {
    test(
      'first run (null lastCountedDay) seeds lastCountedDay, no locked days',
      () async {
        final c = container(
          plans: [planTemplate],
          templates: [mealTemplate],
          foods: [food],
        );

        final milestones = await c.read(streakCatchUpProvider.future);
        check(milestones).isEmpty();

        final streak = await c.read(streakRepositoryProvider).get();
        check(
          streak.lastCountedDay,
        ).equals(todayLabel.subtract(const Duration(days: 1)));
        check(streak.current).equals(0);
        check(streak.personalBest).equals(0);
      },
    );

    test(
      'one unopened gap day back-materializes and resets streak (red: 0 consumed)',
      () async {
        final c = container(
          streak: Streak(lastCountedDay: DateTime.utc(2026, 6, 8)),
          plans: [planTemplate],
          templates: [mealTemplate],
          foods: [food],
        );

        final milestones = await c.read(streakCatchUpProvider.future);
        check(milestones).isEmpty();

        // One day should have been locked and persisted.
        final persisted = await c
            .read(dayRepositoryProvider)
            .getByDate(yesterday);
        check(persisted).isNotNull();
        check(persisted!.lockedAt).isNotNull();
        check(persisted.adherence).equals(0.0);

        final streak = await c.read(streakRepositoryProvider).get();
        check(streak.current).equals(0);
        check(streak.lastCountedDay).equals(yesterday);
      },
    );

    test(
      'persisted open fully-consumed day gets locked and streak advances',
      () async {
        // Build a persisted day for yesterday with all items checked.
        final item = _mealItem(270, checkedAt: DateTime.utc(2026, 6, 9, 8, 30));
        final mealSnap = MealSnapshot(name: 'Omelette', items: [item]);
        final scheduled = ScheduledMeal(
          id: 'm1',
          time: const MealTime(480),
          meal: mealSnap,
        );
        final openDay = Day(
          date: yesterday,
          sourcePlanId: 'p1',
          planName: 'Test Plan',
          meals: [scheduled],
          // adherence / thresholdUsed / lockedAt are null → open
        );

        final c = container(
          streak: Streak(lastCountedDay: twoDaysAgo),
          days: {yesterday: openDay},
          plans: [planTemplate],
          templates: [mealTemplate],
          foods: [food],
        );

        final milestones = await c.read(streakCatchUpProvider.future);
        check(milestones).isEmpty();

        // The day should now be locked.
        final persisted = await c
            .read(dayRepositoryProvider)
            .getByDate(yesterday);
        check(persisted).isNotNull();
        check(persisted!.lockedAt).isNotNull();
        // Same meal count → not rebuilt.
        check(persisted.meals.length).equals(1);
        check(persisted.meals.first.id).equals('m1');

        // Streak advanced.
        final streak = await c.read(streakRepositoryProvider).get();
        check(streak.current).equals(1);
        check(streak.lastCountedDay).equals(yesterday);
      },
    );

    test('already-locked day is folded but not re-saved', () async {
      // Persist an already-locked day.
      final item = _mealItem(270, checkedAt: DateTime.utc(2026, 6, 9, 8, 30));
      final mealSnap = MealSnapshot(name: 'Omelette', items: [item]);
      final scheduled = ScheduledMeal(
        id: 'm1',
        time: const MealTime(480),
        meal: mealSnap,
      );
      final lockedDay = Day(
        date: yesterday,
        sourcePlanId: 'p1',
        planName: 'Test Plan',
        meals: [scheduled],
        adherence: 1.0,
        thresholdUsed: 80,
        lockedAt: DateTime.utc(2026, 6, 9, 23, 59),
      );

      final c = container(
        streak: Streak(lastCountedDay: twoDaysAgo),
        days: {yesterday: lockedDay},
        plans: [planTemplate],
        templates: [mealTemplate],
        foods: [food],
      );

      final milestones = await c.read(streakCatchUpProvider.future);
      check(milestones).isEmpty();

      // The persisted day should still be the same original (lockedAt unchanged).
      final persisted = await c
          .read(dayRepositoryProvider)
          .getByDate(yesterday);
      check(persisted).isNotNull();
      check(persisted!.lockedAt).equals(DateTime.utc(2026, 6, 9, 23, 59));

      // Streak reflects the green day.
      final streak = await c.read(streakRepositoryProvider).get();
      check(streak.current).equals(1);
      check(streak.lastCountedDay).equals(yesterday);
    });

    test('idempotent — re-running with same today yields no change', () async {
      final c = container(
        streak: Streak(lastCountedDay: twoDaysAgo),
        plans: [planTemplate],
        templates: [mealTemplate],
        foods: [food],
      );

      // First run.
      await c.read(streakCatchUpProvider.future);
      final streak1 = await c.read(streakRepositoryProvider).get();
      check(streak1.current).equals(0);
      check(streak1.lastCountedDay).equals(yesterday);

      // Invalidate and re-read (same today).
      c.invalidate(streakCatchUpProvider);
      await c.read(streakCatchUpProvider.future);

      // Streak unchanged — no double count.
      final streak2 = await c.read(streakRepositoryProvider).get();
      check(streak2.current).equals(0);
      check(streak2.lastCountedDay).equals(yesterday);
    });

    test('crossing a milestone surfaces it in the returned list', () async {
      // current 6, one green day yesterday → crosses to 7.
      final item = _mealItem(270, checkedAt: DateTime.utc(2026, 6, 9, 8, 30));
      final openDay = Day(
        date: yesterday,
        sourcePlanId: 'p1',
        planName: 'Test Plan',
        meals: [
          ScheduledMeal(
            id: 'm1',
            time: const MealTime(480),
            meal: MealSnapshot(name: 'Omelette', items: [item]),
          ),
        ],
      );

      final c = container(
        streak: Streak(current: 6, personalBest: 6, lastCountedDay: twoDaysAgo),
        days: {yesterday: openDay},
        plans: [planTemplate],
        templates: [mealTemplate],
        foods: [food],
      );

      final milestones = await c.read(streakCatchUpProvider.future);
      check(milestones).deepEquals([7]);

      final streak = await c.read(streakRepositoryProvider).get();
      check(streak.current).equals(7);
    });

    test(
      'threshold comes from prefs — 0.85 day holds at threshold 90',
      () async {
        // 850/1000 = 0.85 → GREEN at default 80 (would advance), but YELLOW at
        // 90 (holds). Proves the controller reads Prefs.streakThreshold AND that
        // it is frozen onto the locked day.
        final checked = _mealItem(
          850,
          checkedAt: DateTime.utc(2026, 6, 9, 8, 30),
        );
        final unchecked = _mealItem(
          150,
        ); // not eaten → planned 1000, consumed 850
        final openDay = Day(
          date: yesterday,
          sourcePlanId: 'p1',
          planName: 'Test Plan',
          meals: [
            ScheduledMeal(
              id: 'm1',
              time: const MealTime(480),
              meal: MealSnapshot(name: 'Omelette', items: [checked, unchecked]),
            ),
          ],
        );

        final c = container(
          streak: Streak(
            current: 3,
            personalBest: 3,
            lastCountedDay: twoDaysAgo,
          ),
          days: {yesterday: openDay},
          profile: const UserProfile(
            id: 'u1',
            prefs: Prefs(streakThreshold: 90),
          ),
          plans: [planTemplate],
          templates: [mealTemplate],
          foods: [food],
        );

        await c.read(streakCatchUpProvider.future);

        final persisted = await c
            .read(dayRepositoryProvider)
            .getByDate(yesterday);
        check(persisted!.thresholdUsed).equals(90); // frozen from prefs
        check(persisted.adherence!).equals(0.85);

        // Yellow at 90 → streak holds (would be 4 at threshold 80).
        final streak = await c.read(streakRepositoryProvider).get();
        check(streak.current).equals(3);
        check(streak.lastCountedDay).equals(yesterday);
      },
    );

    test(
      'multi-day range locks every elapsed day (loop > 1 iteration)',
      () async {
        // lastCountedDay 6/6 → range {6/7, 6/8, 6/9}; all persisted open green.
        Day greenDayOn(DateTime date) => Day(
          date: date,
          sourcePlanId: 'p1',
          planName: 'Test Plan',
          meals: [
            ScheduledMeal(
              id: 'm-${date.day}',
              time: const MealTime(480),
              meal: MealSnapshot(
                name: 'Omelette',
                items: [
                  _mealItem(
                    270,
                    checkedAt: DateTime.utc(date.year, date.month, date.day, 8),
                  ),
                ],
              ),
            ),
          ],
        );

        final d7 = DateTime.utc(2026, 6, 7);
        final d8 = DateTime.utc(2026, 6, 8);
        final c = container(
          streak: Streak(lastCountedDay: DateTime.utc(2026, 6, 6)),
          days: {
            d7: greenDayOn(d7),
            d8: greenDayOn(d8),
            yesterday: greenDayOn(yesterday),
          },
          plans: [planTemplate],
          templates: [mealTemplate],
          foods: [food],
        );

        await c.read(streakCatchUpProvider.future);

        // Every elapsed day locked + persisted.
        for (final date in [d7, d8, yesterday]) {
          final p = await c.read(dayRepositoryProvider).getByDate(date);
          check(p!.lockedAt).isNotNull();
        }
        final streak = await c.read(streakRepositoryProvider).get();
        check(streak.current).equals(3); // three green days
        check(streak.lastCountedDay).equals(yesterday);
      },
    );
  });
}
