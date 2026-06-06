# S06.1 Today Screen Refinements — Implementation Plan

> **For the worker:** implement task-by-task, top to bottom; each task = contract + steps; read the `.agents/skills` each task names before starting it. Spec: `docs/specs/2026-06-06-s06-1-today-refinements.md`. Repo rules: `AGENTS.md`. Workers do **not** commit — finish each task with format → analyze → test, then report done for review.

**Goal:** Four refinements to the shipped S06 Today tab: (1) intake hero freezes while the meal sheet is open and animates to the new totals on close, (2) snooze presets are relative to `max(now, scheduledTime)` with the resulting time + "We'll remind you at {time}" shown in the sheet, (3) meal sheet gets the `meal.jsx` action tiles (Snooze + Swap stub) and dynamic footer (Skip + Mark Done / Save Partial), (4) the meal card's status circle becomes a one-tap complete/undo control.

**Architecture:** Pure-Dart domain ops first (`Day.unmarkAll`, `snoozeBaseFor`, `canUnmarkMeal`), then the Riverpod layer (`DayController.unmarkAll`, new `intakeFreezeProvider`), then the three UI surfaces (IntakeCard, SnoozeSheet, MealSheet, MealCard + TodayScreen wiring). Persistence behavior is untouched — every toggle still saves immediately; only the hero's *rendering* defers. Dependency rule as always: View → Controller → Repository; domain imports nothing.

**Tech stack:** Flutter, Riverpod 3 codegen (`@riverpod`), freezed domain, `package:checks` assertions, `flutter_test`. Codegen: `dart run build_runner build` after adding the new provider.

**Visual target:** `docs/design/prototype/screens/meal.jsx` lines 91–106 (tiles) + 110–119 (footer) — composition only; every dimension snaps to `lib/ui/core/themes/dimensions.dart` tokens per `docs/design_system.md §5`.

---

## Task 1: Domain — `Day.unmarkAll`, `snoozeBaseFor`, `canUnmarkMeal`

**Role:** pure-Dart domain engineer. No Flutter/Riverpod imports anywhere in this task.

**Goal:** the two domain primitives the UI tasks need: an undo op for one-tap complete, and the snooze base rule "presets are relative to when the meal is due, not to the tap".

**Files:**
- Modify: `lib/domain/day/day.dart` (add `unmarkAll` after `markAllEaten`, ~line 113)
- Modify: `lib/domain/services/meal_lifecycle.dart` (add `canUnmarkMeal` + `snoozeBaseFor` near `canSnoozeMeal`, ~line 40)
- Test: `test/domain/day/day_ops_test.dart` (extend — reuse its `_meal`/`day` fixtures)
- Test: `test/domain/services/meal_lifecycle_test.dart` (extend — follow its existing fixture style)

**Contract:**

```dart
// day.dart — inside Day, after markAllEaten:

/// Undo for the one-tap complete: clears every item's stamp. Leaves
/// skippedAt / snoozedUntil untouched (marking ops never touch the stamps);
/// derivation falls back to them, so skipped → done → skipped round-trips.
Day unmarkAll(String mealId, DateTime today) {
  _ensureUnlocked(today);
  final meal = _mealById(mealId);
  if (!meal.meal.anyChecked) {
    throw StateError('cannot unmark $mealId: nothing is checked');
  }
  final items = [
    for (final i in meal.meal.items) i.copyWith(checkedAt: null),
  ];
  return _withMeal(meal.copyWith(meal: meal.meal.copyWith(items: items)));
}
```

```dart
// meal_lifecycle.dart — after canSnoozeMeal:

bool canUnmarkMeal(Day day, String mealId, DateTime today) {
  if (isDayLocked(day, today)) return false;
  final meal = day.meals.where((m) => m.id == mealId).firstOrNull;
  return meal != null && meal.meal.anyChecked;
}

/// Snooze base (S06.1): presets are relative to when the meal is DUE, not
/// to the tap — max(now, the meal's local instant on its day), as UTC.
/// A future meal snoozed early gets scheduledTime + preset; a past-due
/// meal gets now + preset. Re-snooze recomputes from the same base
/// (snoozeMeal overwrites) — never compounds.
DateTime snoozeBaseFor(Day day, String mealId, DateTime now) {
  final meal = day.meals.firstWhere(
    (m) => m.id == mealId,
    orElse: () => throw StateError('no meal with id $mealId'),
  );
  final scheduled = localInstantAt(day.date, meal.time).toUtc();
  final nowUtc = now.toUtc();
  return scheduled.isAfter(nowUtc) ? scheduled : nowUtc;
}
```

Note `unmarkAll` deliberately takes no `now` — nothing is stamped.

**Steps (TDD):**

- [ ] **1. Write the failing tests.** In `test/domain/day/day_ops_test.dart`, new group reusing the file's `day(...)` fixture (today = `DateTime.utc(2026, 6, 4)`, now = local noon):

```dart
group('unmarkAll', () {
  test('clears every checkedAt', () {
    final d = day(checkedOf2: 2).unmarkAll('lunch', today);
    check(d.meals[1].meal.items[0].checkedAt).isNull();
    check(d.meals[1].meal.items[1].checkedAt).isNull();
  });
  test('preserves skippedAt and snoozedUntil', () {
    final skipped = day().skipMeal('lunch', now, today);
    final done = skipped.markAllEaten('lunch', now, today);
    final undone = done.unmarkAll('lunch', today);
    check(undone.meals[1].skippedAt).isNotNull();
  });
  test('round-trip: skipped → done → skipped derivation', () {
    final skipped = day().skipMeal('lunch', now, today);
    final done = skipped.markAllEaten('lunch', now, today);
    check(deriveMealStatus(done.meals[1], today, now))
        .equals(MealStatus.done);
    final undone = done.unmarkAll('lunch', today);
    check(deriveMealStatus(undone.meals[1], today, now))
        .equals(MealStatus.skipped);
  });
  test('throws when nothing is checked', () {
    check(() => day().unmarkAll('lunch', today)).throws<StateError>();
  });
  test('throws on a locked day', () {
    check(() => day(checkedOf2: 1).unmarkAll('lunch', DateTime.utc(2026, 6, 5)))
        .throws<StateError>();
  });
  test('throws on unknown meal id', () {
    check(() => day().unmarkAll('nope', today)).throws<StateError>();
  });
});
```

  In `test/domain/services/meal_lifecycle_test.dart` (adapt to its local fixtures — meals at 08:00/13:00/19:00 on `DateTime.utc(2026, 6, 4)`):

```dart
group('snoozeBaseFor', () {
  test('future meal → its scheduled instant (UTC)', () {
    // now = local 10:00, dinner scheduled 19:00
    final base = snoozeBaseFor(d, 'dinner', DateTime(2026, 6, 4, 10));
    check(base).equals(
      localInstantAt(DateTime.utc(2026, 6, 4), MealTime(19 * 60)).toUtc(),
    );
    check(base.isUtc).isTrue();
  });
  test('past-due meal → now', () {
    final now = DateTime(2026, 6, 4, 15, 40); // breakfast 08:00 long passed
    check(snoozeBaseFor(d, 'breakfast', now)).equals(now.toUtc());
  });
  test('unknown meal throws', () {
    check(() => snoozeBaseFor(d, 'nope', DateTime(2026, 6, 4, 10)))
        .throws<StateError>();
  });
});

group('canUnmarkMeal', () {
  test('true only when unlocked and any item checked', () {
    check(canUnmarkMeal(dayChecked, 'lunch', today)).isTrue();
    check(canUnmarkMeal(dayUnchecked, 'lunch', today)).isFalse();
    check(canUnmarkMeal(dayChecked, 'lunch', tomorrow)).isFalse(); // locked
    check(canUnmarkMeal(dayChecked, 'nope', today)).isFalse();
  });
});
```

  (Exact fixture names/`MealTime` construction: mirror what the test file already does — `MealTime` takes minutes-since-midnight, e.g. `MealTime(13 * 60)`.)

- [ ] **2. Run them — must fail** with "The method 'unmarkAll' isn't defined" etc.:
  `flutter test test/domain/day/day_ops_test.dart test/domain/services/meal_lifecycle_test.dart`
- [ ] **3. Implement** the contract code above, verbatim, in the two domain files.
- [ ] **4. Run the same tests — green.** Then the full domain suite: `flutter test test/domain/`.
- [ ] **5.** `dart format .` → `flutter analyze` → `flutter test` (all green). Report done for review.

**Skills:** `.agents/skills/dart-add-unit-test`, `.agents/skills/dart-migrate-to-checks-package`.

**Acceptance:** new ops exist with the exact signatures above; `lib/domain/` still imports no Flutter/Riverpod/JSON; architecture test green.

**Out of scope:** any controller or UI change; touching `snoozeMeal`/`maxSnoozeUntilFor` (unchanged).

---

## Task 2: State — `DayController.unmarkAll` + `intakeFreezeProvider`

**Role:** Riverpod view-model engineer.

**Goal:** plumb the new domain op through the controller; add the tiny freeze notifier the IntakeCard will read.

**Files:**
- Modify: `lib/ui/features/today/view_models/day_controller.dart` (one method after `skipMeal`, ~line 59)
- Create: `lib/ui/features/today/view_models/intake_freeze.dart`
- Codegen: `dart run build_runner build` (generates `intake_freeze.g.dart`)
- Test: `test/ui/features/today/view_models/day_controller_test.dart` (extend)
- Test: `test/ui/features/today/view_models/today_providers_test.dart` (extend with the freeze group)

**Contract:**

```dart
// day_controller.dart — after skipMeal:
Future<void> unmarkAll(String mealId) =>
    _apply((d, now, today) => d.unmarkAll(mealId, today));
```

```dart
// intake_freeze.dart — whole file:
import 'package:crudo/domain/shared/macros.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'intake_freeze.g.dart';

/// Holds the consumed-macros snapshot shown by the intake hero while a meal
/// sheet is open (S06.1): freeze on open, clear on close. Null = render the
/// live value. Persistence is NOT deferred — only the hero's rendering.
@riverpod
class IntakeFreeze extends _$IntakeFreeze {
  @override
  Macros? build() => null;

  void freeze(Macros consumed) => state = consumed;

  void clear() => state = null;
}
```

**Steps (TDD):**

- [ ] **1. Failing controller test** in `day_controller_test.dart`, reusing its existing harness (ProviderContainer + in-memory repos + overridden `clockProvider`):

```dart
test('unmarkAll clears checks, persists and re-emits', () async {
  // arrange: today's day with one meal fully eaten (markAllEaten first)
  await ctrl.markAllEaten(mealId);
  await ctrl.unmarkAll(mealId);
  final day = await container.read(dayControllerProvider(today).future);
  final meal = day.meals.singleWhere((m) => m.id == mealId);
  check(meal.meal.items.every((i) => !i.checked)).isTrue();
  // persisted: repo snapshot agrees
  final persisted = await container.read(persistedDayProvider(today).future);
  check(persisted!.meals.singleWhere((m) => m.id == mealId).meal.anyChecked)
      .isFalse();
});
test('unmarkAll guard: nothing checked → StateError, no write', () async {
  await check(ctrl.unmarkAll(mealId)).throws<StateError>();
});
```

  Failing freeze test in `today_providers_test.dart`:

```dart
group('intakeFreezeProvider', () {
  test('null by default; freeze holds; clear resets', () {
    final container = ProviderContainer.test();
    check(container.read(intakeFreezeProvider)).isNull();
    const snap = Macros(protein: 10, carbs: 20, fats: 5);
    container.read(intakeFreezeProvider.notifier).freeze(snap);
    check(container.read(intakeFreezeProvider)).equals(snap);
    container.read(intakeFreezeProvider.notifier).clear();
    check(container.read(intakeFreezeProvider)).isNull();
  });
});
```

  (Match the container setup/teardown idiom already in those files; `Macros` positional/named args — mirror `test/domain/shared/macros_test.dart` usage.)

- [ ] **2. Run — fail** (method/provider undefined).
- [ ] **3. Implement** both contract snippets; run `dart run build_runner build`.
- [ ] **4. Run the two test files — green.**
- [ ] **5.** `dart format .` → `flutter analyze` → `flutter test`. Report done for review.

**Skills:** `.agents/skills/flutter-riverpod-arch`, `.agents/skills/dart-add-unit-test`.

**Acceptance:** controller op present, freeze provider generated and tested; no view file touched yet.

**Out of scope:** wiring freeze into widgets (Task 3).

---

## Task 3: UI — animated IntakeCard + freeze wiring

**Role:** Flutter UI engineer.

**Goal:** the hero animates every value change (kcal roll, bar growth, ring sweep — one motion: 500 ms, `easeOutCubic`) and renders the frozen snapshot while a meal sheet is open.

**Files:**
- Modify: `lib/ui/core/themes/dimensions.dart` (`Durations.slow`)
- Modify: `docs/design_system.md` (§ motion/dimension table: record `Durations.slow = 500ms` — intake hero settle)
- Modify: `lib/ui/features/today/views/intake_card.dart`
- Modify: `lib/ui/features/today/views/meal_sheet.dart` (`showMealSheet` returns the sheet's future)
- Modify: `lib/ui/features/today/views/today_screen.dart` (freeze/clear around the sheet; frozen ?? live into IntakeCard)
- Test: `test/ui/features/today/views/today_screen_test.dart` (extend)

**Contract:**

```dart
// dimensions.dart — extend Durations:
abstract final class Durations {
  static const fast = Duration(milliseconds: 150);
  static const base = Duration(milliseconds: 200);

  /// Intake-hero settle (S06.1): number roll, bar growth, ring sweep.
  static const slow = Duration(milliseconds: 500);
}
```

```dart
// intake_card.dart — IntakeCard stays a StatelessWidget with the same
// (consumed, planned) params. Shared animation constants:
static const _settleCurve = Curves.easeOutCubic; // with Durations.slow

// kcal figure (replaces the static Text inside the FittedBox row):
TweenAnimationBuilder<double>(
  tween: Tween(end: consumed.kcal),
  duration: Durations.slow,
  curve: _settleCurve,
  builder: (_, kcal, _) => Text('${kcal.round()}', style: CrudoText.stat),
),

// ring (replaces the bare MacroRing):
TweenAnimationBuilder<double>(
  tween: Tween(end: _share(consumed.kcal, planned.kcal)),
  duration: Durations.slow,
  curve: _settleCurve,
  builder: (_, v, child) => MacroRing(value: v, size: _ringSize, center: child),
  child: Icon(
    Icons.local_fire_department_outlined,
    size: IconSizes.lg,
    color: colors.primary,
  ),
),

// _MacroBar: wrap the whole Column body so the grams text AND the bar share
// animate together:
TweenAnimationBuilder<double>(
  tween: Tween(end: value),
  duration: Durations.slow,
  curve: Curves.easeOutCubic,
  builder: (context, v, _) {
    final share = total <= 0 ? 0.0 : (v / total).clamp(0.0, 1.0);
    return Column(/* existing content, using v.round() and share */);
  },
)
```

(`Tween(end: …)` with null `begin` = no animation on first build, animates on subsequent value changes — exactly the wanted semantics.)

```dart
// meal_sheet.dart — showMealSheet now returns the sheet future:
Future<void> showMealSheet(
  BuildContext context, {
  required DateTime date,
  required String mealId,
  bool readOnly = false,
}) {
  return showCrudoSheet<void>(
    context,
    builder: (_) => MealSheet(date: date, mealId: mealId, readOnly: readOnly),
  );
}
```

```dart
// today_screen.dart — data section:
final frozen = ref.watch(intakeFreezeProvider);
// ...
IntakeCard(
  consumed: frozen ?? consumedMacros(day),
  planned: plannedMacros(day),
),

// meal card onTap (today path) — freeze before opening, clear on ANY dismiss:
onTap: selected.isAfter(today)
    ? null
    : () {
        if (isToday) {
          ref
              .read(intakeFreezeProvider.notifier)
              .freeze(consumedMacros(day));
        }
        showMealSheet(
          context,
          date: selected,
          mealId: meal.id,
          readOnly: !isToday,
        ).whenComplete(() {
          if (isToday) ref.read(intakeFreezeProvider.notifier).clear();
        });
      },
```

**Steps (TDD):**

- [ ] **1. Failing widget tests** in `today_screen_test.dart` (reuse its pump harness + provider overrides):

```dart
testWidgets('hero freezes while sheet open, settles after close', (t) async {
  // open today's first meal sheet, read the kcal text, toggle one item,
  // pump Durations.slow — hero kcal text UNCHANGED (frozen);
  // close the sheet (drag down / Navigator.pop), pumpAndSettle —
  // hero kcal text now shows the new consumed total.
});
testWidgets('hero animates between values (intermediate frame differs)', (t) async {
  // with no sheet: trigger a consumed change (markAllEaten via the
  // controller), pump(const Duration(milliseconds: 250)) — kcal text is
  // neither old nor final value; pumpAndSettle — final value.
});
```

  Write these as real tests against the harness in the file (it already opens sheets and asserts intake numbers — follow those tests' structure and finders, e.g. `find.text('$kcal')`).

- [ ] **2. Run — fail** (values update immediately today; no animation).
- [ ] **3. Implement** the four contract snippets.
- [ ] **4. Run `flutter test test/ui/features/today/` — green.** Animation changes can break existing intake assertions that expect instant values — fix those tests by adding `pumpAndSettle` after actions, never by weakening assertions.
- [ ] **5.** `dart format .` → `flutter analyze` → `flutter test`. Report done for review.

**Skills:** `.agents/skills/flutter-add-widget-test`, `.agents/skills/flutter-expert` (const discipline — keep `child:` out of rebuilt builders where possible).

**Acceptance:** spec §1 behavior: toggling in the sheet leaves the hero static; closing animates kcal + 3 bars + ring in one 500 ms motion; quick changes without a sheet animate immediately. `Durations.slow` documented in `design_system.md`.

**Out of scope:** sheet buttons (Task 5), card circle (Task 6).

---

## Task 4: UI — SnoozeSheet on the new base + outcome copy

**Role:** Flutter UI engineer.

**Goal:** presets compute from `snoozeBaseFor`; each enabled tile shows its resulting local time; an info line states "We'll remind you at {time}" for the current selection.

**Files:**
- Modify: `lib/ui/features/today/views/snooze_sheet.dart`
- Test: `test/ui/features/today/views/sheets_test.dart` (extend)

**Contract:**

```dart
// _SnoozeSheetState.build — replace the now-based math:
final base = snoozeBaseFor(day, widget.mealId, now);
final bound = maxSnoozeUntil(day, widget.mealId, now);

DateTime untilFor(int m) => base.add(Duration(minutes: m));
bool enabled(int m) => !untilFor(m).isAfter(bound);

// _PresetTile gains a resulting-time line (third row in the tile column,
// hidden when disabled):
_PresetTile(
  // existing params...
  resultLabel: enabled(m) ? timeOfDayLabel(untilFor(m).toLocal()) : null,
)
// rendered under 'MIN' as: Text(resultLabel!, style: CrudoText.labelMd.
//   copyWith(color: <selected ? surfaceLowest : onSurfaceMut>)) — same
//   selected/unselected color treatment as the 'MIN' line.

// info line — between the preset row and the sheet CTA (body Column):
const SizedBox(height: Spacing.md),
Text(
  "We'll remind you at ${timeOfDayLabel(untilFor(selected).toLocal())}.",
  key: const ValueKey('snooze-info'),
  style: CrudoText.body.copyWith(color: colors.onSurfaceMut),
),

// CTA commit:
.snooze(widget.mealId, untilFor(selected)),
```

Import `formatting.dart` for `timeOfDayLabel`. The default-selection logic (`_preferredPreset`, fall back to largest enabled) stays as is, but `enabled` now uses the base.

**Steps (TDD):**

- [ ] **1. Failing widget tests** in `sheets_test.dart` (it already pumps SnoozeSheet with an overridden clock):

```dart
testWidgets('future meal: presets offset from scheduled time', (t) async {
  // clock at 10:00, meal at 15:00 → select 15 → info line reads
  // "We'll remind you at 15:15."; commit → snoozedUntil == 15:15 local.
});
testWidgets('past-due meal: presets offset from now', (t) async {
  // clock at 15:40, meal at 15:00 → select 15 → "We'll remind you at 15:55."
});
testWidgets('preset tiles show resulting times', (t) async {
  // expect find.text('15:15') etc. on the enabled tiles
});
testWidgets('bound still disables presets', (t) async {
  // next meal 30 min after base → 30m preset disabled (Opacity check, as
  // the existing disabled-preset test does)
});
```

- [ ] **2. Run — fail.**
- [ ] **3. Implement** the contract.
- [ ] **4. Run `flutter test test/ui/features/today/views/sheets_test.dart` — green.** Existing snooze tests asserting `now + m` targets must be updated to the base semantics (that's the point of the change).
- [ ] **5.** `dart format .` → `flutter analyze` → `flutter test`. Report done for review.

**Skills:** `.agents/skills/flutter-add-widget-test`, `.agents/skills/flutter-expert`.

**Acceptance:** spec §2 + acceptance bullet 3: 15:00 meal snoozed at 10:00 (+15 m) → 15:15; at 15:40 → 15:55; tiles + info line show the outcome; bound logic intact.

**Out of scope:** notification scheduling (S14) — the copy is forward-looking only; `Day.snoozeMeal` (unchanged).

---

## Task 5: UI — MealSheet action tiles + dynamic footer

**Role:** Flutter UI engineer.

**Goal:** replace the Ate it / Skip / Snooze footer with `meal.jsx` parity: a 2-tile action row (Snooze, Swap stub) in the body + a Skip / dynamic-primary footer.

**Files:**
- Modify: `lib/ui/features/today/views/meal_sheet.dart`
- Test: `test/ui/features/today/views/sheets_test.dart` (extend + update old footer tests)

**Contract:**

```dart
// In build(), before the return:
final items = meal.meal.items;
final checkedCount = items.where((i) => i.checked).length;
final isPartial = checkedCount > 0 && checkedCount < items.length;

// Body ListView gains, after the checklist rows (only when !readOnly):
if (!readOnly) ...[
  const SizedBox(height: Spacing.md),
  Row(
    children: [
      Expanded(
        child: _ActionTile(
          key: const ValueKey('tile-snooze'),
          icon: Icons.snooze_outlined,
          title: 'Snooze',
          subtitle: '15m delay, no further',
          enabled: canSnoozeMeal(day, mealId, now, today),
          colors: colors,
          onTap: () => showCrudoSheet<void>(
            context,
            builder: (_) => SnoozeSheet(date: date, mealId: mealId),
          ),
        ),
      ),
      const SizedBox(width: Spacing.sm),
      Expanded(
        child: _ActionTile(
          key: const ValueKey('tile-swap'),
          icon: Icons.swap_horiz,
          title: 'Swap meal',
          subtitle: 'Pick from library',
          colors: colors,
          // TODO(S08): meal-library picker — design stub until then.
          onTap: null,
        ),
      ),
    ],
  ),
],

// cta — replaces the whole old Column:
cta: readOnly
    ? null
    : Row(
        children: [
          Expanded(
            child: SecondaryAction(
              label: 'Skip',
              enabled: canSkipMeal(day, mealId, today),
              onTap: () =>
                  _run(context, () => ctrl.skipMeal(mealId), pop: true),
            ),
          ),
          const SizedBox(width: Spacing.sm),
          Expanded(
            flex: 2, // meal.jsx: primary is twice the skip width
            child: PrimaryCta(
              label: isPartial ? 'Save Partial' : 'Mark Done',
              onPressed: checkedCount == 0
                  ? () => _run(
                      context,
                      () => ctrl.markAllEaten(mealId),
                      pop: true,
                    )
                  : () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
```

```dart
// _ActionTile — new private widget in meal_sheet.dart (meal.jsx 91–106,
// dimensions snapped: 16px padding → Spacing.md, r-md radius → Radii.md,
// 20px icon → IconSizes.md; subtitle = body muted, the card-preview precedent):
class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.colors,
    this.enabled = true,
    this.onTap,
    super.key,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final CrudoColors colors;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : Opacities.disabled,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.all(Spacing.md),
          decoration: BoxDecoration(
            color: colors.surfaceLow,
            borderRadius: Radii.all(Radii.md),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: IconSizes.md, color: colors.primary),
              const SizedBox(height: Spacing.xs),
              Text(
                title,
                style: CrudoText.body.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colors.onSurface,
                ),
              ),
              Text(
                subtitle,
                style: CrudoText.body.copyWith(color: colors.onSurfaceMut),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

The old "Ate it" CTA and the Skip/Snooze `SecondaryAction` row are removed. Read-only mode unchanged: no tiles, no footer.

**Steps (TDD):**

- [ ] **1. Failing widget tests** in `sheets_test.dart`:

```dart
testWidgets('footer label: 0 checked → Mark Done (marks all + closes)', ...);
testWidgets('footer label: some checked → Save Partial (just closes, state kept)', ...);
testWidgets('footer label: all checked → Mark Done (just closes)', ...);
testWidgets('snooze tile opens SnoozeSheet; disabled when guard fails', ...);
testWidgets('swap tile renders and tap is a no-op', ...);
testWidgets('read-only: no tiles, no footer', ...);
```

  Real implementations following the file's existing sheet-pumping harness; assert persisted state through the container after "Mark Done with 0 checked".

- [ ] **2. Run — fail.**
- [ ] **3. Implement** the contract; delete the dead old footer code.
- [ ] **4. Run `flutter test test/ui/features/today/` — green;** update the old "Ate it"/footer tests to the new structure (the behaviors they guarded — mark-all persists, skip guard — must remain covered).
- [ ] **5.** `dart format .` → `flutter analyze` → `flutter test`. Report done for review.

**Skills:** `.agents/skills/flutter-add-widget-test`, `.agents/skills/flutter-expert` (Semantics on the tiles: `button: true`, label = title).

**Acceptance:** spec §3 decision table verbatim; visual composition matches `meal.jsx` with token dimensions; no new raw px.

**Out of scope:** real swap (S08); any TodayScreen change.

---

## Task 6: UI — MealCard status-circle quick complete + TodayScreen wiring

**Role:** Flutter UI engineer (core widget + feature wiring).

**Goal:** tappable status circle — non-done meals complete in one tap, done meals undo; today only.

**Files:**
- Modify: `lib/ui/core/widgets/meal_card.dart`
- Modify: `docs/design_system.md` (§5: status-circle tap target 44 — new component size)
- Modify: `lib/ui/features/today/views/today_screen.dart`
- Test: `test/ui/widgets/meal_card_test.dart` (extend)
- Test: `test/ui/features/today/views/today_screen_test.dart` (extend)

**Contract:**

```dart
// meal_card.dart — MealCard gains:
/// One-tap complete/undo on the status circle. Null = circle is inert
/// (past/future days). The card stays dumb: the caller decides what a
/// tap means for the current status.
final VoidCallback? onStatusTap;

static const _statusTapTarget = 44.0; // min touch target, 4px grid (§5)

// trailing circle (replaces the bare Center(_StatusCircle)):
Center(
  child: Semantics(
    button: onStatusTap != null,
    label: status == MealStatus.done ? 'Undo $title' : 'Mark $title eaten',
    child: GestureDetector(
      onTap: onStatusTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: _statusTapTarget,
        height: _statusTapTarget,
        child: Center(
          child: _StatusCircle(
            status: status,
            key: ValueKey('meal-status-${status.name}'),
          ),
        ),
      ),
    ),
  ),
)
```

The inner opaque `GestureDetector` wins over the card's outer `onTap` — circle taps never open the sheet.

```dart
// today_screen.dart — in the meal-card Builder (status/ctrl already in scope):
onStatusTap: !isToday
    ? null
    : () {
        final ctrl = ref.read(dayControllerProvider(selected).notifier);
        runDayOp(
          context,
          () => status == MealStatus.done
              ? ctrl.unmarkAll(meal.id)
              : ctrl.markAllEaten(meal.id),
          guardMessage: "That can't be changed anymore.",
        );
      },
```

Add the `sheet_actions.dart` import for `runDayOp`.

**Steps (TDD):**

- [ ] **1. Failing widget tests.** `meal_card_test.dart`:

```dart
testWidgets('status circle tap fires onStatusTap, not onTap', ...);
testWidgets('null onStatusTap: circle tap falls through to card onTap', ...);
testWidgets('semantics: "Mark X eaten" when not done, "Undo X" when done', ...);
```

  `today_screen_test.dart`:

```dart
testWidgets('circle tap completes an upcoming meal (status → done, hero updates)', ...);
testWidgets('second tap undoes (status back, hero rolls back)', ...);
testWidgets('circle tap on a skipped meal completes it', ...);
testWidgets('circle inert on past and future days', ...);
```

- [ ] **2. Run — fail.**
- [ ] **3. Implement** both contract snippets + the `design_system.md §5` row.
- [ ] **4. Run `flutter test test/ui/ — green`** (the showcase/widget suites touch MealCard — new param is optional, defaults preserve behavior).
- [ ] **5.** `dart format .` → `flutter analyze` → `flutter test` — full suite green. Report done for review.

**Skills:** `.agents/skills/flutter-add-widget-test`, `.agents/skills/flutter-expert` (44px min touch target, Semantics labels).

**Acceptance:** spec §4: one tap completes, second undoes, skipped round-trips, inert off-today; hero animates immediately on circle taps (no sheet → no freeze).

**Out of scope:** confirm dialogs, undo snackbars; long-press affordances.

---

## Final check (after Task 6)

- [ ] `dart format .` leaves nothing → `flutter analyze` clean → `flutter test` fully green (incl. `test/architecture/dependency_rules_test.dart`).
- [ ] Walk the spec's Acceptance list (`docs/specs/2026-06-06-s06-1-today-refinements.md`) point by point against the running dev app: `flutter run --flavor dev -t lib/main_development.dart --dart-define-from-file=config/dev.json`.
- [ ] Report done for review — no commits.
