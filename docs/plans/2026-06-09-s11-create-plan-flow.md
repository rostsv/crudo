# Plan — S11: Create-plan flow (unified create/edit + meal composition)

**Worker note:** Turns `docs/specs/2026-06-09-s11-create-plan-flow.md` into ordered `/task <id>` blocks. Builds the create-plan flow by extending the real S10 plan editor into the unified create/edit surface (editable slots), adding a multi-select meal-picker, `clonePlan`/`cloneMeal` in-memory seeds, and a "New plan" entry. Read `AGENTS.md` + role file + named `.agents/skills/<x>` before each task. Domain stays pure. Every `flutter test` passes `--timeout=90s`. No per-task git commit — end at "report for review".

**Goal:** From `/plans`, create a plan (name, weekdays, timed meal slots via picker, macro preview) and fully edit an existing plan's slots; duplicate plans/meals via in-memory seeds (no orphan dupes); Save reuses S10's conflict/override/uncovered flow.

**File changes (whole plan):**

| File | Task | Responsibility |
|---|---|---|
| `lib/ui/features/plans/view_models/plan_draft.dart` | T1 | `SlotVm`→editable `PlanSlotDraft`; slot ops; `canSave`/`isDirtyFrom` |
| `test/ui/features/plans/plan_draft_test.dart` | T1 | pure draft-logic unit tests (new) |
| `lib/ui/features/plans/view_models/plan_detail_controller.dart` | T2 | `build(String?)`, slot ops, `seedFrom`, save builds slots |
| `test/ui/features/plans/plan_detail_controller_test.dart` | T2 | controller tests (extend existing S10 file) |
| `lib/ui/features/meals/view_models/meal_template_draft_controller.dart` | T3 | `seedFrom(MealTemplate)` |
| `lib/ui/features/meals/views/meal_template_builder_screen.dart` | T3 | accept `seed` (via `extra`) |
| `lib/routing/app_router.dart` | T3, T5 | `/meal-templates/new` reads `extra`; add `/plans/new` |
| `lib/ui/features/plans/views/meal_picker_sheet.dart` | T4 | multi-select picker sheet (new) |
| `lib/ui/features/plans/views/plan_detail_screen.dart` | T5 | nullable planId + seed, editable slots, picker wiring, macro preview, Duplicate |
| `lib/ui/features/plans/views/plans_screen.dart` | T6 | "New plan" CTA |
| `test/ui/features/meals/meal_template_builder_screen_test.dart` | T3 | seed widget test (extend) |
| `test/ui/features/plans/meal_picker_sheet_test.dart` | T4 | picker widget tests (new) |
| `test/ui/features/plans/views/plan_detail_screen_test.dart` | T5 | editor widget tests (extend) |
| `test/ui/features/plans/views/plans_screen_test.dart` | T6 | CTA widget test (extend/new) |

**Decisions (settled in brainstorm — no task re-litigates):**

| # | Decision |
|---|---|
| D1 | Unified editor: `PlanDetailController.build(String? planId)` (null = create); same screen for create + edit. |
| D2 | Editable slots: `PlanSlotDraft{id, mealTemplateId, time, mealName, kcal}`; add/retime/drag-reorder/remove. |
| D3 | Default time on add: first 08:00 (`MealTime(480)`), else `(latest+180).clamp(0,1380)`; sequential for batch-add. |
| D4 | Drag-reorder = sorted time-pool reassigned to positions (order always == time order). List re-sorts by time after add/retime. |
| D5 | `canSave` = trimmed name non-empty AND ≥1 slot. |
| D6 | Picker = bottom sheet, multi-select + "Done"; "Create new meal" CTA; per-row "Duplicate". Returns `MealPickerResult`; editor owns navigation. |
| D7 | Duplicate = in-memory seed via go_router `extra`; persisted only on Save. `clonePlan` in editor (edit-mode), `cloneMeal` in picker. |
| D8 | Save = unchanged S10 flow (`detectConflicts`/override modal/`applyOverride`/`uncoveredWeekdays`); only template construction (with slots) changes. `SaveOutcome` reused. |
| D9 | Macro preview: Σ `mealTemplateMacros` over slots + uppercase `Prefs.goal` label. |
| D10 | Time picker = Material `showTimePicker` (`TimeOfDay`↔`MealTime`); custom = follow-up. |
| D11 | Active toggle edit-mode only; create defaults `active:true`. |

---

## Task 1: Editable PlanDraft slots

**Role:** implement

**Goal:** Replace the read-only `SlotVm` with an editable `PlanSlotDraft` and add pure slot operations (add+sort, remove, retime+sort, drag-reorder with time-pool reassignment) plus the new `canSave`/`isDirtyFrom`.

**Files:**
- Modify: `lib/ui/features/plans/view_models/plan_draft.dart`
- Test: `test/ui/features/plans/plan_draft_test.dart` (new)

**Contract:**

```dart
// Replace `typedef SlotVm = ...` with:
/// One editable plan slot. id/mealTemplateId/time persist; mealName/kcal are
/// resolved display data filled by the controller.
typedef PlanSlotDraft = ({
  String id,
  String mealTemplateId,
  MealTime time,
  String mealName,
  int kcal,
});

// PlanDraft: `slots` becomes List<PlanSlotDraft>. Keep name/days/active and
// claimedDays/withName/withActive/toggleDay unchanged. Update/add:

factory PlanDraft.from(PlanTemplate p, List<PlanSlotDraft> slots) => PlanDraft(
  name: p.name, days: [...p.days], active: p.active, slots: slots,
);

bool get canSave => name.trim().isNotEmpty && slots.isNotEmpty;

bool isDirtyFrom(PlanTemplate p) =>
    name.trim() != p.name ||
    !_sameWeekdays(days, p.days) ||
    active != p.active ||
    !_sameSlots(slots, p.slots);

/// Append, then keep ascending by time.
PlanDraft addSlot(PlanSlotDraft s) =>
    _copy(slots: [...slots, s]..sort((a, b) => a.time.compareTo(b.time)));

PlanDraft removeSlot(int index) =>
    _copy(slots: [for (final (i, s) in slots.indexed) if (i != index) s]);

/// Retime one slot, then re-sort by time.
PlanDraft setSlotTime(int index, MealTime t) => _copy(
  slots: [
    for (final (i, s) in slots.indexed)
      if (i == index)
        (id: s.id, mealTemplateId: s.mealTemplateId, time: t, mealName: s.mealName, kcal: s.kcal)
      else s,
  ]..sort((a, b) => a.time.compareTo(b.time)),
);

/// Move [from]→[to], then redistribute the sorted time-pool onto positions so
/// visual order == time order.
PlanDraft reorderSlots(int from, int to) {
  final moved = [...slots];
  moved.insert(to, moved.removeAt(from));
  final pool = slots.map((s) => s.time).toList()..sort((a, b) => a.compareTo(b));
  return _copy(slots: [
    for (final (i, s) in moved.indexed)
      (id: s.id, mealTemplateId: s.mealTemplateId, time: pool[i], mealName: s.mealName, kcal: s.kcal),
  ]);
}

// Helper:
bool _sameSlots(List<PlanSlotDraft> a, List<PlanTemplate p>.slots ... );
// Implement as: lengths equal AND for each i a[i].id==p.slots[i].id &&
// a[i].mealTemplateId==p.slots[i].mealTemplateId && a[i].time==p.slots[i].time.
```

```dart
// Concrete _sameSlots (signature uses PlanSlot from the template):
bool _sameSlots(List<PlanSlotDraft> a, List<PlanSlot> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i].id != b[i].id ||
        a[i].mealTemplateId != b[i].mealTemplateId ||
        a[i].time != b[i].time) {
      return false;
    }
  }
  return true;
}
// Add `import 'package:crudo/domain/plan/plan_slot.dart';` for PlanSlot.
```

**Steps (TDD):**

- [ ] 1. **Failing test** — `test/ui/features/plans/plan_draft_test.dart` (`package:checks`). Helper to build a `PlanSlotDraft`:

```dart
import 'package:checks/checks.dart';
import 'package:test/test.dart';
import 'package:crudo/domain/shared/meal_time.dart';
import 'package:crudo/ui/features/plans/view_models/plan_draft.dart';

PlanSlotDraft slot(String id, int min) =>
    (id: id, mealTemplateId: 't-$id', time: MealTime(min), mealName: id, kcal: 100);

void main() {
  test('addSlot keeps ascending by time', () {
    final d = const PlanDraft(name: 'P', days: [], active: true, slots: [])
        .addSlot(slot('b', 720)).addSlot(slot('a', 480));
    check(d.slots.map((s) => s.id)).deepEquals(['a', 'b']);
  });

  test('canSave needs name + >=1 slot', () {
    const blank = PlanDraft(name: '', days: [], active: true, slots: []);
    check(blank.canSave).isFalse();
    check(blank.copyWithForTest(name: 'P').canSave).isFalse(); // no slots — see note
  });

  test('reorderSlots redistributes sorted time-pool to positions', () {
    final d = const PlanDraft(name: 'P', days: [], active: true, slots: [])
        .addSlot(slot('a', 480)).addSlot(slot('b', 720)).addSlot(slot('c', 1080));
    // drag 'c' (index 2) to front (index 0)
    final r = d.reorderSlots(2, 0);
    check(r.slots.map((s) => s.id)).deepEquals(['c', 'a', 'b']);
    check(r.slots.map((s) => s.time.minutesOfDay)).deepEquals([480, 720, 1080]);
  });

  test('setSlotTime re-sorts', () {
    final d = const PlanDraft(name: 'P', days: [], active: true, slots: [])
        .addSlot(slot('a', 480)).addSlot(slot('b', 720));
    final r = d.setSlotTime(0, const MealTime(1000)); // move 'a' late
    check(r.slots.map((s) => s.id)).deepEquals(['b', 'a']);
  });
}
```
  (Drop the `copyWithForTest` line — assert `canSave` false on a name-only draft by constructing `PlanDraft(name:'P', days:[], active:true, slots:[])` directly.)

- [ ] 2. **Run — red:** `flutter test --timeout=90s test/ui/features/plans/plan_draft_test.dart` → fails (`PlanSlotDraft`/ops undefined or shape changed).
- [ ] 3. **Implement** the contract. `PlanDraft` has no codegen. Update `_copy` to thread `slots`. NOTE: `plan_detail_controller.dart` + `plan_detail_screen.dart` reference the old `SlotVm`/`draft.slots` shape and will not compile until T2/T5 — that is expected; this task's test targets `plan_draft.dart` in isolation, but `flutter analyze`/full `flutter test` will be red until T2+T5 land. Run the gates in step 5 scoped to the new test file; note the cross-file breakage in the report (T2 fixes the controller).
- [ ] 4. **Run — green:** `flutter test --timeout=90s test/ui/features/plans/plan_draft_test.dart`.
- [ ] 5. Gates: `dart format .` · `flutter analyze` (expect pre-existing errors in `plan_detail_controller.dart`/`plan_detail_screen.dart` from the type change — list them, do NOT fix here) · `flutter test --timeout=90s test/ui/features/plans/plan_draft_test.dart`. Report for review, flagging the known T2/T5 breakage.

**Skills:** `.agents/skills/dart-add-unit-test`, `.agents/skills/dart-migrate-to-checks-package`.

**Out of scope:** controller (T2), screen (T5). Don't touch `PlanRowVm`/`SaveOutcome` typedefs. Don't resolve the cross-file compile errors — T2 owns the controller.

---

## Task 2: PlanDetailController — create mode, slot ops, slot-aware save

**Role:** implement

**Goal:** `build(String? planId)` (null = blank create), slot operations (resolving display + default time), `seedFrom` for in-memory duplicates, and a `save()` that builds `PlanTemplate` slots from the draft while reusing the S10 conflict/override/uncovered flow.

**Files:**
- Modify: `lib/ui/features/plans/view_models/plan_detail_controller.dart` (regen `.g.dart`)
- Test: `test/ui/features/plans/plan_detail_controller_test.dart` (extend the existing S10 test file)

**Contract:**

```dart
@riverpod
class PlanDetailController extends _$PlanDetailController {
  PlanTemplate? _original;            // null in create mode
  late PlanTemplate _baseline;        // dirty-comparison baseline
  late PlanTemplateRepository _repo;
  Map<String, MealTemplate> _templatesById = const {};
  Map<String, Food> _foodsById = const {};

  @override
  Future<PlanDraft> build(String? planId) async {
    _repo = ref.read(planTemplateRepositoryProvider);
    _templatesById = {
      for (final t in await ref.read(mealTemplateRepositoryProvider).getAll()) t.id: t,
    };
    _foodsById = {
      for (final f in await ref.read(foodRepositoryProvider).getAll()) f.id: f,
    };
    if (planId == null) {
      _original = null;
      _baseline = const PlanTemplate(id: '', name: '');
      return PlanDraft.from(_baseline, const []);
    }
    final plan = await _repo.getById(planId);
    if (plan == null) throw StateError('Plan $planId not found');
    _original = plan;
    _baseline = plan;
    return PlanDraft.from(plan, _resolveSlots(plan.slots));
  }

  List<PlanSlotDraft> _resolveSlots(List<PlanSlot> slots) => [
    for (final s in slots)
      (
        id: s.id,
        mealTemplateId: s.mealTemplateId,
        time: s.time,
        mealName: _templatesById[s.mealTemplateId]?.name ?? 'Unknown meal',
        kcal: _templatesById[s.mealTemplateId] == null
            ? 0
            : mealTemplateMacros(_templatesById[s.mealTemplateId]!, _foodsById).kcal.round(),
      ),
  ];

  bool get isDirty {
    final d = state.value;
    return d != null && d.isDirtyFrom(_baseline);
  }

  // setName/toggleDay/setActive — unchanged from S10 (operate on state.value).

  void addSlot(String mealTemplateId) {
    final d = state.value;
    final tpl = _templatesById[mealTemplateId];
    if (d == null || tpl == null) return;
    final time = d.slots.isEmpty
        ? const MealTime(480)
        : MealTime(
            (d.slots.map((s) => s.time.minutesOfDay).reduce((a, b) => a > b ? a : b) + 180)
                .clamp(0, 1380),
          );
    state = AsyncData(d.addSlot((
      id: ref.read(idGeneratorProvider).newId(),
      mealTemplateId: mealTemplateId,
      time: time,
      mealName: tpl.name,
      kcal: mealTemplateMacros(tpl, _foodsById).kcal.round(),
    )));
  }

  void removeSlot(int i) => _mutate((d) => d.removeSlot(i));
  void setSlotTime(int i, MealTime t) => _mutate((d) => d.setSlotTime(i, t));
  void reorderSlots(int from, int to) => _mutate((d) => d.reorderSlots(from, to));

  /// In-memory duplicate seed (create mode). Replaces the blank draft once.
  void seedFrom(PlanTemplate src) {
    _baseline = src;
    state = AsyncData(PlanDraft.from(src, _resolveSlots(src.slots)));
  }

  Future<SaveOutcome> save({bool override = false}) async {
    final draft = state.value;
    if (draft == null) {
      return (committed: false, conflicts: const [], uncovered: const []);
    }
    final id = _original?.id ?? ref.read(idGeneratorProvider).newId();
    final allPlans = await _repo.getAll();
    final conflicts = detectConflicts(allPlans, forPlanId: id, proposedDays: draft.claimedDays);
    if (conflicts.isNotEmpty && !override) {
      return (committed: false, conflicts: conflicts, uncovered: const []);
    }
    final updated = PlanTemplate(
      id: id,
      name: draft.name.trim(),
      days: [...draft.days],
      active: draft.active,
      slots: [
        for (final s in draft.slots)
          PlanSlot(id: s.id, mealTemplateId: s.mealTemplateId, time: s.time),
      ],
    );
    if (override && conflicts.isNotEmpty) {
      final changed = applyOverride(allPlans, forPlanId: id, proposedDays: draft.claimedDays);
      var savedMain = false;
      for (final p in changed) {
        if (p.id == id) { await _repo.save(updated); savedMain = true; }
        else { await _repo.save(p); }
      }
      if (!savedMain) await _repo.save(updated);
    } else {
      await _repo.save(updated);
    }
    final postSave = await _repo.getAll();
    final uncovered = uncoveredWeekdays(postSave);
    _original = updated;
    _baseline = updated;
    state = AsyncData(PlanDraft.from(updated, _resolveSlots(updated.slots)));
    return (committed: true, conflicts: const [], uncovered: uncovered);
  }

  Future<bool> delete() async {        // S10, edit-mode only
    final original = _original;
    if (original == null) return false;
    if (!canDeletePlan(await _repo.getAll())) return false;
    await _repo.delete(original.id);
    return true;
  }

  void _mutate(PlanDraft Function(PlanDraft) fn) {
    final d = state.value;
    if (d != null) state = AsyncData(fn(d));
  }
}
```
Add imports: `meal_template.dart`, `meal_template_repository.dart`, `food/food.dart`, `food_repository.dart`, `plan_slot.dart`, `shared/meal_time.dart`, `nutrition.dart`, `id_generator.dart` (for `IdGenerator`), `shared/enums.dart` if needed.

**Steps (TDD):**

- [ ] 1. **Failing test** — extend `test/ui/features/plans/plan_detail_controller_test.dart`. Override `planTemplateRepositoryProvider`, `mealTemplateRepositoryProvider`, `foodRepositoryProvider` (reuse the S10 harness). New cases:
  - `build(null)` → blank draft (`canSave` false, slots empty).
  - `addSlot(tplId)` on empty → one slot at `MealTime(480)`, `mealName`/`kcal` resolved; second `addSlot` → time `660`; verify cap at `1380` when latest ≥ 1200.
  - `removeSlot`/`setSlotTime` (re-sorts)/`reorderSlots` (pool reassign) reflected in `state.value!.slots`.
  - `seedFrom(plan)` → draft mirrors plan; `isDirty` false right after seed; mutating → `isDirty` true; nothing persisted (repo unchanged).
  - `save()` create (planId null, name + 1 slot, no conflict) → repo gains a plan with a minted id, one `PlanSlot` (minted id, correct mealTemplateId/time); `committed:true`.
  - `save()` with conflict + `override:false` → `committed:false`, conflicts returned, nothing written; `override:true` → stolen days stripped from the other plan, self persisted (regression of S10 behavior, now via create/edit path).
  - Existing S10 controller tests still pass (edit path).
- [ ] 2. **Run — red:** `flutter test --timeout=90s test/ui/features/plans/plan_detail_controller_test.dart`.
- [ ] 3. **Implement**; `dart run build_runner build`.
- [ ] 4. **Run — green:** `flutter test --timeout=90s test/ui/features/plans/plan_detail_controller_test.dart`.
- [ ] 5. Gates: `dart format .` · `flutter analyze` (controller now compiles; `plan_detail_screen.dart` may still error on the slot-shape until T5 — note it) · `flutter test --timeout=90s test/ui/features/plans/`. Report.

**Skills:** `.agents/skills/flutter-riverpod`, `.agents/skills/dart-add-unit-test`, `.agents/skills/dart-migrate-to-checks-package`.

**Out of scope:** screen (T5), picker (T4), builder seed (T3). Don't change the `SaveOutcome` typedef or the S10 conflict functions.

---

## Task 3: S11a builder accepts an in-memory seed

**Role:** ui

**Goal:** Let the meal builder open seeded from a `MealTemplate` (passed via go_router `extra`) so `cloneMeal` needs no pre-persist; the id is still minted on Save.

**Files:**
- Modify: `lib/ui/features/meals/view_models/meal_template_draft_controller.dart` (regen `.g.dart`)
- Modify: `lib/ui/features/meals/views/meal_template_builder_screen.dart`
- Modify: `lib/routing/app_router.dart` (`/meal-templates/new` reads `extra`)
- Test: `test/ui/features/meals/meal_template_builder_screen_test.dart` (extend)

**Contract:**

```dart
// meal_template_draft_controller.dart — add (create-mode seed):
/// Replace the blank create draft with one mirroring [src] (name/tags/foods).
/// id stays unminted: _initial keeps id '' so save() still mints on persist.
void seedFrom(MealTemplate src) {
  state = AsyncData(MealTemplateDraft.from(src));
}
```

```dart
// meal_template_builder_screen.dart:
class MealTemplateBuilderScreen extends ConsumerWidget {
  const MealTemplateBuilderScreen({required this.templateId, this.seed, super.key});
  final String? templateId;
  final MealTemplate? seed;          // create-mode in-memory seed
  ...
}
// In the StatefulWidget form's initState (after the controller is first read):
// if (widget.templateId == null && widget.seed != null) {
//   WidgetsBinding.instance.addPostFrameCallback((_) =>
//     ref.read(mealTemplateDraftControllerProvider(null).notifier).seedFrom(widget.seed!));
// }
// (Seed once; the name TextEditingController must also pick up seed.name — set
//  its initial text from widget.seed?.name ?? widget.initial.name.)
```

```dart
// app_router.dart — /meal-templates/new builder:
builder: (context, state) => MealTemplateBuilderScreen(
  templateId: null,
  seed: state.extra as MealTemplate?,
),
```

**Steps (TDD):**

- [ ] 1. **Failing test** — extend `meal_template_builder_screen_test.dart`: pump `MealTemplateBuilderScreen(templateId: null, seed: <a MealTemplate with name "X copy" + 1 food>)`; assert the name field shows "X copy" and the ingredient row + preview reflect the seed; tap SAVE → repo gains a template with a freshly minted id (not the seed's) — OR keep the seed's id (acceptable); cancel (back, discard) → repo unchanged (no persist).
- [ ] 2. **Run — red:** `flutter test --timeout=90s test/ui/features/meals/meal_template_builder_screen_test.dart`.
- [ ] 3. **Implement**; `dart run build_runner build` (controller annotation unchanged but regen is safe).
- [ ] 4. **Run — green:** same command.
- [ ] 5. Gates: `dart format .` · `flutter analyze` · `flutter test --timeout=90s test/ui/features/meals/`. Report.

**Skills:** `.agents/skills/flutter-riverpod`, `.agents/skills/flutter-add-widget-test`, `.agents/skills/flutter-setup-declarative-routing`.

**Out of scope:** plan editor/picker (T4/T5). Keep the non-seeded create + edit paths behavior-identical (existing S11a tests green).

---

## Task 4: Meal-picker sheet

**Role:** ui

**Goal:** A multi-select bottom sheet listing library templates, returning a `MealPickerResult` the editor acts on (select N / create new / duplicate one). The sheet is pure — it never navigates.

**Files:**
- Create: `lib/ui/features/plans/views/meal_picker_sheet.dart`
- Test: `test/ui/features/plans/meal_picker_sheet_test.dart` (new)

**Contract:**

```dart
import 'package:crudo/ui/features/meals/view_models/meal_template_rows.dart';

/// Picker result — exactly one variant is meaningful (checked in priority:
/// createNew, then duplicateTemplateId, then selectedTemplateIds).
typedef MealPickerResult = ({
  List<String>? selectedTemplateIds,
  bool createNew,
  String? duplicateTemplateId,
});

/// Shows the picker; returns null if dismissed without action.
Future<MealPickerResult?> showMealPickerSheet(BuildContext context) =>
    showCrudoSheet<MealPickerResult>(context, builder: (_) => const _MealPickerSheet());

// _MealPickerSheet: ConsumerStatefulWidget holding a local Set<String> _selected.
// Body via SheetScaffold:
//  - title "Add meals".
//  - "Create new meal" CTA (key 'picker-create-new') → Navigator.pop(ctx,
//      (selectedTemplateIds: null, createNew: true, duplicateTemplateId: null)).
//  - For each row in ref.watch(mealTemplateRowsProvider):
//      toggle row (key 'picker-row-${vm.id}') name · '${vm.kcal} kcal' · tags,
//      checkmark when _selected.contains(vm.id); tap toggles.
//      trailing "Duplicate" (key 'picker-dup-${vm.id}') → Navigator.pop(ctx,
//        (selectedTemplateIds: null, createNew: false, duplicateTemplateId: vm.id)).
//  - cta: PrimaryCta 'Done · ${_selected.length} selected' (key 'picker-done')
//      → Navigator.pop(ctx, (selectedTemplateIds: _selected.toList(),
//        createNew: false, duplicateTemplateId: null)).
```
Reuse `Pill`/checkmark style, tonal rows, tokens only. No 1px borders/shadows.

**Steps (TDD):**

- [ ] 1. **Failing test** — `meal_picker_sheet_test.dart`. Override `mealTemplateRows` deps (templates+foods+plans) for ≥2 rows. Pump a host that opens the sheet and captures the popped `MealPickerResult`. Assert: toggling two rows + "Done" → `selectedTemplateIds` has both ids; "Create new meal" → `createNew:true`; a row "Duplicate" → `duplicateTemplateId == that id`.
- [ ] 2. **Run — red:** `flutter test --timeout=90s test/ui/features/plans/meal_picker_sheet_test.dart`.
- [ ] 3. **Implement.**
- [ ] 4. **Run — green:** same command.
- [ ] 5. Gates: `dart format .` · `flutter analyze` · `flutter test --timeout=90s test/ui/features/plans/`. Report.

**Skills:** `.agents/skills/flutter-riverpod`, `.agents/skills/flutter-add-widget-test`, `.agents/skills/flutter-expert`.

**Out of scope:** navigation to builder (T5 orchestrates), editor (T5), controller (T2).

---

## Task 5: Plan editor — create mode, editable slots, picker wiring, macro preview, Duplicate

**Role:** ui

**Goal:** Extend `PlanDetailScreen` to the unified create/edit surface: nullable `planId` + optional seed, editable slot list (reorderable rows, time chip → `showTimePicker`, remove), "ADD MEAL" → picker (orchestrating select/create/duplicate → `addSlot`), live macro preview, and the edit-mode "Duplicate" action. Add the `/plans/new` route.

**Files:**
- Modify: `lib/ui/features/plans/views/plan_detail_screen.dart`
- Modify: `lib/routing/app_router.dart` (add `/plans/new` BEFORE `/plans/:id`)
- Test: `test/ui/features/plans/views/plan_detail_screen_test.dart` (extend)

**Contract:**

```dart
// app_router.dart — add ABOVE the existing '/plans/:id' route:
GoRoute(
  path: '/plans/new',
  builder: (context, state) => PlanDetailScreen(
    planId: null,
    seed: state.extra as PlanTemplate?,
  ),
),
// Existing:
GoRoute(
  path: '/plans/:id',
  builder: (context, state) => PlanDetailScreen(planId: state.pathParameters['id']!),
),
```

```dart
// plan_detail_screen.dart:
class PlanDetailScreen extends ConsumerWidget {
  const PlanDetailScreen({required this.planId, this.seed, super.key});
  final String? planId;            // null = create
  final PlanTemplate? seed;        // in-memory duplicate seed
  ...
}
// Provider family is keyed by planId: planDetailControllerProvider(planId).
// In the stateful form initState: if (planId == null && seed != null) seed once
// via addPostFrameCallback → controller.seedFrom(seed); set _nameController text
// from seed?.name.
```

Editor changes (keep S10 sections; replace the read-only slot list):
- Title: `planId == null ? (seed?.name ?? 'New plan') : draft.name`.
- Active toggle + Delete + Duplicate: render only when `planId != null` (edit mode). Create defaults `active:true` (blank draft).
- **Slot section:** `ReorderableListView.builder` (or `ReorderableListView`) over `draft.slots`:
  - each row keyed `ValueKey(slot.id)`; shows a tappable time chip (`mealTimeLabel(slot.time)`, key `slot-time-$i`) → `_editTime(i, slot.time)`, meal name + `${slot.kcal} kcal`, a drag handle (`ReorderableDragStartListener`), trailing remove (key `slot-remove-$i`) → `controller.removeSlot(i)`.
  - `onReorder: (oldI, newI) { final to = newI > oldI ? newI - 1 : newI; controller.reorderSlots(oldI, to); }`.
  - "ADD MEAL" button (key `add-meal`) → `_addMeals`.
- **Macro preview** gradient card: compute `Macros` = fold `mealTemplateMacros` over the draft's slot templates (resolve via `planTemplatesProvider`? no — the controller already resolved kcal per slot; for P/C/F sum, expose totals). Simplest: sum `slot.kcal` for the kcal headline (already resolved) and read goal label from `ref.watch(profileProvider).value?.prefs.goal`. For P/C/F, resolve `mealTemplateMacros` via `mealTemplateRows`/repo maps — OR add a `Macros draftMacros` getter to the controller. Recommended: add `Macros get totalMacros` to the controller (sums `mealTemplateMacros(_templatesById[s.mealTemplateId]!, _foodsById)` over draft slots); the screen reads it. (If added, note it in the T2 contract surface — acceptable cross-task; implement the getter here in T5 since it's display-only and T2 already exposes the maps via the notifier — read through `ref.read(provider.notifier)`.)
- **`_editTime`:** `final picked = await showTimePicker(context: context, initialTime: TimeOfDay(hour: t.hour, minute: t.minute)); if (picked != null) controller.setSlotTime(i, MealTime(picked.hour*60 + picked.minute));`
- **`_addMeals`:**
```dart
final res = await showMealPickerSheet(context);
if (res == null || !mounted) return;
if (res.createNew) {
  final t = await context.push<MealTemplate>('/meal-templates/new');
  if (t != null) _ctrl.addSlot(t.id);
} else if (res.duplicateTemplateId != null) {
  final src = _ctrl.templateById(res.duplicateTemplateId!); // expose lookup, or read repo
  final copy = cloneMeal(src, newId: ref.read(idGeneratorProvider).newId);
  final t = await context.push<MealTemplate>('/meal-templates/new', extra: copy);
  if (t != null) _ctrl.addSlot(t.id);
} else {
  for (final id in res.selectedTemplateIds ?? const <String>[]) {
    _ctrl.addSlot(id);
  }
}
```
  (Add a `MealTemplate templateById(String)` accessor on the controller, or have the screen read `ref.read(mealTemplateRepositoryProvider).getById`. The created/cloned template is persisted by the builder's Save; `addSlot(t.id)` then resolves it — ensure the controller's `_templatesById` is refreshed: simplest is `addSlot` falls back to fetching the template by id if absent from the cached map. Add that fallback in T2's `addSlot` OR refresh the map here. Recommended: in `_addMeals`, after a create/duplicate returns `t`, the controller adds the slot using `t` directly — add `void addSlotFromTemplate(MealTemplate t)` to avoid the stale-map issue.)
- Save/discard/override/uncovered: reuse S10 `_save`/`_confirmOverride`/`_confirmUncovered`/`_confirmDiscard` verbatim (now also covers slots via the controller). Save CTA gated on `draft.canSave`.
- **Duplicate action (edit mode):** `SecondaryAction(label: 'Duplicate', key: ValueKey('duplicate-plan'))` → `final copy = clonePlan(_original, newId: ...); context.push('/plans/new', extra: copy);`. Get `_original` via the loaded plan (`ref.read(planTemplatesProvider)` find by id, or expose on controller).

> **Stale-map note (important):** the controller resolves `_templatesById` once in `build`. A meal created/cloned mid-flow won't be in that map. Use `addSlotFromTemplate(MealTemplate)` (adds to the map + appends the slot) for the create/duplicate paths; keep `addSlot(String id)` for picker-selected (already-cached) templates. Add `addSlotFromTemplate` to the controller (T2 surface) — implement it alongside the T5 wiring if not already present.

**Steps (TDD):**

- [ ] 1. **Failing test** — extend `plan_detail_screen_test.dart`. With overridden providers:
  - create mode (`planId: null`): blank fields; Save disabled; pump the picker stub → `addSlot` → a slot row appears with default time; add a second → later time; tap remove → gone; Save disabled with 0 slots / blank name, enabled with name + ≥1 slot.
  - retime a slot via the time chip (drive `controller.setSlotTime` directly if `showTimePicker` is hard to pump) → row re-sorts.
  - reorder (call `controller.reorderSlots` via the widget's onReorder, or invoke directly) → times reassigned ascending.
  - macro preview shows summed kcal + goal label.
  - edit mode (`planId: id`): Duplicate action present → pushes `/plans/new` with `extra` (capture via spy router); create mode hides Active/Delete/Duplicate.
  - existing S10 detail tests (conflict banner, override modal, uncovered, discard, delete guard) stay green.
- [ ] 2. **Run — red:** `flutter test --timeout=90s test/ui/features/plans/views/plan_detail_screen_test.dart`.
- [ ] 3. **Implement** screen + route (+ any controller accessor like `addSlotFromTemplate`/`totalMacros`/`templateById`; regen `.g.dart` if the controller changed).
- [ ] 4. **Run — green:** same command.
- [ ] 5. Gates: `dart format .` · `flutter analyze` (now fully clean) · `flutter test --timeout=90s`. Report.

**Skills:** `.agents/skills/flutter-riverpod`, `.agents/skills/flutter-setup-declarative-routing`, `.agents/skills/flutter-add-widget-test`, `.agents/skills/flutter-expert`, `.agents/skills/flutter-apply-architecture-best-practices`.

**Out of scope:** the list CTA (T6). Don't alter S10 conflict/override/uncovered helpers. No raw px; no 1px borders / drop shadows.

---

## Task 6: "New plan" CTA on the plans list

**Role:** ui

**Goal:** Add a "New plan" entry to `PlansScreen` (including the empty state) → `/plans/new`.

**Files:**
- Modify: `lib/ui/features/plans/views/plans_screen.dart`
- Test: `test/ui/features/plans/views/plans_screen_test.dart` (extend or new)

**Contract:**

```dart
// PlansScreen: wrap the body in a Stack/Column so a full-width sticky PrimaryCta
// sits at the bottom (design-system: primary CTA = full-width sticky bottom).
// Both the populated list and the empty state show it.
//   PrimaryCta(key: const ValueKey('new-plan'), label: 'New plan',
//     onPressed: () => context.push('/plans/new'))
// Keep the existing list/empty rendering above it.
```

**Steps (TDD):**

- [ ] 1. **Failing test** — `plans_screen_test.dart`: with seeded plans, find `ValueKey('new-plan')`; tapping pushes `/plans/new` (spy router). Also assert it renders in the empty state (override provider → no plans).
- [ ] 2. **Run — red:** `flutter test --timeout=90s test/ui/features/plans/views/plans_screen_test.dart`.
- [ ] 3. **Implement.**
- [ ] 4. **Run — green:** same command.
- [ ] 5. Gates: `dart format .` · `flutter analyze` · `flutter test --timeout=90s`. Report.

**Skills:** `.agents/skills/flutter-add-widget-test`, `.agents/skills/flutter-expert`.

**Out of scope:** editor (T5). Don't change list card / row behavior.

---

## Plan self-review

- **Spec coverage:** editable slots → T1+T2; create mode + slot-aware save → T2; builder seed (cloneMeal no-persist) → T3; picker → T4; editor wiring (slots/picker/macro/Duplicate/clonePlan/route) → T5; list CTA → T6. Default-time/drag-pool/canSave (D3/D4/D5) → T1+T2. Reused S10 save flow (D8) → T2. ✓
- **Type consistency:** `PlanSlotDraft` (T1) consumed by controller (T2) + screen (T5); `MealPickerResult` (T4) consumed by T5; `SaveOutcome` reused unchanged; `seedFrom` on both controllers (T2/T3). ✓
- **Sequencing hazard flagged:** T1 changes a shared type, leaving `plan_detail_controller`/`plan_detail_screen` uncompilable until T2/T5 — called out in T1 step 3/5 (scope that task's gate to its test file; full analyze/test green only after T5). ✓
- **No placeholders:** all code concrete; the one pseudo-helper (`_sameSlots` signature line) is immediately followed by its concrete implementation. ✓
