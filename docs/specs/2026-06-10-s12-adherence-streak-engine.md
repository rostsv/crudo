# Spec — S12: Adherence + streak engine

**Status:** approved (design) · **Spec S12 (logic)** · Phase 4 (Motivation). Depends on S02 (`Streak`, `Day` frozen trio, `DayState`, `Prefs.streakThreshold`, `StreakRepository`), S05 (`buildDayFromPlan`, `plannedKcal`/`consumedKcal`, `Day` materialization + lock-is-derived), S09 (`selectPlanForDate`). UI counterpart = **S13** (streak card, weekly bar, calendar) — out of scope here.

Scope = the **pure logic** that turns logged days into a streak: per-day adherence ratio + 3-state classification, the midnight-lock freeze of a `Day`'s `adherence`/`thresholdUsed`/`lockedAt` trio, the +1/hold/reset streak transition with personal-best + milestone events, and a pure catch-up orchestrator that locks every elapsed calendar day (including unopened ones) and folds them into the streak. Plus one thin controller hook that fires catch-up on rollover/app-open and persists the result. No new UI surface.

## Goal

Make the streak number real. Each elapsed day is frozen at midnight with the adherence it actually achieved (consumed ÷ planned kcal) and the threshold in effect that day; a green day (≥ threshold) advances the streak, yellow (50–<threshold) holds it, red (<50%) resets it to zero. Personal best tracks the high-water mark; crossing 7/30/100 emits a one-shot milestone event for S13 to celebrate. A day the user never opened is locked as 0%-consumed red and resets the streak — no special gap handling. History never recolors when settings change, because each day stores the threshold it was judged against.

## Decisions (brainstorm 2026-06-10)

- **Lock-on-rollover/open, with catch-up.** No background scheduler exists; the `Today` provider already re-derives on app-resume + a midnight tick (`TodayScreen` owns the observer/timer, calls `refresh()`). S12 ships a pure catch-up orchestrator; a thin today-side hook calls it whenever `Today` advances or the app opens, locking **all** unlocked elapsed days at once (correct even if the app was closed across many midnights). Domain stays pure — the hook is the only Riverpod-aware code. Confirmed via brainstorm fork.
- **Only locked past days count.** Today's `DayState` is derived **live** for the UI (green/yellow/red preview off current consumed/planned + current prefs threshold), but the streak number advances only when a day **locks** at midnight. No optimistic in-day +1 — a displayed streak never decreases within a day. Confirmed via fork.
- **Unopened days back-materialized and locked.** Catch-up materializes each elapsed calendar day from `lastCountedDay + 1` to yesterday via `buildDayFromPlan` + `selectPlanForDate`, locks it, and folds it. An unopened day has 0 consumed → 0% adherence → red → resets. This **is** the gap-detection mechanism; there is no separate date-arithmetic path. Produces accurate persisted history for the S13 calendar. Confirmed via fork.
- **Milestones are emitted events, not derived state.** The transition returns `(newStreak, List<int> milestonesCrossed)`. Milestones {7, 30, 100} fire only on the exact lock that crosses the value upward — ephemeral, never stored. Lets S13 distinguish "just hit 7" from "currently at 12". Confirmed via fork.
- **Adherence denominator is planned kcal, never `dailyKcalTarget`.** `dayAdherence = consumedKcal ÷ plannedKcal`, clamped to [0,1] (architecture §10 + AGENTS.md). `dailyKcalTarget` is onboarding guidance only and is never read here.
- **Threshold is frozen per day.** `lockDay` stores `thresholdUsed = prefs.streakThreshold` at lock time. Later settings changes never rewrite history. The red floor is a fixed `const adherenceRedFloor = 50` (percent) — not stored, not user-settable (matches `Prefs` doc comment). Live/open-day classification uses the **current** prefs threshold; frozen days re-derive from their stored `thresholdUsed`.
- **`lastCountedDay` = high-water mark of processed days.** It advances on **every** locked day folded (green, yellow, **and** red), not only counted ones — its real job is idempotency (catch-up run twice never double-counts) and "where did processing stop". Reset detection is purely the day's own red state, never a date gap.
- **`plannedKcal == 0` → hold (edge).** An empty/all-dangling plan day has no target to hit or miss. The fold special-cases `plannedKcal == 0` as a **hold** (streak unchanged, never reset); `lockDay` still freezes the trio with `adherence = 0.0`. Prevents "no plan ⇒ auto-reset" punishing a legitimately empty day. (The "≥1 plan always exists" invariant makes this rare; back-materialization can still hit it if every template dangled.)
- **No model changes.** `Streak`, `Day`, `DayState`, `Prefs` are final. S12 only fills in the transitions the S02 doc comments explicitly deferred. The only new domain code is `adherence.dart` (pure functions + small records).
- **Service-level lock, not a `Day` method.** The freeze lives in `adherence.dart` as `lockDay(Day, …)`, not as a `Day.lock()` method — `Day` importing a service that imports `Day` would cycle (the same reason `meal_status.dart` deliberately avoids importing `Day`). `adherence.dart` may import `day`, `nutrition`, `meal_lifecycle`, `plan_scheduling`, `enums`, `profile` freely.

## New domain (`lib/domain/services/adherence.dart`, new — pure)

Two sections, one file: per-day (adherence + state + freeze) and cross-day (streak fold + catch-up). Imports `day`, `meal_lifecycle` (for `plannedKcal`/`consumedKcal`, `buildDayFromPlan`), `plan_scheduling` (`selectPlanForDate`), `shared/enums`, `streak`, `profile/prefs`. No Flutter/Riverpod/JSON.

### Per-day

```dart
/// Fixed red floor (percent). Below this a day resets the streak. Not stored,
/// not user-settable (Prefs doc comment); the green line is Prefs.streakThreshold.
const int adherenceRedFloor = 50;

/// Day adherence = consumed ÷ planned kcal, clamped to [0,1]. planned == 0
/// (empty/all-dangling plan) → 0.0 by convention; the fold treats that as a
/// hold, not a failure (see advanceStreak). Never uses dailyKcalTarget.
double dayAdherence(Day day);

/// 3-state verdict for a given adherence ratio (0..1) against a threshold
/// (percent, e.g. 80). ratio*100 >= threshold → green; < adherenceRedFloor →
/// red; else yellow. Boundary is inclusive at the green line, exclusive at the
/// red floor (exactly 50% = yellow, exactly threshold = green).
DayState classifyDayState(double adherence, int threshold);

/// Freeze an open day: writes the frozen trio via copyWith
/// (adherence = dayAdherence(day), thresholdUsed = threshold,
/// lockedAt = now.toUtc()). Idempotent — an already-locked day (lockedAt != null)
/// is returned unchanged. `threshold` is the caller's current prefs value,
/// captured into history so later settings changes never recolor this day.
Day lockDay(Day day, int threshold, DateTime now);

/// State of an ALREADY-LOCKED day, re-derived from its stored
/// adherence + thresholdUsed (history is stable across prefs changes).
/// Throws StateError if the day is not locked (adherence == null).
DayState frozenDayState(Day day);
```

### Cross-day

```dart
/// Result of folding locked days into a streak. milestonesCrossed holds the
/// milestone values {7,30,100} newly reached upward during THIS fold, in
/// ascending order; ephemeral, never persisted.
typedef StreakOutcome = ({Streak next, List<int> milestonesCrossed});

/// Streak milestones that emit a one-shot celebration event.
const List<int> streakMilestones = [7, 30, 100];

/// Fold locked days (ascending by date) into the streak. Skips any day whose
/// date label <= prev.lastCountedDay (idempotent re-runs). Per remaining day:
///   green                       → current + 1, bump personalBest, advance lastCountedDay
///   yellow / planned-kcal == 0  → hold (current unchanged), advance lastCountedDay
///   red                         → current = 0,               advance lastCountedDay
/// personalBest is the max ever seen; never decreases. Emits a milestone each
/// time the RUNNING current transitions from below a streakMilestones value to
/// at-or-above it during this fold (so a reset-then-reclimb past 7 re-emits 7,
/// and one fold over many green days can emit several in ascending order).
/// Each day must be locked (adherence != null) — throws StateError otherwise.
StreakOutcome advanceStreak(Streak prev, List<Day> lockedDaysAscending);

/// Pure catch-up: lock every elapsed calendar day and fold it into the streak.
/// Inputs are raw repo data (no repo access here — mirrors buildDayFromPlan).
/// For each calendar date d in (prevStreak.lastCountedDay, todayLabel), i.e.
/// every elapsed day up to but excluding today:
///   - a persisted day for d already LOCKED → use as-is (idempotent, not re-saved);
///   - a persisted but OPEN day for d → lockDay(it, threshold, …) — it holds the
///     user's real logging, so lock THAT, never a fresh 0-consumed rebuild;
///   - no persisted row → materialize via buildDayFromPlan(selectPlanForDate(
///     plans, d), d, newId, mealTemplates, foods) then lockDay(…).
/// Then fold all the resulting locked days (ascending) via advanceStreak.
/// lockedDays = the days that were newly frozen this run (open-locked + rebuilt;
/// NOT the already-locked persisted ones) — exactly what the caller must persist.
/// An empty range (already caught up) returns prevStreak unchanged + no days.
typedef CatchUpResult = ({
  List<Day> lockedDays,     // newly frozen days to persist (ascending)
  Streak streak,            // post-fold streak
  List<int> milestones,     // crossed this catch-up
});

CatchUpResult catchUp({
  required DateTime todayLabel,            // localDateLabel(now)
  required Streak prevStreak,
  required int threshold,                  // current Prefs.streakThreshold
  required List<Day> persistedDays,        // any already-stored days in range
  required List<PlanTemplate> plans,
  required List<MealTemplate> mealTemplates,
  required List<Food> foods,
  required String Function() newId,        // slot-id minter (uuid v7 in prod)
});
```

**`lockInstantFor(d)` / lock timestamp:** a back-materialized day locks at the end-of-day midnight of `d` (`endOfDayLocal(d).toUtc()`), not "now" — `lockedAt` reflects when the day actually closed, keeping history truthful. Today's own day is never locked by catch-up (it's still open).

**First-run / null `lastCountedDay`:** `DayRepository` has no enumerate/range query (only `watchByDate` + `save`), so catch-up cannot discover which past dates have rows. When `prevStreak.lastCountedDay == null`, catch-up therefore **back-materializes nothing**: it returns `prevStreak` with `lastCountedDay` **seeded to `todayLabel − 1 day`** and `current` unchanged (0 for a fresh user). The streak starts counting from today forward; pre-install history never retro-resets the streak. Every subsequent run has a concrete lower bound and the normal range logic applies. The caller passes only the persisted days it can cheaply fetch in `(lastCountedDay, todayLabel)` (one `watchByDate(...).first` per date — the range is normally a single day).

## Wiring (thin, Riverpod — `lib/ui/features/today/view_models/`)

The only non-pure code. A hook that runs catch-up when `Today` advances or the app opens, then persists:

- On `Today` change / app resume: read `prevStreak` (`StreakRepository`), `threshold` (`Prefs`), active `plans`/`mealTemplates`/`foods`, and any `persistedDays` in range; call `catchUp(...)`; persist each `lockedDays` entry (`DayRepository.save`) and `StreakRepository.save(streak)`. Idempotent — re-running is a no-op once caught up.
- `streakCountProvider` (already exists, currently stubbed off the repo) needs no contract change — once catch-up writes real streaks, the chip shows them. Update its doc comment ("Stub data until S12") to reflect S12 is now live.
- Milestone events surface to S13; for S12 the hook may simply log/no-op them (S13 owns the celebration UI). Do **not** store them.

Exact provider/notifier shape (a dedicated `StreakCatchUpController` vs folding into the existing `Today`/day controller) is the plan's call; the contract is "catch-up fires on rollover/open, persists locked days + streak, never double-counts."

## Out of scope (explicit)

- **Streak card, weekly adherence bar, calendar/history UI** → S13.
- **Milestone celebration UI / toast / animation** → S13 (S12 emits the events only).
- **Notifications / background wake** to drive locking → S14 (S12 locks on next foreground rollover/open).
- **Weekend-skip / rest-day streak rules** → post-MVP (AGENTS.md).
- **JSON / DTOs / persistence wire shapes** → S20 (repos stay in-memory).
- **Model contract changes** — `Streak`/`Day`/`DayState`/`Prefs` are final; only `adherence.dart` is added.
- **`dailyKcalTarget`-based goals or calorie budgeting** — never the adherence denominator.

## Tests

**Domain (`package:test`, `package:checks`):**

- `dayAdherence` — consumed/planned ratio for a normal day; clamps >1 to 1.0 (over-eaten); `plannedKcal == 0` → 0.0; all-skipped day → 0.0.
- `classifyDayState` — green at exactly threshold and above; red below 50; yellow at exactly 50 and in (50, threshold); sweep a few thresholds (70/80/90/100).
- `lockDay` — freezes adherence + thresholdUsed + lockedAt together (trio assert holds); `lockedAt` is UTC; idempotent (locking a locked day returns it unchanged); `thresholdUsed` stores the passed value, not current prefs.
- `frozenDayState` — re-derives from stored trio; **stable across a prefs threshold change** (lock at 80, then classify with 100 still uses the stored 80); throws on an unlocked day.
- `advanceStreak` —
  - green sequence increments and bumps personalBest;
  - yellow holds (current unchanged, lastCountedDay still advances);
  - red resets to 0 (personalBest preserved);
  - `plannedKcal == 0` day holds, does not reset;
  - idempotent: re-folding days with date ≤ lastCountedDay is a no-op;
  - personalBest never decreases after a reset;
  - throws on an unlocked day in the list.
- `advanceStreak` milestones — crossing 7 emits `[7]` on the exact lock; staying above 7 emits nothing; a single fold that jumps past two milestones (e.g. catch-up over many green days) emits both in order; a reset then re-climb re-emits.
- `catchUp` —
  - multi-day gap with one red day in the middle → streak resets at that day, climbs after;
  - unopened day (no persisted row, plan active) back-materialized → red → reset, day returned for persistence;
  - already-caught-up (range empty) → streak unchanged, no days;
  - prefers an existing locked persisted day over re-materializing;
  - first-run (`lastCountedDay == null`, no history) → `current = 0`, no spurious back-materialized days;
  - `lockedAt` on back-materialized days = that day's end-of-day midnight (UTC), not today.

**Wiring (`ProviderContainer`, in-memory repos):**

- Advancing `Today` past an open yesterday triggers catch-up: yesterday is persisted locked, `StreakRepository` reflects the new count; `streakCountProvider` emits it.
- Running the hook twice (same `Today`) does not double-count (idempotent).
- A green yesterday increments the chip; a red/unopened yesterday resets it.

## Acceptance

- `dart format .` clean · `flutter analyze` clean · `flutter test --timeout=90s` green.
- A locked day stores `adherence = consumed÷planned` (clamped), `thresholdUsed` = the threshold in effect that day, and `lockedAt` (UTC) — written exactly once, together; re-locking is a no-op.
- Day state derivation: green ≥ threshold → +1, yellow 50–<threshold → hold, red <50% → reset; history never recolors when the user later changes `streakThreshold`.
- Streak advances only on locked days; today is live-preview only and never changes the stored count mid-day. Personal best is the all-time max. Crossing 7/30/100 emits a one-shot event (not stored).
- Catch-up on rollover/open locks every elapsed calendar day (including unopened = red = reset), folds them into the streak, persists the locked days + streak, and is idempotent across repeated runs and app restarts.
- No file under `lib/domain/` (beyond `adherence.dart` + its tests), `lib/data/`, or `lib/application/` changes contract; `Streak`/`Day`/`DayState`/`Prefs` and all repos are unchanged. `adherence.dart` imports no Flutter/Riverpod/JSON.
