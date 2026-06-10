import 'package:crudo/config/di.dart';
import 'package:crudo/data/services/id_generator.dart';
import 'package:crudo/domain/day/day.dart';
import 'package:crudo/domain/services/adherence.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'today_providers.dart';

part 'streak_catchup_controller.g.dart';

/// Fires streak catch-up on every Today rollover / app-open. Watches
/// todayProvider so it re-runs when the day label advances. Reads (never
/// watches, to avoid mid-run rebuilds) the streak, prefs threshold, the active
/// plans/templates/foods, and the persisted days in the catch-up range; calls
/// the pure catchUp(); persists each newly-locked day + the new streak.
/// Idempotent — re-running once caught up is a no-op (lastCountedDay guards).
/// Milestones are returned for S13 to celebrate; S12 does not store them.
@riverpod
class StreakCatchUp extends _$StreakCatchUp {
  @override
  Future<List<int>> build() async {
    final today = ref.watch(todayProvider);
    final streakRepo = ref.read(streakRepositoryProvider);
    final dayRepo = ref.read(dayRepositoryProvider);

    final prevStreak = await streakRepo.get();
    final profile = await ref.read(profileRepositoryProvider).watch().first;
    final threshold = profile.prefs.streakThreshold;

    // Fetch persisted days in (lastCountedDay, today) — usually one day. No
    // enumerate on DayRepository, so read per-date one-shot. Bounded by range.
    final persisted = <Day>[];
    final from = prevStreak.lastCountedDay;
    if (from != null) {
      var d = from.add(const Duration(days: 1));
      while (d.isBefore(today)) {
        final row = await dayRepo.watchByDate(d).first;
        if (row != null) persisted.add(row);
        d = d.add(const Duration(days: 1));
      }
    }

    final (plans, templates, library) = await (
      ref.read(planTemplateRepositoryProvider).watchAll().first,
      ref.read(mealTemplateRepositoryProvider).watchAll().first,
      ref.read(foodRepositoryProvider).watchAll().first,
    ).wait;

    final result = catchUp(
      todayLabel: today,
      prevStreak: prevStreak,
      threshold: threshold,
      persistedDays: persisted,
      plans: plans,
      mealTemplates: templates,
      foods: library,
      newId: ref.read(idGeneratorProvider).newId,
    );

    if (result.streak != prevStreak) {
      for (final day in result.lockedDays) {
        await dayRepo.save(day);
      }
      await streakRepo.save(result.streak);
    }
    return result.milestones;
  }
}
