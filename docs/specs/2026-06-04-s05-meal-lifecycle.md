# Spec — S05: Meal Lifecycle Engine

**Status:** approved (design) · **Spec S05 (logic)** · depends on S02 (+ mechanical ripple into S03 artifacts) · scope = the **pure domain engine**: instance-tree model refactor, status derivation, lifecycle ops on the `Day` aggregate, snooze bounds, kcal math, day materialization functions. No repositories' behavior changes, no Riverpod/widgets (S06), no notification scheduling (S14), no adherence/streak math (S12), no Supabase.

> **Companion design doc (rationale, diagrams, use cases UC1–11, 25-case edge ledger, decisions log):** `docs/design/domain/2026-06-03-s05-meal-lifecycle-engine.md`. This spec is the contract; the design doc is the why. Where wording differs, this spec wins.

## Goal

Every meal-lifecycle rule (status, leniency, midnight lock, snooze, day assignment, copy-on-write materialization) exists as pure, test-locked domain code before any Today-screen pixel (S06). S06 then only wires repos → controllers → widgets.

## Model refactor (instance tree — final)

State-wrapper around a purer value at every level:

```
Day                  «aggregate root; identity = date (no domain id)»
└─ ScheduledMeal     «entity: timing/notification state»
   └─ MealSnapshot   «the day's content record»
      └─ MealItem    «consumption wrapper»
         └─ FoodSnapshot  «pure value»
```

```dart
// lib/domain/day/day.dart  (REFACTOR)
Day {
  DateTime date,                 // UTC-encoded local-date label, midnight-normalized (existing)
  String? sourcePlanId, String? planName,
  List<ScheduledMeal> meals,     // order = time order at materialization; not identity
  double? adherence, int? thresholdUsed, DateTime? lockedAt,  // frozen trio — written ONCE by S12
}
// @Assert: date label rules (existing); trio all-null-or-all-set; no duplicate ScheduledMeal.id

// lib/domain/day/scheduled_meal.dart  (NEW)
ScheduledMeal {
  String id,                     // slot-stable uuid v7 — notifications key off it; survives content swaps
  MealTime time,
  DateTime? skippedAt,           // UTC; explicit Skip; persists forever (analytics); re-skip overwrites
  DateTime? snoozedUntil,        // UTC; last snooze target; persists forever; re-snooze overwrites
  MealSnapshot meal,             // swap = replace this field; id + time survive
}
// @Assert: id non-empty

// lib/domain/meal/meal_snapshot.dart  (REFACTOR of meal.dart)
MealSnapshot { String? sourceMealTemplateId, String name, List<MealTag> tags, List<MealItem> items }

// lib/domain/meal/meal_item.dart  (NEW)
MealItem { DateTime? checkedAt, FoodSnapshot food }   // checkedAt UTC; null = not eaten
// "checked" == checkedAt != null. Mark travels with its item — list order is display-only.

// lib/domain/meal/food_snapshot.dart  (NEW)
FoodSnapshot {
  String? sourceFoodId,          // weak back-ref, never an integrity dependency
  String name, FoodKind kind, FoodCategory category,
  Grams grams,
  double protein, double carbs, double fat, double kcal,   // ABSOLUTES for these grams, computed once
}
// factory FoodSnapshot.from(Food food, Grams grams)  — absolutes = per100g × grams / 100
```

### Library + enum ripple (mechanical, same change)

| Old (S02/S03) | New |
|---|---|
| `Product` (folder `domain/product/`) | `Food` (folder `domain/food/`) — gains `FoodKind kind`; `kcalOverride?` → always-set `kcalPer100g` (formula default + ±10% check move to S07 input flow) |
| `ProductRef` | `FoodRef { foodId, grams }` |
| `ProductCategory` / new | `FoodCategory` · `FoodKind { product, dish }` (display/filter only — engine never reads it; seed pre-tagged `product`) |
| `ProductRepository` | `FoodRepository` |
| instance `Meal` + `MealProduct` | `MealSnapshot` + `MealItem` + `FoodSnapshot` (above) |
| `Day.state: DayState?` | dropped — replaced by `thresholdUsed` + `lockedAt`; `DayState` enum stays as derived type (S12: `dayState(adherence, thresholdUsed)`) |

S03 in-memory repos, seed DTO/mapper, fakes, and existing S02/S03 tests adjust accordingly. Seed JSON gains `kind` (all `product`) and plain `kcalPer100g`.

## Status derivation (pure, `domain/services/meal_lifecycle.dart`)

`MealStatus deriveMealStatus(ScheduledMeal sm, DateTime dayDate, DateTime now)` — never stored, recomputed per read:

```
1. any item checked     → all checked ? done : partial    (clock + stamps irrelevant)
2. dayDate < today      → skipped                         (history freezes unchecked)
3. dayDate > today      → upcoming                        (preview)
-- today only --
4. skippedAt != null    → skipped
5. snoozedUntil > now   → upcoming                        (UI chip: crossed planned time + gray new time)
6. now >= meal time     → skipped                         (auto-skip, exact meal time, no grace)
7. else                 → upcoming
```

Four-value enum unchanged; "snoozed" is a field-derived chip, not a status.

## Ops on `Day` (rich domain; each returns new `Day` or throws `StateError`)

`mealId` = `ScheduledMeal.id` (uuid, never a position); `itemIndex` = position in `items` at call time (rejects out-of-range). **Universal first guard: `isDayLocked` → reject.** Marking ops never touch `skippedAt`/`snoozedUntil`.

| Op | Mutation | Extra guards |
|---|---|---|
| `checkItem(mealId, itemIndex, now, today)` | `items[i].copyWith(checkedAt: now)` | — |
| `uncheckItem(mealId, itemIndex, now, today)` | `checkedAt: null` (when-data lost) | — |
| `markAllEaten(mealId, now, today)` | stamps every unchecked item with `now`; checked items keep stamps | — |
| `skipMeal(mealId, now, today)` | `skippedAt = now` | rejects if any item checked |
| `snoozeMeal(mealId, until, now, today)` | `snoozedUntil = until` | rejects if done; rejects unless `now < until <= maxSnoozeUntil` |
| `replaceMeal(mealId, MealSnapshot newMeal, now, today)` | swaps `meal`; `id`+`time` survive | rejects unless derived status == `upcoming` |

**Predicates (every throwing op has one — views pre-check, never catch):**

```dart
bool isDayLocked(Day day, DateTime today);                                 // day.date < today
bool canEditMealContent(ScheduledMeal sm, DateTime dayDate, DateTime now); // status == upcoming && !locked
bool canSkipMeal(Day day, String mealId, DateTime today);
bool canSnoozeMeal(Day day, String mealId, DateTime now, DateTime today);
DateTime maxSnoozeUntil(Day day, String mealId, DateTime now);
```

`maxSnoozeUntil` = min( next meal **by `time` value strictly greater** (same-time meals don't bound each other) , **end-of-day midnight** (start of `date+1`, so a `MealTime(0)` meal snoozes into its whole day) ). Snooze repeatable, allowed post-window.

**Edit policy (strict v1):** all content edits `upcoming`-only. Add-item-to-partial deferred (also blocks the remove-item adherence cheat).

## Materialization (pure fns + copy-on-write contract)

```dart
PlanTemplate? selectPlanForDate(List<PlanTemplate> plans, DateTime date);
// active && covers date.weekday; >1 match (defensive, S09 blocks) → lowest id

Day buildDayFromPlan(PlanTemplate? plan, DateTime date, IdGenerator ids,
                     List<MealTemplate> mealTemplates, List<Food> foods);
// PURE; caller passes raw repo data; fn resolves refs by id itself; dangling ref → slot/item dropped
// null plan → empty rest Day. One ScheduledMeal per PlanSlot sorted by time:
//   id = ids.newId(), time = slot.time,
//   meal = MealSnapshot(items: [MealItem(checkedAt: null, food: FoodSnapshot.from(food, ref.grams))…])
```

**CoW contract (orchestrated by S06 controller — documented here, implemented there):** repo row = truth (was today once, or user-edited); no row = preview via build, never persisted. **Today eager-persists on first access** (stable ids). Future day persists only on first direct edit (detached — template edits no longer reach it). Past repo-miss = app never opened that day → render empty locked day. Google-Calendar semantics: previews = recurring-event expansion, detached days = exception instances, template edit = series edit. Materialize-ahead rejected (see design doc §4); S14 notification horizon decided at S14.

## Kcal (pure; composes with S02 nutrition input-time formula)

```
plannedKcal(day)  = Σ item.food.kcal over all meals, all items
consumedKcal(day) = Σ item.food.kcal over items where checkedAt != null
```

Plain summation — absolutes were computed at snapshot creation. Adherence ratio/threshold/coloring = S12.

## Time conventions

All fns take explicit `now`/`today` — no clock reads in domain. Stamps (`skippedAt`, `snoozedUntil`, `checkedAt`, `lockedAt`) = UTC instants (`isUtc` asserted). `today` = `DateTime.utc(y,m,d)` of the local date (S02 label convention). Meal instant = `day.date` + `MealTime` compared in local wall-clock. Strict midnight: logging window = the meal's own local calendar day; day assignment follows the scheduled day, never the logging instant. Generic helpers (label-from-now, end-of-day instant) → `utils/` if absent.

## Tests (`test/domain/`) — `package:test` + `package:checks`

- **Derivation matrix (table-driven):** every chain rule × past/today/future; checked-wins paths (early eat, late log after auto-skip, eat after explicit skip); snooze pending/elapsed; boundary instants (exactly meal time, 23:59 vs 00:00).
- **Op guards:** locked-day rejection for every op; skip-with-checks; snooze bounds (next-meal, end-of-day, same-time meals, `MealTime(0)`, post-window, re-snooze); replaceMeal on each non-upcoming status; out-of-range `itemIndex`; stamps survive marking; `markAllEaten` preserves existing stamps.
- **Materialization:** weekday selection + lowest-id tie-break; rest day; dangling template/food refs dropped; item order = slot/template order; ids minted per call; `FoodSnapshot.from` absolute math (incl. rounding).
- **Kcal:** planned/consumed across done/partial/skipped/upcoming; empty day = 0/0.
- **Invariants:** trio assert; duplicate meal-id assert; refactored S02/S03 tests green after rename ripple.

## Acceptance

- `dart run build_runner build` clean (freezed for new/changed models).
- `flutter analyze` clean; `dart format .` no-op; **`flutter test` fully green including refactored S02/S03 suites**.
- Architecture test still proves `lib/domain/` imports nothing (no Flutter/Riverpod/uuid/data).
- Engine fns + ops covered per test section; no `DateTime.now()` anywhere under `lib/domain/`.

## Out of scope

Controllers/widgets/week-view (S06) · content-edit ops beyond `replaceMeal` — add/remove item, grams edit (S08) · custom-food input flow + ±10% UI validation (S07) · plan CRUD/conflicts (S09) · adherence/streak/`dayState` (S12) · shopping-list summary (S13+/post-MVP) · notifications + snooze-pick UI (S14) · `days`/`scheduled_meals` storage shape (S19/S20) · dangling-`FoodRef` delete policy (S07/S09).

## Skills

`dart-add-unit-test` · `dart-migrate-to-checks-package` · `dart-use-pattern-matching` (derivation chain) · `flutter-expert` (quality overlay) · freezed codegen per `AGENTS.md` commands.
