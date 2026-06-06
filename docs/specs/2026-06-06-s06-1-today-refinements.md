# Spec — S06.1: Today Screen Refinements

**Status:** approved (design) · **Spec S06.1 (ui + domain)** · depends on S06 (today screen) · scope = four refinements to the shipped Today tab: deferred + animated intake updates, snooze re-based on scheduled time, meal-sheet button parity with the `meal.jsx` design, card quick-complete. Visual target: `docs/design/prototype/screens/meal.jsx` (action tiles + footer), dimensions snapped to `design_system.md §5` tokens.

## Goal

Polish the daily loop: intake numbers stop jumping mid-checklist and animate once the sheet closes; snooze means "push the meal back from when it's due" instead of "N minutes from right now"; the meal sheet gains the designed Snooze/Swap tiles and dynamic footer; the meal card's status circle becomes a one-tap complete/undo control.

## Decisions (brainstorm 2026-06-06)

- **Defer = freeze display, not persistence.** Every checklist toggle still persists immediately through `DayController` (no buffered batch — app kill loses nothing, status stays derived). Only the intake hero's *rendering* freezes while a meal sheet is open; on close it animates to the live value.
- **Animation scope = everything in the hero.** Kcal number rolls, macro bars grow, ring sweeps — one shared duration (~500 ms) + curve (`easeOutCubic`), feels like one motion.
- **Snooze base = `max(now, scheduledTime)`.** One rule covers both cases: future meal (15:00 snoozed at 10:00, +15 m) → 15:15; past-due meal (15:00 snoozed at 15:40, +15 m) → 15:55. Bound unchanged: min(next meal by time, end-of-day midnight). Presets stay 10/15/20/30 m relative to the base. Re-snooze recomputes from the same base (overwrite semantics, S05) — never compounds on a prior snooze; the preset labels show the resulting time, so the outcome is always visible before committing.
- **Snooze sheet shows the outcome.** Preset tiles display the resulting time, and an info line in the sheet reads "We'll remind you at {time}" for the selected preset (copy is forward-looking — actual notifications are S14).
- **Meal sheet buttons = `meal.jsx` parity.** Tile row (Snooze + Swap meal) above a floating footer (Skip secondary + dynamic primary). The old Ate it / Skip / Snooze text row is removed.
- **Swap tile is a design stub.** Renders per the prototype (icon, title, "Pick from library" subtitle), tap = no-op, `// TODO(S08)`. Real swap needs the meal-library picker (S08).
- **Dynamic primary CTA:** 0 items checked → "Mark Done" (= `markAllEaten` + close) · some checked → "Save Partial" (= close; already persisted) · all checked → "Mark Done" (= close).
- **Card status circle = quick complete.** Tap on a non-done meal (upcoming / snoozed / skipped / partial) → `markAllEaten`. Tap on a done meal → undo via new domain op `unmarkAll`. No confirm dialog, no snackbar. Card *body* tap still opens the sheet.
- **`unmarkAll` leaves `skippedAt` / `snoozedUntil` untouched** (consistent with the S05 rule that marking ops never touch the stamps; derivation lets checked win). Round-trip is exact: skipped → circle-tap → done → circle-tap → skipped again.
- **Skipped-meal quick-complete needs no un-skip op** — `markAllEaten` over a skipped meal derives done because checked wins.
- **Today only.** Circle is inert on past/future days (existing lock rules); freeze/animate concerns today's hero only (other days never change while visible).

## Domain (`lib/domain/`)

- **`Day.unmarkAll(mealId, now, today)`** — new lifecycle op beside `markAllEaten`: clears `checkedAt` on every item of the meal. Guards: `_ensureUnlocked(today)`, meal must exist, throws `StateError` if no item is checked (nothing to undo — UI pre-checks). Never touches `skippedAt`/`snoozedUntil`.
- **`meal_lifecycle.dart`:**
  - `snoozeBaseFor(day, mealId, now)` — returns `max(now, localInstantAt(day.date, meal.time))` as UTC. UI presets = base + duration; `Day.snoozeMeal` keeps its `until` signature and existing guards (base ≥ now ⇒ `until > now` always holds).
  - `canUnmarkMeal(day, mealId, now, today)` predicate — day unlocked + any item checked.
- No other domain changes. `maxSnoozeUntilFor` unchanged.

## State layer (`lib/ui/features/today/view_models/`)

- **`intakeFreezeProvider`** — `@riverpod Notifier<Macros?>` (consumed macros; kcal derives from `Macros.kcal`). `freeze(consumed)` on meal-sheet open, `clear()` on close. Null = render live.
- **`DayController`:** new ops `unmarkAll(mealId)` (mirrors existing op plumbing: predicate pre-check → Day op → `repo.save`) and `snooze` now receives `until` computed by the UI from `snoozeBaseFor`. Everything else untouched.

## UI (`lib/ui/features/today/views/` + core)

- **`IntakeCard`:** reads `intakeFreezeProvider`; frozen snapshot wins over live values when set. Kcal number, the 3 macro bars and the ring each animate value changes via `TweenAnimationBuilder` (shared 500 ms / `easeOutCubic` constants). Bars/ring animate fraction; kcal rolls as an int.
- **`MealSheet`:**
  - Opens → `intakeFreezeProvider.freeze(...)`; whenComplete → `clear()` (single wrapper around the existing `showCrudoSheet` call so every dismiss path unfreezes).
  - Body unchanged (checklist, live toggles).
  - **Action tiles** (per `meal.jsx` lines 91–106): 2-column grid, each tile = icon (20, primary) + bold title + muted subtitle, `surface-low` background, `r-md` radius, paddings snapped to grid. Snooze tile (subtitle "15m delay, no further") opens `SnoozeSheet`; rendered disabled (`Opacities.disabled`, like snooze presets) when `canSnoozeMeal` fails — both tiles always present so the layout never reflows. Swap tile (subtitle "Pick from library") always enabled-looking, tap no-op, `// TODO(S08)`.
  - **Footer:** Skip (`SecondaryAction`, iff `canSkipMeal`) + dynamic `PrimaryCta` per the decision table above. Read-only mode (past day) unchanged: no tiles, no footer.
- **`SnoozeSheet`:** presets compute `until = snoozeBaseFor(...) + preset`; tile shows duration *and* resulting local time ("+15 m → 15:15"); disabled when `until > maxSnoozeUntilFor`. Info line under the presets: "We'll remind you at {time}" reflecting the currently selected preset (the sheet already tracks a selection for its "Snooze {m}m" CTA).
- **`MealCard` (core):** status circle wrapped in a tap target ≥ 44 px (Semantics: "Mark {meal} eaten" / "Undo {meal}") with an `onStatusTap` callback param (null = inert, keeps core widget dumb). TodayScreen wires it: done → `unmarkAll`, else → `markAllEaten`; only for today. Snoozed-time strikethrough display already exists (S06) — unchanged.
- New dimensional tokens (tile padding/gaps) only if existing `Spacing` tokens don't already cover them; any new size → `dimensions.dart` + `design_system.md §5`, same change.

## Tests

- **Domain unit** (`package:checks`): `unmarkAll` clears stamps, preserves `skippedAt`/`snoozedUntil`, throws on locked day / unknown meal / nothing checked; `snoozeBaseFor` future-meal vs past-due cases; round-trip skipped → done → skipped derivation.
- **Controller unit** (`ProviderContainer`): `unmarkAll` persists + re-emits; freeze provider lifecycle (freeze → toggle ops → live value changes, frozen snapshot stable → clear).
- **Widget:** footer label switches across 0/some/all checked; Mark Done with 0 checked marks all + closes; circle tap completes and undoes; circle inert on past/future days; swap tile renders + tap is a no-op; snooze preset shows resulting time + info line; intake card renders frozen value while sheet open and animates after close (pump frames, assert intermediate ≠ final).
- Existing S06 tests touching the old footer (Ate it / Skip / Snooze row) updated.

## Acceptance

- Checking items in the sheet leaves the hero static; closing the sheet rolls kcal/bars/ring to the new totals in one motion.
- Circle-tap on a card completes the meal instantly (hero animates immediately), second tap undoes it; skipped meals complete and revert correctly.
- Snoozing a 15:00 meal at 10:00 with +15 m yields 15:15 (card strikethrough shows it); snoozing at 15:40 yields 15:55; presets show resulting times; info line states the reminder time.
- Meal sheet visually matches `meal.jsx` (tiles + footer) with all dimensions on tokens.
- `dart format .` clean · `flutter analyze` clean · `flutter test` green · architecture test green.

## Out of scope

Real swap / meal-library picker (S08) · notifications incl. actual snooze reminders (S14) · gram-level partial (post-MVP) · animating other screens' numbers · undo snackbar/toast ceremony.

## Skills

`flutter-riverpod-arch` · `dart-add-unit-test` · `flutter-add-widget-test` · `flutter-expert` (const, semantics on the new tap targets) · `dart-migrate-to-checks-package`.
