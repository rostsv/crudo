import 'package:checks/checks.dart';
import 'package:crudo/config/di.dart';
import 'package:crudo/data/repositories/in_memory_day_repository.dart';
import 'package:crudo/data/repositories/in_memory_profile_repository.dart';
import 'package:crudo/data/repositories/in_memory_streak_repository.dart';
import 'package:crudo/domain/day/day.dart';
import 'package:crudo/domain/day/scheduled_meal.dart';
import 'package:crudo/domain/meal/food_snapshot.dart';
import 'package:crudo/domain/meal/meal_item.dart';
import 'package:crudo/domain/meal/meal_snapshot.dart';
import 'package:crudo/domain/shared/enums.dart';
import 'package:crudo/domain/shared/grams.dart';
import 'package:crudo/domain/shared/meal_time.dart';
import 'package:crudo/domain/streak/streak.dart';
import 'package:crudo/ui/features/history/view_models/history_providers.dart';
import 'package:crudo/ui/features/today/view_models/today_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  var now = DateTime(2026, 6, 10, 9, 30); // local clock
  final todayLabel = DateTime.utc(2026, 6, 10);
  final yesterday = DateTime.utc(2026, 6, 9);
  final twoDaysAgo = DateTime.utc(2026, 6, 8);

  MealItem checkedItem(double kcal, {required DateTime checkedAt}) {
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

  MealItem uncheckedItem(double kcal) {
    return MealItem(
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

  ScheduledMeal meal({
    required String id,
    required int timeMinutes,
    required List<MealItem> items,
  }) {
    return ScheduledMeal(
      id: id,
      time: MealTime(timeMinutes),
      meal: MealSnapshot(name: 'Test Meal', items: items),
    );
  }

  /// Seed a green locked day with one fully-checked meal (270 kcal).
  Day greenLockedDay(DateTime date) {
    return Day(
      date: date,
      adherence: 1.0,
      thresholdUsed: 80,
      lockedAt: DateTime.utc(date.year, date.month, date.day, 23, 59),
      meals: [
        meal(
          id: 'm-${date.day}',
          timeMinutes: 480,
          items: [
            checkedItem(
              270,
              checkedAt: DateTime.utc(date.year, date.month, date.day, 8, 0),
            ),
          ],
        ),
      ],
    );
  }

  /// Seed a red locked day with one unchecked meal.
  Day redLockedDay(DateTime date) {
    return Day(
      date: date,
      adherence: 0.0,
      thresholdUsed: 80,
      lockedAt: DateTime.utc(date.year, date.month, date.day, 23, 59),
      meals: [
        meal(
          id: 'm-${date.day}',
          timeMinutes: 480,
          items: [uncheckedItem(270)],
        ),
      ],
    );
  }

  /// Seed an open (today) day with one fully-checked meal (270 kcal).
  Day openTodayDay(DateTime date) {
    return Day(
      date: date,
      meals: [
        meal(
          id: 'm-${date.day}',
          timeMinutes: 480,
          items: [
            checkedItem(
              270,
              checkedAt: DateTime.utc(date.year, date.month, date.day, 8, 0),
            ),
          ],
        ),
      ],
    );
  }

  ProviderContainer container({Streak? streak, Map<DateTime, Day>? days}) {
    final streakRepo = InMemoryStreakRepository();
    if (streak != null) {
      streakRepo.save(streak);
    }

    final dayRepo = InMemoryDayRepository();
    if (days != null) {
      for (final d in days.values) {
        dayRepo.save(d);
      }
    }

    final profileRepo = InMemoryProfileRepository();

    final c = ProviderContainer(
      overrides: [
        clockProvider.overrideWithValue(() => now),
        streakRepositoryProvider.overrideWithValue(streakRepo),
        dayRepositoryProvider.overrideWithValue(dayRepo),
        profileRepositoryProvider.overrideWithValue(profileRepo),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  group('weeklyAdherence', () {
    test('returns 7 cells: Mon locked red, Tue locked green, today live green, '
        'future cells null state', () async {
      // Week of Wed 2026-06-10: Mon 6/8, Tue 6/9, Wed 6/10, ..., Sun 6/14
      final monDay = redLockedDay(twoDaysAgo);
      final tueDay = greenLockedDay(yesterday);
      final wedDay = openTodayDay(todayLabel);

      final c = container(
        days: {twoDaysAgo: monDay, yesterday: tueDay, todayLabel: wedDay},
      );

      final week = await c.read(weeklyAdherenceProvider.future);
      check(week).length.equals(7);

      // Monday (index 0): locked, state=red (frozen)
      check(week[0].date).equals(twoDaysAgo);
      check(week[0].state).equals(DayState.red);
      check(week[0].kind).equals(DayCellKind.locked);

      // Tuesday (index 1): locked, state=green (frozen)
      check(week[1].date).equals(yesterday);
      check(week[1].state).equals(DayState.green);
      check(week[1].kind).equals(DayCellKind.locked);

      // Wednesday (index 2): today, live state (adherence=1.0 → green)
      check(week[2].date).equals(todayLabel);
      check(week[2].kind).equals(DayCellKind.today);
      check(week[2].state).equals(DayState.green);

      // Thursday-Sunday (indices 3-6): future, state=null
      for (var i = 3; i < 7; i++) {
        check(week[i].state).isNull();
        check(week[i].kind).equals(DayCellKind.future);
      }
    });
  });

  group('historyStats', () {
    test('returns aggregate stats from seeded days', () async {
      final monDay = redLockedDay(twoDaysAgo);
      final tueDay = greenLockedDay(yesterday);
      final wedDay = openTodayDay(todayLabel);

      final c = container(
        days: {twoDaysAgo: monDay, yesterday: tueDay, todayLabel: wedDay},
      );

      final stats = await c.read(historyStatsProvider.future);

      // adherencePct = mean(0, 1, 1) * 100 = round(66.667) = 67
      check(stats.adherencePct).equals(67);
      // mealsDone: Mon 0 + Tue 1 + Wed 1 = 2
      check(stats.mealsDone).equals(2);
      // avgKcal = mean(0, 270, 270) = 180
      check(stats.avgKcal).equals(180);
      // skipped: Mon 1 (past+unchecked) + Tue 0 + Wed 0 = 1
      check(stats.skipped).equals(1);
    });

    test('empty range returns all zeroes', () async {
      final c = container();
      final stats = await c.read(historyStatsProvider.future);
      check(stats.adherencePct).equals(0);
      check(stats.mealsDone).equals(0);
      check(stats.avgKcal).equals(0);
      check(stats.skipped).equals(0);
    });
  });

  group('recentDays', () {
    test('returns 5 days descending with correct done/total', () async {
      final c = container(
        days: {
          twoDaysAgo: redLockedDay(twoDaysAgo),
          yesterday: greenLockedDay(yesterday),
          todayLabel: openTodayDay(todayLabel),
        },
      );

      final recent = await c.read(recentDaysProvider.future);
      check(recent).length.equals(5);

      // Today first
      check(recent[0].date).equals(todayLabel);
      check(recent[0].done).equals(1);
      check(recent[0].total).equals(1);

      // Yesterday
      check(recent[1].date).equals(yesterday);
      check(recent[1].done).equals(1);
      check(recent[1].total).equals(1);

      // 2 days ago
      check(recent[2].date).equals(twoDaysAgo);
      check(recent[2].done).equals(0);
      check(recent[2].total).equals(1);

      // 3 and 4 days ago: no persisted day → placeholder
      check(recent[3].done).equals(0);
      check(recent[3].total).equals(0);
      check(recent[4].done).equals(0);
      check(recent[4].total).equals(0);
    });
  });

  group('monthGrid', () {
    test('has correct leading-null count and future null-state', () async {
      // June 2026: June 1 is Monday → 0 leading nulls
      // Grid: June 1 to July 5 (5 weeks = 35 cells)
      final month = DateTime.utc(2026, 6, 1);

      final c = container(
        days: {
          todayLabel: openTodayDay(todayLabel),
          yesterday: greenLockedDay(yesterday),
        },
      );

      final grid = await c.read(monthGridProvider(month).future);

      // 5 weeks × 7 = 35
      check(grid).length.equals(35);

      // Leading nulls: firstOfMonth(June 1, Mon) → weekOf offset 0 → 0 leading nulls
      // June 1 is Wednesday? No: 2026-06-01 is Monday → weekday=1 → offset=0
      final firstOfMonth = DateTime.utc(2026, 6, 1);
      final weekOfFirst = <DateTime>[
        firstOfMonth.subtract(Duration(days: firstOfMonth.weekday - 1)),
      ];
      for (var i = 1; i < 7; i++) {
        weekOfFirst.add(weekOfFirst.last.add(const Duration(days: 1)));
      }
      final leadingNullCount = weekOfFirst.indexOf(firstOfMonth);
      // Count non-null leading entries
      var actualLeadingNulls = 0;
      for (final cell in grid) {
        if (cell == null) {
          actualLeadingNulls++;
        } else {
          break;
        }
      }
      check(actualLeadingNulls).equals(leadingNullCount);

      // In-month cells: 30 (June has 30 days)
      final inMonth = grid.where((c) => c != null).length;
      check(inMonth).equals(30);

      // Future day (June 11, index 10): state=null, kind=future
      final futureIdx = 10; // June 11 = 10 days after June 1
      check(grid[futureIdx]!.date).equals(DateTime.utc(2026, 6, 11));
      check(grid[futureIdx]!.state).isNull();
      check(grid[futureIdx]!.kind).equals(DayCellKind.future);

      // Today (June 10, index 9): kind=today, state=green
      check(grid[9]!.date).equals(todayLabel);
      check(grid[9]!.kind).equals(DayCellKind.today);
      check(grid[9]!.state).equals(DayState.green);

      // Trailing cells (July 1-5) are null
      // July 1 = index 30, July 5 = index 34
      for (var i = 30; i < 35; i++) {
        check(grid[i]).isNull();
      }
    });
  });
}
