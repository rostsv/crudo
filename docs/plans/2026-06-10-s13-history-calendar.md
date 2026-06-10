# Plan — S13: History calendar UI + catch-up trigger

**Worker note:** Implements `docs/specs/2026-06-10-s13-history-calendar.md` (read it first). UI counterpart of S12 + the one wire S12 left dangling (`streakCatchUpProvider` is never read → streak inert at runtime). Read `.agents/skills/flutter-riverpod`, `.agents/skills/flutter-add-widget-test`, `.agents/skills/dart-add-unit-test` before starting. Tests use `package:checks` (not `matcher`). **Every `flutter test` runs `--timeout=90s`.** No domain logic added — `lib/domain/services/adherence.dart` is READ-ONLY for the whole plan.

**Goal:** Make the streak run (mount catch-up in the always-alive `AppShell`) and visible (real History tab, month Calendar sheet, milestone celebration sheet, Today chip + calendar-button wiring).

**Decisions (settled in brainstorm — no task re-litigates):**

| Fork | Decision |
|---|---|
| Catch-up trigger host | `ref.listen(streakCatchUpProvider)` in `AppShell.build` (always-mounted `indexedStack`); rollover already pokes `todayProvider` via `TodayScreen`. |
| Milestone surfacing | Centered celebration dialog patterned on prototype `StreakRiskSheet`; one per crossing, shown in sequence. |
| Streak chip onTap | `context.go('/history')` (no separate streak-detail sheet). |
| Open today cell | Live `classifyDayState` color + in-progress mark (hatched week bar / inset calendar ring). |
| Stat grid | Full 2×2: Adherence % · Meals done · Avg kcal · Skipped (last 30 days). |
| Flame color | `colors.gold` everywhere (chip-consistent; prototype teal NOT followed). |
| Day color source | `frozenDayState` for locked days, live `classifyDayState` for today — NEVER meal-completion ratio. Meal counts are subtitle text only. |
| Calendar scope | Current-month grid (Mon-first). |
| Weekly bar | Mon-anchored `weekOf(today)`. |

**File changes (whole plan):**
- Create: `lib/ui/features/history/view_models/history_providers.dart` (+ `.g.dart`) — Task 1
- Create: `lib/ui/features/history/views/history_ui.dart` — `dayStateColor` + `AdherenceBar` — Task 2
- Rewrite: `lib/ui/features/history/views/history_screen.dart` (replaces placeholder) — Task 3
- Create: `lib/ui/features/history/views/calendar_sheet.dart` — Task 4
- Create: `lib/ui/features/history/views/milestone_sheet.dart` — Task 5
- Modify: `lib/ui/core/widgets/app_shell.dart`, `lib/ui/features/today/views/today_screen.dart` — Task 6
- Tests under `test/ui/features/history/`.

**Shared contract — repo/provider handles the worker reuses (already exist):**

```dart
// from lib/config/di.dart
final dayRepositoryProvider;      // DayRepository: getRange(from,to) inclusive sorted; watchByDate(d)
final streakRepositoryProvider;   // StreakRepository: watch() Stream<Streak>; get()
final profileRepositoryProvider;  // ProfileRepository: watch() Stream<UserProfile>
// from lib/ui/features/today/view_models/today_providers.dart
final clockProvider;              // Provider<DateTime Function()>
final todayProvider;              // Today: DateTime (UTC day-label), refresh()
// from lib/ui/features/today/view_models/streak_catchup_controller.dart
final streakCatchUpProvider;      // StreakCatchUp: AsyncNotifier<List<int>> (milestones crossed)
// pure helpers (read-only this plan)
double dayAdherence(Day);                       // adherence.dart
DayState classifyDayState(double, int);         // adherence.dart
DayState frozenDayState(Day);                   // adherence.dart (locked day only)
double plannedKcal(Day); double consumedKcal(Day);             // meal_lifecycle.dart
MealStatus deriveMealStatus(ScheduledMeal, DateTime date, DateTime now, DateTime graceEnd); // meal_status.dart
List<DateTime> weekOf(DateTime dayLabel);       // today/views/formatting.dart (Mon..Sun)
```

---

## Task 1: History providers (read layer)

**Role:** implement

**Goal:** Pure read providers deriving the History tab's data from `DayRepository.getRange` + `StreakRepository` + `clockProvider`/`todayProvider`. No mutation, no domain math — compose S12/S05 helpers only.

**Files:**
- Create: `lib/ui/features/history/view_models/history_providers.dart` — `@riverpod`, needs `dart run build_runner build` (creates `history_providers.g.dart`)
- Test: `test/ui/features/history/history_providers_test.dart`

**Contract:**

```dart
// lib/ui/features/history/view_models/history_providers.dart
import 'package:crudo/config/di.dart';
import 'package:crudo/domain/day/day.dart';
import 'package:crudo/domain/services/adherence.dart';
import 'package:crudo/domain/services/meal_lifecycle.dart';
import 'package:crudo/domain/services/meal_status.dart';
import 'package:crudo/domain/shared/enums.dart';
import 'package:crudo/domain/streak/streak.dart';
import 'package:crudo/ui/features/today/view_models/today_providers.dart';
import 'package:crudo/ui/features/today/views/formatting.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'history_providers.g.dart';

/// Open today vs a locked past day vs a future (not-yet) day.
enum DayCellKind { locked, today, future }

typedef WeekCell = ({DateTime date, double adherence, DayState? state, DayCellKind kind});
typedef HistoryStats = ({int adherencePct, int mealsDone, int avgKcal, int skipped});
typedef RecentDay = ({DateTime date, double adherence, DayState state, int done, int total});
typedef CalendarCell = ({
  DateTime date,
  DayState? state,
  DayCellKind kind,
  int done,
  int total,
  int kcal,
  int adherencePct,
});

/// Full streak (current + personalBest). streakCountProvider (today feature) stays.
@riverpod
Stream<Streak> streak(Ref ref) => ref.watch(streakRepositoryProvider).watch();

/// Mon..Sun of weekOf(today). Past locked days → frozenDayState; today → live
/// classifyDayState(dayAdherence, currentThreshold); future → null state.
/// Re-watches todayProvider + streakProvider so it recomputes after a lock.
@riverpod
Future<List<WeekCell>> weeklyAdherence(Ref ref);

/// 30-day rollup ending today inclusive (getRange(today-29d, today)).
/// adherencePct = mean per-day adherence ×100 rounded; mealsDone = Σ done;
/// avgKcal = mean consumedKcal rounded; skipped = Σ skipped. Empty → all 0.
@riverpod
Future<HistoryStats> historyStats(Ref ref);

/// Last 5 days descending (today first).
@riverpod
Future<List<RecentDay>> recentDays(Ref ref);

/// Cells for [month]'s grid, Mon-first: leading nulls then one cell/day.
/// Days after today → kind future, null state. Today → live. Past → frozen.
@riverpod
Future<List<CalendarCell?>> monthGrid(Ref ref, DateTime month);
```

Implementation notes the worker follows verbatim:

```dart
// threshold for live (today) classification:
int _threshold(Ref ref) =>
    ref.watch(profileProvider).value?.prefs.streakThreshold ?? 80;
// NOTE: profileProvider (today_providers.dart) is Stream<UserProfile>.

int _done(Day d, DateTime now) =>
    d.meals.where((m) => deriveMealStatus(m, d.date, now, now) == MealStatus.done).length;
int _skipped(Day d, DateTime now) =>
    d.meals.where((m) => deriveMealStatus(m, d.date, now, now) == MealStatus.skipped).length;

// state of one day given today + threshold:
//   d.date == today  → classifyDayState(dayAdherence(d), threshold)   (live)
//   d.lockedAt != null → frozenDayState(d)                            (frozen)
//   else (open past w/o lock, shouldn't occur post-catch-up) → frozenDayState if locked else live
// kind: d.date.isAfter(today) → future; == today → today; else locked.
```

**Steps (TDD):**

- [ ] 1. **Failing test** — `history_providers_test.dart`: build a `ProviderContainer` overriding `dayRepositoryProvider`, `streakRepositoryProvider`, `profileRepositoryProvider` with fakes and `clockProvider` to a fixed instant. Seed locked days (Mon green via `thresholdUsed`, one red) + today open. Assert `weeklyAdherence` returns 7 cells, Mon `state == DayState.green` from frozen, today `kind == DayCellKind.today` with live state, future cells `state == null`. Assert `historyStats` mean/sums on a seeded 30-day range. Assert `recentDays` length 5 desc with correct `done`/`total`. Assert `monthGrid` leading-null count = `(weekOf(firstOfMonth).indexOf(firstOfMonth))` Mon-first offset and future days null-state.
- [ ] 2. **Run — red:** `flutter test --timeout=90s test/ui/features/history/history_providers_test.dart` → expected FAIL "weeklyAdherence isn't defined" / part file missing.
- [ ] 3. **Implement** the contract + run `gtimeout 600 dart run build_runner build --delete-conflicting-outputs`.
- [ ] 4. **Run — green:** `flutter test --timeout=90s test/ui/features/history/history_providers_test.dart`.
- [ ] 5. Gates: `dart format .` · `flutter analyze` · `flutter test --timeout=90s`. Report for review.

**Skills:** `.agents/skills/flutter-riverpod`, `.agents/skills/dart-add-unit-test`, `.agents/skills/dart-migrate-to-checks-package`.

**Out of scope:** any widget (Tasks 2–6); `adherence.dart` (read-only); the trigger listener (Task 6). Do not add on-read day materialization — providers are pure reads.

**Acceptance:** All five providers derive correctly; locked days use frozen state, today uses live state with the current threshold; future cells carry `null` state; empty range → zeroed `HistoryStats`.

---

## Task 2: Shared history UI helpers

**Role:** ui

**Goal:** One color mapper + one reusable adherence bar, used by the screen, recent list, and calendar detail. Keeps color logic DRY and the `frozenDayState`/live distinction out of widgets.

**Files:**
- Create: `lib/ui/features/history/views/history_ui.dart`
- Test: `test/ui/features/history/history_ui_test.dart`

**Contract:**

```dart
// lib/ui/features/history/views/history_ui.dart
import 'package:flutter/material.dart';
import 'package:crudo/domain/shared/enums.dart';
import '../../../core/themes/colors.dart';
import '../../../core/themes/dimensions.dart';

/// Fill color for a DayState. green → success (teal), yellow → gold,
/// red → error. The single source of day-color truth for S13.
Color dayStateColor(DayState state, CrudoColors colors) => switch (state) {
  DayState.green => colors.success,
  DayState.yellow => colors.gold,
  DayState.red => colors.error,
};

/// Thin rounded progress bar. [value] 0..1, [color] from dayStateColor.
/// Track = surfaceHigh. Height on 4px grid (default 6 → use Spacing.xs+2).
class AdherenceBar extends StatelessWidget {
  const AdherenceBar({required this.value, required this.color, this.height = 6, super.key});
  final double value;
  final Color color;
  final double height;
  @override
  Widget build(BuildContext context);
}
```

**Steps (TDD):**

- [ ] 1. **Failing test** — `history_ui_test.dart`: `check(dayStateColor(DayState.green, CrudoColors.light)).equals(CrudoColors.light.success)` for all three states; pump `AdherenceBar(value: 0.5, color: ...)` inside a sized box, find the fill `Container`/`FractionallySizedBox` and assert `widthFactor`/flex ≈ 0.5 and bar present.
- [ ] 2. **Run — red:** `flutter test --timeout=90s test/ui/features/history/history_ui_test.dart` → FAIL "dayStateColor isn't defined".
- [ ] 3. **Implement** the contract. Bar = `ClipRRect(Radii.full)` over a `surfaceHigh` track with a `FractionallySizedBox(widthFactor: value.clamp(0,1))` filled `color`.
- [ ] 4. **Run — green:** `flutter test --timeout=90s test/ui/features/history/history_ui_test.dart`.
- [ ] 5. Gates: `dart format .` · `flutter analyze` · `flutter test --timeout=90s`. Report for review.

**Skills:** `.agents/skills/flutter-add-widget-test`, `.agents/skills/flutter-fix-layout-issues`.

**Out of scope:** providers (Task 1); the screen/sheets (Tasks 3–5). No drop shadows, no 1px borders (tonal only).

**Acceptance:** `dayStateColor` maps all three states; `AdherenceBar` renders a clamped fill with no border/shadow.

---

## Task 3: History tab screen

**Role:** ui

**Goal:** Replace the placeholder `HistoryScreen` with the real tab: streak hero (current + personal best + gold flame + Mon–Sun bar), 2×2 stat grid, last-5-days list. Calendar button opens the sheet (Task 4 provides `showCalendarSheet`; until then a stub closure — Task 4 wires it).

**Files:**
- Rewrite: `lib/ui/features/history/views/history_screen.dart`
- Test: `test/ui/features/history/history_screen_test.dart`

**Contract:**

```dart
// HistoryScreen: ConsumerWidget. SafeArea > ListView. Sections:
//   _AppBar: "TRACKING" label + "History" headline + calendar IconButton (right).
//   _StreakHero: ref.watch(streakProvider) → current count (CrudoText.display-ish,
//     big), "Personal best: N" pill (colors.primarySoft bg), gold Icons.local_fire_department.
//     Below: week strip from ref.watch(weeklyAdherenceProvider): 7 columns, each a
//     fixed-height track (surfaceLow) with a bottom-anchored fill of height
//     (cell.adherence) and color dayStateColor(cell.state). today cell (kind==today)
//     painted with a hatched/striped fill; future (state==null) left empty. Day
//     initial under each (['M','T','W','T','F','S','S']).
//   _StatGrid: ref.watch(historyStatsProvider) → 2×2 cards: Adherence % (success),
//     Meals done (onSurface), Avg kcal (onSurface), Skipped (error).
//   _RecentList: ref.watch(recentDaysProvider) → rows: date label + "$done/$total meals"
//     subtitle, AdherenceBar(value: day.adherence, color: dayStateColor(day.state)),
//     "${(day.adherence*100).round()}%" trailing.
// Each async section uses .when(loading: shimmer/SizedBox, error: small text, data: …).
// Calendar IconButton onPressed: () => showCalendarSheet(context)  // Task 4
```

**Steps (TDD):**

- [ ] 1. **Failing test** — `history_screen_test.dart`: pump `HistoryScreen` in a `ProviderScope` with the Task-1 providers overridden to return seeded data (streak current 12 / best 21; a week with one red; stats 87%/142/2180/7; 5 recent days). Assert finds text `'12'`, `'Personal best: 21'`, `'87%'`, `'142'`, a `Semantics`/key for the week strip with 7 bars, and 5 recent rows. Assert the calendar `IconButton` exists by key `ValueKey('history-calendar-btn')`.
- [ ] 2. **Run — red:** `flutter test --timeout=90s test/ui/features/history/history_screen_test.dart` → FAIL (placeholder has no '12'/grid).
- [ ] 3. **Implement** the rewrite per contract. Hero card `surfaceLowest`, `Radii.xl`, `Shadows.cloud`. Hatched today bar via a `CustomPaint` stripe or `DecoratedBox` with a repeating gradient on `primarySoft`. Use `Spacing`/`Radii`/`IconSizes` tokens only — no raw px off the 4px grid.
- [ ] 4. **Run — green:** `flutter test --timeout=90s test/ui/features/history/history_screen_test.dart`.
- [ ] 5. Gates: `dart format .` · `flutter analyze` · `flutter test --timeout=90s`. Report for review.

**Skills:** `.agents/skills/flutter-add-widget-test`, `.agents/skills/flutter-build-responsive-layout`, `.agents/skills/flutter-fix-layout-issues`.

**Out of scope:** providers (Task 1); `showCalendarSheet`/calendar UI (Task 4 — reference the symbol, Task 4 creates it; if Task 4 not yet done, import will fail → Task 4 must precede green, OR stub `showCalendarSheet` in Task 4's file first). Milestone sheet (Task 5). Today/shell wiring (Task 6). Flame is gold, never teal.

**Acceptance:** Hero shows current + personal best + gold flame; week strip renders 7 state-colored bars with today hatched; stat grid shows all four; recent list shows 5 rows with adherence bars.

---

## Task 4: Calendar sheet

**Role:** ui

**Goal:** Month-grid Calendar sheet opened from Today's calendar button and the History calendar button: per-day color, tap-to-select detail, monthly kept/partial/missed summary, legend.

**Files:**
- Create: `lib/ui/features/history/views/calendar_sheet.dart`
- Test: `test/ui/features/history/calendar_sheet_test.dart`

**Contract:**

```dart
// lib/ui/features/history/views/calendar_sheet.dart
// Opens via the shared showCrudoSheet (lib/ui/core/widgets/sheet.dart).
Future<void> showCalendarSheet(BuildContext context) =>
    showCrudoSheet<void>(context, builder: (_) => const CalendarSheet());

// CalendarSheet: ConsumerStatefulWidget. Local state: DateTime _month (init today's
// month, UTC first-of-month), DateTime? _selected (init today).
// Body (inside a SheetScaffold-like container w/ grabber, maxHeight ~92%):
//   header: "LAST 30 DAYS" label + month title (e.g. "June 2026") + close X button.
//   day-of-week header row: M T W T F S S.
//   grid: ref.watch(monthGridProvider(_month)) → 7-col GridView/Wrap. Each non-null cell
//     a square button, bg dayStateColor(cell.state) (future/null → transparent, faded),
//     today (kind==today) inset ring (Border via boxShadow inset trick or Container ring),
//     selected → 2px outline ring. Tap non-future → setState(_selected = cell.date).
//   detail card (when _selected has a cell): "$done/$total meals", AdherenceBar, kcal,
//     "$adherencePct%".
//   monthly summary: KEPT (green count) / PARTIAL (yellow) / MISSED (red) from the cells.
//   legend: three swatches.
```

**Steps (TDD):**

- [ ] 1. **Failing test** — `calendar_sheet_test.dart`: pump a host with a button calling `showCalendarSheet`, override `monthGridProvider` to a seeded month (mix of green/yellow/red + future nulls), tap to open. Assert the month title text, 7 weekday headers, the right number of day buttons, KEPT/PARTIAL/MISSED counts match the seed, and tapping a green cell shows its detail ("5/5 meals", "100%").
- [ ] 2. **Run — red:** `flutter test --timeout=90s test/ui/features/history/calendar_sheet_test.dart` → FAIL "showCalendarSheet isn't defined".
- [ ] 3. **Implement** per contract. Reuse `showCrudoSheet`. Grid via `GridView.count(crossAxisCount: 7, shrinkWrap: true)` or a `Wrap`. Future cells `opacity` ~0.35, transparent bg. Colors via `dayStateColor`; red cell uses `errorSoft` bg + `error` text to match the prototype legend.
- [ ] 4. **Run — green:** `flutter test --timeout=90s test/ui/features/history/calendar_sheet_test.dart`.
- [ ] 5. Gates: `dart format .` · `flutter analyze` · `flutter test --timeout=90s`. Report for review.

**Skills:** `.agents/skills/flutter-add-widget-test`, `.agents/skills/flutter-build-responsive-layout`, `.agents/skills/flutter-fix-layout-issues`.

**Out of scope:** providers (Task 1); month paging beyond current month (optional polish, skip); Today/shell wiring (Task 6 calls `showCalendarSheet`). No 1px borders — rings via tonal `boxShadow`/`Container` per the no-line rule.

**Acceptance:** Grid colors each day by state with Mon-first alignment, today ringed, future faded; tapping a day shows its detail; summary counts match.

---

## Task 5: Milestone celebration sheet

**Role:** ui

**Goal:** One-shot celebration dialog shown when catch-up crosses 7/30/100, patterned on the prototype `StreakRiskSheet` (centered modal, gold flame circle, headline, primary CTA).

**Files:**
- Create: `lib/ui/features/history/views/milestone_sheet.dart`
- Test: `test/ui/features/history/milestone_sheet_test.dart`

**Contract:**

```dart
// lib/ui/features/history/views/milestone_sheet.dart
// Centered modal (showDialog) — NOT a bottom sheet (matches StreakRiskSheet layout).
// Returns when dismissed so the caller can chain multiple crossings in order.
Future<void> showMilestoneSheet(BuildContext context, int milestone) =>
    showDialog<void>(context: context, builder: (_) => _MilestoneDialog(milestone: milestone));

// _MilestoneDialog: Dialog(backgroundColor transparent) > Container surfaceLowest,
// Radii.lg, Shadows.cloud, padding Spacing.lg, centered column:
//   gold Icons.local_fire_department (IconSizes.xl) in an 80px circle bg gold @ 15%.
//   "STREAK MILESTONE" label (gold).
//   headline "$milestone-day streak!" (CrudoText.title/headline).
//   body: a short congratulatory line (e.g. "$milestone days locked in. Keep the fire going.").
//   PrimaryCta "Keep going" → Navigator.pop(context).
```

**Steps (TDD):**

- [ ] 1. **Failing test** — `milestone_sheet_test.dart`: pump a host button calling `showMilestoneSheet(context, 7)`, tap, assert finds "7-day streak!", "STREAK MILESTONE", a gold flame icon, and a "Keep going" button; tapping it pops the dialog (gone after pump).
- [ ] 2. **Run — red:** `flutter test --timeout=90s test/ui/features/history/milestone_sheet_test.dart` → FAIL "showMilestoneSheet isn't defined".
- [ ] 3. **Implement** per contract. Reuse `PrimaryCta` (`lib/ui/core/widgets/primary_cta.dart`). Flame circle = `Container(width:80,height:80, shape circle, color gold.withValues(alpha:0.15))`.
- [ ] 4. **Run — green:** `flutter test --timeout=90s test/ui/features/history/milestone_sheet_test.dart`.
- [ ] 5. Gates: `dart format .` · `flutter analyze` · `flutter test --timeout=90s`. Report for review.

**Skills:** `.agents/skills/flutter-add-widget-test`, `.agents/skills/flutter-fix-layout-issues`.

**Out of scope:** the listener that calls this (Task 6); storing milestones (S12 already doesn't); the actual `StreakRiskSheet` (S14). Gold flame, never teal; never pure black text.

**Acceptance:** `showMilestoneSheet(ctx, n)` shows a centered gold-flame dialog reading "$n-day streak!" with a working "Keep going" dismiss.

---

## Task 6: Wire the trigger + Today entry points

**Role:** ui

**Goal:** The critical S12 unblock. Mount `streakCatchUpProvider` in `AppShell` so catch-up runs at app-open + every rollover and persists; surface crossed milestones via `showMilestoneSheet`. Wire `StreakChip.onTap` → History tab and Today's calendar button → `showCalendarSheet`.

**Files:**
- Modify: `lib/ui/core/widgets/app_shell.dart` (add the `ref.listen`)
- Modify: `lib/ui/features/today/views/today_screen.dart:137` (StreakChip `onTap`) and `:108-109` (`onCalendarTap`)
- Test: `test/ui/features/history/catchup_trigger_test.dart`, and extend Today wiring assertions in `test/ui/features/today/` if a screen test exists (else add `today_wiring_test.dart`).

**Contract:**

```dart
// app_shell.dart — inside AppShell.build, before returning the Scaffold:
ref.listen<AsyncValue<List<int>>>(streakCatchUpProvider, (prev, next) {
  final milestones = next.valueOrNull;
  if (milestones == null || milestones.isEmpty) return;
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    final ctx = navigatorContext;            // a BuildContext valid for dialogs
    if (ctx == null || !ctx.mounted) return;
    for (final m in milestones) {            // ascending, in order
      await showMilestoneSheet(ctx, m);
    }
  });
});
// ref.listen activates the provider → build() runs at app-open and re-runs when
// todayProvider advances (TodayScreen already pokes refresh on resume + midnight).
// Use the shell's own context (a Builder under the Navigator) for `navigatorContext`.

// today_screen.dart:
//   StreakChip(count: streak, onTap: () => context.go('/history')),
//   _AppBar(onCalendarTap: () => showCalendarSheet(context), ...)   // replaces toast stub
```

**Steps (TDD):**

- [ ] 1. **Failing test** — `catchup_trigger_test.dart`: pump `AppShell` (or a minimal `MaterialApp.router` with the real shell) inside a `ProviderScope` overriding `dayRepositoryProvider`/`streakRepositoryProvider`/`profileRepositoryProvider` with fakes and `clockProvider` fixed. Seed a streak with `lastCountedDay = today-3` and a green day at today-1 so catch-up locks it and crosses no milestone in one variant, and crosses 7 in another (seed current 6). Assert: after pump+settle the streak repo received a `save` (current advanced, day persisted), and in the crossing variant the milestone dialog ("7-day streak!") appears. Separate assert: `StreakChip.onTap` routes to `/history` (find History content) and the calendar button opens the sheet.
- [ ] 2. **Run — red:** `flutter test --timeout=90s test/ui/features/history/catchup_trigger_test.dart` → FAIL (no listener; chip onTap null; calendar shows toast not sheet).
- [ ] 3. **Implement** the `ref.listen` in `AppShell` (wrap nav in a `Builder` to get a dialog-capable context) and the two Today wirings. Import `streakCatchUpProvider`, `showMilestoneSheet`, `showCalendarSheet`, `go_router`.
- [ ] 4. **Run — green:** `flutter test --timeout=90s test/ui/features/history/catchup_trigger_test.dart` (+ the Today wiring test).
- [ ] 5. Gates: `dart format .` · `flutter analyze` · `flutter test --timeout=90s` (full suite — this touches shared shell + Today). Report for review.

**Skills:** `.agents/skills/flutter-riverpod`, `.agents/skills/flutter-add-widget-test`, `.agents/skills/flutter-setup-declarative-routing`.

**Out of scope:** changing `StreakCatchUp`/`catchUp` logic (S12 — read-only); the midnight timer (TodayScreen already owns it); adding new streak math. Don't double-show milestones — rely on `build()` returning a fold's crossings once (idempotent re-run returns `[]`).

**Acceptance:** Launching the app with elapsed unlocked days runs catch-up (days + streak persisted); a crossing shows the milestone dialog once; the streak chip opens the History tab; Today's calendar button opens the Calendar sheet.

---

## Self-review

- **Spec coverage:** trigger→T6; History tab (hero/week/grid/recent)→T3 over T1 providers; Calendar sheet→T4; milestone sheet→T5; color invariants (frozen vs live)→T1+T2; chip/calendar wiring→T6. All spec sections mapped.
- **Type consistency:** `DayCellKind` (locked/today/future), `WeekCell`/`HistoryStats`/`RecentDay`/`CalendarCell`, `dayStateColor`, `AdherenceBar`, `showCalendarSheet`, `showMilestoneSheet`, `streakProvider`/`weeklyAdherenceProvider`/`historyStatsProvider`/`recentDaysProvider`/`monthGridProvider` used identically across tasks.
- **Ordering note:** T3 references `showCalendarSheet` (T4). Run order T1→T2→T4→T3→T5→T6, OR keep T3 before T4 and have the worker add a one-line `showCalendarSheet` stub in T4's file during T3. Recommend executing **T1, T2, T4, T5, T3, T6** so every symbol exists when referenced.
- **No placeholders:** every code step shows real contracts; no TODO/TBD.
