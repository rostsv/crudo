# Plan — S09: Plan logic + scheduling

**Worker note:** Implements spec `docs/specs/2026-06-08-s09-plan-scheduling.md`. Pure-domain only — one new service file `lib/domain/services/plan_scheduling.dart` + its unit test. No widgets, no controllers, no repository changes. Read `.agents/skills/flutter-apply-architecture-best-practices` (domain depends on nothing external) and `.agents/skills/dart-add-unit-test` before Task 1. Run tasks in order; each ends at "report for review" — no commits.

**Goal:** Lock the cross-plan scheduling invariants as pure, unit-tested functions before any plan UI (S10/S11): weekday-conflict detection + steal-override, ≥1-plan delete guard, uncovered-weekday detection, and clone plan & meal.

## Decisions (brainstorm 2026-06-08 — do not re-litigate)

| Fork | Decision |
|---|---|
| Scope | Cross-plan conflict + override, ≥1-plan guard, uncovered-weekday detection, clone plan & meal. Pure domain. No controller (S10). |
| Override | **Steal** — strip the contested weekday from the other active plan; assign to the new one. Keeps "each weekday ≤1 active plan." |
| Conflict return | `detectConflicts` returns which other active plans claim which proposed weekdays (for S10's modal). Override is a plain strip. |
| ≥1-plan | `canDeletePlan(plans) => plans.length > 1`. Any plan counts (active or not). Repo unchanged — pure pre-check. |
| Weekday gaps | Allowed. Uncovered weekday → empty day (`selectPlanForDate` → null). Never require full coverage. |
| Gap warning | Non-blocking confirm in S10. S09 supplies only `uncoveredWeekdays` detection. |
| Clone days | `clonePlan` clears `days` to `[]` (no instant conflict); keeps `active`; fresh slot ids; name `"{src.name} copy"`. |
| Clone purity | `newId` callback param (the `buildDayFromPlan` pattern); domain never imports `IdGenerator`. |
| `selectPlanForDate` | **Relocated** from `meal_lifecycle.dart` into the new file, verbatim, with an `export … show selectPlanForDate;` shim so `day_controller`'s import is untouched. |
| Snapshot-on-schedule / future-only | No new code — already shipped (S05 `buildDayFromPlan`, S06 `day_controller`, S08 CoW). Not in this plan. |

## File changes (whole plan)

- **Create** `lib/domain/services/plan_scheduling.dart` — all S09 pure functions + relocated `selectPlanForDate`.
- **Modify** `lib/domain/services/meal_lifecycle.dart` — remove `selectPlanForDate` body; add `export 'plan_scheduling.dart' show selectPlanForDate;`.
- **Create** `test/domain/services/plan_scheduling_test.dart` — unit tests for every new function + the relocated `selectPlanForDate` group.
- **Modify** `test/domain/services/meal_lifecycle_test.dart` — remove the `selectPlanForDate` group (moves to the new test file).

Codegen: none (no `@freezed`/`@riverpod` touched — `WeekdayConflict` is a record typedef, the models already have generated parts).

---

## Task 1: Relocate selectPlanForDate into plan_scheduling.dart

**Role:** implement

**Goal:** Create the new pure-domain service file by moving the existing, tested `selectPlanForDate` into it and leaving an export shim — so the file is anchored on known-green code and `day_controller` keeps compiling unchanged. This is a refactor (move + shim + test move), not new behavior; verification is "everything still green."

**Files:**
- Create: `lib/domain/services/plan_scheduling.dart` — new file, imports `../plan/plan_template.dart`.
- Modify: `lib/domain/services/meal_lifecycle.dart` — delete the `selectPlanForDate` function (lines defining it, currently ~118–127) and its doc comment; add the export shim near the top (after the imports). Keep the `../plan/plan_template.dart` import (still used by `buildDayFromPlan`).
- Create: `test/domain/services/plan_scheduling_test.dart` — the relocated `selectPlanForDate` group + a local `_plan()` helper.
- Modify: `test/domain/services/meal_lifecycle_test.dart` — delete the `group('selectPlanForDate', …)` block only.

**Contract:**

```dart
// lib/domain/services/plan_scheduling.dart — opening
import '../plan/plan_template.dart';

/// The active plan covering [date]'s weekday (0=Mon…6=Sun). >1 match should
/// be impossible (S09 blocks weekday conflicts) — defensively the lowest id
/// wins, deterministically.
PlanTemplate? selectPlanForDate(List<PlanTemplate> plans, DateTime date) {
  final weekday = date.weekday - 1;
  final matches =
      plans.where((p) => p.active && p.days.contains(weekday)).toList()
        ..sort((a, b) => a.id.compareTo(b.id));
  return matches.isEmpty ? null : matches.first;
}
```

```dart
// lib/domain/services/meal_lifecycle.dart — add after the import block,
// so importers of meal_lifecycle (e.g. day_controller) still see the symbol:
export 'plan_scheduling.dart' show selectPlanForDate;
```

```dart
// test/domain/services/plan_scheduling_test.dart — relocated group verbatim,
// with a local minimal helper (the meal_lifecycle test's _plan() stays there
// for buildDayFromPlan; this file gets its own):
import 'package:checks/checks.dart';
import 'package:crudo/domain/plan/plan_slot.dart';
import 'package:crudo/domain/plan/plan_template.dart';
import 'package:crudo/domain/services/plan_scheduling.dart';
import 'package:flutter_test/flutter_test.dart';

// Tasks 2–4 add imports as their tests need them (meal_time, grams, enums,
// food_ref, meal_template). Keep the import list minimal per task to stay
// `flutter analyze`-clean between reviews.

PlanTemplate _plan({
  String id = 'p1',
  bool active = true,
  List<int> days = const [0, 1, 2, 3, 4], // Mon–Fri
  List<PlanSlot> slots = const [],
}) => PlanTemplate(id: id, name: 'Plan $id', days: days, active: active, slots: slots);

void main() {
  final thursday = DateTime.utc(2026, 6, 4); // Thursday
  final sunday = DateTime.utc(2026, 6, 7);

  group('selectPlanForDate', () {
    test('picks the active plan covering the weekday', () {
      check(selectPlanForDate([_plan()], thursday)).isNotNull();
    });
    test('null when no plan covers the weekday (rest day)', () {
      check(selectPlanForDate([_plan()], sunday)).isNull();
    });
    test('ignores inactive plans', () {
      check(selectPlanForDate([_plan(active: false)], thursday)).isNull();
    });
    test('defensive tie-break: lowest id wins', () {
      final picked = selectPlanForDate([_plan(id: 'p2'), _plan(id: 'p1')], thursday);
      check(picked!.id).equals('p1');
    });
  });
}
```

**Steps (TDD — here a verified refactor):**

- [ ] 1. Create `plan_scheduling.dart` with the import + `selectPlanForDate` (verbatim from the contract).
- [ ] 2. In `meal_lifecycle.dart`: delete the `selectPlanForDate` function + its doc comment; add `export 'plan_scheduling.dart' show selectPlanForDate;` after the imports.
- [ ] 3. Create `plan_scheduling_test.dart` with the relocated group (contract above).
- [ ] 4. In `meal_lifecycle_test.dart`: delete the `group('selectPlanForDate', …)` block (and any now-unused helper *only if* nothing else references it — `_plan()` is shared with `buildDayFromPlan`, so leave it).
- [ ] 5. **Run — green (no regressions):** `flutter test --timeout=90s test/domain/services/plan_scheduling_test.dart test/domain/services/meal_lifecycle_test.dart`. Both files pass; the moved group runs from its new home.
- [ ] 6. Gates: `dart format .` · `flutter analyze` (confirm `day_controller.dart` still resolves `selectPlanForDate` via the export — no import edit needed) · `flutter test --timeout=90s`. Report for review.

**Skills:** `.agents/skills/flutter-apply-architecture-best-practices` · `.agents/skills/dart-run-static-analysis`

**Out of scope:** Any new function (Tasks 2–4). Do not change `selectPlanForDate`'s logic. Do not touch `buildDayFromPlan` or its tests. No file under `lib/ui`, `lib/application`, `lib/data`.

**Acceptance:** New file owns `selectPlanForDate`; `meal_lifecycle.dart` re-exports it; `flutter analyze` clean; full suite green; `day_controller` unchanged.

---

## Task 2: Weekday-conflict detection + steal-override

**Role:** implement

**Goal:** Add the cross-plan conflict layer: `WeekdayConflict` record, `detectConflicts` (what a proposed assignment would steal), and `applyOverride` (perform the steal, return only changed plans).

**Files:**
- Modify: `lib/domain/services/plan_scheduling.dart` — append the typedef + two functions.
- Modify: `test/domain/services/plan_scheduling_test.dart` — append `group('detectConflicts')` and `group('applyOverride')`.

**Contract:**

```dart
/// One weekday a proposed assignment would steal from another active plan.
/// A record (not a class): free structural equality for tests, no codegen.
/// weekday is 0=Mon…6=Sun; otherPlanName carries the S10 modal copy.
typedef WeekdayConflict = ({int weekday, String otherPlanId, String otherPlanName});

/// Active OTHER plans (id != forPlanId) currently claiming any of [proposedDays].
/// One entry per (weekday, conflicting plan), in plan-then-weekday order.
/// Empty → save freely. Inactive plans never conflict.
List<WeekdayConflict> detectConflicts(
  List<PlanTemplate> plans, {
  required String forPlanId,
  required List<int> proposedDays,
}) {
  final proposed = proposedDays.toSet();
  return [
    for (final p in plans)
      if (p.id != forPlanId && p.active)
        for (final d in p.days)
          if (proposed.contains(d))
            (weekday: d, otherPlanId: p.id, otherPlanName: p.name),
  ];
}

/// STEAL: strip every proposedDay from all OTHER plans; set forPlanId.days =
/// proposedDays. Returns only the plans that CHANGED (incl. forPlanId if its
/// day-set differs). Unchanged plans are absent; input order preserved among
/// the changed. forPlanId not present in [plans] → only the strips returned.
List<PlanTemplate> applyOverride(
  List<PlanTemplate> plans, {
  required String forPlanId,
  required List<int> proposedDays,
}) {
  final proposed = proposedDays.toSet();
  final changed = <PlanTemplate>[];
  for (final p in plans) {
    if (p.id == forPlanId) {
      if (!_sameWeekdays(p.days, proposedDays)) {
        changed.add(p.copyWith(days: [...proposedDays]));
      }
    } else {
      final kept = p.days.where((d) => !proposed.contains(d)).toList();
      if (kept.length != p.days.length) changed.add(p.copyWith(days: kept));
    }
  }
  return changed;
}

bool _sameWeekdays(List<int> a, List<int> b) {
  if (a.length != b.length) return false;
  final sa = a.toSet();
  return b.every(sa.contains) && sa.length == b.toSet().length;
}
```

**Steps (TDD):**

- [ ] 1. **Failing tests** — append to `plan_scheduling_test.dart`:

```dart
  group('detectConflicts', () {
    test('no overlap → empty', () {
      final plans = [_plan(id: 'a', days: [0, 1])];
      check(detectConflicts(plans, forPlanId: 'b', proposedDays: [2, 3])).isEmpty();
    });
    test('one other plan claims a proposed day → one entry', () {
      final plans = [_plan(id: 'a', days: [0, 1, 2])];
      final c = detectConflicts(plans, forPlanId: 'b', proposedDays: [2, 5]);
      check(c).deepEquals([(weekday: 2, otherPlanId: 'a', otherPlanName: 'Plan a')]);
    });
    test('forPlanId own days are not a conflict', () {
      final plans = [_plan(id: 'a', days: [0, 1, 2])];
      check(detectConflicts(plans, forPlanId: 'a', proposedDays: [0, 1])).isEmpty();
    });
    test('inactive conflicting plan ignored', () {
      final plans = [_plan(id: 'a', active: false, days: [2])];
      check(detectConflicts(plans, forPlanId: 'b', proposedDays: [2])).isEmpty();
    });
    test('two plans conflicting on different days → two entries', () {
      final plans = [_plan(id: 'a', days: [1]), _plan(id: 'c', days: [3])];
      final c = detectConflicts(plans, forPlanId: 'b', proposedDays: [1, 3]);
      check(c.length).equals(2);
      check(c).contains((weekday: 1, otherPlanId: 'a', otherPlanName: 'Plan a'));
      check(c).contains((weekday: 3, otherPlanId: 'c', otherPlanName: 'Plan c'));
    });
  });

  group('applyOverride', () {
    test('steals the contested weekday from the other plan', () {
      final plans = [_plan(id: 'a', days: [0, 1, 2]), _plan(id: 'b', days: [])];
      final changed = applyOverride(plans, forPlanId: 'b', proposedDays: [2]);
      final a = changed.firstWhere((p) => p.id == 'a');
      final b = changed.firstWhere((p) => p.id == 'b');
      check(a.days).deepEquals([0, 1]);
      check(b.days).deepEquals([2]);
    });
    test('returns only changed plans', () {
      final plans = [
        _plan(id: 'a', days: [0]),
        _plan(id: 'b', days: []),
        _plan(id: 'c', days: [5]), // untouched
      ];
      final changed = applyOverride(plans, forPlanId: 'b', proposedDays: [0]);
      check(changed.map((p) => p.id).toList()).deepEquals(['a', 'b']);
    });
    test('other plan emptied when it only held the stolen day', () {
      final plans = [_plan(id: 'a', days: [2]), _plan(id: 'b', days: [])];
      final a = applyOverride(plans, forPlanId: 'b', proposedDays: [2])
          .firstWhere((p) => p.id == 'a');
      check(a.days).isEmpty();
    });
    test('no real change → empty result', () {
      final plans = [_plan(id: 'b', days: [3])];
      check(applyOverride(plans, forPlanId: 'b', proposedDays: [3])).isEmpty();
    });
  });
```

- [ ] 2. **Run — red:** `flutter test --timeout=90s test/domain/services/plan_scheduling_test.dart`. Expected: compile error / `detectConflicts` undefined.
- [ ] 3. **Implement** — append the contract (typedef + `detectConflicts` + `applyOverride` + `_sameWeekdays`) to `plan_scheduling.dart`.
- [ ] 4. **Run — green:** `flutter test --timeout=90s test/domain/services/plan_scheduling_test.dart`.
- [ ] 5. Gates: `dart format .` · `flutter analyze` · `flutter test --timeout=90s`. Report for review.

**Skills:** `.agents/skills/dart-add-unit-test` · `.agents/skills/dart-use-pattern-matching` (record syntax) · `.agents/skills/dart-run-static-analysis`

**Out of scope:** `canDeletePlan`/`uncoveredWeekdays` (Task 3), clone (Task 4). No UI/repo/controller. Do not re-validate `proposedDays` (per-plan validators already cover uniqueness/range).

**Acceptance:** `detectConflicts` and `applyOverride` behave per the test matrix; analyze clean; full suite green.

---

## Task 3: ≥1-plan guard + uncovered-weekday detection

**Role:** implement

**Goal:** Add the two small integrity helpers: `canDeletePlan` (the ≥1-plan floor) and `uncoveredWeekdays` (gap detection feeding S10's non-blocking leave-page warning).

**Files:**
- Modify: `lib/domain/services/plan_scheduling.dart` — append two functions.
- Modify: `test/domain/services/plan_scheduling_test.dart` — append two groups.

**Contract:**

```dart
/// The ≥1-plan rule: the last plan can never be deleted. Any plan counts
/// (active or inactive). Pure pre-check — the repo stays unaware (S09 owns it).
bool canDeletePlan(List<PlanTemplate> plans) => plans.length > 1;

/// Weekdays 0..6 claimed by NO active plan, ascending and deduped.
/// [] = full coverage. Inactive plans cover nothing.
List<int> uncoveredWeekdays(List<PlanTemplate> plans) {
  final covered = <int>{
    for (final p in plans)
      if (p.active) ...p.days,
  };
  return [for (var d = 0; d < 7; d++) if (!covered.contains(d)) d];
}
```

**Steps (TDD):**

- [ ] 1. **Failing tests** — append:

```dart
  group('canDeletePlan', () {
    test('zero plans → false', () => check(canDeletePlan([])).isFalse());
    test('one plan → false', () => check(canDeletePlan([_plan()])).isFalse());
    test('two plans → true', () {
      check(canDeletePlan([_plan(id: 'a'), _plan(id: 'b')])).isTrue();
    });
    test('inactive plans still count toward the floor', () {
      check(canDeletePlan([_plan(id: 'a'), _plan(id: 'b', active: false)])).isTrue();
    });
  });

  group('uncoveredWeekdays', () {
    test('full coverage → empty', () {
      check(uncoveredWeekdays([_plan(days: [0, 1, 2, 3, 4, 5, 6])])).isEmpty();
    });
    test('Mon–Fri plan → weekend uncovered', () {
      check(uncoveredWeekdays([_plan(days: [0, 1, 2, 3, 4])])).deepEquals([5, 6]);
    });
    test('no active plans → all seven uncovered', () {
      check(uncoveredWeekdays([_plan(active: false, days: [0, 1, 2, 3, 4])]))
          .deepEquals([0, 1, 2, 3, 4, 5, 6]);
    });
    test('overlapping plans dedupe coverage', () {
      final plans = [_plan(id: 'a', days: [0, 1, 2]), _plan(id: 'b', days: [2, 3])];
      check(uncoveredWeekdays(plans)).deepEquals([4, 5, 6]);
    });
  });
```

- [ ] 2. **Run — red:** `flutter test --timeout=90s test/domain/services/plan_scheduling_test.dart`. Expected: `canDeletePlan` undefined.
- [ ] 3. **Implement** — append the two functions to `plan_scheduling.dart`.
- [ ] 4. **Run — green:** `flutter test --timeout=90s test/domain/services/plan_scheduling_test.dart`.
- [ ] 5. Gates: `dart format .` · `flutter analyze` · `flutter test --timeout=90s`. Report for review.

**Skills:** `.agents/skills/dart-add-unit-test` · `.agents/skills/dart-run-static-analysis`

**Out of scope:** Clone (Task 4). The leave-page warning UI (S10). No repo/controller/UI.

**Acceptance:** Both helpers match the matrix; analyze clean; full suite green.

---

## Task 4: Clone plan & meal

**Role:** implement

**Goal:** Add pure clone helpers for plan and meal templates (product §51 "build once, clone, tweak"). Plan clone clears weekdays and re-mints slot ids; both take a `newId` callback.

**Files:**
- Modify: `lib/domain/services/plan_scheduling.dart` — append two functions + the `../plan/plan_slot.dart` and `../meal/meal_template.dart` imports at the top of the file.
- Modify: `test/domain/services/plan_scheduling_test.dart` — append two groups + a `_SeqIds` helper and a `meal_template`/`food_ref` import.

**Contract:**

```dart
// add to the import block of plan_scheduling.dart:
import '../meal/meal_template.dart';
import '../plan/plan_slot.dart';

/// Duplicate a plan as an editable starting point: new id, name "{src} copy",
/// days CLEARED to [] (no instant weekday conflict — the user reassigns),
/// active preserved, every slot re-minted (fresh ids never alias the source).
PlanTemplate clonePlan(PlanTemplate src, {required String Function() newId}) =>
    PlanTemplate(
      id: newId(),
      name: '${src.name} copy',
      days: const [],
      active: src.active,
      slots: [
        for (final s in src.slots)
          PlanSlot(id: newId(), mealTemplateId: s.mealTemplateId, time: s.time),
      ],
    );

/// Duplicate a meal template: new id, name "{src} copy", tags + food refs
/// copied unchanged (a fresh recipe the user can tweak independently).
MealTemplate cloneMeal(MealTemplate src, {required String Function() newId}) =>
    MealTemplate(
      id: newId(),
      name: '${src.name} copy',
      tags: [...src.tags],
      foods: [...src.foods],
    );
```

**Steps (TDD):**

- [ ] 1. **Failing tests** — append (add `_SeqIds` helper near the top of the test file's helpers, plus imports `package:crudo/domain/meal/meal_template.dart`, `package:crudo/domain/food/food_ref.dart`, `package:crudo/domain/shared/enums.dart`, `package:crudo/domain/shared/grams.dart`). Verified shapes: `MealTime(int minutesOfDay)` is single-positional (480 = 08:00); `FoodRef.grams` is a `Grams` value object; `MealTag` values are `{breakfast, lunch, dinner, snack, preWorkout, postWorkout}`.

```dart
class _SeqIds {
  int _n = 0;
  String next() => 'gen-${_n++}';
}

  group('clonePlan', () {
    test('clears days and copies name with suffix', () {
      final ids = _SeqIds();
      final src = _plan(id: 'p1', days: [0, 1, 2]);
      final clone = clonePlan(src, newId: ids.next);
      check(clone.days).isEmpty();
      check(clone.name).equals('Plan p1 copy');
      check(clone.id == 'p1').isFalse();
      check(clone.active).equals(src.active);
    });
    test('re-mints fresh slot ids, preserves mealTemplateId + time', () {
      final ids = _SeqIds();
      final src = _plan(id: 'p1', slots: const [
        PlanSlot(id: 's1', mealTemplateId: 'm1', time: MealTime(480)),
      ]);
      final clone = clonePlan(src, newId: ids.next);
      check(clone.slots.single.id == 's1').isFalse();
      check(clone.slots.single.mealTemplateId).equals('m1');
      check(clone.slots.single.time).equals(const MealTime(480));
    });
  });

  group('cloneMeal', () {
    test('new id, suffixed name, copies tags + foods', () {
      final ids = _SeqIds();
      const src = MealTemplate(
        id: 'm1',
        name: 'Breakfast',
        tags: [MealTag.breakfast],
        foods: [FoodRef(foodId: 'egg', grams: Grams(100))],
      );
      final clone = cloneMeal(src, newId: ids.next);
      check(clone.id == 'm1').isFalse();
      check(clone.name).equals('Breakfast copy');
      check(clone.tags).deepEquals([MealTag.breakfast]);
      check(clone.foods).deepEquals([const FoodRef(foodId: 'egg', grams: Grams(100))]);
    });
  });
```

- [ ] 2. **Run — red:** `flutter test --timeout=90s test/domain/services/plan_scheduling_test.dart`. Expected: `clonePlan` undefined.
- [ ] 3. **Implement** — append the two imports + two functions to `plan_scheduling.dart`.
- [ ] 4. **Run — green:** `flutter test --timeout=90s test/domain/services/plan_scheduling_test.dart`.
- [ ] 5. Gates: `dart format .` · `flutter analyze` · `flutter test --timeout=90s`. Report for review.

**Skills:** `.agents/skills/dart-add-unit-test` · `.agents/skills/flutter-apply-architecture-best-practices` · `.agents/skills/dart-run-static-analysis`

**Out of scope:** No clone wiring into any controller/UI (S10/S11). No repo changes. Do not change `PlanTemplate`/`PlanSlot`/`MealTemplate` models.

**Acceptance:** `clonePlan` clears days + re-mints slot ids; `cloneMeal` copies tags + foods with a new id; analyze clean; full suite green; `plan_scheduling.dart` imports only domain files + `freezed_annotation` (architecture test passes).
