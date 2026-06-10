# Spec — S13: History calendar UI + catch-up trigger

**Status:** approved (design) · **Spec S13 (UI)** · Phase 4 (Motivation). Depends on S04 (routing, `AppShell` `StatefulShellRoute.indexedStack`, core widgets, `Sheet`), S12 (`adherence.dart`: `dayAdherence`/`classifyDayState`/`frozenDayState`; `StreakCatchUp` controller; `catchUp`). Also uses S05 (`Day` trio, `plannedKcal`/`consumedKcal`, `deriveMealStatus`, `weekOf`, `localDateLabel`, `endOfDayLocal`), S02 (`Streak`, `DayState`, `Prefs.streakThreshold`, `DayRepository.getRange`, `StreakRepository`).

Scope = the **UI counterpart of S12** plus the **one wire S12 left dangling**: the real History tab (streak hero, weekly bar, stat grid, recent-days list), a month Calendar sheet, a milestone celebration sheet, and the catch-up **trigger** that makes the streak engine actually run at runtime. No new domain logic — S12 owns all adherence/streak math; S13 is providers + widgets + the trigger read.

## Goal

Make the streak visible and make it run. S12 shipped a pure engine that nothing reads, so the streak never advances at runtime. S13 mounts `streakCatchUpProvider` in the always-alive app shell so catch-up fires on app-open and on every midnight/resume rollover, persisting locked days + the new streak. It then surfaces that history: a History tab showing the current streak, personal best, a Mon–Sun adherence bar, 30-day stats, and recent days; a month Calendar sheet with per-day color and a tapped-day detail; and a one-shot milestone celebration when a fold crosses 7/30/100. Locked days are colored from their **frozen** state (never recolored by later threshold changes); today is a **live** preview that does not advance the streak.

## Decisions (brainstorm 2026-06-10)

- **Trigger lives in `AppShell`.** `ref.listen(streakCatchUpProvider, …)` in `AppShell.build`. `AppShell` is the `StatefulShellRoute.indexedStack` host — always mounted, survives tab switches, present from app-open. `StreakCatchUp.build` already `ref.watch(todayProvider)`, and `TodayScreen` already pokes `todayProvider.refresh()` on app-resume + the midnight tick → catch-up re-fires on every rollover with no new timer. Confirmed via fork. (Alternative — a `TodayScreen` watcher — rejected: couples streak liveness to the Today tab being the live branch.)
- **Milestones surface as a celebration sheet** patterned on `StreakRiskSheet` (centered modal, gold flame in a tinted circle, headline, body, primary CTA). The listener reads `AsyncData<List<int>>` from the catch-up provider; each crossed value shows a sheet. Multiple crossings in one fold are shown in sequence (ascending). One-shot — never stored (S12 already does not persist them). Confirmed via fork.
- **Streak chip → History tab.** `StreakChip.onTap` (currently unset) calls `context.go('/history')`. No dedicated streak-detail sheet — the History hero already is the full streak surface; a separate sheet would duplicate it. Confirmed via fork.
- **Open today cell = provisional color + distinct mark.** Today is not locked, so it has no `frozenDayState`. The weekly bar / calendar / recent list color today via the **live** `classifyDayState(dayAdherence(today), currentThreshold)` but render it visually as in-progress (hatched bar fill in the week strip; inset ring in the calendar grid) so it never reads as final. Confirmed via fork.
- **Full 2×2 stat grid.** Adherence % · Meals done · Avg kcal · Skipped, all over the last 30 days, matching the prototype. Needs one 30-day aggregation provider over `DayRepository.getRange`. Confirmed via fork.
- **Gold streak flame everywhere.** Hero flame, milestone sheet, and the shipped `StreakChip` all use `colors.gold` (AGENTS.md "streak flame = gold"). The prototype History hero's teal flame is **not** followed — chip consistency wins. Confirmed via fork.
- **Color comes from adherence state, never meal-completion ratio.** The prototype colors days by done/total **meals**; S12's invariant is that day color = `frozenDayState` (kcal-adherence). S13 colors every day by adherence state and uses meal counts (`deriveMealStatus`) only as secondary subtitle text ("4/5 meals"). This is the one place the prototype is deliberately overridden.
- **Calendar sheet = current-month grid** (not a recent-N list — that would duplicate the History recent-days list). Mon-first columns, per-day color, tap-to-select detail, monthly kept/partial/missed summary, legend. Confirmed via fork.
- **Weekly bar = Mon-anchored** via the existing `weekOf(today)` helper (same week the Today day-strip shows). Confirmed via fork.
- **No domain changes, no new math.** S13 imports `adherence.dart` read-only (`dayAdherence`, `classifyDayState`, `frozenDayState`) and `meal_lifecycle.dart` (`plannedKcal`, `consumedKcal`, `deriveMealStatus`, `weekOf`). All new code is providers (read layer over repos) + widgets + the shell listener. `adherence.dart` is **not** touched.

## Color mapping (single source for S13)

A small pure helper maps a `DayState` to a `CrudoColors` slot, used by every S13 surface:

| DayState | fill | text/accent |
|----------|------|-------------|
| green | `colors.success` (teal) | white on fill / `success` on tint |
| yellow | `colors.gold` | `goldDeep` on tint |
| red | `colors.error` / `errorSoft` bg | `error` |

Today (open, unlocked) uses the live-classified color **with** an in-progress treatment (hatch / ring). A day with no persisted row and no plan data resolves to red (matches S12's "unopened day = 0% = red").

## Providers (`lib/ui/features/history/view_models/` — read layer, no domain logic)

All derive synchronously from already-loaded repo streams + the injected `clockProvider`/`todayProvider`. None mutate. Threshold for live (today) classification comes from `profileProvider … prefs.streakThreshold`.

```dart
/// Full streak (current + personalBest), not just the count. streakCountProvider
/// (today feature) stays; this exposes the whole record for the hero.
@riverpod
Stream<Streak> streak(Ref ref);   // streakRepository.watch()

/// One Mon–Sun cell: the date, its adherence ratio (0..1), DayState, and whether
/// it is the open today (live) vs a locked past day (frozen) vs a future day.
typedef WeekCell = ({DateTime date, double adherence, DayState? state, WeekCellKind kind});
enum WeekCellKind { locked, today, future }

/// weekOf(today) → 7 cells. getRange(weekStart, today). Past locked days →
/// frozenDayState; today → live classifyDayState(dayAdherence, threshold);
/// future → null state (empty bar).
@riverpod
Future<List<WeekCell>> weeklyAdherence(Ref ref);

/// 30-day rollup ending today (inclusive). getRange(today-29d, today).
typedef HistoryStats = ({int adherencePct, int mealsDone, int avgKcal, int skipped});
@riverpod
Future<HistoryStats> historyStats(Ref ref);

/// Last 5 days descending (today first). Per day: date, adherence, DayState
/// (frozen for locked, live for today), meals done / total.
typedef RecentDay = ({DateTime date, double adherence, DayState state, int done, int total});
@riverpod
Future<List<RecentDay>> recentDays(Ref ref);

/// Cells for a month grid (the Calendar sheet). Leading nulls for Mon-first
/// alignment, then one cell per day with color state (frozen/live/future-empty)
/// and per-day detail (done/total meals, consumed kcal, adherence pct).
typedef CalendarCell = ({DateTime date, DayState? state, WeekCellKind kind, int done, int total, int kcal, int adherencePct});
@riverpod
Future<List<CalendarCell?>> monthGrid(Ref ref, DateTime month);
```

Aggregation rules (no new math — compose S12 + S05 helpers):
- **adherence** of a day = `dayAdherence(day)` (consumed÷planned, clamped).
- **state** of a *locked* day = `frozenDayState(day)`; of *today* = `classifyDayState(dayAdherence(today), threshold)`.
- **meals done/total** = count `deriveMealStatus(meal, day.date, now, now) == done` / `meal count`. (`now` as graceEnd is fine for historical/locked days — rule 1/2 fire before grace logic.)
- **adherencePct** = `(dayAdherence(day) * 100).round()`.
- **historyStats**: `adherencePct` = mean of per-day adherence over locked days in range, ×100 rounded; `mealsDone` = Σ done meals; `avgKcal` = mean `consumedKcal` per day rounded; `skipped` = Σ skipped meals.
- Days with **no persisted row** in a range are absent (the engine back-materializes+locks them on rollover; if catch-up has run they exist, if not they simply don't render yet). No on-read materialization — providers are pure reads.

## Widgets

### History tab — `lib/ui/features/history/views/history_screen.dart` (replaces placeholder)

`ConsumerWidget`, scrollable, `SafeArea`. Sections top→bottom:
1. **App bar**: "Tracking" label + "History" headline (left), calendar `IconButton` (right) → `showCalendarSheet`.
2. **Streak hero card** (`surfaceLowest`, `Radii.xl`, `Shadows.cloud`): big current count + "days", `Personal best: N` pill, gold `Icons.local_fire_department`. Below: Mon–Sun **week strip** — 7 vertical bars, height ∝ adherence, color by `WeekCell.state`, today bar hatched, future bars empty (`surfaceLow`). Day initials under each.
3. **Stat grid** (2×2): Adherence % · Meals done · Avg kcal · Skipped (`historyStats`). Adherence colored `success`, Skipped colored `error`, others neutral.
4. **Recent days** ("Last 5 days"): per `RecentDay` a row — date + "x/y meals" subtitle, adherence progress bar (state color), pct on the right.

All async sections render via `.when` with a compact loading shimmer/`SizedBox` and an error fallback (consistent with TodayScreen's `dayAsync.when`).

### Calendar sheet — `lib/ui/features/history/views/calendar_sheet.dart` (new)

Bottom `Sheet` (grabber, `maxHeight ~92%`). Header: "Last 30 days" label + month title + close button. Mon-first day-of-week header (M T W T F S S). Month grid (`monthGrid(month)`): each cell a square, color by state, today inset ring, future faded/empty, selected day a 2px outline ring. Tapping a non-future day selects it → detail card (done/total meals, `Progress` bar, calories, adherence %). Monthly summary row: KEPT / PARTIAL / MISSED counts. Legend. State (`selectedDate`, optional month paging) held locally in a `StatefulWidget`/`HookConsumer`; opened via `showCrudoSheet`-style helper `showCalendarSheet(context)`.

### Milestone sheet — `lib/ui/features/history/views/milestone_sheet.dart` (new)

Centered modal (pattern = `StreakRiskSheet`): gold flame in a `gold @ 15%` circle, gold "Streak milestone" label, headline ("`N`-day streak!"), supportive body, "Keep going" primary CTA. `showMilestoneSheet(context, milestone)` returns a `Future` so the listener can `await` and chain multiple crossings in order.

### Today wiring — `lib/ui/features/today/views/today_screen.dart`, `streak_chip.dart`

- `StreakChip` usage in `TodayScreen` gets `onTap: () => context.go('/history')`.
- `_AppBar.onCalendarTap` replaced: toast stub → `showCalendarSheet(context)`.

### Catch-up trigger — `lib/ui/core/widgets/app_shell.dart`

In `AppShell.build`, add a `ref.listen<AsyncValue<List<int>>>(streakCatchUpProvider, (prev, next) { … })`. On `AsyncData` with a non-empty list, for each milestone (ascending) `await showMilestoneSheet`. `ref.listen` activates the provider, so `build()` runs once at app-open and again whenever `todayProvider` advances. Guard against showing sheets before the first frame / when no `BuildContext` route is ready (use a post-frame callback if needed). No behavior change when the list is empty (the common case).

## Invariants S13 must not break

- **Locked days never recolor.** Color of any `lockedAt != null` day comes only from `frozenDayState(day)` (stored `adherence` + `thresholdUsed`). Never re-run `classifyDayState` with the *current* threshold on a locked day.
- **Today never advances the streak.** Today's color is a live preview only; the displayed streak count comes from `streakRepository`, which only changes when catch-up locks a day at/after midnight.
- **Adherence denominator is planned kcal** (via `dayAdherence`), never `dailyKcalTarget`.
- **Idempotent trigger.** Re-firing catch-up after it has caught up is a no-op (S12's `lastCountedDay` guard) — the listener must not double-show milestones for the same fold (each `build` returns that fold's crossings once; an unchanged rebuild returns `[]`).

## Testing (`package:checks`, `flutter test --timeout=90s`)

Provider tests with overridden `dayRepository`/`streakRepository`/`profileRepository` + fixed `clockProvider`:
- `weeklyAdherence`: locked past days use frozen state; today uses live state with current threshold; future cells empty; Mon-anchored ordering.
- `historyStats`: adherence mean, meals-done/skipped counts, avg kcal over a seeded range; empty range → zeros.
- `recentDays`: 5 desc, today first, frozen vs live state, done/total counts.
- `monthGrid`: leading-null alignment (Mon-first), per-cell state + detail, future faded.
- **Frozen-vs-live**: a locked day whose `thresholdUsed` differs from current prefs keeps its frozen color; today flips color when prefs threshold changes.

Trigger / wiring tests (widget-level, pumped `AppShell` with fake repos + clock):
- App-open with elapsed unlocked days → catch-up runs → days persisted + streak saved (assert repo writes), milestone sheet shown for a crossing.
- `todayProvider` advance (simulate rollover) → catch-up re-fires.
- Empty/no-op fold → no sheet, no extra writes.
- `StreakChip.onTap` → routes to `/history`; calendar button → opens sheet.

Goldens deferred (per design-alignment backlog) unless the hero/grid layout warrants one — not required for S13 green.

## Out of scope

S14 streak-at-risk + reminders (the `StreakRiskSheet` itself ships in S14; S13 only *patterns* the milestone sheet on it). Date-pinned plan override (backlog). JSON/DTOs (S20). Any new adherence/streak math (S12). Profile "Streak preferences" toggles (prototype shows them under Profile — that's S15/settings, not S13). Month paging beyond the current month is optional polish, not required.
