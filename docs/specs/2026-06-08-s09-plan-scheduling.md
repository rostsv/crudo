# Spec — S09: Plan logic + scheduling

**Status:** approved (design) · **Spec S09 (logic)** · depends on S02 (`PlanTemplate`/`PlanSlot`/`MealTemplate` models, validation framework), S03 (`PlanTemplateRepository`, `IdGenerator`), S05 (materialization engine: `buildDayFromPlan`, `mealSnapshotFromTemplate`, `selectPlanForDate`) · scope = pure-domain plan-scheduling service (cross-plan weekday conflicts + override, ≥1-plan delete guard, uncovered-weekday detection, clone plan & meal). **No widgets, no controllers, no repository changes** — S10 (plans list+detail) and S11 (create-plan flow) consume these functions and own all UI/Riverpod wiring.

## Goal

Lock the plan-scheduling integrity rules as pure, unit-tested domain functions before any plan UI is built: which plan runs on which weekday, what happens when two plans fight over a weekday, the floor of "always ≥1 plan", which weekdays end up with no plan, and how a plan/meal is duplicated. These are the hard invariants S10/S11 must not be able to violate.

## Decisions (brainstorm 2026-06-08)

- **Substrate already shipped (S05).** `selectPlanForDate(plans, date)` (active-plan-for-weekday, lowest-id tiebreak), `buildDayFromPlan` (snapshot-on-schedule read path), `mealSnapshotFromTemplate` (the single unchecked-snapshot factory), and per-plan validators (`blankName`, `duplicateWeekday` *within* a plan, `invalidWeekday` range, `emptyActivePlan`) all exist. S09 adds the **cross-plan** layer those leave open.
- **Scope = conflict + ≥1-plan + clone + gap-detection.** Pure domain only. Clone/duplicate (plan & meal, product §51) is in scope here so S10/S11 wrap it directly. No `PlanController` — that belongs to S10 ([logic]/[ui] split preserved).
- **Override = STEAL.** Assigning weekday `W` to plan `B` while active plan `A` already claims `W`: on Override, `W` is removed from `A.days` and set on `B`. Preserves the invariant **each weekday is claimed by ≤1 active plan** — `selectPlanForDate` then never faces a real conflict (its lowest-id tiebreak stays a defensive backstop only). `A` may end up with `days == []` (unassigned, still exists).
- **Conflict detection returns the map.** `detectConflicts` names which other active plans claim which proposed weekdays, so S10's conflict modal can list "Rest Day will lose Mon, Wed" before the user confirms. Override itself is a plain strip.
- **≥1-plan rule = count only.** `canDeletePlan(plans) => plans.length > 1`. Any plan counts (active or inactive). The repo's doc-comment already defers this to S09 ("application-level logic, not enforced here"). Repo contract unchanged — the guard is a pure pre-check S10 calls before `repo.delete`.
- **Weekday gaps are allowed.** A weekday with no active plan materializes an empty day (`selectPlanForDate` → `null` → `buildDayFromPlan(null, …)`). Full 7-day coverage is **never** required.
- **Uncovered-weekday warning is non-blocking.** Leaving plan-detail with gaps shows a confirm ("Mon, Thu have no plan — leave anyway?", Leave/Stay — same PopScope pattern as S08's discard-changes). Never a hard block. S09 supplies only the detection (`uncoveredWeekdays`); the confirm UI is S10.
- **Clone clears days.** `clonePlan` copies name + slots but starts `days: []` — no instant conflict with the source ("build once, clone, tweak"); the user assigns weekdays afterward. Clone keeps `active: src.active` (harmless with no days). Slots get fresh ids so editing the clone never aliases the source. Name = `"{src.name} copy"`.
- **Clone is pure** — takes a `String Function() newId` callback (the `buildDayFromPlan` pattern); the domain never imports `IdGenerator`.
- **Snapshot-on-schedule + template-edits-future-only = no new code.** Already satisfied end-to-end: `day_controller` (S06) eager-persists today (= the snapshot write), leaves future days as pure previews (template edits flow through until first edit detaches them — S08 CoW), and treats persisted past days as immutable. S09 documents this as locked and references the existing engine/controller tests; it adds none.

## Domain layer (`lib/domain/services/plan_scheduling.dart`)

New pure-Dart file (no `package:flutter`, Riverpod, or data imports). `selectPlanForDate` **relocates** here from `meal_lifecycle.dart`, with an `export 'plan_scheduling.dart' show selectPlanForDate;` shim left in `meal_lifecycle.dart` so `day_controller`'s existing import keeps working (S08 relocation precedent). Its existing tests move to `plan_scheduling_test.dart`.

### Conflict detection + override

```dart
/// One weekday a proposed assignment would steal from another active plan.
/// A record (not a class/freezed): free structural equality for test
/// assertions, no codegen in a pure service file. weekday is 0=Mon … 6=Sun;
/// otherPlanName carries the S10 modal copy.
typedef WeekdayConflict = ({int weekday, String otherPlanId, String otherPlanName});

/// Active OTHER plans (id != forPlanId) currently claiming any of [proposedDays].
/// One entry per (weekday, conflicting plan). Empty → save freely.
/// Inactive plans never conflict (they claim no weekday).
List<WeekdayConflict> detectConflicts(
  List<PlanTemplate> plans, {
  required String forPlanId,
  required List<int> proposedDays,
});

/// STEAL: strip every proposedDay from all OTHER plans, set forPlanId.days = proposedDays.
/// Returns only the plans that CHANGED (including forPlanId) for the controller to persist.
/// Order/identity of unchanged plans untouched.
List<PlanTemplate> applyOverride(
  List<PlanTemplate> plans, {
  required String forPlanId,
  required List<int> proposedDays,
});
```

`forPlanId` may be a plan not yet in `plans` (new plan mid-create) — `detectConflicts` simply scans the others; `applyOverride` includes a freshly-constructed `forPlan` only if present in the input list (S10/S11 pass the in-flight plan in the list when needed). `proposedDays` is assumed already valid per the per-plan validators (unique, 0..6); `applyOverride` does not re-validate.

### ≥1-plan guard

```dart
bool canDeletePlan(List<PlanTemplate> plans) => plans.length > 1;
```

### Uncovered-weekday detection

```dart
/// Weekdays 0..6 claimed by NO active plan, ascending. [] = full coverage.
List<int> uncoveredWeekdays(List<PlanTemplate> plans);
```

### Clone

```dart
/// new id · name "{src.name} copy" · days: [] · active: src.active
/// · slots: fresh ids, same mealTemplateId + time.
PlanTemplate clonePlan(PlanTemplate src, {required String Function() newId});

/// new id · name "{src.name} copy" · copies tags + foods unchanged.
MealTemplate cloneMeal(MealTemplate src, {required String Function() newId});
```

## Out of scope (explicit)

- Any widget, screen, route, or Riverpod provider/controller — S10/S11.
- `PlanTemplateRepository` changes — contract is final; S09 functions are pure pre-checks/transforms the controller composes around existing CRUD.
- Per-plan field validation — already in `validators.dart` (S09 conflict logic is cross-plan, deliberately *not* in the single-entity validator).
- New `selectPlanForDate` behavior — relocated verbatim, not changed.
- Snapshot/materialization code — already shipped (S05/S06/S08).

## Tests (`test/domain/services/plan_scheduling_test.dart`)

Pure functions, no providers, no repo.

- **`detectConflicts`:** no overlap → `[]` · single plan claims one proposed day → one entry (right weekday/id/name) · two plans claim different proposed days → two entries · a plan claiming a day NOT in proposedDays → ignored · `forPlanId` itself excluded (re-assigning its own days isn't a conflict) · inactive conflicting plan → ignored · multi-weekday overlap → one entry per (weekday, plan).
- **`applyOverride`:** stolen weekday removed from the other plan · `forPlanId.days` set exactly to proposedDays · other plan emptied to `[]` when it only held stolen days · only changed plans returned (incl. forPlanId) · unchanged plans absent from the result · no conflict → result is just forPlanId updated.
- **`canDeletePlan`:** `length 0 → false` · `1 → false` · `2 → true` · inactive plans still counted.
- **`uncoveredWeekdays`:** full coverage → `[]` · one plan covering Mon–Fri → `[5,6]` · no active plans → `[0..6]` · inactive plan's days don't count as covered · result ascending + deduped across overlapping plans.
- **`clonePlan`:** `days` cleared to `[]` · name == `"{src} copy"` · new plan id ≠ source · every slot gets a fresh id ≠ source slot ids · slot `mealTemplateId`/`time` preserved · `active` preserved.
- **`cloneMeal`:** new id ≠ source · name == `"{src} copy"` · tags + foods copied equal to source.
- **`selectPlanForDate`:** existing cases relocated unchanged (covers weekday match, no-match → null, inactive ignored, lowest-id tiebreak).

## Acceptance

- `flutter analyze` clean; `flutter test --timeout=90s` green.
- `plan_scheduling.dart` imports only `package:freezed_annotation` (for the models) and other domain files — architecture test (domain depends on nothing external) still passes.
- `meal_lifecycle.dart` re-exports `selectPlanForDate`; `day_controller` builds unchanged (no import edit needed).
- Every function above has the listed unit coverage.
- No file under `lib/ui/`, `lib/application/`, or `lib/data/` is touched.
