import '../day/day.dart';
import '../food/food.dart';
import '../meal/meal_template.dart';
import '../plan/plan_template.dart';
import '../shared/enums.dart';
import '../streak/streak.dart';
import 'meal_lifecycle.dart';
import 'meal_status.dart';

/// Fixed red floor (percent). Below this a day resets the streak. Not stored,
/// not user-settable (Prefs doc comment); the green line is Prefs.streakThreshold.
const int adherenceRedFloor = 50;

/// Day adherence = consumed ÷ planned kcal, clamped to [0,1]. planned == 0
/// (empty/all-dangling plan) → 0.0 by convention; advanceStreak treats that as
/// a hold, not a failure. Never uses dailyKcalTarget.
double dayAdherence(Day day) {
  final planned = plannedKcal(day);
  if (planned <= 0) return 0.0;
  return (consumedKcal(day) / planned).clamp(0.0, 1.0);
}

/// 3-state verdict for an adherence ratio (0..1) against a threshold (percent,
/// e.g. 80). ratio*100 >= threshold → green; ratio*100 < adherenceRedFloor →
/// red; else yellow. Green line inclusive, red floor exclusive: exactly 50% =
/// yellow, exactly threshold = green.
DayState classifyDayState(double adherence, int threshold) {
  final pct = adherence * 100;
  if (pct >= threshold) return DayState.green;
  if (pct < adherenceRedFloor) return DayState.red;
  return DayState.yellow;
}

/// Freeze an open day: writes the frozen trio via copyWith. Idempotent — a day
/// already locked (lockedAt != null) is returned unchanged. `threshold` is the
/// caller's current prefs value, captured into history so later settings
/// changes never recolor this day.
Day lockDay(Day day, int threshold, DateTime now) {
  if (day.lockedAt != null) return day;
  return day.copyWith(
    adherence: dayAdherence(day),
    thresholdUsed: threshold,
    lockedAt: now.toUtc(),
  );
}

/// State of an ALREADY-LOCKED day, re-derived from its stored adherence +
/// thresholdUsed (history stable across prefs changes). Throws StateError if
/// the day is not locked.
DayState frozenDayState(Day day) {
  final a = day.adherence;
  final t = day.thresholdUsed;
  if (a == null || t == null) {
    throw StateError('frozenDayState requires a locked day');
  }
  return classifyDayState(a, t);
}

/// Result of folding locked days into a streak. milestonesCrossed holds the
/// milestone values newly reached upward during THIS fold, ascending. Ephemeral.
typedef StreakOutcome = ({Streak next, List<int> milestonesCrossed});

/// Streak milestones that emit a one-shot celebration event.
const List<int> streakMilestones = [7, 30, 100];

/// Fold locked days (ascending by date) into the streak. Skips any day whose
/// date label <= prev.lastCountedDay (idempotent re-runs). Per remaining day:
///   green                      → current + 1, bump personalBest
///   yellow / plannedKcal == 0  → hold (current unchanged)
///   red                        → current = 0
/// Every processed day advances lastCountedDay to its date (high-water mark).
/// personalBest is the max ever seen; never decreases. Emits a milestone each
/// time the RUNNING current transitions from below a streakMilestones value to
/// at-or-above it during this fold (reset-then-reclimb past 7 re-emits 7; one
/// fold over many green days can emit several, ascending). Each day must be
/// locked (adherence != null) — throws StateError otherwise.
StreakOutcome advanceStreak(Streak prev, List<Day> lockedDaysAscending) {
  var current = prev.current;
  var best = prev.personalBest;
  var lastCounted = prev.lastCountedDay;
  final crossed = <int>[];

  for (final day in lockedDaysAscending) {
    if (day.adherence == null || day.thresholdUsed == null) {
      throw StateError('advanceStreak requires locked days');
    }
    if (lastCounted != null && !day.date.isAfter(lastCounted)) continue;

    final before = current;
    final planned = plannedKcal(day);
    if (planned <= 0) {
      // hold
    } else {
      switch (frozenDayState(day)) {
        case DayState.green:
          current += 1;
        case DayState.yellow:
          break; // hold
        case DayState.red:
          current = 0;
      }
    }
    for (final m in streakMilestones) {
      if (before < m && current >= m) crossed.add(m);
    }
    if (current > best) best = current;
    lastCounted = day.date;
  }

  return (
    next: Streak(
      current: current,
      personalBest: best,
      lastCountedDay: lastCounted,
    ),
    milestonesCrossed: crossed,
  );
}

/// Result of a catch-up pass.
typedef CatchUpResult = ({
  List<Day> lockedDays, // newly frozen days to persist (ascending)
  Streak streak, // post-fold streak
  List<int> milestones, // crossed this catch-up
});

/// Pure catch-up: lock every elapsed calendar day in (prevStreak.lastCountedDay,
/// todayLabel) — every day up to but excluding today — and fold into the streak.
/// For each date d:
///   persisted-and-locked → use as-is (not re-saved);
///   persisted-but-open   → lockDay(it) (it holds the user's real logging);
///   no persisted row     → buildDayFromPlan(selectPlanForDate(plans,d),…) then lockDay.
/// Back-materialized lockedAt = endOfDayLocal(d).toUtc() (when the day actually
/// closed, not "now"). lockedDays = only the days newly frozen here (open-locked
/// + rebuilt), i.e. what the caller persists. First run (lastCountedDay == null):
/// the repo has no enumerate, so back-materialize NOTHING — return prevStreak
/// with lastCountedDay seeded to (todayLabel - 1 day), no locked days. Empty
/// range → prevStreak unchanged, no days.
CatchUpResult catchUp({
  required DateTime todayLabel,
  required Streak prevStreak,
  required int threshold,
  required List<Day> persistedDays,
  required List<PlanTemplate> plans,
  required List<MealTemplate> mealTemplates,
  required List<Food> foods,
  required String Function() newId,
}) {
  if (prevStreak.lastCountedDay == null) {
    final seeded = todayLabel.subtract(const Duration(days: 1));
    return (
      lockedDays: const <Day>[],
      streak: prevStreak.copyWith(lastCountedDay: seeded),
      milestones: const <int>[],
    );
  }

  final byDate = {for (final d in persistedDays) d.date: d};
  final toFold = <Day>[]; // every elapsed locked day (for the fold)
  final newlyLocked = <Day>[]; // subset the caller must persist

  var d = prevStreak.lastCountedDay!.add(const Duration(days: 1));
  while (d.isBefore(todayLabel)) {
    final existing = byDate[d];
    if (existing != null && existing.lockedAt != null) {
      toFold.add(existing); // already frozen — idempotent
    } else {
      final base =
          existing ??
          buildDayFromPlan(
            selectPlanForDate(plans, d),
            d,
            newId,
            mealTemplates,
            foods,
          );
      final frozen = lockDay(base, threshold, endOfDayLocal(d).toUtc());
      toFold.add(frozen);
      newlyLocked.add(frozen);
    }
    d = d.add(const Duration(days: 1));
  }

  final outcome = advanceStreak(prevStreak, toFold);
  return (
    lockedDays: newlyLocked,
    streak: outcome.next,
    milestones: outcome.milestonesCrossed,
  );
}
