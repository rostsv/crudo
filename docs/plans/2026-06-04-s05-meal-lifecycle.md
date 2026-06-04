# S05 — Meal Lifecycle Engine Implementation Plan

> **Workers:** execute tasks **in order**, one at a time, on the main working tree. Read `AGENTS.md` + the skills each task names before coding. **Do not commit** — finish each task at "all green", write the completion report at the end (`.opencode/handoff/2026-06-04-s05-meal-lifecycle.report.md`). Opus reviews and integrates.

**Goal:** the pure domain engine for meal lifecycle — instance-tree model refactor (`ScheduledMeal`/`MealSnapshot`/`MealItem`/`FoodSnapshot`), `Product`→`Food` library rename, status derivation, `Day` ops, snooze bounds, materialization, kcal math — fully test-locked, zero UI.

**Spec:** `docs/specs/2026-06-04-s05-meal-lifecycle.md` (contract — wins on conflict) · **Design:** `docs/design/domain/2026-06-03-s05-meal-lifecycle-engine.md` (rationale, edge ledger).

**Architecture:** pure Dart in `lib/domain/` (no Flutter/Riverpod/uuid imports — arch test enforces). freezed models; ops as methods on the `Day` aggregate; derivation in `domain/services/meal_status.dart` (imports no `Day` — avoids an import cycle); materialization/kcal/predicates in `domain/services/meal_lifecycle.dart`. All functions take explicit `now`/`today` — never read the clock.

**Conventions that bind every task:**
- Field name is **`fats`** (codebase idiom), not `fat`.
- Stamps (`skippedAt`, `snoozedUntil`, `checkedAt`, `lockedAt`) are **UTC instants**; `Day.date`/`today` are **UTC-encoded local-date labels** (`DateTime.utc(y,m,d)`).
- Tests: `package:test` / `flutter_test` + **`package:checks`** (never `matcher`).
- After any `@freezed` model change: `dart run build_runner build` (no `--delete-conflicting-outputs` flag — build_runner 2.15).
- Required command order per task: `dart format .` → `flutter analyze` → `flutter test`. All three clean/green before the task counts as done.

---

## Task 1: Library rename — `Food` (domain layer) [implement]

**Goal:** `Product` becomes `Food` (folder `domain/food/`), gains `kind: FoodKind`, swaps `kcalOverride?` for always-set `kcalPer100g`. `ProductRef` → `FoodRef`. Nutrition service + validators follow. Template tree (`MealTemplate`, `PlanSlot`, `PlanTemplate`) keeps shape — only the ref type renames.

**Files:**
- Create: `lib/domain/food/food.dart`, `lib/domain/food/food_ref.dart`
- Delete: `lib/domain/product/product.dart`, `lib/domain/product/product_ref.dart` (+ their `.freezed.dart`)
- Modify: `lib/domain/shared/enums.dart`, `lib/domain/meal/meal_template.dart`, `lib/domain/services/nutrition.dart`, `lib/domain/validation/validators.dart`, `lib/domain/repositories/product_repository.dart` → rename file to `food_repository.dart`
- Tests: `test/domain/product/product_test.dart` → move to `test/domain/food/food_test.dart`; `test/domain/services/nutrition_test.dart`, `test/domain/validation/validators_test.dart`, `test/domain/meal/meal_test.dart`, `test/domain/plan/plan_test.dart` (rename ripple)

**Skills:** `.agents/skills/dart-add-unit-test`, `.agents/skills/dart-migrate-to-checks-package`.

- [ ] **Step 1.1 — enums:** in `lib/domain/shared/enums.dart` rename `ProductCategory` → `FoodCategory` (same values) and add below it:

```dart
/// Food library kind — display/filter only (library "Dishes" group, meal-row
/// icon). The engine never reads it. Seed foods are all `product`.
enum FoodKind { product, dish }
```

Leave `MealStatus`, `MealTag`, `Goal`, `Unit`, `ReminderMode`, `DayState` untouched (`DayState` stays — S12 derives it; it just stops being a `Day` field in Task 3).

- [ ] **Step 1.2 — `lib/domain/food/food.dart`** (replaces `product.dart`):

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

import '../shared/enums.dart';

part 'food.freezed.dart';

/// A food library item (template tree). Macros + kcal are per 100 g.
/// `kcalPer100g` is a plain stored value: defaulted to the Atwater formula at
/// input time, or user-entered and validated within ±10% (S07 owns that flow).
/// There is no override field — the accepted value simply IS the kcal.
/// `kind` is display/filter only; `id` is an app-generated uuid v7
/// (seed ids are readable strings). Seed foods have `isCustom == false`.
@freezed
abstract class Food with _$Food {
  const Food._();

  @Assert('protein >= 0', 'protein must be >= 0')
  @Assert('carbs >= 0', 'carbs must be >= 0')
  @Assert('fats >= 0', 'fats must be >= 0')
  @Assert('kcalPer100g >= 0', 'kcalPer100g must be >= 0')
  const factory Food({
    required String id,
    required String name,
    @Default(FoodKind.product) FoodKind kind,
    required FoodCategory category,
    required double protein,
    required double carbs,
    required double fats,
    required double kcalPer100g,
    @Default(false) bool isCustom,
  }) = _Food;
}
```

- [ ] **Step 1.3 — `lib/domain/food/food_ref.dart`** (replaces `product_ref.dart`):

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

import '../shared/grams.dart';

part 'food_ref.freezed.dart';

/// A food reference + amount inside a [MealTemplate] (template tree).
/// Macros are derived via the nutrition service, never stored.
@freezed
abstract class FoodRef with _$FoodRef {
  const FoodRef._();

  const factory FoodRef({required String foodId, required Grams grams}) =
      _FoodRef;
}
```

- [ ] **Step 1.4 — `lib/domain/meal/meal_template.dart`:** swap the import and list type; keep field name `products` → rename to `items` is **NOT** done here — template field renames to `foods`? **No.** Keep the template field named `products`? **Decision: rename to `foods`** for consistency with the new type:

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

import '../food/food_ref.dart';
import '../shared/enums.dart';

part 'meal_template.freezed.dart';

/// A reusable meal recipe (template tree): food refs + tags, deliberately
/// time-free — WHEN it is eaten belongs to the plan ([PlanSlot.time]).
@freezed
abstract class MealTemplate with _$MealTemplate {
  const MealTemplate._();

  const factory MealTemplate({
    required String id,
    required String name,
    @Default(<MealTag>[]) List<MealTag> tags,
    @Default(<FoodRef>[]) List<FoodRef> foods,
  }) = _MealTemplate;
}
```

- [ ] **Step 1.5 — `lib/domain/services/nutrition.dart`:** library-side only in this task (instance-side fns move/change in Task 3). Replace the whole file with:

```dart
import '../food/food.dart';
import '../meal/meal_template.dart';
import '../shared/macros.dart';

/// Nutrition rules (domain service — pure functions). Single source of truth:
/// totals are always recomputed, never stored (architecture §6). The Atwater
/// formula lives at INPUT time: it defaults a food's kcalPer100g and bounds
/// an explicit user entry (±10%, S07 form flow).

/// Atwater factors: protein 4, carbs 4, fats 9 kcal per gram.
double calculatedKcal({
  required double protein,
  required double carbs,
  required double fats,
}) => protein * 4 + carbs * 4 + fats * 9;

/// An explicit kcal entry is accepted only within ±[tolerance] (default 10%)
/// of the calculated value. Non-positive calculated → only 0 is valid.
/// Used by the S07 add/edit-food form before storing Food.kcalPer100g.
bool isExplicitKcalValid({
  required double calculated,
  required double explicit,
  double tolerance = 0.10,
}) {
  if (calculated <= 0) return explicit == 0;
  return (explicit - calculated).abs() <= calculated * tolerance;
}

/// Macros of [grams] of a library [Food] = per-100g values × grams / 100.
Macros macrosForFood(Food food, double grams) {
  final factor = grams / 100.0;
  return Macros(
    protein: food.protein * factor,
    carbs: food.carbs * factor,
    fats: food.fats * factor,
    kcal: food.kcalPer100g * factor,
  );
}

/// Preview macros of a meal TEMPLATE — needs the food library to resolve
/// refs. An unresolved foodId is skipped (libraries are soft-deleted, S19).
Macros mealTemplateMacros(MealTemplate template, Map<String, Food> foodsById) {
  var total = const Macros();
  for (final ref in template.foods) {
    final food = foodsById[ref.foodId];
    if (food == null) continue;
    total = total + macrosForFood(food, ref.grams.value);
  }
  return total;
}
```

(`macrosForProduct`, `mealMacros`, `consumedMacros`, `effectiveKcalPer100g` are deleted — instance-side replacements arrive in Task 3; `isKcalOverrideValid` is renamed to `isExplicitKcalValid`. The old `Meal`/`MealProduct` imports go away — that breaks `validators.dart`, fixed next step, and `meal.dart`/`meal_product.dart`, which Task 3 replaces; to keep THIS task green, Step 1.7 temporarily patches them.)

- [ ] **Step 1.6 — `lib/domain/validation/validators.dart`:** update the food rules; keep meal/plan/day/profile rules compiling against current types:
  - Replace `_macroRules` (kcalOverride block goes away) and the `Product`/`MealProduct` extensions:

```dart
List<ValidationIssue> _macroRules({
  required String name,
  required double protein,
  required double carbs,
  required double fats,
}) {
  final issues = <ValidationIssue>[];
  if (name.trim().isEmpty) {
    issues.add(
      const ValidationIssue(
        field: 'name',
        code: ValidationCode.blankName,
        message: 'Name must not be blank',
      ),
    );
  }
  if (protein + carbs + fats > _macroMassLimit) {
    issues.add(
      const ValidationIssue(
        field: 'macros',
        code: ValidationCode.macroMassExceeded,
        message: 'protein + carbs + fats cannot exceed 100 g per 100 g',
      ),
    );
  }
  return issues;
}

extension FoodValidation on Food {
  List<ValidationIssue> validate() =>
      _macroRules(name: name, protein: protein, carbs: carbs, fats: fats);
}
```

  - Imports: `../product/product.dart` → `../food/food.dart`.
  - `MealTemplateValidation`: field `products` → `foods` (`if (foods.isEmpty)`, field string `'foods'`).
  - `MealProductValidation` extension: **delete** (type dies in Task 3; until then nothing validates it).
  - Keep `MealValidation`, `PlanSlotValidation`, `PlanTemplateValidation`, `DayValidation`, `PrefsValidation`, `UserProfileValidation` as-is (they compile unchanged).
  - If `ValidationCode.kcalOverrideOutOfRange` is now unreferenced, leave the enum value in place (S07 will reuse it for the explicit-entry form rule) with a `// reused by S07 form validation` comment in `validation_issue.dart`.

- [ ] **Step 1.7 — temporary instance-tree patch** (keeps Task 1 green; Task 3 replaces these files): in `lib/domain/meal/meal_product.dart` change `ProductCategory` → `FoodCategory` (import stays `../shared/enums.dart`; field `kcalOverride` stays for now). In `lib/domain/repositories/product_repository.dart`: rename file to `food_repository.dart`, content:

```dart
import '../food/food.dart';

/// Food library: seed + user customs; deleted items excluded from queries.
abstract class FoodRepository {
  Stream<List<Food>> watchAll();
  Future<List<Food>> getAll();
  Future<Food?> getById(String id);
  Future<void> save(Food food);
  Future<void> delete(String id);
}
```

(Data-layer fallout compiles in Task 2 — run only `flutter test test/domain` at this step if the full suite is red on data files; full green is required at end of Task 2 instead. State this in the report if used.)

- [ ] **Step 1.8 — codegen:** `dart run build_runner build`. Delete orphaned `lib/domain/product/` generated files.

- [ ] **Step 1.9 — domain tests:** move/adjust per rename map: `Product(`→`Food(`, `category: ProductCategory.`→`category: FoodCategory.`, `fats:` unchanged, every `kcalOverride:` argument in Food constructions → `kcalPer100g:` with the value the test expects effective (for tests that asserted override behavior, the expectation becomes: stored value wins, no formula at read). Files: `test/domain/food/food_test.dart` (moved), `nutrition_test.dart` (drop `effectiveKcalPer100g`/`macrosForProduct`/`mealMacros`/`consumedMacros` tests — Task 3 re-adds instance-side; add the two below), `validators_test.dart`, `meal_test.dart`, `plan_test.dart`. New nutrition tests:

```dart
import 'package:checks/checks.dart';
import 'package:crudo/domain/food/food.dart';
import 'package:crudo/domain/services/nutrition.dart';
import 'package:crudo/domain/shared/enums.dart';
import 'package:test/test.dart';

void main() {
  group('macrosForFood', () {
    final egg = Food(
      id: 'f1',
      name: 'Egg',
      category: FoodCategory.eggs,
      protein: 13,
      carbs: 1.1,
      fats: 11,
      kcalPer100g: 155,
    );

    test('scales per-100g values by grams/100', () {
      final m = macrosForFood(egg, 60);
      check(m.protein).isCloseTo(7.8, 1e-9);
      check(m.kcal).isCloseTo(93.0, 1e-9);
    });
  });

  group('isExplicitKcalValid', () {
    test('accepts within ±10% of formula', () {
      final calc = calculatedKcal(protein: 13, carbs: 1.1, fats: 11);
      check(isExplicitKcalValid(calculated: calc, explicit: calc * 1.09))
          .isTrue();
      check(isExplicitKcalValid(calculated: calc, explicit: calc * 1.11))
          .isFalse();
    });
  });
}
```

- [ ] **Step 1.10 — verify:** `dart format .` → `flutter analyze` (domain clean; data-layer errors allowed ONLY if Step 1.7 note applies) → `flutter test test/domain`. Expected: green.

**Acceptance:** `lib/domain/` has no `Product`/`ProductRef`/`ProductCategory`/`kcalOverride` identifiers left (grep clean, except the parked `ValidationCode` value); `test/domain` green.
**Out of scope:** data layer, DI, instance tree, any engine fn.

---

## Task 2: Data layer + DI + architecture ripple [build]

**Goal:** data layer serves `Food`. Seed asset stays byte-identical — the mapper supplies `kind: FoodKind.product` and computes `kcalPer100g` (seed has no kcal field).

**Files:**
- Rename+modify: `lib/data/dto/product_dto.dart`→`food_dto.dart` (class `FoodDto`), `lib/data/mappers/product_mapper.dart`→`food_mapper.dart` (class `FoodMapper`), `lib/data/repositories/in_memory_product_repository.dart`→`in_memory_food_repository.dart`
- Modify: `lib/data/services/seed_service.dart`, `lib/config/di.dart`, `test/architecture/dependency_rules_test.dart` (only if it names `product` paths), `test/data/repositories_test.dart`, `test/data/seed_test.dart`, `test/config/di_test.dart`
- Do **not** touch: `assets/seed/products.json` (path + content keep — it's wire data, not domain naming)

**Skills:** `.agents/skills/dart-add-unit-test`, `.agents/skills/dart-migrate-to-checks-package`.

- [ ] **Step 2.1 — `lib/data/dto/food_dto.dart`:** rename class only (`ProductDto`→`FoodDto`), fields unchanged (id/name/category/protein/carbs/fats — wire shape mirrors the asset).

- [ ] **Step 2.2 — `lib/data/mappers/food_mapper.dart`:**

```dart
import 'package:crudo/domain/food/food.dart';
import 'package:crudo/domain/services/nutrition.dart';
import 'package:crudo/domain/shared/enums.dart';

import '../dto/food_dto.dart';

/// DTO -> domain. Seed foods are never custom, all kind `product`, and carry
/// no explicit kcal — kcalPer100g defaults to the Atwater formula here
/// (the same input-time rule the S07 form applies).
abstract final class FoodMapper {
  static Food toDomain(FoodDto dto) => Food(
    id: dto.id,
    name: dto.name,
    category: FoodCategory.values.byName(dto.category),
    protein: dto.protein,
    carbs: dto.carbs,
    fats: dto.fats,
    kcalPer100g: calculatedKcal(
      protein: dto.protein,
      carbs: dto.carbs,
      fats: dto.fats,
    ),
  );
}
```

- [ ] **Step 2.3 — `in_memory_food_repository.dart`:** class `InMemoryFoodRepository extends InMemoryCrud<Food> implements FoodRepository`, constructor param `seed` unchanged. **Step 2.4 — `seed_service.dart`:** types `Food`/`FoodDto`/`FoodMapper`; asset path unchanged. **Step 2.5 — `di.dart`:** provider rename `productRepositoryProvider`→`foodRepositoryProvider`, types swap; everything else untouched.

- [ ] **Step 2.6 — tests:** apply rename map across `test/data/*` + `test/config/di_test.dart` (same map as Step 1.9 + `InMemoryProductRepository`→`InMemoryFoodRepository`, provider name). In `seed_test.dart` add one mapper assertion:

```dart
test('seed kcalPer100g is formula-derived and kind is product', () async {
  final foods = await SeedService().loadProducts();
  final chicken = foods.singleWhere((f) => f.id == 'seed-chicken-breast');
  check(chicken.kind).equals(FoodKind.product);
  check(chicken.kcalPer100g)
      .isCloseTo(31.0 * 4 + 0.0 * 4 + 3.6 * 9, 1e-9); // 156.4
});
```

(If `SeedService.loadProducts` reads better renamed to `loadFoods`, rename it and its call sites in `di.dart` + tests — keep the asset path.)

- [ ] **Step 2.7 — arch test:** confirm `test/architecture/dependency_rules_test.dart` allowlists still hold (no path renames needed unless they reference `domain/product`). Run it.

- [ ] **Step 2.8 — verify:** `dart format .` → `flutter analyze` (whole repo clean now) → `flutter test` (whole suite green).

**Acceptance:** repo-wide grep for `Product` finds only: the seed asset filename/path, `ValidationCode.kcalOverrideOutOfRange` parked value, historical docs. Full suite green.
**Out of scope:** instance tree, engine.

---

## Task 3: Instance tree — `FoodSnapshot`, `MealItem`, `MealSnapshot`, `ScheduledMeal`, `Day` refactor [implement]

**Goal:** the final model ladder (spec "Model refactor"). Old `Meal`/`MealProduct` die. `Day` gains `thresholdUsed`/`lockedAt`, loses `state`, holds `List<ScheduledMeal>`.

**Files:**
- Create: `lib/domain/meal/food_snapshot.dart`, `lib/domain/meal/meal_item.dart`, `lib/domain/meal/meal_snapshot.dart`, `lib/domain/day/scheduled_meal.dart`
- Delete: `lib/domain/meal/meal.dart`, `lib/domain/meal/meal_product.dart` (+ generated)
- Modify: `lib/domain/day/day.dart`, `lib/domain/validation/validators.dart`, `lib/domain/services/nutrition.dart` (instance fns), `lib/data/repositories/in_memory_day_repository.dart` (compiles unchanged — verify only)
- Tests: rewrite `test/domain/meal/meal_test.dart`, `test/domain/day/day_test.dart`; extend `test/domain/services/nutrition_test.dart`, `test/domain/validation/validators_test.dart`

**Skills:** `.agents/skills/dart-add-unit-test`, `.agents/skills/dart-migrate-to-checks-package`.

- [ ] **Step 3.1 — `lib/domain/meal/food_snapshot.dart`:**

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

import '../food/food.dart';
import '../shared/enums.dart';
import '../shared/grams.dart';

part 'food_snapshot.freezed.dart';

/// A library food fixed at a weight (instance tree) — PURE VALUE, state-free.
/// Macros + kcal are ABSOLUTES for [grams], computed once at creation; the
/// per-100g source is deliberately not carried (derivable as abs/grams×100;
/// grams edits scale linearly). `sourceFoodId` is a weak back-ref only —
/// later library edits/deletes never alter this snapshot (architecture §8).
@freezed
abstract class FoodSnapshot with _$FoodSnapshot {
  const FoodSnapshot._();

  @Assert('protein >= 0', 'protein must be >= 0')
  @Assert('carbs >= 0', 'carbs must be >= 0')
  @Assert('fats >= 0', 'fats must be >= 0')
  @Assert('kcal >= 0', 'kcal must be >= 0')
  const factory FoodSnapshot({
    String? sourceFoodId,
    required String name,
    @Default(FoodKind.product) FoodKind kind,
    required FoodCategory category,
    required Grams grams,
    required double protein,
    required double carbs,
    required double fats,
    required double kcal,
  }) = _FoodSnapshot;

  /// The one creation door: resolve a library food at a weight, baking the
  /// absolutes in (per-100g × grams / 100).
  factory FoodSnapshot.from(Food food, Grams grams) {
    final factor = grams.value / 100.0;
    return FoodSnapshot(
      sourceFoodId: food.id,
      name: food.name,
      kind: food.kind,
      category: food.category,
      grams: grams,
      protein: food.protein * factor,
      carbs: food.carbs * factor,
      fats: food.fats * factor,
      kcal: food.kcalPer100g * factor,
    );
  }
}
```

- [ ] **Step 3.2 — `lib/domain/meal/meal_item.dart`:**

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

import 'food_snapshot.dart';

part 'meal_item.freezed.dart';

/// Consumption wrapper around a pure [FoodSnapshot] (instance tree).
/// `checkedAt` null = not eaten; set = eaten at that UTC instant. The mark
/// travels with its item — list order is display-only, never identity.
/// NOTE: non-const factory — the @Assert needs DateTime property access,
/// which Dart forbids in const-constructor asserts (same as Day).
@freezed
abstract class MealItem with _$MealItem {
  const MealItem._();

  @Assert('checkedAt == null || checkedAt.isUtc', 'checkedAt must be UTC')
  factory MealItem({DateTime? checkedAt, required FoodSnapshot food}) =
      _MealItem;

  bool get checked => checkedAt != null;
}
```

- [ ] **Step 3.3 — `lib/domain/meal/meal_snapshot.dart`:**

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

import '../shared/enums.dart';
import 'meal_item.dart';

part 'meal_snapshot.freezed.dart';

/// The day's content record for one scheduled meal (instance tree): a
/// detached snapshot seeded from a MealTemplate, freely divergent afterwards
/// (swap/edits never touch templates). Holds WHAT is (to be) eaten + the
/// per-item consumption state; WHEN/skip/snooze live on ScheduledMeal.
@freezed
abstract class MealSnapshot with _$MealSnapshot {
  const MealSnapshot._();

  const factory MealSnapshot({
    String? sourceMealTemplateId,
    required String name,
    @Default(<MealTag>[]) List<MealTag> tags,
    @Default(<MealItem>[]) List<MealItem> items,
  }) = _MealSnapshot;

  bool get anyChecked => items.any((i) => i.checked);
  bool get allChecked => items.isNotEmpty && items.every((i) => i.checked);
}
```

- [ ] **Step 3.4 — `lib/domain/day/scheduled_meal.dart`:**

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

import '../meal/meal_snapshot.dart';
import '../shared/meal_time.dart';

part 'scheduled_meal.freezed.dart';

/// Scheduling wrapper (instance tree, entity inside the Day aggregate):
/// slot-stable `id` (uuid v7 — notifications key off it) + `time` + timing
/// acts. Swapping content replaces `meal` only — `id` and `time` survive.
/// `skippedAt`/`snoozedUntil` persist forever (analytics); derivation ignores
/// them once anything is checked. Status is DERIVED (meal_status.dart),
/// deliberately not a field. Non-const factory: asserts need .isUtc.
@freezed
abstract class ScheduledMeal with _$ScheduledMeal {
  const ScheduledMeal._();

  @Assert('id != ""', 'id must not be empty')
  @Assert('skippedAt == null || skippedAt.isUtc', 'skippedAt must be UTC')
  @Assert(
    'snoozedUntil == null || snoozedUntil.isUtc',
    'snoozedUntil must be UTC',
  )
  factory ScheduledMeal({
    required String id,
    required MealTime time,
    DateTime? skippedAt,
    DateTime? snoozedUntil,
    required MealSnapshot meal,
  }) = _ScheduledMeal;
}
```

- [ ] **Step 3.5 — `lib/domain/day/day.dart`:** replace fields + asserts (ops arrive in Task 5 — this step is model only):

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

import 'scheduled_meal.dart';

part 'day.freezed.dart';

/// A materialized day (instance tree, aggregate root): the user's local
/// calendar date + that day's scheduled meals. Identity = `date` (no domain
/// id; storage may add a surrogate key — S19 concern). ONE type serves
/// today/future/history — "locked" is DERIVED from the date (past = locked,
/// meal_lifecycle.dart). The frozen trio `adherence`/`thresholdUsed`/
/// `lockedAt` is null while the day is open and written exactly once by S12
/// at midnight-lock; storing the threshold USED that day means later settings
/// changes never recolor history (DayState derives: S12).
/// `date` is a date LABEL: the local calendar date encoded DateTime.utc(y,m,d).
@freezed
abstract class Day with _$Day {
  const Day._();

  @Assert('date.isUtc', 'date must be the UTC-encoded local-date label')
  @Assert(
    'date.hour == 0 && date.minute == 0 && date.second == 0 && '
        'date.millisecond == 0 && date.microsecond == 0',
    'date must be midnight-normalized',
  )
  @Assert(
    '(adherence == null) == (thresholdUsed == null) && '
        '(adherence == null) == (lockedAt == null)',
    'adherence, thresholdUsed and lockedAt are frozen together at lock',
  )
  @Assert(
    'adherence == null || (adherence >= 0 && adherence <= 1)',
    'adherence must be within [0,1]',
  )
  @Assert('lockedAt == null || lockedAt.isUtc', 'lockedAt must be UTC')
  factory Day({
    required DateTime date,
    String? sourcePlanId,
    String? planName,
    @Default(<ScheduledMeal>[]) List<ScheduledMeal> meals,
    double? adherence,
    int? thresholdUsed,
    DateTime? lockedAt,
  }) = _Day;
}
```

- [ ] **Step 3.6 — validators:** in `validators.dart` replace `MealValidation` with `MealSnapshotValidation` (same two rules, `items.isEmpty`, field `'items'`, import `meal_snapshot.dart`); `DayValidation` unchanged logic (`meals.map((m) => m.id)` still compiles against `ScheduledMeal`).

- [ ] **Step 3.7 — nutrition instance fns:** append to `nutrition.dart`:

```dart
/// Macros of one snapshot item — plain unpack, absolutes were baked at
/// creation (FoodSnapshot.from). No multiplication at read time.
Macros macrosOfSnapshot(FoodSnapshot snapshot) => Macros(
  protein: snapshot.protein,
  carbs: snapshot.carbs,
  fats: snapshot.fats,
  kcal: snapshot.kcal,
);

/// Planned macros of an instance meal = Σ all items.
Macros mealSnapshotMacros(MealSnapshot meal) => meal.items.fold(
  const Macros(),
  (total, i) => total + macrosOfSnapshot(i.food),
);

/// Consumed macros = Σ checked items only.
Macros consumedMealMacros(MealSnapshot meal) => meal.items
    .where((i) => i.checked)
    .fold(const Macros(), (total, i) => total + macrosOfSnapshot(i.food));
```

(imports: add `../meal/food_snapshot.dart`, `../meal/meal_snapshot.dart`.)

- [ ] **Step 3.8 — codegen** then **tests.** Rewrite `test/domain/meal/meal_test.dart` (model round-trips, `FoodSnapshot.from` math incl. a rounding case, `checked`/`anyChecked`/`allChecked`, UTC asserts throw on local stamps) and `test/domain/day/day_test.dart` (label asserts kept from old file; trio assert: setting only `adherence` throws, all three together OK; duplicate-id validate issue). Representative new tests (write all of these):

```dart
// meal_test.dart (excerpt — full file covers each model)
test('FoodSnapshot.from bakes absolutes', () {
  final f = Food(
    id: 'f1', name: 'Egg', category: FoodCategory.eggs,
    protein: 13, carbs: 1.1, fats: 11, kcalPer100g: 155,
  );
  final s = FoodSnapshot.from(f, const Grams(60));
  check(s.kcal).isCloseTo(93.0, 1e-9);
  check(s.protein).isCloseTo(7.8, 1e-9);
  check(s.sourceFoodId).equals('f1');
});

test('MealItem rejects non-UTC checkedAt', () {
  final food = FoodSnapshot.from(
    Food(id: 'f', name: 'X', category: FoodCategory.custom,
         protein: 0, carbs: 0, fats: 0, kcalPer100g: 0),
    const Grams(100),
  );
  check(() => MealItem(checkedAt: DateTime(2026, 6, 4, 12), food: food))
      .throws<AssertionError>();
});

// day_test.dart (excerpt)
test('frozen trio must be set together', () {
  check(() => Day(date: DateTime.utc(2026, 6, 4), adherence: 0.8))
      .throws<AssertionError>();
  final locked = Day(
    date: DateTime.utc(2026, 6, 4),
    adherence: 0.8,
    thresholdUsed: 80,
    lockedAt: DateTime.utc(2026, 6, 5, 0, 0, 1),
  );
  check(locked.thresholdUsed).equals(80);
});
```

- [ ] **Step 3.9 — verify:** format → analyze → `flutter test` full suite green (day repo impl + its tests compile against new `Day` shape — adjust `test/data/repositories_test.dart` Day fixtures: `meals: []` still valid, `state:` argument deleted if present).

**Acceptance:** ladder types exist with documented asserts; `meal.dart`/`meal_product.dart` gone; full suite green.
**Out of scope:** derivation, ops, materialization.

---

## Task 4: Status derivation — `meal_status.dart` [implement]

**Goal:** the priority chain as one pure function + local-time helpers. **No `Day` import** (Day ops will import this file in Task 5 — cycle-free).

**Files:**
- Create: `lib/domain/services/meal_status.dart`
- Test: `test/domain/services/meal_status_test.dart`

**Skills:** `.agents/skills/dart-add-unit-test`, `.agents/skills/dart-use-pattern-matching`, `.agents/skills/dart-migrate-to-checks-package`.

- [ ] **Step 4.1 — write the failing tests** (`meal_status_test.dart`) — table-driven over the chain. Full file:

```dart
import 'package:checks/checks.dart';
import 'package:crudo/domain/day/scheduled_meal.dart';
import 'package:crudo/domain/food/food.dart';
import 'package:crudo/domain/meal/food_snapshot.dart';
import 'package:crudo/domain/meal/meal_item.dart';
import 'package:crudo/domain/meal/meal_snapshot.dart';
import 'package:crudo/domain/services/meal_status.dart';
import 'package:crudo/domain/shared/enums.dart';
import 'package:crudo/domain/shared/grams.dart';
import 'package:crudo/domain/shared/meal_time.dart';
import 'package:test/test.dart';

final _food = Food(
  id: 'f',
  name: 'X',
  category: FoodCategory.custom,
  protein: 10,
  carbs: 10,
  fats: 10,
  kcalPer100g: 170,
);

FoodSnapshot _snap() => FoodSnapshot.from(_food, const Grams(100));

ScheduledMeal _meal({
  int timeMinutes = 13 * 60, // 13:00
  int checkedOf2 = 0,
  DateTime? skippedAt,
  DateTime? snoozedUntil,
}) => ScheduledMeal(
  id: 'm1',
  time: MealTime(timeMinutes),
  skippedAt: skippedAt,
  snoozedUntil: snoozedUntil,
  meal: MealSnapshot(
    name: 'Lunch',
    items: [
      MealItem(
        checkedAt: checkedOf2 >= 1 ? DateTime.utc(2026, 6, 4, 10) : null,
        food: _snap(),
      ),
      MealItem(
        checkedAt: checkedOf2 >= 2 ? DateTime.utc(2026, 6, 4, 10) : null,
        food: _snap(),
      ),
    ],
  ),
);

void main() {
  // The day under test, as a local-date label, and `now` instants built in
  // LOCAL time on that date so "today" cases hold in any test timezone.
  final dayDate = DateTime.utc(2026, 6, 4);
  DateTime nowAt(int hour, [int minute = 0]) =>
      DateTime(2026, 6, 4, hour, minute);

  group('checked wins (rule 1) on any day', () {
    for (final (label, date) in [
      ('past', DateTime.utc(2026, 6, 3)),
      ('today', dayDate),
      ('future', DateTime.utc(2026, 6, 5)),
    ]) {
      test('partial on $label day', () {
        check(deriveMealStatus(_meal(checkedOf2: 1), date, nowAt(9)))
            .equals(MealStatus.partial);
      });
      test('done on $label day', () {
        check(deriveMealStatus(_meal(checkedOf2: 2), date, nowAt(9)))
            .equals(MealStatus.done);
      });
    }
    test('checked beats explicit skip AND elapsed clock', () {
      final m = _meal(
        checkedOf2: 2,
        skippedAt: DateTime.utc(2026, 6, 4, 9),
        snoozedUntil: DateTime.utc(2026, 6, 4, 11),
      );
      check(deriveMealStatus(m, dayDate, nowAt(23))).equals(MealStatus.done);
    });
  });

  group('non-today, unchecked', () {
    test('past day freezes to skipped (rule 2)', () {
      check(deriveMealStatus(_meal(), DateTime.utc(2026, 6, 3), nowAt(9)))
          .equals(MealStatus.skipped);
    });
    test('future day is upcoming (rule 3) even past meal time', () {
      check(deriveMealStatus(_meal(), DateTime.utc(2026, 6, 5), nowAt(23)))
          .equals(MealStatus.upcoming);
    });
  });

  group('today chain', () {
    test('explicit skip shows immediately, pre-window (rule 4)', () {
      final m = _meal(skippedAt: DateTime.utc(2026, 6, 4, 9));
      check(deriveMealStatus(m, dayDate, nowAt(9, 30)))
          .equals(MealStatus.skipped);
    });
    test('skip beats pending snooze (rule 4 over 5)', () {
      final m = _meal(
        skippedAt: DateTime.utc(2026, 6, 4, 9),
        snoozedUntil: nowAt(18).toUtc(),
      );
      check(deriveMealStatus(m, dayDate, nowAt(14)))
          .equals(MealStatus.skipped);
    });
    test('pending snooze holds upcoming past meal time (rule 5 over 6)', () {
      final m = _meal(snoozedUntil: nowAt(14, 30).toUtc());
      check(deriveMealStatus(m, dayDate, nowAt(14)))
          .equals(MealStatus.upcoming);
    });
    test('elapsed snooze falls through to auto-skip (rule 6)', () {
      final m = _meal(snoozedUntil: nowAt(13, 30).toUtc());
      check(deriveMealStatus(m, dayDate, nowAt(14)))
          .equals(MealStatus.skipped);
    });
    test('auto-skip flips at meal time exactly, no grace (rule 6)', () {
      check(deriveMealStatus(_meal(), dayDate, nowAt(12, 59)))
          .equals(MealStatus.upcoming);
      check(deriveMealStatus(_meal(), dayDate, nowAt(13)))
          .equals(MealStatus.skipped);
    });
    test('MealTime(0) auto-skips from day start (edge 18)', () {
      check(deriveMealStatus(_meal(timeMinutes: 0), dayDate, nowAt(0)))
          .equals(MealStatus.skipped);
    });
    test('upcoming before meal time (rule 7)', () {
      check(deriveMealStatus(_meal(), dayDate, nowAt(8)))
          .equals(MealStatus.upcoming);
    });
  });

  group('time helpers', () {
    test('localDateLabel encodes local date as UTC label', () {
      final label = localDateLabel(DateTime(2026, 6, 4, 23, 59));
      check(label).equals(DateTime.utc(2026, 6, 4));
      check(label.isUtc).isTrue();
    });
    test('localInstantAt builds local wall-clock instant on label date', () {
      final inst = localInstantAt(dayDate, const MealTime(13 * 60));
      check(inst).equals(DateTime(2026, 6, 4, 13));
      check(inst.isUtc).isFalse();
    });
    test('endOfDayLocal is start of next local day', () {
      check(endOfDayLocal(dayDate)).equals(DateTime(2026, 6, 5));
    });
  });
}
```

- [ ] **Step 4.2 — run:** `flutter test test/domain/services/meal_status_test.dart` → FAIL (no `meal_status.dart`).

- [ ] **Step 4.3 — `lib/domain/services/meal_status.dart`:**

```dart
import '../day/scheduled_meal.dart';
import '../shared/enums.dart';
import '../shared/meal_time.dart';

/// Status derivation (S05). Status is NEVER stored — recomputed per read from
/// (checked marks, skippedAt, snoozedUntil, time, dayDate, now). This file
/// deliberately does not import Day, so Day's ops can import it cycle-free.

/// The user's local calendar date at [now], UTC-encoded (Day.date convention).
DateTime localDateLabel(DateTime now) {
  final local = now.toLocal();
  return DateTime.utc(local.year, local.month, local.day);
}

/// The local wall-clock instant of [time] on the labeled date.
DateTime localInstantAt(DateTime dayDate, MealTime time) =>
    DateTime(dayDate.year, dayDate.month, dayDate.day, time.hour, time.minute);

/// Start of the next local day — the midnight that ends [dayDate].
DateTime endOfDayLocal(DateTime dayDate) =>
    DateTime(dayDate.year, dayDate.month, dayDate.day + 1);

/// Priority chain (spec §Status derivation):
///   1 any item checked → done/partial   (clock + stamps irrelevant)
///   2 past day         → skipped        (history freezes unchecked)
///   3 future day       → upcoming       (preview)
///   4 skippedAt set    → skipped        (explicit skip, shown pre-window too)
///   5 snooze pending   → upcoming       (UI chips off the field)
///   6 meal time passed → skipped        (auto-skip, exact time, no grace)
///   7 otherwise        → upcoming
MealStatus deriveMealStatus(
  ScheduledMeal meal,
  DateTime dayDate,
  DateTime now,
) {
  final items = meal.meal.items;
  final checked = items.where((i) => i.checked).length;
  if (checked > 0) {
    return checked == items.length ? MealStatus.done : MealStatus.partial;
  }
  final today = localDateLabel(now);
  if (dayDate.isBefore(today)) return MealStatus.skipped;
  if (dayDate.isAfter(today)) return MealStatus.upcoming;
  if (meal.skippedAt != null) return MealStatus.skipped;
  final snoozedUntil = meal.snoozedUntil;
  if (snoozedUntil != null && snoozedUntil.isAfter(now)) {
    return MealStatus.upcoming;
  }
  if (!now.toLocal().isBefore(localInstantAt(dayDate, meal.time))) {
    return MealStatus.skipped;
  }
  return MealStatus.upcoming;
}
```

- [ ] **Step 4.4 — run the file again:** green. Then `dart format .` → `flutter analyze` → `flutter test`.

**Acceptance:** every chain rule + both rationale orderings (4>5, 5>6) covered by a named test; helpers tested; suite green.
**Out of scope:** ops, predicates needing `Day`.

---

## Task 5: `Day` ops + predicates [implement]

**Goal:** lifecycle mutations as methods on the `Day` aggregate (each returns a new `Day` or throws `StateError`), plus the UI pre-check predicates in `meal_lifecycle.dart`.

**Files:**
- Modify: `lib/domain/day/day.dart` (append methods to the freezed body)
- Create: `lib/domain/services/meal_lifecycle.dart` (predicates now; materialization/kcal in Task 6)
- Test: `test/domain/day/day_ops_test.dart` (new)

**Skills:** `.agents/skills/dart-add-unit-test`, `.agents/skills/dart-migrate-to-checks-package`.

- [ ] **Step 5.1 — failing tests** (`day_ops_test.dart`). Full file:

```dart
import 'package:checks/checks.dart';
import 'package:crudo/domain/day/day.dart';
import 'package:crudo/domain/day/scheduled_meal.dart';
import 'package:crudo/domain/food/food.dart';
import 'package:crudo/domain/meal/food_snapshot.dart';
import 'package:crudo/domain/meal/meal_item.dart';
import 'package:crudo/domain/meal/meal_snapshot.dart';
import 'package:crudo/domain/services/meal_lifecycle.dart';
import 'package:crudo/domain/shared/grams.dart';
import 'package:crudo/domain/shared/meal_time.dart';
import 'package:crudo/domain/shared/enums.dart';
import 'package:test/test.dart';

final _food = Food(
  id: 'f',
  name: 'X',
  category: FoodCategory.custom,
  protein: 10,
  carbs: 10,
  fats: 10,
  kcalPer100g: 170,
);

MealItem _item([DateTime? checkedAt]) =>
    MealItem(checkedAt: checkedAt, food: FoodSnapshot.from(_food, const Grams(100)));

ScheduledMeal _meal(String id, int minutes, {int checkedOf2 = 0}) =>
    ScheduledMeal(
      id: id,
      time: MealTime(minutes),
      meal: MealSnapshot(
        name: 'M$id',
        items: [
          _item(checkedOf2 >= 1 ? DateTime.utc(2026, 6, 4, 9) : null),
          _item(checkedOf2 >= 2 ? DateTime.utc(2026, 6, 4, 9) : null),
        ],
      ),
    );

void main() {
  final today = DateTime.utc(2026, 6, 4);
  final now = DateTime(2026, 6, 4, 12); // local noon
  Day day({int checkedOf2 = 0}) => Day(
    date: today,
    meals: [
      _meal('breakfast', 8 * 60),
      _meal('lunch', 13 * 60, checkedOf2: checkedOf2),
      _meal('dinner', 19 * 60),
    ],
  );

  group('universal lock guard', () {
    final tomorrow = DateTime.utc(2026, 6, 5);
    test('every op rejects on a locked day', () {
      final d = day();
      check(() => d.checkItem('lunch', 0, now, tomorrow))
          .throws<StateError>();
      check(() => d.uncheckItem('lunch', 0, now, tomorrow))
          .throws<StateError>();
      check(() => d.markAllEaten('lunch', now, tomorrow))
          .throws<StateError>();
      check(() => d.skipMeal('lunch', now, tomorrow)).throws<StateError>();
      check(() => d.snoozeMeal('lunch', now.add(const Duration(minutes: 30)),
          now, tomorrow)).throws<StateError>();
      check(() => d.replaceMeal('lunch', MealSnapshot(name: 'N', items: [_item()]),
          now, tomorrow)).throws<StateError>();
      check(isDayLocked(d, tomorrow)).isTrue();
      check(isDayLocked(d, today)).isFalse();
    });
  });

  group('checkItem / uncheckItem / markAllEaten', () {
    test('checkItem stamps UTC now on the item', () {
      final d = day().checkItem('lunch', 0, now, today);
      final stamped =
          d.meals.singleWhere((m) => m.id == 'lunch').meal.items[0].checkedAt;
      check(stamped).isNotNull();
      check(stamped!.isUtc).isTrue();
      check(stamped).equals(now.toUtc());
    });
    test('out-of-range index throws', () {
      check(() => day().checkItem('lunch', 2, now, today))
          .throws<StateError>();
      check(() => day().checkItem('lunch', -1, now, today))
          .throws<StateError>();
    });
    test('unknown meal id throws', () {
      check(() => day().checkItem('nope', 0, now, today))
          .throws<StateError>();
    });
    test('uncheckItem clears the stamp', () {
      final d = day(checkedOf2: 1).uncheckItem('lunch', 0, now, today);
      check(d.meals[1].meal.items[0].checkedAt).isNull();
    });
    test('markAllEaten stamps unchecked, preserves existing stamps', () {
      final before = day(checkedOf2: 1);
      final original = before.meals[1].meal.items[0].checkedAt;
      final d = before.markAllEaten('lunch', now, today);
      check(d.meals[1].meal.items[0].checkedAt).equals(original);
      check(d.meals[1].meal.items[1].checkedAt).equals(now.toUtc());
    });
    test('marking never touches skippedAt/snoozedUntil', () {
      final skipped = day().skipMeal('lunch', now, today);
      final d = skipped.markAllEaten('lunch', now, today);
      final lunch = d.meals.singleWhere((m) => m.id == 'lunch');
      check(lunch.skippedAt).isNotNull(); // stamp survives — analytics keep
    });
  });

  group('skipMeal', () {
    test('stamps UTC; re-skip overwrites', () {
      final d1 = day().skipMeal('lunch', now, today);
      final later = now.add(const Duration(hours: 1));
      final d2 = d1.skipMeal('lunch', later, today);
      check(d2.meals[1].skippedAt).equals(later.toUtc());
    });
    test('rejects when any item checked', () {
      check(() => day(checkedOf2: 1).skipMeal('lunch', now, today))
          .throws<StateError>();
      check(canSkipMeal(day(checkedOf2: 1), 'lunch', today)).isFalse();
      check(canSkipMeal(day(), 'lunch', today)).isTrue();
    });
  });

  group('snoozeMeal + maxSnoozeUntil', () {
    test('bound is next meal by time (lunch → dinner 19:00)', () {
      final bound = maxSnoozeUntil(day(), 'lunch', now);
      check(bound).equals(DateTime(2026, 6, 4, 19).toUtc());
    });
    test('last meal bounds at end-of-day midnight', () {
      final bound = maxSnoozeUntil(day(), 'dinner', now);
      check(bound).equals(DateTime(2026, 6, 5).toUtc());
    });
    test('same-time meals do not bound each other', () {
      final d = Day(date: today, meals: [
        _meal('a', 13 * 60),
        _meal('b', 13 * 60),
      ]);
      check(maxSnoozeUntil(d, 'a', now)).equals(DateTime(2026, 6, 5).toUtc());
    });
    test('MealTime(0) meal can snooze into its whole day (edge 18)', () {
      final d = Day(date: today, meals: [_meal('mid', 0)]);
      check(maxSnoozeUntil(d, 'mid', now))
          .equals(DateTime(2026, 6, 5).toUtc());
    });
    test('accepts within bound, repeatable; rejects past bound or non-future', () {
      final d1 = day().snoozeMeal(
          'lunch', DateTime(2026, 6, 4, 13, 30).toUtc(), now, today);
      final d2 = d1.snoozeMeal(
          'lunch', DateTime(2026, 6, 4, 14, 15).toUtc(), now, today);
      check(d2.meals[1].snoozedUntil)
          .equals(DateTime(2026, 6, 4, 14, 15).toUtc());
      check(() => day().snoozeMeal(
              'lunch', DateTime(2026, 6, 4, 19, 1).toUtc(), now, today))
          .throws<StateError>(); // past next meal
      check(() => day().snoozeMeal('lunch', now.toUtc(), now, today))
          .throws<StateError>(); // not strictly future
    });
    test('rejects when done; canSnoozeMeal mirrors', () {
      check(() => day(checkedOf2: 2).snoozeMeal(
              'lunch', DateTime(2026, 6, 4, 14).toUtc(), now, today))
          .throws<StateError>();
      check(canSnoozeMeal(day(checkedOf2: 2), 'lunch', now, today)).isFalse();
      check(canSnoozeMeal(day(), 'lunch', now, today)).isTrue();
    });
  });

  group('replaceMeal (content-edit guard)', () {
    final newMeal = MealSnapshot(name: 'Swap', items: [_item()]);
    test('swaps content; id + time survive', () {
      final d = day().replaceMeal('lunch', newMeal, now, today);
      final lunch = d.meals[1];
      check(lunch.id).equals('lunch');
      check(lunch.time).equals(const MealTime(13 * 60));
      check(lunch.meal.name).equals('Swap');
    });
    test('rejects on every non-upcoming status', () {
      // partial / done
      check(() => day(checkedOf2: 1).replaceMeal('lunch', newMeal, now, today))
          .throws<StateError>();
      check(() => day(checkedOf2: 2).replaceMeal('lunch', newMeal, now, today))
          .throws<StateError>();
      // explicitly skipped
      final skipped = day().skipMeal('lunch', now, today);
      check(() => skipped.replaceMeal('lunch', newMeal, now, today))
          .throws<StateError>();
      // auto-skipped (window passed, 14:00 > 13:00)
      final after = DateTime(2026, 6, 4, 14);
      check(() => day().replaceMeal('lunch', newMeal, after, today))
          .throws<StateError>();
      // predicate mirrors
      check(canEditMealContent(day().meals[1], today, after)).isFalse();
      check(canEditMealContent(day().meals[1], today, now)).isTrue();
    });
  });
}
```

- [ ] **Step 5.2 — run:** FAIL (methods missing).

- [ ] **Step 5.3 — implement.** Append to the `Day` class body in `day.dart` (add imports `../shared/meal_time.dart`, `../meal/meal_snapshot.dart`, `../services/meal_status.dart`):

```dart
  // ───────────────────────── lifecycle ops (S05) ─────────────────────────
  // Each op returns a NEW Day or throws StateError on a violated guard —
  // views must pre-check with the predicates in meal_lifecycle.dart.
  // `mealId` is always ScheduledMeal.id; `itemIndex` addresses the items
  // list at call time (order is display-only — the index is a selector,
  // never persisted identity). Marking ops never touch skippedAt /
  // snoozedUntil: the stamps persist for analytics; derivation lets
  // checked win regardless.

  bool _locked(DateTime today) => date.isBefore(today);

  void _ensureUnlocked(DateTime today) {
    if (_locked(today)) {
      throw StateError('day $date is locked (today is $today)');
    }
  }

  ScheduledMeal _mealById(String mealId) => meals.firstWhere(
    (m) => m.id == mealId,
    orElse: () => throw StateError('no meal with id $mealId'),
  );

  Day _withMeal(ScheduledMeal updated) => copyWith(
    meals: [
      for (final m in meals)
        if (m.id == updated.id) updated else m,
    ],
  );

  Day _withItemStamp(
    String mealId,
    int itemIndex,
    DateTime? stamp,
    DateTime today,
  ) {
    _ensureUnlocked(today);
    final meal = _mealById(mealId);
    final items = meal.meal.items;
    if (itemIndex < 0 || itemIndex >= items.length) {
      throw StateError('item index $itemIndex out of range for $mealId');
    }
    final updated = [...items];
    updated[itemIndex] = updated[itemIndex].copyWith(checkedAt: stamp);
    return _withMeal(meal.copyWith(meal: meal.meal.copyWith(items: updated)));
  }

  Day checkItem(String mealId, int itemIndex, DateTime now, DateTime today) =>
      _withItemStamp(mealId, itemIndex, now.toUtc(), today);

  Day uncheckItem(
    String mealId,
    int itemIndex,
    DateTime now,
    DateTime today,
  ) => _withItemStamp(mealId, itemIndex, null, today);

  /// "Ate it" one-tap: stamps every UNCHECKED item with now; items already
  /// checked keep their original (earlier) stamp.
  Day markAllEaten(String mealId, DateTime now, DateTime today) {
    _ensureUnlocked(today);
    final meal = _mealById(mealId);
    final stamp = now.toUtc();
    final items = [
      for (final i in meal.meal.items)
        if (i.checked) i else i.copyWith(checkedAt: stamp),
    ];
    return _withMeal(meal.copyWith(meal: meal.meal.copyWith(items: items)));
  }

  /// Explicit skip. Re-skip overwrites the stamp. Skipping an eaten meal is
  /// meaningless — uncheck first (UI pre-checks with canSkipMeal).
  Day skipMeal(String mealId, DateTime now, DateTime today) {
    _ensureUnlocked(today);
    final meal = _mealById(mealId);
    if (meal.meal.anyChecked) {
      throw StateError('cannot skip $mealId: items are checked');
    }
    return _withMeal(meal.copyWith(skippedAt: now.toUtc()));
  }

  /// Snooze bound: next meal by `time` STRICTLY greater (same-time meals do
  /// not bound each other), else the end-of-day midnight (start of date+1) —
  /// so a MealTime(0) meal can still snooze into its whole day. Returned UTC.
  DateTime maxSnoozeUntilFor(String mealId, DateTime now) {
    final meal = _mealById(mealId);
    MealTime? nextTime;
    for (final m in meals) {
      if (m.time.compareTo(meal.time) > 0 &&
          (nextTime == null || m.time.compareTo(nextTime) < 0)) {
        nextTime = m.time;
      }
    }
    final bound = nextTime == null
        ? endOfDayLocal(date)
        : localInstantAt(date, nextTime);
    return bound.toUtc();
  }

  /// Repeatable (overwrites), allowed post-window ("remind me later anyway").
  Day snoozeMeal(String mealId, DateTime until, DateTime now, DateTime today) {
    _ensureUnlocked(today);
    final meal = _mealById(mealId);
    if (meal.meal.allChecked) {
      throw StateError('cannot snooze $mealId: meal is done');
    }
    if (!until.isAfter(now) ||
        until.toUtc().isAfter(maxSnoozeUntilFor(mealId, now))) {
      throw StateError('snooze target $until violates bound');
    }
    return _withMeal(meal.copyWith(snoozedUntil: until.toUtc()));
  }

  /// Whole-content swap — the slot's id + time survive (notifications keep
  /// their key). Content-edit guard: only while derived status is upcoming
  /// (any checked item, explicit skip, or a passed window locks content).
  Day replaceMeal(
    String mealId,
    MealSnapshot newMeal,
    DateTime now,
    DateTime today,
  ) {
    _ensureUnlocked(today);
    final meal = _mealById(mealId);
    if (deriveMealStatus(meal, date, now) != MealStatus.upcoming) {
      throw StateError('cannot edit $mealId: status is not upcoming');
    }
    return _withMeal(meal.copyWith(meal: newMeal));
  }
```

(also add `import '../shared/enums.dart';` for `MealStatus`.)

- [ ] **Step 5.4 — `lib/domain/services/meal_lifecycle.dart`** (predicates; Task 6 appends to this file):

```dart
import '../day/day.dart';
import '../day/scheduled_meal.dart';
import '../shared/enums.dart';
import 'meal_status.dart';

/// Engine façade (S05): UI pre-check predicates. Every throwing Day op has a
/// matching predicate — views consult these and never discover a guard by
/// catching. Materialization + kcal live below (Task 6).

/// Locked = the label date is before today's label. Purely derived — correct
/// even if the app was closed across many midnights (no timer, no write).
bool isDayLocked(Day day, DateTime today) => day.date.isBefore(today);

/// Content edits (replaceMeal now; add/remove/grams at S08) only while the
/// derived status is `upcoming` — blocks edit-after-eating and the
/// "delete what I didn't eat" adherence cheat.
bool canEditMealContent(ScheduledMeal meal, DateTime dayDate, DateTime now) =>
    !dayDate.isBefore(localDateLabel(now)) &&
    deriveMealStatus(meal, dayDate, now) == MealStatus.upcoming;

bool canSkipMeal(Day day, String mealId, DateTime today) {
  if (isDayLocked(day, today)) return false;
  final meal = day.meals.where((m) => m.id == mealId).firstOrNull;
  return meal != null && !meal.meal.anyChecked;
}

bool canSnoozeMeal(Day day, String mealId, DateTime now, DateTime today) {
  if (isDayLocked(day, today)) return false;
  final meal = day.meals.where((m) => m.id == mealId).firstOrNull;
  if (meal == null || meal.meal.allChecked) return false;
  return maxSnoozeUntil(day, mealId, now).isAfter(now);
}

/// min(next meal by time strictly greater, end-of-day midnight) as UTC.
DateTime maxSnoozeUntil(Day day, String mealId, DateTime now) =>
    day.maxSnoozeUntilFor(mealId, now);
```

- [ ] **Step 5.5 — verify:** ops test file green → format → analyze → full `flutter test`.

**Acceptance:** every op × every guard has a test; predicates mirror ops; suite green.
**Out of scope:** materialization, kcal.

---

## Task 6: Materialization + kcal + final review [implement]

**Goal:** `selectPlanForDate`, `buildDayFromPlan`, day-level macro/kcal fns. Then the worker-side review pass and the report.

**Files:**
- Modify: `lib/domain/services/meal_lifecycle.dart` (append)
- Test: `test/domain/services/meal_lifecycle_test.dart` (new)

**Skills:** `.agents/skills/dart-add-unit-test`, `.agents/skills/dart-migrate-to-checks-package`.

- [ ] **Step 6.1 — failing tests** (`meal_lifecycle_test.dart`). Full file:

```dart
import 'package:checks/checks.dart';
import 'package:crudo/domain/day/day.dart';
import 'package:crudo/domain/food/food.dart';
import 'package:crudo/domain/food/food_ref.dart';
import 'package:crudo/domain/meal/meal_template.dart';
import 'package:crudo/domain/plan/plan_slot.dart';
import 'package:crudo/domain/plan/plan_template.dart';
import 'package:crudo/domain/services/meal_lifecycle.dart';
import 'package:crudo/domain/shared/enums.dart';
import 'package:crudo/domain/shared/grams.dart';
import 'package:crudo/domain/shared/meal_time.dart';
import 'package:test/test.dart';

class _SeqIds {
  int _n = 0;
  String newId() => 'id-${_n++}';
}

final _egg = Food(
  id: 'egg',
  name: 'Egg',
  category: FoodCategory.eggs,
  protein: 13,
  carbs: 1.1,
  fats: 11,
  kcalPer100g: 155,
);
final _rice = Food(
  id: 'rice',
  name: 'Rice',
  category: FoodCategory.grain,
  protein: 2.7,
  carbs: 28,
  fats: 0.3,
  kcalPer100g: 130,
);

final _breakfastTpl = MealTemplate(
  id: 'tpl-b',
  name: 'Eggs',
  foods: [FoodRef(foodId: 'egg', grams: const Grams(120))],
);
final _lunchTpl = MealTemplate(
  id: 'tpl-l',
  name: 'Rice bowl',
  foods: [
    FoodRef(foodId: 'rice', grams: const Grams(150)),
    FoodRef(foodId: 'egg', grams: const Grams(60)),
  ],
);

PlanTemplate _plan({
  String id = 'p1',
  List<int> days = const [0, 1, 2, 3, 4], // Mon–Fri
  bool active = true,
}) => PlanTemplate(
  id: id,
  name: 'Cut',
  days: days,
  active: active,
  slots: [
    // deliberately unsorted — materialization must sort by time
    PlanSlot(id: 's2', mealTemplateId: 'tpl-l', time: const MealTime(13 * 60)),
    PlanSlot(id: 's1', mealTemplateId: 'tpl-b', time: const MealTime(8 * 60)),
  ],
);

void main() {
  final thursday = DateTime.utc(2026, 6, 4); // 2026-06-04 is a Thursday
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
      final picked = selectPlanForDate(
        [_plan(id: 'p2'), _plan(id: 'p1')],
        thursday,
      );
      check(picked!.id).equals('p1');
    });
  });

  group('buildDayFromPlan', () {
    Day build({PlanTemplate? plan}) => buildDayFromPlan(
      plan,
      thursday,
      _SeqIds().newId,
      [_breakfastTpl, _lunchTpl],
      [_egg, _rice],
    );

    test('null plan → empty rest day, no plan refs', () {
      final d = build(plan: null);
      check(d.date).equals(thursday);
      check(d.sourcePlanId).isNull();
      check(d.meals).isEmpty();
    });

    test('one ScheduledMeal per slot, sorted by time, fresh ids, unchecked', () {
      final d = build(plan: _plan());
      check(d.sourcePlanId).equals('p1');
      check(d.planName).equals('Cut');
      check(d.meals.length).equals(2);
      check(d.meals[0].time).equals(const MealTime(8 * 60)); // sorted
      check(d.meals[0].id).equals('id-0');
      check(d.meals[1].id).equals('id-1');
      check(d.meals[0].meal.sourceMealTemplateId).equals('tpl-b');
      check(d.meals[0].meal.items.every((i) => !i.checked)).isTrue();
    });

    test('items carry computed absolutes from FoodSnapshot.from', () {
      final d = build(plan: _plan());
      final eggs120 = d.meals[0].meal.items.single;
      check(eggs120.food.kcal).isCloseTo(155 * 1.2, 1e-9);
      check(eggs120.food.sourceFoodId).equals('egg');
    });

    test('dangling food ref drops the item; dangling template drops the slot', () {
      final d = buildDayFromPlan(
        _plan(),
        thursday,
        _SeqIds().newId,
        [_lunchTpl], // tpl-b missing → breakfast slot dropped
        [_rice], // egg missing → lunch keeps only rice
      );
      check(d.meals.length).equals(1);
      check(d.meals.single.meal.items.length).equals(1);
      check(d.meals.single.meal.items.single.food.sourceFoodId)
          .equals('rice');
    });

    test('slot whose items ALL dangle is dropped entirely', () {
      final d = buildDayFromPlan(
        _plan(),
        thursday,
        _SeqIds().newId,
        [_breakfastTpl, _lunchTpl],
        [_rice], // egg missing → breakfast (egg-only) drops; lunch keeps rice
      );
      check(d.meals.length).equals(1);
      check(d.meals.single.meal.name).equals('Rice bowl');
    });
  });

  group('day kcal/macros', () {
    test('planned sums all items; consumed sums checked only; empty day 0/0', () {
      final now = DateTime(2026, 6, 4, 12);
      final today = thursday;
      var d = buildDayFromPlan(
        _plan(),
        thursday,
        _SeqIds().newId,
        [_breakfastTpl, _lunchTpl],
        [_egg, _rice],
      );
      final expectedPlanned =
          155 * 1.2 + 130 * 1.5 + 155 * 0.6; // eggs120 + rice150 + egg60
      check(plannedKcal(d)).isCloseTo(expectedPlanned, 1e-9);
      check(consumedKcal(d)).equals(0);

      d = d.markAllEaten(d.meals[0].id, now, today); // breakfast done
      d = d.checkItem(d.meals[1].id, 0, now, today); // lunch: rice only
      check(consumedKcal(d)).isCloseTo(155 * 1.2 + 130 * 1.5, 1e-9);
      check(consumedKcal(d) <= plannedKcal(d)).isTrue();

      final rest = Day(date: thursday);
      check(plannedKcal(rest)).equals(0);
      check(consumedKcal(rest)).equals(0);
      check(plannedMacros(d).kcal).isCloseTo(plannedKcal(d), 1e-9);
      check(consumedMacros(d).kcal).isCloseTo(consumedKcal(d), 1e-9);
    });
  });
}
```

- [ ] **Step 6.2 — run:** FAIL. **Step 6.3 — append to `meal_lifecycle.dart`** (add imports: `../food/food.dart`, `../meal/food_snapshot.dart`, `../meal/meal_item.dart`, `../meal/meal_snapshot.dart`, `../meal/meal_template.dart`, `../plan/plan_template.dart`, `../shared/grams.dart` is pulled transitively — import what the analyzer asks, plus `../shared/macros.dart`, `nutrition.dart`):

```dart
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

/// Materializes a Day from a plan (copy-on-write read path — the S06
/// controller persists the result ONLY for today, or on first edit of a
/// future day; otherwise it's a throwaway preview).
///
/// PURE: no repo access — the caller passes raw repo data; refs are resolved
/// here by id. A dangling food ref drops that item; a dangling template (or a
/// slot whose items all dangle) drops the slot (S07/S09 prevent upstream).
/// [newId] mints slot-stable ScheduledMeal ids (uuid v7 in production —
/// injected as a function so the domain stays uuid-free).
Day buildDayFromPlan(
  PlanTemplate? plan,
  DateTime date,
  String Function() newId,
  List<MealTemplate> mealTemplates,
  List<Food> foods,
) {
  if (plan == null) return Day(date: date);
  final templatesById = {for (final t in mealTemplates) t.id: t};
  final foodsById = {for (final f in foods) f.id: f};

  final slots = [...plan.slots]..sort((a, b) => a.time.compareTo(b.time));
  final meals = <ScheduledMeal>[];
  for (final slot in slots) {
    final template = templatesById[slot.mealTemplateId];
    if (template == null) continue;
    final items = <MealItem>[
      for (final ref in template.foods)
        if (foodsById[ref.foodId] != null)
          MealItem(food: FoodSnapshot.from(foodsById[ref.foodId]!, ref.grams)),
    ];
    if (items.isEmpty) continue;
    meals.add(
      ScheduledMeal(
        id: newId(),
        time: slot.time,
        meal: MealSnapshot(
          sourceMealTemplateId: template.id,
          name: template.name,
          tags: template.tags,
          items: items,
        ),
      ),
    );
  }
  return Day(
    date: date,
    sourcePlanId: plan.id,
    planName: plan.name,
    meals: meals,
  );
}

/// Day totals — plain summation of stored absolutes (no multiplication at
/// read time; the formula ran once at snapshot creation).
Macros plannedMacros(Day day) => day.meals.fold(
  const Macros(),
  (total, m) => total + mealSnapshotMacros(m.meal),
);

Macros consumedMacros(Day day) => day.meals.fold(
  const Macros(),
  (total, m) => total + consumedMealMacros(m.meal),
);

double plannedKcal(Day day) => plannedMacros(day).kcal;
double consumedKcal(Day day) => consumedMacros(day).kcal;
```

(Note: `buildDayFromPlan` takes `String Function() newId` rather than the data-layer `IdGenerator` class — domain cannot import `lib/data/`. The S06 controller passes `idGenerator.newId`.)

- [ ] **Step 6.4 — verify:** green → format → analyze → full `flutter test`.

- [ ] **Step 6.5 — review pass:** run `@review` (nemotron) on the whole working-tree diff vs the spec (`docs/specs/2026-06-04-s05-meal-lifecycle.md`) + `AGENTS.md` invariants. Fix any `BLOCK`. Re-run format/analyze/test.

- [ ] **Step 6.6 — report:** write `.opencode/handoff/2026-06-04-s05-meal-lifecycle.report.md` per the format in `docs/workflow.md` (status, per-task checklist, pasted real command output, files touched, deviations, blockers).

**Acceptance:** spec's test matrix fully covered (derivation, guards, bounds incl. same-time + `MealTime(0)`, materialization incl. dangling refs + sorting + tie-break, kcal incl. 0/0); `grep -rn "DateTime.now()" lib/domain/` empty; full suite green; report written.
**Out of scope:** controllers, persistence orchestration, notifications.

---

## Plan self-review notes (Opus)

- Spec coverage: model refactor (T3), rename ripple (T1+T2), derivation (T4), ops+predicates (T5), `maxSnoozeUntil` rule (T5), materialization + CoW read-path contract (T6 — orchestration itself is S06, only the pure fns ship), kcal (T6), time conventions (T4 helpers + UTC asserts in T3), test matrix (T4–T6), acceptance (each task gate + T6.4).
- Deviations from spec, intentional: field `fats` not `fat` (codebase idiom); seed asset untouched — mapper computes `kcalPer100g` + `kind` (spec said "seed JSON gains" — mapper is simpler and keeps the asset stable); engine split into `meal_status.dart` + `meal_lifecycle.dart` (cycle-free; spec named one file); `buildDayFromPlan` takes `String Function() newId` not `IdGenerator` (domain cannot import data; spec signature listed `IdGenerator` loosely); `isKcalOverrideValid` renamed `isExplicitKcalValid` (override concept is gone).
