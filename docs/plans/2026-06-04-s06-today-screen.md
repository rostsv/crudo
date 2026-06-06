# S06: Today Screen — Implementation Plan

> **For workers:** implement task-by-task, top to bottom. Each task = a contract + checkbox (`- [ ]`) steps; read the `.agents/skills` it names. Work on the main working tree. **Do not commit** — report each task done for Opus to review & integrate; after the last task write the handoff report to `.opencode/handoff/2026-06-04-s06-today-screen.report.md`. Spec: `docs/specs/2026-06-04-s06-today-screen.md`. S05 read-path contract: `docs/design/domain/2026-06-03-s05-meal-lifecycle-engine.md §4.3`. Visual target: `docs/design/prototype/screens/today.jsx` + `sheets.jsx` (SnoozeSheet) — composition only; every dimension snaps to `lib/ui/core/themes/dimensions.dart` tokens.

**Goal:** the Today tab — S05 §4.3 day-resolution controller (`@riverpod` codegen), intake hero card + macro bars, streak chip (stub provider), Mon–Sun day strip, meal list with marking sheet + snooze sheet.

**Architecture:** providers in `lib/ui/features/today/view_models/` (riverpod codegen, `part '*.g.dart'`), views in `lib/ui/features/today/views/`. View → controller → repository interface; **zero new domain code** — the controller composes existing pure functions (`selectPlanForDate`, `buildDayFromPlan`, `plannedMacros`/`consumedMacros`, `deriveMealStatus`, `isDayLocked`, `maxSnoozeUntil`). Day ops throw `StateError` on guard violations — views pre-check with `meal_lifecycle` predicates and catch into `showCrudoToast`.

**Tech Stack:** flutter_riverpod 3.3.1 + (new) `riverpod_annotation` / `riverpod_generator`; freezed codegen already wired (`dart run build_runner build` — no `--delete-conflicting-outputs` flag on build_runner 2.15). Tests: `flutter_test` + `package:checks`; controllers via `ProviderContainer`.

**Conventions:** follow `AGENTS.md`. Hard design rules: no 1px borders/dividers, no drop shadows (only `Shadows.cloud` on floating), never pure black, split-circle for partial (never "½"), paddings/gaps only from `Spacing`, icons from `IconSizes`, radii from `Radii`; new size = new token in `dimensions.dart` + `design_system.md §5` entry. After each task: `dart format . && flutter analyze && flutter test` clean/green.

**Domain API you will use (already shipped, do not modify):**

```dart
// lib/domain/services/meal_status.dart
DateTime localDateLabel(DateTime now);            // DateTime.utc(y,m,d) of local now
DateTime localInstantAt(DateTime dayDate, MealTime time);
DateTime endOfDayLocal(DateTime dayDate);         // local start of next day
MealStatus deriveMealStatus(ScheduledMeal meal, DateTime dayDate, DateTime now);

// lib/domain/services/meal_lifecycle.dart
bool isDayLocked(Day day, DateTime today);
bool canSkipMeal(Day day, String mealId, DateTime today);
bool canSnoozeMeal(Day day, String mealId, DateTime now, DateTime today);
DateTime maxSnoozeUntil(Day day, String mealId, DateTime now);   // UTC bound
PlanTemplate? selectPlanForDate(List<PlanTemplate> plans, DateTime date);
Day buildDayFromPlan(PlanTemplate? plan, DateTime date, String Function() newId,
    List<MealTemplate> mealTemplates, List<Food> foods);
Macros plannedMacros(Day day);  Macros consumedMacros(Day day);
double plannedKcal(Day day);    double consumedKcal(Day day);

// lib/domain/day/day.dart — ops return a NEW Day or throw StateError
Day checkItem(String mealId, int itemIndex, DateTime now, DateTime today);
Day uncheckItem(String mealId, int itemIndex, DateTime now, DateTime today);
Day markAllEaten(String mealId, DateTime now, DateTime today);
Day skipMeal(String mealId, DateTime now, DateTime today);
Day snoozeMeal(String mealId, DateTime until, DateTime now, DateTime today);
// ScheduledMeal: id, time (MealTime), skippedAt?, snoozedUntil?, meal (MealSnapshot)
// MealSnapshot: name, tags (List<MealTag>), items (List<MealItem>), anyChecked, allChecked
// MealItem: checkedAt?, checked, food (FoodSnapshot: name, grams, protein, carbs, fats, kcal)
```

---

### Task 1: Riverpod codegen deps · bronze token · dev demo seed

**Role:** build · **Skills:** `flutter-riverpod-arch` (setup section), `dart-add-unit-test`
**Files:** Modify `pubspec.yaml`, `docs/design/prototype/app.css`, `lib/ui/core/themes/colors.dart`, `lib/ui/core/themes/typography.dart`, `lib/data/repositories/in_memory_meal_template_repository.dart`, `lib/data/repositories/in_memory_plan_template_repository.dart`, `lib/config/di.dart` · Create `lib/data/services/demo_seed.dart` · Test `test/config/di_demo_seed_test.dart`
**Contract:** `riverpod_annotation` (deps) + `riverpod_generator` (dev_deps) installed; `CrudoColors.bronze` = `#9A7E4E` (and `--bronze` recorded in `app.css`); `CrudoText.stat` = 56/-2/w700 (mirrors `.streak-num`); both template repos accept `{Iterable<T> seed = const []}`; `di.dart` seeds `demoMealTemplates` + `[demoPlanTemplate]` only when `appConfigProvider.isDev`.
**Out of scope:** any provider/controller (Task 2–3), any widget.

- [ ] **Step 1:** Add deps:

```bash
flutter pub add riverpod_annotation
flutter pub add --dev riverpod_generator
```

- [ ] **Step 2:** Bronze token. In `docs/design/prototype/app.css`, after the `--gold-soft` line add:

```css
  --bronze: #9a7e4e;          /* Fats macro */
```

In `lib/ui/core/themes/colors.dart` add `static const bronze = Color(0xFF9A7E4E);` to `CrudoPalette`, a `bronze` field to `CrudoColors` (constructor, field declaration grouped with `gold/goldSoft/goldDeep`, the `light` const, and the existing `copyWith`/`lerp` overrides — follow the pattern of every other color).

- [ ] **Step 3:** Stat type token. In `lib/ui/core/themes/typography.dart` after `displaySm` add:

```dart
  /// Hero statistic figure (app.css .streak-num — intake kcal, streak count).
  static const stat = TextStyle(
    fontFamily: _f,
    fontSize: 56,
    height: 1.0,
    letterSpacing: -2,
    fontWeight: FontWeight.w700,
    color: CrudoPalette.onSurface,
  );
```

(Do NOT add it to `textTheme` — it is a component style, not a Material slot.)

- [ ] **Step 4:** Seed parameters (both repos, same pattern):

```dart
// lib/data/repositories/in_memory_meal_template_repository.dart
class InMemoryMealTemplateRepository extends InMemoryCrud<MealTemplate>
    implements MealTemplateRepository {
  InMemoryMealTemplateRepository({Iterable<MealTemplate> seed = const []})
    : super((t) => t.id, seed);
}
```

```dart
// lib/data/repositories/in_memory_plan_template_repository.dart
class InMemoryPlanTemplateRepository extends InMemoryCrud<PlanTemplate>
    implements PlanTemplateRepository {
  InMemoryPlanTemplateRepository({Iterable<PlanTemplate> seed = const []})
    : super((p) => p.id, seed);
}
```

- [ ] **Step 5:** Create `lib/data/services/demo_seed.dart` (ids reference `assets/seed/products.json` entries; removed when S09–S11 ship real plan building):

```dart
import 'package:crudo/domain/food/food_ref.dart';
import 'package:crudo/domain/meal/meal_template.dart';
import 'package:crudo/domain/plan/plan_slot.dart';
import 'package:crudo/domain/plan/plan_template.dart';
import 'package:crudo/domain/shared/enums.dart';
import 'package:crudo/domain/shared/grams.dart';
import 'package:crudo/domain/shared/meal_time.dart';

/// Dev-flavor demo data: 4 meal templates + 1 everyday plan so the Today
/// screen is demoable before plan building exists (S09–S11). Wired in
/// di.dart behind `appConfigProvider.isDev`; prod stays unseeded.
const demoMealTemplates = <MealTemplate>[
  MealTemplate(
    id: 'demo-meal-breakfast',
    name: 'Protein Oats Bowl',
    tags: [MealTag.breakfast],
    foods: [
      FoodRef(foodId: 'seed-oats', grams: Grams(80)),
      FoodRef(foodId: 'seed-greek-yogurt', grams: Grams(150)),
      FoodRef(foodId: 'seed-blueberries', grams: Grams(100)),
      FoodRef(foodId: 'seed-peanut-butter', grams: Grams(20)),
    ],
  ),
  MealTemplate(
    id: 'demo-meal-lunch',
    name: 'Chicken Rice Bowl',
    tags: [MealTag.lunch],
    foods: [
      FoodRef(foodId: 'seed-chicken-breast', grams: Grams(180)),
      FoodRef(foodId: 'seed-rice-white', grams: Grams(150)),
      FoodRef(foodId: 'seed-broccoli', grams: Grams(150)),
      FoodRef(foodId: 'seed-olive-oil', grams: Grams(10)),
    ],
  ),
  MealTemplate(
    id: 'demo-meal-snack',
    name: 'Yogurt & Banana',
    tags: [MealTag.snack],
    foods: [
      FoodRef(foodId: 'seed-greek-yogurt', grams: Grams(200)),
      FoodRef(foodId: 'seed-banana', grams: Grams(120)),
      FoodRef(foodId: 'seed-almonds', grams: Grams(20)),
    ],
  ),
  MealTemplate(
    id: 'demo-meal-dinner',
    name: 'Salmon & Sweet Potato',
    tags: [MealTag.dinner],
    foods: [
      FoodRef(foodId: 'seed-salmon', grams: Grams(160)),
      FoodRef(foodId: 'seed-sweet-potato', grams: Grams(200)),
      FoodRef(foodId: 'seed-spinach', grams: Grams(100)),
      FoodRef(foodId: 'seed-olive-oil', grams: Grams(8)),
    ],
  ),
];

const demoPlanTemplate = PlanTemplate(
  id: 'demo-plan-everyday',
  name: 'Everyday Plan',
  days: [1, 2, 3, 4, 5, 6, 7],
  slots: [
    PlanSlot(
      id: 'demo-slot-breakfast',
      mealTemplateId: 'demo-meal-breakfast',
      time: MealTime(8 * 60),
    ),
    PlanSlot(
      id: 'demo-slot-lunch',
      mealTemplateId: 'demo-meal-lunch',
      time: MealTime(12 * 60 + 30),
    ),
    PlanSlot(
      id: 'demo-slot-snack',
      mealTemplateId: 'demo-meal-snack',
      time: MealTime(16 * 60),
    ),
    PlanSlot(
      id: 'demo-slot-dinner',
      mealTemplateId: 'demo-meal-dinner',
      time: MealTime(19 * 60),
    ),
  ],
);
```

- [ ] **Step 6:** Wire in `lib/config/di.dart` (add imports for `app_config.dart` + `demo_seed.dart`):

```dart
final mealTemplateRepositoryProvider = Provider<MealTemplateRepository>(
  (ref) => InMemoryMealTemplateRepository(
    seed: ref.watch(appConfigProvider).isDev ? demoMealTemplates : const [],
  ),
);

final planTemplateRepositoryProvider = Provider<PlanTemplateRepository>(
  (ref) => InMemoryPlanTemplateRepository(
    seed: ref.watch(appConfigProvider).isDev
        ? const [demoPlanTemplate]
        : const [],
  ),
);
```

- [ ] **Step 7:** Write `test/config/di_demo_seed_test.dart`:

```dart
import 'package:checks/checks.dart';
import 'package:crudo/config/app_config.dart';
import 'package:crudo/config/di.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

ProviderContainer _container(Flavor flavor) {
  final c = ProviderContainer(
    overrides: [
      appConfigProvider.overrideWithValue(AppConfig(flavor: flavor)),
    ],
  );
  addTearDown(c.dispose);
  return c;
}

void main() {
  test('dev flavor seeds 4 demo meals + 1 everyday plan', () async {
    final c = _container(Flavor.dev);
    final meals = await c.read(mealTemplateRepositoryProvider).getAll();
    final plans = await c.read(planTemplateRepositoryProvider).getAll();
    check(meals.length).equals(4);
    check(plans.length).equals(1);
    check(plans.single.days).deepEquals([1, 2, 3, 4, 5, 6, 7]);
    check(plans.single.slots.length).equals(4);
  });

  test('prod flavor stays unseeded', () async {
    final c = _container(Flavor.prod);
    check(await c.read(mealTemplateRepositoryProvider).getAll()).isEmpty();
    check(await c.read(planTemplateRepositoryProvider).getAll()).isEmpty();
  });
}
```

(If `AppConfig`'s constructor needs more arguments, mirror how `test/routing/app_router_test.dart` constructs it.)

- [ ] **Step 8:** Run `flutter test test/config/ && dart format . && flutter analyze` — green/clean. Report done for review.

---

### Task 2: Clock, today, selection + repo stream providers

**Role:** implement · **Skills:** `flutter-riverpod-arch`, `dart-add-unit-test`, `dart-migrate-to-checks-package`
**Files:** Create `lib/ui/features/today/view_models/today_providers.dart` (+ generated `.g.dart`) · Test `test/ui/features/today/view_models/today_providers_test.dart` · Delete `lib/ui/features/today/view_models/.gitkeep`
**Contract:** exactly these providers (names matter — Tasks 3–6 consume them):

```dart
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);
todayProvider          // Notifier<DateTime>: UTC day-label; .refresh() re-derives
selectedDateProvider   // Notifier<DateTime>: follows today; .select(date)
streakCountProvider    // Stream<int> — StreakRepository.watch().map(current); S12 swaps the engine behind it
profileProvider        // Stream<UserProfile>
persistedDayProvider(date)  // Stream<Day?> — DayRepository.watchByDate
planTemplatesProvider  // Stream<List<PlanTemplate>>
mealTemplatesProvider  // Stream<List<MealTemplate>>
foodsProvider          // Stream<List<Food>>
```

**Out of scope:** `DayController` (Task 3), any widget.

- [ ] **Step 1:** Write the failing tests:

```dart
// test/ui/features/today/view_models/today_providers_test.dart
import 'package:checks/checks.dart';
import 'package:crudo/config/di.dart';
import 'package:crudo/domain/streak/streak.dart';
import 'package:crudo/ui/features/today/view_models/today_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Mutable fake clock: local 2026-06-04 09:30.
  var now = DateTime(2026, 6, 4, 9, 30);

  ProviderContainer container() {
    final c = ProviderContainer(
      overrides: [clockProvider.overrideWithValue(() => now)],
    );
    addTearDown(c.dispose);
    return c;
  }

  test('todayProvider emits the UTC day-label of the local clock', () {
    final c = container();
    check(c.read(todayProvider)).equals(DateTime.utc(2026, 6, 4));
  });

  test('refresh() rolls today over when the clock crosses midnight', () {
    final c = container();
    check(c.read(todayProvider)).equals(DateTime.utc(2026, 6, 4));
    now = DateTime(2026, 6, 5, 0, 0, 30);
    c.read(todayProvider.notifier).refresh();
    check(c.read(todayProvider)).equals(DateTime.utc(2026, 6, 5));
  });

  test('selectedDate defaults to today, selects, and snaps back on rollover',
      () {
    now = DateTime(2026, 6, 4, 9, 30);
    final c = container();
    check(c.read(selectedDateProvider)).equals(DateTime.utc(2026, 6, 4));

    c.read(selectedDateProvider.notifier).select(DateTime.utc(2026, 6, 6));
    check(c.read(selectedDateProvider)).equals(DateTime.utc(2026, 6, 6));

    now = DateTime(2026, 6, 5, 8, 0);
    c.read(todayProvider.notifier).refresh();
    check(c.read(selectedDateProvider)).equals(DateTime.utc(2026, 6, 5));
  });

  test('streakCount maps the repository stream', () async {
    final c = container();
    check(await c.read(streakCountProvider.future)).equals(0);
    await c
        .read(streakRepositoryProvider)
        .save(const Streak(current: 7, personalBest: 9));
    await c.pump();
    check(await c.read(streakCountProvider.future)).equals(7);
  });
}
```

- [ ] **Step 2:** Run `flutter test test/ui/features/today/` — FAIL (file missing).

- [ ] **Step 3:** Implement:

```dart
// lib/ui/features/today/view_models/today_providers.dart
import 'package:crudo/config/di.dart';
import 'package:crudo/domain/day/day.dart';
import 'package:crudo/domain/food/food.dart';
import 'package:crudo/domain/meal/meal_template.dart';
import 'package:crudo/domain/plan/plan_template.dart';
import 'package:crudo/domain/profile/user_profile.dart';
import 'package:crudo/domain/services/meal_status.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'today_providers.g.dart';

/// Injectable wall clock — overridden in every test for deterministic time.
/// The domain never reads a clock (S05 §5); only providers do, through this.
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

/// The current local calendar day as a UTC day-label (S02 convention).
/// Re-derived via [refresh] on app resume + the midnight tick (TodayScreen
/// owns the observer/timer); never advances on its own.
@riverpod
class Today extends _$Today {
  @override
  DateTime build() => localDateLabel(ref.read(clockProvider)());

  void refresh() {
    final next = localDateLabel(ref.read(clockProvider)());
    if (next != state) state = next;
  }
}

/// The day the UI is looking at. Follows today (snaps back on rollover —
/// watch dependency) until the user picks another date in the week strip.
@riverpod
class SelectedDate extends _$SelectedDate {
  @override
  DateTime build() => ref.watch(todayProvider);

  void select(DateTime date) => state = date;
}

/// Streak count for the chip. Stub data until S12 writes real streaks —
/// the provider contract is final, only the data source matures.
@riverpod
Stream<int> streakCount(Ref ref) =>
    ref.watch(streakRepositoryProvider).watch().map((s) => s.current);

@riverpod
Stream<UserProfile> profile(Ref ref) =>
    ref.watch(profileRepositoryProvider).watch();

/// The persisted Day snapshot for a date — null while the repo has no row.
/// Repo presence is the authoritative bit of the S05 §4.3 read path.
@riverpod
Stream<Day?> persistedDay(Ref ref, DateTime date) =>
    ref.watch(dayRepositoryProvider).watchByDate(date);

@riverpod
Stream<List<PlanTemplate>> planTemplates(Ref ref) =>
    ref.watch(planTemplateRepositoryProvider).watchAll();

@riverpod
Stream<List<MealTemplate>> mealTemplates(Ref ref) =>
    ref.watch(mealTemplateRepositoryProvider).watchAll();

@riverpod
Stream<List<Food>> foods(Ref ref) =>
    ref.watch(foodRepositoryProvider).watchAll();
```

- [ ] **Step 4:** Run `dart run build_runner build` — generates `today_providers.g.dart`.

- [ ] **Step 5:** Run `flutter test test/ui/features/today/` — PASS. `dart format . && flutter analyze` clean. Report done for review.

---

### Task 3: DayController — the S05 §4.3 read path + ops

**Role:** implement · **Skills:** `flutter-riverpod-arch`, `dart-add-unit-test`, `dart-migrate-to-checks-package`
**Files:** Create `lib/ui/features/today/view_models/day_controller.dart` (+ `.g.dart`) · Test `test/ui/features/today/view_models/day_controller_test.dart`
**Contract:**

```dart
@riverpod
class DayController extends _$DayController {
  Future<Day> build(DateTime date);        // §4.3: repo hit wins → past miss = empty locked →
                                           // preview via buildDayFromPlan → today eager-persists
  Future<void> checkItem(String mealId, int itemIndex);
  Future<void> uncheckItem(String mealId, int itemIndex);
  Future<void> markAllEaten(String mealId);
  Future<void> skipMeal(String mealId);
  Future<void> snooze(String mealId, DateTime until);
  // every op: today-only (StateError otherwise), applies the Day op, saves;
  // repo stream re-emits → persistedDayProvider → this rebuilds.
}
```

**Out of scope:** widgets/sheets; `replaceMeal` (S08); any domain change.

- [ ] **Step 1:** Write the failing tests:

```dart
// test/ui/features/today/view_models/day_controller_test.dart
import 'package:checks/checks.dart';
import 'package:crudo/config/app_config.dart';
import 'package:crudo/config/di.dart';
import 'package:crudo/data/services/demo_seed.dart';
import 'package:crudo/data/services/id_generator.dart';
import 'package:crudo/domain/day/day.dart';
import 'package:crudo/domain/services/meal_lifecycle.dart';
import 'package:crudo/ui/features/today/view_models/day_controller.dart';
import 'package:crudo/ui/features/today/view_models/today_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Deterministic ids: sm-0, sm-1, …
class FakeIdGenerator implements IdGenerator {
  int _n = 0;
  @override
  String newId() => 'sm-${_n++}';
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  // Demo templates reference seed-food ids — load the real bundled seed
  // once so buildDayFromPlan can resolve them (add the SeedService import).
  late List<Food> seedFoods;
  setUpAll(() async => seedFoods = await SeedService().loadFoods());

  var now = DateTime(2026, 6, 4, 9, 30); // local Thursday
  final today = DateTime.utc(2026, 6, 4);
  final tomorrow = DateTime.utc(2026, 6, 5);
  final yesterday = DateTime.utc(2026, 6, 3);

  ProviderContainer container() {
    final c = ProviderContainer(
      overrides: [
        appConfigProvider.overrideWithValue(AppConfig(flavor: Flavor.dev)),
        seedFoodsProvider.overrideWithValue(seedFoods),
        clockProvider.overrideWithValue(() => now),
        idGeneratorProvider.overrideWithValue(FakeIdGenerator()),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  test('today: repo miss → materializes from plan and eager-persists once',
      () async {
    final c = container();
    final day = await c.read(dayControllerProvider(today).future);

    check(day.meals.length).equals(4);
    check(day.sourcePlanId).equals('demo-plan-everyday');
    // persisted eagerly:
    final persisted = await c.read(dayRepositoryProvider).getByDate(today);
    check(persisted).isNotNull();
    // ids minted exactly once — invalidate and re-read, ids stable:
    final idsFirst = day.meals.map((m) => m.id).toList();
    c.invalidate(dayControllerProvider(today));
    final again = await c.read(dayControllerProvider(today).future);
    check(again.meals.map((m) => m.id).toList()).deepEquals(idsFirst);
  });

  test('persisted snapshot wins over the template', () async {
    final c = container();
    await c
        .read(dayRepositoryProvider)
        .save(Day(date: today, planName: 'hand-made'));
    final day = await c.read(dayControllerProvider(today).future);
    check(day.planName).equals('hand-made');
    check(day.meals).isEmpty(); // not re-materialized
  });

  test('future date: preview built, NOT persisted', () async {
    final c = container();
    final day = await c.read(dayControllerProvider(tomorrow).future);
    check(day.meals.length).equals(4);
    check(await c.read(dayRepositoryProvider).getByDate(tomorrow)).isNull();
  });

  test('future preview follows template edits; persisted today does not',
      () async {
    final c = container();
    await c.read(dayControllerProvider(today).future); // persist today
    // deactivate the plan:
    final plans = c.read(planTemplateRepositoryProvider);
    await plans.save(demoPlanTemplate.copyWith(active: false));
    await c.pump();
    final future = await c.read(dayControllerProvider(tomorrow).future);
    check(future.meals).isEmpty(); // preview re-built — now a rest day
    final todayDay = await c.read(dayControllerProvider(today).future);
    check(todayDay.meals.length).equals(4); // snapshot untouched
  });

  test('past repo miss → empty locked day', () async {
    final c = container();
    final day = await c.read(dayControllerProvider(yesterday).future);
    check(day.meals).isEmpty();
    check(isDayLocked(day, today)).isTrue();
    check(await c.read(dayRepositoryProvider).getByDate(yesterday)).isNull();
  });

  test('markAllEaten persists; stream rebuild reflects it', () async {
    final c = container();
    final day = await c.read(dayControllerProvider(today).future);
    final mealId = day.meals.first.id;
    await c.read(dayControllerProvider(today).notifier).markAllEaten(mealId);
    await c.pump();
    final updated = await c.read(dayControllerProvider(today).future);
    check(updated.meals.first.meal.allChecked).isTrue();
    check(consumedKcal(updated)).equals(
      // breakfast only
      updated.meals.first.meal.items
          .fold<double>(0, (s, i) => s + i.food.kcal),
    );
  });

  test('ops on a non-today date throw StateError and write nothing',
      () async {
    final c = container();
    final day = await c.read(dayControllerProvider(tomorrow).future);
    await check(
      c
          .read(dayControllerProvider(tomorrow).notifier)
          .markAllEaten(day.meals.first.id),
    ).throws<StateError>();
    check(await c.read(dayRepositoryProvider).getByDate(tomorrow)).isNull();
  });

  test('skip on a checked meal throws (guard surfaces, nothing saved)',
      () async {
    final c = container();
    final day = await c.read(dayControllerProvider(today).future);
    final id = day.meals.first.id;
    final ctrl = c.read(dayControllerProvider(today).notifier);
    await ctrl.checkItem(id, 0);
    await c.pump();
    await check(ctrl.skipMeal(id)).throws<StateError>();
  });

  test('snooze persists snoozedUntil', () async {
    final c = container();
    final day = await c.read(dayControllerProvider(today).future);
    final id = day.meals.first.id; // 08:00 breakfast; next slot 12:30
    final until = DateTime(2026, 6, 4, 9, 45);
    await c.read(dayControllerProvider(today).notifier).snooze(id, until);
    await c.pump();
    final updated = await c.read(dayControllerProvider(today).future);
    check(updated.meals.first.snoozedUntil).equals(until.toUtc());
  });

  test('rollover: refresh() locks yesterday and re-materializes new today',
      () async {
    final c = container();
    await c.read(dayControllerProvider(today).future); // persist 06-04
    now = DateTime(2026, 6, 5, 7, 0);
    c.read(todayProvider.notifier).refresh();
    await c.pump();
    final newToday = c.read(todayProvider);
    check(newToday).equals(tomorrow);
    final fresh = await c.read(dayControllerProvider(tomorrow).future);
    check(fresh.meals.length).equals(4); // eager-materialized now
    final old = await c.read(dayControllerProvider(today).future);
    check(isDayLocked(old, newToday)).isTrue();
  });
}
```

(Imports to add for the harness: `package:crudo/data/services/seed_service.dart`, `package:crudo/domain/food/food.dart`. The seed asset is declared in `pubspec.yaml` already.)

- [ ] **Step 2:** Run `flutter test test/ui/features/today/view_models/day_controller_test.dart` — FAIL.

- [ ] **Step 3:** Implement:

```dart
// lib/ui/features/today/view_models/day_controller.dart
import 'package:crudo/config/di.dart';
import 'package:crudo/data/services/id_generator.dart';
import 'package:crudo/domain/day/day.dart';
import 'package:crudo/domain/services/meal_lifecycle.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'today_providers.dart';

part 'day_controller.g.dart';

/// Day resolution per S05 §4.3 — the contract the engine left to S06:
/// repo hit wins (snapshot authoritative, never re-materialized) → past
/// miss = empty locked day → otherwise build from plan; today persists
/// EAGERLY so ScheduledMeal ids are minted exactly once (S14 keys off
/// them); future days stay pure previews (template edits flow through).
@riverpod
class DayController extends _$DayController {
  @override
  Future<Day> build(DateTime date) async {
    final today = ref.watch(todayProvider);
    final persisted = await ref.watch(persistedDayProvider(date).future);
    if (persisted != null) return persisted;
    if (date.isBefore(today)) return Day(date: date); // never-opened past day

    final plans = await ref.watch(planTemplatesProvider.future);
    final templates = await ref.watch(mealTemplatesProvider.future);
    final library = await ref.watch(foodsProvider.future);
    final built = buildDayFromPlan(
      selectPlanForDate(plans, date),
      date,
      ref.read(idGeneratorProvider).newId,
      templates,
      library,
    );
    if (date.isAtSameMomentAs(today)) {
      // Eager persist: the save re-emits through persistedDayProvider and
      // this provider settles on the snapshot.
      await ref.read(dayRepositoryProvider).save(built);
    }
    return built;
  }

  Future<void> checkItem(String mealId, int itemIndex) =>
      _apply((d, now, today) => d.checkItem(mealId, itemIndex, now, today));

  Future<void> uncheckItem(String mealId, int itemIndex) =>
      _apply((d, now, today) => d.uncheckItem(mealId, itemIndex, now, today));

  Future<void> markAllEaten(String mealId) =>
      _apply((d, now, today) => d.markAllEaten(mealId, now, today));

  Future<void> skipMeal(String mealId) =>
      _apply((d, now, today) => d.skipMeal(mealId, now, today));

  Future<void> snooze(String mealId, DateTime until) =>
      _apply((d, now, today) => d.snoozeMeal(mealId, until, now, today));

  /// All ops are today-only in S06 (future-day edits = the S08 detach
  /// path; past days are locked by the domain anyway). Guard violations
  /// throw StateError — views pre-check with meal_lifecycle predicates
  /// and catch the rest into a toast.
  Future<void> _apply(
    Day Function(Day day, DateTime now, DateTime today) op,
  ) async {
    final today = ref.read(todayProvider);
    if (!date.isAtSameMomentAs(today)) {
      throw StateError('day $date is read-only (today is $today)');
    }
    final day = await future;
    final now = ref.read(clockProvider)();
    await ref.read(dayRepositoryProvider).save(op(day, now, today));
  }
}
```

- [ ] **Step 4:** Run `dart run build_runner build`, then `flutter test test/ui/features/today/` — PASS.

- [ ] **Step 5:** `dart format . && flutter analyze && flutter test` — clean/green (architecture test must stay green: this file imports domain + di only, no data impls). Report done for review.

---

### Task 4: Presentational widgets — MealCard snooze, DayStrip, IntakeCard, StreakChip, NudgeCard

**Role:** ui · **Skills:** `flutter-add-widget-test`, `flutter-add-widget-preview`, `flutter-build-responsive-layout`, `flutter-expert`
**Files:** Modify `lib/ui/core/widgets/meal_card.dart`, `lib/previews.dart`, `docs/design_system.md` (§5 — record new component sizes) · Create `lib/ui/features/today/views/formatting.dart`, `lib/ui/features/today/views/day_strip.dart`, `lib/ui/features/today/views/intake_card.dart`, `lib/ui/features/today/views/streak_chip.dart`, `lib/ui/features/today/views/nudge_card.dart` · Test `test/ui/features/today/views/widgets_test.dart` (+ extend the existing MealCard test file)
**Contract:** plain params only (primitives + `Macros`/`MealTime`/enums — never `Day`/`ScheduledMeal`):

```dart
// meal_card.dart — ADD one optional param, nothing else changes:
//   this.snoozedTimeLabel,  →  final String? snoozedTimeLabel;
// when set, timeLabel renders struck-through, snoozed time to its right.

// formatting.dart (pure functions):
String mealTimeLabel(MealTime t);                 // '08:00'
String timeOfDayLabel(DateTime local);            // '14:15'
String dateHeadline(DateTime dayLabel);           // 'Thursday, June 4'
String greetingFor(DateTime now, String? name);   // 'Good morning, Mark' / 'Good evening'
List<DateTime> weekOf(DateTime dayLabel);         // Mon..Sun UTC labels around it

class DayStrip   { dates(7 labels) · selected · today · ValueChanged<DateTime> onSelect }
class IntakeCard { Macros consumed · Macros planned }
class StreakChip { int count · VoidCallback? onTap }
class NudgeCard  { String title · String body }
```

**Out of scope:** screen composition (Task 6), sheets (Task 5), providers.

- [ ] **Step 1:** Write the failing tests:

```dart
// test/ui/features/today/views/widgets_test.dart
import 'package:checks/checks.dart';
import 'package:crudo/domain/shared/macros.dart';
import 'package:crudo/domain/shared/meal_time.dart';
import 'package:crudo/ui/core/themes/theme.dart';
import 'package:crudo/ui/features/today/views/day_strip.dart';
import 'package:crudo/ui/features/today/views/formatting.dart';
import 'package:crudo/ui/features/today/views/intake_card.dart';
import 'package:crudo/ui/features/today/views/nudge_card.dart';
import 'package:crudo/ui/features/today/views/streak_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) =>
    MaterialApp(theme: crudoTheme, home: Scaffold(body: child));

void main() {
  group('formatting', () {
    test('mealTimeLabel pads', () {
      check(mealTimeLabel(const MealTime(8 * 60))).equals('08:00');
      check(mealTimeLabel(const MealTime(12 * 60 + 30))).equals('12:30');
    });
    test('dateHeadline', () {
      check(dateHeadline(DateTime.utc(2026, 6, 4)))
          .equals('Thursday, June 4');
    });
    test('greeting buckets + nameless fallback', () {
      check(greetingFor(DateTime(2026, 6, 4, 9), 'Mark'))
          .equals('Good morning, Mark');
      check(greetingFor(DateTime(2026, 6, 4, 14), 'Mark'))
          .equals('Good afternoon, Mark');
      check(greetingFor(DateTime(2026, 6, 4, 20), null))
          .equals('Good evening');
    });
    test('weekOf returns Mon..Sun containing the label', () {
      final week = weekOf(DateTime.utc(2026, 6, 4)); // Thursday
      check(week.length).equals(7);
      check(week.first).equals(DateTime.utc(2026, 6, 1)); // Monday
      check(week.last).equals(DateTime.utc(2026, 6, 7)); // Sunday
    });
  });

  testWidgets('DayStrip renders 7 pills, fires onSelect', (tester) async {
    DateTime? tapped;
    final week = weekOf(DateTime.utc(2026, 6, 4));
    await tester.pumpWidget(_wrap(DayStrip(
      dates: week,
      selected: DateTime.utc(2026, 6, 4),
      today: DateTime.utc(2026, 6, 4),
      onSelect: (d) => tapped = d,
    )));
    expect(find.byKey(const ValueKey('day-pill-2026-06-06')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('day-pill-2026-06-06')));
    check(tapped).equals(DateTime.utc(2026, 6, 6));
  });

  testWidgets('IntakeCard shows consumed/planned kcal + macro grams',
      (tester) async {
    await tester.pumpWidget(_wrap(const IntakeCard(
      consumed: Macros(protein: 30, carbs: 40, fats: 10, kcal: 370),
      planned: Macros(protein: 120, carbs: 200, fats: 60, kcal: 1820),
    )));
    expect(find.text('370'), findsOneWidget);
    expect(find.text('/1820 kcal'), findsOneWidget);
    expect(find.text('30/120g'), findsOneWidget); // protein bar value
  });

  testWidgets('StreakChip renders count', (tester) async {
    await tester.pumpWidget(_wrap(const StreakChip(count: 12)));
    expect(find.text('12-day streak'), findsOneWidget);
  });

  testWidgets('NudgeCard renders copy', (tester) async {
    await tester.pumpWidget(_wrap(const NudgeCard(
      title: "You're 60% of the way there.",
      body: '2 meals remain. A done day keeps the streak.',
    )));
    expect(find.text("You're 60% of the way there."), findsOneWidget);
  });
}
```

Plus in the existing MealCard test file: a case asserting that with `snoozedTimeLabel: '14:15'` both `14:00` (struck-through — find the `Text.rich`/`RichText` and check the first span's `TextDecoration.lineThrough`) and `14:15` render.

- [ ] **Step 2:** Run `flutter test test/ui/features/today/views/` — FAIL.

- [ ] **Step 3:** `formatting.dart` (English-only v1 — no intl dep):

```dart
// lib/ui/features/today/views/formatting.dart
import 'package:crudo/domain/shared/meal_time.dart';

const _weekdays = [
  'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday',
];
const _months = [
  'January', 'February', 'March', 'April', 'May', 'June', 'July',
  'August', 'September', 'October', 'November', 'December',
];

String _two(int n) => n.toString().padLeft(2, '0');

String mealTimeLabel(MealTime t) => '${_two(t.hour)}:${_two(t.minute)}';

String timeOfDayLabel(DateTime local) => '${_two(local.hour)}:${_two(local.minute)}';

/// 'Thursday, June 4' — [dayLabel] is a UTC day-label (S02 convention).
String dateHeadline(DateTime dayLabel) =>
    '${_weekdays[dayLabel.weekday - 1]}, ${_months[dayLabel.month - 1]} ${dayLabel.day}';

String greetingFor(DateTime now, String? name) {
  final part = now.hour < 12
      ? 'morning'
      : now.hour < 18
          ? 'afternoon'
          : 'evening';
  return (name == null || name.isEmpty) ? 'Good $part' : 'Good $part, $name';
}

/// Mon..Sun UTC day-labels of the week containing [dayLabel].
List<DateTime> weekOf(DateTime dayLabel) {
  final monday = dayLabel.subtract(Duration(days: dayLabel.weekday - 1));
  return [for (var i = 0; i < 7; i++) monday.add(Duration(days: i))];
}
```

- [ ] **Step 4:** `MealCard` — add the field after `timeLabel`:

```dart
  /// When the meal is snoozed: the new local time. Renders [timeLabel]
  /// struck-through with this to its right.
  final String? snoozedTimeLabel;
```

and replace the `'$timeLabel · $mealTypeLabel'` `Text` with:

```dart
Expanded(
  child: Text.rich(
    TextSpan(
      style: CrudoText.label.copyWith(color: colors.onSurfaceMut),
      children: [
        TextSpan(
          text: timeLabel,
          style: snoozedTimeLabel == null
              ? null
              : const TextStyle(decoration: TextDecoration.lineThrough),
        ),
        if (snoozedTimeLabel != null) TextSpan(text: '  $snoozedTimeLabel'),
        TextSpan(text: ' · $mealTypeLabel'),
      ],
    ),
  ),
),
```

- [ ] **Step 5:** `day_strip.dart` — pill geometry from `app.css .day-pill` (44×60, full radius, active = `surfaceHighest` bg + `onSurface`):

```dart
// lib/ui/features/today/views/day_strip.dart
import 'package:flutter/material.dart';

import '../../../core/themes/colors.dart';
import '../../../core/themes/dimensions.dart';
import '../../../core/themes/typography.dart';

/// Mon–Sun week strip (current week only — far navigation is S13's
/// calendar). Pills: 44×60 per app.css .day-pill; selected = surfaceHighest
/// tonal fill; today (when unselected) marks its number in primary.
class DayStrip extends StatelessWidget {
  const DayStrip({
    required this.dates,
    required this.selected,
    required this.today,
    required this.onSelect,
    super.key,
  });

  /// Exactly 7 UTC day-labels, Monday first.
  final List<DateTime> dates;
  final DateTime selected;
  final DateTime today;
  final ValueChanged<DateTime> onSelect;

  static const _pillWidth = 44.0; // component size, 4px grid (app.css)
  static const _pillHeight = 60.0; // component size, 4px grid (app.css)
  static const _letters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CrudoColors>()!;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (final (i, date) in dates.indexed)
          _DayPill(
            key: ValueKey(
              'day-pill-${date.toIso8601String().substring(0, 10)}',
            ),
            number: date.day,
            letter: _letters[i],
            selected: date == selected,
            isToday: date == today,
            colors: colors,
            onTap: () => onSelect(date),
          ),
      ],
    );
  }
}

class _DayPill extends StatelessWidget {
  const _DayPill({
    required this.number,
    required this.letter,
    required this.selected,
    required this.isToday,
    required this.colors,
    required this.onTap,
    super.key,
  });

  final int number;
  final String letter;
  final bool selected;
  final bool isToday;
  final CrudoColors colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final numColor = selected
        ? colors.onSurface
        : isToday
            ? colors.primary
            : colors.onSurfaceMut;
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: Durations.base,
          width: DayStrip._pillWidth,
          height: DayStrip._pillHeight,
          decoration: BoxDecoration(
            color: selected ? colors.surfaceHighest : null,
            borderRadius: Radii.all(Radii.full),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$number',
                style: CrudoText.bodyLg.copyWith(
                  fontWeight: FontWeight.w700,
                  color: numColor,
                ),
              ),
              Text(
                letter,
                style: CrudoText.label.copyWith(
                  color: numColor.withValues(alpha: 0.7),
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

- [ ] **Step 6:** `intake_card.dart`:

```dart
// lib/ui/features/today/views/intake_card.dart
import 'package:flutter/material.dart';

import '../../../../domain/shared/macros.dart';
import '../../../core/themes/colors.dart';
import '../../../core/themes/dimensions.dart';
import '../../../core/themes/typography.dart';
import '../../../core/widgets/macro_ring.dart';

/// Hero intake summary: consumed/planned kcal + progress ring + the three
/// macro bars (Protein=primary, Carbs=gold, Fats=bronze). Floating card —
/// the one Cloud Shadow on this screen.
class IntakeCard extends StatelessWidget {
  const IntakeCard({required this.consumed, required this.planned, super.key});

  final Macros consumed;
  final Macros planned;

  static const _ringSize = 72.0; // component size, 4px grid

  double _share(double v, double t) => t <= 0 ? 0 : v / t;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CrudoColors>()!;
    return Container(
      padding: const EdgeInsets.all(Spacing.lg),
      decoration: BoxDecoration(
        color: colors.surfaceLowest,
        borderRadius: Radii.all(Radii.xl),
        boxShadow: Shadows.cloud,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("TODAY'S INTAKE", style: CrudoText.label),
                    const SizedBox(height: Spacing.sm),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text('${consumed.kcal.round()}', style: CrudoText.stat),
                        const SizedBox(width: Spacing.xs),
                        Text(
                          '/${planned.kcal.round()} kcal',
                          style: CrudoText.bodyLg.copyWith(
                            color: colors.onSurfaceMut,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              MacroRing(
                value: _share(consumed.kcal, planned.kcal),
                size: _ringSize,
                center: Icon(
                  Icons.local_fire_department_outlined,
                  size: IconSizes.lg,
                  color: colors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacing.lg),
          Row(
            children: [
              Expanded(
                child: _MacroBar(
                  label: 'Protein',
                  value: consumed.protein,
                  total: planned.protein,
                  color: colors.primary,
                ),
              ),
              const SizedBox(width: Spacing.md),
              Expanded(
                child: _MacroBar(
                  label: 'Carbs',
                  value: consumed.carbs,
                  total: planned.carbs,
                  color: colors.gold,
                ),
              ),
              const SizedBox(width: Spacing.md),
              Expanded(
                child: _MacroBar(
                  label: 'Fats',
                  value: consumed.fats,
                  total: planned.fats,
                  color: colors.bronze,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MacroBar extends StatelessWidget {
  const _MacroBar({
    required this.label,
    required this.value,
    required this.total,
    required this.color,
  });

  final String label;
  final double value;
  final double total;
  final Color color;

  static const _barHeight = 4.0; // prototype 3px → snapped to grid

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CrudoColors>()!;
    final share = total <= 0 ? 0.0 : (value / total).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: CrudoText.labelMd.copyWith(color: colors.onSurfaceVar),
            ),
            Text(
              '${value.round()}/${total.round()}g',
              style: CrudoText.labelMd.copyWith(color: colors.onSurface),
            ),
          ],
        ),
        const SizedBox(height: Spacing.xs),
        ClipRRect(
          borderRadius: Radii.all(Radii.full),
          child: SizedBox(
            height: _barHeight,
            child: LinearProgressIndicator(
              value: share,
              backgroundColor: colors.outline,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ),
      ],
    );
  }
}
```

- [ ] **Step 7:** `streak_chip.dart` (gradient snapped to tokens — the prototype's raw `#1a3d3a` is sketch, use `primarySoft→primary` 135° per the CTA convention):

```dart
// lib/ui/features/today/views/streak_chip.dart
import 'package:flutter/material.dart';

import '../../../core/themes/colors.dart';
import '../../../core/themes/dimensions.dart';
import '../../../core/themes/typography.dart';

/// Floating streak pill, inset over the intake card. Reads the stub
/// streakCountProvider until S12 lands the real engine.
class StreakChip extends StatelessWidget {
  const StreakChip({required this.count, this.onTap, super.key});

  final int count;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CrudoColors>()!;
    return Semantics(
      label: '$count-day streak',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.sm + Spacing.xs, // 12 on-grid
            vertical: Spacing.xs,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [colors.primarySoft, colors.primary],
            ),
            borderRadius: Radii.all(Radii.full),
            boxShadow: Shadows.cloud,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.local_fire_department,
                size: IconSizes.sm,
                color: colors.gold,
              ),
              const SizedBox(width: Spacing.xs),
              Text(
                '$count-day streak',
                style: CrudoText.labelMd.copyWith(
                  color: colors.surfaceLowest,
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

- [ ] **Step 8:** `nudge_card.dart`:

```dart
// lib/ui/features/today/views/nudge_card.dart
import 'package:flutter/material.dart';

import '../../../core/themes/colors.dart';
import '../../../core/themes/dimensions.dart';
import '../../../core/themes/typography.dart';

/// End-of-day encouragement strip (today only). Tonal — surfaceLow on
/// surface, no shadow, no border.
class NudgeCard extends StatelessWidget {
  const NudgeCard({required this.title, required this.body, super.key});

  final String title;
  final String body;

  static const _iconCircle = 40.0; // component size, 4px grid

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CrudoColors>()!;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.lg,
        vertical: Spacing.md,
      ),
      decoration: BoxDecoration(
        color: colors.surfaceLow,
        borderRadius: Radii.all(Radii.lg),
      ),
      child: Row(
        children: [
          Container(
            width: _iconCircle,
            height: _iconCircle,
            decoration: BoxDecoration(
              color: colors.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.auto_awesome,
              size: IconSizes.md,
              color: colors.primary,
            ),
          ),
          const SizedBox(width: Spacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: CrudoText.body.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colors.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(body, style: CrudoText.body),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

(`SizedBox(height: 2)` is a painted-adjacent micro-gap — if `flutter analyze`/review flags it, use `Spacing.xs`.)

- [ ] **Step 9:** Previews — add to `lib/previews.dart` following the existing pattern: `DayStrip` (mid-week selection), `IntakeCard` (60% day), `StreakChip` (12), `NudgeCard`, `MealCard` with `snoozedTimeLabel`.

- [ ] **Step 10:** Record in `docs/design_system.md §5`: day-pill 44×60, macro-bar height 4 (3→4 snap), nudge icon circle 40, `CrudoText.stat` 56, `bronze` color. Run `flutter test && dart format . && flutter analyze` — green/clean. Report done for review.

---

### Task 5: Meal sheet + snooze sheet

**Role:** ui · **Skills:** `flutter-add-widget-test`, `flutter-riverpod-arch`, `flutter-expert`
**Files:** Create `lib/ui/features/today/views/meal_sheet.dart`, `lib/ui/features/today/views/snooze_sheet.dart` · Test `test/ui/features/today/views/meal_sheet_test.dart`, `test/ui/features/today/views/snooze_sheet_test.dart`
**Contract:**

```dart
// Opens the marking sheet for one scheduled meal of one day.
void showMealSheet(BuildContext context, {required DateTime date,
    required String mealId, bool readOnly = false});
// MealSheet (ConsumerWidget): watches dayControllerProvider(date) — checklist
// re-derives live. Footer (readOnly: hidden): PrimaryCta 'Ate it', 'Skip'
// secondary (enabled iff canSkipMeal), 'Snooze' secondary (visible iff
// canSnoozeMeal) → opens SnoozeSheet. StateError from any op → showCrudoToast.

// SnoozeSheet (ConsumerStatefulWidget): presets [10, 15, 20, 30] min;
// preset disabled iff now+m exceeds maxSnoozeUntil(day, mealId, now);
// confirm → dayController.snooze(mealId, now+m) → pops.
```

**Out of scope:** screen composition (Task 6); swap/replace (S08).

- [ ] **Step 1:** Write the failing tests:

```dart
// test/ui/features/today/views/meal_sheet_test.dart
import 'package:checks/checks.dart';
import 'package:crudo/config/app_config.dart';
import 'package:crudo/config/di.dart';
import 'package:crudo/data/services/id_generator.dart';
import 'package:crudo/data/services/seed_service.dart';
import 'package:crudo/domain/food/food.dart';
import 'package:crudo/ui/core/themes/theme.dart';
import 'package:crudo/ui/features/today/view_models/day_controller.dart';
import 'package:crudo/ui/features/today/view_models/today_providers.dart';
import 'package:crudo/ui/features/today/views/meal_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeIdGenerator implements IdGenerator {
  int _n = 0;
  @override
  String newId() => 'sm-${_n++}';
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late List<Food> seedFoods;
  setUpAll(() async => seedFoods = await SeedService().loadFoods());

  final now = DateTime(2026, 6, 4, 9, 30);
  final today = DateTime.utc(2026, 6, 4);

  late ProviderContainer container;

  Widget app({bool readOnly = false}) {
    container = ProviderContainer(
      overrides: [
        appConfigProvider.overrideWithValue(AppConfig(flavor: Flavor.dev)),
        seedFoodsProvider.overrideWithValue(seedFoods),
        clockProvider.overrideWithValue(() => now),
        idGeneratorProvider.overrideWithValue(FakeIdGenerator()),
      ],
    );
    addTearDown(container.dispose);
    return UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: crudoTheme,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => showMealSheet(
                  context,
                  date: today,
                  mealId: 'sm-0', // breakfast — first minted id
                  readOnly: readOnly,
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> open(WidgetTester tester, {bool readOnly = false}) async {
    await tester.pumpWidget(app(readOnly: readOnly));
    // materialize today before opening:
    await container.read(dayControllerProvider(today).future);
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('shows name, time and the 4-ingredient checklist',
      (tester) async {
    await open(tester);
    expect(find.text('Protein Oats Bowl'), findsOneWidget);
    expect(find.textContaining('08:00'), findsOneWidget);
    expect(find.textContaining('Oats'), findsWidgets);
    expect(find.byKey(const ValueKey('item-check-0')), findsOneWidget);
    expect(find.byKey(const ValueKey('item-check-3')), findsOneWidget);
  });

  testWidgets('tapping an item checks it; status label flips to PARTIAL',
      (tester) async {
    await open(tester);
    await tester.tap(find.byKey(const ValueKey('item-check-0')));
    await tester.pumpAndSettle();
    expect(find.text('PARTIAL'), findsOneWidget);
    final day = await container.read(dayControllerProvider(today).future);
    check(day.meals.first.meal.items.first.checked).isTrue();
  });

  testWidgets('Ate it marks all and closes', (tester) async {
    await open(tester);
    await tester.tap(find.text('Ate it'));
    await tester.pumpAndSettle();
    expect(find.text('Ate it'), findsNothing); // sheet closed
    final day = await container.read(dayControllerProvider(today).future);
    check(day.meals.first.meal.allChecked).isTrue();
  });

  testWidgets('Skip skips and closes', (tester) async {
    await open(tester);
    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();
    final day = await container.read(dayControllerProvider(today).future);
    check(day.meals.first.skippedAt).isNotNull();
  });

  testWidgets('readOnly hides all actions, taps are inert', (tester) async {
    await open(tester, readOnly: true);
    expect(find.text('Ate it'), findsNothing);
    expect(find.text('Skip'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('item-check-0')));
    await tester.pumpAndSettle();
    final day = await container.read(dayControllerProvider(today).future);
    check(day.meals.first.meal.anyChecked).isFalse();
  });
}
```

```dart
// test/ui/features/today/views/snooze_sheet_test.dart — same harness
// (copy the container/app scaffolding, but the button opens SnoozeSheet
// via showCrudoSheet for mealId 'sm-2' — the 16:00 snack; next slot 19:00).
// Tests:
// 1. renders the 4 presets; with now=15:55 local, presets 10/15/20/30:
//    15:55+30 = 16:25 < 19:00 → ALL enabled; tap 15 → confirm
//    'Snooze 15m' → snoozedUntil == 16:10 local (UTC in the domain).
// 2. with now=18:45 local: 10 min (18:55 < 19:00... wait — bound is the
//    NEXT slot 19:00) → 10 enabled, 20/30 disabled (18:45+20=19:05 > 19:00);
//    disabled preset tap does nothing (selection stays).
// 3. confirm pops the sheet and the card-facing state holds the new time.
//    (Use clockProvider override per test; reuse FakeIdGenerator ids.)
```

Write test 2's assertions concretely: after pumping with `now = DateTime(2026, 6, 4, 18, 45)`, `find.byKey(ValueKey('snooze-preset-30'))` exists but tapping it then tapping the CTA still snoozes by the last *enabled* selection — simpler: assert the preset tile renders with disabled styling via a `ValueKey`d `Opacity`/flag, and that tapping CTA with `15` selected at 18:45 succeeds (`18:45+15=19:00`? — `snoozeMeal` rejects `until > bound`; 19:00 == bound exactly is allowed (`isAfter` check) — assert success).

- [ ] **Step 2:** Run them — FAIL.

- [ ] **Step 3:** Implement `meal_sheet.dart`:

```dart
// lib/ui/features/today/views/meal_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../domain/services/meal_lifecycle.dart';
import '../../../../domain/services/meal_status.dart';
import '../../../core/themes/colors.dart';
import '../../../core/themes/dimensions.dart';
import '../../../core/themes/typography.dart';
import '../../../core/widgets/primary_cta.dart';
import '../../../core/widgets/sheet.dart';
import '../../../core/widgets/toast.dart';
import '../view_models/day_controller.dart';
import '../view_models/today_providers.dart';
import 'formatting.dart';
import 'snooze_sheet.dart';

/// Inline marking sheet (S06 stand-in for the S08 mealDetail route).
void showMealSheet(
  BuildContext context, {
  required DateTime date,
  required String mealId,
  bool readOnly = false,
}) {
  showCrudoSheet<void>(
    context,
    builder: (_) => MealSheet(date: date, mealId: mealId, readOnly: readOnly),
  );
}

class MealSheet extends ConsumerWidget {
  const MealSheet({
    required this.date,
    required this.mealId,
    this.readOnly = false,
    super.key,
  });

  final DateTime date;
  final String mealId;
  final bool readOnly;

  Future<void> _run(BuildContext context, Future<void> Function() op,
      {bool pop = false}) async {
    try {
      await op();
      if (pop && context.mounted) Navigator.of(context).pop();
    } on StateError {
      if (context.mounted) {
        showCrudoToast(context, "That can't be changed anymore.");
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<CrudoColors>()!;
    final day = ref.watch(dayControllerProvider(date)).value;
    final meal =
        day?.meals.where((m) => m.id == mealId).firstOrNull;
    if (day == null || meal == null) return const SizedBox.shrink();

    final now = ref.watch(clockProvider)();
    final today = ref.watch(todayProvider);
    final status = deriveMealStatus(meal, day.date, now);
    final ctrl = ref.read(dayControllerProvider(date).notifier);
    final tag = meal.meal.tags.isEmpty ? 'Meal' : _tagLabel(meal.meal.tags.first);

    return SheetScaffold(
      label: '${mealTimeLabel(meal.time)} · $tag · ${status.name}',
      title: meal.meal.name,
      body: ListView(
        shrinkWrap: true,
        children: [
          for (final (i, item) in meal.meal.items.indexed)
            _ItemRow(
              key: ValueKey('item-check-$i'),
              name: item.food.name,
              grams: item.food.grams.value,
              kcal: item.food.kcal,
              checked: item.checked,
              colors: colors,
              onTap: readOnly
                  ? null
                  : () => _run(
                        context,
                        () => item.checked
                            ? ctrl.uncheckItem(mealId, i)
                            : ctrl.checkItem(mealId, i),
                      ),
            ),
        ],
      ),
      cta: readOnly
          ? null
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PrimaryCta(
                  label: 'Ate it',
                  onPressed: () =>
                      _run(context, () => ctrl.markAllEaten(mealId), pop: true),
                ),
                const SizedBox(height: Spacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: _SecondaryAction(
                        label: 'Skip',
                        enabled: canSkipMeal(day, mealId, today),
                        colors: colors,
                        onTap: () =>
                            _run(context, () => ctrl.skipMeal(mealId), pop: true),
                      ),
                    ),
                    if (canSnoozeMeal(day, mealId, now, today)) ...[
                      const SizedBox(width: Spacing.sm),
                      Expanded(
                        child: _SecondaryAction(
                          label: 'Snooze',
                          enabled: true,
                          colors: colors,
                          onTap: () => showCrudoSheet<void>(
                            context,
                            builder: (_) =>
                                SnoozeSheet(date: date, mealId: mealId),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
    );
  }
}

String _tagLabel(Enum tag) {
  final n = tag.name;
  return n[0].toUpperCase() + n.substring(1);
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({
    required this.name,
    required this.grams,
    required this.kcal,
    required this.checked,
    required this.colors,
    this.onTap,
    super.key,
  });

  final String name;
  final double grams;
  final double kcal;
  final bool checked;
  final CrudoColors colors;
  final VoidCallback? onTap;

  static const _checkSize = 28.0; // component size, 4px grid

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
        child: Row(
          children: [
            AnimatedContainer(
              duration: Durations.fast,
              width: _checkSize,
              height: _checkSize,
              decoration: BoxDecoration(
                color: checked ? colors.primary : colors.surfaceLow,
                shape: BoxShape.circle,
              ),
              child: checked
                  ? Icon(Icons.check,
                      size: IconSizes.sm, color: colors.surfaceLowest)
                  : null,
            ),
            const SizedBox(width: Spacing.md),
            Expanded(
              child: Text(
                name,
                style: CrudoText.body.copyWith(color: colors.onSurface),
              ),
            ),
            Text(
              '${grams.round()}g · ${kcal.round()} kcal',
              style: CrudoText.body.copyWith(color: colors.onSurfaceMut),
            ),
          ],
        ),
      ),
    );
  }
}

class _SecondaryAction extends StatelessWidget {
  const _SecondaryAction({
    required this.label,
    required this.enabled,
    required this.colors,
    required this.onTap,
  });

  final String label;
  final bool enabled;
  final CrudoColors colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.4,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: Spacing.md),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: colors.surfaceLow,
            borderRadius: Radii.all(Radii.full),
          ),
          child: Text(
            label,
            style: CrudoText.body.copyWith(
              fontWeight: FontWeight.w700,
              color: colors.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 4:** Implement `snooze_sheet.dart`:

```dart
// lib/ui/features/today/views/snooze_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../domain/services/meal_lifecycle.dart';
import '../../../core/themes/colors.dart';
import '../../../core/themes/dimensions.dart';
import '../../../core/themes/typography.dart';
import '../../../core/widgets/primary_cta.dart';
import '../../../core/widgets/sheet.dart';
import '../../../core/widgets/toast.dart';
import '../view_models/day_controller.dart';
import '../view_models/today_providers.dart';

/// Commitment-style snooze: short presets, bounded by the next meal /
/// midnight (sheets.jsx SnoozeSheet).
class SnoozeSheet extends ConsumerStatefulWidget {
  const SnoozeSheet({required this.date, required this.mealId, super.key});

  final DateTime date;
  final String mealId;

  @override
  ConsumerState<SnoozeSheet> createState() => _SnoozeSheetState();
}

class _SnoozeSheetState extends ConsumerState<SnoozeSheet> {
  static const _presets = [10, 15, 20, 30];
  int _selected = 15;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CrudoColors>()!;
    final day = ref.watch(dayControllerProvider(widget.date)).value;
    if (day == null) return const SizedBox.shrink();
    final now = ref.watch(clockProvider)();
    final bound = maxSnoozeUntil(day, widget.mealId, now);

    bool enabled(int m) =>
        !now.add(Duration(minutes: m)).toUtc().isAfter(bound);

    return SheetScaffold(
      label: 'Commitment',
      title: 'Snooze, then eat.',
      body: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Short delay only — can't push past your next meal.",
            style: CrudoText.body,
          ),
          const SizedBox(height: Spacing.lg),
          Row(
            children: [
              for (final m in _presets) ...[
                Expanded(
                  child: _PresetTile(
                    key: ValueKey('snooze-preset-$m'),
                    minutes: m,
                    selected: _selected == m,
                    enabled: enabled(m),
                    colors: colors,
                    onTap: () => setState(() => _selected = m),
                  ),
                ),
                if (m != _presets.last) const SizedBox(width: Spacing.sm),
              ],
            ],
          ),
        ],
      ),
      cta: PrimaryCta(
        label: 'Snooze ${_selected}m',
        enabled: enabled(_selected),
        onPressed: () async {
          try {
            await ref
                .read(dayControllerProvider(widget.date).notifier)
                .snooze(widget.mealId, now.add(Duration(minutes: _selected)));
            if (context.mounted) Navigator.of(context).pop();
          } on StateError {
            if (context.mounted) {
              showCrudoToast(context, "Can't snooze that far.");
            }
          }
        },
      ),
    );
  }
}

class _PresetTile extends StatelessWidget {
  const _PresetTile({
    required this.minutes,
    required this.selected,
    required this.enabled,
    required this.colors,
    required this.onTap,
    super.key,
  });

  final int minutes;
  final bool selected;
  final bool enabled;
  final CrudoColors colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.4,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: AnimatedContainer(
          duration: Durations.fast,
          padding: const EdgeInsets.symmetric(vertical: Spacing.md),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? colors.primary : colors.surfaceLow,
            borderRadius: Radii.all(Radii.md),
          ),
          child: Column(
            children: [
              Text(
                '$minutes',
                style: CrudoText.headline.copyWith(
                  color: selected ? colors.surfaceLowest : colors.onSurface,
                ),
              ),
              Text(
                'MIN',
                style: CrudoText.label.copyWith(
                  color: (selected ? colors.surfaceLowest : colors.onSurfaceMut)
                      .withValues(alpha: 0.7),
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

(If `PrimaryCta` lacks an `enabled` param check its actual API — S04 spec lists `enabled=true`, so it exists.)

- [ ] **Step 5:** Run `flutter test test/ui/features/today/ && dart format . && flutter analyze` — green/clean. Report done for review.

---

### Task 6: TodayScreen composition + lifecycle wiring

**Role:** ui · **Skills:** `flutter-add-widget-test`, `flutter-riverpod-arch`, `flutter-build-responsive-layout`, `flutter-expert`
**Files:** Rewrite `lib/ui/features/today/views/today_screen.dart` · Test `test/ui/features/today/views/today_screen_test.dart` · Update any S04 showcase assertions that pumped the old placeholder (check `test/routing/app_router_test.dart` — the 'Today' title finder must still pass; fix finders if they asserted showcase dummy content)
**Contract:** `TodayScreen` = `ConsumerStatefulWidget` + `WidgetsBindingObserver`; on resume → `todayProvider.notifier.refresh()` + reschedule the midnight `Timer` (`endOfDayLocal(localDateLabel(now)).difference(now) + 1s`); dispose cancels. Composition top-to-bottom: appbar (dateHeadline + greeting + calendar IconButton → toast 'Calendar — coming soon') · DayStrip · IntakeCard with StreakChip stacked inset (top-right, overlapping by `Spacing.sm`) · meals header with done/partial counts · MealCards · NudgeCard (today only). Tap rules: today → `showMealSheet`; past → `showMealSheet(readOnly: true)`; future → card not tappable. Empty states: past empty day → 'No data for this day.' · today/future empty → 'Rest day — nothing planned.'
**Out of scope:** anything S08+ (swap, meal detail route), calendar sheet (S13), streak sheet (S12).

- [ ] **Step 1:** Write the failing tests (same harness as Task 5 — dev flavor, seeded foods, fake clock/ids; pump the real `TodayScreen` inside `MaterialApp(theme: crudoTheme, home: ...)` with `UncontrolledProviderScope`):

```dart
// test/ui/features/today/views/today_screen_test.dart — cases:
// 1. boots: greeting 'Good morning' renders; date headline 'Thursday, June 4';
//    4 MealCards; intake card shows '0' consumed and the planned total;
//    '0/4 complete' header; streak chip '0-day streak'.
// 2. eager persist: after first pump, dayRepository.getByDate(today) != null.
// 3. tap a card → MealSheet opens (find 'Ate it'); tap 'Ate it' →
//    sheet closes, card shows DONE, intake consumed kcal > 0,
//    header '1/4 complete'.
// 4. mark one ingredient via sheet → header gains '· 1 partial'.
// 5. select tomorrow in the strip → 4 cards all UPCOMING, consumed '0',
//    cards not tappable (tap → no sheet), no NudgeCard,
//    repo has NO row for tomorrow.
// 6. select a past day (repo miss) → 'No data for this day.'
// 7. snoozed meal renders both times: snooze breakfast (via controller
//    directly: ctrl.snooze('sm-0', now+15min)) → pump → card shows '08:00'
//    struck-through and '09:45' (the snoozed local time).
// 8. prod-flavor container (no seed) → 'Rest day — nothing planned.'
// 9. nudge: with 1 of 4 meals done, NudgeCard shows
//    'You're {pct}% of the way there.' where pct = round(consumed/planned*100),
//    and '3 meals remain. A done day keeps the streak.'
```

Write each as a real `testWidgets` with concrete finders (`find.text`, `ValueKey('day-pill-…')`, `find.byType(MealCard)`); reuse the `FakeIdGenerator` so meal ids are `sm-0…sm-3`.

- [ ] **Step 2:** Run — FAIL.

- [ ] **Step 3:** Implement `today_screen.dart`:

```dart
// lib/ui/features/today/views/today_screen.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../domain/day/day.dart';
import '../../../../domain/services/meal_lifecycle.dart';
import '../../../../domain/services/meal_status.dart';
import '../../../../domain/shared/enums.dart';
import '../../../core/themes/colors.dart';
import '../../../core/themes/dimensions.dart';
import '../../../core/themes/typography.dart';
import '../../../core/widgets/meal_card.dart';
import '../../../core/widgets/toast.dart';
import '../view_models/day_controller.dart';
import '../view_models/today_providers.dart';
import 'day_strip.dart';
import 'formatting.dart';
import 'intake_card.dart';
import 'meal_sheet.dart';
import 'nudge_card.dart';
import 'streak_chip.dart';

class TodayScreen extends ConsumerStatefulWidget {
  const TodayScreen({super.key});

  @override
  ConsumerState<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends ConsumerState<TodayScreen>
    with WidgetsBindingObserver {
  Timer? _midnightTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scheduleMidnightTick();
  }

  @override
  void dispose() {
    _midnightTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(todayProvider.notifier).refresh();
      _scheduleMidnightTick();
    }
  }

  /// Rollover is derived, never timed in the domain (S05 §4.4) — this
  /// timer only pokes todayProvider when local midnight passes.
  void _scheduleMidnightTick() {
    _midnightTimer?.cancel();
    final now = ref.read(clockProvider)();
    final nextMidnight = endOfDayLocal(localDateLabel(now));
    _midnightTimer =
        Timer(nextMidnight.difference(now) + const Duration(seconds: 1), () {
      ref.read(todayProvider.notifier).refresh();
      _scheduleMidnightTick();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CrudoColors>()!;
    final today = ref.watch(todayProvider);
    final selected = ref.watch(selectedDateProvider);
    final dayAsync = ref.watch(dayControllerProvider(selected));
    final profile = ref.watch(profileProvider).value;
    final streak = ref.watch(streakCountProvider).value ?? 0;
    final now = ref.read(clockProvider)();
    final isToday = selected.isAtSameMomentAs(today);
    final isPast = selected.isBefore(today);

    return SafeArea(
      child: dayAsync.when(
        loading: () => const SizedBox.shrink(),
        error: (e, _) =>
            Center(child: Text('Something went wrong', style: CrudoText.body)),
        data: (day) => ListView(
          padding: const EdgeInsets.fromLTRB(
            Spacing.md, Spacing.md, Spacing.md, Spacing.xxl,
          ),
          children: [
            _AppBar(
              dateLabel: dateHeadline(selected),
              greeting: greetingFor(now, profile?.displayName),
              onCalendarTap: () =>
                  showCrudoToast(context, 'Calendar — coming soon'),
            ),
            const SizedBox(height: Spacing.md),
            DayStrip(
              dates: weekOf(today),
              selected: selected,
              today: today,
              onSelect: ref.read(selectedDateProvider.notifier).select,
            ),
            const SizedBox(height: Spacing.lg),
            Stack(
              clipBehavior: Clip.none,
              children: [
                IntakeCard(
                  consumed: consumedMacros(day),
                  planned: plannedMacros(day),
                ),
                Positioned(
                  top: -Spacing.sm,
                  right: Spacing.lg,
                  child: StreakChip(count: streak),
                ),
              ],
            ),
            const SizedBox(height: Spacing.xl),
            if (day.meals.isEmpty)
              _EmptyState(
                message: isPast
                    ? 'No data for this day.'
                    : 'Rest day — nothing planned.',
                colors: colors,
              )
            else ...[
              _MealsHeader(day: day, now: now),
              const SizedBox(height: Spacing.sm),
              for (final meal in day.meals) ...[
                Builder(builder: (context) {
                  final status = deriveMealStatus(meal, day.date, now);
                  final snoozed = meal.snoozedUntil != null &&
                          status == MealStatus.upcoming
                      ? timeOfDayLabel(meal.snoozedUntil!.toLocal())
                      : null;
                  return MealCard(
                    title: meal.meal.name,
                    timeLabel: mealTimeLabel(meal.time),
                    snoozedTimeLabel: snoozed,
                    mealTypeLabel: meal.meal.tags.isEmpty
                        ? 'Meal'
                        : meal.meal.tags.first.name[0].toUpperCase() +
                            meal.meal.tags.first.name.substring(1),
                    macros: mealSnapshotMacros(meal.meal),
                    ingredientNames: [
                      for (final i in meal.meal.items) i.food.name,
                    ],
                    status: status,
                    onTap: selected.isAfter(today)
                        ? null
                        : () => showMealSheet(
                              context,
                              date: selected,
                              mealId: meal.id,
                              readOnly: !isToday,
                            ),
                  );
                }),
                const SizedBox(height: Spacing.sm),
              ],
              if (isToday) _nudge(day, now),
            ],
          ],
        ),
      ),
    );
  }

  Widget _nudge(Day day, DateTime now) {
    final planned = plannedKcal(day);
    final consumed = consumedKcal(day);
    final remaining = day.meals
        .where((m) {
          final s = deriveMealStatus(m, day.date, now);
          return s == MealStatus.upcoming;
        })
        .length;
    if (planned <= 0 || remaining == 0) return const SizedBox.shrink();
    final pct = (consumed / planned * 100).round();
    return Padding(
      padding: const EdgeInsets.only(top: Spacing.md),
      child: NudgeCard(
        title: "You're $pct% of the way there.",
        body: remaining == 1
            ? 'One meal remains. A done day keeps the streak.'
            : '$remaining meals remain. A done day keeps the streak.',
      ),
    );
  }
}

class _AppBar extends StatelessWidget {
  const _AppBar({
    required this.dateLabel,
    required this.greeting,
    required this.onCalendarTap,
  });

  final String dateLabel;
  final String greeting;
  final VoidCallback onCalendarTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CrudoColors>()!;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(dateLabel.toUpperCase(), style: CrudoText.label),
              const SizedBox(height: Spacing.xs),
              Text(greeting, style: CrudoText.headlineSm),
            ],
          ),
        ),
        IconButton(
          onPressed: onCalendarTap,
          icon: Icon(
            Icons.calendar_today_outlined,
            size: IconSizes.md,
            color: colors.onSurface,
          ),
        ),
      ],
    );
  }
}

class _MealsHeader extends StatelessWidget {
  const _MealsHeader({required this.day, required this.now});

  final Day day;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    var done = 0;
    var partial = 0;
    for (final m in day.meals) {
      switch (deriveMealStatus(m, day.date, now)) {
        case MealStatus.done:
          done++;
        case MealStatus.partial:
          partial++;
        case MealStatus.upcoming || MealStatus.skipped:
          break;
      }
    }
    final counts = partial > 0
        ? '$done/${day.meals.length} complete · $partial partial'
        : '$done/${day.meals.length} complete';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Expanded(child: Text('Meals', style: CrudoText.headline)),
        Text(counts, style: CrudoText.label),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message, required this.colors});

  final String message;
  final CrudoColors colors;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Spacing.xxl),
      child: Center(
        child: Text(
          message,
          style: CrudoText.body.copyWith(color: colors.onSurfaceMut),
        ),
      ),
    );
  }
}
```

(`mealSnapshotMacros` comes from `domain/services/nutrition.dart` — add that import.)

- [ ] **Step 4:** Run `dart run build_runner build` if needed, then the new test file — PASS. Fix any S04-era test that asserted the showcase placeholder content.

- [ ] **Step 5:** Full gate: `dart format . && flutter analyze && flutter test` — clean/green (architecture test included).

- [ ] **Step 6:** Smoke-run `flutter run --flavor dev -t lib/main_development.dart --dart-define-from-file=config/dev.json` if a device/simulator is available — verify the seeded plan renders, marking + snooze work. (Skip if no device; note it in the report.)

- [ ] **Step 7:** Run `@review` on the whole working-tree diff (worker's last step), fix any `BLOCK`, then write `.opencode/handoff/2026-06-04-s06-today-screen.report.md` per the workflow format. Report done for review.
