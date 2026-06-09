# Plan — S11a: Meal-template builder (library create/edit/delete)

**Worker note:** This plan turns `docs/specs/2026-06-09-s11a-meal-template-builder.md` into ordered tasks for `/task <id>`. It builds the reusable library **MealTemplate builder** (S11 prerequisite). Read `AGENTS.md` + your role file + the named `.agents/skills/<x>` before each task. Domain stays pure (no Flutter/Riverpod imports). All `flutter test` runs pass `--timeout=90s`. No per-task git commit — end at "report for review".

**Goal:** A dev-reachable meal-template library list + a create/edit form (name, tags, ingredients with grams, live macros) + a reference-safe delete (cascade-strip, blocked when it would empty a plan), mirroring the S08 instance editor retargeted to library `MealTemplate`.

**File changes (whole plan):**

| File | Task | Responsibility |
|---|---|---|
| `lib/domain/services/plan_scheduling.dart` | T1 | + `TemplateUsage`, `templateUsage`, `stripTemplateFromPlan` (pure) |
| `test/domain/services/template_usage_test.dart` | T1 | unit tests for the helpers |
| `lib/ui/features/meals/view_models/meal_template_draft.dart` | T2 | `MealTemplateDraft` VM + `IngredientRowVm` |
| `lib/ui/features/meals/view_models/meal_template_draft_controller.dart` | T2 | `MealTemplateDraftController` + `DeleteOutcome` |
| `lib/ui/features/meals/view_models/meal_template_rows.dart` | T2 | `mealTemplateRows` provider + `MealTemplateRowVm` |
| `test/ui/features/meals/meal_template_draft_controller_test.dart` | T2 | controller + rows unit tests |
| `lib/ui/features/meals/views/add_ingredient_screen.dart` | T3 | pop payload → `({Food food, Grams grams})` |
| `lib/ui/features/meals/views/meal_editor_screen.dart` | T3 | S08 caller wraps record → `FoodSnapshot` |
| `lib/ui/features/meals/views/meal_template_builder_screen.dart` | T4 | builder screen |
| `lib/ui/features/meals/views/meal_template_library_screen.dart` | T5 | library list screen + row card |
| `lib/routing/app_router.dart` | T4, T5 | `/meal-templates` subtree |
| `test/ui/features/meals/meal_template_builder_screen_test.dart` | T4 | widget tests |
| `test/ui/features/meals/meal_template_library_screen_test.dart` | T5 | widget tests |

**Decisions (settled in brainstorm — no task re-litigates):**

| # | Decision |
|---|---|
| D1 | Builder = mirror of S08 `meal_editor_screen`, retargeted `MealSnapshot`→`MealTemplate`, `FoodSnapshot`→`FoodRef`; persists via `MealTemplateRepository.save`. |
| D2 | Dev-reachable like S07 `/foods`: `/meal-templates` (+`/new`, `/:id`), **not** in the tab bar (placement → S11/S15). |
| D3 | Ingredient picker yields `({Food food, Grams grams})` (extracted from `AddIngredientScreen`); builder wraps → `FoodRef(foodId: food.id, grams)`, S08 wraps → `FoodSnapshot.from`. `FoodSnapshot.sourceFoodId` is nullable — never used for `FoodRef.foodId`. |
| D4 | `save()` returns the persisted `MealTemplate`; screen `context.pop`s it (S11's picker awaits it). |
| D5 | Edit propagation is automatic (live ref + derived macros); already-materialized days frozen. No sync code. |
| D6 | Delete: usage badge always shown; unused → confirm-delete; referencing-but-all-keep-≥1-slot → warn-confirm + cascade-strip; any plan would hit 0 slots → **block** with naming message. |
| D7 | No model changes; only the two pure helpers added to domain. |
| D8 | No goal/time fields (template is time-free; goal is profile-level). |

---

## Task 1: Pure template-usage helpers

**Role:** implement

**Goal:** Add pure reference-accounting for the delete flow: which plans use a template, and which would be emptied if its slots were stripped. No Flutter/Riverpod.

**Files:**
- Modify: `lib/domain/services/plan_scheduling.dart` — append the typedef + two functions
- Test: `test/domain/services/template_usage_test.dart` (new)

**Contract:**

```dart
// In lib/domain/services/plan_scheduling.dart (imports already present:
// plan_template.dart, plan_slot.dart).

/// Reference accounting for a library meal template.
/// [using]      — plans with ≥1 slot whose mealTemplateId == templateId.
/// [wouldEmpty] — subset of [using] left with zero slots after every slot
///                referencing templateId is removed (the template is the
///                plan's only meal). Drives the delete block.
typedef TemplateUsage = ({
  List<PlanTemplate> using,
  List<PlanTemplate> wouldEmpty,
});

TemplateUsage templateUsage(List<PlanTemplate> plans, String templateId) {
  final using = <PlanTemplate>[];
  final wouldEmpty = <PlanTemplate>[];
  for (final p in plans) {
    final refs = p.slots.where((s) => s.mealTemplateId == templateId).length;
    if (refs == 0) continue;
    using.add(p);
    if (refs == p.slots.length) wouldEmpty.add(p);
  }
  return (using: using, wouldEmpty: wouldEmpty);
}

/// The plan with every slot referencing [templateId] removed (order + other
/// fields preserved). Used for the cascade-strip write.
PlanTemplate stripTemplateFromPlan(PlanTemplate p, String templateId) =>
    p.copyWith(
      slots: [
        for (final s in p.slots)
          if (s.mealTemplateId != templateId) s,
      ],
    );
```

**Steps (TDD):**

- [ ] 1. **Failing test** — `test/domain/services/template_usage_test.dart`. Use `package:checks`. Build `PlanSlot`s with `MealTime` (use any existing factory/value — e.g. `MealTime(hour: 8, minute: 0)`; copy the shape from existing slot tests in `test/domain/`). Cases:
  - no plan references `'t1'` → `using` empty, `wouldEmpty` empty.
  - plan A has slots `[t1, t2]`, plan B has `[t3]` → `templateUsage([A,B],'t1').using` == `[A]`, `wouldEmpty` empty.
  - plan C has slots `[t1]` only → `using` == `[C]` **and** `wouldEmpty` == `[C]`.
  - plan D has `[t1, t1, t5]` (dup ref) → in `using`, not in `wouldEmpty` (3 slots, 2 refs).
  - `stripTemplateFromPlan(D,'t1').slots` == the single `t5` slot; name/days/active unchanged.

```dart
import 'package:checks/checks.dart';
import 'package:test/test.dart';
import 'package:crudo/domain/plan/plan_template.dart';
import 'package:crudo/domain/plan/plan_slot.dart';
import 'package:crudo/domain/shared/meal_time.dart';
import 'package:crudo/domain/services/plan_scheduling.dart';

PlanSlot _slot(String id, String tplId) =>
    PlanSlot(id: id, mealTemplateId: tplId, time: const MealTime(hour: 8, minute: 0));

void main() {
  test('no references → empty usage', () {
    final p = PlanTemplate(id: 'p', name: 'P', slots: [_slot('s1', 'other')]);
    final u = templateUsage([p], 't1');
    check(u.using).isEmpty();
    check(u.wouldEmpty).isEmpty();
  });

  test('referenced but plan keeps other slots → using, not wouldEmpty', () {
    final a = PlanTemplate(id: 'a', name: 'A', slots: [_slot('s1', 't1'), _slot('s2', 't2')]);
    final b = PlanTemplate(id: 'b', name: 'B', slots: [_slot('s3', 't3')]);
    final u = templateUsage([a, b], 't1');
    check(u.using.map((p) => p.id)).deepEquals(['a']);
    check(u.wouldEmpty).isEmpty();
  });

  test('template is plan only meal → wouldEmpty', () {
    final c = PlanTemplate(id: 'c', name: 'C', slots: [_slot('s1', 't1')]);
    final u = templateUsage([c], 't1');
    check(u.using.map((p) => p.id)).deepEquals(['c']);
    check(u.wouldEmpty.map((p) => p.id)).deepEquals(['c']);
  });

  test('duplicate refs but other slot remains → not wouldEmpty', () {
    final d = PlanTemplate(id: 'd', name: 'D', slots: [_slot('s1', 't1'), _slot('s2', 't1'), _slot('s3', 't5')]);
    final u = templateUsage([d], 't1');
    check(u.wouldEmpty).isEmpty();
    final stripped = stripTemplateFromPlan(d, 't1');
    check(stripped.slots.map((s) => s.id)).deepEquals(['s3']);
    check(stripped.name).equals('D');
  });
}
```

- [ ] 2. **Run — red:** `flutter test --timeout=90s test/domain/services/template_usage_test.dart` → expect failure: `templateUsage` / `stripTemplateFromPlan` undefined.
- [ ] 3. **Implement** the contract above in `plan_scheduling.dart`. (No codegen — pure Dart.) Confirm `MealTime` const ctor signature matches the project (adjust `_slot` helper if the real ctor differs — grep an existing `PlanSlot(` in `test/`).
- [ ] 4. **Run — green:** `flutter test --timeout=90s test/domain/services/template_usage_test.dart`.
- [ ] 5. Gates: `dart format .` · `flutter analyze` · `flutter test --timeout=90s`. Report for review.

**Skills:** `.agents/skills/dart-add-unit-test`, `.agents/skills/dart-migrate-to-checks-package`.

**Out of scope:** UI, controllers, any file outside `plan_scheduling.dart` + the new test. Do not change `PlanTemplate`/`PlanSlot`.

---

## Task 2: Draft, controller, row provider

**Role:** implement

**Goal:** All meal-template view-models: the immutable `MealTemplateDraft`, the `MealTemplateDraftController` (create/edit/save/delete), and the `mealTemplateRows` library-feed provider. Tested with `ProviderContainer` + in-memory repos.

**Files:**
- Create: `lib/ui/features/meals/view_models/meal_template_draft.dart`
- Create: `lib/ui/features/meals/view_models/meal_template_draft_controller.dart` (+ `.g.dart` via build_runner)
- Create: `lib/ui/features/meals/view_models/meal_template_rows.dart` (+ `.g.dart`)
- Test: `test/ui/features/meals/meal_template_draft_controller_test.dart` (new)

**Contract:**

```dart
// meal_template_draft.dart
import 'package:crudo/domain/food/food.dart';
import 'package:crudo/domain/food/food_ref.dart';
import 'package:crudo/domain/meal/meal_template.dart';
import 'package:crudo/domain/services/nutrition.dart'; // mealTemplateMacros
import 'package:crudo/domain/shared/enums.dart';        // MealTag
import 'package:crudo/domain/shared/grams.dart';
import 'package:crudo/domain/shared/macros.dart';

/// Resolved display data for one ingredient row (name + macros) so the widget
/// never resolves foods itself.
typedef IngredientRowVm = ({String name, Grams grams, int kcal});

/// In-progress library-template edit. Immutable; the controller swaps whole
/// drafts. `foods` are live FoodRefs (foodId + grams). Mirrors meal_draft.dart.
class MealTemplateDraft {
  const MealTemplateDraft({
    this.name = '',
    this.tags = const <MealTag>[],
    this.foods = const <FoodRef>[],
  });

  factory MealTemplateDraft.from(MealTemplate t) => MealTemplateDraft(
    name: t.name,
    tags: t.tags,
    foods: t.foods,
  );

  final String name;
  final List<MealTag> tags;
  final List<FoodRef> foods;

  /// Build the persistable template at [id] ('' while editing/previewing).
  MealTemplate toTemplate(String id) => MealTemplate(
    id: id,
    name: name.trim(),
    tags: tags,
    foods: foods,
  );

  /// Macros over the current foods, resolved against [foodsById].
  Macros macros(Map<String, Food> foodsById) =>
      mealTemplateMacros(toTemplate(''), foodsById);

  /// Resolved ingredient rows for display.
  List<IngredientRowVm> rows(Map<String, Food> foodsById) => [
    for (final r in foods)
      (
        name: foodsById[r.foodId]?.name ?? 'Unknown food',
        grams: r.grams,
        kcal: foodsById[r.foodId] == null
            ? 0
            : macrosForFood(foodsById[r.foodId]!, r.grams.value).kcal.round(),
      ),
  ];

  /// S02 rule: non-blank name + ≥1 ingredient.
  bool get canSave => name.trim().isNotEmpty && foods.isNotEmpty;

  MealTemplateDraft withName(String v) => _copy(name: v);

  MealTemplateDraft toggleTag(MealTag t) => _copy(
    tags: tags.contains(t)
        ? [for (final x in tags) if (x != t) x]
        : [...tags, t],
  );

  MealTemplateDraft addFood(FoodRef r) => _copy(foods: [...foods, r]);

  MealTemplateDraft removeFood(int index) =>
      _copy(foods: [for (final (i, r) in foods.indexed) if (i != index) r]);

  MealTemplateDraft setGrams(int index, Grams g) => _copy(
    foods: [
      for (final (i, r) in foods.indexed)
        i == index ? r.copyWith(grams: g) : r,
    ],
  );

  MealTemplateDraft _copy({String? name, List<MealTag>? tags, List<FoodRef>? foods}) =>
      MealTemplateDraft(
        name: name ?? this.name,
        tags: tags ?? this.tags,
        foods: foods ?? this.foods,
      );
}
```

```dart
// meal_template_draft_controller.dart
import 'package:crudo/config/di.dart';
import 'package:crudo/domain/food/food.dart';
import 'package:crudo/domain/meal/meal_template.dart';
import 'package:crudo/domain/plan/plan_template.dart';
import 'package:crudo/domain/repositories/meal_template_repository.dart';
import 'package:crudo/domain/repositories/plan_template_repository.dart';
import 'package:crudo/domain/services/plan_scheduling.dart'; // templateUsage, stripTemplateFromPlan
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'meal_template_draft.dart';

part 'meal_template_draft_controller.g.dart';

/// Outcome of a delete attempt — lets the screen pick block vs warn vs done.
/// blockedByEmpty:true  → refused (affected = plans that would be emptied).
/// deleted:false, blockedByEmpty:false, affected non-empty → needs confirm
///   (affected = plans that lose this meal); call delete(confirmed: true).
/// deleted:true → template removed (+ cascade-stripped plans persisted).
typedef DeleteOutcome = ({
  bool deleted,
  bool blockedByEmpty,
  List<PlanTemplate> affected,
});

@riverpod
class MealTemplateDraftController extends _$MealTemplateDraftController {
  late MealTemplate _initial; // blank (id '') on create, loaded on edit
  late MealTemplateRepository _repo;
  Map<String, Food> _foodsById = const {};

  @override
  Future<MealTemplateDraft> build(String? templateId) async {
    _repo = ref.read(mealTemplateRepositoryProvider);
    // One-shot food resolution (NOT a stream watch): a library emit mid-edit
    // must not rebuild and discard the draft (plan_detail_controller pattern).
    _foodsById = {
      for (final f in await ref.read(foodRepositoryProvider).getAll()) f.id: f,
    };
    if (templateId == null) {
      _initial = const MealTemplate(id: '', name: '');
      return const MealTemplateDraft();
    }
    final t = await _repo.getById(templateId);
    if (t == null) throw StateError('no meal template with id $templateId');
    _initial = t;
    return MealTemplateDraft.from(t);
  }

  Map<String, Food> get foodsById => _foodsById;

  bool get isDirty {
    final d = state.value;
    if (d == null) return false;
    return d.toTemplate(_initial.id) != _initial;
  }

  void setName(String v) => _update((d) => d.withName(v));
  void toggleTag(MealTag t) => _update((d) => d.toggleTag(t));
  void addFood(FoodRef r) => _update((d) => d.addFood(r));
  void removeFood(int i) => _update((d) => d.removeFood(i));
  void setGrams(int i, Grams g) => _update((d) => d.setGrams(i, g));

  /// Persist + return the saved template (caller pops it). Create mints an id.
  Future<MealTemplate> save() async {
    final d = state.requireValue;
    if (!d.canSave) throw StateError('draft has validation issues');
    final id = _initial.id.isEmpty ? ref.read(idGeneratorProvider).newId() : _initial.id;
    final saved = d.toTemplate(id);
    await _repo.save(saved);
    _initial = saved;
    return saved;
  }

  /// Guarded delete. See DeleteOutcome. confirmed:true performs the cascade.
  Future<DeleteOutcome> delete({bool confirmed = false}) async {
    if (_initial.id.isEmpty) {
      return (deleted: false, blockedByEmpty: false, affected: const []);
    }
    final plans = await ref.read(planTemplateRepositoryProvider).getAll();
    final usage = templateUsage(plans, _initial.id);
    if (usage.wouldEmpty.isNotEmpty) {
      return (deleted: false, blockedByEmpty: true, affected: usage.wouldEmpty);
    }
    if (usage.using.isNotEmpty && !confirmed) {
      return (deleted: false, blockedByEmpty: false, affected: usage.using);
    }
    final planRepo = ref.read(planTemplateRepositoryProvider);
    for (final p in usage.using) {
      await planRepo.save(stripTemplateFromPlan(p, _initial.id));
    }
    await _repo.delete(_initial.id);
    return (deleted: true, blockedByEmpty: false, affected: usage.using);
  }

  void _update(MealTemplateDraft Function(MealTemplateDraft) fn) {
    final d = state.value;
    if (d != null) state = AsyncData(fn(d));
  }
}
```

```dart
// meal_template_rows.dart
import 'package:crudo/domain/food/food.dart';
import 'package:crudo/domain/meal/meal_template.dart';
import 'package:crudo/domain/plan/plan_template.dart';
import 'package:crudo/domain/services/nutrition.dart';        // mealTemplateMacros
import 'package:crudo/domain/services/plan_scheduling.dart';  // templateUsage
import 'package:crudo/domain/shared/enums.dart';              // MealTag
import 'package:crudo/ui/features/today/view_models/today_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'meal_template_rows.g.dart';

/// One library row — display data resolved up front.
typedef MealTemplateRowVm = ({
  String id,
  String name,
  List<MealTag> tags,
  int kcal,        // mealTemplateMacros, rounded
  int usedInPlans, // templateUsage(plans, id).using.length
});

/// Library feed. Sync derived provider (mirrors plansList): reads .value of
/// the S06 stream providers; empty until data arrives.
@riverpod
List<MealTemplateRowVm> mealTemplateRows(Ref ref) {
  final templates =
      ref.watch(mealTemplatesProvider).value ?? const <MealTemplate>[];
  final Map<String, Food> foods = {
    for (final f in ref.watch(foodsProvider).value ?? const <Food>[]) f.id: f,
  };
  final plans =
      ref.watch(planTemplatesProvider).value ?? const <PlanTemplate>[];
  return [
    for (final t in templates)
      (
        id: t.id,
        name: t.name,
        tags: t.tags,
        kcal: mealTemplateMacros(t, foods).kcal.round(),
        usedInPlans: templateUsage(plans, t.id).using.length,
      ),
  ];
}
```

**Steps (TDD):**

- [ ] 1. **Failing test** — `test/ui/features/meals/meal_template_draft_controller_test.dart`. Build a `ProviderContainer` overriding `mealTemplateRepositoryProvider`, `planTemplateRepositoryProvider`, `foodRepositoryProvider` with in-memory fakes seeded with ≥2 foods + templates + plans (copy the override harness from `test/ui/features/plans/` S10 controller tests). Assert:
  - create: `build(null)` → draft `canSave` false; after `setName('X')` + `addFood(FoodRef(foodId: <seeded>, grams: Grams(100)))` → `canSave` true; `save()` returns a template with a non-empty minted id; repo now has it.
  - edit: `build(existingId)` → draft matches; `setName` → `isDirty` true; `save()` keeps id; repo reflects new name.
  - `removeFood`/`setGrams` mutate `foods`; `draft.macros(foodsById)` / `rows` recompute.
  - delete unused template → `deleted:true`; repo no longer has it.
  - delete a template referenced by a plan that has another slot, `confirmed:false` → `(deleted:false, blockedByEmpty:false, affected:[that plan])`; `confirmed:true` → `deleted:true`, the plan persisted without the stripped slot, template gone.
  - delete a template that is a plan's only slot → `(deleted:false, blockedByEmpty:true, affected:[that plan])`; nothing written (template still present).
  - `mealTemplateRows` (override stream providers or use the dev seed) emits rows with correct `kcal`, `tags`, `usedInPlans`.
- [ ] 2. **Run — red:** `flutter test --timeout=90s test/ui/features/meals/meal_template_draft_controller_test.dart` → expect failure (types undefined / no `.g.dart`).
- [ ] 3. **Implement** the three files above, then `dart run build_runner build` (generates both `.g.dart`). Confirm `idGeneratorProvider` import path (`package:crudo/config/di.dart` — grep `idGeneratorProvider` to confirm; it's used by `food_draft_controller`). Confirm `FoodRef.copyWith` exists (freezed — yes).
- [ ] 4. **Run — green:** `flutter test --timeout=90s test/ui/features/meals/meal_template_draft_controller_test.dart`.
- [ ] 5. Gates: `dart format .` · `flutter analyze` · `flutter test --timeout=90s`. Report for review.

**Skills:** `.agents/skills/flutter-riverpod`, `.agents/skills/dart-add-unit-test`, `.agents/skills/dart-migrate-to-checks-package`, `.agents/skills/dart-generate-test-mocks`.

**Out of scope:** screens, routing, the ingredient picker (T3), any S08 file. Do not add a tab-bar entry.

---

## Task 3: Extract the ingredient picker to yield `(Food, Grams)`

**Role:** ui

**Goal:** Make `AddIngredientScreen` pop a `({Food food, Grams grams})` record instead of a `FoodSnapshot`, so both the S08 meal editor and the new template builder can wrap it into their own type. Behavior-preserving for S08.

**Files:**
- Modify: `lib/ui/features/meals/views/add_ingredient_screen.dart` — change the "Add to Meal" CTA pop payload
- Modify: `lib/ui/features/meals/views/meal_editor_screen.dart` — `_addIngredient` wraps the record into `FoodSnapshot.from`

**Contract:**

```dart
// add_ingredient_screen.dart — the bottomNavigationBar CTA onPressed:
// BEFORE: onPressed: () => context.pop(FoodSnapshot.from(picked, Grams(_grams!))),
// AFTER:
onPressed: () => context.pop((food: picked, grams: Grams(_grams!))),
// Remove the now-unused FoodSnapshot import if nothing else uses it (the
// GramsEntry baseline still needs FoodSnapshot.from(picked, const Grams(100)) —
// keep that import; only the pop payload changes).
```

```dart
// meal_editor_screen.dart — _addIngredient:
Future<void> _addIngredient() async {
  final r = await context.push<({Food food, Grams grams})>(
    '/meal/${dayParam(widget.date)}/${widget.mealId}/edit/add-ingredient',
  );
  if (r != null) _ctrl.addItem(FoodSnapshot.from(r.food, r.grams));
}
// Add import: import '../../../../domain/food/food.dart';  (for the Food type)
```

**Steps (TDD):**

- [ ] 1. **Failing test** — extend (or add to) the existing add-ingredient widget test under `test/ui/features/meals/`. Find the test that drives the picker and asserts the popped value; change its expectation to the record shape `(food: <Food>, grams: Grams(...))`. If no such direct test exists, add `test/ui/features/meals/add_ingredient_picker_test.dart`: pump `AddIngredientScreen` inside a router that captures the pop result, pick a seeded food, tap "Add to Meal", assert the captured result is `({Food food, Grams grams})` with the expected food id + grams.
- [ ] 2. **Run — red:** `flutter test --timeout=90s test/ui/features/meals/` → the picker test fails on the old `FoodSnapshot` expectation.
- [ ] 3. **Implement** both edits above.
- [ ] 4. **Run — green:** `flutter test --timeout=90s test/ui/features/meals/` — **the existing S08 `meal_editor_screen` tests must stay green** (the editor still receives a `FoodSnapshot` via the wrap). This is the regression gate.
- [ ] 5. Gates: `dart format .` · `flutter analyze` · `flutter test --timeout=90s`. Report for review.

**Skills:** `.agents/skills/flutter-add-widget-test`, `.agents/skills/flutter-expert`.

**Out of scope:** the builder screen + library (T4/T5), controllers (T2), routing changes. Do not alter `GramsEntry`/`GramsSheet`. Keep the picker's UI/copy identical.

---

## Task 4: Meal-template builder screen + routes

**Role:** ui

**Goal:** The create/edit form at `/meal-templates/new` and `/meal-templates/:id`: name, tag pills, ingredient list (add via the T3 picker, edit grams via `GramsSheet`, remove), live gradient macro preview, save→pop, discard guard, and the guarded delete flow.

**Files:**
- Create: `lib/ui/features/meals/views/meal_template_builder_screen.dart`
- Modify: `lib/routing/app_router.dart` — add the `/meal-templates` subtree (this task adds `new` + `:id` + their `add-ingredient`; T5 adds the `/meal-templates` list builder)
- Test: `test/ui/features/meals/meal_template_builder_screen_test.dart` (new)

**Contract:**

```dart
// app_router.dart — add a sibling pushed route (mirror the /foods block).
GoRoute(
  path: '/meal-templates/new',
  builder: (context, state) => const MealTemplateBuilderScreen(templateId: null),
  routes: [
    GoRoute(
      path: 'add-ingredient',
      builder: (context, state) => const AddIngredientScreen(),
    ),
  ],
),
GoRoute(
  path: '/meal-templates/:id',
  builder: (context, state) =>
      MealTemplateBuilderScreen(templateId: state.pathParameters['id']!),
  routes: [
    GoRoute(
      path: 'add-ingredient',
      builder: (context, state) => const AddIngredientScreen(),
    ),
  ],
),
// Import: package:crudo/ui/features/meals/views/meal_template_builder_screen.dart
// (AddIngredientScreen already imported.)
```

```dart
// meal_template_builder_screen.dart — public shape:
class MealTemplateBuilderScreen extends ConsumerStatefulWidget {
  const MealTemplateBuilderScreen({required this.templateId, super.key});
  final String? templateId; // null = create
  ...
}
```

Behavior (mirror `meal_editor_screen.dart` structure — copy its scaffold/header/PopScope/sections, retargeting controller calls):
- Watch `mealTemplateDraftControllerProvider(templateId)`; `.when` → form / spinner / "Meal not found".
- Header: back (`_maybePop`, dirty→`showCrudoSheet` "Discard changes?" — copy S08's `_maybePop`); title = `draft.name` (or "New meal" when blank); `SAVE` `TextButton` (`Opacity` dimmed when `!draft.canSave`) → `save()` then `if (mounted) context.pop(saved)`.
- On edit (`templateId != null`): show `Used in N plans` next to the title (read `mealTemplateRowsProvider`, find this id's `usedInPlans`; or `templateUsage(ref.watch(planTemplatesProvider).value ?? const [], templateId!).using.length`).
- NAME `TextField` (key `ValueKey('template-name')`, `softInputDecoration`, `onChanged: ctrl.setName`).
- TAGS: `Wrap` of `Pill`(key `tag-${t.name}`) over `MealTag.values`, `selected: draft.tags.contains(t)`, `onTap: () => ctrl.toggleTag(t)`, label `mealTagLabels[t]!`.
- INGREDIENTS tonal container: header "Ingredients · N ITEMS"; for `draft.rows(ctrl.foodsById)` render rows (key `ingredient-$i`: name · `gramsLabel`/`${grams}g` · `${kcal} kcal`; tap → edit grams; trailing remove → `ctrl.removeFood(i)`); empty placeholder (key `template-empty`); "ADD INGREDIENT" (key `add-ingredient`) → `_addIngredient`.
- Grams edit: build `FoodSnapshot.from(foodsById[ref.foodId]!, ref.grams)` and `showCrudoSheet<Grams>(context, builder: (_) => GramsSheet(item: snapshot))`; on result → `ctrl.setGrams(i, g)`.
- `_addIngredient`: `final r = await context.push<({Food food, Grams grams})>('/meal-templates/${templateId ?? 'new'}/add-ingredient'); if (r != null) ctrl.addFood(FoodRef(foodId: r.food.id, grams: r.grams));`
- MACRO PREVIEW: gradient card (copy S08), `draft.macros(ctrl.foodsById)` → keyed `template-preview-kcal` kcal + P/C/F.
- DELETE (edit only): `SecondaryAction(label: 'Delete meal', onTap: _delete)`.
- `PopScope(canPop: !ctrl.isDirty, onPopInvokedWithResult: (didPop,_) { if (!didPop) _maybePop(); })`.

```dart
// _delete flow in the screen:
Future<void> _delete() async {
  var out = await _ctrl.delete();
  if (!mounted) return;
  if (out.blockedByEmpty) {
    final names = out.affected.map((p) => p.name).join(', ');
    showCrudoToast(
      context,
      "This is the only meal in $names — add another meal or delete that plan first.",
      kind: ToastKind.warn,
    );
    return;
  }
  if (!out.deleted && out.affected.isNotEmpty) {
    final names = out.affected.map((p) => p.name).join(', ');
    final ok = await showCrudoSheet<bool>(
      context,
      builder: (sheetCtx) => SheetScaffold(
        title: 'Delete meal?',
        body: Text('$names will lose this meal.', style: CrudoText.body),
        cta: Column(mainAxisSize: MainAxisSize.min, children: [
          PrimaryCta(label: 'Delete', onPressed: () => Navigator.of(sheetCtx).pop(true)),
          const SizedBox(height: Spacing.sm),
          SecondaryAction(label: 'Cancel', onTap: () => Navigator.of(sheetCtx).pop(false)),
        ]),
      ),
    );
    if (ok != true) return;
    out = await _ctrl.delete(confirmed: true);
  } else if (!out.deleted) {
    // unused: plain confirm
    final ok = await showCrudoSheet<bool>(
      context,
      builder: (sheetCtx) => SheetScaffold(
        title: 'Delete meal?',
        body: Text('This meal will be removed from your library.', style: CrudoText.body),
        cta: Column(mainAxisSize: MainAxisSize.min, children: [
          PrimaryCta(label: 'Delete', onPressed: () => Navigator.of(sheetCtx).pop(true)),
          const SizedBox(height: Spacing.sm),
          SecondaryAction(label: 'Cancel', onTap: () => Navigator.of(sheetCtx).pop(false)),
        ]),
      ),
    );
    if (ok != true) return;
    out = await _ctrl.delete(confirmed: true);
  }
  if (out.deleted && mounted) context.pop();
}
```

> Note: an unused template's first `delete()` returns `affected:[]` → falls to the `else if (!out.deleted)` plain-confirm branch. Keep both branches.

**Steps (TDD):**

- [ ] 1. **Failing test** — `test/ui/features/meals/meal_template_builder_screen_test.dart`. Pump the screen in a `MaterialApp`/router with overridden providers (copy the harness from `test/ui/features/plans/plan_detail_screen_test.dart` and the S08 editor test). Cases:
  - create: empty form; `SAVE` disabled; enter name + (stub addFood via controller, or drive the picker) → `SAVE` enabled; tap SAVE → repo has new template; route popped with it.
  - tag toggle selects/deselects a `Pill`.
  - remove ingredient drops a row; macro preview (key `template-preview-kcal`) updates.
  - edit existing: shows `Used in N plans`; delete unused → confirm sheet → deletes; delete referenced-non-empty → warn sheet names the plan → confirm strips; delete sole-meal → warn toast, no delete (template still present).
  - dirty back shows discard sheet; pristine back pops.
- [ ] 2. **Run — red:** `flutter test --timeout=90s test/ui/features/meals/meal_template_builder_screen_test.dart` → fails (screen undefined).
- [ ] 3. **Implement** the screen + routes. No codegen (screen has no annotations). Reuse `Pill`, `PrimaryCta`, `SecondaryAction`, `GramsSheet`, `softInputDecoration`, `showCrudoSheet`/`SheetScaffold`, `showCrudoToast`, gradient-preview pattern. Dimensions from `dimensions.dart` only.
- [ ] 4. **Run — green:** `flutter test --timeout=90s test/ui/features/meals/meal_template_builder_screen_test.dart`.
- [ ] 5. Gates: `dart format .` · `flutter analyze` · `flutter test --timeout=90s`. Report for review.

**Skills:** `.agents/skills/flutter-riverpod`, `.agents/skills/flutter-setup-declarative-routing`, `.agents/skills/flutter-add-widget-test`, `.agents/skills/flutter-expert`, `.agents/skills/flutter-apply-architecture-best-practices`.

**Out of scope:** the library list screen + `/meal-templates` list route (T5), domain (T1), controllers (T2). No tab-bar entry. No raw px — snap to tokens (`AGENTS.md` design rules; no 1px borders / drop shadows).

---

## Task 5: Meal-template library list screen + route

**Role:** ui

**Goal:** The dev-reachable `/meal-templates` list: one card per template (name · kcal · tags · `Used in N plans`), "New" CTA, tap→edit. Mirrors `FoodLibraryScreen`.

**Files:**
- Create: `lib/ui/features/meals/views/meal_template_library_screen.dart`
- Modify: `lib/routing/app_router.dart` — add the parent `/meal-templates` route (the `new`/`:id` children already exist from T4; restructure so `new` + `:id` become children of `/meal-templates`, OR keep them as siblings and add a standalone `/meal-templates` route — pick whichever keeps go_router happy; siblings are simplest and match how `/foods` + `/foods/new` are written)
- Test: `test/ui/features/meals/meal_template_library_screen_test.dart` (new)

**Contract:**

```dart
// app_router.dart — add (sibling form, mirroring /foods which is path:'/foods'
// with child 'new'):
GoRoute(
  path: '/meal-templates',
  builder: (context, state) => const MealTemplateLibraryScreen(),
),
// Keep the T4 '/meal-templates/new' and '/meal-templates/:id' routes as
// written. (go_router matches '/meal-templates/new' before ':id'.)
```

```dart
// meal_template_library_screen.dart
class MealTemplateLibraryScreen extends ConsumerWidget {
  const MealTemplateLibraryScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // final rows = ref.watch(mealTemplateRowsProvider);
    // Header: 'Meals' title + 'New' action → context.push('/meal-templates/new').
    // Body: rows.isEmpty → centered 'No meals yet' (key 'templates-empty');
    //   else ListView of cards. Each card (key 'template-row-${vm.id}'):
    //     name (CrudoText.headlineSm), subtitle '${vm.kcal} kcal · ${tags}',
    //     usage chip: vm.usedInPlans == 0 ? 'Unused' : 'Used in ${n} plan${n==1?'':'s'}'.
    //   tap → context.push('/meal-templates/${vm.id}').
    // tags label via mealTagLabels[t]! joined ' · '.
    ...
  }
}
```

**Steps (TDD):**

- [ ] 1. **Failing test** — `test/ui/features/meals/meal_template_library_screen_test.dart`. Override `mealTemplatesProvider`/`foodsProvider`/`planTemplatesProvider` (or use the dev seed harness) so `mealTemplateRows` yields ≥2 rows, one referenced by a plan. Assert: one card per template (keys present); subtitle shows kcal + tags; the referenced template shows `Used in 1 plan`, the unreferenced shows `Unused`; tapping a card pushes `/meal-templates/:id` (capture via a spy router); the "New" action pushes `/meal-templates/new`; empty rows → `templates-empty` text.
- [ ] 2. **Run — red:** `flutter test --timeout=90s test/ui/features/meals/meal_template_library_screen_test.dart` → fails (screen undefined).
- [ ] 3. **Implement** the screen + route. Reuse a tonal card style (copy the S10 `plan_list_card.dart` / `SelectionCard` pattern) + `Pill` for tags/usage. Tokens only.
- [ ] 4. **Run — green:** `flutter test --timeout=90s test/ui/features/meals/meal_template_library_screen_test.dart`.
- [ ] 5. Gates: `dart format .` · `flutter analyze` · `flutter test --timeout=90s`. Report for review.

**Skills:** `.agents/skills/flutter-riverpod`, `.agents/skills/flutter-setup-declarative-routing`, `.agents/skills/flutter-add-widget-test`, `.agents/skills/flutter-expert`.

**Out of scope:** builder screen (T4), controllers (T2), domain (T1). No tab-bar entry (placement → S11/S15). No raw px; no 1px borders / drop shadows.

---

## Plan self-review

- **Spec coverage:** library list → T5; builder create/edit + save→pop + discard → T4; draft/controller/rows + delete logic → T2; pure `templateUsage`/`stripTemplateFromPlan` → T1; picker `FoodRef` extraction → T3; edit-propagation (D5) needs no code (derived). ✓
- **Type consistency:** `MealTemplateDraft`, `MealTemplateDraftController`, `DeleteOutcome`, `IngredientRowVm`, `MealTemplateRowVm`, `mealTemplateRows`, `templateUsage`/`TemplateUsage`, `stripTemplateFromPlan` used identically across T1→T5. Picker payload `({Food food, Grams grams})` consistent in T3↔T4. ✓
- **No placeholders:** all code blocks concrete; reused widgets named with verified signatures. ✓
