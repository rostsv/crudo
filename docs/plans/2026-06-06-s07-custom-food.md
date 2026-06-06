# S07 Custom Food + Food Library — Implementation Plan

> **For the worker:** implement task-by-task, top to bottom; each task = contract + steps; read the `.agents/skills` each task names before starting it. Spec: `docs/specs/2026-06-06-s07-custom-food.md`. Repo rules: `AGENTS.md`. Workers do **not** commit — finish each task with format → analyze → test, then report done for review.

**Goal:** A new `foods` feature: a browsable food library (search + grouped seed+custom foods) at `/foods`, and a custom-food form with full CRUD — kcal auto-calc (Atwater) with an optional explicit override hard-validated to ±10 %, Product|Dish toggle, optional category. Seed foods stay read-only.

**Architecture:** Zero new domain code — `Food`, `calculatedKcal`, `isExplicitKcalValid`, `FoodValidation.validate()`, `ValidationCode.kcalOverrideOutOfRange`, and `FoodRepository` all exist (S02/S03/S05). S07 is a UI feature: view-models first (library grouping provider, `FoodDraft` + `FoodDraftController`), then routing + library screen, then the form screen. Dependency rule as always: View → Controller → Repository; `lib/domain/` imports nothing new.

**Tech stack:** Flutter, Riverpod 3 codegen (`@riverpod`), `go_router`, `package:checks` assertions, `flutter_test`. Codegen: `dart run build_runner build` after adding each provider file.

**Visual target:** `docs/design/prototype/screens/meal.jsx` lines 415–533 (`AddCustomFoodScreen`) + the list portion of `AddIngredientScreen` (lines 249–353) for grouping/search — composition only; every dimension snaps to `lib/ui/core/themes/dimensions.dart` tokens per `docs/design_system.md §5`. The prototype lacks the Product|Dish toggle — S05's design doc mandates it (default `product`); add it anyway.

**Color/theme idiom:** wherever a snippet below says `colors`, obtain `CrudoColors` exactly the way `lib/ui/features/today/views/intake_card.dart` does — copy that lookup, don't invent a new one.

---

## Task 1: View-models — library grouping + search

**Role:** Riverpod view-model engineer. No widgets in this task.

**Goal:** the reactive "library view": all foods from `FoodRepository.watchAll()`, filtered by a search query, grouped — categories in enum order, dishes last, alphabetical within a group, empty groups omitted.

**Files:**
- Create: `lib/ui/features/foods/view_models/food_library.dart`
- Codegen: `dart run build_runner build` (generates `food_library.g.dart`)
- Test: `test/ui/features/foods/view_models/food_library_test.dart` (new)

**Contract:**

```dart
// food_library.dart — whole file:
import 'package:crudo/config/di.dart';
import 'package:crudo/domain/food/food.dart';
import 'package:crudo/domain/shared/enums.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'food_library.g.dart';

/// One rendered section of the library list.
typedef FoodGroup = ({String label, List<Food> foods});

/// Display labels (library sections + S07 form chips; prototype CAT_LABELS).
const foodCategoryLabels = <FoodCategory, String>{
  FoodCategory.meat: 'Meat',
  FoodCategory.fish: 'Fish',
  FoodCategory.eggs: 'Eggs & Dairy',
  FoodCategory.grain: 'Grains',
  FoodCategory.veg: 'Vegetables',
  FoodCategory.fruit: 'Fruits',
  FoodCategory.oil: 'Oils & Fats',
  FoodCategory.custom: 'Custom',
};

const dishesGroupLabel = 'Dishes';

@riverpod
Stream<List<Food>> libraryFoods(Ref ref) =>
    ref.watch(foodRepositoryProvider).watchAll();

@riverpod
class FoodSearchQuery extends _$FoodSearchQuery {
  @override
  String build() => '';

  void setQuery(String value) => state = value;
}

/// Search + grouping over the whole library (S07): kind == dish → "Dishes"
/// group placed last (S05 §1.4); products grouped by category in enum
/// order; alphabetical within a group; empty groups omitted.
@riverpod
Future<List<FoodGroup>> foodLibrary(Ref ref) async {
  final foods = await ref.watch(libraryFoodsProvider.future);
  final q = ref.watch(foodSearchQueryProvider).trim().toLowerCase();
  final visible = q.isEmpty
      ? foods
      : [
          for (final f in foods)
            if (f.name.toLowerCase().contains(q)) f,
        ];
  int byName(Food a, Food b) =>
      a.name.toLowerCase().compareTo(b.name.toLowerCase());
  final groups = <FoodGroup>[];
  for (final cat in FoodCategory.values) {
    final inCat = [
      for (final f in visible)
        if (f.kind == FoodKind.product && f.category == cat) f,
    ]..sort(byName);
    if (inCat.isNotEmpty) {
      groups.add((label: foodCategoryLabels[cat]!, foods: inCat));
    }
  }
  final dishes = [
    for (final f in visible)
      if (f.kind == FoodKind.dish) f,
  ]..sort(byName);
  if (dishes.isNotEmpty) groups.add((label: dishesGroupLabel, foods: dishes));
  return groups;
}
```

Note: a `foodsProvider` already exists in `today/view_models/today_providers.dart`; `libraryFoods` is deliberately separate — features don't import each other's view_models.

**Steps (TDD):**

- [ ] **1. Write the failing tests.** New file `test/ui/features/foods/view_models/food_library_test.dart` with a small handmade seed (NOT the 63-food asset — deterministic and fast). kcal values are exact Atwater:

```dart
import 'package:checks/checks.dart';
import 'package:crudo/config/di.dart';
import 'package:crudo/domain/food/food.dart';
import 'package:crudo/domain/shared/enums.dart';
import 'package:crudo/ui/features/foods/view_models/food_library.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _chicken = Food(
  id: 'seed-chicken-breast', name: 'Chicken breast',
  category: FoodCategory.meat,
  protein: 31, carbs: 0, fats: 3.6, kcalPer100g: 156.4,
);
const _turkey = Food(
  id: 'seed-turkey', name: 'Turkey',
  category: FoodCategory.meat,
  protein: 29, carbs: 0, fats: 1, kcalPer100g: 125,
);
const _broccoli = Food(
  id: 'seed-broccoli', name: 'Broccoli',
  category: FoodCategory.veg,
  protein: 2.8, carbs: 7, fats: 0.4, kcalPer100g: 42.8,
);
const _shake = Food(
  id: 'c1', name: 'My shake',
  category: FoodCategory.custom,
  protein: 30, carbs: 10, fats: 5, kcalPer100g: 205, isCustom: true,
);
const _soup = Food(
  id: 'c2', name: 'Mom soup', kind: FoodKind.dish,
  category: FoodCategory.custom,
  protein: 5, carbs: 8, fats: 3, kcalPer100g: 79, isCustom: true,
);

void main() {
  ProviderContainer container() {
    final c = ProviderContainer(
      overrides: [
        seedFoodsProvider.overrideWithValue(
          const [_chicken, _turkey, _broccoli, _shake, _soup],
        ),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  test('groups: category enum order, dishes last, empty groups omitted',
      () async {
    final groups = await container().read(foodLibraryProvider.future);
    check(groups.map((g) => g.label).toList())
        .deepEquals(['Meat', 'Vegetables', 'Custom', 'Dishes']);
  });

  test('alphabetical within a group (case-insensitive)', () async {
    final groups = await container().read(foodLibraryProvider.future);
    check(groups.first.foods.map((f) => f.name).toList())
        .deepEquals(['Chicken breast', 'Turkey']);
  });

  test('search: case-insensitive contains', () async {
    final c = container();
    c.read(foodSearchQueryProvider.notifier).setQuery('  BROC');
    // note: leading whitespace trimmed, case ignored
    final groups = await c.read(foodLibraryProvider.future);
    check(groups.map((g) => g.label).toList()).deepEquals(['Vegetables']);
    check(groups.single.foods.single.name).equals('Broccoli');
  });

  test('no match → empty list', () async {
    final c = container();
    c.read(foodSearchQueryProvider.notifier).setQuery('zzz');
    check(await c.read(foodLibraryProvider.future)).isEmpty();
  });

  test('repo save re-emits: a new custom food appears', () async {
    final c = container();
    c.listen(foodLibraryProvider, (_, _) {}); // keep alive across emissions
    await c.read(foodLibraryProvider.future);
    await c.read(foodRepositoryProvider).save(
          const Food(
            id: 'c3', name: 'Bar',
            category: FoodCategory.custom,
            protein: 20, carbs: 30, fats: 10,
            kcalPer100g: 290, isCustom: true,
          ),
        );
    await Future<void>.delayed(Duration.zero); // let the stream emit
    final groups = await c.read(foodLibraryProvider.future);
    final custom = groups.singleWhere((g) => g.label == 'Custom');
    check(custom.foods.map((f) => f.name).toList())
        .deepEquals(['Bar', 'My shake']);
  });
}
```

- [ ] **2. Run — must fail** (file/provider undefined):
  `flutter test test/ui/features/foods/view_models/food_library_test.dart`
- [ ] **3. Implement** the contract file verbatim; run `dart run build_runner build`.
- [ ] **4. Run the test file — green.**
- [ ] **5.** `dart format .` → `flutter analyze` → `flutter test` (all green). Report done for review.

**Skills:** `.agents/skills/flutter-riverpod-arch`, `.agents/skills/dart-add-unit-test`, `.agents/skills/dart-migrate-to-checks-package`.

**Acceptance:** provider compiles via codegen; grouping/search/reactivity tests green; no widget files; architecture test green.

**Out of scope:** draft/controller (Task 2); any view.

---

## Task 2: View-models — `FoodDraft` + `FoodDraftController`

**Role:** Riverpod view-model engineer. No widgets in this task.

**Goal:** the form's state: an immutable draft with derived validation (reusing the domain fns — never reimplementing the ±10 % or mass rules), and an `AsyncNotifier`-family controller (null id = create, id = edit) with save/delete.

**Files:**
- Create: `lib/ui/features/foods/view_models/food_draft.dart` (pure Dart — domain imports only, no Riverpod)
- Create: `lib/ui/features/foods/view_models/food_draft_controller.dart`
- Codegen: `dart run build_runner build` (generates `food_draft_controller.g.dart`)
- Test: `test/ui/features/foods/view_models/food_draft_controller_test.dart` (new — covers both files)

**Contract:**

```dart
// food_draft.dart — whole file:
import 'package:crudo/domain/food/food.dart';
import 'package:crudo/domain/services/nutrition.dart';
import 'package:crudo/domain/shared/enums.dart';
import 'package:crudo/domain/validation/validation_issue.dart';
import 'package:crudo/domain/validation/validators.dart';

/// In-progress add/edit-food form state (S07). Immutable — the controller
/// swaps whole instances via the withX methods. `explicitKcal == null`
/// means auto (Atwater); a non-null value is the user's override, gated
/// by isExplicitKcalValid before save.
class FoodDraft {
  const FoodDraft({
    this.name = '',
    this.kind = FoodKind.product,
    this.category,
    this.protein = 0,
    this.carbs = 0,
    this.fats = 0,
    this.explicitKcal,
  });

  /// Prefill for edit. A stored kcal exactly equal to the formula renders
  /// as auto; anything else was an accepted override — show it. A stored
  /// category of `custom` renders as "no chip selected" (saving with no
  /// chip writes `custom` back — symmetric).
  factory FoodDraft.fromFood(Food food) {
    final calc = calculatedKcal(
      protein: food.protein,
      carbs: food.carbs,
      fats: food.fats,
    );
    return FoodDraft(
      name: food.name,
      kind: food.kind,
      category: food.category == FoodCategory.custom ? null : food.category,
      protein: food.protein,
      carbs: food.carbs,
      fats: food.fats,
      explicitKcal: food.kcalPer100g == calc ? null : food.kcalPer100g,
    );
  }

  final String name;
  final FoodKind kind;
  final FoodCategory? category; // null = no chip → saved as custom
  final double protein;
  final double carbs;
  final double fats;
  final double? explicitKcal; // null = auto

  double get calculated =>
      calculatedKcal(protein: protein, carbs: carbs, fats: fats);

  double get effectiveKcal => explicitKcal ?? calculated;

  bool get kcalValid =>
      explicitKcal == null ||
      isExplicitKcalValid(calculated: calculated, explicit: explicitKcal!);

  /// Domain save rules (blank name, macro mass ≤ 101) + the S07 form rule
  /// (explicit kcal within ±10 % — ValidationCode.kcalOverrideOutOfRange,
  /// reserved for this since S02).
  List<ValidationIssue> get issues => [
        ...toFood('draft').validate(),
        if (!kcalValid)
          const ValidationIssue(
            field: 'kcalPer100g',
            code: ValidationCode.kcalOverrideOutOfRange,
            message:
                'kcal must be within ±10% of the value calculated from macros',
          ),
      ];

  bool get canSave => issues.isEmpty;

  /// The Food this draft saves as. Drafts only ever produce custom foods.
  Food toFood(String id) => Food(
        id: id,
        name: name,
        kind: kind,
        category: category ?? FoodCategory.custom,
        protein: protein,
        carbs: carbs,
        fats: fats,
        kcalPer100g: effectiveKcal,
        isCustom: true,
      );

  FoodDraft withName(String v) => FoodDraft(
        name: v, kind: kind, category: category,
        protein: protein, carbs: carbs, fats: fats,
        explicitKcal: explicitKcal,
      );
  FoodDraft withKind(FoodKind v) => FoodDraft(
        name: name, kind: v, category: category,
        protein: protein, carbs: carbs, fats: fats,
        explicitKcal: explicitKcal,
      );
  FoodDraft withCategory(FoodCategory? v) => FoodDraft(
        name: name, kind: kind, category: v,
        protein: protein, carbs: carbs, fats: fats,
        explicitKcal: explicitKcal,
      );
  FoodDraft withProtein(double v) => FoodDraft(
        name: name, kind: kind, category: category,
        protein: v, carbs: carbs, fats: fats,
        explicitKcal: explicitKcal,
      );
  FoodDraft withCarbs(double v) => FoodDraft(
        name: name, kind: kind, category: category,
        protein: protein, carbs: v, fats: fats,
        explicitKcal: explicitKcal,
      );
  FoodDraft withFats(double v) => FoodDraft(
        name: name, kind: kind, category: category,
        protein: protein, carbs: carbs, fats: v,
        explicitKcal: explicitKcal,
      );
  FoodDraft withExplicitKcal(double? v) => FoodDraft(
        name: name, kind: kind, category: category,
        protein: protein, carbs: carbs, fats: fats,
        explicitKcal: v,
      );
}
```

(Hand-written `withX` instead of freezed: the only consumer is the controller, and `withExplicitKcal(null)`/`withCategory(null)` must genuinely clear — no sentinel gymnastics, no codegen.)

```dart
// food_draft_controller.dart — whole file:
import 'package:crudo/config/di.dart';
import 'package:crudo/data/services/id_generator.dart';
import 'package:crudo/domain/shared/enums.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'food_draft.dart';

part 'food_draft_controller.g.dart';

/// Add/edit-food form controller (S07). `foodId == null` = create;
/// otherwise loads the existing CUSTOM food for editing. Seed foods are
/// read-only — routing one here is a programming error and surfaces as
/// the provider's error state.
@riverpod
class FoodDraftController extends _$FoodDraftController {
  @override
  Future<FoodDraft> build(String? foodId) async {
    if (foodId == null) return const FoodDraft();
    final food = await ref.watch(foodRepositoryProvider).getById(foodId);
    if (food == null) throw StateError('no food with id $foodId');
    if (!food.isCustom) throw StateError('seed foods are read-only');
    return FoodDraft.fromFood(food);
  }

  void setName(String v) => _update((d) => d.withName(v));
  void setKind(FoodKind v) => _update((d) => d.withKind(v));
  void setCategory(FoodCategory? v) => _update((d) => d.withCategory(v));
  void setProtein(double v) => _update((d) => d.withProtein(v < 0 ? 0 : v));
  void setCarbs(double v) => _update((d) => d.withCarbs(v < 0 ? 0 : v));
  void setFats(double v) => _update((d) => d.withFats(v < 0 ? 0 : v));
  void setExplicitKcal(double? v) =>
      _update((d) => d.withExplicitKcal(v != null && v < 0 ? 0 : v));

  /// Mirrors the UI gate (SAVE disabled unless canSave) — reaching this
  /// with an invalid draft is a bug, not a user error.
  Future<void> save() async {
    final draft = state.requireValue;
    if (!draft.canSave) throw StateError('draft has validation issues');
    final id = foodId ?? ref.read(idGeneratorProvider).newId();
    await ref.read(foodRepositoryProvider).save(draft.toFood(id));
  }

  /// Unconditional in S07: nothing can reference a food before templates
  /// exist (S09 adds the block-while-referenced check). Logged days hold
  /// frozen FoodSnapshot copies — never affected.
  Future<void> delete() async {
    final id = foodId;
    if (id == null) throw StateError('cannot delete an unsaved draft');
    await ref.read(foodRepositoryProvider).delete(id);
  }

  void _update(FoodDraft Function(FoodDraft) fn) {
    final d = state.valueOrNull;
    if (d != null) state = AsyncData(fn(d));
  }
}
```

**Steps (TDD):**

- [ ] **1. Write the failing tests** in `test/ui/features/foods/view_models/food_draft_controller_test.dart`. Reuse the `_chicken`/`_shake` fixtures from Task 1's test (copy the consts — test files stay self-contained). Local fake id generator (don't extract anything from existing tests):

```dart
class _FakeIdGenerator implements IdGenerator {
  int _n = 0;
  @override
  String newId() => 'id-${_n++}';
}
```

  Container: overrides `seedFoodsProvider` (with `[_chicken, _shake]` plus an override-kcal food `_jam`, below) and `idGeneratorProvider.overrideWithValue(_FakeIdGenerator())`; `addTearDown(c.dispose)`. For every controller read, first `c.listen(foodDraftControllerProvider(<id>), (_, _) {})` to keep the autoDispose provider alive.

```dart
const _jam = Food(
  id: 'c9', name: 'Label jam',
  category: FoodCategory.custom,
  protein: 0, carbs: 50, fats: 0,
  kcalPer100g: 210, // calc = 200; stored ≠ calc → was an explicit override
  isCustom: true,
);
```

  Draft-validation group (pure, no container):

```dart
group('FoodDraft validation', () {
  // calc = 20*4 + 30*4 + 10*9 = 290; ±10% bound = 319.0
  const base = FoodDraft(name: 'X', protein: 20, carbs: 30, fats: 10);

  test('valid draft, auto kcal', () {
    check(base.canSave).isTrue();
    check(base.effectiveKcal).equals(290);
  });
  test('explicit kcal at the ±10% boundary is accepted', () {
    check(base.withExplicitKcal(319).canSave).isTrue();
    check(base.withExplicitKcal(319).effectiveKcal).equals(319);
  });
  test('explicit kcal outside ±10% → kcalOverrideOutOfRange', () {
    check(base.withExplicitKcal(320).issues.map((i) => i.code))
        .contains(ValidationCode.kcalOverrideOutOfRange);
    check(base.withExplicitKcal(320).canSave).isFalse();
  });
  test('blank name → blankName', () {
    check(base.withName('  ').issues.map((i) => i.code))
        .contains(ValidationCode.blankName);
  });
  test('macro mass > 101 blocked; 100.9 ok', () {
    check(base.withProtein(60).withCarbs(50).issues.map((i) => i.code))
        .contains(ValidationCode.macroMassExceeded);
    check(
      const FoodDraft(name: 'X', protein: 60, carbs: 40, fats: 0.9).canSave,
    ).isTrue();
  });
  test('all-zero macros allowed (water); explicit must then be 0', () {
    const water = FoodDraft(name: 'Water');
    check(water.canSave).isTrue();
    check(water.effectiveKcal).equals(0);
    check(water.withExplicitKcal(0).canSave).isTrue();
    check(water.withExplicitKcal(5).issues.map((i) => i.code))
        .contains(ValidationCode.kcalOverrideOutOfRange);
  });
  test('fromFood: stored == calc → auto; stored ≠ calc → prefilled override',
      () {
    check(FoodDraft.fromFood(_shake).explicitKcal).isNull(); // 205 == calc
    check(FoodDraft.fromFood(_jam).explicitKcal).equals(210);
    check(FoodDraft.fromFood(_shake).category).isNull(); // custom → no chip
  });
});
```

  Controller group (async, with container):

```dart
test('create: defaults, save mints uuid once, isCustom, category default',
    () async {
  final c = container();
  c.listen(foodDraftControllerProvider(null), (_, _) {});
  await c.read(foodDraftControllerProvider(null).future);
  final ctrl = c.read(foodDraftControllerProvider(null).notifier);
  ctrl.setName('My bar');
  ctrl.setProtein(30);
  ctrl.setCarbs(10);
  ctrl.setFats(5);
  await ctrl.save();
  final saved = await c.read(foodRepositoryProvider).getById('id-0');
  check(saved).isNotNull();
  check(saved!.isCustom).isTrue();
  check(saved.kind).equals(FoodKind.product);
  check(saved.category).equals(FoodCategory.custom);
  check(saved.kcalPer100g).equals(205); // unrounded effective (auto)
});
test('save with invalid draft → StateError, nothing written', () async {
  final c = container();
  c.listen(foodDraftControllerProvider(null), (_, _) {});
  await c.read(foodDraftControllerProvider(null).future);
  final ctrl = c.read(foodDraftControllerProvider(null).notifier);
  await check(ctrl.save()).throws<StateError>(); // blank name
  check(await c.read(foodRepositoryProvider).getById('id-0')).isNull();
});
test('edit: loads draft, save keeps id', () async {
  final c = container();
  c.listen(foodDraftControllerProvider('c1'), (_, _) {});
  final draft = await c.read(foodDraftControllerProvider('c1').future);
  check(draft.name).equals('My shake');
  final ctrl = c.read(foodDraftControllerProvider('c1').notifier);
  ctrl.setProtein(35);
  await ctrl.save();
  final saved = await c.read(foodRepositoryProvider).getById('c1');
  check(saved!.protein).equals(35);
  check(saved.kcalPer100g).equals(225); // auto recalc: 35*4+10*4+5*9
});
test('edit a seed food → error state', () async {
  final c = container();
  c.listen(foodDraftControllerProvider('seed-chicken-breast'), (_, _) {});
  await check(
    c.read(foodDraftControllerProvider('seed-chicken-breast').future),
  ).throws<StateError>();
});
test('delete removes from repo; create-mode delete throws', () async {
  final c = container();
  c.listen(foodDraftControllerProvider('c1'), (_, _) {});
  await c.read(foodDraftControllerProvider('c1').future);
  await c.read(foodDraftControllerProvider('c1').notifier).delete();
  check(await c.read(foodRepositoryProvider).getById('c1')).isNull();

  c.listen(foodDraftControllerProvider(null), (_, _) {});
  await c.read(foodDraftControllerProvider(null).future);
  await check(c.read(foodDraftControllerProvider(null).notifier).delete())
      .throws<StateError>();
});
```

- [ ] **2. Run — must fail:**
  `flutter test test/ui/features/foods/view_models/food_draft_controller_test.dart`
- [ ] **3. Implement** both contract files verbatim; `dart run build_runner build`.
- [ ] **4. Run the test file — green.**
- [ ] **5.** `dart format .` → `flutter analyze` → `flutter test`. Report done for review.

**Skills:** `.agents/skills/flutter-riverpod-arch`, `.agents/skills/dart-add-unit-test`, `.agents/skills/dart-migrate-to-checks-package`.

**Acceptance:** the ±10 % and mass rules come from `nutrition.dart`/`validators.dart` only (no reimplementation — grep `* 4` and `0.10` must hit nothing new under `lib/ui/`); all tests green; `food_draft.dart` imports domain only.

**Out of scope:** any widget; routing.

---

## Task 3: Route `/foods` + `FoodLibraryScreen` + `FoodRow`

**Role:** Flutter UI engineer.

**Goal:** the library screen on a real (unlinked) route: search field, grouped list, add button → create form, custom rows → edit form, seed rows inert.

**Files:**
- Modify: `lib/routing/app_router.dart` (new top-level route after the shell route)
- Create: `lib/ui/features/foods/views/food_library_screen.dart`
- Create: `lib/ui/features/foods/views/food_row.dart`
- Create (stub, completed in Task 4): `lib/ui/features/foods/views/food_form_screen.dart`
- Test: `test/ui/features/foods/views/food_library_screen_test.dart` (new)

**Contract:**

```dart
// app_router.dart — append to the top-level routes list, AFTER the
// StatefulShellRoute entry:

      // S07: dev-reachable, not yet linked from the tab bar (permanent nav
      // placement decided later — S15 candidate). S08's add-ingredient
      // picker reuses the library list.
      GoRoute(
        path: '/foods',
        builder: (context, state) => const FoodLibraryScreen(),
        routes: [
          GoRoute(
            path: 'new',
            builder: (context, state) => const FoodFormScreen(foodId: null),
          ),
          GoRoute(
            path: ':id',
            builder: (context, state) =>
                FoodFormScreen(foodId: state.pathParameters['id']!),
          ),
        ],
      ),
```

```dart
// food_form_screen.dart — Task 3 STUB ONLY (Task 4 replaces the body):
class FoodFormScreen extends ConsumerWidget {
  const FoodFormScreen({required this.foodId, super.key});

  /// null = create, id = edit (custom foods only — seed rows never route
  /// here).
  final String? foodId;

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      const Scaffold(body: SizedBox.shrink());
}
```

```dart
// food_row.dart — whole file (public: reused by the gallery and by S08's
// picker):
/// Library list row: name + per-100g summary. Custom foods get a marker
/// pill and (when [onTap] is set) navigate to edit; seed rows are inert
/// until S08's picker gives them a tap meaning.
class FoodRow extends StatelessWidget {
  const FoodRow({required this.food, this.onTap, super.key});

  final Food food;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = /* CrudoColors lookup, intake_card.dart idiom */;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(Spacing.md),
        decoration: BoxDecoration(
          color: colors.surfaceLow,
          borderRadius: Radii.all(Radii.sm),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          food.name,
                          style: CrudoText.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (food.isCustom) ...[
                        const SizedBox(width: Spacing.sm),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: Spacing.sm,
                            vertical: Spacing.xs / 2,
                          ),
                          decoration: BoxDecoration(
                            color: colors.primaryContainer,
                            borderRadius: Radii.all(Radii.full),
                          ),
                          child: Text(
                            'CUSTOM',
                            style: CrudoText.label
                                .copyWith(color: colors.primary),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: Spacing.xs),
                  Text(
                    foodSummary(food),
                    style:
                        CrudoText.body.copyWith(color: colors.onSurfaceMut),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              Icon(
                Icons.chevron_right,
                size: IconSizes.md,
                color: colors.onSurfaceMut,
              ),
          ],
        ),
      ),
    );
  }
}

/// "165 kcal · P31 C0 F3.6" — kcal rounded for display (stored value stays
/// unrounded), grams trimmed of trailing .0.
String foodSummary(Food f) =>
    '${f.kcalPer100g.round()} kcal · '
    'P${gramsText(f.protein)} C${gramsText(f.carbs)} F${gramsText(f.fats)}';

String gramsText(double v) =>
    v == v.roundToDouble() ? '${v.round()}' : '$v';
```

```dart
// food_library_screen.dart — structure (fill layout per tokens; key parts
// verbatim):
class FoodLibraryScreen extends ConsumerWidget {
  const FoodLibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = /* CrudoColors lookup */;
    final groups = ref.watch(foodLibraryProvider);
    final query = ref.watch(foodSearchQueryProvider);
    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Appbar row: optional back (only when pushed), title, add.
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  Spacing.md, Spacing.sm, Spacing.md, 0),
              child: Row(
                children: [
                  if (context.canPop())
                    IconButton(
                      onPressed: context.pop,
                      icon: Icon(Icons.arrow_back,
                          size: IconSizes.lg, color: colors.onSurface),
                    ),
                  const Expanded(
                    child: Text('Food library', style: CrudoText.headline),
                  ),
                  IconButton(
                    key: const ValueKey('add-food'),
                    onPressed: () => context.push('/foods/new'),
                    icon: Icon(Icons.add,
                        size: IconSizes.lg, color: colors.onSurface),
                  ),
                ],
              ),
            ),
            // Search — soft input per design system (filled surfaceLow,
            // Radii.sm, no border), hint 'Search foods'.
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  Spacing.md, Spacing.sm, Spacing.md, 0),
              child: TextField(
                key: const ValueKey('food-search'),
                onChanged: (v) =>
                    ref.read(foodSearchQueryProvider.notifier).setQuery(v),
                decoration: /* soft style + hint */,
              ),
            ),
            Expanded(
              child: groups.when(
                data: (gs) => gs.isEmpty
                    ? Center(
                        child: Text(
                          'No foods match “${query.trim()}”',
                          style: CrudoText.body
                              .copyWith(color: colors.onSurfaceMut),
                        ),
                      )
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(
                            Spacing.md, Spacing.sm, Spacing.md, Spacing.xl),
                        children: [
                          for (final g in gs) ...[
                            Padding(
                              padding: const EdgeInsets.only(
                                  top: Spacing.md, bottom: Spacing.sm),
                              child: Text(g.label.toUpperCase(),
                                  style: CrudoText.label),
                            ),
                            for (final f in g.foods)
                              Padding(
                                padding: const EdgeInsets.only(
                                    bottom: Spacing.sm),
                                child: FoodRow(
                                  food: f,
                                  onTap: f.isCustom
                                      ? () => context.push('/foods/${f.id}')
                                      : null,
                                ),
                              ),
                          ],
                        ],
                      ),
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                  child: Text('Something went wrong', style: CrudoText.body),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

**Steps (TDD):**

- [ ] **1. Failing widget tests** in `food_library_screen_test.dart`. Harness (this file's own — don't import other tests). Reuse the Task 1 food consts (copy them in):

```dart
Widget app(ProviderContainer c, {String initial = '/foods'}) {
  final router = GoRouter(
    initialLocation: initial,
    routes: [
      GoRoute(
        path: '/foods',
        builder: (_, _) => const FoodLibraryScreen(),
        routes: [
          GoRoute(
            path: 'new',
            builder: (_, _) => const FoodFormScreen(foodId: null),
          ),
          GoRoute(
            path: ':id',
            builder: (_, s) =>
                FoodFormScreen(foodId: s.pathParameters['id']!),
          ),
        ],
      ),
    ],
  );
  return UncontrolledProviderScope(
    container: c,
    child: MaterialApp.router(theme: crudoTheme, routerConfig: router),
  );
}
```

  Tests (pump: `await tester.pumpWidget(app(c)); await tester.pumpAndSettle();`):

```dart
testWidgets('renders groups + rows', (t) async {
  // expect: 'MEAT', 'VEGETABLES', 'CUSTOM', 'DISHES' section labels;
  // 'Chicken breast' before 'Turkey'; summary text '156 kcal · P31 C0 F3.6'
});
testWidgets('search narrows the list', (t) async {
  // enterText 'broc' into ValueKey('food-search'), pumpAndSettle:
  // only 'Broccoli' row remains; 'MEAT' header gone
});
testWidgets('no match → empty hint', (t) async {
  // enterText 'zzz' → find.textContaining('No foods match')
});
testWidgets('custom row tap → edit form route; seed row tap inert',
    (t) async {
  // tap 'My shake' → pumpAndSettle → library title gone (stub form shown);
  // restart, tap 'Chicken breast' → still on 'Food library'
});
testWidgets('add button → create form route', (t) async {
  // tap ValueKey('add-food') → library title gone
});
testWidgets('custom rows show CUSTOM pill + chevron, seed rows neither',
    (t) async { /* find.text('CUSTOM') count == custom rows */ });
```

- [ ] **2. Run — fail** (screens undefined):
  `flutter test test/ui/features/foods/views/food_library_screen_test.dart`
- [ ] **3. Implement:** router entry, `FoodRow`, `FoodLibraryScreen`, the `FoodFormScreen` stub.
- [ ] **4. Run the test file — green.**
- [ ] **5.** `dart format .` → `flutter analyze` → `flutter test`. Report done for review.

**Skills:** `.agents/skills/flutter-add-widget-test`, `.agents/skills/flutter-riverpod-arch`, `.agents/skills/flutter-expert` (const discipline; `Semantics` on tappable rows: `button: true`, label = food name).

**Acceptance:** `/foods` route resolves outside the tab shell; list is grouped/searchable/reactive; only custom rows navigate; all dimensions on tokens (no new raw px beyond tokens).

**Out of scope:** the real form body (Task 4); any tab-bar link; pick/grams behavior (S08).

---

## Task 4: `FoodFormScreen` — create / edit / delete

**Role:** Flutter UI engineer.

**Goal:** the prototype form, complete: name, Product|Dish toggle, optional category chips, three macro fields, kcal card with optional override + hard-block mismatch banner, SAVE gating, edit prefill, delete with confirm sheet.

**Files:**
- Replace stub: `lib/ui/features/foods/views/food_form_screen.dart`
- Create: `lib/ui/features/foods/views/macro_field.dart`
- Create: `lib/ui/features/foods/views/kcal_card.dart`
- Modify: `docs/design_system.md` (§5: macro-field accent bar 8×36 — new component size)
- Test: `test/ui/features/foods/views/food_form_screen_test.dart` (new)

**Contract:**

```dart
// macro_field.dart — whole file (public: gallery + this form):
/// Labeled per-100g macro input with a colored accent bar (prototype
/// AddCustomFoodScreen rows). Accent bar 8×36 — recorded in
/// design_system.md §5.
class MacroField extends StatelessWidget {
  const MacroField({
    required this.label,
    required this.accent,
    required this.controller,
    required this.onChanged,
    super.key,
  });

  static const _barWidth = 8.0; // §5: macro accent bar
  static const _barHeight = 36.0;

  final String label; // 'PROTEIN' etc — rendered CrudoText.label
  final Color accent;
  final TextEditingController controller;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = /* CrudoColors lookup */;
    return Row(
      children: [
        Container(
          width: _barWidth,
          height: _barHeight,
          decoration: BoxDecoration(
            color: accent,
            borderRadius: Radii.all(Radii.full),
          ),
        ),
        const SizedBox(width: Spacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: CrudoText.label),
              TextField(
                controller: controller,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                style: CrudoText.headlineSm,
                decoration: /* borderless soft input */,
                onChanged: (s) => onChanged(double.tryParse(s) ?? 0),
              ),
            ],
          ),
        ),
        Text('g',
            style: CrudoText.body.copyWith(color: colors.onSurfaceMut)),
      ],
    );
  }
}
```

```dart
// kcal_card.dart — whole file (public: gallery + this form):
/// "Calculated kcal" card with the optional override input and the
/// mismatch banner (errorText != null → banner shown; SAVE gating happens
/// in the form, not here).
class KcalCard extends StatelessWidget {
  const KcalCard({
    required this.calculated,
    required this.overrideController,
    required this.onOverrideChanged,
    this.errorText,
    super.key,
  });

  final double calculated;
  final TextEditingController overrideController;
  final ValueChanged<String> onOverrideChanged; // raw text; form parses
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final colors = /* CrudoColors lookup */;
    return Container(
      padding: const EdgeInsets.all(Spacing.lg),
      decoration: BoxDecoration(
        color: colors.surfaceLow,
        borderRadius: Radii.all(Radii.md),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('CALCULATED KCAL', style: CrudoText.label),
                Text('${calculated.round()}', style: CrudoText.displaySm),
              ]),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                const Text('OVERRIDE (OPTIONAL)', style: CrudoText.label),
                SizedBox(
                  width: 100, // matches prototype input width; FittedBox ok
                  child: TextField(
                    key: const ValueKey('kcal-override'),
                    controller: overrideController,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    textAlign: TextAlign.right,
                    style: CrudoText.displaySm,
                    decoration: /* borderless, hintText: 'auto' */,
                    onChanged: onOverrideChanged,
                  ),
                ),
              ]),
            ],
          ),
          if (errorText != null) ...[
            const SizedBox(height: Spacing.sm),
            Container(
              key: const ValueKey('kcal-mismatch'),
              padding: const EdgeInsets.all(Spacing.sm),
              decoration: BoxDecoration(
                color: colors.errorSoft,
                borderRadius: Radii.all(Radii.sm),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline,
                      size: IconSizes.md, color: colors.error),
                  const SizedBox(width: Spacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Mismatch',
                            style: CrudoText.body.copyWith(
                                fontWeight: FontWeight.w700,
                                color: colors.error)),
                        Text(errorText!, style: CrudoText.body),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
```

```dart
// food_form_screen.dart — full replacement. Outer widget resolves the
// async draft; the inner stateful form owns TextEditingControllers (so
// provider updates never clobber in-progress typing — controllers are
// created once from the initial draft).
class FoodFormScreen extends ConsumerWidget {
  const FoodFormScreen({required this.foodId, super.key});

  /// null = create, id = edit (custom foods only).
  final String? foodId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(foodDraftControllerProvider(foodId));
    return draft.when(
      // initial is read once by _FoodForm's initState; the form watches the
      // provider itself for live derived values.
      data: (d) => _FoodForm(foodId: foodId, initial: d),
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(
        body: Center(child: Text('Food not found', style: CrudoText.body)),
      ),
    );
  }
}

class _FoodForm extends ConsumerStatefulWidget {
  const _FoodForm({required this.foodId, required this.initial});

  final String? foodId;
  final FoodDraft initial;

  @override
  ConsumerState<_FoodForm> createState() => _FoodFormState();
}

class _FoodFormState extends ConsumerState<_FoodForm> {
  late final _name = TextEditingController(text: widget.initial.name);
  late final _protein =
      TextEditingController(text: gramsText(widget.initial.protein));
  late final _carbs =
      TextEditingController(text: gramsText(widget.initial.carbs));
  late final _fats =
      TextEditingController(text: gramsText(widget.initial.fats));
  late final _override = TextEditingController(
    text: widget.initial.explicitKcal == null
        ? ''
        : gramsText(widget.initial.explicitKcal!),
  );

  @override
  void dispose() {
    for (final c in [_name, _protein, _carbs, _fats, _override]) {
      c.dispose();
    }
    super.dispose();
  }

  FoodDraftController get _ctrl =>
      ref.read(foodDraftControllerProvider(widget.foodId).notifier);

  /// Spec copy, verbatim: percentage variant when macros yield kcal,
  /// zero-rule variant otherwise.
  String? _kcalError(FoodDraft d) {
    if (d.kcalValid) return null;
    if (d.calculated <= 0) return 'Macros are zero — calories must be 0.';
    final pct =
        ((d.explicitKcal! - d.calculated).abs() / d.calculated * 100).round();
    return 'Override differs by $pct% from macros. Max allowed is 10%.';
  }

  Future<void> _save() async {
    await _ctrl.save();
    if (!mounted) return;
    context.pop();
  }

  Future<void> _confirmDelete(String name) async {
    final confirmed = await showCrudoSheet<bool>(
          context,
          builder: (sheetCtx) => SheetScaffold(
            title: 'Delete food?',
            body: Text(
              '“$name” will be removed from your library. '
              'Logged days keep their copies.',
              style: CrudoText.body,
            ),
            cta: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                PrimaryCta(
                  label: 'Delete',
                  onPressed: () => Navigator.of(sheetCtx).pop(true),
                ),
                const SizedBox(height: Spacing.sm),
                TextButton(
                  key: const ValueKey('cancel-delete'),
                  onPressed: () => Navigator.of(sheetCtx).pop(false),
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ),
        ) ??
        false;
    if (!confirmed || !mounted) return;
    await _ctrl.delete();
    if (!mounted) return;
    showCrudoToast(context, 'Food deleted');
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final colors = /* CrudoColors lookup */;
    final draft = ref
        .watch(foodDraftControllerProvider(widget.foodId))
        .requireValue;
    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Header: back · title · SAVE (disabled-dim unless canSave).
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  Spacing.md, Spacing.sm, Spacing.md, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: context.pop,
                    icon: Icon(Icons.arrow_back,
                        size: IconSizes.lg, color: colors.onSurface),
                  ),
                  Expanded(
                    child: Text(
                      widget.foodId == null ? 'Custom food' : 'Edit food',
                      style: CrudoText.headlineSm,
                    ),
                  ),
                  Opacity(
                    opacity: draft.canSave ? 1 : Opacities.disabled,
                    child: TextButton(
                      key: const ValueKey('save-food'),
                      onPressed: draft.canSave ? _save : null,
                      child: Text('SAVE',
                          style: CrudoText.labelMd
                              .copyWith(color: colors.primary)),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                    Spacing.xl, Spacing.sm, Spacing.xl, Spacing.xl),
                children: [
                  // NAME — large soft input, hint 'e.g. My protein blend';
                  // onChanged: _ctrl.setName
                  // (TextField key: ValueKey('food-name'),
                  //  style: CrudoText.headline)

                  // TYPE — Product|Dish toggle (S05 mandate; prototype
                  // lacks it). Two Pills:
                  // Pill(label: 'Product',
                  //      selected: draft.kind == FoodKind.product,
                  //      onTap: () => _ctrl.setKind(FoodKind.product)),
                  // Pill(label: 'Dish', ... FoodKind.dish ...)

                  // CATEGORY (label row with 'OPTIONAL' trailing) — Wrap of
                  // Pills for the 7 non-custom categories
                  // (foodCategoryLabels minus FoodCategory.custom):
                  // selected: draft.category == cat,
                  // onTap: () => _ctrl.setCategory(
                  //     draft.category == cat ? null : cat)  // tap-again clears

                  // MACROS PER 100G · ALL REQUIRED — three MacroFields:
                  // MacroField(key: ValueKey('macro-protein'),
                  //   label: 'PROTEIN', accent: colors.primary,
                  //   controller: _protein, onChanged: _ctrl.setProtein),
                  // ('CARBS', colors.gold, _carbs, setCarbs),
                  // ('FATS', colors.bronze, _fats, setFats)

                  // KCAL CARD:
                  KcalCard(
                    calculated: draft.calculated,
                    overrideController: _override,
                    onOverrideChanged: (s) => _ctrl.setExplicitKcal(
                      s.trim().isEmpty ? null : double.tryParse(s),
                    ),
                    errorText: _kcalError(draft),
                  ),

                  // DELETE (edit mode only):
                  if (widget.foodId != null) ...[
                    const SizedBox(height: Spacing.xl),
                    TextButton(
                      key: const ValueKey('delete-food'),
                      onPressed: () => _confirmDelete(draft.name),
                      child: Text('Delete food',
                          style: CrudoText.body
                              .copyWith(color: colors.error)),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

Behavior notes (spec-locked, do not soften):
- Out-of-range override → banner + SAVE disabled (hard block). Clearing the override field → `setExplicitKcal(null)` → auto kcal, banner gone.
- Unparseable override text (`double.tryParse` null) → treated as cleared (auto).
- All-zero macros save fine with empty override (kcal 0); a non-zero override then shows the zero-rule banner.
- Stored kcal is the unrounded effective value; only display rounds.

**Steps (TDD):**

- [ ] **1. Failing widget tests** in `food_form_screen_test.dart`. Same `app(...)` harness as Task 3 (copy it in; use `initial: '/foods/new'` or `'/foods/c1'`), same food consts + the Task 2 `_jam` fixture:

```dart
testWidgets('create: name+macros → calculated kcal shown, save persists',
    (t) async {
  // enter 'My bar' into food-name; '30'/'10'/'5' into macro fields;
  // expect find.text('205') (calculated); tap save-food; pumpAndSettle;
  // back on 'Food library'; repo: getAll() contains isCustom food named
  // 'My bar' with kcalPer100g == 205, category == FoodCategory.custom.
});
testWidgets('SAVE disabled on blank name; enabled once valid', (t) async {
  // initial: TextButton(save-food).onPressed == null;
  // enter name + one macro → onPressed != null.
});
testWidgets('override out of ±10% → banner + SAVE blocked; clear reverts',
    (t) async {
  // name 'X', macros 20/30/10 (calc 290); override '320' →
  // find.byKey(kcal-mismatch) + textContaining('Override differs by 10%');
  // save disabled. Override '319' → banner gone, save enabled.
  // Clear override ('') → banner gone, find.text('290') still shown.
});
testWidgets('all-zero macros: empty override saves kcal 0; nonzero blocked',
    (t) async {
  // name 'Water', macros 0 → save enabled → saved kcalPer100g == 0.
  // Variant: override '5' → find.text('Macros are zero — calories must be 0.')
  //   + save disabled.
});
testWidgets('kind toggle + category chip select/clear persist', (t) async {
  // tap 'Dish' pill, tap 'Meat' chip → save → kind == dish, category == meat.
  // Variant: tap 'Meat' twice → category == custom.
});
testWidgets('edit: prefilled, save keeps id', (t) async {
  // initial '/foods/c1': name field text 'My shake', protein '30',
  // override field EMPTY (stored == calc → auto). setProtein 35 → save →
  // repo getById('c1')!.protein == 35.
});
testWidgets('edit prefills an accepted override', (t) async {
  // initial '/foods/c9' (_jam): override field text '210', calc shows '200',
  // no banner (210 within ±10% of 200).
});
testWidgets('delete: confirm sheet → removed + toast; cancel keeps',
    (t) async {
  // initial '/foods/c1': tap delete-food → find.text('Delete food?');
  // tap 'Delete' → pumpAndSettle → repo getById('c1') == null,
  // find.text('Food deleted'). Variant: cancel-delete → food still there.
});
```

- [ ] **2. Run — fail** (stub form has no body):
  `flutter test test/ui/features/foods/views/food_form_screen_test.dart`
- [ ] **3. Implement** `MacroField`, `KcalCard`, the full `FoodFormScreen`; add the design_system.md §5 row (`macro accent bar — 8×36, MacroField`).
- [ ] **4. Run `flutter test test/ui/features/foods/` — green.**
- [ ] **5.** `dart format .` → `flutter analyze` → `flutter test`. Report done for review.

**Skills:** `.agents/skills/flutter-add-widget-test`, `.agents/skills/flutter-expert` (Semantics: SAVE/`delete-food` buttons labeled; TextField `decoration` hints double as a11y labels), `.agents/skills/flutter-build-responsive-layout`.

**Acceptance:** every spec validation-matrix row exercised by a test; ±10 % math reaches the UI only through `FoodDraft` (no kcal arithmetic in widgets beyond display rounding + the banner pct); composition matches `meal.jsx` AddCustomFoodScreen + the added toggle; dimensions on tokens.

**Out of scope:** add-ingredient picker/CTA (S08); blocking delete on references (S09); name-uniqueness.

---

## Task 5: Gallery entries + final check

**Role:** Flutter UI engineer.

**Goal:** dev-verifiable visuals: the stateless S07 pieces join the widget gallery (the screens themselves are provider-driven — same exclusion as MealSheet, see the comment at the bottom of `previews.dart`).

**Files:**
- Modify: `lib/previews.dart`

**Contract:** append to the `_PreviewHome` ListView, before the closing MealSheet comment — follow the file's exact section pattern (headline → `Spacing.md` gap → variants → `Spacing.lg` gap):

```dart
const Text('FoodRow', style: CrudoText.headline),
const SizedBox(height: Spacing.md),
const FoodRow(
  food: Food(
    id: 'preview-chicken', name: 'Chicken breast',
    category: FoodCategory.meat,
    protein: 31, carbs: 0, fats: 3.6, kcalPer100g: 156.4,
  ),
),
const SizedBox(height: Spacing.sm),
FoodRow(
  food: const Food(
    id: 'preview-shake', name: 'My shake',
    category: FoodCategory.custom,
    protein: 30, carbs: 10, fats: 5, kcalPer100g: 205, isCustom: true,
  ),
  onTap: _noop,
),
const SizedBox(height: Spacing.lg),

const Text('MacroField', style: CrudoText.headline),
const SizedBox(height: Spacing.md),
MacroField(
  label: 'PROTEIN',
  accent: CrudoColors.light.primary,
  controller: TextEditingController(text: '31'),
  onChanged: (_) {},
),
const SizedBox(height: Spacing.lg),

const Text('KcalCard', style: CrudoText.headline),
const SizedBox(height: Spacing.md),
KcalCard(
  calculated: 290,
  overrideController: TextEditingController(),
  onOverrideChanged: (_) {},
),
const SizedBox(height: Spacing.sm),
KcalCard(
  calculated: 290,
  overrideController: TextEditingController(text: '350'),
  onOverrideChanged: (_) {},
  errorText: 'Override differs by 21% from macros. Max allowed is 10%.',
),
const SizedBox(height: Spacing.lg),

// FoodLibraryScreen / FoodFormScreen are provider-driven — verified via
// the /foods route (dev) + widget tests, not from this static gallery.
```

(Inline `TextEditingController`s never disposed — acceptable in this throwaway preview app, matching its existing looseness.)

**Steps:**

- [ ] **1. Add** the gallery sections + imports (`food_row.dart`, `macro_field.dart`, `kcal_card.dart`, `food/food.dart`).
- [ ] **2. Visual sanity:** `flutter run -t lib/previews.dart` (any device/simulator) — sections render, no overflow.
- [ ] **3. Final check:**
  - `dart format .` leaves nothing → `flutter analyze` clean → `flutter test` fully green (incl. `test/architecture/dependency_rules_test.dart`).
  - Walk the spec's Acceptance list (`docs/specs/2026-06-06-s07-custom-food.md`) on-device: temporarily change `initialLocation` in `app_router.dart` to `'/foods'`, run `flutter run --flavor dev -t lib/main_development.dart --dart-define-from-file=config/dev.json`, exercise browse/search/create/edit/delete end-to-end, then REVERT `initialLocation` to `'/today'` before reporting.
- [ ] **4. Report done for review** — no commits.

**Skills:** `.agents/skills/flutter-add-widget-preview`.

**Acceptance:** gallery renders the three new pieces; full suite green; `initialLocation` back on `/today`; working tree contains only the S07 files from Tasks 1–5.
