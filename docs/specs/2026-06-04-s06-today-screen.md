# Spec — S06: Today Screen

**Status:** approved (design) · **Spec S06 (ui)** · depends on S03 (repos + seed), S04 (shell, core widgets, sheets/toast), S05 (lifecycle engine) · scope = the Today tab: day-resolution controller (S05 §4.3 read path), intake hero card, macro bars, streak chip (stub), week day-picker, meal list, marking sheet, snooze sheet. Visual target: `docs/design/prototype/screens/today.jsx` + `sheets.jsx` (SnoozeSheet), dimensions snapped to `design_system.md §5` tokens.

## Goal

First real feature screen: the daily loop. User sees today's plan materialized, marks meals (full / partial / skip / snooze), watches intake fill up. Controller implements the S05 copy-on-write read path — the contract S05 deliberately left to S06.

## Decisions (brainstorm 2026-06-04)

- **Marking = tap card → inline bottom sheet** (S04 `showCrudoSheet`): ingredient checklist + Ate it / Skip / Snooze. Full marking incl. partial ships now; S08's `mealDetail` route replaces the sheet later.
- **Snooze in scope.** Snooze sheet per prototype (10/15/20/30 min presets); presets exceeding `maxSnoozeUntil` disabled. Snoozed meal's card shows original time struck-through + new time to its right.
- **Swap (`replaceMeal`) deferred to S08** — needs the meal-library picker.
- **Streak chip = stub provider.** Chip UI per prototype reads `streakCountProvider` (wraps `StreakRepository`, seed default 0). S12 swaps the engine in; zero UI rework. Tap = no-op.
- **Week strip = current week only** (Mon–Sun pills, today highlighted). Far navigation = calendar sheet, S13.
- **Future days fully read-only** (preview; consumed = 0; no ops — the detach/CoW edit path arrives with S08 swap). **Past days read-only** (repo snapshot frozen; repo miss → empty locked "no data" day). Sheet opens read-only for past days.
- **Extras in:** end-of-day nudge card (today only) · calendar appbar icon → "coming soon" toast (S13) · greeting with profile `displayName`, time-of-day aware.
- **Controller = `AsyncNotifier.family` keyed by date** (`dayControllerProvider(date)`); `selectedDateProvider` + `todayProvider` drive which instance the UI watches.
- **Riverpod codegen arrives now:** `riverpod_annotation` + `riverpod_generator` installed in S06 (deferred from S02; AGENTS.md locked `@riverpod` style — view_models use it from day one). `custom_lint`/`riverpod_lint` still deferred (analyzer constraint).
- **Dev demo seed:** in-memory meal-template + plan-template seed (dev flavor) so the screen is demoable before S09/S11 exist. 4 meal templates composed from the S03 food seed + 1 active everyday plan. Prod stays unseeded (empty rest day + empty state).
- **Fats macro color = new bronze token** `#9A7E4E` (prototype's inline value, promoted): `--bronze` in `app.css` + `CrudoColors.bronze`. Closes the pending fats-color design item.
- **Intake number type = new `CrudoText.stat`** (56px/-2/w700) — mirrors `app.css` `.streak-num`, which the prototype's intake figure reuses inline.

## State layer (`lib/ui/features/today/view_models/`)

All providers `@riverpod` codegen style.

- **`todayProvider`** — `Notifier<DateTime>`, emits the UTC day-label (`localDateLabel(now)`, S05 convention). Re-evaluates on app resume (`WidgetsBindingObserver`) and on a timer scheduled for next local midnight (`endOfDayLocal`). The observer/tick wiring lives in a small widget-layer hook (`TodayScreen` registers it), not in the provider itself — the provider exposes a `refresh()`.
- **`selectedDateProvider`** — `Notifier<DateTime>`; defaults to today; listens to `todayProvider` and snaps back to the new today on rollover.
- **`dayControllerProvider(date)`** — `AsyncNotifier` family. `build(date)` = S05 §4.3:
  1. `watch` the `DayRepository.watchByDate(date)` stream → snapshot present = authoritative, emit it (never rebuilt).
  2. Miss + `date` before today → `Day(date: date)` empty locked day.
  3. Miss + today/future → read active plans, meal templates, foods (raw lists) → `selectPlanForDate` → `buildDayFromPlan(plan, date, idGenerator.newId, templates, foods)`.
  4. `date == today` → `repo.save(day)` **before** emitting (eager persist; ids minted exactly once; stream re-emits it as the snapshot).
  5. Future date → emit preview, no persist. Preview rebuilds when watched template/food repos change (template edits flow through).
  - **Ops** (methods on the today instance only): `checkItem` / `uncheckItem` / `markAllEaten` / `skipMeal` / `snoozeMeal(until)` — pre-check `meal_lifecycle` predicates (`canSkipMeal`, `canSnoozeMeal`, `isDayLocked`), apply the Day op, `repo.save`; the watch stream re-emits. Wrapped in `AsyncValue.guard`; a guard rejection surfaces `showCrudoToast`.
- **`streakCountProvider`** — exposes `StreakRepository.watch()` → `streak.current`. Stub data (0) until S12.
- No new domain code. UI derivations reuse pure fns: `plannedMacros` / `consumedMacros` / `plannedKcal` / `consumedKcal`, `deriveMealStatus(meal, dayDate, now)`, `isDayLocked`, `maxSnoozeUntil`.

## Screen composition (`lib/ui/features/today/views/`)

- **Appbar:** muted date label ("Friday, June 4") over greeting headline ("Good morning, {displayName}" — morning/afternoon/evening by local hour; no name → "Good morning"). Right: 42-token `IconBtn` calendar → `showCrudoToast(context, 'Calendar — coming soon')`.
- **Week strip** (`DayStrip`, feature-local): 7 `DayPill`s Mon–Sun of the current week; shows day number + first letter; selected = active style per prototype; today gets distinct marker when not selected. Tap → `selectedDateProvider`.
- **Intake hero card** (`IntakeCard`): "Today's Intake" label; `consumedKcal` huge (`CrudoText.stat`) + "/{plannedKcal} kcal"; right: 72 `MacroRing` (value = consumed/planned, flame icon center). Below: 3 macro bars — Protein (primary) / Carbs (gold) / Fats (bronze) — `consumed/planned` g each, 4-high bars (prototype's 3px snapped to grid). Non-today: consumed renders per snapshot (past) or 0 (future preview).
- **Streak chip** (`StreakChip`): gradient pill inset at hero's top-right, gold flame, "{n}-day streak" from `streakCountProvider`.
- **Meals section:** "Meals" headline + "{done}/{total} complete · {partial} partial" (partial part only when > 0). List of core `MealCard`s sorted by time. Status via `deriveMealStatus`.
- **`MealCard` core change:** optional `snoozedTimeLabel` param — when set, `timeLabel` renders struck-through with the snoozed time to its right. (Field-parity rules: plain params only.)
- **Nudge card** (`NudgeCard`): today only; icon circle + bold line + body. Copy derived from consumed %, remaining (non-done, non-skipped) meal count; hidden when day complete or empty.
- **Empty state:** rest day (no plan covers the date / prod unseeded) → centered muted "Rest day — nothing planned." Past repo-miss → "No data for this day."

## Sheets (`views/`)

- **Meal sheet** (`MealSheet`, via `showCrudoSheet` + `SheetScaffold`): meal name, time · tag, per-ingredient checklist rows (name, grams, kcal; check toggles `checkItem`/`uncheckItem` live — status re-derives instantly). Footer actions: **Ate it** (PrimaryCta → `markAllEaten`, closes) · **Skip** (secondary → `skipMeal`, closes) · **Snooze** (visible iff `canSnoozeMeal`; opens snooze sheet). Read-only mode (past day): checklist visible, all controls disabled. Not openable for future days (cards not tappable).
- **Snooze sheet** (`SnoozeSheet`): per prototype — "Commitment / Snooze, then eat." header, 4 preset tiles 10/15/20/30 min, presets where `now + m > maxSnoozeUntil(day, mealId, now)` disabled, Cancel + "Snooze {m}m" CTA → `snoozeMeal(until)`.

## Dev demo seed

`InMemoryMealTemplateRepository` + `InMemoryPlanTemplateRepository` get optional `seed:` lists wired in `di.dart` behind the dev flavor (`appConfigProvider`): 4 meal templates (breakfast/lunch/snack/dinner built from existing S03 food-seed ids) + 1 `PlanTemplate` (active, days 1–7, 4 slots at 08:00/12:30/16:00/19:00). Removed/replaced at S09–S11.

## Tests

- **Controller unit** (`ProviderContainer` + in-memory repos): snapshot wins over template; preview not persisted; today eager-persists exactly once (stable `ScheduledMeal.id`s across reads); past miss → empty locked day; ops persist + stream re-emit; guard rejection → no write; rollover (todayProvider change) re-resolves; plan/template edit reflected in future preview but not in persisted today.
- **Widget** (fake/overridden providers): intake card numbers + ring value; macro bar values; all 4 `MealCard` statuses; snoozed-time strikethrough render; week-strip selection switches day; future day read-only (no tap); past-day sheet read-only; checklist toggle drives status label; Ate it / Skip flows; snooze preset disabling; nudge copy variants; empty states; streak chip reads provider; greeting variants.
- Existing showcase placeholder test for Today updated/replaced.

## Acceptance

- Dev flavor boots into a populated Today: seeded plan materialized, eager-persisted; marking flows work end-to-end; intake + macros update live; snooze re-times the card with strikethrough; week strip navigates with correct read-only semantics.
- Read path honors S05 §4.3 verbatim (repo-hit wins · preview never persisted · today eager-persist).
- Visuals match `today.jsx`/`sheets.jsx` composition with all dimensions on tokens (new sizes → `dimensions.dart` + `design_system.md §5`).
- `dart format .` clean · `flutter analyze` clean · `flutter test` green · architecture test green.

## Out of scope

Meal detail route + swap/replaceMeal (S08) · custom food/library (S07) · plan editing (S09–S11) · real streak/adherence engine + streak sheet (S12) · calendar sheet + history (S13) · notifications incl. snooze side-effects (S14) · gram-level partial (post-MVP) · week paging in the strip · goldens.

## Skills

`flutter-riverpod-arch` · `dart-add-unit-test` · `flutter-add-widget-test` · `flutter-add-widget-preview` · `flutter-build-responsive-layout` · `flutter-expert` (const, semantics on tap targets) · `dart-migrate-to-checks-package`.
