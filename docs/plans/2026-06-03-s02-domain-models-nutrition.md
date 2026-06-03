# S02: Domain Layer — Implementation Plan

> **For workers:** implement task-by-task, top to bottom. Each task = a contract + checkbox (`- [ ]`) steps; read the `.agents/skills` it names before that task. Sequential, main working tree. **Do not commit** — report each task done for Opus to review & integrate. Spec: `docs/specs/2026-06-03-s02-domain-models-nutrition.md`. Diagrams: `docs/design/domain/2026-06-02-s02-domain-diagrams.md`.

**Goal:** Ship the pure domain layer — value objects, aggregate-module freezed entities (template + instance trees), two-tier validation, the nutrition domain service, generic date utils, the dependency-rule architecture test — plus the freezed codegen toolchain (deferred from S01). **No JSON anywhere in domain** (DTOs land in `data/` at S20). No widgets, repos, or engines.

**Architecture:** "Riverpod MVVM + shared DDD core" (locked 2026-06-03, see `architecture.md` §2). `lib/domain/` is PURE Dart — allowed imports: `dart:*`, `package:freezed_annotation/`, `package:crudo/domain/` (+ relative). `lib/utils/` = generic only (`dart:*`). An architecture test enforces this mechanically. Aggregate modules: `product/ meal/ plan/ day/ profile/ streak/` + `shared/` (VOs, enums) + `services/` (nutrition) + `validation/`.

**Tech Stack:** Flutter 3.41.9 / Dart 3.11.5. `freezed 3.2.5` + `freezed_annotation 3.1.0` + `build_runner 2.15.0` — all stable, **no `dependency_overrides`**, `meta` stays `1.17.0` (verified). **`json_serializable`/`json_annotation` must NOT be added.** Tests: `flutter_test` + **`package:checks`**. Codegen command is `dart run build_runner build` (the `--delete-conflicting-outputs` flag was **removed** in build_runner 2.15).

**Conventions:** follow `AGENTS.md`. freezed 3.x: `abstract class X with _$X` + `const factory X(...) = _X;` + `const X._();` private ctor (so behavior methods can be added in S05/S12) + `@Assert` for invariants. Generated `*.freezed.dart` **are committed**. After touching any `@freezed` file run `dart run build_runner build` before testing. `dart format .` + `flutter analyze` + `flutter test` must be clean per task.

---

### Task 1: Codegen toolchain (freezed only) + docs fix

**Role:** build · **Skills:** `dart-resolve-package-conflicts`
**Goal:** Install the freezed toolchain; verify the all-stable/no-override resolution; correct the codegen command in `AGENTS.md`.
**Files:** Modify `pubspec.yaml` · Modify `AGENTS.md`
**Contract:** runtime dep `freezed_annotation ^3.1.0`; dev deps `build_runner ^2.15.0`, `freezed ^3.2.5`. **NO** `json_serializable`, `json_annotation`, `riverpod_generator`, `custom_lint`, `mockito`. No `dependency_overrides`; no prerelease; `meta` transitive stays `1.17.0`.
**Out of scope:** any Dart code (later tasks).

- [ ] **Step 1: Add deps**

```bash
flutter pub add freezed_annotation
flutter pub add dev:build_runner dev:freezed
```
Expected: `freezed_annotation 3.1.0`, `build_runner 2.15.0`, `freezed 3.2.5`, transitive `analyzer 10.0.1`, `meta 1.17.0` unchanged.

- [ ] **Step 2: Verify clean resolution**

Run: `flutter pub get`
Then confirm in `pubspec.yaml`: no `dependency_overrides:` block; no `json_serializable`/`json_annotation` anywhere. If any prerelease (`-dev`) version resolved, stop and report — do not pin a prerelease.

- [ ] **Step 3: Fix the codegen command in `AGENTS.md`**

Replace the Commands line
```
dart run build_runner build --delete-conflicting-outputs  # codegen: freezed, riverpod (added in S02)
```
with
```
dart run build_runner build                               # codegen: freezed (build_runner 2.15: no --delete-conflicting-outputs flag)
```
And update the prose note below the commands block: replace the sentence saying the codegen toolchain "arrives in S02" with: "The freezed codegen toolchain is installed (S02); run `dart run build_runner build` after touching any `@freezed` model. JSON codegen is deliberately absent — the domain is serialization-free; DTOs arrive in `data/` at S20."

- [ ] **Step 4: Analyze**

Run: `flutter analyze`
Expected: 0 issues.

- [ ] **Step 5: Report** this task done for review (do **not** commit). Include resolved versions of `freezed`, `build_runner`, `analyzer`, `meta`.

---

### Task 2: Value objects + enums (`domain/shared/`)

**Role:** implement · **Skills:** `dart-add-unit-test`, `dart-migrate-to-checks-package`
**Goal:** `MealTime`, `Grams` (plain immutable classes with invariant asserts), `Macros` (freezed, with `+` operator), all enums. Proves the freezed toolchain end-to-end.
**Files:** Create `lib/domain/shared/enums.dart`, `lib/domain/shared/meal_time.dart`, `lib/domain/shared/grams.dart`, `lib/domain/shared/macros.dart` · Tests `test/domain/shared/meal_time_test.dart`, `test/domain/shared/grams_test.dart`, `test/domain/shared/macros_test.dart`
**Contract:** exactly the shapes below. No JSON. `Macros` gets `operator +` (used by nutrition sums later).
**Out of scope:** entities (Tasks 4–8); any calculation beyond `Macros.+`.

- [ ] **Step 1: Write the failing tests**

```dart
// test/domain/shared/meal_time_test.dart
import 'package:checks/checks.dart';
import 'package:crudo/domain/shared/meal_time.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('exposes hour and minute', () {
    const t = MealTime(485); // 08:05
    check(t.hour).equals(8);
    check(t.minute).equals(5);
    check(t.minutesOfDay).equals(485);
  });

  test('value equality + compareTo', () {
    check(const MealTime(480)).equals(const MealTime(480));
    check(const MealTime(480).compareTo(const MealTime(720))).isLessThan(0);
  });

  test('asserts 0..1439', () {
    check(() => MealTime(-1)).throws<AssertionError>();
    check(() => MealTime(1440)).throws<AssertionError>();
    check(MealTime(0).minutesOfDay).equals(0);
    check(MealTime(1439).hour).equals(23);
  });
}
```

```dart
// test/domain/shared/grams_test.dart
import 'package:checks/checks.dart';
import 'package:crudo/domain/shared/grams.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('holds value, equality, compareTo', () {
    check(const Grams(150).value).equals(150);
    check(const Grams(12.5)).equals(const Grams(12.5));
    check(const Grams(50).compareTo(const Grams(100))).isLessThan(0);
  });

  test('asserts > 0', () {
    check(() => Grams(0)).throws<AssertionError>();
    check(() => Grams(-10)).throws<AssertionError>();
  });
}
```

```dart
// test/domain/shared/macros_test.dart
import 'package:checks/checks.dart';
import 'package:crudo/domain/shared/macros.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('defaults to zero', () {
    const m = Macros();
    check(m.protein).equals(0);
    check(m.carbs).equals(0);
    check(m.fats).equals(0);
    check(m.kcal).equals(0);
  });

  test('value equality + copyWith', () {
    const m = Macros(protein: 10, carbs: 20, fats: 5, kcal: 165);
    check(m).equals(const Macros(protein: 10, carbs: 20, fats: 5, kcal: 165));
    check(m.copyWith(kcal: 200).protein).equals(10);
  });

  test('operator + sums componentwise', () {
    const a = Macros(protein: 10, carbs: 20, fats: 5, kcal: 165);
    const b = Macros(protein: 1, carbs: 2, fats: 3, kcal: 39);
    check(a + b).equals(const Macros(protein: 11, carbs: 22, fats: 8, kcal: 204));
  });
}
```

- [ ] **Step 2: Run — expect FAIL** (URIs don't exist)

Run: `flutter test test/domain/shared/`

- [ ] **Step 3: Create `lib/domain/shared/enums.dart`**

```dart
/// Per-day meal state — always DERIVED from checked flags + time (S05); never stored.
enum MealStatus { done, partial, upcoming, skipped }

/// Meal category tags; a meal may carry several.
enum MealTag { breakfast, lunch, dinner, snack, preWorkout, postWorkout }

/// Product library category. `custom` is the default for user-created products.
enum ProductCategory { meat, fish, eggs, grain, veg, fruit, oil, custom }

/// Profile goal — label only in v1 (no kcal target attached).
enum Goal { cut, maintain, bulk }

/// Display unit. Quantities are always stored as grams.
enum Unit { g, oz }

/// Reminder scheduling mode. `interval` is modeled now, v2-only.
enum ReminderMode { fixed, interval }

/// Day adherence verdict — derived live while open, frozen at midnight-lock (S12).
enum DayState { green, yellow, red }
```

- [ ] **Step 4: Create `lib/domain/shared/meal_time.dart`**

```dart
/// Time of day as minutes from midnight (0–1439). Pure value object — the UI
/// formats it; S05 maps it onto concrete schedule instants.
class MealTime implements Comparable<MealTime> {
  const MealTime(this.minutesOfDay)
      : assert(
          minutesOfDay >= 0 && minutesOfDay <= 1439,
          'minutesOfDay must be within 0..1439',
        );

  final int minutesOfDay;

  int get hour => minutesOfDay ~/ 60;
  int get minute => minutesOfDay % 60;

  @override
  int compareTo(MealTime other) => minutesOfDay.compareTo(other.minutesOfDay);

  @override
  bool operator ==(Object other) =>
      other is MealTime && other.minutesOfDay == minutesOfDay;

  @override
  int get hashCode => minutesOfDay.hashCode;

  @override
  String toString() =>
      'MealTime(${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')})';
}
```

- [ ] **Step 5: Create `lib/domain/shared/grams.dart`**

```dart
/// A quantity in grams. Must be positive — this constructor is the only door,
/// so a non-positive quantity is unrepresentable (forms validate input first).
class Grams implements Comparable<Grams> {
  const Grams(this.value) : assert(value > 0, 'grams must be > 0');

  final double value;

  @override
  int compareTo(Grams other) => value.compareTo(other.value);

  @override
  bool operator ==(Object other) => other is Grams && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'Grams($value)';
}
```

- [ ] **Step 6: Create `lib/domain/shared/macros.dart`**

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'macros.freezed.dart';

/// Derived macro totals (protein/carbs/fats grams + kcal). Never persisted —
/// always recomputed from products (architecture §6), hence no JSON.
@freezed
abstract class Macros with _$Macros {
  const Macros._();

  const factory Macros({
    @Default(0) double protein,
    @Default(0) double carbs,
    @Default(0) double fats,
    @Default(0) double kcal,
  }) = _Macros;

  Macros operator +(Macros other) => Macros(
        protein: protein + other.protein,
        carbs: carbs + other.carbs,
        fats: fats + other.fats,
        kcal: kcal + other.kcal,
      );
}
```

- [ ] **Step 7: Generate + test**

```bash
dart run build_runner build
flutter test test/domain/shared/
```
Expected: `macros.freezed.dart` written; all tests pass.

- [ ] **Step 8: Format + analyze**

Run: `dart format . && flutter analyze`
Expected: clean.

- [ ] **Step 9: Report** this task done for review (do **not** commit).

---

### Task 3: Architecture test (dependency rule, machine-enforced)

**Role:** implement · **Skills:** `dart-add-unit-test`
**Goal:** A test that fails if `lib/domain/` or `lib/utils/` imports anything outside its allowlist. Guards every later task automatically (pre-commit runs `flutter test`).
**Files:** Create `test/architecture/dependency_rules_test.dart`
**Contract:** `lib/domain` allowlist = `dart:`, `package:freezed_annotation/`, `package:crudo/domain/` (+ relative imports). `lib/utils` allowlist = `dart:` (+ relative). `*.freezed.dart` skipped (they are `part of` files). Missing layer dir = skipped, not failed.
**Out of scope:** rules for `data/`/`application/`/`ui/` (added when those layers land, S03+).

- [ ] **Step 1: Create the test**

```dart
// test/architecture/dependency_rules_test.dart
import 'dart:io';

import 'package:checks/checks.dart';
import 'package:flutter_test/flutter_test.dart';

/// The Clean dependency rule, executable (architecture.md §2).
/// Maps layer directory -> allowed `package:` import prefixes.
/// Relative imports (non-package URIs) are always allowed within a layer.
const Map<String, List<String>> allowedPackageImports = {
  'lib/domain': ['dart:', 'package:freezed_annotation/', 'package:crudo/domain/'],
  'lib/utils': ['dart:'],
};

void main() {
  allowedPackageImports.forEach((dir, allowlist) {
    test('$dir respects the dependency rule', () {
      final layer = Directory(dir);
      if (!layer.existsSync()) return; // layer not created yet

      final violations = <String>[];
      final files = layer
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) =>
              f.path.endsWith('.dart') && !f.path.endsWith('.freezed.dart'));

      for (final file in files) {
        final imports = RegExp(r'''^import\s+['"]([^'"]+)['"]''', multiLine: true)
            .allMatches(file.readAsStringSync())
            .map((m) => m.group(1)!);
        for (final uri in imports) {
          final isRelative = !uri.contains(':');
          final isAllowed = isRelative || allowlist.any(uri.startsWith);
          if (!isAllowed) violations.add('${file.path} -> $uri');
        }
      }

      check(
        because: 'forbidden imports:\n${violations.join('\n')}',
        violations,
      ).isEmpty();
    });
  });
}
```

- [ ] **Step 2: Run — expect PASS** (current domain/shared files are clean)

Run: `flutter test test/architecture/`

- [ ] **Step 3: Prove it catches violations** — temporarily add `import 'package:flutter/material.dart';` to `lib/domain/shared/enums.dart`, run the test, confirm it FAILS listing that import, then **revert the line** and confirm PASS again.

- [ ] **Step 4: Format + analyze**

Run: `dart format . && flutter analyze`

- [ ] **Step 5: Report** this task done for review (do **not** commit). Mention the violation drill result.

---

### Task 4: Product aggregate (`domain/product/`)

**Role:** implement · **Skills:** `dart-add-unit-test`, `dart-migrate-to-checks-package`
**Goal:** `Product` (library item) + `ProductRef` (template ingredient), with invariants.
**Files:** Create `lib/domain/product/product.dart`, `lib/domain/product/product_ref.dart` · Test `test/domain/product/product_test.dart`
**Contract:** shapes below; macros per-100g doubles `>= 0` (`@Assert`); `kcalOverride` nullable (±10 % rule is Tier-2, Task 10 — NOT asserted here); `isCustom` defaults false; `ProductRef.grams` is the `Grams` VO.
**Out of scope:** validation extensions (Task 10); kcal math (Task 9).

- [ ] **Step 1: Write the failing test**

```dart
// test/domain/product/product_test.dart
import 'package:checks/checks.dart';
import 'package:crudo/domain/product/product.dart';
import 'package:crudo/domain/product/product_ref.dart';
import 'package:crudo/domain/shared/enums.dart';
import 'package:crudo/domain/shared/grams.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const chicken = Product(
    id: '0197-aaaa',
    name: 'Chicken breast',
    category: ProductCategory.meat,
    protein: 31,
    carbs: 0,
    fats: 3.6,
  );

  test('defaults: not custom, no override', () {
    check(chicken.isCustom).isFalse();
    check(chicken.kcalOverride).isNull();
  });

  test('value equality + copyWith', () {
    check(chicken.copyWith(name: 'Chicken thigh').name).equals('Chicken thigh');
    check(chicken.copyWith(name: 'Chicken thigh').protein).equals(31);
  });

  test('asserts non-negative macros', () {
    check(() => Product(
          id: 'x',
          name: 'Bad',
          category: ProductCategory.custom,
          protein: -1,
          carbs: 0,
          fats: 0,
        )).throws<AssertionError>();
  });

  test('product ref holds Grams VO', () {
    const ref = ProductRef(productId: '0197-aaaa', grams: Grams(150));
    check(ref.grams.value).equals(150);
    check(ref).equals(const ProductRef(productId: '0197-aaaa', grams: Grams(150)));
  });
}
```

- [ ] **Step 2: Run — expect FAIL**

Run: `flutter test test/domain/product/`

- [ ] **Step 3: Create `lib/domain/product/product.dart`**

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

import '../shared/enums.dart';

part 'product.freezed.dart';

/// A product library item (template tree). Macros are per 100 g.
/// `id` is an app-generated uuid v7. Built-in seed products have
/// `isCustom == false`; user-created ones `true` (category is orthogonal).
/// The ±10% kcalOverride rule is user-facing validation (validators.dart).
@freezed
abstract class Product with _$Product {
  const Product._();

  @Assert('protein >= 0', 'protein must be >= 0')
  @Assert('carbs >= 0', 'carbs must be >= 0')
  @Assert('fats >= 0', 'fats must be >= 0')
  const factory Product({
    required String id,
    required String name,
    required ProductCategory category,
    required double protein,
    required double carbs,
    required double fats,
    double? kcalOverride,
    @Default(false) bool isCustom,
  }) = _Product;
}
```

- [ ] **Step 4: Create `lib/domain/product/product_ref.dart`**

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

import '../shared/grams.dart';

part 'product_ref.freezed.dart';

/// A product reference + amount inside a [MealTemplate] (template tree).
/// Macros are derived via the nutrition service, never stored.
@freezed
abstract class ProductRef with _$ProductRef {
  const ProductRef._();

  const factory ProductRef({
    required String productId,
    required Grams grams,
  }) = _ProductRef;
}
```

- [ ] **Step 5: Generate + test**

```bash
dart run build_runner build
flutter test test/domain/product/ test/architecture/
```
Expected: all pass (architecture test still green).

- [ ] **Step 6: Format + analyze** — `dart format . && flutter analyze` clean.

- [ ] **Step 7: Report** this task done for review (do **not** commit).

---

### Task 5: Meal aggregate (`domain/meal/`)

**Role:** implement · **Skills:** `dart-add-unit-test`, `dart-migrate-to-checks-package`
**Goal:** `MealTemplate` (time-free, reusable), `MealProduct` (detached snapshot product), `Meal` (instance scheduling wrapper — slot-stable id + time + snapshot content).
**Files:** Create `lib/domain/meal/meal_template.dart`, `lib/domain/meal/meal_product.dart`, `lib/domain/meal/meal.dart` · Test `test/domain/meal/meal_test.dart`
**Contract:** shapes below. `Meal` has **no status field** (derived, S05). `MealProduct` carries its own snapshot data + nullable `sourceProductId` back-ref + `checked` (default false). `MealTemplate` has **no time** (time lives on `PlanSlot`).
**Out of scope:** status derivation, checkAll/swap behavior methods (S05); macros (Task 9).

- [ ] **Step 1: Write the failing test**

```dart
// test/domain/meal/meal_test.dart
import 'package:checks/checks.dart';
import 'package:crudo/domain/meal/meal.dart';
import 'package:crudo/domain/meal/meal_product.dart';
import 'package:crudo/domain/meal/meal_template.dart';
import 'package:crudo/domain/shared/enums.dart';
import 'package:crudo/domain/shared/grams.dart';
import 'package:crudo/domain/shared/meal_time.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const eggs = MealProduct(
    sourceProductId: '0197-eggs',
    name: 'Eggs',
    category: ProductCategory.eggs,
    protein: 13,
    carbs: 1,
    fats: 11,
    grams: Grams(120),
  );

  test('meal template: time-free, defaults empty', () {
    const t = MealTemplate(id: 'mt1', name: 'Breakfast');
    check(t.tags).isEmpty();
    check(t.products).isEmpty();
  });

  test('meal product snapshot: defaults unchecked, keeps back-ref', () {
    check(eggs.checked).isFalse();
    check(eggs.sourceProductId).equals('0197-eggs');
    check(eggs.copyWith(checked: true).checked).isTrue();
  });

  test('meal product: detached snapshot may have no source', () {
    check(eggs.copyWith(sourceProductId: null).sourceProductId).isNull();
  });

  test('instance meal wraps time + snapshot products, no status field', () {
    const meal = Meal(
      id: 'm1',
      time: MealTime(480),
      sourceMealTemplateId: 'mt1',
      name: 'Breakfast',
      tags: [MealTag.breakfast],
      products: [eggs],
    );
    check(meal.time.hour).equals(8);
    check(meal.products.single.name).equals('Eggs');
    // content swap keeps the slot id (notifications key off it):
    final swapped = meal.copyWith(name: 'Restaurant', sourceMealTemplateId: null, products: []);
    check(swapped.id).equals('m1');
    check(swapped.time).equals(const MealTime(480));
  });

  test('asserts non-negative snapshot macros', () {
    check(() => MealProduct(
          name: 'Bad',
          category: ProductCategory.custom,
          protein: 0,
          carbs: -2,
          fats: 0,
          grams: Grams(10),
        )).throws<AssertionError>();
  });
}
```

- [ ] **Step 2: Run — expect FAIL**

Run: `flutter test test/domain/meal/`

- [ ] **Step 3: Create `lib/domain/meal/meal_template.dart`**

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

import '../product/product_ref.dart';
import '../shared/enums.dart';

part 'meal_template.freezed.dart';

/// A reusable meal recipe (template tree): products + tags, deliberately
/// time-free — WHEN it is eaten belongs to the plan ([PlanSlot.time]).
@freezed
abstract class MealTemplate with _$MealTemplate {
  const MealTemplate._();

  const factory MealTemplate({
    required String id,
    required String name,
    @Default(<MealTag>[]) List<MealTag> tags,
    @Default(<ProductRef>[]) List<ProductRef> products,
  }) = _MealTemplate;
}
```

- [ ] **Step 4: Create `lib/domain/meal/meal_product.dart`**

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

import '../shared/enums.dart';
import '../shared/grams.dart';

part 'meal_product.freezed.dart';

/// A snapshotted product inside an instance [Meal] (instance tree). Carries its
/// own name + per-100g macros so later library edits/deletes never alter this
/// day (architecture §8). `sourceProductId` is a weak back-ref only — nothing
/// about display or calculation depends on it.
@freezed
abstract class MealProduct with _$MealProduct {
  const MealProduct._();

  @Assert('protein >= 0', 'protein must be >= 0')
  @Assert('carbs >= 0', 'carbs must be >= 0')
  @Assert('fats >= 0', 'fats must be >= 0')
  const factory MealProduct({
    String? sourceProductId,
    required String name,
    required ProductCategory category,
    required double protein,
    required double carbs,
    required double fats,
    double? kcalOverride,
    required Grams grams,
    @Default(false) bool checked,
  }) = _MealProduct;
}
```

- [ ] **Step 5: Create `lib/domain/meal/meal.dart`**

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

import '../shared/enums.dart';
import '../shared/meal_time.dart';
import 'meal_product.dart';

part 'meal.freezed.dart';

/// An instance meal — the scheduling WRAPPER (instance tree): a slot-stable
/// `id` + `time` + detached snapshot content. Notifications and "this meal"
/// references key off `id`; swapping the content (grams edits, product swaps,
/// whole-meal swaps) keeps `id` and `time` — only `sourceMealTemplateId`,
/// `name`, `tags`, `products` change. Status is DERIVED (checked flags + time,
/// S05) and deliberately not a field.
@freezed
abstract class Meal with _$Meal {
  const Meal._();

  const factory Meal({
    required String id,
    required MealTime time,
    String? sourceMealTemplateId,
    required String name,
    @Default(<MealTag>[]) List<MealTag> tags,
    @Default(<MealProduct>[]) List<MealProduct> products,
  }) = _Meal;
}
```

- [ ] **Step 6: Generate + test**

```bash
dart run build_runner build
flutter test test/domain/ test/architecture/
```

- [ ] **Step 7: Format + analyze** — clean.

- [ ] **Step 8: Report** this task done for review (do **not** commit).

---

### Task 6: Plan aggregate (`domain/plan/`)

**Role:** implement · **Skills:** `dart-add-unit-test`, `dart-migrate-to-checks-package`
**Goal:** `PlanSlot` (meal-template ref + time) and `PlanTemplate` (weekday-assigned ordered slots).
**Files:** Create `lib/domain/plan/plan_slot.dart`, `lib/domain/plan/plan_template.dart` · Test `test/domain/plan/plan_test.dart`
**Contract:** shapes below; `days` are weekday indices 0=Mon…6=Sun (`@Assert` each in range; uniqueness is Tier-2). Display tag is derived (goal + Σ kcal) — **no tag/goal field**.
**Out of scope:** scheduling/conflict logic (S09); validation extensions (Task 10).

- [ ] **Step 1: Write the failing test**

```dart
// test/domain/plan/plan_test.dart
import 'package:checks/checks.dart';
import 'package:crudo/domain/plan/plan_slot.dart';
import 'package:crudo/domain/plan/plan_template.dart';
import 'package:crudo/domain/shared/meal_time.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const slot = PlanSlot(id: 's1', mealTemplateId: 'mt1', time: MealTime(480));

  test('slot binds meal template to a time', () {
    check(slot.time.hour).equals(8);
    check(slot).equals(const PlanSlot(id: 's1', mealTemplateId: 'mt1', time: MealTime(480)));
  });

  test('plan defaults: unassigned, active, no slots', () {
    const p = PlanTemplate(id: 'p1', name: 'Cut');
    check(p.days).isEmpty();
    check(p.active).isTrue();
    check(p.slots).isEmpty();
  });

  test('plan holds ordered slots + weekdays', () {
    const p = PlanTemplate(
      id: 'p2',
      name: 'Weekday cut',
      days: [0, 1, 2, 3, 4],
      slots: [slot],
    );
    check(p.days).deepEquals([0, 1, 2, 3, 4]);
    check(p.slots.single.mealTemplateId).equals('mt1');
    check(p.copyWith(active: false).active).isFalse();
  });

  test('asserts weekday range 0..6', () {
    check(() => PlanTemplate(id: 'p3', name: 'Bad', days: [7]))
        .throws<AssertionError>();
    check(() => PlanTemplate(id: 'p4', name: 'Bad', days: [-1]))
        .throws<AssertionError>();
  });
}
```

- [ ] **Step 2: Run — expect FAIL**

Run: `flutter test test/domain/plan/`

- [ ] **Step 3: Create `lib/domain/plan/plan_slot.dart`**

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

import '../shared/meal_time.dart';

part 'plan_slot.freezed.dart';

/// A slot in a [PlanTemplate]: WHICH meal template at WHAT time. Time lives
/// here (not on the meal) so one template is reusable at different times
/// across plans. Materialization (S05) turns a slot into an instance Meal.
@freezed
abstract class PlanSlot with _$PlanSlot {
  const PlanSlot._();

  const factory PlanSlot({
    required String id,
    required String mealTemplateId,
    required MealTime time,
  }) = _PlanSlot;
}
```

- [ ] **Step 4: Create `lib/domain/plan/plan_template.dart`**

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

import 'plan_slot.dart';

part 'plan_template.freezed.dart';

/// A plan template (factory): ordered meal slots assigned to weekdays.
/// Edits affect future days only (architecture §8). `days` are 0=Mon … 6=Sun;
/// `[]` = unassigned. The display tag ('CUT · 2200 KCAL') is derived — profile
/// goal + computed planned kcal — never stored.
@freezed
abstract class PlanTemplate with _$PlanTemplate {
  const PlanTemplate._();

  @Assert('days.every((d) => d >= 0 && d <= 6)', 'weekdays must be 0..6')
  const factory PlanTemplate({
    required String id,
    required String name,
    @Default(<int>[]) List<int> days,
    @Default(true) bool active,
    @Default(<PlanSlot>[]) List<PlanSlot> slots,
  }) = _PlanTemplate;
}
```

- [ ] **Step 5: Generate + test**

```bash
dart run build_runner build
flutter test test/domain/ test/architecture/
```

- [ ] **Step 6: Format + analyze** — clean.

- [ ] **Step 7: Report** this task done for review (do **not** commit).

---

### Task 7: Day aggregate (`domain/day/`)

**Role:** implement · **Skills:** `dart-add-unit-test`, `dart-migrate-to-checks-package`
**Goal:** `Day` — the materialized-day aggregate root: one type for today/future/history; adherence verdict frozen at lock.
**Files:** Create `lib/domain/day/day.dart` · Test `test/domain/day/day_test.dart`
**Contract:** shape below. `date` is a **local-calendar-date label encoded as UTC midnight** (`DateTime.utc(y,m,d)`) — asserted. `adherence` + `state` null while open, set together at midnight-lock — asserted. Weak back-refs `sourcePlanId`/`planName` nullable.
**Out of scope:** materialization, behavior methods (`markMealEaten`, lock) — S05/S12.

- [ ] **Step 1: Write the failing test**

```dart
// test/domain/day/day_test.dart
import 'package:checks/checks.dart';
import 'package:crudo/domain/day/day.dart';
import 'package:crudo/domain/shared/enums.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('open day: no verdict, defaults empty', () {
    final d = Day(date: DateTime.utc(2026, 6, 3));
    check(d.adherence).isNull();
    check(d.state).isNull();
    check(d.meals).isEmpty();
    check(d.sourcePlanId).isNull();
  });

  test('locked day carries frozen verdict', () {
    final d = Day(date: DateTime.utc(2026, 6, 2), adherence: 0.85, state: DayState.green);
    check(d.adherence).equals(0.85);
    check(d.state).equals(DayState.green);
  });

  test('asserts date is a UTC-midnight label', () {
    check(() => Day(date: DateTime(2026, 6, 3))).throws<AssertionError>();          // local
    check(() => Day(date: DateTime.utc(2026, 6, 3, 14))).throws<AssertionError>();  // not midnight
  });

  test('asserts adherence and state freeze together, adherence in [0,1]', () {
    check(() => Day(date: DateTime.utc(2026, 6, 2), adherence: 0.5))
        .throws<AssertionError>(); // adherence without state
    check(() => Day(date: DateTime.utc(2026, 6, 2), state: DayState.red))
        .throws<AssertionError>(); // state without adherence
    check(() => Day(date: DateTime.utc(2026, 6, 2), adherence: 1.2, state: DayState.green))
        .throws<AssertionError>(); // out of range
  });
}
```

- [ ] **Step 2: Run — expect FAIL**

Run: `flutter test test/domain/day/`

- [ ] **Step 3: Create `lib/domain/day/day.dart`**

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

import '../meal/meal.dart';
import '../shared/enums.dart';

part 'day.freezed.dart';

/// A materialized day (instance tree, aggregate root): the user's local
/// calendar date + that day's snapshot meals. ONE type serves today, future,
/// and history — "locked" is derived from the date (past = locked at local
/// midnight, S05). `adherence` + `state` are null while the day is open and
/// written exactly once at midnight-lock (S12), so later threshold changes
/// can't recolor history. `date` is a date LABEL: the local calendar date
/// encoded as DateTime.utc(y, m, d). Real instants elsewhere are true UTC.
@freezed
abstract class Day with _$Day {
  const Day._();

  @Assert('date.isUtc', 'date must be the UTC-encoded local-date label')
  @Assert(
    'date.hour == 0 && date.minute == 0 && date.second == 0 && date.millisecond == 0 && date.microsecond == 0',
    'date must be midnight-normalized',
  )
  @Assert('(adherence == null) == (state == null)',
      'adherence and state are frozen together at lock')
  @Assert('adherence == null || (adherence >= 0 && adherence <= 1)',
      'adherence must be within [0,1]')
  const factory Day({
    required DateTime date,
    String? sourcePlanId,
    String? planName,
    @Default(<Meal>[]) List<Meal> meals,
    double? adherence,
    DayState? state,
  }) = _Day;
}
```

- [ ] **Step 4: Generate + test**

```bash
dart run build_runner build
flutter test test/domain/ test/architecture/
```

- [ ] **Step 5: Format + analyze** — clean.

- [ ] **Step 6: Report** this task done for review (do **not** commit).

---

### Task 8: Profile + Streak (`domain/profile/`, `domain/streak/`)

**Role:** implement · **Skills:** `dart-add-unit-test`, `dart-migrate-to-checks-package`
**Goal:** `Prefs`, `UserProfile`, `Streak` with defaults + invariants.
**Files:** Create `lib/domain/profile/prefs.dart`, `lib/domain/profile/user_profile.dart`, `lib/domain/streak/streak.dart` · Tests `test/domain/profile/profile_test.dart`, `test/domain/streak/streak_test.dart`
**Contract:** shapes below. `dailyKcalTarget` nullable int — **guidance only** (never the adherence denominator). Threshold set membership is Tier-2 (Task 10).
**Out of scope:** streak transitions/milestones (S12); auth fields (S22).

- [ ] **Step 1: Write the failing tests**

```dart
// test/domain/profile/profile_test.dart
import 'package:checks/checks.dart';
import 'package:crudo/domain/profile/prefs.dart';
import 'package:crudo/domain/profile/user_profile.dart';
import 'package:crudo/domain/shared/enums.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('prefs defaults match spec', () {
    const p = Prefs();
    check(p.goal).equals(Goal.maintain);
    check(p.units).equals(Unit.g);
    check(p.dailyKcalTarget).isNull();
    check(p.streakThreshold).equals(80);
    check(p.reminderMode).equals(ReminderMode.fixed);
    check(p.preOn).isTrue();
    check(p.atOn).isTrue();
    check(p.eodOn).isTrue();
    check(p.riskOn).isTrue();
    check(p.preMin).equals(30);
  });

  test('prefs asserts preMin >= 0', () {
    check(() => Prefs(preMin: -1)).throws<AssertionError>();
  });

  test('profile defaults prefs, allows display name', () {
    const u = UserProfile(id: 'u1');
    check(u.prefs).equals(const Prefs());
    check(u.displayName).isNull();
    check(u.copyWith(displayName: 'Rost').displayName).equals('Rost');
  });
}
```

```dart
// test/domain/streak/streak_test.dart
import 'package:checks/checks.dart';
import 'package:crudo/domain/streak/streak.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('defaults to zero, no last day', () {
    const s = Streak();
    check(s.current).equals(0);
    check(s.personalBest).equals(0);
    check(s.lastCountedDay).isNull();
  });

  test('asserts non-negative and best >= current', () {
    check(() => Streak(current: -1)).throws<AssertionError>();
    check(() => Streak(current: 5, personalBest: 3)).throws<AssertionError>();
  });

  test('valid streak', () {
    final s = Streak(current: 5, personalBest: 12, lastCountedDay: DateTime.utc(2026, 6, 2));
    check(s.personalBest).equals(12);
  });
}
```

- [ ] **Step 2: Run — expect FAIL**

Run: `flutter test test/domain/profile/ test/domain/streak/`

- [ ] **Step 3: Create `lib/domain/profile/prefs.dart`**

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

import '../shared/enums.dart';

part 'prefs.freezed.dart';

/// User settings. `dailyKcalTarget` is the onboarding "how many calories a
/// day?" number — build-time GUIDANCE only; adherence is always computed
/// consumed ÷ planned-products (architecture §10), never against this target.
/// `streakThreshold` is the green line (70/80/90/100, default 80); red floor
/// fixed at 50, not stored. Set membership is user-facing validation.
@freezed
abstract class Prefs with _$Prefs {
  const Prefs._();

  @Assert('preMin >= 0', 'preMin must be >= 0')
  const factory Prefs({
    @Default(Goal.maintain) Goal goal,
    @Default(Unit.g) Unit units,
    int? dailyKcalTarget,
    @Default(80) int streakThreshold,
    @Default(ReminderMode.fixed) ReminderMode reminderMode,
    @Default(true) bool preOn,
    @Default(true) bool atOn,
    @Default(true) bool eodOn,
    @Default(true) bool riskOn,
    @Default(30) int preMin,
  }) = _Prefs;
}
```

- [ ] **Step 4: Create `lib/domain/profile/user_profile.dart`**

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

import 'prefs.dart';

part 'user_profile.freezed.dart';

/// The per-user root that scopes repositories (S03). Auth/identity fields
/// arrive with S22 — for now an id, optional display name, and settings.
@freezed
abstract class UserProfile with _$UserProfile {
  const UserProfile._();

  const factory UserProfile({
    required String id,
    String? displayName,
    @Default(Prefs()) Prefs prefs,
  }) = _UserProfile;
}
```

- [ ] **Step 5: Create `lib/domain/streak/streak.dart`**

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'streak.freezed.dart';

/// Calorie-based streak state (architecture §10). Shape only — +1/hold/reset
/// transitions and milestone badges (7/30/100) are S12. `lastCountedDay` is a
/// UTC-encoded local-date label, used for reset detection.
@freezed
abstract class Streak with _$Streak {
  const Streak._();

  @Assert('current >= 0', 'current must be >= 0')
  @Assert('personalBest >= 0', 'personalBest must be >= 0')
  @Assert('personalBest >= current', 'personalBest cannot be below current')
  const factory Streak({
    @Default(0) int current,
    @Default(0) int personalBest,
    DateTime? lastCountedDay,
  }) = _Streak;
}
```

- [ ] **Step 6: Generate + test**

```bash
dart run build_runner build
flutter test test/domain/ test/architecture/
```

- [ ] **Step 7: Format + analyze** — clean.

- [ ] **Step 8: Report** this task done for review (do **not** commit).

---

### Task 9: Nutrition domain service (`domain/services/nutrition.dart`)

**Role:** implement · **Skills:** `dart-add-unit-test`, `dart-migrate-to-checks-package`, `dart-use-pattern-matching`
**Goal:** All nutrition math as pure domain functions — the kcal formula, ±10 % override rule, effective kcal, product/meal/template macro sums.
**Files:** Create `lib/domain/services/nutrition.dart` · Test `test/domain/services/nutrition_test.dart`
**Contract:** exact signatures below; planned = all products, consumed = checked only; template preview skips unresolved product ids.
**Out of scope:** adherence ratio → `DayState` (S12); `MealStatus` (S05).

- [ ] **Step 1: Write the failing test**

```dart
// test/domain/services/nutrition_test.dart
import 'package:checks/checks.dart';
import 'package:crudo/domain/meal/meal.dart';
import 'package:crudo/domain/meal/meal_product.dart';
import 'package:crudo/domain/meal/meal_template.dart';
import 'package:crudo/domain/product/product.dart';
import 'package:crudo/domain/product/product_ref.dart';
import 'package:crudo/domain/services/nutrition.dart';
import 'package:crudo/domain/shared/enums.dart';
import 'package:crudo/domain/shared/grams.dart';
import 'package:crudo/domain/shared/meal_time.dart';
import 'package:flutter_test/flutter_test.dart';

MealProduct _snap(String name,
        {double p = 0, double c = 0, double f = 0, double? kcal, double g = 100, bool checked = false}) =>
    MealProduct(
      name: name,
      category: ProductCategory.custom,
      protein: p,
      carbs: c,
      fats: f,
      kcalOverride: kcal,
      grams: Grams(g),
      checked: checked,
    );

void main() {
  test('calculatedKcal applies 4/4/9', () {
    check(calculatedKcal(protein: 20, carbs: 30, fats: 10)).equals(290);
    check(calculatedKcal(protein: 0, carbs: 0, fats: 0)).equals(0);
  });

  test('isKcalOverrideValid: ±10% boundaries', () {
    check(isKcalOverrideValid(calculated: 100, override: 110)).isTrue();
    check(isKcalOverrideValid(calculated: 100, override: 111)).isFalse();
    check(isKcalOverrideValid(calculated: 100, override: 90)).isTrue();
    check(isKcalOverrideValid(calculated: 100, override: 89)).isFalse();
    check(isKcalOverrideValid(calculated: 0, override: 0)).isTrue();
    check(isKcalOverrideValid(calculated: 0, override: 1)).isFalse();
  });

  test('effectiveKcalPer100g: valid override honored, invalid ignored', () {
    // calc = 20*4 + 30*4 + 10*9 = 290
    check(effectiveKcalPer100g(protein: 20, carbs: 30, fats: 10, kcalOverride: 300)).equals(300);
    check(effectiveKcalPer100g(protein: 20, carbs: 30, fats: 10, kcalOverride: 400)).equals(290);
    check(effectiveKcalPer100g(protein: 20, carbs: 30, fats: 10)).equals(290);
  });

  test('macrosForProduct scales by grams/100 (integer-clean → exact)', () {
    final m = macrosForProduct(_snap('a', p: 30, c: 0, f: 10, g: 200));
    check(m.protein).equals(60);
    check(m.fats).equals(20);
    check(m.kcal).equals(420); // (30*4 + 10*9) * 2
  });

  test('mealMacros sums all; consumedMacros sums checked only', () {
    final meal = Meal(
      id: 'm1',
      time: const MealTime(720),
      name: 'Lunch',
      products: [
        _snap('chicken', p: 31, f: 4, checked: true),
        _snap('rice', c: 23),
      ],
    );
    check(mealMacros(meal).protein).equals(31);
    check(mealMacros(meal).carbs).equals(23);
    check(consumedMacros(meal).protein).equals(31);
    check(consumedMacros(meal).carbs).equals(0);
  });

  test('mealTemplateMacros resolves via map, skips unresolved ids', () {
    const products = {
      'p1': Product(id: 'p1', name: 'Chicken', category: ProductCategory.meat, protein: 31, carbs: 0, fats: 4),
    };
    const template = MealTemplate(id: 'mt1', name: 'Lunch', products: [
      ProductRef(productId: 'p1', grams: Grams(100)),
      ProductRef(productId: 'missing', grams: Grams(100)),
    ]);
    final m = mealTemplateMacros(template, products);
    check(m.protein).equals(31);
    check(m.kcal).equals(160); // 31*4 + 4*9
  });
}
```

- [ ] **Step 2: Run — expect FAIL**

Run: `flutter test test/domain/services/`

- [ ] **Step 3: Create `lib/domain/services/nutrition.dart`**

```dart
import '../meal/meal.dart';
import '../meal/meal_product.dart';
import '../meal/meal_template.dart';
import '../product/product.dart';
import '../shared/macros.dart';

/// Nutrition rules (domain service — pure functions). Single source of truth:
/// totals are always recomputed from products, never stored (architecture §6).

/// Atwater factors: protein 4, carbs 4, fats 9 kcal per gram.
double calculatedKcal({
  required double protein,
  required double carbs,
  required double fats,
}) =>
    protein * 4 + carbs * 4 + fats * 9;

/// A manual kcal override is accepted only within ±[tolerance] (default 10%)
/// of the calculated value. Non-positive calculated → only 0 is valid.
bool isKcalOverrideValid({
  required double calculated,
  required double override,
  double tolerance = 0.10,
}) {
  if (calculated <= 0) return override == 0;
  return (override - calculated).abs() <= calculated * tolerance;
}

/// Effective per-100g kcal: a VALID override wins, otherwise calculated.
double effectiveKcalPer100g({
  required double protein,
  required double carbs,
  required double fats,
  double? kcalOverride,
}) {
  final calculated =
      calculatedKcal(protein: protein, carbs: carbs, fats: fats);
  if (kcalOverride != null &&
      isKcalOverrideValid(calculated: calculated, override: kcalOverride)) {
    return kcalOverride;
  }
  return calculated;
}

/// Macros of one snapshot product = per-100g values × grams / 100.
Macros macrosForProduct(MealProduct product) {
  final factor = product.grams.value / 100.0;
  return Macros(
    protein: product.protein * factor,
    carbs: product.carbs * factor,
    fats: product.fats * factor,
    kcal: effectiveKcalPer100g(
          protein: product.protein,
          carbs: product.carbs,
          fats: product.fats,
          kcalOverride: product.kcalOverride,
        ) *
        factor,
  );
}

/// Planned macros of an instance meal = Σ all products (self-contained — the
/// snapshot needs no library lookup).
Macros mealMacros(Meal meal) =>
    meal.products.fold(const Macros(), (total, p) => total + macrosForProduct(p));

/// Consumed macros = Σ checked products only.
Macros consumedMacros(Meal meal) => meal.products
    .where((p) => p.checked)
    .fold(const Macros(), (total, p) => total + macrosForProduct(p));

/// Preview macros of a meal TEMPLATE — needs the product library to resolve
/// refs. An unresolved productId is skipped (libraries are soft-deleted, S19).
Macros mealTemplateMacros(
  MealTemplate template,
  Map<String, Product> productsById,
) {
  var total = const Macros();
  for (final ref in template.products) {
    final product = productsById[ref.productId];
    if (product == null) continue;
    final factor = ref.grams.value / 100.0;
    total = total +
        Macros(
          protein: product.protein * factor,
          carbs: product.carbs * factor,
          fats: product.fats * factor,
          kcal: effectiveKcalPer100g(
                protein: product.protein,
                carbs: product.carbs,
                fats: product.fats,
                kcalOverride: product.kcalOverride,
              ) *
              factor,
        );
  }
  return total;
}
```

- [ ] **Step 4: Run — expect PASS**

Run: `flutter test test/domain/services/ test/architecture/`

- [ ] **Step 5: Format + analyze** — clean.

- [ ] **Step 6: Report** this task done for review (do **not** commit).

---

### Task 10: Validation (`domain/validation/`)

**Role:** implement · **Skills:** `dart-add-unit-test`, `dart-migrate-to-checks-package`
**Goal:** Tier-2 user-facing validation: `ValidationIssue` + `ValidationCode`, and `validate()` extension methods per entity. Called at save boundaries; never throws.
**Files:** Create `lib/domain/validation/validation_issue.dart`, `lib/domain/validation/validators.dart` · Test `test/domain/validation/validators_test.dart`
**Contract:** every rule from the spec table; each failing rule yields one issue with the exact code below. ±10 % + macro-mass use the nutrition service. Macro-mass tolerance: fail when `protein + carbs + fats > 101`.
**Out of scope:** cross-aggregate rules (weekday conflicts across plans — S09 domain service); localization (UI maps codes).

- [ ] **Step 1: Write the failing test**

```dart
// test/domain/validation/validators_test.dart
import 'package:checks/checks.dart';
import 'package:crudo/domain/day/day.dart';
import 'package:crudo/domain/meal/meal.dart';
import 'package:crudo/domain/meal/meal_product.dart';
import 'package:crudo/domain/meal/meal_template.dart';
import 'package:crudo/domain/plan/plan_slot.dart';
import 'package:crudo/domain/plan/plan_template.dart';
import 'package:crudo/domain/product/product.dart';
import 'package:crudo/domain/profile/prefs.dart';
import 'package:crudo/domain/profile/user_profile.dart';
import 'package:crudo/domain/shared/enums.dart';
import 'package:crudo/domain/shared/grams.dart';
import 'package:crudo/domain/shared/meal_time.dart';
import 'package:crudo/domain/validation/validation_issue.dart';
import 'package:crudo/domain/validation/validators.dart';
import 'package:flutter_test/flutter_test.dart';

Product _product({String name = 'Chicken', double p = 20, double c = 30, double f = 10, double? kcal}) =>
    Product(id: 'x', name: name, category: ProductCategory.meat, protein: p, carbs: c, fats: f, kcalOverride: kcal);

Meal _meal({String id = 'm1', String name = 'Lunch', List<MealProduct> products = const []}) =>
    Meal(id: id, time: const MealTime(720), name: name, products: products);

const _snap = MealProduct(
    name: 'Eggs', category: ProductCategory.eggs, protein: 13, carbs: 1, fats: 11, grams: Grams(100));

void main() {
  List<ValidationCode> codes(List<ValidationIssue> issues) => issues.map((i) => i.code).toList();

  test('valid product → no issues', () {
    check(_product(kcal: 300).validate()).isEmpty(); // calc 290, within 10%
  });

  test('product: blank name', () {
    check(codes(_product(name: '  ').validate())).contains(ValidationCode.blankName);
  });

  test('product: kcal override out of ±10%', () {
    check(codes(_product(kcal: 400).validate())).contains(ValidationCode.kcalOverrideOutOfRange);
    check(codes(_product(kcal: -5).validate())).contains(ValidationCode.kcalOverrideOutOfRange);
  });

  test('product: macro mass > 100g per 100g (±1g tolerance)', () {
    check(codes(_product(p: 60, c: 50, f: 0).validate())).contains(ValidationCode.macroMassExceeded);
    check(_product(p: 60, c: 40, f: 0.9).validate()).isEmpty(); // 100.9 ≤ 101 ok
  });

  test('meal product snapshot: same rules apply', () {
    final bad = _snap.copyWith(name: '', kcalOverride: 999);
    check(codes(bad.validate()))
      ..contains(ValidationCode.blankName)
      ..contains(ValidationCode.kcalOverrideOutOfRange);
  });

  test('meal template / instance meal: blank name + empty products', () {
    check(codes(const MealTemplate(id: 't', name: '').validate()))
      ..contains(ValidationCode.blankName)
      ..contains(ValidationCode.emptyMeal);
    check(codes(_meal(name: ' ').validate()))
      ..contains(ValidationCode.blankName)
      ..contains(ValidationCode.emptyMeal);
    check(_meal(products: [_snap]).validate()).isEmpty();
  });

  test('plan slot: blank meal template id', () {
    check(codes(const PlanSlot(id: 's', mealTemplateId: '', time: MealTime(480)).validate()))
        .contains(ValidationCode.blankMealTemplateId);
  });

  test('plan template: duplicates + empty active plan', () {
    const slot = PlanSlot(id: 's', mealTemplateId: 'mt', time: MealTime(480));
    check(codes(const PlanTemplate(id: 'p', name: 'Cut', days: [1, 1]).validate()))
        .contains(ValidationCode.duplicateWeekday);
    check(codes(const PlanTemplate(id: 'p', name: 'Cut').validate()))
        .contains(ValidationCode.emptyActivePlan);
    check(const PlanTemplate(id: 'p', name: 'Cut', active: false).validate())
        .isEmpty(); // inactive may be slotless
    check(const PlanTemplate(id: 'p', name: 'Cut', days: [0, 1], slots: [slot]).validate())
        .isEmpty();
  });

  test('day: duplicate meal ids', () {
    final d = Day(date: DateTime.utc(2026, 6, 3), meals: [_meal(products: [_snap]), _meal(products: [_snap])]);
    check(codes(d.validate())).contains(ValidationCode.duplicateMealId);
  });

  test('prefs: threshold set, target, preMin cap', () {
    check(codes(const Prefs(streakThreshold: 75).validate())).contains(ValidationCode.invalidThreshold);
    check(codes(const Prefs(dailyKcalTarget: 0).validate())).contains(ValidationCode.nonPositiveTarget);
    check(codes(const Prefs(preMin: 500).validate())).contains(ValidationCode.preMinTooLarge);
    check(const Prefs(dailyKcalTarget: 2200).validate()).isEmpty();
  });

  test('user profile: blank id', () {
    check(codes(const UserProfile(id: ' ').validate())).contains(ValidationCode.blankId);
  });
}
```

- [ ] **Step 2: Run — expect FAIL**

Run: `flutter test test/domain/validation/`

- [ ] **Step 3: Create `lib/domain/validation/validation_issue.dart`**

```dart
/// Machine-readable reason a save-time validation failed. The UI maps [code]
/// to localized text; [message] is a developer-readable fallback.
enum ValidationCode {
  blankName,
  blankId,
  blankMealTemplateId,
  kcalOverrideOutOfRange,
  macroMassExceeded,
  emptyMeal,
  emptyActivePlan,
  invalidThreshold,
  nonPositiveTarget,
  preMinTooLarge,
  duplicateMealId,
  duplicateWeekday,
}

class ValidationIssue {
  const ValidationIssue({
    required this.field,
    required this.code,
    required this.message,
  });

  final String field;
  final ValidationCode code;
  final String message;

  @override
  bool operator ==(Object other) =>
      other is ValidationIssue &&
      other.field == field &&
      other.code == code &&
      other.message == message;

  @override
  int get hashCode => Object.hash(field, code, message);

  @override
  String toString() => 'ValidationIssue($field, $code, $message)';
}
```

- [ ] **Step 4: Create `lib/domain/validation/validators.dart`**

```dart
import '../day/day.dart';
import '../meal/meal.dart';
import '../meal/meal_product.dart';
import '../meal/meal_template.dart';
import '../plan/plan_slot.dart';
import '../plan/plan_template.dart';
import '../product/product.dart';
import '../profile/prefs.dart';
import '../profile/user_profile.dart';
import '../services/nutrition.dart';
import 'validation_issue.dart';

/// Tier-2 (user-facing) validation: called at SAVE boundaries by forms/repos.
/// Returns issues instead of throwing — mid-edit drafts are allowed.
/// Tier-1 impossible states are guarded by @Assert on the types themselves.

const _allowedThresholds = {70, 80, 90, 100};
const _macroMassLimit = 101.0; // 100 g per 100 g + 1 g rounding tolerance

List<ValidationIssue> _macroRules({
  required String name,
  required double protein,
  required double carbs,
  required double fats,
  required double? kcalOverride,
}) {
  final issues = <ValidationIssue>[];
  if (name.trim().isEmpty) {
    issues.add(const ValidationIssue(
      field: 'name',
      code: ValidationCode.blankName,
      message: 'Name must not be blank',
    ));
  }
  if (kcalOverride != null) {
    final calculated =
        calculatedKcal(protein: protein, carbs: carbs, fats: fats);
    final valid = kcalOverride >= 0 &&
        isKcalOverrideValid(calculated: calculated, override: kcalOverride);
    if (!valid) {
      issues.add(const ValidationIssue(
        field: 'kcalOverride',
        code: ValidationCode.kcalOverrideOutOfRange,
        message: 'kcal override must be within ±10% of the calculated value',
      ));
    }
  }
  if (protein + carbs + fats > _macroMassLimit) {
    issues.add(const ValidationIssue(
      field: 'macros',
      code: ValidationCode.macroMassExceeded,
      message: 'protein + carbs + fats cannot exceed 100 g per 100 g',
    ));
  }
  return issues;
}

extension ProductValidation on Product {
  List<ValidationIssue> validate() => _macroRules(
        name: name,
        protein: protein,
        carbs: carbs,
        fats: fats,
        kcalOverride: kcalOverride,
      );
}

extension MealProductValidation on MealProduct {
  List<ValidationIssue> validate() => _macroRules(
        name: name,
        protein: protein,
        carbs: carbs,
        fats: fats,
        kcalOverride: kcalOverride,
      );
}

extension MealTemplateValidation on MealTemplate {
  List<ValidationIssue> validate() => [
        if (name.trim().isEmpty)
          const ValidationIssue(
            field: 'name',
            code: ValidationCode.blankName,
            message: 'Meal name must not be blank',
          ),
        if (products.isEmpty)
          const ValidationIssue(
            field: 'products',
            code: ValidationCode.emptyMeal,
            message: 'A meal must contain at least one product',
          ),
      ];
}

extension MealValidation on Meal {
  List<ValidationIssue> validate() => [
        if (name.trim().isEmpty)
          const ValidationIssue(
            field: 'name',
            code: ValidationCode.blankName,
            message: 'Meal name must not be blank',
          ),
        if (products.isEmpty)
          const ValidationIssue(
            field: 'products',
            code: ValidationCode.emptyMeal,
            message: 'A meal must contain at least one product',
          ),
      ];
}

extension PlanSlotValidation on PlanSlot {
  List<ValidationIssue> validate() => [
        if (mealTemplateId.trim().isEmpty)
          const ValidationIssue(
            field: 'mealTemplateId',
            code: ValidationCode.blankMealTemplateId,
            message: 'A slot must reference a meal template',
          ),
      ];
}

extension PlanTemplateValidation on PlanTemplate {
  List<ValidationIssue> validate() => [
        if (name.trim().isEmpty)
          const ValidationIssue(
            field: 'name',
            code: ValidationCode.blankName,
            message: 'Plan name must not be blank',
          ),
        if (days.toSet().length != days.length)
          const ValidationIssue(
            field: 'days',
            code: ValidationCode.duplicateWeekday,
            message: 'Weekdays must be unique',
          ),
        if (active && slots.isEmpty)
          const ValidationIssue(
            field: 'slots',
            code: ValidationCode.emptyActivePlan,
            message: 'An active plan must have at least one meal slot',
          ),
      ];
}

extension DayValidation on Day {
  List<ValidationIssue> validate() => [
        if (meals.map((m) => m.id).toSet().length != meals.length)
          const ValidationIssue(
            field: 'meals',
            code: ValidationCode.duplicateMealId,
            message: 'Meal ids within a day must be unique',
          ),
      ];
}

extension PrefsValidation on Prefs {
  List<ValidationIssue> validate() => [
        if (!_allowedThresholds.contains(streakThreshold))
          const ValidationIssue(
            field: 'streakThreshold',
            code: ValidationCode.invalidThreshold,
            message: 'Threshold must be one of 70, 80, 90, 100',
          ),
        if (dailyKcalTarget != null && dailyKcalTarget! <= 0)
          const ValidationIssue(
            field: 'dailyKcalTarget',
            code: ValidationCode.nonPositiveTarget,
            message: 'Daily kcal target must be positive',
          ),
        if (preMin > 240)
          const ValidationIssue(
            field: 'preMin',
            code: ValidationCode.preMinTooLarge,
            message: 'Pre-meal reminder lead cannot exceed 240 minutes',
          ),
      ];
}

extension UserProfileValidation on UserProfile {
  List<ValidationIssue> validate() => [
        if (id.trim().isEmpty)
          const ValidationIssue(
            field: 'id',
            code: ValidationCode.blankId,
            message: 'Profile id must not be blank',
          ),
      ];
}
```

- [ ] **Step 5: Run — expect PASS**

Run: `flutter test test/domain/ test/architecture/`

- [ ] **Step 6: Format + analyze** — clean.

- [ ] **Step 7: Report** this task done for review (do **not** commit).

---

### Task 11: Generic date utils (`utils/day.dart`)

**Role:** implement · **Skills:** `dart-add-unit-test`, `dart-migrate-to-checks-package`
**Goal:** Pure, domain-free calendar helpers. Date-component arithmetic (DST-safe), no `Duration` day math.
**Files:** Create `lib/utils/day.dart` · Test `test/utils/day_test.dart`
**Contract:** signatures below. `utils` may import `dart:*` only (architecture test enforces). Both args of `isSameDay` are expected in the same frame (both local or both UTC).
**Out of scope:** plan-day boundary assignment (01:00 meal → previous day's plan) — scheduling, S05.

- [ ] **Step 1: Write the failing test**

```dart
// test/utils/day_test.dart
import 'package:checks/checks.dart';
import 'package:crudo/utils/day.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('dayKey strips time, preserves utc flag', () {
    check(dayKey(DateTime(2026, 6, 3, 13, 45))).equals(DateTime(2026, 6, 3));
    check(dayKey(DateTime.utc(2026, 6, 3, 13, 45))).equals(DateTime.utc(2026, 6, 3));
  });

  test('isSameDay ignores time, distinguishes dates', () {
    check(isSameDay(DateTime(2026, 6, 3, 1), DateTime(2026, 6, 3, 23))).isTrue();
    check(isSameDay(DateTime(2026, 6, 3, 23, 59), DateTime(2026, 6, 4, 0, 1))).isFalse();
  });

  test('weekdayIndex maps Mon..Sun to 0..6', () {
    check(weekdayIndex(DateTime(2026, 6, 1))).equals(0); // 2026-06-01 is a Monday
    check(weekdayIndex(DateTime(2026, 6, 7))).equals(6); // Sunday
  });

  test('addDays normalizes, crosses boundaries, handles negatives', () {
    check(addDays(DateTime(2026, 6, 3, 18), 1)).equals(DateTime(2026, 6, 4));
    check(addDays(DateTime(2026, 6, 30), 1)).equals(DateTime(2026, 7, 1));
    check(addDays(DateTime(2026, 12, 31), 1)).equals(DateTime(2027, 1, 1));
    check(addDays(DateTime(2026, 6, 3), -1)).equals(DateTime(2026, 6, 2));
    check(addDays(DateTime.utc(2026, 6, 3), 1)).equals(DateTime.utc(2026, 6, 4));
  });

  test('localDayLabel converts a UTC instant to a UTC-midnight local-date label', () {
    final label = localDayLabel(DateTime.utc(2026, 6, 3, 12));
    final expected = DateTime.utc(2026, 6, 3, 12).toLocal();
    check(label).equals(DateTime.utc(expected.year, expected.month, expected.day));
    check(label.isUtc).isTrue();
    check(label.hour).equals(0);
  });
}
```
> The Monday/Sunday assertions are real calendar facts — do not change them.

- [ ] **Step 2: Run — expect FAIL**

Run: `flutter test test/utils/`

- [ ] **Step 3: Create `lib/utils/day.dart`**

```dart
/// Generic calendar helpers. Pure and domain-free — business rules about days
/// (plan-day assignment, midnight-lock) live in domain/application (S05).

/// Midnight-normalized copy, preserving the input's local/UTC frame.
DateTime dayKey(DateTime dt) => dt.isUtc
    ? DateTime.utc(dt.year, dt.month, dt.day)
    : DateTime(dt.year, dt.month, dt.day);

/// True when both instants fall on the same calendar date. Both arguments are
/// expected in the same frame (both local or both UTC).
bool isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// Weekday as 0=Mon … 6=Sun (the PlanTemplate.days convention). Dart's
/// DateTime.weekday is 1=Mon … 7=Sun.
int weekdayIndex(DateTime dt) => dt.weekday - 1;

/// The date [n] days from [dt] (may be negative), midnight-normalized.
/// Uses date-component arithmetic, not Duration — safe across DST shifts.
DateTime addDays(DateTime dt, int n) => dt.isUtc
    ? DateTime.utc(dt.year, dt.month, dt.day + n)
    : DateTime(dt.year, dt.month, dt.day + n);

/// Converts a real UTC instant to the user's local calendar date, encoded as
/// a UTC-midnight DateTime — the canonical `Day.date` label form.
DateTime localDayLabel(DateTime utcInstant) {
  final local = utcInstant.toLocal();
  return DateTime.utc(local.year, local.month, local.day);
}
```

- [ ] **Step 4: Run — expect PASS, full suite**

Run: `flutter test`
Expected: everything green — shared VOs, all aggregates, services, validation, architecture, utils, plus the existing S01 tests.

- [ ] **Step 5: Format + analyze** — `dart format . && flutter analyze` clean.

- [ ] **Step 6: Report** this task done for review (do **not** commit).

---

## Final verification (Opus, before integrating)
- [ ] `flutter pub get` — no `dependency_overrides`; no prerelease; `meta 1.17.0`; **no json_serializable/json_annotation**.
- [ ] `dart run build_runner build` — regenerates all `*.freezed.dart`, 0 errors; all generated files tracked by git.
- [ ] `flutter test` — full suite green (incl. architecture test) · `dart format .` no changes · `flutter analyze` 0 issues.
- [ ] Architecture drill: a `package:flutter` import anywhere under `lib/domain/` makes the suite fail.
- [ ] `AGENTS.md` codegen command corrected; spec coverage check against `docs/specs/2026-06-03-s02-domain-models-nutrition.md` (every type, VO, enum, rule, util has a task).
