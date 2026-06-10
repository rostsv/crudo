# Plan — S12: Adherence + streak engine

**Worker note:** Implements `docs/specs/2026-06-10-s12-adherence-streak-engine.md`. Pure-logic story (no UI — that's S13). Read `.agents/skills/flutter-expert`, `.agents/skills/dart-add-unit-test`, and `.agents/skills/dart-migrate-to-checks-package` before starting. Domain stays PURE — `lib/domain/services/adherence.dart` must import no Flutter/Riverpod/JSON. Tests use `package:checks` (not `matcher`). Every `flutter test` runs with `--timeout=90s`. No `git commit` in any task — end at "report for review".

**Goal:** Turn logged days into a real streak: per-day adherence (consumed÷planned kcal) + 3-state classification, the midnight-lock freeze of each `Day`'s `adherence`/`thresholdUsed`/`lockedAt` trio, the +1/hold/reset streak transition with personal-best + one-shot milestone events, a pure catch-up orchestrator that locks every elapsed day (unopened = red = reset), and one thin Riverpod hook that fires catch-up on rollover/open and persists.

**Decisions (settled in brainstorm — do not re-litigate):**

| Fork | Decision |
|---|---|
| Lock trigger | Lock-on-rollover/open via pure `catchUp` + a thin today-side hook; no scheduler (S14 owns notifications). |
| Counted days | Only locked past days advance the streak; today is live-preview only. |
| Gap days | Back-materialize + lock every elapsed day; unopened = 0 consumed = red = reset. No date-arithmetic gap path. |
| Milestones | `advanceStreak` returns crossed events (`{7,30,100}`); ephemeral, never stored. |
| Adherence denom | `consumed ÷ planned` kcal, clamped [0,1]. Never `dailyKcalTarget`. |
| Threshold | Frozen per day in `thresholdUsed`; red floor fixed `const = 50`. History never recolors. |
| `lastCountedDay` | High-water mark of processed days — advances on green/yellow/red. Idempotency + range lower bound. |
| `plannedKcal == 0` | Hold (no plan ⇒ can't fail); never reset. Stores `adherence = 0.0`. |
| First-run (`lastCountedDay == null`) | No back-materialize (repo has no enumerate); seed `lastCountedDay = today − 1`, `current` unchanged. |

**File changes (whole plan):**
- Create: `lib/domain/services/adherence.dart` — all pure functions (Tasks 1–3).
- Create: `test/domain/services/adherence_test.dart` — domain tests (Tasks 1–3).
- Create: `lib/ui/features/today/view_models/streak_catchup_controller.dart` + `.g.dart` — the wiring hook (Task 4).
- Modify: `lib/ui/features/today/view_models/today_providers.dart` — `streakCountProvider` doc comment only (Task 4).
- Create: `test/ui/features/today/view_models/streak_catchup_controller_test.dart` (Task 4).

**Existing API the tasks consume (verbatim — already in the tree):**
```dart
// lib/domain/services/meal_lifecycle.dart
double plannedKcal(Day day);
double consumedKcal(Day day);
Day buildDayFromPlan(PlanTemplate? plan, DateTime date, String Function() newId,
    List<MealTemplate> mealTemplates, List<Food> foods);
DateTime endOfDayLocal(DateTime dayDate);   // re-exported from meal_status.dart
DateTime localDateLabel(DateTime now);       // from meal_status.dart
// lib/domain/services/plan_scheduling.dart
PlanTemplate? selectPlanForDate(List<PlanTemplate> plans, DateTime date);
// lib/domain/streak/streak.dart
Streak({int current = 0, int personalBest = 0, DateTime? lastCountedDay});
// lib/domain/day/day.dart — frozen trio fields: double? adherence, int? thresholdUsed, DateTime? lockedAt
// lib/domain/shared/enums.dart — enum DayState { green, yellow, red }
```

---

## Task 1: Per-day adherence, classification, and lock freeze

**Role:** implement

**Goal:** The per-day section of `adherence.dart` — adherence ratio, 3-state classification, the idempotent `lockDay` freeze, and `frozenDayState` re-derivation that stays stable across prefs changes.

**Files:**
- Create: `lib/domain/services/adherence.dart`
- Test: `test/domain/services/adherence_test.dart`

**Contract:**

```dart
// lib/domain/services/adherence.dart
import '../day/day.dart';
import '../shared/enums.dart';
import 'meal_lifecycle.dart';

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
```

**Steps (TDD):**

- [ ] 1. **Failing test** — create `test/domain/services/adherence_test.dart`. Build small `Day`s via existing test helpers / direct `Day(date:…, meals:[…])` with `ScheduledMeal`/`MealSnapshot`/`MealItem`+`FoodSnapshot` carrying known kcal (mirror `test/domain/services/meal_lifecycle_test.dart` setup). Assert with `package:checks`:
  - `dayAdherence`: consumed 800 of planned 1000 → `.equals(0.8)`; over-eaten (consumed > planned) → clamps to `1.0`; planned 0 (empty `Day(date:…)`) → `0.0`; nothing checked → `0.0`.
  - `classifyDayState`: `(0.80, 80)` green; `(0.79, 80)` yellow; `(0.50, 80)` yellow; `(0.49, 80)` red; `(1.0, 100)` green; `(0.99, 100)` yellow.
  - `lockDay`: on an open day sets all three trio fields together; `lockedAt` `.isUtc` true; `thresholdUsed` equals the passed value; calling `lockDay` again returns an identical instance (idempotent — assert `lockedAt` unchanged).
  - `frozenDayState`: lock a 0.80 day at threshold 80 → green; re-classify the SAME locked day reading its stored trio still green even though you then call with a different live threshold (prove via `frozenDayState`, which only reads stored fields); `frozenDayState` on an open day `.throws<StateError>()`.
- [ ] 2. **Run — red:** `flutter test --timeout=90s test/domain/services/adherence_test.dart`. Expected: FAIL — `Error: Couldn't resolve the package 'crudo/domain/services/adherence.dart'` / undefined `dayAdherence`.
- [ ] 3. **Implement** `lib/domain/services/adherence.dart` exactly as the Contract above (per-day section only). No `build_runner` needed (no `@freezed`/`@riverpod` in this file).
- [ ] 4. **Run — green:** `flutter test --timeout=90s test/domain/services/adherence_test.dart`.
- [ ] 5. Gates: `dart format .` · `flutter analyze` · `flutter test --timeout=90s`. Report for review.

**Skills:** `.agents/skills/flutter-expert`, `.agents/skills/dart-add-unit-test`, `.agents/skills/dart-migrate-to-checks-package`.

**Out of scope:** the cross-day fold (`advanceStreak`) and `catchUp` (Tasks 2–3); any Riverpod/UI; any change to `Day`/`Streak`/`DayState`/`Prefs` or any repo.

---

## Task 2: Cross-day streak fold + milestone events

**Role:** implement

**Goal:** Add the cross-day section to `adherence.dart`: `advanceStreak` folding locked days into a `Streak` with +1/hold/reset, personal-best tracking, idempotent skipping, and one-shot milestone events.

**Files:**
- Modify: `lib/domain/services/adherence.dart` — add the cross-day section + new import.
- Test: `test/domain/services/adherence_test.dart` — add a `group('advanceStreak')`.

**Contract:** (append to `adherence.dart`; add `import '../streak/streak.dart';`)

```dart
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
```

**Steps (TDD):**

- [ ] 1. **Failing test** — add `group('advanceStreak')` to `adherence_test.dart`. Helper: `Day locked(DateTime date, double adherence, {int threshold = 80, double planned = 1000})` building a `Day` whose meals sum to `planned` planned kcal and `adherence*planned` consumed kcal, then `lockDay(_, threshold, someUtc)` — OR construct the `Day` directly with the trio set + meals sized so `plannedKcal` matches (the fold reads `plannedKcal(day)` live, so meals must back the planned value). Assert with `checks`:
  - three consecutive green days from `Streak()` → `current` 3, `personalBest` 3, `lastCountedDay` = 3rd date.
  - a yellow day holds: green,green,yellow → `current` 2 (unchanged by yellow), `lastCountedDay` advances to the yellow date.
  - a red day resets: green×3 then red → `current` 0, `personalBest` 3.
  - `plannedKcal == 0` day (empty `Day` with the trio set) holds, does not reset: green then planned-0 → `current` 1.
  - idempotent: fold a list, then re-fold a list whose dates are all `<= next.lastCountedDay` → `current`/`best` unchanged, no milestones.
  - `throws<StateError>()` when a list contains an unlocked day (`adherence == null`).
  - milestones: a fold that takes current 6→7 emits `[7]`; staying 7→8 emits `[]`; a single fold of enough green days to jump 0→30 emits `[7, 30]` in order; reset to 0 then climb back past 7 re-emits `[7]`.
- [ ] 2. **Run — red:** `flutter test --timeout=90s test/domain/services/adherence_test.dart`. Expected: FAIL — undefined `advanceStreak` / `StreakOutcome`.
- [ ] 3. **Implement** the cross-day section per Contract (append to `adherence.dart`, add the `streak.dart` import). No codegen.
- [ ] 4. **Run — green:** `flutter test --timeout=90s test/domain/services/adherence_test.dart`.
- [ ] 5. Gates: `dart format .` · `flutter analyze` · `flutter test --timeout=90s`. Report for review.

**Skills:** `.agents/skills/flutter-expert`, `.agents/skills/dart-add-unit-test`, `.agents/skills/dart-migrate-to-checks-package`, `.agents/skills/dart-use-pattern-matching`.

**Out of scope:** `catchUp` (Task 3); Riverpod/UI; model/repo changes.

---

## Task 3: Pure catch-up orchestrator

**Role:** implement

**Goal:** Add `catchUp` to `adherence.dart`: lock every elapsed calendar day (prefer a persisted open day's real logging, else back-materialize from the plan), fold them, and return the days to persist + new streak + milestones. Handles the first-run (null `lastCountedDay`) and empty-range cases.

**Files:**
- Modify: `lib/domain/services/adherence.dart` — add `catchUp` + `CatchUpResult` + imports.
- Test: `test/domain/services/adherence_test.dart` — add a `group('catchUp')`.

**Contract:** (append; add `import '../food/food.dart';`, `import '../meal/meal_template.dart';`, `import '../plan/plan_template.dart';`, `import 'plan_scheduling.dart';`)

```dart
/// Result of a catch-up pass.
typedef CatchUpResult = ({
  List<Day> lockedDays, // newly frozen days to persist (ascending)
  Streak streak,        // post-fold streak
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
  required DateTime todayLabel, // localDateLabel(now)
  required Streak prevStreak,
  required int threshold,
  required List<Day> persistedDays, // any stored days the caller could fetch in range
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
```

> **Note for worker:** `d` is a UTC day-label (`DateTime.utc(y,m,d)`); `add(Duration(days:1))` on a UTC instant is DST-safe (no local offset). `todayLabel` and `lastCountedDay` are both day-labels, so the `isBefore`/`isAfter` comparisons are exact.

**Steps (TDD):**

- [ ] 1. **Failing test** — add `group('catchUp')`. Use a fixed `today = DateTime.utc(2026, 6, 10)` and label helpers `DateTime.utc(2026, 6, d)`. Provide a minimal `plans`/`mealTemplates`/`foods` set such that `buildDayFromPlan` yields a day with known planned kcal and zero consumed (unopened ⇒ red). `newId` = an incrementing counter closure. Assert with `checks`:
  - empty range (`lastCountedDay = today - 1 day`, no persisted) → `lockedDays` empty, `streak` equals `prevStreak`, `milestones` empty.
  - first run (`lastCountedDay == null`) → `lockedDays` empty, `streak.lastCountedDay` equals `today - 1 day`, `streak.current` equals `prevStreak.current`.
  - one unopened gap day (`lastCountedDay = today - 2 days`, no persisted row for `today - 1`) → `lockedDays` has 1 day, that day `lockedAt == endOfDayLocal(today-1).toUtc()`, its `adherence == 0.0`, and `streak.current == 0` (red reset).
  - persisted OPEN day with full consumption for `today - 1` → catch-up locks IT (not a rebuild): `lockedDays` single day whose `adherence` reflects the logged consumption (e.g. 1.0), `streak.current` incremented; assert the locked day's meals are the persisted ones (same meal count/ids), proving no rebuild.
  - persisted ALREADY-LOCKED day in range → NOT in `lockedDays` (not re-saved) but still folded (streak reflects it).
  - multi-day range with a red in the middle → streak resets then climbs; `lockedDays` count == number newly frozen.
- [ ] 2. **Run — red:** `flutter test --timeout=90s test/domain/services/adherence_test.dart`. Expected: FAIL — undefined `catchUp` / `CatchUpResult`.
- [ ] 3. **Implement** `catchUp` + `CatchUpResult` per Contract (append, add the four imports). No codegen.
- [ ] 4. **Run — green:** `flutter test --timeout=90s test/domain/services/adherence_test.dart`.
- [ ] 5. Gates: `dart format .` · `flutter analyze` · `flutter test --timeout=90s`. Report for review.

**Skills:** `.agents/skills/flutter-expert`, `.agents/skills/dart-add-unit-test`, `.agents/skills/dart-migrate-to-checks-package`.

**Out of scope:** Riverpod wiring (Task 4); model/repo changes; any UI.

---

## Task 4: Catch-up wiring — controller hook + persistence

**Role:** implement

**Goal:** A thin Riverpod controller that runs `catchUp` when `Today` advances / app opens, persists each newly-locked day + the new streak, and is idempotent. Refresh the `streakCountProvider` doc comment now that S12 is live. This is the only non-pure code in S12.

**Files:**
- Create: `lib/ui/features/today/view_models/streak_catchup_controller.dart`
- Modify: `lib/ui/features/today/view_models/today_providers.dart` — `streakCountProvider` doc comment only (no contract change).
- Test: `test/ui/features/today/view_models/streak_catchup_controller_test.dart`

**Contract:**

```dart
// lib/ui/features/today/view_models/streak_catchup_controller.dart
import 'package:crudo/config/di.dart';
import 'package:crudo/domain/day/day.dart';
import 'package:crudo/domain/services/adherence.dart';
import 'package:crudo/domain/services/meal_status.dart' show localDateLabel;
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
```

**Steps (TDD):**

- [ ] 1. **Failing test** — create `test/ui/features/today/view_models/streak_catchup_controller_test.dart`. Build a `ProviderContainer` overriding `clockProvider` for deterministic time (mirror `test/ui/features/today/view_models/today_providers_test.dart`), seeding the in-memory repos via DI overrides. Use `package:checks`. Assert:
  - With a streak `lastCountedDay = today - 2 days` and no persisted row for `today - 1`: awaiting `streakCatchUpProvider.future` persists one locked day (`dayRepo.watchByDate(today-1).first` non-null, `lockedAt != null`) and `streakRepo.get()` reflects the reset (`current == 0`).
  - A persisted OPEN, fully-consumed `today - 1` day → after catch-up `streakRepo.get().current` incremented and the persisted `today-1` day is now locked.
  - Idempotent: read the provider, then invalidate + re-read with the SAME `today` → streak unchanged (no double count), no extra saves (assert `current` stable).
  - First run (`Streak()` default, `lastCountedDay == null`) → no locked days saved; `streakRepo.get().lastCountedDay == today - 1 day`, `current == 0`.
- [ ] 2. **Run — red:** `flutter test --timeout=90s test/ui/features/today/view_models/streak_catchup_controller_test.dart`. Expected: FAIL — `streak_catchup_controller.g.dart` missing / undefined `streakCatchUpProvider`.
- [ ] 3. **Implement** `streak_catchup_controller.dart` per Contract, then `dart run build_runner build` (generates `.g.dart` for the new `@riverpod`). Update the `streakCountProvider` doc comment in `today_providers.dart` from "Stub data until S12 writes real streaks" to note S12 now writes real streaks via `StreakCatchUp`.
- [ ] 4. **Run — green:** `flutter test --timeout=90s test/ui/features/today/view_models/streak_catchup_controller_test.dart`.
- [ ] 5. Gates: `dart format .` · `flutter analyze` · `flutter test --timeout=90s`. Report for review.

**Skills:** `.agents/skills/flutter-expert`, `.agents/skills/flutter-riverpod`, `.agents/skills/dart-add-unit-test`, `.agents/skills/dart-generate-test-mocks`, `.agents/skills/dart-migrate-to-checks-package`.

**Out of scope:** triggering the controller from `TodayScreen`/the widget tree (S13 wires the chip + observer consumes it); the streak card / weekly bar / calendar UI (S13); milestone celebration UI (S13); notifications (S14); any change to `DayRepository`/`StreakRepository`/`Streak`/`Day` contracts or to `streakCountProvider`'s signature.

---

## Acceptance (whole plan)

- `dart format .` clean · `flutter analyze` clean · `flutter test --timeout=90s` green.
- `lib/domain/services/adherence.dart` imports no Flutter/Riverpod/JSON. `Streak`/`Day`/`DayState`/`Prefs` and all repository interfaces are unchanged.
- A locked day stores `adherence` (consumed÷planned, clamped), `thresholdUsed` (the threshold in effect that day), and `lockedAt` (UTC), written once together; re-locking is a no-op; `frozenDayState` stays stable when prefs change.
- `advanceStreak`: green +1, yellow/planned-0 hold, red reset; `personalBest` is the all-time max; idempotent on already-counted days; milestones {7,30,100} emit one-shot on upward crossing.
- `catchUp` locks every elapsed day (persisted-open locked in place, unopened rebuilt = red = reset, already-locked folded but not re-saved), seeds first-run cleanly, and is empty on an exhausted range.
- The `StreakCatchUp` controller persists newly-locked days + the streak on rollover/open and is idempotent across re-reads. No UI surface added (S13).
