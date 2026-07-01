# Done-meal guards — Log-only-when-changed + confirm on undo

## Goal
Two behavior refinements around the draft-logging model (no visual redesign):

1. **Log meal only when changed.** In the meal detail screen the "Log meal" button is currently enabled whenever the draft is non-empty. Change it to enable only when the **draft differs from the persisted checked set** — so re-opening an already-done meal (all boxes seeded checked) shows Log meal **disabled** until the user actually changes something.
2. **Confirm before undoing a done meal**, at **both** entry points:
   - Today card status circle (`today_screen.dart` `onStatusTap`) when it would `unmarkAll` a `done` meal.
   - Meal detail "Log meal" when the commit would drop a currently-**done** meal below done (fewer boxes than a full set).

## Architecture / tech stack
Flutter + Riverpod. Meal check state persists on `ScheduledMeal.meal.items[i].checkedAt`; a meal is **done** when `meal.meal.allChecked`. The draft lives in `MealDetailScreen` state (`Set<int> _draft`) and commits via `DayController.logMeal(mealId, Set<int>)`. The app's confirm idiom is **`showCrudoSheet<bool>` + `SheetScaffold`** (title · body · `PrimaryCta` + `SecondaryAction`) — see `_confirmDelete`/`_confirmDiscard` in `lib/ui/features/plans/views/plan_detail_screen.dart`. Reuse that idiom (do NOT introduce a Material `AlertDialog`). Design system is law; no raw `Border`.

## How to work
Task-by-task, top to bottom. Each task = contract + steps. Read `AGENTS.md`, `docs/design_system.md`, and the named `.agents/skills` first. TDD, real values. **Do not commit** — end each task with "report done for review".

---

## Task 1 — Log meal enabled only when the draft changed

**Role:** Flutter UI engineer.
**Goal:** Disable "Log meal" unless the draft differs from what's persisted.
**Files:** `lib/ui/features/meals/views/meal_detail_screen.dart`, `test/ui/features/meals/views/meal_detail_screen_test.dart`.
**Skills:** `flutter-riverpod`, `flutter-expert`, `flutter-add-widget-test`, `dart-run-static-analysis`.

**Contract:**
- Compute `persistedChecked = { i : meal.meal.items[i].checked }` from the resolved meal (the same source the draft is seeded from).
- "Log meal" `enabled` = `!setEquals(_draft, persistedChecked)` (use `package:flutter/foundation.dart` `setEquals`). When enabled, `onPressed` still commits `ctrl.logMeal(mealId, _draft)` through `_run(..., pop: true)`; when disabled it's inert.
- No change to Check-all, per-item toggles, or the draft seeding.

**Acceptance:**
- Re-opening an all-checked (done) meal → Log meal disabled; unchecking one box → enabled; re-checking it back to the persisted set → disabled again.
- A fresh (nothing persisted) meal → disabled until ≥1 box checked.
- `flutter test --timeout=90s` green; `flutter analyze` + `dart format` clean.

**Out of scope:** the confirm dialog (Task 2); domain/controller changes.

---

## Task 2 — Confirm before undoing a done meal (both entry points)

**Role:** Flutter UI engineer.
**Goal:** Guard the two paths that take a `done` meal back to not-done with a confirm sheet.
**Files:** `lib/ui/features/today/views/today_screen.dart`, `lib/ui/features/meals/views/meal_detail_screen.dart`, their tests. Optionally a small shared helper `lib/ui/core/widgets/confirm_sheet.dart` if it reduces duplication (only if clean).
**Skills:** `flutter-riverpod`, `flutter-expert`, `flutter-add-widget-test`, `dart-run-static-analysis`.

**Contract:**
- **Confirm sheet** (app idiom): `showCrudoSheet<bool>` + `SheetScaffold`, title **"Undo this meal?"**, body **"It's marked done. Undoing removes it from today's progress."**, `PrimaryCta('Undo')` → pops `true`, `SecondaryAction('Cancel')` → pops `false`. Returns `Future<bool?>`.
- **Today entry point** (`today_screen.dart` `onStatusTap`): today the handler does `status == done ? ctrl.unmarkAll : ctrl.markAllEaten` inside `runDayOp`. Change the **done** branch to first `await` the confirm sheet; only run `unmarkAll` when it returns `true`. The `markAllEaten` branch (marking not-done → done) is unchanged — no confirm.
- **Detail entry point** (`meal_detail_screen.dart` Log meal `onPressed`): if the persisted meal is done (`meal.meal.allChecked`) AND the draft is not a full set (`_draft.length < items.length`), `await` the confirm sheet before `logMeal`; commit + pop only on `true`. If not currently done, commit directly (no confirm).

**Acceptance:**
- Today: tapping a done meal's circle opens the confirm sheet; Cancel leaves it done (no repo write), Undo clears it.
- Today: tapping an upcoming/partial meal's circle still marks all eaten with no confirm.
- Detail: logging a change that reduces a done meal prompts confirm (Cancel aborts, Undo commits + pops); logging a not-previously-done meal commits with no confirm.
- `flutter test --timeout=90s` green; `flutter analyze` + `dart format` clean.

**Out of scope:** hard-locking done meals; changing midnight/day-rollover locking; the toast redesign (separate plan).
