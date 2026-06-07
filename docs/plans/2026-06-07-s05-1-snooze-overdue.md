# S05.1 Snooze Overdue & Eligibility Refinements — Implementation Plan

> **For the worker:** implement task-by-task, top to bottom; each task = contract + steps; read the `.agents/skills` each task names before starting it. Spec: `docs/specs/2026-06-06-s05-1-snooze-overdue.md`. Repo rules: `AGENTS.md`. Workers do **not** commit — finish each task with format → analyze → test, then report done for review.

**Goal:** Snooze gets a 15-minute grace window — an expired snooze now derives a new 5th `MealStatus.overdue` (warm amber, actionable) instead of silently auto-skipping; snooze eligibility excludes skipped meals; the disabled snooze tile explains itself with a toast; disabled snooze presets show why ("Past Dinner" / "Past midnight"), with an empty-state message when no preset fits.

**Architecture:** Color tokens first (independent, keeps every later step compiling against final colors). Then the domain core: `MealStatus.overdue`, `deriveMealStatus` gains a `graceEnd` parameter (stays Day-import-free), `computeGraceEnd` + `snoozeGraceMinutes` + `mealStatus` convenience wrapper in `meal_lifecycle.dart` — adding the enum value breaks every exhaustive `MealStatus` switch, so Task 2 also carries the mechanical UI arm additions (the compiler enumerates them; the contract gives each arm verbatim). Then two UI seams: ineligibility toast (MealSheet) and preset reasons + empty state (SnoozeSheet). State layer untouched — `DayController.snooze` keeps its signature; grace is a pure-derivation concern.

**Tech stack:** Flutter, Riverpod 3 (no provider changes), freezed domain (no model changes — no codegen needed), `package:checks`, `flutter_test`.

**Resolved spec gaps (validated 2026-06-07):**
- `today_screen.dart` `_MealsHeader` switch gains an `overdue` break arm (counts unchanged).
- `_nudge` "remaining" count **includes overdue** (user decision 2026-06-07 — overdue is actionable).
- MealSheet's snooze tile uses the existing `_ActionTile(enabled:)` mechanism, not `onTap: null` — the tile gains an `onDisabledTap` callback.
- `previews.dart` already iterates `MealStatus.values`, so a plain overdue card appears automatically; the explicit new entry is the snoozed variant.

---

## Task 1: Color tokens — `overdue` / `overdueSoft`

**Role:** Flutter theming engineer.

**Goal:** the two warm-amber tokens every later task renders with. Distinct from gold (`#E9B949`, partial) and error (`#BA1A1A`, skipped).

**Files:**
- Modify: `lib/ui/core/themes/colors.dart`
- Modify: `docs/design_system.md` (meal-status color list: add Overdue)
- Test: `test/ui/themes/colors_test.dart` (extend)

**Contract:**

```dart
// CrudoPalette — after errorSoft (line ~23):
static const overdue = Color(0xFFD97706); // warm amber — urgent, not terminal
static const overdueSoft = Color(0xFFFEF3C7); // amber tint — overdue circle bg
```

`CrudoColors` gains `overdue` and `overdueSoft` in all five places, mirroring how `error`/`errorSoft` appear: constructor (`required this.overdue, required this.overdueSoft`), the field declaration group (`final Color … error, errorSoft, overdue, overdueSoft, success, outline;`), the `light` const (`overdue: CrudoPalette.overdue, overdueSoft: CrudoPalette.overdueSoft,`), `copyWith` (params + `overdue: overdue ?? this.overdue,` etc.), and `lerp` (`overdue: Color.lerp(overdue, other.overdue, t)!,` etc.).

In `docs/design_system.md`, find the meal-status color statement ("Done = teal, Partial = gold … Skipped = red") and extend it with: Overdue = warm amber `#D97706` (`overdueSoft #FEF3C7` circle bg) — snooze-expired grace window (S05.1). These tokens are an S05.1 addition, not in `app.css` — the design doc is their record.

**Steps (TDD):**

- [ ] **1. Failing test.** In `test/ui/themes/colors_test.dart`, extend the first test:

```dart
expect(c.overdue, const Color(0xFFD97706));
expect(c.overdueSoft, const Color(0xFFFEF3C7));
```

- [ ] **2. Run — fail** ("The getter 'overdue' isn't defined"): `flutter test test/ui/themes/colors_test.dart`
- [ ] **3. Implement** the contract (palette + 5 CrudoColors sites + design_system.md line).
- [ ] **4. Run — green:** `flutter test test/ui/themes/`
- [ ] **5.** `dart format .` → `flutter analyze` → `flutter test`. Report done for review.

**Skills:** `.agents/skills/flutter-expert`.

**Acceptance:** both tokens exposed on `CrudoColors.light`; `copyWith`/`lerp` handle them; doc records them.

**Out of scope:** any widget using the tokens (Tasks 2–4).

---

## Task 2: Domain — overdue status + grace engine + mechanical switch updates + overdue rendering

**Role:** pure-Dart domain engineer for `lib/domain/`; the UI edits in this task are compiler-driven mechanical arms specified verbatim below (adding an enum value breaks every exhaustive switch — they must land in the same task to keep the tree green).

**Goal:** rule 6 of the new chain — snooze expired + grace active → `overdue` — plus the grace computation, the UI-facing `mealStatus` wrapper, and the amber rendering on MealCard/TodayScreen/MealSheet.

**Files:**
- Modify: `lib/domain/shared/enums.dart`
- Modify: `lib/domain/services/meal_status.dart`
- Modify: `lib/domain/services/meal_lifecycle.dart` (grace const + `computeGraceEnd` + `mealStatus`; `canEditMealContent` sentinel)
- Modify: `lib/domain/day/day.dart:184` (`replaceMeal` sentinel)
- Modify: `lib/ui/core/widgets/meal_card.dart` (3 switch arms)
- Modify: `lib/ui/features/today/views/today_screen.dart` (status via `mealStatus`, snoozed label, `_MealsHeader` arm, `_nudge`)
- Modify: `lib/ui/features/today/views/meal_sheet.dart` (status via `mealStatus`, snoozed label)
- Modify: `lib/previews.dart` (overdue-snoozed MealCard entry)
- Test: `test/domain/services/meal_status_test.dart` (helper + new group + renumber)
- Test: `test/domain/services/meal_lifecycle_test.dart` (new group)
- Test: `test/domain/day/day_ops_test.dart` (mechanical: 4th arg)
- Test: `test/ui/widgets/meal_card_test.dart` (overdue rendering)
- Test: `test/ui/features/today/views/today_screen_test.dart` (overdue label + circle tap + nudge count)

**Contract — domain:**

```dart
// enums.dart:
/// Per-meal status — always DERIVED from checked flags + time (S05/S05.1); never stored.
enum MealStatus { done, partial, upcoming, overdue, skipped }
```

```dart
// meal_status.dart — replace the doc chain + function:

/// Priority chain (S05.1 §Status derivation):
///   1 any item checked → done/partial   (clock + stamps irrelevant)
///   2 past day         → skipped        (history freezes unchecked)
///   3 future day       → upcoming       (preview)
///   4 skippedAt set    → skipped        (explicit skip, shown pre-window too)
///   5 snooze pending   → upcoming       (UI chips off the field)
///   6 snooze expired   → overdue        (grace window active — S05.1)
///     && now < graceEnd
///   7 meal time passed → skipped        (auto-skip: no snooze, or grace over)
///   8 otherwise        → upcoming
///
/// [graceEnd] comes from computeGraceEnd (meal_lifecycle.dart) — passed in so
/// this file stays Day-free (avoids the import cycle). Callers that only
/// check `== upcoming` pass [now]: now.isBefore(now) is false, rule 6 never
/// fires, an expired snooze falls through to rule 7 (skipped) as before.
MealStatus deriveMealStatus(
  ScheduledMeal meal,
  DateTime dayDate,
  DateTime now,
  DateTime graceEnd,
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
  if (snoozedUntil != null && now.isBefore(graceEnd)) {
    return MealStatus.overdue;
  }
  if (!now.toLocal().isBefore(localInstantAt(dayDate, meal.time))) {
    return MealStatus.skipped;
  }
  return MealStatus.upcoming;
}
```

```dart
// meal_lifecycle.dart — after maxSnoozeUntil:

/// Snooze grace period (S05.1) — the actionable window after a snooze
/// expires before the meal auto-skips. Single source of truth; promote to
/// Prefs if a user-configurable grace is ever needed.
const snoozeGraceMinutes = 15;

/// Grace end for a snoozed meal: min(snoozedUntil + grace, snooze bound).
/// The bound (next meal / midnight) caps the grace — a meal snoozed AT the
/// bound gets grace = 0 → immediate auto-skip (the user already pushed to
/// the absolute limit). Returns UTC.
DateTime computeGraceEnd(Day day, String mealId, DateTime snoozedUntil) {
  final fixedGrace = snoozedUntil.add(
    const Duration(minutes: snoozeGraceMinutes),
  );
  final bound = day.maxSnoozeUntilFor(mealId, snoozedUntil);
  return fixedGrace.isBefore(bound) ? fixedGrace : bound;
}

/// Convenience derivation with graceEnd computed from the Day — the UI
/// entry point. Domain-internal callers that only check `== upcoming`
/// call deriveMealStatus directly with `now` as graceEnd.
MealStatus mealStatus(Day day, String mealId, DateTime now) {
  final meal = day.meals.firstWhere(
    (m) => m.id == mealId,
    orElse: () => throw StateError('no meal with id $mealId'),
  );
  final graceEnd = meal.snoozedUntil != null
      ? computeGraceEnd(day, mealId, meal.snoozedUntil!)
      : now;
  return deriveMealStatus(meal, day.date, now, graceEnd);
}
```

(Deliberate deviation from the spec snippet: `firstWhere` gets the `orElse`-throw idiom, mirroring `snoozeBaseFor` directly above it.)

Sentinel callers — both only check `== upcoming`, `now` as graceEnd is the safe sentinel:

```dart
// meal_lifecycle.dart canEditMealContent — the predicate becomes:
deriveMealStatus(meal, dayDate, now, now) == MealStatus.upcoming;

// day.dart:184 replaceMeal — the guard becomes:
if (deriveMealStatus(meal, date, now, now) != MealStatus.upcoming) {
```

**Contract — mechanical UI arms (verbatim):**

```dart
// meal_card.dart _statusLabelColor — full switch:
Color _statusLabelColor(CrudoColors colors) => switch (status) {
  MealStatus.done => colors.primary,
  MealStatus.partial => colors.goldDeep,
  MealStatus.upcoming => colors.onSurfaceMut,
  MealStatus.overdue => colors.overdue,
  MealStatus.skipped => colors.error,
};

// meal_card.dart _barColor — full switch:
Color _barColor(CrudoColors colors) => switch (status) {
  MealStatus.done => colors.primarySoft,
  MealStatus.partial => colors.gold,
  MealStatus.upcoming => colors.primary.withValues(alpha: 0.18),
  MealStatus.overdue => colors.overdue,
  MealStatus.skipped => colors.error.withValues(alpha: 0.4),
};

// meal_card.dart _StatusCircle — new case between upcoming and skipped:
// (same clock icon as upcoming but amber on amber-soft: "still your turn,
// but urgent")
MealStatus.overdue => (
  colors.overdueSoft,
  null,
  Icon(Icons.schedule, size: IconSizes.md, color: colors.overdue),
),
```

The title-color expression in `meal_card.dart` (`status == MealStatus.skipped ? onSurfaceMut : onSurface`) is already correct for overdue — actionable, not muted. No change. The `Semantics` label (`done ? 'Undo …' : 'Mark … eaten'`) is also already correct.

```dart
// today_screen.dart meal-card Builder (~line 154) — derivation + label:
final status = mealStatus(day, meal.id, now);
final snoozed =
    meal.snoozedUntil != null &&
        (status == MealStatus.upcoming ||
            status == MealStatus.overdue)
    ? timeOfDayLabel(meal.snoozedUntil!.toLocal())
    : null;

// today_screen.dart _nudge — remaining includes overdue (user decision):
final remaining = day.meals.where((m) {
  final s = mealStatus(day, m.id, now);
  return s == MealStatus.upcoming || s == MealStatus.overdue;
}).length;

// today_screen.dart _MealsHeader — switch over mealStatus(day, m.id, now):
switch (mealStatus(day, m.id, now)) {
  case MealStatus.done:
    done++;
  case MealStatus.partial:
    partial++;
  case MealStatus.upcoming || MealStatus.overdue || MealStatus.skipped:
    break;
}
```

(`today_screen.dart` keeps its `meal_status.dart` import — `localDateLabel`/`endOfDayLocal` still used by the midnight timer.)

```dart
// meal_sheet.dart (~line 66) — derivation + label:
final status = mealStatus(day, mealId, now);
// …
final snoozedLabel =
    meal.snoozedUntil != null &&
        (status == MealStatus.upcoming ||
            status == MealStatus.overdue)
    ? '${mealTimeLabel(meal.time)} → ${timeOfDayLabel(meal.snoozedUntil!.toLocal())}'
    : mealTimeLabel(meal.time);
```

`meal_sheet.dart`'s `meal_status.dart` import becomes unused after the swap — remove it.

```dart
// previews.dart — after the `for (final status in MealStatus.values)` loop
// in the MealCard section (the loop auto-renders a plain overdue card; this
// is the snoozed variant):
Padding(
  padding: const EdgeInsets.only(bottom: Spacing.sm),
  child: MealCard(
    title: 'Meal — overdue (snoozed)',
    timeLabel: '14:00',
    snoozedTimeLabel: '14:15',
    mealTypeLabel: 'Lunch',
    macros: const Macros(protein: 32, carbs: 45, fats: 12, kcal: 420),
    ingredientNames: const ['Egg, whole', 'Greek Yogurt'],
    status: MealStatus.overdue,
  ),
),
```

**Steps (TDD):**

- [ ] **1. Write the failing domain tests.** In `test/domain/services/meal_status_test.dart`, add a local helper after `nowAt` and mechanically route every existing `deriveMealStatus(` call through it (sentinel semantics preserved):

```dart
MealStatus derive(
  ScheduledMeal m,
  DateTime date,
  DateTime now, {
  DateTime? graceEnd,
}) => deriveMealStatus(m, date, now, graceEnd ?? now);
```

  Renumber test names: `'elapsed snooze falls through to auto-skip (rule 6)'` is **replaced** by the overdue group below; `'auto-skip flips at meal time exactly, no grace (rule 6)'` → `(rule 7)`; `'upcoming before meal time (rule 7)'` → `(rule 8)`. New group:

```dart
group('overdue (rule 6)', () {
  test('elapsed snooze within grace → overdue', () {
    final m = _meal(snoozedUntil: nowAt(13, 30).toUtc());
    check(
      derive(m, dayDate, nowAt(13, 40), graceEnd: nowAt(13, 45).toUtc()),
    ).equals(MealStatus.overdue);
  });
  test('elapsed snooze past grace → skipped (rule 7)', () {
    final m = _meal(snoozedUntil: nowAt(13, 30).toUtc());
    check(
      derive(m, dayDate, nowAt(14), graceEnd: nowAt(13, 45).toUtc()),
    ).equals(MealStatus.skipped);
  });
  test('grace = 0 (graceEnd == snoozedUntil) → skipped immediately', () {
    final m = _meal(snoozedUntil: nowAt(13, 30).toUtc());
    check(
      derive(m, dayDate, nowAt(13, 31), graceEnd: nowAt(13, 30).toUtc()),
    ).equals(MealStatus.skipped);
  });
  test('checked wins over overdue (rule 1)', () {
    final m = _meal(checkedOf2: 2, snoozedUntil: nowAt(13, 30).toUtc());
    check(
      derive(m, dayDate, nowAt(13, 40), graceEnd: nowAt(13, 45).toUtc()),
    ).equals(MealStatus.done);
  });
  test('explicit skip beats overdue (rule 4 over 6)', () {
    final m = _meal(
      skippedAt: DateTime.utc(2026, 6, 4, 9),
      snoozedUntil: nowAt(13, 30).toUtc(),
    );
    check(
      derive(m, dayDate, nowAt(13, 40), graceEnd: nowAt(13, 45).toUtc()),
    ).equals(MealStatus.skipped);
  });
  test(
    'pre-window snooze expired, grace over, meal time not reached → '
    'upcoming (rule 8)',
    () {
      // Meal at 14:00 snoozed (domain allows until < scheduled) to 12:30;
      // grace over at 12:45; 12:50 < 14:00 → rule 7 dead → upcoming.
      final m = _meal(
        timeMinutes: 14 * 60,
        snoozedUntil: nowAt(12, 30).toUtc(),
      );
      check(
        derive(m, dayDate, nowAt(12, 50), graceEnd: nowAt(12, 45).toUtc()),
      ).equals(MealStatus.upcoming);
    },
  );
  test('MealTime(0) snoozed: overdue within grace, skipped after', () {
    final m = _meal(timeMinutes: 0, snoozedUntil: nowAt(0, 20).toUtc());
    check(
      derive(m, dayDate, nowAt(0, 25), graceEnd: nowAt(0, 35).toUtc()),
    ).equals(MealStatus.overdue);
    check(
      derive(m, dayDate, nowAt(0, 40), graceEnd: nowAt(0, 35).toUtc()),
    ).equals(MealStatus.skipped);
  });
});
```

  In `test/domain/services/meal_lifecycle_test.dart` (reuse `_plan`/`_breakfastTpl`/`_lunchTpl` fixtures — meals materialize as `id-0` breakfast 08:00, `id-1` lunch 13:00; lunch is last → its bound is midnight):

```dart
group('computeGraceEnd / mealStatus', () {
  Day d() => buildDayFromPlan(
    _plan(),
    thursday,
    _SeqIds().newId,
    [_breakfastTpl, _lunchTpl],
    [_egg, _rice],
  );

  test('standard: snoozedUntil + 15min within bound', () {
    final until = DateTime(2026, 6, 4, 10).toUtc();
    check(
      computeGraceEnd(d(), 'id-0', until),
    ).equals(DateTime(2026, 6, 4, 10, 15).toUtc());
  });
  test('capped at next meal time', () {
    final until = DateTime(2026, 6, 4, 12, 50).toUtc();
    check(
      computeGraceEnd(d(), 'id-0', until),
    ).equals(DateTime(2026, 6, 4, 13).toUtc());
  });
  test('capped at end-of-day midnight (last meal)', () {
    final until = DateTime(2026, 6, 4, 23, 55).toUtc();
    check(
      computeGraceEnd(d(), 'id-1', until),
    ).equals(DateTime(2026, 6, 5).toUtc());
  });
  test('snoozedUntil at the bound → grace = 0', () {
    final until = DateTime(2026, 6, 4, 13).toUtc();
    check(computeGraceEnd(d(), 'id-0', until)).equals(until);
  });
  test('mealStatus: pending → upcoming, in grace → overdue, after → skipped '
      '(acceptance #1)', () {
    final snoozed = d().snoozeMeal(
      'id-0',
      DateTime(2026, 6, 4, 12, 30),
      DateTime(2026, 6, 4, 12),
      thursday,
    );
    check(
      mealStatus(snoozed, 'id-0', DateTime(2026, 6, 4, 12, 20)),
    ).equals(MealStatus.upcoming);
    check(
      mealStatus(snoozed, 'id-0', DateTime(2026, 6, 4, 12, 31)),
    ).equals(MealStatus.overdue);
    check(
      mealStatus(snoozed, 'id-0', DateTime(2026, 6, 4, 12, 46)),
    ).equals(MealStatus.skipped);
  });
  test('snoozed to the bound skips immediately on expiry (acceptance #2)', () {
    final snoozed = d().snoozeMeal(
      'id-0',
      DateTime(2026, 6, 4, 13),
      DateTime(2026, 6, 4, 12),
      thursday,
    );
    check(
      mealStatus(snoozed, 'id-0', DateTime(2026, 6, 4, 13, 1)),
    ).equals(MealStatus.skipped);
  });
  test('no snooze: mealStatus matches the sentinel path', () {
    check(
      mealStatus(d(), 'id-0', DateTime(2026, 6, 4, 7)),
    ).equals(MealStatus.upcoming);
    check(
      mealStatus(d(), 'id-0', DateTime(2026, 6, 4, 9)),
    ).equals(MealStatus.skipped);
  });
  test('unknown meal throws', () {
    check(
      () => mealStatus(d(), 'nope', DateTime(2026, 6, 4, 9)),
    ).throws<StateError>();
  });
});
```

- [ ] **2. Run — fail** (enum member / 4th param / functions undefined):
  `flutter test test/domain/services/`
- [ ] **3. Implement the domain contract** (enums.dart, meal_status.dart, meal_lifecycle.dart, day.dart). Mechanically fix the two `deriveMealStatus` calls in `test/domain/day/day_ops_test.dart` (~line 254/258): append `, now` as the 4th argument.
- [ ] **4. Implement the mechanical UI arms** (meal_card.dart, today_screen.dart, meal_sheet.dart, previews.dart) — `flutter analyze` is the checklist: it must go from "missing case" errors to clean.
- [ ] **5. Run the domain suite — green:** `flutter test test/domain/`
- [ ] **6. Failing-then-green widget tests.** `test/ui/widgets/meal_card_test.dart` (add `import 'package:crudo/ui/core/themes/colors.dart';`):

```dart
testWidgets('overdue: amber label + clock icon on amber-soft circle; '
    'title not muted', (tester) async {
  await tester.pumpWidget(_wrap(_card(status: MealStatus.overdue)));
  expect(find.text('OVERDUE'), findsOneWidget);
  final label = tester.widget<Text>(find.text('OVERDUE'));
  check(label.style!.color).equals(CrudoColors.light.overdue);
  final icon = tester.widget<Icon>(find.byIcon(Icons.schedule));
  check(icon.color).equals(CrudoColors.light.overdue);
  final title = tester.widget<Text>(find.text('Protein Bowl'));
  check(title.style!.color).equals(CrudoColors.light.onSurface);
});

testWidgets('overdue keeps struck-through original + snoozed time', (
  tester,
) async {
  await tester.pumpWidget(
    _wrap(
      MealCard(
        title: 'Protein Bowl',
        timeLabel: '14:00',
        snoozedTimeLabel: '14:15',
        mealTypeLabel: 'Lunch',
        macros: _macros,
        status: MealStatus.overdue,
      ),
    ),
  );
  final rich = tester
      .widgetList<RichText>(find.byType(RichText))
      .where(
        (r) =>
            r.text.toPlainText().contains('14:00') &&
            r.text.toPlainText().contains('14:15'),
      );
  check(rich).isNotEmpty();
});
```

  (The existing all-statuses loop test auto-covers the new value — `OVERDUE` chip + `meal-status-overdue` key. If it asserts exact counts anywhere, extend, don't weaken.)

  `test/ui/features/today/views/today_screen_test.dart` (reuse `pumpToday`/`app`/mutable `now`; sm-2 = 'Yogurt & Banana', snack 16:00; sm-3 dinner 19:00). Re-pumping `app(c)` after moving `now` is the rebuild trick — the screen reads the clock each build:

```dart
testWidgets('overdue meal: OVERDUE label + snoozed time persist on the card', (
  tester,
) async {
  now = DateTime(2026, 6, 4, 15, 55);
  final c = await pumpToday(tester);
  await c
      .read(dayControllerProvider(today).notifier)
      .snooze('sm-2', DateTime(2026, 6, 4, 16, 15));
  // Cross into the grace window: 16:15 + 15m → 16:30 (dinner 19:00 no cap).
  now = DateTime(2026, 6, 4, 16, 20);
  await tester.pumpWidget(app(c));
  await tester.pumpAndSettle();
  expect(find.text('OVERDUE'), findsOneWidget);
  // The card's time row is a Text.rich — match the span, not a Text widget.
  expect(
    find.textContaining('16:15', findRichText: true),
    findsOneWidget,
  ); // snoozed label persists
});

testWidgets('nudge counts an overdue meal as remaining', (tester) async {
  now = DateTime(2026, 6, 4, 15, 55);
  final c = await pumpToday(tester);
  await c
      .read(dayControllerProvider(today).notifier)
      .snooze('sm-2', DateTime(2026, 6, 4, 16, 15));
  now = DateTime(2026, 6, 4, 16, 20);
  await tester.pumpWidget(app(c));
  await tester.pumpAndSettle();
  // snack overdue + dinner upcoming = 2 (breakfast/lunch auto-skipped).
  expect(
    find.text('2 meals remain. A done day keeps the streak.'),
    findsOneWidget,
  );
});

testWidgets('circle tap on an overdue meal completes it', (tester) async {
  now = DateTime(2026, 6, 4, 15, 55);
  final c = await pumpToday(tester);
  await c
      .read(dayControllerProvider(today).notifier)
      .snooze('sm-2', DateTime(2026, 6, 4, 16, 15));
  now = DateTime(2026, 6, 4, 16, 20);
  await tester.pumpWidget(app(c));
  await tester.pumpAndSettle();
  await tester.tap(
    find.byKey(const ValueKey('meal-status-overdue')),
    warnIfMissed: false,
  );
  await tester.pumpAndSettle();
  final day = await c.read(dayControllerProvider(today).future);
  expect(day.meals.firstWhere((m) => m.id == 'sm-2').meal.allChecked, isTrue);
});
```

- [ ] **7. Run — green:** `flutter test test/ui/`
- [ ] **8.** `dart format .` → `flutter analyze` → `flutter test` (full suite, incl. `test/architecture/dependency_rules_test.dart`). Report done for review.

**Skills:** `.agents/skills/dart-add-unit-test`, `.agents/skills/dart-migrate-to-checks-package`, `.agents/skills/flutter-add-widget-test`, `.agents/skills/flutter-expert`.

**Acceptance:** enum has 5 values with `overdue` between `upcoming` and `skipped`; `deriveMealStatus` has the 4-param signature; sentinel callers compile and behave as before for expired snoozes; spec acceptance #1 and #2 timing tests green; overdue card renders amber bar/label/clock circle with persistent snoozed label; `lib/domain/` still imports no Flutter/Riverpod.

**Out of scope:** `canSnoozeMeal`/`snoozeIneligibilityReason` (Task 3); SnoozeSheet (Task 4); any change to `Day.snoozeMeal`, `maxSnoozeUntilFor`, `snoozeBaseFor`, `ScheduledMeal`, controllers.

---

## Task 3: Eligibility — skipped-meal guard + `snoozeIneligibilityReason` + MealSheet toast

**Role:** domain engineer (meal_lifecycle.dart) + Flutter UI engineer (meal_sheet.dart).

**Goal:** a skipped meal can't be snoozed (rejected commitment); the disabled snooze tile explains itself with a warn toast instead of being silently dead.

**Files:**
- Modify: `lib/domain/services/meal_lifecycle.dart` (guard + new function)
- Modify: `lib/ui/features/today/views/meal_sheet.dart` (`_ActionTile.onDisabledTap` + snooze-tile wiring + toast import)
- Test: `test/domain/services/meal_lifecycle_test.dart` (extend)
- Test: `test/ui/features/today/views/sheets_test.dart` (extend)

**Contract:**

```dart
// meal_lifecycle.dart — canSnoozeMeal gains the skippedAt guard:
bool canSnoozeMeal(Day day, String mealId, DateTime now, DateTime today) {
  if (isDayLocked(day, today)) return false;
  final meal = day.meals.where((m) => m.id == mealId).firstOrNull;
  if (meal == null || meal.meal.allChecked) return false;
  if (meal.skippedAt != null) return false; // S05.1: skip = rejected commitment
  return maxSnoozeUntil(day, mealId, now).isAfter(now);
}

/// Human-readable reason snooze is unavailable, or null when eligible —
/// the MealSheet's toast copy. Mirrors canSnoozeMeal's guard order exactly.
String? snoozeIneligibilityReason(
  Day day,
  String mealId,
  DateTime now,
  DateTime today,
) {
  if (isDayLocked(day, today)) return 'Day is locked';
  final meal = day.meals.where((m) => m.id == mealId).firstOrNull;
  if (meal == null) return 'Meal not found';
  if (meal.meal.allChecked) return 'Meal is done';
  if (meal.skippedAt != null) return 'Meal is skipped';
  if (!maxSnoozeUntil(day, mealId, now).isAfter(now)) {
    return 'No room before your next meal';
  }
  return null;
}
```

```dart
// meal_sheet.dart — _ActionTile gains a disabled-tap callback:
//   new field, after onTap:
/// Fires when the tile is tapped while disabled (S05.1: ineligibility
/// toast). The tile still renders at Opacities.disabled — never hides.
final VoidCallback? onDisabledTap;
//   constructor: this.onDisabledTap,
//   GestureDetector: onTap: enabled ? onTap : onDisabledTap,
// Semantics stays `button: enabled && onTap != null` — the disabled tap is
// an explanation affordance, not an action.

// Snooze tile wiring (import '../../../core/widgets/toast.dart'):
_ActionTile(
  key: const ValueKey('tile-snooze'),
  icon: Icons.snooze_outlined,
  title: 'Snooze',
  subtitle: '${snoozePresetMinutes.last}m delay, no further',
  enabled: canSnoozeMeal(day, mealId, now, today),
  colors: colors,
  onTap: () => showCrudoSheet<void>(
    context,
    builder: (_) => SnoozeSheet(date: date, mealId: mealId),
  ),
  onDisabledTap: () {
    final reason = snoozeIneligibilityReason(day, mealId, now, today);
    if (reason != null) {
      showCrudoToast(context, reason, kind: ToastKind.warn);
    }
  },
),
```

**Steps (TDD):**

- [ ] **1. Failing domain tests** in `meal_lifecycle_test.dart` (reuse the `d()` builder from Task 2's group):

```dart
group('canSnoozeMeal S05.1 guards', () {
  final noon = DateTime(2026, 6, 4, 12);

  test('false when skippedAt is set', () {
    final skipped = d().skipMeal('id-0', noon, thursday);
    check(canSnoozeMeal(skipped, 'id-0', noon, thursday)).isFalse();
  });
  test('true for an overdue meal while the bound permits', () {
    // snoozed 12:00 → 12:30; at 12:40 the snooze is expired (grace ends
    // 12:45) and lunch (13:00) is still ahead → re-snooze allowed.
    final snoozed = d().snoozeMeal(
      'id-0',
      DateTime(2026, 6, 4, 12, 30),
      noon,
      thursday,
    );
    final at1240 = DateTime(2026, 6, 4, 12, 40);
    check(mealStatus(snoozed, 'id-0', at1240)).equals(MealStatus.overdue);
    check(canSnoozeMeal(snoozed, 'id-0', at1240, thursday)).isTrue();
  });
});

group('snoozeIneligibilityReason', () {
  final noon = DateTime(2026, 6, 4, 12);

  test('null when eligible', () {
    check(snoozeIneligibilityReason(d(), 'id-0', noon, thursday)).isNull();
  });
  test('Day is locked for a past day', () {
    check(
      snoozeIneligibilityReason(d(), 'id-0', noon, DateTime.utc(2026, 6, 5)),
    ).equals('Day is locked');
  });
  test('Meal not found', () {
    check(
      snoozeIneligibilityReason(d(), 'nope', noon, thursday),
    ).equals('Meal not found');
  });
  test('Meal is done for allChecked', () {
    final done = d().markAllEaten('id-0', noon, thursday);
    check(
      snoozeIneligibilityReason(done, 'id-0', noon, thursday),
    ).equals('Meal is done');
  });
  test('Meal is skipped for skippedAt', () {
    final skipped = d().skipMeal('id-0', noon, thursday);
    check(
      snoozeIneligibilityReason(skipped, 'id-0', noon, thursday),
    ).equals('Meal is skipped');
  });
  test('No room before your next meal when bound ≤ now', () {
    // breakfast's bound is lunch 13:00; at 13:05 it's behind us.
    check(
      snoozeIneligibilityReason(
        d(),
        'id-0',
        DateTime(2026, 6, 4, 13, 5),
        thursday,
      ),
    ).equals('No room before your next meal');
  });
});
```

- [ ] **2. Run — fail:** `flutter test test/domain/services/meal_lifecycle_test.dart`
- [ ] **3. Implement** the meal_lifecycle.dart contract. Run — green.
- [ ] **4. Failing widget tests** in `sheets_test.dart`, MealSheet group. Toast note: `showCrudoToast` runs a 4500 ms auto-dismiss timer — after tapping, use fixed `tester.pump(...)` calls (mirror `test/ui/widgets/toast_test.dart`'s idiom), **not** `pumpAndSettle`, and let the toast expire with a final `await tester.pump(const Duration(seconds: 5));` before the test ends:

```dart
testWidgets('disabled snooze tile tap on a done meal toasts "Meal is done"', (
  tester,
) async {
  await open(tester, (c) => mealSheetOpener(c));
  final day0 = await container.read(dayControllerProvider(today).future);
  await container
      .read(dayControllerProvider(today).notifier)
      .markAllEaten(day0.meals.first.id);
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const ValueKey('tile-snooze')));
  await tester.pump(); // toast entrance
  expect(find.text('Meal is done'), findsOneWidget);
  expect(find.text('Snooze, then eat.'), findsNothing); // sheet didn't open
  await tester.pump(const Duration(seconds: 5)); // let the toast expire
});

testWidgets(
  'disabled snooze tile tap on a skipped meal toasts "Meal is skipped"',
  (tester) async {
    await open(tester, (c) => mealSheetOpener(c));
    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();
    // Skip pops the sheet — reopen on the now-skipped meal.
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('tile-snooze')));
    await tester.pump();
    expect(find.text('Meal is skipped'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
  },
);
```

- [ ] **5. Run — fail**, **implement** the meal_sheet.dart contract, **run — green:** `flutter test test/ui/features/today/views/sheets_test.dart`
- [ ] **6.** `dart format .` → `flutter analyze` → `flutter test`. Report done for review.

**Skills:** `.agents/skills/dart-add-unit-test`, `.agents/skills/flutter-add-widget-test`, `.agents/skills/flutter-expert`.

**Acceptance:** spec acceptance bullets 3–4 (done-meal toast "Meal is done", skipped-meal toast "Meal is skipped"); skipped meals fail `canSnoozeMeal`; overdue meals pass while the bound permits; tile never hides — `Opacities.disabled` rendering unchanged.

**Out of scope:** SnoozeSheet internals (Task 4); un-skip affordances (the existing skip-toggle path already covers it).

---

## Task 4: SnoozeSheet — disabled-preset reasons + empty state

**Role:** Flutter UI engineer.

**Goal:** disabled presets say why ("Past Dinner" / "Past midnight") in the result-label slot; when no preset fits, the body says so and the CTA stays disabled.

**Files:**
- Modify: `lib/ui/features/today/views/snooze_sheet.dart`
- Test: `test/ui/features/today/views/sheets_test.dart` (extend SnoozeSheet group)

**Contract:**

```dart
// snooze_sheet.dart — imports gain:
import '../../../../domain/day/scheduled_meal.dart';

// build(), after `bound`: which cap is in play? maxSnoozeUntilFor returns
// the next meal's instant when one exists, else midnight — so the reason
// follows from whether a strictly-later meal exists (same comparison rule:
// strictly greater by time, earliest such).
final mealNow = day.meals.firstWhere((m) => m.id == widget.mealId);
ScheduledMeal? next;
for (final m in day.meals) {
  if (m.time.compareTo(mealNow.time) > 0 &&
      (next == null || m.time.compareTo(next.time) < 0)) {
    next = m;
  }
}
final nextTag = next == null
    ? null
    : next.meal.tags.isEmpty
    ? 'next meal'
    : next.meal.tags.first.name[0].toUpperCase() +
          next.meal.tags.first.name.substring(1);
final disabledReason = nextTag == null ? 'Past midnight' : 'Past $nextTag';

// _PresetTile call — the resultLabel slot does double duty (it already
// renders CrudoText.labelMd in onSurfaceMut below 'MIN', exactly the spec
// treatment for the reason):
resultLabel: enabled(m)
    ? timeOfDayLabel(untilFor(m).toLocal())
    : disabledReason,

// body Column, after the preset Row — empty state when even the smallest
// preset overshoots (canSnoozeMeal should prevent this sheet from opening;
// this is the safety net). CTA disabling needs no change: enabled(selected)
// is already false for every preset.
if (!enabled(snoozePresetMinutes.first)) ...[
  const SizedBox(height: dim.Spacing.md),
  Text(
    'No room to snooze — your next meal is too soon',
    key: const ValueKey('snooze-empty'),
    style: CrudoText.body.copyWith(color: colors.onSurfaceMut),
  ),
],
```

All 4 presets stay visible in every state — never hidden.

**Steps (TDD):**

- [ ] **1. Failing widget tests** in `sheets_test.dart`, SnoozeSheet group (seed: sm-2 snack 16:00, sm-3 dinner 19:00 is the last meal):

```dart
testWidgets(
  'bound 20 min away: 10/15/20 enabled (bound inclusive), 30 reasoned '
  '"Past Dinner"',
  (tester) async {
    // 18:40 — snack base = now (16:00 passed); dinner bound 19:00.
    // +20 = 19:00 == bound → enabled; +30 = 19:10 → disabled with reason.
    now = DateTime(2026, 6, 4, 18, 40);
    await open(tester, (c) => snoozeOpener(c));
    expect(find.text('Past Dinner'), findsOneWidget);
    expect(find.text('19:00'), findsOneWidget); // +20 result label, enabled
  },
);

testWidgets('last meal: late presets reasoned "Past midnight"', (
  tester,
) async {
  // 23:46 — dinner (sm-3) is last → bound is midnight. +10 = 23:56 fits;
  // +15/+20/+30 cross it.
  now = DateTime(2026, 6, 4, 23, 46);
  await open(tester, (c) => snoozeOpener(c, mealId: 'sm-3'));
  expect(find.text('Past midnight'), findsNWidgets(3));
});

testWidgets('all presets disabled → empty-state message + disabled CTA', (
  tester,
) async {
  // 18:56 — snack base = now; +10 = 19:06 already past dinner 19:00.
  now = DateTime(2026, 6, 4, 18, 56);
  await open(tester, (c) => snoozeOpener(c));
  expect(
    find.text('No room to snooze — your next meal is too soon'),
    findsOneWidget,
  );
  expect(find.text('Past Dinner'), findsNWidgets(4));
  final cta = tester.widget<PrimaryCta>(find.byType(PrimaryCta));
  check(cta.enabled).isFalse();
});
```

  (If `PrimaryCta`'s field isn't named `enabled`, read `lib/ui/core/widgets/primary_cta.dart` and assert on the actual field — don't weaken to a tap-and-see.)

- [ ] **2. Run — fail:** `flutter test test/ui/features/today/views/sheets_test.dart`
- [ ] **3. Implement** the contract.
- [ ] **4. Run — green** (same file; the existing disabled-preset tests must stay green — they assert selection behavior, not label absence).
- [ ] **5.** `dart format .` → `flutter analyze` → `flutter test`. Report done for review.

**Skills:** `.agents/skills/flutter-add-widget-test`, `.agents/skills/flutter-expert`.

**Acceptance:** spec acceptance bullets 5–6: bound 20 min away → 10/15/20 enabled (bound inclusive), 30 disabled with "Past {next meal}"; bound < 10 min → all disabled + empty-state message + disabled CTA; reasons render in the labelMd/onSurfaceMut slot below MIN; no preset ever hidden.

**Out of scope:** preset list changes; `maxSnoozeUntilFor`/`snoozeBaseFor` (unchanged); notification copy (S14).

---

## Final check (after Task 4)

- [ ] `dart format .` leaves nothing → `flutter analyze` clean → `flutter test` fully green (incl. `test/architecture/dependency_rules_test.dart`).
- [ ] Walk the spec's Acceptance list (`docs/specs/2026-06-06-s05-1-snooze-overdue.md`) point by point against the running dev app: `flutter run --flavor dev -t lib/main_development.dart --dart-define-from-file=config/dev.json` — snooze a meal to near a bound and watch upcoming → overdue → skipped roll over live (midnight-timer rebuilds only fire at midnight; reopen the screen or toggle days to re-derive).
- [ ] Report done for review — no commits.
