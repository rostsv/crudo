# Spec — S02: Domain Layer (Models, Validation, Nutrition)

**Status:** approved (design); plan pending · **Spec S02 (logic, foundation)** · scope = the full pure domain layer (template + instance trees, VOs, two-tier validation, nutrition domain service), generic date utils, and the **codegen toolchain** (freezed only — deferred from S01). No widgets, no repositories, no JSON, no backend, no engines.

> Supersedes `docs/specs/2026-06-02-s02-domain-models-nutrition.md`. Diagrams: `docs/design/domain/2026-06-02-s02-domain-diagrams.md`.

## Goal
Ship the app's core: every domain type as an immutable, **serialization-free** freezed model organized by aggregate; value objects guarding invariants; two-tier validation in domain; the nutrition rules as a pure domain service; generic calendar helpers in `utils/`. Test-locked foundation for S03+ (repos), S05 (lifecycle), S09 (plans), S12 (streaks).

## Architecture (locked 2026-06-03 — "Riverpod MVVM + shared DDD core")
Full rationale: brainstorm 2026-06-02/03; sources: Flutter Compass case study, CodeWithAndrea architecture comparison, DDD report.

- **One bounded context.** Domain is cohesive + shared; feature-first applies to UI only. No per-feature domain.
- **Clean dependency rule:** `ui → application → domain ← data`; **domain depends on nothing** (no Flutter/Riverpod/JSON/Supabase imports — only `freezed_annotation` + core Dart). `utils/` = generic technical helpers, **no business rules**.
- **DDD tactical, selective:** aggregate modules, a few meaningful VOs, rich behavior on aggregates (methods arrive with their engine specs), domain services for cross-entity logic, self-validation on entities.
- **Domain is serialization-free.** No `fromJson`/`toJson` on domain types (reverses the earlier "JSON now" call — nothing needs JSON before S20; S03 is in-memory + a seed DTO in `data/`). DTOs + mappers live in `data/` from S20.
- **Repository interfaces** will live in `domain/repositories/` — **defined in S03** with their consumers (not speculatively now). `application/` use-cases are **emergent** (only when logic spans repos); Riverpod controllers are the application layer otherwise.
- **Controller→Repository→Service chain** (Spring mapping: Notifier ≈ @Service entry, repository ≈ @Repository, data service ≈ EntityManager/WebClient-level client).

### Domain design decisions (binding)
1. **Template vs instance split.** Templates (`PlanTemplate→PlanSlot→MealTemplate→ProductRef→Product`) are the factory; edits affect future only. Instances (`Day→Meal→MealProduct`) are **detached, self-contained snapshots**, individually editable per day (snapshot-on-schedule, §8 architecture.md).
2. **One `Day` type** for today/future/history; "locked" derived from date; `adherence`+`state` frozen onto the Day at midnight-lock (null while open). No `Week` entity (a week = query over Days).
3. **Meal time lives on `PlanSlot`** (template) and on instance `Meal` (the scheduling wrapper). `MealTemplate` is time-free + reusable.
4. **Instance `Meal` is the wrapper**: slot-stable `id` + `time` + snapshot content. Notifications/refs key off `Meal.id`; content swaps keep the id.
5. **Status derived, never stored** (checked flags + time → S05). Adherence state derived live, frozen at lock (S12).
6. **kcal goal = `Prefs.dailyKcalTarget`** (nullable int, onboarding, guidance only). Goal enum profile-level. Plan tag derived (goal label + Σ planned kcal). Adherence stays consumed÷planned.
7. **uuid-string ids (v7, app-generated)** · **grams/macros double, per-100 g** · **UTC instants; day key = local calendar date encoded `DateTime.utc(y,m,d)`; midnight-lock at local 00:00.**
8. **Product origin:** explicit `isCustom` flag (category orthogonal).

## Codegen (resolved — verified on Flutter 3.41.9 / Dart 3.11.5)
All-stable, **no `dependency_overrides`**, `meta` stays `1.17.0`: `freezed 3.2.5`, `freezed_annotation 3.1.0`, `build_runner 2.15.0` (transitive `analyzer 10.0.1`). **`json_serializable`/`json_annotation` NOT added** (domain serialization-free; DTOs at S20).
- `build_runner 2.15.0` **removed `--delete-conflicting-outputs`** → command is `dart run build_runner build`; fix `AGENTS.md`/`CLAUDE.md`.
- freezed 3.x: `abstract class X with _$X` + `const factory X(...) = _X;`; invariants via `@Assert`; add `const X._();` private ctor so behavior methods can be added later.
- Generated `*.freezed.dart` committed. No prerelease deps.

## Layout (S02 files)
```
lib/domain/
  product/    product.dart  product_ref.dart
  meal/       meal_template.dart  meal.dart  meal_product.dart
  plan/       plan_template.dart  plan_slot.dart
  day/        day.dart
  profile/    user_profile.dart  prefs.dart
  streak/     streak.dart
  shared/     meal_time.dart  macros.dart  grams.dart  enums.dart
  services/   nutrition.dart
  validation/ validation_issue.dart  validators.dart
  repositories/   (reserved — interfaces land in S03)
lib/utils/    day.dart        (generic calendar; no business rules)
```

## Type catalog
All freezed unless noted; **no JSON anywhere**; lists `@Default([])`.

**Value objects (`shared/`)**
- `MealTime` — plain class: `final int minutesOfDay` (assert 0–1439), getters `hour`/`minute`, `==`/`hashCode`, `compareTo`.
- `Grams` — plain class: `final double value` (assert `> 0`), `==`/`hashCode`. The only door to a quantity — forms validate input *before* constructing.
- `Macros` — freezed: `double protein/carbs/fats/kcal` (`@Default(0)`). Derived totals, never persisted.

**Enums (`shared/enums.dart`)** — plain Dart (wire names = S20 DTO concern):
`MealStatus{done,partial,upcoming,skipped}` · `MealTag{breakfast,lunch,dinner,snack,preWorkout,postWorkout}` · `ProductCategory{meat,fish,eggs,grain,veg,fruit,oil,custom}` · `Goal{cut,maintain,bulk}` · `Unit{g,oz}` · `ReminderMode{fixed,interval}` · `DayState{green,yellow,red}`

**Template aggregates**
- `Product` — `id`, `name`, `category`, `protein/carbs/fats` (per-100g doubles), `kcalOverride?` (per-100g), `isCustom=false`.
- `ProductRef` — `productId`, `grams: Grams`.
- `MealTemplate` — `id`, `name`, `tags`, `products: List<ProductRef>`. No time.
- `PlanSlot` — `id`, `mealTemplateId`, `time: MealTime`.
- `PlanTemplate` — `id`, `name`, `days: List<int>` (0=Mon…6=Sun), `active=true`, `slots: List<PlanSlot>`.

**Instance aggregates (snapshots)**
- `MealProduct` — `sourceProductId?`, `name`, `category`, `protein/carbs/fats`, `kcalOverride?`, `grams: Grams`, `checked=false`.
- `Meal` — `id`, `time: MealTime`, `sourceMealTemplateId?`, `name`, `tags`, `products: List<MealProduct>`. No status field.
- `Day` — `date` (UTC-midnight local-date label), `sourcePlanId?`, `planName?`, `meals: List<Meal>`, `adherence?: double`, `state?: DayState`.

**Profile / motivation**
- `Prefs` — `goal=maintain`, `units=g`, `dailyKcalTarget?: int`, `streakThreshold=80`, `reminderMode=fixed`, `preOn/atOn/eodOn/riskOn=true`, `preMin=30`.
- `UserProfile` — `id`, `displayName?`, `prefs=Prefs()`.
- `Streak` — `current=0`, `personalBest=0`, `lastCountedDay?`.

## Validation (two-tier, in domain)
**Tier 1 — invariants** (`@Assert` / ctor asserts; debug guards for impossible states):
`MealTime` 0–1439 · `Grams > 0` · `Product`/`MealProduct` macros `>= 0` · `Day` `date.isUtc` & midnight, `(adherence==null)==(state==null)`, `adherence ∈ [0,1]` · `Prefs.preMin >= 0` · `Streak` `current>=0`, `personalBest>=current`.

> **Const-assert limitation (discovered in implementation):** Dart const-constructor asserts allow only potentially-constant expressions — no property/method access on params (`date.isUtc`, `days.every(...)`). Resolution: `Day` uses a **non-const factory** (a const `Day` is impossible anyway — `DateTime` is never const-creatable), keeping its asserts. `PlanTemplate` stays const (const construction is used), so its weekday-range rule moved to Tier-2 as `invalidWeekday`.

**Tier 2 — `validate() → List<ValidationIssue>`** (extension methods in `validation/validators.dart`; called at save; never throws; mid-edit drafts allowed):
| Type | Rules |
|---|---|
| `Product`/`MealProduct` | name non-blank · `kcalOverride` (if set) ≥0 **and within ±10 %** of calculated · `protein+carbs+fats ≤ 100` per-100g (**±1 g tolerance**) |
| `MealTemplate`/`Meal` | name non-blank · ≥ 1 product |
| `PlanSlot` | `mealTemplateId` non-blank |
| `PlanTemplate` | name non-blank · days unique · each day `∈ 0..6` (`invalidWeekday`) · ≥ 1 slot when `active` |
| `Day` | unique meal ids |
| `Prefs` | `streakThreshold ∈ {70,80,90,100}` · `dailyKcalTarget` (if set) > 0 · `preMin ≤ 240` |
| `UserProfile` | id non-blank |

`ValidationIssue { field, ValidationCode code, message }`; `ValidationCode` enum (`blankName`, `kcalOverrideOutOfRange`, `macroMassExceeded`, `emptyMeal`, `emptyActivePlan`, `invalidThreshold`, `nonPositiveTarget`, `duplicateMealId`, `duplicateWeekday`, `invalidWeekday`, `blankMealTemplateId`, `preMinTooLarge`, `blankId`). UI maps codes → localized text.

## Nutrition domain service (`domain/services/nutrition.dart` — pure)
- `calculatedKcal({protein, carbs, fats})` → `p*4 + c*4 + f*9`
- `isKcalOverrideValid({calculated, override, tolerance = 0.10})`; `calculated <= 0` → only `0` valid
- `effectiveKcalPer100g({protein, carbs, fats, kcalOverride})` → valid override else calculated
- `macrosForProduct(MealProduct)` → per-100g × `grams.value/100`
- `mealMacros(Meal)` → Σ products (planned) · `consumedMacros(Meal)` → Σ checked
- `mealTemplateMacros(MealTemplate, Map<String, Product>)` → preview; unresolved id skipped

Out of scope: adherence→`DayState` (S12), `MealStatus` derivation (S05).

## Generic date utils (`utils/day.dart` — pure, domain-free)
`dayKey(dt)` · `isSameDay(a,b)` · `weekdayIndex(dt)` (=`weekday-1`, 0=Mon) · `addDays(dt,n)` · `localDayLabel(utcInstant)` → local date re-encoded `DateTime.utc(y,m,d)`.

## Dependency-rule enforcement (`test/architecture/dependency_rules_test.dart`)
The Clean dependency rule is **machine-enforced** by an architecture test (zero new deps; runs in `flutter test`, so the pre-commit hook gates it). It scans `import` lines per layer against an allowlist:
- `lib/domain/**` → only `dart:*`, `package:freezed_annotation/`, `package:crudo/domain/` (+ relative). No Flutter/Riverpod/JSON/Supabase/data/ui/application/utils.
- `lib/utils/**` → only `dart:*` (generic; no project imports, no Flutter).
- Generated `*.freezed.dart` skipped. Allowlist map grows as layers land (S03: data/application rules). `custom_lint` graduation deferred (analyzer cap).

## Tests (`test/domain/`, `test/utils/` — `package:checks`)
- VOs: `MealTime` getters/bounds/equality; `Grams` >0 assert + equality; `Macros` equality/copyWith.
- Every model: construction defaults + `copyWith` + value equality.
- Invariants: impossible constructions throw in debug (e.g. `Grams(0)`, `Streak(current:2, personalBest:1)`, `Day(adherence:0.5, state:null)`, non-UTC `Day.date`).
- `validate()`: pass + fail case per rule asserting the exact `ValidationCode` (calc-290 → override 320 fails, 310 passes; p60+c50 → `macroMassExceeded`; etc.).
- Nutrition: kcal formula (20/30/10→290); override boundaries (calc 100: 110 ok / 111 no / 90 ok / 89 no; calc 0: 0 ok / 1 no); scaling with integer-clean values (factor 2 exact); planned vs consumed sums; template preview skip-unresolved.
- Day utils: strips time; same-day boundaries; 2026-06-01 Mon→0, 2026-06-07 Sun→6; month/year crossing; negative n; `localDayLabel` returns UTC-midnight.

## Acceptance
- `flutter pub get`: no overrides, no prerelease, `meta 1.17.0`; **no json_serializable/json_annotation present**.
- `dart run build_runner build` → all `*.freezed.dart`, 0 errors, committed.
- Domain imports: no `package:flutter/`, no Riverpod, no Supabase anywhere under `lib/domain/` — **enforced by the architecture test** (`test/architecture/dependency_rules_test.dart` green).
- `dart format .` clean · `flutter analyze` clean · `flutter test` green.
- `AGENTS.md` + `CLAUDE.md` codegen command corrected (`dart run build_runner build`).

## Out of scope
Repo interfaces + impls + seed + DTOs/mappers (S03/S20) · aggregate behavior methods + status derivation + materialization + snooze (S05) · validation UI (S07) · scheduling/conflicts (S09) · adherence/streak engines (S12) · `riverpod_generator` (S05+) · `custom_lint` (deferred) · widgets · Postgres DDL (S19 — target sketch in diagrams doc).

## Skills
`dart-add-unit-test` · `dart-migrate-to-checks-package` · `dart-resolve-package-conflicts` · `dart-use-pattern-matching` · `flutter-expert` (quality overlay).
