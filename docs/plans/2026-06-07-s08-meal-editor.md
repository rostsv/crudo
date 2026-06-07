# S08 Meal Editor — Implementation Plan

> **For the worker:** implement task-by-task, top to bottom; each task = contract + steps; read the `.agents/skills` each task names before starting it. Spec: `docs/specs/2026-06-07-s08-meal-editor.md`. Repo rules: `AGENTS.md`. Workers do **not** commit — finish each task with format → analyze → test, then report done for review.

**Goal:** A full `mealDetail` pushed route (replacing the S06 `MealSheet`), a day-instance meal editor (name/tags/items, draft committed once via `replaceMeal`), swap-from-library (SwapSheet over `MealTemplateRepository`), an add-ingredient picker reusing the S07 library list with a custom-food round-trip — all gated by `canEditMealContent`, with copy-on-write future-day detach.

**Architecture:** Two tiny domain additions (`mealSnapshotFromTemplate`, `FoodSnapshot.scaledTo`) — the engine (`replaceMeal`, predicates, CoW contract) shipped at S05. Then: `DayController` content-op path (today+future), `MealDraft`+`MealDraftController` (meals feature), S07 retrofits (reusable `FoodLibraryList`, form pop-result), and the four UI surfaces. Dependency rule unchanged: View → Controller → Repository. **Accepted cross-feature dependency:** the meals feature imports `today/view_models/day_controller.dart` + `today_providers.dart` — `DayController` is *the* Day-aggregate controller; duplicating it would mean two sources of truth (S07's "features don't import each other's view_models" note was about trivial stream providers).

**Tech stack:** Flutter, Riverpod 3 codegen (`@riverpod`), `go_router`, `package:checks`, `flutter_test`. Codegen: `dart run build_runner build` after adding/altering provider files.

**Visual target:** `docs/design/prototype/screens/meal.jsx` (`MealDetailScreen` 1–122, `AddMealScreen` 129–246 minus the time row, `AddIngredientScreen` 258–412) + `sheets.jsx` (`SwapSheet` 45–73) — composition only; every dimension snaps to `lib/ui/core/themes/dimensions.dart` tokens per `docs/design_system.md §5`. Two deliberate deviations: the picker CTA's dashed border → tonal container (no-line rule); the 44px kcal number → `CrudoText.display` (40, nearest type token).

**Color/theme idiom:** wherever a snippet says `colors`, obtain `CrudoColors` exactly like `lib/ui/features/today/views/meal_sheet.dart` does (`Theme.of(context).extension<CrudoColors>()!`).

**Status discipline (review watchpoint):** display status ONLY via `mealStatus(day, mealId, now)`; edit/swap eligibility ONLY via `canEditMealContent` / `canSkipMeal` / `canSnoozeMeal`. Never call `deriveMealStatus` from UI, never compare times by hand.

---

## Task 1: Domain — `mealSnapshotFromTemplate` + `FoodSnapshot.scaledTo`

**Role:** `implement`. Pure domain; no Flutter/Riverpod imports — the architecture test enforces this.

**Goal:** one shared template→snapshot resolution path (used by `buildDayFromPlan` today and the swap flow next), and linear grams rescaling on the pure food value.

**Files:**
- Modify: `lib/domain/meal/food_snapshot.dart`
- Modify: `lib/domain/services/meal_lifecycle.dart`
- Test: `test/domain/services/meal_lifecycle_test.dart` (add groups), `test/domain/meal/food_snapshot_test.dart` (extend if present, else add group in the existing meal test file)

**Contract:**

```dart
// food_snapshot.dart — add inside the FoodSnapshot class body:

  /// The same food at a different weight: absolutes scale linearly
  /// (newGrams / grams) — never re-resolves the library; the snapshot is
  /// the source (S05 §1.1: per-100g derivable, grams edits scale linearly).
  FoodSnapshot scaledTo(Grams newGrams) {
    final factor = newGrams.value / grams.value;
    return copyWith(
      grams: newGrams,
      protein: protein * factor,
      carbs: carbs * factor,
      fats: fats * factor,
      kcal: kcal * factor,
    );
  }
```

```dart
// meal_lifecycle.dart — add (above buildDayFromPlan):

/// Resolves a meal template into a day-ready snapshot: each FoodRef becomes
/// an UNCHECKED MealItem whose FoodSnapshot bakes the absolutes at creation
/// (the only snapshot factory — S05 §1.4). Dangling food refs are dropped
/// defensively. Shared by buildDayFromPlan and the S08 swap flow, so a
/// replacement MealSnapshot can never arrive with pre-checked items
/// (S05-review obligation discharged by construction).
MealSnapshot mealSnapshotFromTemplate(
  MealTemplate template,
  List<Food> foods,
) {
  final foodsById = {for (final f in foods) f.id: f};
  return MealSnapshot(
    sourceMealTemplateId: template.id,
    name: template.name,
    tags: template.tags,
    items: [
      for (final ref in template.foods)
        if (foodsById[ref.foodId] != null)
          MealItem(food: FoodSnapshot.from(foodsById[ref.foodId]!, ref.grams)),
    ],
  );
}
```

`buildDayFromPlan` refactors its loop body to use it (drop the inline `foodsById`/items construction; the `templatesById` map stays):

```dart
  final slots = [...plan.slots]..sort((a, b) => a.time.compareTo(b.time));
  final meals = <ScheduledMeal>[];
  for (final slot in slots) {
    final template = templatesById[slot.mealTemplateId];
    if (template == null) continue;
    final snapshot = mealSnapshotFromTemplate(template, foods);
    if (snapshot.items.isEmpty) continue;
    meals.add(ScheduledMeal(id: newId(), time: slot.time, meal: snapshot));
  }
```

**Steps (TDD):**

- [ ] **1. Failing tests.** In `test/domain/services/meal_lifecycle_test.dart` add:

```dart
  group('mealSnapshotFromTemplate', () {
    const oats = Food(
      id: 'f-oats', name: 'Oats', category: FoodCategory.grain,
      protein: 13, carbs: 60, fats: 7, kcalPer100g: 370,
    );
    const template = MealTemplate(
      id: 't1', name: 'Bowl', tags: [MealTag.breakfast],
      foods: [
        FoodRef(foodId: 'f-oats', grams: Grams(50)),
        FoodRef(foodId: 'ghost', grams: Grams(10)),
      ],
    );

    test('resolves refs, bakes absolutes, drops dangling, nothing checked', () {
      final snap = mealSnapshotFromTemplate(template, const [oats]);
      check(snap.sourceMealTemplateId).equals('t1');
      check(snap.name).equals('Bowl');
      check(snap.tags).deepEquals([MealTag.breakfast]);
      check(snap.items.length).equals(1);
      check(snap.items.single.checked).isFalse();
      check(snap.items.single.food.sourceFoodId).equals('f-oats');
      check(snap.items.single.food.kcal).equals(185); // 370 × 50/100
      check(snap.items.single.food.protein).equals(6.5);
    });

    test('all refs dangling → empty items (caller decides)', () {
      final snap = mealSnapshotFromTemplate(template, const []);
      check(snap.items).isEmpty();
    });
  });

  group('FoodSnapshot.scaledTo', () {
    const oats = Food(
      id: 'f-oats', name: 'Oats', category: FoodCategory.grain,
      protein: 13, carbs: 60, fats: 7, kcalPer100g: 370,
    );

    test('scales absolutes linearly and replaces grams', () {
      final base = FoodSnapshot.from(oats, const Grams(100));
      final scaled = base.scaledTo(const Grams(150));
      check(scaled.grams).equals(const Grams(150));
      check(scaled.protein).equals(19.5);
      check(scaled.carbs).equals(90);
      check(scaled.fats).equals(10.5);
      check(scaled.kcal).equals(555);
      check(scaled.sourceFoodId).equals('f-oats');
      check(scaled.name).equals('Oats');
    });

    test('zero-macro food stays zero at any weight', () {
      const water = Food(
        id: 'f-water', name: 'Water', category: FoodCategory.custom,
        protein: 0, carbs: 0, fats: 0, kcalPer100g: 0,
      );
      final scaled = FoodSnapshot.from(water, const Grams(100))
          .scaledTo(const Grams(250));
      check(scaled.kcal).equals(0);
    });
  });
```

Add the missing imports at the top of the test file (`MealTemplate`, `FoodRef`, `MealItem` are likely already imported — verify).

- [ ] **2. Run:** `flutter test test/domain/services/meal_lifecycle_test.dart` → FAIL (`mealSnapshotFromTemplate` undefined, `scaledTo` undefined).
- [ ] **3. Implement** both additions + the `buildDayFromPlan` refactor exactly as in the contract. Run `dart run build_runner build` (freezed file untouched — only needed if the analyzer complains; `scaledTo` uses `copyWith`, no new fields).
- [ ] **4. Run:** `flutter test test/domain` → all PASS (existing `buildDayFromPlan` matrix proves the refactor is behavior-neutral).
- [ ] **5.** `dart format .` · `flutter analyze` clean.

**Skills:** `dart-add-unit-test`, `dart-migrate-to-checks-package`.
**Out of scope:** controllers, widgets, any repo access from domain.

---

## Task 2: `DayController.replaceMeal` — content path with CoW detach

**Role:** `implement`.

**Goal:** the one content op the UI calls. Today: persists the swap/edit. Future date: the save **is** the copy-on-write detach (S05 §4.3 — repo hit wins thereafter). Past: rejects. Marking ops untouched.

**Files:**
- Modify: `lib/ui/features/today/view_models/day_controller.dart`
- Test: `test/ui/features/today/view_models/day_controller_test.dart` (extend — reuse its container/harness verbatim)

**Contract** (add to `DayController`; new import `package:crudo/domain/meal/meal_snapshot.dart`):

```dart
  /// Content op (S08): allowed for today AND future days — saving a
  /// future-day preview IS the copy-on-write detach (S05 §4.3: the repo
  /// hit wins on every later read; template edits no longer touch it).
  /// Past days reject. Marking/skip/snooze stay today-only (_apply).
  Future<void> replaceMeal(String mealId, MealSnapshot newMeal) =>
      _applyContent(
        (d, now, today) => d.replaceMeal(mealId, newMeal, now, today),
      );

  Future<void> _applyContent(
    Day Function(Day day, DateTime now, DateTime today) op,
  ) async {
    final today = ref.read(todayProvider);
    if (date.isBefore(today)) {
      throw StateError('day $date is read-only (today is $today)');
    }
    final day = await future;
    final now = ref.read(clockProvider)();
    await ref.read(dayRepositoryProvider).save(op(day, now, today));
  }
```

**Steps (TDD):**

- [ ] **1. Failing tests.** Append to `day_controller_test.dart` (new imports: `package:crudo/domain/services/meal_lifecycle.dart` already there; add `package:crudo/domain/meal/meal_snapshot.dart` if the analyzer asks):

```dart
  test('replaceMeal today: persists, slot id + time survive, unchecked', () async {
    final c = container();
    final sub = c.listen(dayControllerProvider(today), (p, n) {});
    final day = await c.read(dayControllerProvider(today).future);
    final slot = day.meals.first; // 08:00 Protein Oats Bowl
    final replacement = mealSnapshotFromTemplate(demoMealTemplates[1], seedFoods);
    await c
        .read(dayControllerProvider(today).notifier)
        .replaceMeal(slot.id, replacement);
    await Future<void>.delayed(Duration.zero);
    final updated = await c.read(dayControllerProvider(today).future);
    final swapped = updated.meals.firstWhere((m) => m.id == slot.id);
    check(swapped.time).equals(slot.time);
    check(swapped.meal.name).equals('Chicken Rice Bowl');
    check(swapped.meal.anyChecked).isFalse();
    sub.close();
  });

  test('replaceMeal on a FUTURE day detaches it (copy-on-write)', () async {
    final c = container();
    final sub = c.listen(dayControllerProvider(tomorrow), (p, n) {});
    final preview = await c.read(dayControllerProvider(tomorrow).future);
    check(await c.read(dayRepositoryProvider).getByDate(tomorrow)).isNull();
    final slot = preview.meals.first;
    final replacement = mealSnapshotFromTemplate(demoMealTemplates[3], seedFoods);
    await c
        .read(dayControllerProvider(tomorrow).notifier)
        .replaceMeal(slot.id, replacement);
    await Future<void>.delayed(Duration.zero);
    check(await c.read(dayRepositoryProvider).getByDate(tomorrow)).isNotNull();
    // detached: a template edit no longer reaches this day (UC7)
    await c
        .read(planTemplateRepositoryProvider)
        .save(demoPlanTemplate.copyWith(active: false));
    await Future<void>.delayed(Duration.zero);
    final after = await c.read(dayControllerProvider(tomorrow).future);
    check(after.meals.length).equals(4); // snapshot, not a rest-day rebuild
    check(
      after.meals.firstWhere((m) => m.id == slot.id).meal.name,
    ).equals('Salmon & Sweet Potato');
    sub.close();
  });

  test('replaceMeal on a past day throws, writes nothing', () async {
    final c = container();
    final sub = c.listen(dayControllerProvider(yesterday), (p, n) {});
    await c.read(dayControllerProvider(yesterday).future);
    final replacement = mealSnapshotFromTemplate(demoMealTemplates[0], seedFoods);
    await check(
      c
          .read(dayControllerProvider(yesterday).notifier)
          .replaceMeal('whatever', replacement),
    ).throws<StateError>();
    check(await c.read(dayRepositoryProvider).getByDate(yesterday)).isNull();
    sub.close();
  });

  test('replaceMeal guard: checked item → StateError (status not upcoming)', () async {
    final c = container();
    final sub = c.listen(dayControllerProvider(today), (p, n) {});
    final day = await c.read(dayControllerProvider(today).future);
    final id = day.meals.first.id;
    await c.read(dayControllerProvider(today).notifier).checkItem(id, 0);
    await Future<void>.delayed(Duration.zero);
    final replacement = mealSnapshotFromTemplate(demoMealTemplates[1], seedFoods);
    await check(
      c.read(dayControllerProvider(today).notifier).replaceMeal(id, replacement),
    ).throws<StateError>();
    sub.close();
  });
```

- [ ] **2. Run:** `flutter test test/ui/features/today/view_models/day_controller_test.dart` → 4 new FAIL (`replaceMeal` undefined).
- [ ] **3. Implement** the contract. `dart run build_runner build`.
- [ ] **4. Run** same file → all PASS (existing tests prove marking ops still today-only).
- [ ] **5.** `dart format .` · `flutter analyze` clean.

**Skills:** `flutter-riverpod-arch`, `dart-add-unit-test`.
**Out of scope:** any UI; relaxing `_apply` (marking stays today-only).

---

## Task 3: `MealDraft` + `MealDraftController`

**Role:** `implement`.

**Goal:** the editor's draft state: load a meal's snapshot, mutate name/tags/items, commit once — items rebuilt unchecked.

**Files:**
- Create: `lib/ui/features/meals/view_models/meal_draft.dart`
- Create: `lib/ui/features/meals/view_models/meal_draft_controller.dart` (+ codegen `.g.dart`)
- Test: `test/ui/features/meals/view_models/meal_draft_controller_test.dart` (new)

**Contract:**

```dart
// meal_draft.dart — whole file:
import 'package:crudo/domain/meal/food_snapshot.dart';
import 'package:crudo/domain/meal/meal_item.dart';
import 'package:crudo/domain/meal/meal_snapshot.dart';
import 'package:crudo/domain/services/nutrition.dart';
import 'package:crudo/domain/shared/enums.dart';
import 'package:crudo/domain/shared/macros.dart';

/// In-progress meal-instance edit (S08). Immutable — the controller swaps
/// whole instances. Items are pure FoodSnapshots: the consumption marks are
/// dropped on load (only `upcoming` meals are editable, so none exist) and
/// [toSnapshot] rebuilds every item UNCHECKED by construction — the S05
/// replaceMeal obligation, discharged at the type level.
class MealDraft {
  const MealDraft({
    this.name = '',
    this.tags = const <MealTag>[],
    this.items = const <FoodSnapshot>[],
    this.sourceMealTemplateId,
  });

  factory MealDraft.fromSnapshot(MealSnapshot meal) => MealDraft(
    name: meal.name,
    tags: meal.tags,
    items: [for (final i in meal.items) i.food],
    sourceMealTemplateId: meal.sourceMealTemplateId,
  );

  final String name;
  final List<MealTag> tags;
  final List<FoodSnapshot> items;

  /// Weak back-ref, preserved through edits (it never implies sync).
  final String? sourceMealTemplateId;

  Macros get macros => mealSnapshotMacros(toSnapshot());

  /// Non-blank name + the S02 "≥1 item per saved meal" rule.
  bool get canSave => name.trim().isNotEmpty && items.isNotEmpty;

  MealSnapshot toSnapshot() => MealSnapshot(
    sourceMealTemplateId: sourceMealTemplateId,
    name: name.trim(),
    tags: tags,
    items: [for (final f in items) MealItem(food: f)],
  );

  MealDraft copyWith({
    String? name,
    List<MealTag>? tags,
    List<FoodSnapshot>? items,
  }) => MealDraft(
    name: name ?? this.name,
    tags: tags ?? this.tags,
    items: items ?? this.items,
    sourceMealTemplateId: sourceMealTemplateId,
  );
}
```

```dart
// meal_draft_controller.dart — whole file:
import 'package:crudo/domain/meal/food_snapshot.dart';
import 'package:crudo/domain/shared/enums.dart';
import 'package:crudo/domain/shared/grams.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../today/view_models/day_controller.dart';
import 'meal_draft.dart';

part 'meal_draft_controller.g.dart';

/// Editor draft for one scheduled meal of one day (S08). Loads the current
/// MealSnapshot ONCE (ref.read, NOT watch — an external day write while the
/// editor is open must never silently reset an in-progress draft; staleness
/// is caught at commit time by the replaceMeal guard). save() commits ONCE
/// through DayController.replaceMeal — the upcoming-only content-edit guard
/// lives in the domain op, not here.
@riverpod
class MealDraftController extends _$MealDraftController {
  MealDraft? _initial;

  @override
  Future<MealDraft> build(DateTime date, String mealId) async {
    final day = await ref.read(dayControllerProvider(date).future);
    final meal = day.meals.where((m) => m.id == mealId).firstOrNull;
    if (meal == null) throw StateError('no meal with id $mealId');
    return _initial = MealDraft.fromSnapshot(meal.meal);
  }

  /// Any change vs the loaded snapshot — freezed deep equality via
  /// toSnapshot(). Drives the editor's discard-confirm gate.
  bool get isDirty {
    final d = state.asData?.value;
    final initial = _initial;
    if (d == null || initial == null) return false;
    return d.toSnapshot() != initial.toSnapshot();
  }

  void setName(String v) => _update((d) => d.copyWith(name: v));

  void toggleTag(MealTag t) => _update(
    (d) => d.copyWith(
      tags: d.tags.contains(t)
          ? [
              for (final x in d.tags)
                if (x != t) x,
            ]
          : [...d.tags, t],
    ),
  );

  void addItem(FoodSnapshot f) =>
      _update((d) => d.copyWith(items: [...d.items, f]));

  void removeItem(int index) => _update(
    (d) => d.copyWith(
      items: [
        for (final (i, f) in d.items.indexed)
          if (i != index) f,
      ],
    ),
  );

  void setItemGrams(int index, Grams g) => _update(
    (d) => d.copyWith(
      items: [
        for (final (i, f) in d.items.indexed) i == index ? f.scaledTo(g) : f,
      ],
    ),
  );

  /// Mirrors the UI gate (SAVE disabled unless canSave). The domain guard
  /// (status flipped while editing) surfaces as StateError — caller toasts.
  Future<void> save() async {
    final draft = state.requireValue;
    if (!draft.canSave) throw StateError('draft has validation issues');
    await ref
        .read(dayControllerProvider(date).notifier)
        .replaceMeal(mealId, draft.toSnapshot());
  }

  void _update(MealDraft Function(MealDraft) fn) {
    final d = state.asData?.value;
    if (d != null) state = AsyncData(fn(d));
  }
}
```

**Steps (TDD):**

- [ ] **1. Failing tests.** New file `test/ui/features/meals/view_models/meal_draft_controller_test.dart` — copy the container/harness block (seed load, `container()`, `now`/`today` constants) verbatim from `day_controller_test.dart`, then:

```dart
  test('build loads the snapshot into a draft', () async {
    final c = container();
    final sub = c.listen(dayControllerProvider(today), (p, n) {});
    final day = await c.read(dayControllerProvider(today).future);
    final id = day.meals.first.id;
    final draft = await c.read(mealDraftControllerProvider(today, id).future);
    check(draft.name).equals('Protein Oats Bowl');
    check(draft.tags).deepEquals([MealTag.breakfast]);
    check(draft.items.length).equals(4);
    check(draft.sourceMealTemplateId).equals('demo-meal-breakfast');
    check(draft.canSave).isTrue();
    sub.close();
  });

  test('mutations: name, tag toggle, remove, grams rescale, add', () async {
    final c = container();
    final sub = c.listen(dayControllerProvider(today), (p, n) {});
    final day = await c.read(dayControllerProvider(today).future);
    final id = day.meals.first.id;
    await c.read(mealDraftControllerProvider(today, id).future);
    final ctrl = c.read(mealDraftControllerProvider(today, id).notifier);

    ctrl.setName('Big Bowl');
    ctrl.toggleTag(MealTag.snack); // add
    ctrl.toggleTag(MealTag.breakfast); // remove
    final before = c.read(mealDraftControllerProvider(today, id)).requireValue;
    final oatsKcal = before.items.first.kcal; // 80g oats
    ctrl.setItemGrams(0, const Grams(160)); // double it
    ctrl.removeItem(3);
    final oats = seedFoods.firstWhere((f) => f.id == 'seed-oats');
    ctrl.addItem(FoodSnapshot.from(oats, const Grams(40)));

    final d = c.read(mealDraftControllerProvider(today, id)).requireValue;
    check(d.name).equals('Big Bowl');
    check(d.tags).deepEquals([MealTag.snack]);
    check(d.items.length).equals(4); // 4 - 1 + 1
    check(d.items.first.kcal).equals(oatsKcal * 2);
    sub.close();
  });

  test('canSave gates: blank name, zero items', () async {
    final c = container();
    final sub = c.listen(dayControllerProvider(today), (p, n) {});
    final day = await c.read(dayControllerProvider(today).future);
    final id = day.meals.first.id;
    await c.read(mealDraftControllerProvider(today, id).future);
    final ctrl = c.read(mealDraftControllerProvider(today, id).notifier);
    ctrl.setName('   ');
    check(
      c.read(mealDraftControllerProvider(today, id)).requireValue.canSave,
    ).isFalse();
    ctrl.setName('Ok');
    for (var i = 3; i >= 0; i--) {
      ctrl.removeItem(i);
    }
    check(
      c.read(mealDraftControllerProvider(today, id)).requireValue.canSave,
    ).isFalse();
    await check(ctrl.save()).throws<StateError>();
    sub.close();
  });

  test('save commits once via replaceMeal: persisted, all unchecked', () async {
    final c = container();
    final sub = c.listen(dayControllerProvider(today), (p, n) {});
    final day = await c.read(dayControllerProvider(today).future);
    final id = day.meals.first.id;
    await c.read(mealDraftControllerProvider(today, id).future);
    final ctrl = c.read(mealDraftControllerProvider(today, id).notifier);
    ctrl.setName('Big Bowl');
    await ctrl.save();
    await Future<void>.delayed(Duration.zero);
    final persisted = await c.read(dayRepositoryProvider).getByDate(today);
    final meal = persisted!.meals.firstWhere((m) => m.id == id);
    check(meal.meal.name).equals('Big Bowl');
    check(meal.meal.anyChecked).isFalse();
    check(meal.meal.sourceMealTemplateId).equals('demo-meal-breakfast');
    sub.close();
  });

  test('save on a checked meal surfaces the domain guard', () async {
    final c = container();
    final sub = c.listen(dayControllerProvider(today), (p, n) {});
    final day = await c.read(dayControllerProvider(today).future);
    final id = day.meals.first.id;
    await c.read(mealDraftControllerProvider(today, id).future);
    await c.read(dayControllerProvider(today).notifier).checkItem(id, 0);
    await Future<void>.delayed(Duration.zero);
    await check(
      c.read(mealDraftControllerProvider(today, id).notifier).save(),
    ).throws<StateError>();
    sub.close();
  });

  test('external day write does NOT reset an in-progress draft (load-once)', () async {
    final c = container();
    final sub = c.listen(dayControllerProvider(today), (p, n) {});
    final day = await c.read(dayControllerProvider(today).future);
    final id = day.meals.first.id;
    final otherId = day.meals[1].id;
    final subDraft = c.listen(mealDraftControllerProvider(today, id), (p, n) {});
    await c.read(mealDraftControllerProvider(today, id).future);
    final ctrl = c.read(mealDraftControllerProvider(today, id).notifier);
    ctrl.setName('Edited Name');
    // Simulate an S14-style background write while the editor is open:
    await c.read(dayControllerProvider(today).notifier).markAllEaten(otherId);
    await Future<void>.delayed(Duration.zero);
    check(
      c.read(mealDraftControllerProvider(today, id)).requireValue.name,
    ).equals('Edited Name'); // draft survived
    subDraft.close();
    sub.close();
  });

  test('isDirty: false on load, true after a mutation, false after revert', () async {
    final c = container();
    final sub = c.listen(dayControllerProvider(today), (p, n) {});
    final day = await c.read(dayControllerProvider(today).future);
    final id = day.meals.first.id;
    await c.read(mealDraftControllerProvider(today, id).future);
    final ctrl = c.read(mealDraftControllerProvider(today, id).notifier);
    check(ctrl.isDirty).isFalse();
    ctrl.setName('Changed');
    check(ctrl.isDirty).isTrue();
    ctrl.setName('Protein Oats Bowl'); // back to the loaded name
    check(ctrl.isDirty).isFalse();
    sub.close();
  });
```

- [ ] **2. Run:** `flutter test test/ui/features/meals` → FAIL (files don't exist).
- [ ] **3. Implement** both files. `dart run build_runner build`.
- [ ] **4. Run** → all PASS.
- [ ] **5.** `dart format .` · `flutter analyze` clean.

**Skills:** `flutter-riverpod-arch`, `dart-add-unit-test`, `dart-migrate-to-checks-package`.
**Out of scope:** widgets; any new Day op.

---

## Task 4: Mechanical relocations (shared formatting + sheet plumbing)

**Role:** `build`. Pure moves — behavior identical, full suite stays green.

**Goal:** the meals feature needs time formatting, `runDayOp`/`SecondaryAction`, and `SnoozeSheet`; relocate them to where the architecture tree says they live instead of cross-importing `today/views`.

**Files:**
- Create: `lib/ui/core/formatting.dart`
- Modify: `lib/ui/features/today/views/formatting.dart`
- Move: `lib/ui/features/today/views/sheet_actions.dart` → `lib/ui/core/widgets/sheet_actions.dart`
- Move: `lib/ui/features/today/views/snooze_sheet.dart` → `lib/ui/features/meals/views/snooze_sheet.dart`
- Modify importers: `lib/ui/features/today/views/meal_sheet.dart`, `lib/ui/features/today/views/today_screen.dart`, plus any test importing the moved files (`grep -rn "sheet_actions\|snooze_sheet" lib test`)

**Steps:**

- [ ] **1.** Create `lib/ui/core/formatting.dart`:

```dart
import 'package:crudo/domain/shared/meal_time.dart';

// Display + route-param formatting shared across features (today, meals).

String _two(int n) => n.toString().padLeft(2, '0');

/// 'HH:mm' of a MealTime (24h).
String mealTimeLabel(MealTime t) => '${_two(t.hour)}:${_two(t.minute)}';

/// 'HH:mm' of a local instant.
String timeOfDayLabel(DateTime local) =>
    '${_two(local.hour)}:${_two(local.minute)}';

/// Route-param form of a UTC day label: '2026-06-07'.
String dayParam(DateTime dayLabel) =>
    '${dayLabel.year.toString().padLeft(4, '0')}-'
    '${_two(dayLabel.month)}-${_two(dayLabel.day)}';

/// Parses [dayParam] output back to the UTC-midnight day label.
DateTime parseDayParam(String s) {
  final p = DateTime.parse(s);
  return DateTime.utc(p.year, p.month, p.day);
}

/// Trims trailing ".0" — "3.6" stays "3.6", "31.0" renders as "31".
/// (Moved from foods/views/formatting.dart — meals feature needs it too.)
String gramsText(double v) => v == v.roundToDouble() ? '${v.round()}' : '$v';

/// Normalises a user-typed number string (comma or dot decimal) and parses
/// it. Returns null when the string is not a valid number.
double? parseGrams(String s) => double.tryParse(s.replaceAll(',', '.'));
```

- [ ] **2.** In `lib/ui/features/today/views/formatting.dart`: delete `mealTimeLabel`, `timeOfDayLabel`, and the now-unused `_two`; add at the top (after imports):

```dart
export 'package:crudo/ui/core/formatting.dart'
    show mealTimeLabel, timeOfDayLabel;
```

(All existing `import 'formatting.dart'` call sites keep compiling.)

- [ ] **2b.** In `lib/ui/features/foods/views/formatting.dart`: delete `gramsText` and `parseGrams` (they moved to core; `pctText` stays); add at the top:

```dart
export 'package:crudo/ui/core/formatting.dart' show gramsText, parseGrams;
```

(Foods call sites keep compiling; the meals feature imports core directly.)

- [ ] **3.** `git mv lib/ui/features/today/views/sheet_actions.dart lib/ui/core/widgets/sheet_actions.dart`; fix its relative imports (`../../../core/themes/…` → `../themes/…`, `../../../core/widgets/toast.dart` → `toast.dart`). Update importers (`meal_sheet.dart`, `today_screen.dart`, the moved `snooze_sheet.dart`) to `import '../../../core/widgets/sheet_actions.dart';` (path relative to each file).
- [ ] **4.** `git mv lib/ui/features/today/views/snooze_sheet.dart lib/ui/features/meals/views/snooze_sheet.dart`; fix its imports: domain unchanged, `../view_models/day_controller.dart` → `../../today/view_models/day_controller.dart`, `../view_models/today_providers.dart` → `../../today/view_models/today_providers.dart`, `formatting.dart` → `../../../core/formatting.dart`, `sheet_actions.dart` → `../../../core/widgets/sheet_actions.dart`. Update `meal_sheet.dart`'s import of it.
- [ ] **5.** Run `grep -rn "views/sheet_actions\|views/snooze_sheet" lib test` — fix any remaining importer (e.g. `test/ui/features/today/views/sheets_test.dart`).
- [ ] **6.** `dart format .` · `flutter analyze` clean · `flutter test` → **entire suite green, zero test-logic changes** (only import paths).

**Skills:** none beyond repo conventions — mechanical.
**Out of scope:** any behavior change, any new widget.

---

## Task 5: S07 retrofits — reusable `FoodLibraryList` + form pop-result

**Role:** `ui`.

**Goal:** (a) extract the library list (search + groups + empty state) into `FoodLibraryList` with a picker mode, leaving `/foods` behavior identical; (b) `FoodFormScreen` pops the created/edited `Food` as the route result so the picker can await it.

**Files:**
- Create: `lib/ui/features/foods/views/food_library_list.dart`
- Modify: `lib/ui/features/foods/views/food_library_screen.dart`
- Modify: `lib/ui/features/foods/view_models/food_draft_controller.dart`
- Modify: `lib/ui/features/foods/views/food_form_screen.dart`
- Test: extend `test/ui/features/foods/views/` (existing library + form test files; follow their router/pump harness)

**Contract:**

```dart
// food_library_list.dart — whole file:
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../domain/food/food.dart';
import '../../../core/themes/colors.dart';
import '../../../core/themes/dimensions.dart';
import '../../../core/themes/input_decoration.dart';
import '../../../core/themes/typography.dart';
import '../view_models/food_library.dart';
import 'food_row.dart';

/// The reusable library list (S07 list extracted for the S08 picker):
/// search field + grouped sections + empty-search state.
///
/// Library mode ([onPick] == null): custom rows navigate to the edit form,
/// seed rows are inert. Picker mode: EVERY row calls back with its food.
class FoodLibraryList extends ConsumerWidget {
  const FoodLibraryList({
    this.onPick,
    this.header,
    this.pickerHint = false,
    super.key,
  });

  final void Function(Food food)? onPick;

  /// Optional slot above the first group (the picker's custom-food CTA).
  final Widget? header;

  /// Adds the picker's "add it as a custom food" second line to the
  /// empty-search state.
  final bool pickerHint;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<CrudoColors>()!;
    final groups = ref.watch(foodLibraryProvider);
    final query = ref.watch(foodSearchQueryProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(Spacing.md, Spacing.sm, Spacing.md, 0),
          child: TextField(
            key: const ValueKey('food-search'),
            onChanged: (v) =>
                ref.read(foodSearchQueryProvider.notifier).setQuery(v),
            style: CrudoText.body,
            decoration: softInputDecoration(
              colors,
              hint: 'Search foods',
              prefixIcon: Icon(
                Icons.search,
                size: IconSizes.md,
                color: colors.onSurfaceMut,
              ),
            ),
          ),
        ),
        // Header (the picker's custom-food CTA) renders OUTSIDE the list so
        // it survives an empty search — the empty-state copy points at it.
        if (header != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
            child: header!,
          ),
        Expanded(
          child: groups.when(
            data: (gs) => gs.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'No foods match "${query.trim()}"',
                          style: CrudoText.body.copyWith(
                            color: colors.onSurfaceMut,
                          ),
                        ),
                        if (pickerHint) ...[
                          const SizedBox(height: Spacing.xs),
                          Text(
                            'Use the button above to add it as a custom food.',
                            key: const ValueKey('picker-empty-hint'),
                            style: CrudoText.body.copyWith(
                              color: colors.onSurfaceMut,
                            ),
                          ),
                        ],
                      ],
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(
                      Spacing.md, Spacing.sm, Spacing.md, Spacing.xl,
                    ),
                    children: [
                      for (final g in gs) ...[
                        Padding(
                          padding: const EdgeInsets.only(
                            top: Spacing.md, bottom: Spacing.sm,
                          ),
                          child: Text(
                            g.label.toUpperCase(),
                            key: ValueKey('group-${g.label}'),
                            style: CrudoText.label,
                          ),
                        ),
                        for (final f in g.foods)
                          Padding(
                            padding: const EdgeInsets.only(bottom: Spacing.sm),
                            child: FoodRow(
                              food: f,
                              onTap: onPick != null
                                  ? () => onPick!(f)
                                  : f.isCustom
                                      ? () => context.push('/foods/${f.id}')
                                      : null,
                            ),
                          ),
                      ],
                    ],
                  ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Text('Something went wrong', style: CrudoText.body),
            ),
          ),
        ),
      ],
    );
  }
}
```

`FoodLibraryScreen` keeps only its appbar row (back-if-can-pop, "Food library" title, add button) and renders `const Expanded(child: FoodLibraryList())` below it — search/list/empty code deleted from the screen.

```dart
// food_draft_controller.dart — save() now returns the saved Food:
  Future<Food> save() async {
    final draft = state.requireValue;
    if (!draft.canSave) throw StateError('draft has validation issues');
    final id = foodId ?? ref.read(idGeneratorProvider).newId();
    final food = draft.toFood(id);
    await ref.read(foodRepositoryProvider).save(food);
    return food;
  }
```

(add `import 'package:crudo/domain/food/food.dart';`)

```dart
// food_form_screen.dart — _save pops the result:
  Future<void> _save() async {
    final result = await AsyncValue.guard(_ctrl.save);
    if (!mounted) return;
    if (result is AsyncError) {
      showCrudoToast(context, "Couldn't save — try again", kind: ToastKind.error);
      return;
    }
    context.pop(result.value); // the saved Food — picker awaits it (S08)
  }
```

**Steps (TDD):**

- [ ] **1. Failing tests.** In the existing foods views test files add (reuse their pump harness):
  - `FoodLibraryList` picker mode: pump with `onPick` callback collecting foods → tap a **seed** row → callback fired with that food (seed rows are pickable in picker mode).
  - Library mode regression: existing `FoodLibraryScreen` tests stay green untouched (custom row → edit route, seed row inert).
  - `pickerHint`: search for gibberish in picker mode → both empty-state lines render (`ValueKey('picker-empty-hint')` present); library mode → hint absent.
  - Form result: pump the form via a test `GoRouter` whose pushing screen captures `await context.push<Food>('/foods/new')`; fill a valid draft, tap SAVE → captured result is a `Food` with `isCustom == true` and the typed name.
- [ ] **2. Run:** `flutter test test/ui/features/foods` → new tests FAIL.
- [ ] **3. Implement** the extraction + retrofit per contract.
- [ ] **4. Run:** `flutter test test/ui/features/foods` → all PASS (old + new).
- [ ] **5.** `dart format .` · `flutter analyze` clean · `flutter test` full suite green.

**Skills:** `flutter-add-widget-test`, `flutter-riverpod-arch`, `flutter-expert`.
**Out of scope:** the picker screen itself (Task 7); any change to `/foods` visuals or behavior.

---

## Task 6: `SwapSheet`

**Role:** `ui`.

**Goal:** the swap picker sheet: meal templates with macro summaries; tap = immediate `replaceMeal` + close.

**Files:**
- Create: `lib/ui/features/meals/views/swap_sheet.dart`
- Create: `lib/ui/features/meals/views/formatting.dart`
- Test: `test/ui/features/meals/views/swap_sheet_test.dart` (new; copy the pump/override harness style from `test/ui/features/today/views/sheets_test.dart`)

**Contract:**

```dart
// meals/views/formatting.dart — whole file:
import 'package:crudo/domain/shared/enums.dart';

/// Display labels for meal tags (editor chips + swap rows).
const mealTagLabels = <MealTag, String>{
  MealTag.breakfast: 'Breakfast',
  MealTag.lunch: 'Lunch',
  MealTag.dinner: 'Dinner',
  MealTag.snack: 'Snack',
  MealTag.preWorkout: 'Pre-workout',
  MealTag.postWorkout: 'Post-workout',
};

/// One-time toast when a content edit detaches a future day (S08 review
/// amendment) — shared by SwapSheet and the editor's save.
const detachToastMessage =
    "This day now keeps its own changes — plan edits won't affect it.";
```

```dart
// swap_sheet.dart — whole file:
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../domain/services/meal_lifecycle.dart';
import '../../../../domain/services/nutrition.dart';
import '../../../core/themes/colors.dart';
import '../../../core/themes/dimensions.dart';
import '../../../core/themes/typography.dart';
import '../../../core/widgets/sheet.dart';
import '../../../core/widgets/toast.dart';
import '../../today/view_models/day_controller.dart';
import '../../today/view_models/today_providers.dart';
import 'formatting.dart';

/// Swap-from-library sheet (S08, sheets.jsx SwapSheet): meal-template rows,
/// tap = immediate replaceMeal + close (reversible — the meal was upcoming,
/// nothing checked). A template whose refs all dangle renders disabled.
class SwapSheet extends ConsumerWidget {
  const SwapSheet({required this.date, required this.mealId, super.key});

  final DateTime date;
  final String mealId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<CrudoColors>()!;
    final templates = ref.watch(mealTemplatesProvider).value ?? const [];
    final foods = ref.watch(foodsProvider).value ?? const [];
    return SheetScaffold(
      label: 'From your library',
      title: 'Swap meal',
      body: templates.isEmpty
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: Spacing.lg),
              child: Text(
                'No meals in your library yet.',
                key: const ValueKey('swap-empty'),
                style: CrudoText.body.copyWith(color: colors.onSurfaceMut),
              ),
            )
          : ListView(
              shrinkWrap: true,
              children: [
                for (final t in templates)
                  _SwapRow(
                    key: ValueKey('swap-${t.id}'),
                    name: t.name,
                    summary: _summary(t, foods),
                    enabled: mealSnapshotFromTemplate(t, foods).items.isNotEmpty,
                    colors: colors,
                    onTap: () => _swap(context, ref, t, foods),
                  ),
              ],
            ),
    );
  }

  /// Detach-aware commit (review amendment): when this op is the future
  /// day's FIRST persist (no repo row before it), announce the detach.
  Future<void> _swap(
    BuildContext context,
    WidgetRef ref,
    MealTemplate t,
    List<Food> foods,
  ) async {
    final today = ref.read(todayProvider);
    final detaches =
        date.isAfter(today) &&
        ref.read(persistedDayProvider(date)).value == null;
    try {
      await ref
          .read(dayControllerProvider(date).notifier)
          .replaceMeal(mealId, mealSnapshotFromTemplate(t, foods));
      if (!context.mounted) return;
      if (detaches) showCrudoToast(context, detachToastMessage);
      Navigator.of(context).pop();
    } on StateError {
      if (context.mounted) {
        showCrudoToast(
          context,
          "That can't be changed anymore.",
          kind: ToastKind.warn,
        );
      }
    }
  }

  static String _summary(MealTemplate t, List<Food> foods) {
    final resolved = mealSnapshotFromTemplate(t, foods);
    final m = mealSnapshotMacros(resolved);
    final tags = [for (final tag in t.tags) mealTagLabels[tag]!].join(' · ');
    final lead = tags.isEmpty ? '' : '$tags · ';
    return '$lead${m.kcal.round()} kcal · ${resolved.items.length} ingredients';
  }
}

class _SwapRow extends StatelessWidget {
  const _SwapRow({
    required this.name,
    required this.summary,
    required this.enabled,
    required this.colors,
    required this.onTap,
    super.key,
  });

  final String name;
  final String summary;
  final bool enabled;
  final CrudoColors colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : Opacities.disabled,
      child: Semantics(
        button: enabled,
        label: 'Swap to $name',
        child: GestureDetector(
          onTap: enabled ? onTap : null,
          behavior: HitTestBehavior.opaque,
          child: Container(
            margin: const EdgeInsets.only(bottom: Spacing.xs),
            padding: const EdgeInsets.all(Spacing.md),
            decoration: BoxDecoration(
              color: colors.surfaceLow,
              borderRadius: Radii.all(Radii.md),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: CrudoText.body.copyWith(
                          fontWeight: FontWeight.w700,
                          color: colors.onSurface,
                        ),
                      ),
                      const SizedBox(height: Spacing.xs),
                      Text(
                        summary,
                        style: CrudoText.body.copyWith(
                          color: colors.onSurfaceMut,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.swap_horiz, size: IconSizes.sm, color: colors.primary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```

(Add the needed `MealTemplate`/`Food` domain imports for `_summary`.)

**Steps (TDD):**

- [ ] **1. Failing tests** in `swap_sheet_test.dart` (harness: `ProviderContainer` overrides as in `sheets_test.dart`, pump `SwapSheet(date: today, mealId: …)` inside a themed `MaterialApp`/`Scaffold` with `UncontrolledProviderScope`):
  - renders one row per demo template with name + summary (`find.byKey(ValueKey('swap-demo-meal-dinner'))`).
  - tap a row → day repo's meal content for that slot is the resolved template, slot id survives, sheet popped.
  - seed an extra template whose refs all dangle (`MealTemplate(id: 'x', name: 'Ghost', foods: [FoodRef(foodId: 'nope', grams: Grams(50))])` saved to `mealTemplateRepositoryProvider`) → its row renders disabled, tap is a no-op.
  - swap on a meal with a checked item → warn toast (guard surfaced), nothing changed.
  - empty template repo (override `appConfigProvider` to prod flavor) → `ValueKey('swap-empty')`.
  - **detach toast:** pump for `tomorrow` (preview, no repo row) → swap → `detachToastMessage` toast shown; pump for `today` → swap → NO detach toast; swap a second meal on the already-detached tomorrow → NO detach toast (row existed).
- [ ] **2. Run** → FAIL. **3. Implement.** **4. Run** → PASS. **5.** format · analyze · full test green.

**Skills:** `flutter-add-widget-test`, `flutter-riverpod-arch`, `flutter-expert` (semantics).
**Out of scope:** the detail screen (Task 9 wires the tile to this sheet).

---

## Task 7: `GramsEntry` + `AddIngredientScreen`

**Role:** `ui`.

**Goal:** the two-stage picker: library list (with custom-food CTA) → grams stage (input + presets + live preview) → pops a `FoodSnapshot`. Custom-food round-trip lands in the grams stage prefilled.

**Files:**
- Create: `lib/ui/features/meals/views/grams_entry.dart`
- Create: `lib/ui/features/meals/views/add_ingredient_screen.dart`
- Test: `test/ui/features/meals/views/add_ingredient_screen_test.dart` (new)

**Contract:**

```dart
// grams_entry.dart — whole file:
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../domain/meal/food_snapshot.dart';
import '../../../../domain/shared/grams.dart';
import '../../../core/themes/colors.dart';
import '../../../core/themes/dimensions.dart';
import '../../../core/themes/input_decoration.dart';
import '../../../core/themes/typography.dart';
import '../../../core/formatting.dart' show gramsText, parseGrams;

/// The canned portion presets (grams) — meal.jsx AddIngredientScreen.
const gramsPresets = <double>[50, 100, 150, 200, 250];

/// Quantity entry with presets and a live macro preview. Two consumers:
/// the add-ingredient picker's stage 2 (baseline = the picked food at 100g)
/// and the editor's grams re-edit sheet (baseline = the existing item).
/// Preview scales linearly from [baseline] (FoodSnapshot.scaledTo); the
/// parent owns the current value via [onChanged] (null = invalid input).
class GramsEntry extends StatefulWidget {
  const GramsEntry({
    required this.baseline,
    required this.initialGrams,
    required this.onChanged,
    super.key,
  });

  final FoodSnapshot baseline;
  final double initialGrams;
  final ValueChanged<double?> onChanged;

  @override
  State<GramsEntry> createState() => _GramsEntryState();
}

class _GramsEntryState extends State<GramsEntry> {
  late final _controller =
      TextEditingController(text: gramsText(widget.initialGrams));
  late double? _grams = widget.initialGrams;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _set(double? g) {
    setState(() => _grams = g);
    widget.onChanged(g);
  }

  void _pickPreset(double g) {
    _controller.text = gramsText(g);
    _set(g);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CrudoColors>()!;
    final g = _grams;
    final preview = (g != null && g > 0)
        ? widget.baseline.scaledTo(Grams(g))
        : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('QUANTITY', style: CrudoText.label),
        const SizedBox(height: Spacing.sm),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                key: const ValueKey('grams-input'),
                controller: _controller,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
                ],
                style: CrudoText.stat,
                decoration: softInputDecoration(colors, hint: '100'),
                onChanged: (s) {
                  final v = parseGrams(s);
                  _set(v != null && v > 0 ? v : null);
                },
              ),
            ),
            const SizedBox(width: Spacing.sm),
            Padding(
              padding: const EdgeInsets.only(bottom: Spacing.md),
              child: Text(
                'grams',
                style: CrudoText.title.copyWith(color: colors.onSurfaceMut),
              ),
            ),
          ],
        ),
        const SizedBox(height: Spacing.md),
        Wrap(
          spacing: Spacing.sm,
          runSpacing: Spacing.sm,
          children: [
            for (final p in gramsPresets)
              _PresetPill(
                key: ValueKey('grams-preset-${p.round()}'),
                grams: p,
                selected: _grams == p,
                colors: colors,
                onTap: () => _pickPreset(p),
              ),
          ],
        ),
        const SizedBox(height: Spacing.lg),
        Container(
          padding: const EdgeInsets.all(Spacing.md),
          decoration: BoxDecoration(
            color: colors.surfaceLow,
            borderRadius: Radii.all(Radii.lg),
          ),
          child: preview == null
              ? Text(
                  'Enter a quantity above zero.',
                  key: const ValueKey('grams-invalid'),
                  style: CrudoText.body.copyWith(color: colors.onSurfaceMut),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'FOR ${gramsText(preview.grams.value).toUpperCase()}G',
                      style: CrudoText.label,
                    ),
                    const SizedBox(height: Spacing.xs),
                    Text(
                      '${preview.kcal.round()} kcal',
                      key: const ValueKey('grams-preview-kcal'),
                      style: CrudoText.displaySm,
                    ),
                    const SizedBox(height: Spacing.sm),
                    Text(
                      'P ${preview.protein.round()}g'
                      '  C ${preview.carbs.round()}g'
                      '  F ${preview.fats.round()}g',
                      style: CrudoText.body.copyWith(
                        color: colors.onSurfaceMut,
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _PresetPill extends StatelessWidget {
  const _PresetPill({
    required this.grams,
    required this.selected,
    required this.colors,
    required this.onTap,
    super.key,
  });

  final double grams;
  final bool selected;
  final CrudoColors colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.md,
            vertical: Spacing.sm,
          ),
          decoration: BoxDecoration(
            color: selected ? colors.primaryContainer : colors.surfaceLow,
            borderRadius: Radii.all(Radii.full),
          ),
          child: Text(
            '${grams.round()}g',
            style: CrudoText.labelMd.copyWith(
              color: selected ? colors.primary : colors.onSurfaceVar,
            ),
          ),
        ),
      ),
    );
  }
}
```

```dart
// add_ingredient_screen.dart — whole file:
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../domain/food/food.dart';
import '../../../../domain/meal/food_snapshot.dart';
import '../../../../domain/shared/grams.dart';
import '../../../core/themes/colors.dart';
import '../../../core/themes/dimensions.dart';
import '../../../core/themes/typography.dart';
import '../../../core/widgets/primary_cta.dart';
import '../../foods/views/food_library_list.dart';
import 'grams_entry.dart';

/// Two-stage add-ingredient picker (S08, meal.jsx AddIngredientScreen):
/// stage 1 = the S07 library list in picker mode (+ custom-food CTA),
/// stage 2 = grams entry with presets + live preview. Pops a FoodSnapshot
/// created AT ADD TIME via FoodSnapshot.from (S05 §1.4 point 2) — the
/// editor's draft receives it; this screen never touches the draft.
class AddIngredientScreen extends ConsumerStatefulWidget {
  const AddIngredientScreen({super.key});

  @override
  ConsumerState<AddIngredientScreen> createState() =>
      _AddIngredientScreenState();
}

class _AddIngredientScreenState extends ConsumerState<AddIngredientScreen> {
  Food? _picked;
  double? _grams = 100;

  Future<void> _createCustom() async {
    // The retrofitted FoodFormScreen pops the created Food (Task 5) —
    // land in the grams stage prefilled (decision: never auto-add at 100g).
    final created = await context.push<Food>('/foods/new');
    if (created != null && mounted) {
      setState(() {
        _picked = created;
        _grams = 100;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CrudoColors>()!;
    final picked = _picked;
    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Spacing.md, Spacing.sm, Spacing.md, 0,
              ),
              child: Row(
                children: [
                  IconButton(
                    key: const ValueKey('picker-back'),
                    onPressed: picked == null
                        ? context.pop
                        : () => setState(() => _picked = null),
                    icon: Icon(
                      Icons.arrow_back,
                      size: IconSizes.lg,
                      color: colors.onSurface,
                    ),
                  ),
                  const Expanded(
                    child: Text('Add ingredient', style: CrudoText.headlineSm),
                  ),
                ],
              ),
            ),
            if (picked == null)
              Expanded(
                child: FoodLibraryList(
                  pickerHint: true,
                  header: _CreateCustomCta(
                    colors: colors,
                    onTap: _createCustom,
                  ),
                  onPick: (f) => setState(() {
                    _picked = f;
                    _grams = 100;
                  }),
                ),
              )
            else
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                    Spacing.xl, Spacing.sm, Spacing.xl, Spacing.xl,
                  ),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(Spacing.md),
                      decoration: BoxDecoration(
                        color: colors.surfaceLowest,
                        borderRadius: Radii.all(Radii.lg),
                        boxShadow: Shadows.cloud,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('SELECTED', style: CrudoText.label),
                          const SizedBox(height: Spacing.xs),
                          Text(picked.name, style: CrudoText.headline),
                          const SizedBox(height: Spacing.xs),
                          Text(
                            'Per 100g · ${picked.kcalPer100g.round()} kcal',
                            style: CrudoText.body.copyWith(
                              color: colors.onSurfaceMut,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: Spacing.lg),
                    GramsEntry(
                      // GramsEntry is keyed by food so re-picks reset it.
                      key: ValueKey('grams-entry-${picked.id}'),
                      baseline: FoodSnapshot.from(picked, const Grams(100)),
                      initialGrams: _grams ?? 100,
                      onChanged: (g) => setState(() => _grams = g),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: picked == null
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(Spacing.md),
                child: PrimaryCta(
                  key: const ValueKey('add-to-meal'),
                  label: 'Add to Meal',
                  enabled: _grams != null && _grams! > 0,
                  onPressed: () => context.pop(
                    FoodSnapshot.from(picked, Grams(_grams!)),
                  ),
                ),
              ),
            ),
    );
  }
}

/// Persistent "Create custom food" CTA above the list. Tonal container —
/// the prototype's dashed border violates the no-line rule.
class _CreateCustomCta extends StatelessWidget {
  const _CreateCustomCta({required this.colors, required this.onTap});

  final CrudoColors colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Create custom food',
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          key: const ValueKey('create-custom-cta'),
          margin: const EdgeInsets.only(top: Spacing.sm),
          padding: const EdgeInsets.all(Spacing.md),
          decoration: BoxDecoration(
            color: colors.surfaceLow,
            borderRadius: Radii.all(Radii.md),
          ),
          child: Row(
            children: [
              Container(
                width: 40, // icon circle, 4px grid (matches sheet grabber)
                height: 40,
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.add, size: IconSizes.md, color: colors.primary),
              ),
              const SizedBox(width: Spacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Create custom food',
                      style: CrudoText.body.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colors.primary,
                      ),
                    ),
                    Text(
                      'Add your own with macros per 100g',
                      style: CrudoText.body.copyWith(
                        color: colors.onSurfaceMut,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, size: IconSizes.sm, color: colors.primary),
            ],
          ),
        ),
      ),
    );
  }
}
```

**Steps (TDD):**

- [ ] **1. Failing tests** in `add_ingredient_screen_test.dart`. Harness: a test `GoRouter` (initial route `/pick` → a launcher screen that does `final snap = await context.push<FoodSnapshot>('/add'); …collect…`; `/add` → `AddIngredientScreen`; `/foods/new` → real `FoodFormScreen(foodId: null)`), wrapped in `UncontrolledProviderScope` with the seed/clock overrides used by the foods tests. Cases:
  - stage 1 lists groups; tapping a seed row (e.g. "Chicken Breast") shows stage 2 with the selected card + `grams-input` text `100`.
  - preset tap (150) updates input + preview kcal = per-100g × 1.5 rounded.
  - clearing the input → `grams-invalid` hint + `Add to Meal` disabled.
  - `Add to Meal` at 150g → launcher received a `FoodSnapshot` with `grams == Grams(150)` and `sourceFoodId` = picked id.
  - back from stage 2 returns to stage 1 (list visible, no pop).
  - custom-food CTA → form opens; fill name "My blend", protein 30 → SAVE → back on picker **stage 2** with `My blend` selected (grams 100 prefilled); Add → snapshot's `sourceFoodId` is the new food's id.
- [ ] **2. Run** → FAIL. **3. Implement** both files. **4. Run** → PASS. **5.** format · analyze · full test green.

**Skills:** `flutter-add-widget-test`, `flutter-setup-declarative-routing` (test router), `flutter-expert` (form a11y, semantics).
**Out of scope:** route registration in `app_router.dart` (Task 9); the editor.

---

## Task 8: `MealEditorScreen` (+ grams re-edit sheet)

**Role:** `ui`.

**Goal:** the draft editor: name, tag chips, ingredient list (remove / grams re-edit / add), gradient macro preview, SAVE.

**Files:**
- Create: `lib/ui/features/meals/views/meal_editor_screen.dart`
- Modify: `lib/ui/features/meals/views/grams_entry.dart` (add `GramsSheet`)
- Test: `test/ui/features/meals/views/meal_editor_screen_test.dart` (new)

**Contract — `GramsSheet`** (append to `grams_entry.dart`; add imports for `sheet.dart`, `primary_cta.dart`):

```dart
/// Grams re-edit sheet (editor row tap): GramsEntry seeded from the existing
/// item; confirms with the new Grams — the controller rescales via scaledTo.
class GramsSheet extends StatefulWidget {
  const GramsSheet({required this.item, super.key});

  final FoodSnapshot item;

  @override
  State<GramsSheet> createState() => _GramsSheetState();
}

class _GramsSheetState extends State<GramsSheet> {
  late double? _grams = widget.item.grams.value;

  @override
  Widget build(BuildContext context) {
    return SheetScaffold(
      label: 'Quantity',
      title: widget.item.name,
      body: GramsEntry(
        baseline: widget.item,
        initialGrams: widget.item.grams.value,
        onChanged: (g) => setState(() => _grams = g),
      ),
      cta: PrimaryCta(
        key: const ValueKey('set-grams'),
        label: 'Set quantity',
        enabled: _grams != null && _grams! > 0,
        onPressed: () => Navigator.of(context).pop(Grams(_grams!)),
      ),
    );
  }
}
```

**Contract — `meal_editor_screen.dart`** (whole file; S07 form pattern: outer resolves async, inner stateful owns the name controller created once):

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../domain/meal/food_snapshot.dart';
import '../../../../domain/shared/enums.dart';
import '../../../../domain/shared/grams.dart';
import '../../../core/formatting.dart';
import '../../../core/themes/colors.dart';
import '../../../core/themes/dimensions.dart';
import '../../../core/themes/input_decoration.dart';
import '../../../core/themes/typography.dart';
import '../../../core/widgets/pill.dart';
import '../../../core/widgets/primary_cta.dart';
import '../../../core/widgets/sheet.dart';
import '../../../core/widgets/toast.dart';
import '../../today/view_models/today_providers.dart';
import '../view_models/meal_draft.dart';
import '../view_models/meal_draft_controller.dart';
import 'formatting.dart';
import 'grams_entry.dart';

/// S08 instance editor: draft-shaped (name/tags/items), committed ONCE via
/// MealDraftController.save → replaceMeal. Back: pristine pops silently,
/// dirty asks "Discard changes?" (review amendment — no silent data loss).
class MealEditorScreen extends ConsumerWidget {
  const MealEditorScreen({required this.date, required this.mealId, super.key});

  final DateTime date;
  final String mealId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(mealDraftControllerProvider(date, mealId));
    return draft.when(
      data: (d) => _EditorForm(date: date, mealId: mealId, initial: d),
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(
        body: Center(child: Text('Meal not found', style: CrudoText.body)),
      ),
    );
  }
}

class _EditorForm extends ConsumerStatefulWidget {
  const _EditorForm({
    required this.date,
    required this.mealId,
    required this.initial,
  });

  final DateTime date;
  final String mealId;
  final MealDraft initial;

  @override
  ConsumerState<_EditorForm> createState() => _EditorFormState();
}

class _EditorFormState extends ConsumerState<_EditorForm> {
  late final _name = TextEditingController(text: widget.initial.name);

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  MealDraftController get _ctrl => ref.read(
    mealDraftControllerProvider(widget.date, widget.mealId).notifier,
  );

  Future<void> _save() async {
    // Detach pre-check BEFORE the op: first persist of a future day = detach.
    final today = ref.read(todayProvider);
    final detaches =
        widget.date.isAfter(today) &&
        ref.read(persistedDayProvider(widget.date)).value == null;
    final result = await AsyncValue.guard(_ctrl.save);
    if (!mounted) return;
    if (result is AsyncError) {
      // Raced status flip (item checked / window passed mid-edit) or a
      // repo failure — one warn message covers the guard UX.
      showCrudoToast(
        context,
        "That can't be changed anymore.",
        kind: ToastKind.warn,
      );
      return;
    }
    if (detaches) showCrudoToast(context, detachToastMessage);
    context.pop();
  }

  /// Back handler (header button + system pop via PopScope): pristine pops,
  /// dirty confirms. The confirmed pop uses context.pop() directly — it
  /// bypasses the PopScope gate, no re-entry.
  Future<void> _maybePop() async {
    if (!_ctrl.isDirty) {
      context.pop();
      return;
    }
    final discard =
        await showCrudoSheet<bool>(
          context,
          builder: (sheetCtx) => SheetScaffold(
            title: 'Discard changes?',
            body: Text(
              'Your edits to this meal will be lost.',
              style: CrudoText.body,
            ),
            cta: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                PrimaryCta(
                  label: 'Discard',
                  onPressed: () => Navigator.of(sheetCtx).pop(true),
                ),
                const SizedBox(height: Spacing.sm),
                TextButton(
                  key: const ValueKey('keep-editing'),
                  onPressed: () => Navigator.of(sheetCtx).pop(false),
                  child: const Text('Keep editing'),
                ),
              ],
            ),
          ),
        ) ??
        false;
    if (discard && mounted) context.pop();
  }

  Future<void> _addIngredient() async {
    final snap = await context.push<FoodSnapshot>(
      '/meal/${dayParam(widget.date)}/${widget.mealId}/edit/add-ingredient',
    );
    if (snap != null) _ctrl.addItem(snap);
  }

  Future<void> _editGrams(int index, FoodSnapshot item) async {
    final g = await showCrudoSheet<Grams>(
      context,
      builder: (_) => GramsSheet(item: item),
    );
    if (g != null) _ctrl.setItemGrams(index, g);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CrudoColors>()!;
    final draft = ref
        .watch(mealDraftControllerProvider(widget.date, widget.mealId))
        .requireValue;
    // The form watches the draft provider, so a mutation rebuilds and
    // canPop tracks dirtiness; system pops on a dirty draft divert to
    // _maybePop's confirm sheet.
    return PopScope(
      canPop: !_ctrl.isDirty,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _maybePop();
      },
      child: Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Header: back (pristine pop / dirty confirm) · 'Edit meal' · SAVE.
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Spacing.md, Spacing.sm, Spacing.md, 0,
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: _maybePop,
                    icon: Icon(
                      Icons.arrow_back,
                      size: IconSizes.lg,
                      color: colors.onSurface,
                    ),
                  ),
                  const Expanded(
                    child: Text('Edit meal', style: CrudoText.headlineSm),
                  ),
                  Opacity(
                    opacity: draft.canSave ? 1 : Opacities.disabled,
                    child: TextButton(
                      key: const ValueKey('save-meal'),
                      onPressed: draft.canSave ? _save : null,
                      child: Text(
                        'SAVE',
                        style: CrudoText.labelMd.copyWith(
                          color: colors.primary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  Spacing.md, Spacing.sm, Spacing.md, Spacing.xl,
                ),
                children: [
                  // NAME
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: Spacing.sm),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('MEAL NAME', style: CrudoText.label),
                        const SizedBox(height: Spacing.sm),
                        TextField(
                          key: const ValueKey('meal-name'),
                          controller: _name,
                          style: CrudoText.headline,
                          decoration: softInputDecoration(
                            colors,
                            hint: 'e.g. Protein Bowl',
                            hintStyle: CrudoText.headline.copyWith(
                              color: colors.onSurfaceMut,
                            ),
                            radius: Radii.md,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: Spacing.md,
                              vertical: Spacing.md,
                            ),
                          ),
                          onChanged: _ctrl.setName,
                        ),
                        const SizedBox(height: Spacing.lg),

                        // TAGS
                        const Text(
                          'TAGS · SELECT MULTIPLE',
                          style: CrudoText.label,
                        ),
                        const SizedBox(height: Spacing.sm),
                        Wrap(
                          spacing: Spacing.sm,
                          runSpacing: Spacing.sm,
                          children: [
                            for (final t in MealTag.values)
                              Pill(
                                key: ValueKey('tag-${t.name}'),
                                label: mealTagLabels[t]!,
                                selected: draft.tags.contains(t),
                                onTap: () => _ctrl.toggleTag(t),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: Spacing.lg),

                  // INGREDIENTS
                  Container(
                    padding: const EdgeInsets.all(Spacing.md),
                    decoration: BoxDecoration(
                      color: colors.surfaceLow,
                      borderRadius: Radii.all(Radii.lg),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            const Expanded(
                              child: Text(
                                'Ingredients',
                                style: CrudoText.headlineSm,
                              ),
                            ),
                            Text(
                              '${draft.items.length} ITEMS',
                              style: CrudoText.label,
                            ),
                          ],
                        ),
                        const SizedBox(height: Spacing.md),
                        if (draft.items.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: Spacing.md,
                            ),
                            child: Center(
                              child: Text(
                                'No ingredients yet',
                                key: const ValueKey('editor-empty'),
                                style: CrudoText.body.copyWith(
                                  color: colors.onSurfaceMut,
                                ),
                              ),
                            ),
                          )
                        else
                          for (final (i, item) in draft.items.indexed)
                            _IngredientRow(
                              key: ValueKey('ingredient-$i'),
                              item: item,
                              colors: colors,
                              onTap: () => _editGrams(i, item),
                              onRemove: () => _ctrl.removeItem(i),
                            ),
                        const SizedBox(height: Spacing.sm),
                        Semantics(
                          button: true,
                          label: 'Add ingredient',
                          child: GestureDetector(
                            onTap: _addIngredient,
                            behavior: HitTestBehavior.opaque,
                            child: Container(
                              key: const ValueKey('add-ingredient'),
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                vertical: Spacing.md,
                              ),
                              decoration: BoxDecoration(
                                color: colors.surfaceLowest,
                                borderRadius: Radii.all(Radii.md),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.add,
                                    size: IconSizes.sm,
                                    color: colors.primary,
                                  ),
                                  const SizedBox(width: Spacing.sm),
                                  Text(
                                    'ADD INGREDIENT',
                                    style: CrudoText.labelMd.copyWith(
                                      color: colors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: Spacing.md),

                  // MACRO PREVIEW (gradient, live)
                  Container(
                    padding: const EdgeInsets.all(Spacing.md),
                    decoration: BoxDecoration(
                      borderRadius: Radii.all(Radii.lg),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft, // 135°
                        end: Alignment.bottomRight,
                        colors: [colors.primary, colors.primarySoft],
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AUTO-CALCULATED',
                          style: CrudoText.label.copyWith(
                            color: colors.surfaceLowest.withValues(
                              alpha: Opacities.muted,
                            ),
                          ),
                        ),
                        const SizedBox(height: Spacing.sm),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Expanded(
                              child: Text(
                                '${draft.macros.kcal.round()} kcal',
                                key: const ValueKey('editor-preview-kcal'),
                                style: CrudoText.displaySm.copyWith(
                                  color: colors.surfaceLowest,
                                ),
                              ),
                            ),
                            Text(
                              'P ${draft.macros.protein.round()}g'
                              '  C ${draft.macros.carbs.round()}g'
                              '  F ${draft.macros.fats.round()}g',
                              style: CrudoText.body.copyWith(
                                color: colors.surfaceLowest,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      ), // PopScope
    );
  }
}

class _IngredientRow extends StatelessWidget {
  const _IngredientRow({
    required this.item,
    required this.colors,
    required this.onTap,
    required this.onRemove,
    super.key,
  });

  final FoodSnapshot item;
  final CrudoColors colors;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Edit ${item.name} quantity',
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          margin: const EdgeInsets.only(bottom: Spacing.xs),
          padding: const EdgeInsets.all(Spacing.sm),
          decoration: BoxDecoration(
            color: colors.surfaceLowest,
            borderRadius: Radii.all(Radii.md),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: CrudoText.body.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colors.onSurface,
                      ),
                    ),
                    Text(
                      '${gramsText(item.grams.value)}g · '
                      '${item.kcal.round()} kcal',
                      style: CrudoText.body.copyWith(
                        color: colors.onSurfaceMut,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                key: ValueKey('remove-${item.name}'),
                onPressed: onRemove,
                icon: Icon(
                  Icons.close,
                  size: IconSizes.sm,
                  color: colors.onSurfaceMut,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

**Steps (TDD):**

- [ ] **1. Failing tests** in `meal_editor_screen_test.dart`. Harness: test `GoRouter` (`/` → launcher pushing `/meal/:date/:mealId/edit` → `MealEditorScreen`; `/meal/:date/:mealId/edit/add-ingredient` → a fake screen that immediately pops a known `FoodSnapshot`), seed/clock overrides as in Task 3's controller test; materialize today first via the container. Cases:
  - renders prefilled name, selected tag pills, 4 ingredient rows, live preview kcal.
  - clear name → SAVE dim-disabled; type name → enabled.
  - remove row → 3 ITEMS + preview kcal drops.
  - row tap → `GramsSheet`; preset 200 → Set quantity → row summary + preview rescale.
  - ADD INGREDIENT → fake picker pops snapshot → 5 ITEMS.
  - SAVE → route pops; repo day has the new content, all items unchecked.
  - **back, pristine** → pops silently, no write.
  - **back, dirty** → "Discard changes?" sheet; "Keep editing" → still on editor, draft intact; "Discard" → pops, repo content unchanged.
  - **system pop, dirty** (`tester.binding.handlePopRoute()` or `Navigator.maybePop`) → same confirm sheet (PopScope path).
  - **detach toast:** editor opened for `tomorrow` (preview), rename, SAVE → `detachToastMessage` toast + pop; same flow for `today` → NO detach toast.
  - SAVE after externally checking an item (drive `dayControllerProvider` directly in the test) → warn toast shown, still on editor.
- [ ] **2. Run** → FAIL. **3. Implement.** **4. Run** → PASS. **5.** format · analyze · full test green.

**Skills:** `flutter-add-widget-test`, `flutter-riverpod-arch`, `flutter-expert`.
**Out of scope:** real route registration (Task 9); detail screen.

---

## Task 9a: `MealDetailScreen` (screen + tests, no integration)

**Role:** `ui`. Split from the old Task 9 (review amendment) — the screen lands and is fully tested in isolation; Task 9b does the wiring. `meal_sheet.dart` stays alive until 9b.

**Files:**
- Create: `lib/ui/features/meals/views/meal_detail_screen.dart`
- Test: `test/ui/features/meals/views/meal_detail_screen_test.dart` (new — migrate the MealSheet cases from `test/ui/features/today/views/sheets_test.dart`, which itself is only TOUCHED in 9b)

**Contract — routes for reference** (registered in **Task 9b**, shown here because the screen pushes `…/edit` by path):

```dart
      // S08: meal detail / editor / picker — pushed over the shell. :date is
      // the ISO day label (dayParam/parseDayParam).
      GoRoute(
        path: '/meal/:date/:mealId',
        builder: (context, state) => MealDetailScreen(
          date: parseDayParam(state.pathParameters['date']!),
          mealId: state.pathParameters['mealId']!,
        ),
        routes: [
          GoRoute(
            path: 'edit',
            builder: (context, state) => MealEditorScreen(
              date: parseDayParam(state.pathParameters['date']!),
              mealId: state.pathParameters['mealId']!,
            ),
            routes: [
              GoRoute(
                path: 'add-ingredient',
                builder: (context, state) => const AddIngredientScreen(),
              ),
            ],
          ),
        ],
      ),
```

**Contract — `meal_detail_screen.dart`** (whole file; `_ItemRow`, `_CheckCircle`, `_CheckRingPainter`, `_ActionTile` move **verbatim** from `meal_sheet.dart` lines 181–346):

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../domain/services/meal_lifecycle.dart';
import '../../../../domain/services/nutrition.dart';
import '../../../../domain/shared/enums.dart';
import '../../../../domain/shared/macros.dart';
import '../../../core/formatting.dart';
import '../../../core/themes/colors.dart';
import '../../../core/themes/dimensions.dart';
import '../../../core/themes/typography.dart';
import '../../../core/widgets/primary_cta.dart';
import '../../../core/widgets/sheet.dart';
import '../../../core/widgets/sheet_actions.dart';
import '../../../core/widgets/toast.dart';
import '../../today/view_models/day_controller.dart';
import '../../today/view_models/today_providers.dart';
import 'snooze_sheet.dart';
import 'swap_sheet.dart';

/// S08 meal detail route — replaces the S06 MealSheet stand-in. Day modes:
/// today = marking + snooze/swap/edit · future = inert checklist + swap/edit
/// (first content edit detaches the day, S05 §4.2) · past = read-only.
/// Status display ONLY via mealStatus; eligibility ONLY via the predicates.
class MealDetailScreen extends ConsumerWidget {
  const MealDetailScreen({required this.date, required this.mealId, super.key});

  final DateTime date;
  final String mealId;

  static const _guardMessage = "That can't be changed anymore.";

  Future<void> _run(
    BuildContext context,
    Future<void> Function() op, {
    bool pop = false,
  }) => runDayOp(context, op, guardMessage: _guardMessage, pop: pop);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<CrudoColors>()!;
    final day = ref.watch(dayControllerProvider(date)).value;
    final meal = day?.meals.where((m) => m.id == mealId).firstOrNull;
    if (day == null) {
      return Scaffold(
        backgroundColor: colors.surface,
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (meal == null) {
      // Future-day preview ids are throwaway (S05 §4.2): a template edit
      // while this route is open re-mints them — degrade gracefully.
      return Scaffold(
        backgroundColor: colors.surface,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                onPressed: context.pop,
                icon: Icon(
                  Icons.arrow_back,
                  size: IconSizes.lg,
                  color: colors.onSurface,
                ),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    'This meal is no longer here.',
                    key: const ValueKey('meal-gone'),
                    style: CrudoText.body,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final now = ref.watch(clockProvider)();
    final today = ref.watch(todayProvider);
    final isToday = date.isAtSameMomentAs(today);
    final isPast = date.isBefore(today);
    final status = mealStatus(day, mealId, now);
    final canEdit = canEditMealContent(meal, day.date, now);
    final ctrl = ref.read(dayControllerProvider(date).notifier);
    final tag = meal.meal.tags.isEmpty ? 'Meal' : meal.meal.tags.first.name;

    final items = meal.meal.items;
    final checkedCount = items.where((i) => i.checked).length;
    final isPartial = checkedCount > 0 && checkedCount < items.length;

    final snoozedLabel =
        meal.snoozedUntil != null &&
            (status == MealStatus.upcoming || status == MealStatus.overdue)
        ? '${mealTimeLabel(meal.time)} → ${timeOfDayLabel(meal.snoozedUntil!.toLocal())}'
        : mealTimeLabel(meal.time);

    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: back · name + meta · Edit (gated by canEditMealContent).
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Spacing.md, Spacing.sm, Spacing.md, 0,
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: context.pop,
                    icon: Icon(
                      Icons.arrow_back,
                      size: IconSizes.lg,
                      color: colors.onSurface,
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          meal.meal.name,
                          style: CrudoText.headlineSm,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '$snoozedLabel · $tag · ${status.name}'.toUpperCase(),
                          style: CrudoText.label,
                        ),
                      ],
                    ),
                  ),
                  Opacity(
                    opacity: canEdit ? 1 : Opacities.disabled,
                    child: IconButton(
                      key: const ValueKey('edit-meal'),
                      onPressed: () {
                        if (!canEdit) {
                          showCrudoToast(
                            context,
                            _guardMessage,
                            kind: ToastKind.warn,
                          );
                          return;
                        }
                        context.push('/meal/${dayParam(date)}/$mealId/edit');
                      },
                      icon: Icon(
                        Icons.edit_outlined,
                        size: IconSizes.md,
                        color: colors.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  Spacing.md, Spacing.sm, Spacing.md, Spacing.xl,
                ),
                children: [
                  _MacroSummary(macros: mealSnapshotMacros(meal.meal)),
                  const SizedBox(height: Spacing.lg),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      const Expanded(
                        child: Text('Ingredients', style: CrudoText.headlineSm),
                      ),
                      Text(
                        '$checkedCount OF ${items.length} EATEN',
                        key: const ValueKey('eaten-count'),
                        style: CrudoText.label,
                      ),
                    ],
                  ),
                  const SizedBox(height: Spacing.sm),
                  _EatenProgress(
                    fraction: items.isEmpty
                        ? 0
                        : checkedCount / items.length,
                    colors: colors,
                  ),
                  const SizedBox(height: Spacing.sm),
                  for (final (i, item) in items.indexed)
                    _ItemRow(
                      key: ValueKey('item-check-$i'),
                      name: item.food.name,
                      grams: item.food.grams.value,
                      kcal: item.food.kcal,
                      checked: item.checked,
                      colors: colors,
                      onTap: !isToday
                          ? null
                          : () => _run(
                              context,
                              () => item.checked
                                  ? ctrl.uncheckItem(mealId, i)
                                  : ctrl.checkItem(mealId, i),
                            ),
                    ),
                  if (!isPast) ...[
                    const SizedBox(height: Spacing.md),
                    Row(
                      children: [
                        if (isToday) ...[
                          Expanded(
                            child: _ActionTile(
                              key: const ValueKey('tile-snooze'),
                              icon: Icons.snooze_outlined,
                              title: 'Snooze',
                              subtitle:
                                  '${snoozePresetMinutes.last}m delay, no further',
                              enabled: canSnoozeMeal(day, mealId, now, today),
                              colors: colors,
                              onTap: () => showCrudoSheet<void>(
                                context,
                                builder: (_) =>
                                    SnoozeSheet(date: date, mealId: mealId),
                              ),
                              onDisabledTap: () {
                                final reason = snoozeIneligibilityReason(
                                  day, mealId, now, today,
                                );
                                if (reason != null) {
                                  showCrudoToast(
                                    context, reason, kind: ToastKind.warn,
                                  );
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: Spacing.sm),
                        ],
                        Expanded(
                          child: _ActionTile(
                            key: const ValueKey('tile-swap'),
                            icon: Icons.swap_horiz,
                            title: 'Swap meal',
                            subtitle: 'Pick from library',
                            enabled: canEdit,
                            colors: colors,
                            onTap: () => showCrudoSheet<void>(
                              context,
                              builder: (_) =>
                                  SwapSheet(date: date, mealId: mealId),
                            ),
                            onDisabledTap: () => showCrudoToast(
                              context, _guardMessage, kind: ToastKind.warn,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: !isToday
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(Spacing.md),
                child: Row(
                  children: [
                    Expanded(
                      child: SecondaryAction(
                        label: 'Skip',
                        enabled: canSkipMeal(day, mealId, today),
                        onTap: () => _run(
                          context, () => ctrl.skipMeal(mealId), pop: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: Spacing.sm),
                    Expanded(
                      flex: 2,
                      child: PrimaryCta(
                        label: isPartial ? 'Save Partial' : 'Mark Done',
                        onPressed: checkedCount == 0
                            ? () => _run(
                                context,
                                () => ctrl.markAllEaten(mealId),
                                pop: true,
                              )
                            : () => context.pop(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

/// Total-intake card (meal.jsx 33–51): big kcal + three macro mini-tiles.
class _MacroSummary extends StatelessWidget {
  const _MacroSummary({required this.macros});

  final Macros macros;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CrudoColors>()!;
    final tiles = [
      ('PROTEIN', macros.protein, colors.proteinColor),
      ('CARBS', macros.carbs, colors.carbsColor),
      ('FATS', macros.fats, colors.fatsColor),
    ];
    return Container(
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        color: colors.surfaceLow,
        borderRadius: Radii.all(Radii.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('TOTAL INTAKE', style: CrudoText.label),
          const SizedBox(height: Spacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '${macros.kcal.round()}',
                key: const ValueKey('detail-kcal'),
                style: CrudoText.display,
              ),
              const SizedBox(width: Spacing.sm),
              Text(
                'kcal',
                style: CrudoText.body.copyWith(color: colors.onSurfaceMut),
              ),
            ],
          ),
          const SizedBox(height: Spacing.md),
          Row(
            children: [
              for (final (label, value, accent) in tiles) ...[
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(Spacing.sm),
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: Radii.all(Radii.md),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(label, style: CrudoText.label),
                        const SizedBox(height: Spacing.xs),
                        Text.rich(
                          TextSpan(
                            text: '${value.round()}',
                            style: CrudoText.title.copyWith(color: accent),
                            children: [
                              TextSpan(
                                text: 'g',
                                style: CrudoText.label.copyWith(
                                  color: colors.onSurfaceMut,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (label != 'FATS') const SizedBox(width: Spacing.sm),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// Thin eaten-fraction bar. Height = 4 (4px grid; design_system §5).
class _EatenProgress extends StatelessWidget {
  const _EatenProgress({required this.fraction, required this.colors});

  final double fraction;
  final CrudoColors colors;

  static const _height = 4.0; // component size, 4px grid (§5)

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: Radii.all(Radii.full),
      child: SizedBox(
        height: _height,
        child: Row(
          children: [
            Expanded(
              flex: (fraction * 1000).round(),
              child: ColoredBox(color: colors.primary),
            ),
            Expanded(
              flex: ((1 - fraction) * 1000).round(),
              child: ColoredBox(color: colors.surfaceLow),
            ),
          ],
        ),
      ),
    );
  }
}

// _ItemRow, _CheckCircle, _CheckRingPainter, _ActionTile: moved VERBATIM
// from lib/ui/features/today/views/meal_sheet.dart (lines 181–346).
```

Guard the degenerate `_EatenProgress` flexes: when `fraction == 0` the first `Expanded` gets flex 0 — Flutter requires flex ≥ 0, which holds; both 0 is impossible (they sum to 1000).

**Steps (TDD):**

- [ ] **1. Failing tests.** `meal_detail_screen_test.dart` — harness: test `GoRouter` (`/` → launcher pushing `/meal/:date/:mealId` → `MealDetailScreen`; `…/edit` → a probe screen recording it was pushed), overrides as in `sheets_test.dart`. Migrate every MealSheet case from `sheets_test.dart` (copy, don't move yet) and add the new ones:
  - **today mode:** checklist toggles persist; footer matrix (0 checked → Mark Done marks all + pops · some → Save Partial pops · all → Mark Done pops); Skip enabled/disabled per `canSkipMeal`; snooze tile opens `SnoozeSheet`, disabled-tap toasts the reason; macro summary kcal + `eaten-count` label correct.
  - **edit gating:** upcoming → edit icon pushes the probe route; after `markAllEaten` → icon dimmed, tap toasts `_guardMessage`, no push; same for an explicitly skipped meal.
  - **swap tile:** upcoming → opens `SwapSheet`; checked meal → dimmed + toast.
  - **past mode:** checklist inert, no tiles, no footer, edit dimmed.
  - **future mode:** checklist inert, snooze tile ABSENT, swap tile present + enabled, edit enabled, no footer.
  - **meal gone:** pump with an unknown mealId → `ValueKey('meal-gone')`.
- [ ] **2. Run:** `flutter test test/ui/features/meals` → FAIL.
- [ ] **3. Implement** the screen (contract above; `_ItemRow`/`_CheckCircle`/`_CheckRingPainter`/`_ActionTile` copied verbatim from `meal_sheet.dart` — the originals stay until 9b deletes the file).
- [ ] **4. Run** → PASS. **5.** `dart format .` · `flutter analyze` clean · `flutter test` full suite green (MealSheet tests still green beside the new ones).

**Skills:** `flutter-add-widget-test`, `flutter-riverpod-arch`, `flutter-expert` (semantics on edit icon + tiles).
**Out of scope:** `app_router.dart`, `today_screen.dart`, deleting `meal_sheet.dart` — all Task 9b.

---

## Task 9b: Routes + Today wiring — MealSheet retires

**Role:** `ui`. The integration step, deliberately small: every screen it wires already has green tests.

**Files:**
- Modify: `lib/routing/app_router.dart` (register the `/meal` subtree — the routes block shown in Task 9a)
- Modify: `lib/ui/features/today/views/today_screen.dart` (push route instead of sheet; future cards tappable)
- Delete: `lib/ui/features/today/views/meal_sheet.dart`
- Modify: `test/ui/features/today/views/sheets_test.dart` (drop the MealSheet blocks — their migrated copies live in `meal_detail_screen_test.dart` since 9a; SnoozeSheet blocks stay), `today_screen_test.dart` (router harness)
- Modify: `docs/design_system.md` (§5 entries)

**Contract — Today wiring** (in `today_screen.dart`):
- Remove the `meal_sheet.dart` import; add `package:go_router/go_router.dart` and keep `formatting.dart` (re-exports `mealTimeLabel`; `dayParam` comes via `package:crudo/ui/core/formatting.dart` — import it directly).
- Replace the card `onTap` (the `selected.isAfter(today) ? null : …` block) with — **future cards become tappable**:

```dart
                        onTap: () {
                          if (isToday) {
                            ref
                                .read(intakeFreezeProvider.notifier)
                                .freeze(consumedMacros(day));
                          }
                          context
                              .push('/meal/${dayParam(selected)}/${meal.id}')
                              .whenComplete(() {
                            if (isToday) {
                              ref
                                  .read(intakeFreezeProvider.notifier)
                                  .clear();
                            }
                          });
                        },
```

- Delete `lib/ui/features/today/views/meal_sheet.dart` (its private widgets now live in `meal_detail_screen.dart`; `showMealSheet`/`MealSheet`/`readOnly` are gone).

**Steps (TDD):**

- [ ] **1. Failing tests.** Update `today_screen_test.dart`: harness becomes `MaterialApp.router` with a two-route test router (`/` → `TodayScreen`; `/meal/:date/:mealId` → `MealDetailScreen` via `parseDayParam`); card-tap test asserts `MealDetailScreen` appears — for today AND for a future-day selection (new behavior); intake-freeze test asserts frozen during push, cleared after pop.
- [ ] **2. Run:** `flutter test test/ui/features/today` → FAIL (today_screen still opens the sheet).
- [ ] **3. Implement:** register the `/meal` subtree in `app_router.dart` (routes block in Task 9a); rewire `today_screen.dart` per the contract above; delete `lib/ui/features/today/views/meal_sheet.dart`; drop the MealSheet blocks from `sheets_test.dart` (their copies live in `meal_detail_screen_test.dart` since 9a; SnoozeSheet blocks stay).
- [ ] **4. Run:** `flutter test` → **full suite** PASS.
- [ ] **5.** Add to `docs/design_system.md §5`: `MealDetailScreen._EatenProgress` height 4 · macro mini-tile uses `Spacing.sm` padding / `Radii.md` · picker CTA icon circle 40 (shared with sheet grabber width). `dart format .` · `flutter analyze` clean.

**Skills:** `flutter-setup-declarative-routing`, `flutter-add-widget-test`, `flutter-riverpod-arch`.
**Out of scope:** changing checklist row visuals; touching `_apply` marking guards.

---

## Task 10: Gallery entries + final sweep

**Role:** `build`.

**Files:**
- Modify: `lib/previews.dart`
- Modify: `docs/design_system.md` (§5 — verify Task 9's entries landed; add any missed token note)

**Steps:**

- [ ] **1.** In `lib/previews.dart`, replace the stale comment "MealSheet / SnoozeSheet are provider-driven…" with "MealDetailScreen / MealEditorScreen / AddIngredientScreen / SnoozeSheet / SwapSheet are provider-driven — verified via the dev flavor + widget tests, not from this static gallery." Add static-widget entries that CAN be previewed (follow the existing `FoodRow` entry pattern):
  - `GramsEntry` (baseline = a handmade `FoodSnapshot` via `FoodSnapshot.from` of the preview chicken `Food` at `Grams(100)`, `initialGrams: 150`, `onChanged: (_) {}`).
  - `_CreateCustomCta` is private — skip it; instead add a `FoodLibraryList` note line (provider-driven).
- [ ] **2.** `grep -rn "TODO(S08)" lib test` → must return nothing (the swap-tile stub died with `meal_sheet.dart`).
- [ ] **3.** `grep -rn "meal_sheet" lib test` → must return nothing.
- [ ] **4.** Full gate: `dart format .` (no changes) · `flutter analyze` (clean) · `flutter test` (green, including the architecture test).
- [ ] **5.** Write the worker report to `.opencode/handoff/2026-06-07-s08-meal-editor.report.md` (status, per-task checklist, verification output, files touched, deviations, blockers).

**Skills:** `flutter-add-widget-preview`.
**Out of scope:** everything else.

---

## Self-review (done at planning time)

- **Spec coverage:** detail route (T9a) · day modes (T9a) · CoW detach (T2) · draft+replaceMeal commit, unchecked by construction (T3) · swap sheet immediate + detach toast (T6) · picker + grams stage + presets (T7) · custom-food pop-result round-trip (T5+T7) · grams re-edit via scaledTo (T1+T8) · discard-confirm on dirty back (T8) · `FoodLibraryList` reuse with inert-seed library mode preserved (T5) · snooze today-only UI (T9a) · eligibility via predicates only (T6–T9a) · relocations per architecture tree (T4) · routes + Today wiring (T9b) · gallery + §5 entries (T9b–T10). Demo-seed weekday fix: already applied + tested in the working tree (separate commit before this plan).
- **Type consistency:** `replaceMeal(String mealId, MealSnapshot newMeal)` (T2) consumed by T3/T6; `mealSnapshotFromTemplate(MealTemplate, List<Food>)` (T1) consumed by T2-tests/T6; `FoodSnapshot.scaledTo(Grams)` (T1) consumed by T3/T7/T8; `mealDraftControllerProvider(date, mealId)` positional family everywhere; `isDirty` (T3) consumed by T8's PopScope; `detachToastMessage` (T6 formatting.dart) consumed by T6/T8; `dayParam`/`parseDayParam` (T4) consumed by T8/T9a/T9b.
- **Known mid-plan states:** until T9b, `meal_sheet.dart` keeps working against the moved snooze/sheet-action files (T4 fixes its imports) and its `sheets_test.dart` cases coexist with their migrated copies (9a copies, 9b deletes); routes don't exist until T9b — T7/T8/T9a widget tests use local test routers by design.
- **Review resolution (2026-06-07):** amendments from the critical reviews folded in — draft load-once (T3, real clobber bug), `isDirty` + discard-confirm (T3/T8), detach toast (T6/T8), T9 split into 9a/9b. Scope kept in full; rejected points logged in the spec's decisions section.
