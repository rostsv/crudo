# Meal detail — draft-logging model + visual redesign

## Goal
Rework the meal detail screen (`lib/ui/features/meals/views/meal_detail_screen.dart`) around a **draft** logging model and a cleaner layout:

- Checking an ingredient is a **draft** (local UI state only). Nothing persists until the user taps **Log meal**, which commits the whole draft in one op. Leaving the screen without logging discards the draft.
- Remove the "N OF M EATEN" text and the top progress bar entirely.
- Ingredient rows go back to **flat** (no card background); keep the gray-border check circle; on check the item name gets **struck through + muted**, animated.
- A single **progress line under the ingredients list**: gray track that fills green as items are checked in the draft, with a smooth fill transition.
- Bottom bar = one wide **Log meal** button + a **kebab (⋮)** icon that opens a bottom sheet with **Snooze / Swap meal / Skip**. The old inline Snooze/Swap chips are removed.

## Architecture / tech stack
Flutter + Riverpod (codegen), DDD domain in `lib/domain/`. Meal check state lives on `ScheduledMeal.meal.items[i].checkedAt`; meal status is **derived** from checked items (`lib/domain/services/meal_status.dart`). `DayController` (`lib/ui/features/today/view_models/day_controller.dart`) wraps domain ops and persists via `dayRepositoryProvider`. UI guards go through `runDayOp` (`_run` in the screen). Design system is law: 4px grid + named tokens (`docs/design_system.md`); **no raw `Border`** — surfaces / painted rings / progress tracks only.

### Consequence of the draft model (intended)
Because checks no longer persist per-tap, an in-progress meal shows **no** progress on the Today screen and its derived status stays `upcoming`/`overdue` until **Log meal** commits. Header status label + `canSnooze`/`canSkip`/`canEdit` gates keep reading **persisted** state (correct — they gate against what's saved, not the draft). Only the checkboxes, the fill line, and Log-meal enablement read the draft.

## How to work
Implement task-by-task, top to bottom. Each task = an AGENTS.md-style contract + steps. Read `AGENTS.md`, `docs/design_system.md`, and the `.agents/skills` each task names before starting it. TDD with real values — no placeholders. **Do not commit** — finish each task with "report done for review"; integration + commits are handled after review.

---

## Task 1 — Domain + controller: `logMeal` commit op

**Role:** Domain engineer.
**Goal:** One atomic op that sets a meal's checked items to exactly a given index set — the commit path for the draft.
**Files:** `lib/domain/day/day.dart`, `lib/ui/features/today/view_models/day_controller.dart`, tests under `test/domain/day/` and `test/ui/features/today/view_models/`.
**Skills:** `dart-add-unit-test`, `dart-use-pattern-matching`, `dart-run-static-analysis`.

**Contract:**
```dart
// lib/domain/day/day.dart
/// Commits a draft: every item whose index ∈ [checked] is stamped (items
/// already checked keep their earlier stamp — mirror markAllEaten); every
/// other item is cleared to null. Single transition. Locked/past days reject
/// via _ensureUnlocked. Empty [checked] clears all (caller gates this).
Day logMeal(String mealId, Set<int> checked, DateTime now, DateTime today);

// lib/ui/features/today/view_models/day_controller.dart
Future<void> logMeal(String mealId, Set<int> checked) =>
    _apply((d, now, today) => d.logMeal(mealId, checked, now, today));
```
Reuse the existing `_ensureUnlocked` / `_mealById` / `_withMeal` helpers and the `now.toUtc()` stamp convention (see `markAllEaten`, `unmarkAll`).

**Acceptance:**
- Domain tests: `logMeal` with a subset stamps exactly those indices and clears the rest; already-checked items in the set keep their original earlier stamp; out-of-range index throws `StateError`; a locked/past day throws.
- Controller test: `logMeal` persists through the repository (mirror the existing `markAllEaten`/`unmarkAll` controller tests).
- `flutter test --timeout=90s` green; `flutter analyze` clean.

**Out of scope:** any UI; touching `markAllEaten`/`unmarkAll`/`checkItem` behavior; adherence/status derivation (unchanged — it already reads stamps).

---

## Task 2 — Meal detail screen: draft state + visual redesign

**Role:** Flutter UI engineer.
**Goal:** Convert the screen to a draft model and apply the new ingredient/list visuals. (Bottom-bar actions menu is Task 3.)
**Files:** `lib/ui/features/meals/views/meal_detail_screen.dart`, `test/ui/features/meals/views/meal_detail_screen_test.dart`, and any Today-screen tests that assert on old labels (`test/ui/features/today/views/today_screen_test.dart`).
**Skills:** `flutter-riverpod`, `flutter-expert`, `flutter-add-widget-test`, `flutter-fix-layout-issues`, `dart-run-static-analysis`.

**Contract / behavior:**
- Convert `MealDetailScreen` to a `ConsumerStatefulWidget`. Hold `Set<int> _draft`, seeded from the meal's currently-persisted checked indices when the meal first resolves (re-opening an already-logged meal shows its checks). Guard against re-seeding on every rebuild.
- Ingredient tap (today only) toggles the index in `_draft` via `setState` — **no** controller call, nothing persists.
- **Remove** the "N OF M EATEN" `Text` (key `eaten-count`) and the top `_EatenProgress` bar (the one above the list).
- Ingredient rows: **flat** — drop the `surfaceLow`/`Radii.md` card container and the inter-card `Spacing.sm` gaps added previously; back to a padded `Row` on the 4px grid. Keep the gray-border check circle (`_CheckCircle` + `_CheckRingPainter(colors.outline)`) and its existing check animation.
- On checked, the ingredient **name** animates to `decoration: TextDecoration.lineThrough` + `colors.onSurfaceMut` (use `AnimatedDefaultTextStyle` with `Durations.fast` / `Curves.easeOut`, matching the check-circle animation). Unchecked = normal `CrudoText.body` / `colors.onSurface`. Base the checked state on `_draft`, not `item.checked`.
- **Progress line under the list:** a thin (height 4, 4px grid) rounded track (`colors.surfaceLow`) that fills `colors.primary` proportional to `_draft.length / items.length`, animating the fill smoothly on change (e.g. `TweenAnimationBuilder<double>` driving an `AnimatedFractionallySizedBox`/fractional width, `Durations.fast`/`Curves.easeOut`). Reuse/repurpose `_EatenProgress` for this — it must be the ONLY progress indicator. Placed after the ingredient rows.
- **Log meal** button: label always `'Log meal'`; `enabled: _draft.isNotEmpty`; when enabled, `onPressed` calls `ctrl.logMeal(mealId, _draft)` through `_run(context, ..., pop: true)` (commit + close); disabled otherwise. Keep the `Skip` `SecondaryAction` for now (Task 3 moves it into the sheet).
- **Check-all** toggle (`check-all-toggle`, today only): toggles the **draft** only — fill `_draft` with all indices when not all drafted, clear it when all drafted. No controller call. Keep it near where the count used to be (or above the list). Keep `Semantics`.

**Acceptance:**
- Checking ingredients does not persist (no repo write) until Log meal; a widget test verifies the controller/repo is untouched on check and that `logMeal` fires with the drafted set on Log meal.
- Log meal disabled with empty draft, enabled after a check.
- Check-all fills/clears the draft (line + circles update) without persisting.
- No `eaten-count` text, no top progress bar; exactly one fill line present and it animates.
- Checked name is struck-through + muted.
- `flutter test --timeout=90s` green (update/rewrite the old assertions on `Mark Done`/`Save Partial`/`eaten-count`); `flutter analyze` clean; `dart format` clean.

**Out of scope:** the actions bottom sheet / kebab (Task 3); domain changes (Task 1); changing snooze/swap/skip eligibility logic.

---

## Task 3 — Bottom actions: kebab + `MealActionsSheet`

**Role:** Flutter UI engineer.
**Goal:** Move Snooze / Swap meal / Skip out of the inline chips into a bottom sheet triggered by a kebab next to Log meal.
**Files:** `lib/ui/features/meals/views/meal_detail_screen.dart`, a new `lib/ui/features/meals/views/meal_actions_sheet.dart`, `test/ui/features/meals/views/meal_detail_screen_test.dart` (+ a sheet test).
**Skills:** `flutter-riverpod`, `flutter-expert`, `flutter-add-widget-test`, `dart-run-static-analysis`.

**Contract:**
- Bottom bar (today only) = a wide **Log meal** button + a **kebab** `IconButton` (`Icons.more_vert`, key `meal-actions`) that opens `showCrudoSheet` with `MealActionsSheet(date:, mealId:)`.
- **Remove** the inline `_ActionChip`/`_ActionTile` row (Snooze/Swap) from the body and the `Skip` `SecondaryAction` from the bottom bar — all three now live in the sheet.
- `MealActionsSheet` lists three actions as thin rows (icon left + label, matching the design system), preserving the exact existing behavior and eligibility from the current screen:
  - **Snooze** (key `action-snooze`): enabled = `canSnoozeMeal`; enabled → open `SnoozeSheet`; disabled → `snoozeIneligibilityReason` toast. Render at `Opacities.disabled` when disabled (never hide).
  - **Swap meal** (key `action-swap`): enabled = `canEdit` (`canEditMealContent`); enabled → open `SwapSheet`; disabled → `_guardMessage` toast.
  - **Skip** (key `action-skip`): enabled = `canSkipMeal`; runs `ctrl.skipMeal(mealId)` through the `runDayOp` guard, then closes the sheet and the screen (`pop`).
- Route all mutating ops through the same `runDayOp` guard the screen uses (`_guardMessage`). The sheet reads `dayControllerProvider(date)` for gating, same as the screen does today.

**Acceptance:**
- Kebab opens the sheet; sheet shows all three actions with correct enabled/disabled state and disabled-tap toasts.
- Snooze/Swap open their existing sheets; Skip skips + closes.
- No inline Snooze/Swap chips or bottom Skip button remain.
- `flutter test --timeout=90s` green (migrate the `tile-snooze`/`tile-swap` tests to the sheet keys); `flutter analyze` + `dart format` clean.

**Out of scope:** changing SnoozeSheet/SwapSheet internals; snooze/skip/edit domain logic.
