# Plan — S10: Plans list + detail (ui)

**Worker note:** implements `docs/specs/2026-06-08-s10-plans-list-detail.md`. Read that spec + `AGENTS.md` first. Read the named `.agents/skills/<x>` before each task. This is a **ui** slice over already-shipped pure domain (S09 `plan_scheduling.dart`) — no domain/data/repository edits. Every `flutter test` runs with `--timeout=90s`. Tasks end at "report for review"; Opus reviews the working tree and commits (no per-task `git commit`).

**Goal:** make the recurring weekday schedule browsable and editable — a `/plans` list (derived target, weekday chips, Today badge) and a pushed `/plans/:id` detail screen that renames, reassigns weekdays (steal-override on conflict), pauses/resumes (`active`), and deletes (≥1-plan guarded).

**Architecture:** one feature folder `lib/ui/features/plans/{view_models,views}`. A synchronous derived provider feeds the list; an `AsyncNotifier` family drives detail editing through a local `PlanDraft`. All integrity logic is delegated to the S09 pure functions (`detectConflicts`, `applyOverride`, `canDeletePlan`, `uncoveredWeekdays`, `selectPlanForDate`); the UI only composes them. Slots are read-only; no creation. Riverpod 3.x `@riverpod` codegen, `go_router`, `package:checks`.

## Decisions (settled in brainstorm — do not re-litigate)

| Fork | Decision |
|---|---|
| Slot editing | **Read-only** in S10. No add/remove/retime. No "Edit meals" affordance (dead until S11). |
| Creation | **None** in S10. No "New plan" CTA, no clone. Both → S11. |
| Conflict UX | Inline error-outline on colliding weekday chips + warning banner; **save-time** Override modal listing what each other plan loses → `applyOverride`. |
| `active` | Pause/resume. **Keep `days` dormant** on deactivate. `claimedDays = active ? days : const []` drives both inline highlight and save. Reactivate into a taken weekday → same Override modal. |
| Uncovered | Non-blocking confirm **after** a committed save when `uncoveredWeekdays` is non-empty. |
| Goal | Profile-level (`Prefs.goal`); no per-plan goal. Derived list subtitle only. |
| List provider | **Synchronous derived** `@riverpod` combining the S06 stream providers (`planTemplatesProvider`, `mealTemplatesProvider`, `foodsProvider`, `profileProvider`) + `todayProvider`. |

## File changes (whole plan)

- Create `lib/ui/features/plans/view_models/plan_draft.dart` — `PlanDraft`, `PlanRowVm`, `SlotVm`, `SaveOutcome` (Task 1).
- Create `lib/ui/features/plans/view_models/plans_list.dart` (+ `.g.dart`) — `plansList` derived provider (Task 2).
- Create `lib/ui/features/plans/view_models/plan_detail_controller.dart` (+ `.g.dart`) — `PlanDetailController` (Task 3).
- Create `lib/ui/features/plans/views/plan_detail_screen.dart` + `lib/routing/app_router.dart` (Modify: add `/plans/:id`) (Task 4).
- Rewrite `lib/ui/features/plans/views/plans_screen.dart`; create `lib/ui/features/plans/views/plan_list_card.dart` (Task 5).
- Tests under `test/ui/features/plans/`.

---

## Task 1: Plan view-model types (PlanDraft / PlanRowVm / SlotVm / SaveOutcome)

**Role:** implement

**Goal:** the pure, Flutter-free-ish view-model layer the controllers and widgets share: an editable `PlanDraft` (name/days/active + read-only slots) with `claimedDays`/`canSave`/`isDirtyFrom`/copy helpers, plus the list-row and save-outcome records.

**Files:**
- Create: `lib/ui/features/plans/view_models/plan_draft.dart`
- Test: `test/ui/features/plans/view_models/plan_draft_test.dart`

**Contract:**

```dart
import 'package:crudo/domain/plan/plan_template.dart';
import 'package:crudo/domain/services/plan_scheduling.dart'; // WeekdayConflict
import 'package:crudo/domain/shared/enums.dart';            // Goal
import 'package:crudo/domain/shared/meal_time.dart';         // MealTime

/// Read-only display data for one plan slot. S10 shows slots, never edits them.
typedef SlotVm = ({String mealName, MealTime time, int kcal});

/// One row of the plans list — all display data resolved up front.
/// days/goal/kcal/mealCount drive the subtitle + weekday chips; isToday is
/// `this == selectPlanForDate(plans, today)`.
typedef PlanRowVm = ({
  String id,
  String name,
  List<int> days, // 0=Mon…6=Sun, dormant-inclusive (a paused plan keeps its days)
  Goal goal,
  int kcal,
  int mealCount,
  bool active,
  bool isToday,
});

/// Result of PlanDetailController.save(). committed:false carries the pending
/// conflicts (no write happened); committed:true carries the post-save
/// uncovered weekdays for the advisory confirm.
typedef SaveOutcome = ({
  bool committed,
  List<WeekdayConflict> conflicts,
  List<int> uncovered,
});

/// Editable detail draft. name/days/active are mutable via copy helpers;
/// slots are resolved once and shown read-only.
class PlanDraft {
  const PlanDraft({
    required this.name,
    required this.days,
    required this.active,
    required this.slots,
  });

  final String name;
  final List<int> days; // 0=Mon…6=Sun
  final bool active;
  final List<SlotVm> slots;

  factory PlanDraft.from(PlanTemplate p, List<SlotVm> slots) => PlanDraft(
    name: p.name,
    days: [...p.days],
    active: p.active,
    slots: slots,
  );

  /// Weekdays this plan actually claims — none while paused.
  List<int> get claimedDays => active ? days : const [];

  bool get canSave => name.trim().isNotEmpty;

  /// Dirty vs the persisted plan (slots can't change, so they're not compared).
  bool isDirtyFrom(PlanTemplate p) =>
      name.trim() != p.name ||
      !_sameWeekdays(days, p.days) ||
      active != p.active;

  PlanDraft withName(String v) => _copy(name: v);
  PlanDraft withActive(bool v) => _copy(active: v);

  /// Add the weekday if absent, else remove it. Result kept ascending.
  PlanDraft toggleDay(int weekday) {
    final next = days.contains(weekday)
        ? [for (final d in days) if (d != weekday) d]
        : ([...days, weekday]..sort());
    return _copy(days: next);
  }

  PlanDraft _copy({String? name, List<int>? days, bool? active}) => PlanDraft(
    name: name ?? this.name,
    days: days ?? this.days,
    active: active ?? this.active,
    slots: slots,
  );
}

bool _sameWeekdays(List<int> a, List<int> b) {
  if (a.length != b.length) return false;
  final sa = a.toSet();
  return sa.length == b.toSet().length && b.every(sa.contains);
}
```

**Steps (TDD):**

- [ ] 1. **Failing test** — `plan_draft_test.dart`. Assertions (use `package:checks`):
  - `claimedDays` == `days` when `active`; `== const []` when `!active`.
  - `canSave` false for `'   '`, true for `'Cut'`.
  - `toggleDay(2)` adds Wed (ascending) when absent; removes it when present.
  - `withName('X')` / `withActive(false)` change only that field, slots preserved by identity.
  - `isDirtyFrom`: false for an unchanged draft built via `PlanDraft.from`; true after `withName`, after `toggleDay`, after `withActive`; **order-insensitive** on days (`[0,2]` vs `[2,0]` → not dirty).
  - `PlanDraft.from` copies `days` into a new list (mutating the draft's list never touches the source plan — assert via toggle).
- [ ] 2. **Run — red:** `flutter test --timeout=90s test/ui/features/plans/view_models/plan_draft_test.dart` → "Target of URI doesn't exist" / `PlanDraft` undefined.
- [ ] 3. **Implement** the contract above verbatim.
- [ ] 4. **Run — green:** same command.
- [ ] 5. Gates: `dart format .` · `flutter analyze` · `flutter test --timeout=90s`. Report.

**Skills:** `.agents/skills/dart-add-unit-test`, `.agents/skills/dart-migrate-to-checks-package`, `.agents/skills/flutter-expert`.

**Out of scope:** providers, widgets, any domain edit.

---

## Task 2: Plans list provider (`plansList`)

**Role:** implement

**Goal:** a synchronous derived provider that combines plans + meal templates + foods + profile goal + today into `List<PlanRowVm>` — kcal summed via `mealTemplateMacros`, `isToday` from `selectPlanForDate`.

**Files:**
- Create: `lib/ui/features/plans/view_models/plans_list.dart`
- Test: `test/ui/features/plans/view_models/plans_list_test.dart`
- Codegen: `dart run build_runner build` (new `@riverpod`)

**Contract:**

```dart
import 'package:crudo/domain/food/food.dart';
import 'package:crudo/domain/meal/meal_template.dart';
import 'package:crudo/domain/plan/plan_template.dart';
import 'package:crudo/domain/services/nutrition.dart';        // mealTemplateMacros
import 'package:crudo/domain/services/plan_scheduling.dart';  // selectPlanForDate
import 'package:crudo/domain/shared/enums.dart';
import 'package:crudo/ui/features/today/view_models/today_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'plan_draft.dart';

part 'plans_list.g.dart';

/// Derived list rows. Watches the S06 stream providers (immediate emit on
/// listen, so loading is transient) + todayProvider. Empty until plans arrive.
@riverpod
List<PlanRowVm> plansList(Ref ref) {
  final plans =
      ref.watch(planTemplatesProvider).valueOrNull ?? const <PlanTemplate>[];
  final templates = {
    for (final t in ref.watch(mealTemplatesProvider).valueOrNull ??
        const <MealTemplate>[])
      t.id: t,
  };
  final foods = {
    for (final f in ref.watch(foodsProvider).valueOrNull ?? const <Food>[])
      f.id: f,
  };
  final goal =
      ref.watch(profileProvider).valueOrNull?.prefs.goal ?? Goal.maintain;
  final today = ref.watch(todayProvider);
  final todayPlanId = selectPlanForDate(plans, today)?.id;

  int kcalOf(PlanTemplate p) {
    var total = const Macros();
    for (final s in p.slots) {
      final mt = templates[s.mealTemplateId];
      if (mt == null) continue;
      total = total + mealTemplateMacros(mt, foods);
    }
    return total.kcal.round();
  }

  return [
    for (final p in plans)
      (
        id: p.id,
        name: p.name,
        days: p.days,
        goal: goal,
        kcal: kcalOf(p),
        mealCount: p.slots.length,
        active: p.active,
        isToday: p.id == todayPlanId,
      ),
  ];
}
```

> Import `Macros` — it comes through `nutrition.dart` (re-exported) or `package:crudo/domain/shared/macros.dart`; match whichever `nutrition.dart` uses. Confirm `profileProvider` exposes `UserProfile` with `.prefs.goal` (it does — `today_providers.dart`).

**Steps (TDD):**

- [ ] 1. **Failing test** — `plans_list_test.dart`. Build a `ProviderContainer` overriding the repo providers (`planTemplateRepositoryProvider`, `mealTemplateRepositoryProvider`, `foodRepositoryProvider`, `profileRepositoryProvider`) with in-memory impls seeded with: two plans (A active days `[0,2,4]` 2 slots, B active days `[5,6]` 0 slots), the referenced meal templates, foods, and a profile with `Goal.cut`; override `clockProvider`/`Today` so today is a Wednesday (weekday index 2). Assertions:
  - row count == 2.
  - row A `kcal` == Σ `mealTemplateMacros` of its slots (compute expected from the seed), `mealCount` == 2, `goal` == `Goal.cut`, `days` == `[0,2,4]`.
  - exactly row A `isToday == true` (covers Wed), B false.
  - no plan covers today (today = Sunday with A/B not claiming it) → all `isToday == false`. *(second container or pump a different `Today`.)*
  - inactive plan still present in rows with `active: false`.
- [ ] 2. **Run — red:** `flutter test --timeout=90s test/ui/features/plans/view_models/plans_list_test.dart` → undefined `plansListProvider`.
- [ ] 3. **Implement** the contract; run `dart run build_runner build`.
- [ ] 4. **Run — green:** same command.
- [ ] 5. Gates: `dart format .` · `flutter analyze` · `flutter test --timeout=90s`. Report.

**Skills:** `.agents/skills/flutter-riverpod-arch`, `.agents/skills/dart-add-unit-test`, `.agents/skills/dart-generate-test-mocks`, `.agents/skills/flutter-expert`.

**Out of scope:** widgets, detail controller, domain edits.

---

## Task 3: Plan detail controller (`PlanDetailController`)

**Role:** implement

**Goal:** the editing brain. Seeds a `PlanDraft` from the repo, exposes name/day/active mutations, and a `save`/`delete` that compose the S09 functions: conflict gate → steal-override → persist self + stripped others → report uncovered; delete guarded by `canDeletePlan`.

**Files:**
- Create: `lib/ui/features/plans/view_models/plan_detail_controller.dart`
- Test: `test/ui/features/plans/view_models/plan_detail_controller_test.dart`
- Codegen: `dart run build_runner build`

**Contract:**

```dart
import 'package:crudo/config/di.dart';
import 'package:crudo/domain/food/food.dart';
import 'package:crudo/domain/meal/meal_template.dart';
import 'package:crudo/domain/plan/plan_template.dart';
import 'package:crudo/domain/services/nutrition.dart';
import 'package:crudo/domain/services/plan_scheduling.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'plan_draft.dart';

part 'plan_detail_controller.g.dart';

/// Detail/edit controller. `build` loads the plan + resolves its slots for
/// read-only display; throws StateError for an unknown id (programming error).
@riverpod
class PlanDetailController extends _$PlanDetailController {
  PlanTemplate? _seed; // the persisted plan, for the dirty check

  @override
  Future<PlanDraft> build(String planId) async {
    final plan = await ref.watch(planTemplateRepositoryProvider).getById(planId);
    if (plan == null) throw StateError('no plan with id $planId');
    _seed = plan;
    final templates = {
      for (final t in await ref.read(mealTemplateRepositoryProvider).getAll())
        t.id: t,
    };
    final foods = {
      for (final f in await ref.read(foodRepositoryProvider).getAll()) f.id: f,
    };
    final slots = [
      for (final s in plan.slots)
        (
          mealName: templates[s.mealTemplateId]?.name ?? '—',
          time: s.time,
          kcal: templates[s.mealTemplateId] == null
              ? 0
              : mealTemplateMacros(templates[s.mealTemplateId]!, foods)
                    .kcal
                    .round(),
        ),
    ];
    return PlanDraft.from(plan, slots);
  }

  bool get isDirty {
    final d = state.valueOrNull;
    final seed = _seed;
    return d != null && seed != null && d.isDirtyFrom(seed);
  }

  void setName(String v) => _update((d) => d.withName(v));
  void setActive(bool v) => _update((d) => d.withActive(v));
  void toggleDay(int weekday) => _update((d) => d.toggleDay(weekday));

  /// Persist. With conflicts and override:false → no write, conflicts returned.
  /// Else: strip stolen weekdays from OTHER active plans + save self (name/days/
  /// active; days kept verbatim — dormant when paused). Returns post-save
  /// uncovered weekdays.
  Future<SaveOutcome> save({bool override = false}) async {
    final draft = state.requireValue;
    if (!draft.canSave) throw StateError('cannot save an invalid draft');
    final repo = ref.read(planTemplateRepositoryProvider);
    final all = await repo.getAll();
    final claimed = draft.claimedDays;

    final conflicts =
        detectConflicts(all, forPlanId: planId, proposedDays: claimed);
    if (conflicts.isNotEmpty && !override) {
      return (committed: false, conflicts: conflicts, uncovered: const []);
    }

    final current = all.firstWhere((p) => p.id == planId);
    final updatedSelf = current.copyWith(
      name: draft.name.trim(),
      days: [...draft.days],
      active: draft.active,
    );
    final stripped = applyOverride(all, forPlanId: planId, proposedDays: claimed)
        .where((p) => p.id != planId);
    for (final p in stripped) {
      await repo.save(p);
    }
    await repo.save(updatedSelf);

    final after = await repo.getAll();
    return (
      committed: true,
      conflicts: const [],
      uncovered: uncoveredWeekdays(after),
    );
  }

  /// Returns false (no-op) when this is the last plan; true after deleting.
  Future<bool> delete() async {
    final repo = ref.read(planTemplateRepositoryProvider);
    if (!canDeletePlan(await repo.getAll())) return false;
    await repo.delete(planId);
    return true;
  }

  void _update(PlanDraft Function(PlanDraft) fn) {
    final d = state.valueOrNull;
    if (d != null) state = AsyncData(fn(d));
  }
}
```

**Steps (TDD):**

- [ ] 1. **Failing test** — `plan_detail_controller_test.dart`. Helper builds a `ProviderContainer` with in-memory repos. Cases:
  - **build** resolves draft: name/days/active from plan; `slots` length == plan slots, each `mealName`/`kcal` resolved; unknown id → `build` future throws `StateError`.
  - **save, no conflict:** plan A days `[0]`, no other plan claims `[0,2]`. `setName('Cut2')`, `toggleDay(2)`, `save()` → `committed:true`; repo's A now `name=='Cut2'`, `days==[0,2]`; no other plan changed.
  - **save, conflict, override:false:** A days `[0]`; B active days `[2]`. On A: `toggleDay(2)` then `save()` → `committed:false`, `conflicts` has one entry `(weekday:2, otherPlanId:B, otherPlanName:…)`; repo **unchanged** (A still `[0]`, B still `[2]`).
  - **save, conflict, override:true:** same setup → `save(override:true)` → A `days==[0,2]`, B `days==[]` (Wed stolen); both persisted.
  - **inactive draft:** A days `[2]`; B active days `[2]`. `setActive(false)` then `save()` → `committed:true`, **no conflict** (claimedDays empty), A persisted with `active:false` **and `days` still `[2]`** (dormant), B untouched.
  - **reactivate into conflict:** A persisted inactive days `[2]`; B active `[2]`. `setActive(true)` then `save()` → `committed:false`, conflict on Wed.
  - **uncovered reported:** single active plan covering `[0,1,2,3,4]`, `save()` (no-op edit ok) → `uncovered` == `[5,6]`.
  - **delete guard:** one plan in repo → `delete()` == false, plan still present. Two plans → `delete()` == true, gone.
  - **isDirty:** false right after build; true after `setName`/`toggleDay`/`setActive`.
- [ ] 2. **Run — red:** `flutter test --timeout=90s test/ui/features/plans/view_models/plan_detail_controller_test.dart` → undefined controller.
- [ ] 3. **Implement** the contract; `dart run build_runner build`.
- [ ] 4. **Run — green:** same command.
- [ ] 5. Gates: `dart format .` · `flutter analyze` · `flutter test --timeout=90s`. Report.

**Skills:** `.agents/skills/flutter-riverpod-arch`, `.agents/skills/dart-add-unit-test`, `.agents/skills/dart-generate-test-mocks`, `.agents/skills/flutter-expert`.

**Out of scope:** widgets, list provider, domain/repo edits. Do **not** add `selectPlanForDate`/`applyOverride` logic locally — call the S09 functions.

---

## Task 4: Plan detail screen + route

**Role:** ui

**Goal:** the `/plans/:id` editing screen — back-header, name field, weekday chips with live conflict highlight + banner, active toggle, read-only slot list, sticky Save running the override→uncovered flow, guarded Delete, and a discard `PopScope`. Register the route.

**Files:**
- Create: `lib/ui/features/plans/views/plan_detail_screen.dart`
- Modify: `lib/routing/app_router.dart` — add the `/plans/:id` route
- Test: `test/ui/features/plans/views/plan_detail_screen_test.dart`

**Contract:**

```dart
// plan_detail_screen.dart
class PlanDetailScreen extends ConsumerWidget {
  const PlanDetailScreen({required this.planId, super.key});
  final String planId;
  // build: watch planDetailControllerProvider(planId) -> AsyncValue<PlanDraft>.
  // Inline conflicts: read the live plan list for names/ids —
  //   final all = ref.watch(planTemplatesProvider).valueOrNull ?? const [];
  //   final conflicts = detectConflicts(all, forPlanId: planId,
  //       proposedDays: draft.claimedDays);
  //   final conflictDays = {for (final c in conflicts) c.weekday};
  // Plan count for the delete guard: `all.length`.
}
```

Routing — add as a top-level pushed route (sibling of `/meal/...`), inside `app_router.dart`'s `routes:` list:

```dart
GoRoute(
  path: '/plans/:id',
  builder: (context, state) =>
      PlanDetailScreen(planId: state.pathParameters['id']!),
),
```

UI composition (tokens only — `Spacing`/`Radii`/`IconSizes` from `dimensions.dart`; colors/type from theme; no 1px borders, no shadows):

- **Scaffold** `backgroundColor: colors.surface`. Wrap body in `PopScope`:
  ```dart
  PopScope(
    canPop: !ref.read(planDetailControllerProvider(planId).notifier).isDirty,
    onPopInvokedWithResult: (didPop, _) async {
      if (didPop) return;
      final leave = await _confirmDiscard(context); // sheet/dialog → bool?
      if (leave == true && context.mounted) context.pop();
    },
    child: ...,
  )
  ```
  (Re-read `isDirty` each build — the widget watches the draft `AsyncValue`, so `canPop` recomputes.)
- **Header row:** back `IconButton(Icons.arrow_back, onPressed: context.pop)` + title (plan name) — mirror `meal_detail_screen.dart`'s hand-rolled header.
- **Name:** a text field seeded from `draft.name`, `onChanged: (v) => ctrl.setName(v)` (use a `TextEditingController` initialised once from the first non-loading draft).
- **Repeats on:** a `Row`/`Wrap` of 7 day chips, labels `['M','T','W','T','F','S','S']`, index 0..6. A chip is *selected* when `draft.days.contains(i)`; in *conflict* when `conflictDays.contains(i)`. Conflict styling = error-tone outline-equivalent (tonal — e.g. `colors.errorContainer` fill or error text; **no 1px border** — use a surface/color shift). Tap → `ctrl.toggleDay(i)`. Below, when `conflicts.isNotEmpty`, a warning banner (`colors.errorContainer` surface, `Radii.md`) listing overlaps grouped by `otherPlanName` (e.g. "Wed overlaps Rest Day").
- **Active:** a labelled `Switch` (or tonal toggle) bound to `draft.active`, `onChanged: ctrl.setActive` — label "Active"/"Paused".
- **Meals:** read-only column of `draft.slots` — each row: formatted `time` · `mealName` · `'$kcal kcal'`. No tap, no edit control.
- **Delete:** a `SecondaryAction`/tonal destructive button. Disabled when `all.length <= 1`; tapped-while-disabled (or always, then guard) → `showCrudoToast(context, "Can't delete your only plan", kind: ToastKind.warn)`. Enabled → `_confirmDelete` → `await ctrl.delete()` → on true `context.pop()`.
- **Save:** sticky bottom `PrimaryCta(label: 'Save', onPressed: draft.canSave ? _save : null)`:
  ```dart
  Future<void> _save() async {
    final ctrl = ref.read(planDetailControllerProvider(planId).notifier);
    var out = await ctrl.save();
    if (!out.committed) {
      final ok = await _confirmOverride(context, out.conflicts); // bool?
      if (ok != true) return;
      out = await ctrl.save(override: true);
    }
    if (out.uncovered.isNotEmpty) {
      final leave = await _confirmUncovered(context, out.uncovered); // bool?
      if (leave != true) return;
    }
    if (context.mounted) context.pop();
  }
  ```
- **Override modal** `_confirmOverride` — `showCrudoSheet`/`SheetScaffold` titled "Override existing plans?", body lists per other plan "{name} loses {weekday names}" (group `conflicts` by `otherPlanId`; weekday names via `['Mon'..'Sun']`), footer `SecondaryAction('Cancel', pop(false))` + `PrimaryCta('Override', pop(true))`.
- **Uncovered confirm** `_confirmUncovered` — sheet/dialog: "{day names} have no plan — save anyway?", Save → pop(true) / Cancel → pop(false).
- **Discard confirm** `_confirmDiscard` — "Discard changes?", Discard → pop(true) / Keep editing → pop(false).
- Loading/error: `AsyncValue` → centered spinner / error text.

**Steps (TDD):**

- [ ] 1. **Failing test** — `plan_detail_screen_test.dart`. Pump `PlanDetailScreen(planId: 'A')` inside a `MaterialApp`/`ProviderScope` with in-memory repos (A active `[0]`; B active `[2]` named "Rest Day"; plus its templates/foods/profile), wrapped enough that `context.pop` and `showCrudoSheet` work (a minimal `GoRouter` or `Navigator`). Cases:
  - renders name, 7 day chips, active switch on, slot rows for A's slots.
  - tapping the Wed chip (index 2) marks it selected **and** shows the conflict outline + a banner containing "Rest Day" (B claims Wed).
  - tapping Save with the conflict opens the Override sheet (find "Override existing plans?" + "Rest Day loses Wed"); tapping **Cancel** dismisses it and leaves B unchanged (`repo` B still `[2]`).
  - turning the active switch **off** clears the conflict outline while the Wed chip stays selected.
  - delete disabled + warn toast when only one plan in the repo; with two plans, tapping Delete shows the confirm.
  - leaving (trigger back) after `setName`/toggling shows the discard confirm; with a clean draft it pops without a confirm.
  *(Drive async confirms with `tester.pumpAndSettle()` guarded by the global `--timeout`; never `pumpAndSettle` a running animation.)*
- [ ] 2. **Run — red:** `flutter test --timeout=90s test/ui/features/plans/views/plan_detail_screen_test.dart` → undefined `PlanDetailScreen`.
- [ ] 3. **Implement** the screen + route.
- [ ] 4. **Run — green:** same command.
- [ ] 5. Gates: `dart format .` · `flutter analyze` · `flutter test --timeout=90s`. Report.

**Skills:** `.agents/skills/flutter-add-widget-test`, `.agents/skills/flutter-riverpod-arch`, `.agents/skills/flutter-setup-declarative-routing`, `.agents/skills/flutter-expert`. Read `docs/design_system.md §5` + `app.css` for tokens.

**Out of scope:** the list screen (Task 5), any slot-edit/create affordance, domain edits. Reuse `PrimaryCta`/`SecondaryAction`/`showCrudoSheet`/`SheetScaffold`/`showCrudoToast` — do not invent new shells.

---

## Task 5: Plans list screen + row card

**Role:** ui

**Goal:** replace the placeholder `/plans` tab with the real list — one card per plan (name, derived "{GOAL} · {kcal} KCAL · {n} meals" subtitle, weekday chips, Today badge, Inactive styling), tapping pushes `/plans/:id`. No "New plan" CTA.

**Files:**
- Rewrite: `lib/ui/features/plans/views/plans_screen.dart`
- Create: `lib/ui/features/plans/views/plan_list_card.dart`
- Test: `test/ui/features/plans/views/plans_screen_test.dart`

**Contract:**

```dart
// plan_list_card.dart
class PlanListCard extends StatelessWidget {
  const PlanListCard({required this.row, required this.onTap, super.key});
  final PlanRowVm row;          // from plan_draft.dart
  final VoidCallback onTap;
  // Renders: name (CrudoText.title); subtitle "${row.goal.name.toUpperCase()}"
  //   " · ${row.kcal} KCAL · ${row.mealCount} meal(s)"; a 7-cell weekday strip
  //   (M T W T F S S) with claimed days (row.days) filled; a "Today" badge when
  //   row.isToday; muted tone + "Inactive" tag when !row.active.
  // Tonal card: colors.surfaceLowest, Radii.md, Spacing.md padding. No borders.
}

// plans_screen.dart
class PlansScreen extends ConsumerWidget { /* watch plansListProvider */ }
```

Composition:
- `final rows = ref.watch(plansListProvider);` → `ListView` (`Spacing.md` padding) with a "Plans" headline + one `PlanListCard` per row (`Spacing.md` gap), `onTap: () => context.push('/plans/${row.id}')`.
- Empty `rows` → centered muted "No plans yet" text (defensive; real data always has ≥1 post-onboarding).
- Weekday strip helper: `const labels = ['M','T','W','T','F','S','S'];` filled cell when `row.days.contains(i)`. Subtitle pluralisation: `row.mealCount == 1 ? '1 meal' : '${row.mealCount} meals'`.

**Steps (TDD):**

- [ ] 1. **Failing test** — `plans_screen_test.dart`. Pump `PlansScreen` with `plansListProvider` overridden to a fixed `List<PlanRowVm>`: row A `(goal: Goal.cut, kcal: 2200, mealCount: 5, days: [0,2,4], active: true, isToday: true)`, row B `(active: false, mealCount: 1, isToday: false, days: [5,6])`. Assertions:
  - two `PlanListCard`s; A shows "CUT · 2200 KCAL · 5 meals"; B shows "1 meal".
  - A renders a "Today" badge; B does not.
  - B shows an "Inactive" tag.
  - tapping A's card pushes `/plans/A` (use a `GoRouter` with a stub `/plans/:id` route and assert the location, or a mock-nav observer).
  - empty list → "No plans yet" visible.
- [ ] 2. **Run — red:** `flutter test --timeout=90s test/ui/features/plans/views/plans_screen_test.dart` → fails (placeholder text / undefined `PlanListCard`).
- [ ] 3. **Implement** `PlanListCard` + rewrite `PlansScreen`.
- [ ] 4. **Run — green:** same command.
- [ ] 5. Gates: `dart format .` · `flutter analyze` · `flutter test --timeout=90s`. Report.

**Skills:** `.agents/skills/flutter-add-widget-test`, `.agents/skills/flutter-riverpod-arch`, `.agents/skills/flutter-expert`. Tokens from `docs/design_system.md §5` + `app.css`.

**Out of scope:** "New plan"/clone CTA, detail screen, domain edits. Snap every dimension to a token — never copy raw px from `plan-create.jsx`.

---

## Acceptance (whole plan)

- `dart format .` clean · `flutter analyze` clean · `flutter test --timeout=90s` green.
- `/plans` lists every plan with derived target, weekday chips, Today badge, Inactive styling; tapping opens `/plans/:id`.
- Detail edits name + weekdays + active and deletes — steal-override modal, ≥1-plan delete guard, non-blocking uncovered confirm, and discard guard all behave per the spec; the "≤1 active plan per weekday" invariant cannot be violated through the UI.
- No file under `lib/domain/`, `lib/data/`, or `lib/application/` is modified.
- Every dimension on the 4px grid; colors/type from `app.css` tokens.
