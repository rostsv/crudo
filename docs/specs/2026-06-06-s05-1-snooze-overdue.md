# Spec — S05.1: Snooze Overdue & Eligibility Refinements

**Status:** draft · **Spec S05.1 (logic + ui)** · depends on S05 (meal lifecycle engine), S06.1 (today refinements) · scope = **overdue state** between snooze-expired and auto-skip, tightened **snooze eligibility** (done/skipped/past-day excluded with reasons), **snooze-preset filtering** with disabled-reason labels, and **overdue visual rendering** across MealCard/MealSheet/TodayScreen.

> **Companion:** the S05 spec (`docs/specs/2026-06-04-s05-meal-lifecycle.md`) and design doc (`docs/design/domain/2026-06-03-s05-meal-lifecycle-engine.md`) define the status derivation chain and snooze bounds this spec extends. Where wording differs, this spec wins for the changed behavior; S05 remains authoritative for everything untouched.

## Goal

Honor the snooze commitment with a grace window instead of silently auto-skipping; make snooze ineligible states visible and explained; filter snooze presets so invalid options are disabled with a reason rather than silently unavailable.

## Decisions (brainstorm 2026-06-06)

- **Overdue = 5th `MealStatus` value.** Not a chip/overlay like snoozed — a real status that the derivation chain produces. The existing 4-value enum (`done`, `partial`, `upcoming`, `skipped`) gains `overdue` between `upcoming` and `skipped`.
- **Grace period = domain constant, parameterized.** `const snoozeGraceMinutes = 15` in `meal_lifecycle.dart` — single source of truth, referenced by `computeGraceEnd` and any future Prefs promotion. Not hardcoded at call sites.
- **Grace cap = `min(snoozedUntil + grace, nextMealTime, endOfDayMidnight)`.** Computed by `computeGraceEnd(Day, mealId, snoozedUntil)` in `meal_lifecycle.dart`. When snoozed-until was set AT the bound (e.g., snoozed until next-meal time), grace = 0 → immediate skip. Correct: the user already pushed to the absolute limit.
- **`deriveMealStatus` gains a `graceEnd` parameter.** Keeps the function pure (no Day import — avoids the cycle). Callers that only check `== upcoming` (content-edit guard, `replaceMeal`) pass `now` as a safe sentinel: snooze-expired + graceEnd=now → rule 6 doesn't fire → falls to rule 7 → `skipped` (not upcoming). A convenience wrapper `mealStatus(Day, mealId, now)` in `meal_lifecycle.dart` computes graceEnd for UI callers.
- **Overdue is actionable.** The user can eat it (checked wins, rule 1), re-snooze (if bound allows), or explicitly skip. `canSnoozeMeal` returns true for overdue meals when the bound permits.
- **Overdue color = new warm-amber token.** `overdue: #D97706` + `overdueSoft: #FEF3C7` — distinct from gold (`#E9B949`, partial) and error (`#BA1A1A`, skipped). Warm, urgent, not terminal.
- **Ineligible snooze = disabled tile + toast on tap.** The snooze action tile stays visible but renders at `Opacities.disabled`. Tapping the disabled tile fires `showCrudoToast` with the reason ("Meal is done", "Day is locked", etc.). Uses existing `ToastKind.warn`. The tile never hides — layout stability and discoverability.
- **Invalid snooze presets = disabled with reason text.** Presets past the bound render disabled (existing behavior) and gain a reason label below the minutes: "Past {next meal tag}" or "Past midnight". All 4 presets always visible — never hidden.
- **All-presets-invalid = empty-state message.** When `bound ≤ base + 10min` (no preset fits), the SnoozeSheet body shows "No room to snooze — your next meal is too soon" and the CTA is disabled. `canSnoozeMeal` should prevent the sheet from opening in this case, but the empty state is a safety net.
- **Snooze eligibility tightened: skipped meals excluded.** `canSnoozeMeal` gains a `skippedAt != null` guard. A skipped meal is a rejected commitment — snoozing contradicts the decision. To snooze a skipped meal, un-skip first (via `unmarkAll` or the skip toggle).
- **Grace window constant is the single source of truth.** `snoozeGraceMinutes` in `meal_lifecycle.dart` — referenced by every function that needs it. Never hardcoded anywhere else.
- **Notify results of disabled presets; toast won't directly explain timings**, but `snoozeIneligibilityReason` helper returns a human-readable string or null. UI consults it for the toast message. Lives in `meal_lifecycle.dart` beside `canSnoozeMeal`.

## Domain (`lib/domain/`)

### Enum change

```dart
// enums.dart — MealStatus gains overdue between upcoming and skipped:
enum MealStatus { done, partial, upcoming, overdue, skipped }
```

### Status derivation (updated priority chain)

```
1. any item checked     → done / partial    (clock + stamps irrelevant)
2. past day             → skipped           (history freezes unchecked)
3. future day           → upcoming          (preview)
4. skippedAt != null    → skipped           (explicit skip)
5. snoozedUntil > now   → upcoming          (snooze pending)
6. snoozedUntil != null → OVERDUE           (NEW: snooze expired, grace active)
   && now < graceEnd
7. now >= meal time     → skipped           (auto-skip: no snooze, or grace expired)
8. else                 → upcoming
```

```dart
// meal_status.dart — updated signature + rule 6:
MealStatus deriveMealStatus(
  ScheduledMeal meal,
  DateTime dayDate,
  DateTime now,
  DateTime graceEnd,   // NEW: from computeGraceEnd; pass `now` if irrelevant
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
  // NEW rule 6: snooze expired, grace window active
  if (snoozedUntil != null && now.isBefore(graceEnd)) {
    return MealStatus.overdue;
  }
  if (!now.toLocal().isBefore(localInstantAt(dayDate, meal.time))) {
    return MealStatus.skipped;
  }
  return MealStatus.upcoming;
}
```

### Grace computation (`meal_lifecycle.dart`)

```dart
/// Snooze grace period — the actionable window after a snooze expires
/// before the meal auto-skips. Single source of truth; promote to Prefs
/// if user-configurable grace is needed later.
const snoozeGraceMinutes = 15;

/// Grace end for an overdue meal: the earliest of snoozedUntil + grace,
/// next meal time, or end-of-day midnight. Returns UTC.
DateTime computeGraceEnd(Day day, String mealId, DateTime snoozedUntil) {
  final fixedGrace = snoozedUntil.add(
    const Duration(minutes: snoozeGraceMinutes),
  );
  final bound = day.maxSnoozeUntilFor(mealId, snoozedUntil);
  return fixedGrace.isBefore(bound) ? fixedGrace : bound;
}

/// Convenience: derives status with graceEnd computed from the Day.
/// UI callers use this; domain-internal callers that only check
/// `== upcoming` can call deriveMealStatus directly with `now` as graceEnd.
MealStatus mealStatus(Day day, String mealId, DateTime now) {
  final meal = day.meals.firstWhere((m) => m.id == mealId);
  final graceEnd = meal.snoozedUntil != null
      ? computeGraceEnd(day, mealId, meal.snoozedUntil!)
      : now;
  return deriveMealStatus(meal, day.date, now, graceEnd);
}
```

### Updated eligibility (`meal_lifecycle.dart`)

```dart
/// Updated: done and skipped meals cannot be snoozed.
bool canSnoozeMeal(Day day, String mealId, DateTime now, DateTime today) {
  if (isDayLocked(day, today)) return false;
  final meal = day.meals.where((m) => m.id == mealId).firstOrNull;
  if (meal == null) return false;
  if (meal.meal.allChecked) return false;       // done
  if (meal.skippedAt != null) return false;      // NEW: explicitly skipped
  return maxSnoozeUntil(day, mealId, now).isAfter(now);
}

/// Human-readable reason why snooze is unavailable, or null if eligible.
/// UI shows this in a toast when the disabled tile is tapped.
String? snoozeIneligibilityReason(
  Day day, String mealId, DateTime now, DateTime today,
) {
  if (isDayLocked(day, today)) return "Day is locked";
  final meal = day.meals.where((m) => m.id == mealId).firstOrNull;
  if (meal == null) return "Meal not found";
  if (meal.meal.allChecked) return "Meal is done";
  if (meal.skippedAt != null) return "Meal is skipped";
  if (!maxSnoozeUntil(day, mealId, now).isAfter(now)) {
    return "No room before your next meal";
  }
  return null;
}
```

### Mechanical caller updates

- **`canEditMealContent`** (meal_lifecycle.dart): pass `now` as graceEnd — safe sentinel for `== upcoming` check.
- **`Day.replaceMeal`** (day.dart): pass `now` as graceEnd — same reasoning.
- **`MealSheet`** (meal_sheet.dart): use `mealStatus(day, mealId, now)` or compute graceEnd via `computeGraceEnd`.
- **`TodayScreen`** (today_screen.dart): use `mealStatus(day, mealId, now)` or compute graceEnd. The `snoozed` label condition extends to include `MealStatus.overdue`.

## State layer (`lib/ui/features/today/view_models/`)

No changes. `DayController.snooze(mealId, until)` keeps its existing signature. The controller never reads `deriveMealStatus` — it delegates to `Day.snoozeMeal`. The `Day` domain op `snoozeMeal` is unchanged. The grace computation and overdue status are domain concerns; the controller simply persists whatever `Day` produces.

## UI (`lib/ui/`)

### Color tokens (`colors.dart`)

```dart
// CrudoPalette — new tokens:
static const overdue = Color(0xFFD97706);      // warm amber — urgent, not terminal
static const overdueSoft = Color(0xFFFEF3C7);  // amber tint — overdue circle bg
```

Add `overdue` and `overdueSoft` to `CrudoColors` (constructor, fields, `light` const, `copyWith`, `lerp`).

### MealCard — overdue rendering

- **Status label color:** `MealStatus.overdue => colors.overdue` (warm amber).
- **Vertical bar color:** `MealStatus.overdue => colors.overdue`.
- **Status circle:** `MealStatus.overdue` → `overdueSoft` background, clock icon (`Icons.schedule`) in `overdue` color — same icon as upcoming but amber instead of muted. Signals "still your turn, but urgent."
- **Title text:** overdue uses `colors.onSurface` (not muted like skipped — it's still actionable).
- **Snoozed-time label:** persists during overdue (the `snoozedUntil` field is still set) — the card shows the struck-through original + the expired snoozed time, so the user sees the commitment they made.

### TodayScreen — overdue snoozed label

Extend the snoozed-time computation to also render for `overdue` status:

```dart
// today_screen.dart — extend the condition:
final snoozed =
    meal.snoozedUntil != null &&
            (status == MealStatus.upcoming || status == MealStatus.overdue)
        ? timeOfDayLabel(meal.snoozedUntil!.toLocal())
        : null;
```

### MealSheet — snooze tile + overdue header

- **Snooze tile tap when disabled:** instead of `onTap: null`, the disabled tile gets a tap handler that fires `showCrudoToast(context, reason, kind: ToastKind.warn)` where `reason` comes from `snoozeIneligibilityReason`. The tile still renders at `Opacities.disabled` — the tap just produces a toast instead of opening the sheet.
- **Snoozed header label:** extend the condition to include `overdue` (same as TodayScreen).
- **Status derivation:** use `mealStatus(day, mealId, now)` or compute graceEnd.

### SnoozeSheet — disabled reasons + empty state

- **Disabled preset tiles** gain a reason label below "MIN": `CrudoText.labelMd` in `onSurfaceMut`, e.g., "Past Lunch" or "Past midnight". The reason is computed from the bound: if `bound == nextMealTime` → "Past {next meal tag}"; if `bound == endOfDay` → "Past midnight".
- **Empty state:** when all presets are disabled (`!enabled(snoozePresetMinutes.first)`), the body shows a centered message "No room to snooze — your next meal is too soon" in `CrudoText.body` + `onSurfaceMut`, and the CTA is disabled.

### Previews

Add a `MealCard — overdue` entry to `previews.dart` with `status: MealStatus.overdue` and `snoozedTimeLabel: '14:15'`.

## Tests

### Domain unit (`package:checks`, `meal_status_test.dart`)

- **Overdue:** snoozedUntil expired, within grace → `overdue`.
- **Overdue:** snoozedUntil expired, grace expired → `skipped` (rule 7).
- **Overdue:** snoozedUntil expired, grace = 0 (bound reached) → `skipped` immediately.
- **Checked wins over overdue** (rule 1).
- **Explicit skip beats overdue** (rule 4 over 6).
- **`MealTime(0)` + snooze + grace edge cases.**
- **Update the "elapsed snooze falls through to auto-skip" test** — it now produces `overdue` (within grace) or `skipped` (grace expired). Split into two assertions.

### Domain unit (`meal_lifecycle_test.dart`)

- **`computeGraceEnd`:** standard (snoozedUntil + 15min within bound); capped at next meal time; capped at end-of-day midnight; snoozedUntil at bound → grace = bound.
- **`canSnoozeMeal` guard additions:** returns false when `skippedAt` is set; returns true for overdue meal (snoozedUntil expired, within grace, bound allows).
- **`snoozeIneligibilityReason`:** returns null when eligible; returns "Day is locked" for past day; returns "Meal is done" for allChecked; returns "Meal is skipped" for skippedAt set; returns "No room before your next meal" when bound ≤ now.

### Widget (`meal_card_test.dart`)

- Overdue renders amber bar, amber "OVERDUE" label, clock icon on amber-soft circle, snoozedTimeLabel persists.

### Widget (`sheets_test.dart`)

- Disabled presets show reason text ("Past Lunch", "Past midnight").
- All-disabled shows empty-state message + disabled CTA.
- Disabled snooze tile tap fires toast with ineligibility reason.

### Widget (`today_screen_test.dart`)

- Overdue meal card shows snoozed time label.
- Circle tap on overdue meal completes it (existing `markAllEaten` path).

## Acceptance

- A meal snoozed until 12:30 (next meal at 13:00) shows `overdue` at 12:31, `skipped` at 12:46 (grace = 15 min).
- A meal snoozed until 13:00 (next meal at 13:00) skips immediately at 13:01 (grace = 0, bound reached).
- Tapping the disabled snooze tile on a done meal shows a toast: "Meal is done."
- Tapping the disabled snooze tile on a skipped meal shows a toast: "Meal is skipped."
- SnoozeSheet with bound 20 min away: 10m and 15m enabled, 20m enabled (bound inclusive), 30m disabled with "Past {next meal}" reason.
- SnoozeSheet with bound 5 min away: all presets disabled, empty-state message shown, CTA disabled.
- Overdue meal card renders amber bar + amber "OVERDUE" label + clock icon on amber-soft circle.
- Overdue meal's snoozed-time label persists on the card (struck-through original + expired snoozed time).
- `dart format .` clean · `flutter analyze` clean · `flutter test` green · architecture test green.

## Out of scope

- User-configurable grace period (promote to `Prefs` later if needed).
- Notification rescheduling on snooze/overdue (S14).
- Overdue-specific notification ("your snoozed meal is overdue").
- Weekend-skip interaction (post-MVP).
- Gram-level partial (post-MVP).
- Any change to `Day.snoozeMeal`, `maxSnoozeUntilFor`, `snoozeBaseFor`, or the `ScheduledMeal` model.

## Skills

`dart-add-unit-test` · `dart-migrate-to-checks-package` · `flutter-add-widget-test` · `flutter-expert` (const, semantics) · `flutter-riverpod-arch` (if controller changes needed).
