# Today screen — intake card + meal card polish

## Goal
Two visual refinements on the Today tab, no behavior change:

1. **Intake card macro bars** (`lib/ui/features/today/views/intake_card.dart`): stop the label truncating ("Protein"→"Prot") and mute the planned number. Stack **label over value over bar**; the consumed number is bold black, the `/planned` part is muted + non-bold (mirror the kcal treatment already used at the top of the card).
2. **Meal card** (`lib/ui/core/widgets/meal_card.dart`): replace the `P 30g C 45g F 12g` text with **colored dots + grams**; make **kcal smaller**; make the **ingredient preview smaller** and **fit-aware** (show as many names as fit on one line, collapse the rest into "+N more" — not a fixed first-3); **remove the DONE/PARTIAL/SKIPPED status text** (the circle already conveys status); keep the status circle top-aligned.

## Architecture / tech stack
Flutter, design system is law (`docs/design_system.md`): 4px grid + named tokens, **no raw `Border`**. Type scale (`lib/ui/core/themes/typography.dart`): `stat 56 · display 40 · title 18 · bodyLg 16 · body 14 · labelMd 12 · label 10`. Macro colors: `colors.proteinColor` (teal), `colors.carbsColor` (gold), `colors.fatsColor` (bronze). `MealCard` is a shared widget (`lib/ui/core/widgets/meal_card.dart`) — check all call sites before changing its public API; prefer changing only internals.

## How to work
Implement task-by-task, top to bottom. Each task = contract + steps. Read `AGENTS.md`, `docs/design_system.md`, and the named `.agents/skills` before starting. TDD with real values. **Do not commit** — end each task with "report done for review".

---

## Task 1 — Intake card macro bars: stacked layout + muted planned

**Role:** Flutter UI engineer.
**Goal:** Full labels (no truncation) + kcal-style consumed/planned emphasis.
**Files:** `lib/ui/features/today/views/intake_card.dart`, `test/ui/features/today/views/intake_card_test.dart` (create if absent).
**Skills:** `flutter-expert`, `flutter-fix-layout-issues`, `flutter-add-widget-test`, `dart-run-static-analysis`.

**Contract (rework `_MacroBar.build`):** replace the single side-by-side `Row(label, value)` with a vertical `Column`:
1. **Label** line — `Text(label)` in `CrudoText.labelMd` / `colors.onSurfaceVar`, full width, `maxLines: 1` (it no longer shares the row, so "Protein"/"Carbs"/"Fats" render in full at normal widths). Drop the `Flexible`/`FittedBox` label+value row.
2. **Value** line — `Text.rich` with two spans: the consumed `'${v.round()}'` in `CrudoText.labelMd` bold `colors.onSurface`, then `'/${total.round()}g'` in `CrudoText.labelMd` **non-bold** (`fontWeight: FontWeight.w500`) `colors.onSurfaceMut`. This mirrors the kcal treatment (bold consumed + muted `/planned`) at the top of the card.
3. **Bar** — the existing `ClipRRect` + `LinearProgressIndicator` (height 4, `colors.outline` track, macro `color` fill), unchanged, with the existing `Spacing.xs` gaps between the three lines.

Keep the `TweenAnimationBuilder` fill animation and the three `Expanded` columns + `Spacing.md` gutters in the parent `Row`.

**Acceptance:**
- Labels render in full ("Protein", not "Prot") at 390px width — widget test pumps at that width and finds the full text.
- Value shows bold consumed + muted non-bold `/Ng` (assert the two spans' styles differ in weight/color).
- `flutter test --timeout=90s` green; `flutter analyze` + `dart format` clean.

**Out of scope:** the kcal hero row, the ring, colors/tokens beyond those named; `MealCard`.

---

## Task 2 — Meal card: dots+grams, smaller kcal, fit-aware ingredient preview, no status text

**Role:** Flutter UI engineer.
**Goal:** Cleaner, denser meal card per the decisions below.
**Files:** `lib/ui/core/widgets/meal_card.dart`, `test/ui/core/widgets/meal_card_test.dart`, and any call-site tests asserting on removed text (grep for `P `/`kcal`/`DONE`/`PARTIAL` in `test/ui/features/today/`).
**Skills:** `flutter-expert`, `flutter-fix-layout-issues`, `flutter-add-widget-test`, `dart-run-static-analysis`.

**Contract:**

a) **Macros row → kcal + colored dots.** Replace the current `Row('${kcal} kcal', 'P ..g C ..g F ..g')` with:
   - kcal: `'${macros.kcal.round()} kcal'` in `CrudoText.labelMd` (12, **down from body/14**) bold `colors.onSurface`.
   - three macro chips, each = a small colored dot + grams `'${v.round()}g'`: dot is a `Container` `width: height: Spacing.xs` (or `Spacing.sm`), `shape: BoxShape.circle`, colored `proteinColor` / `carbsColor` / `fatsColor` respectively; grams text `CrudoText.labelMd` `colors.onSurfaceMut`. `Spacing.xs` between dot and grams, `Spacing.md`/`Spacing.sm` between chips. Order P, C, F.

b) **Ingredient preview → smaller + fit-aware.** Keep the preview but:
   - Style down to `CrudoText.labelMd` (12) `colors.onSurfaceMut` (was `body`/14).
   - Replace the fixed `_previewCount = 3` logic with a **width-aware** count: show as many names (joined by ` · `) as fit on **one line** at the available width, and collapse the remainder into a trailing ` · +N more`. Implement with a `LayoutBuilder` to get `maxWidth` and a `TextPainter`-based pure helper, e.g.:
     ```dart
     /// Largest k such that names[0..k) joined by ' · ' (plus ' · +N more'
     /// when k < names.length) fits within [maxWidth] at [style]. Always
     /// shows at least 1 name (may ellipsize if a single name overflows).
     static int _namesThatFit(List<String> names, double maxWidth, TextStyle style, TextScaler scaler);
     ```
     Render the resulting string with `maxLines: 1`, `overflow: TextOverflow.ellipsis` as a safety net. Keep the `if (ingredientNames.isNotEmpty)` guard.

c) **Remove status text.** Delete the `Text(status.name.toUpperCase(), ...)` in the meta row (top-right). The meta row becomes just the time · meal-type `Text.rich` (let it take the full width). Status is still conveyed by the left color bar + the trailing `_StatusCircle`.

d) **Keep** the trailing status circle top-aligned (leave `crossAxisAlignment: CrossAxisAlignment.start` and the circle's `Center` wrapper as-is), the left vertical status bar, `onTap`/`onStatusTap`, and all `Semantics`.

**Acceptance:**
- No `status.name` text anywhere in the card (grep the widget + tests).
- Macros row shows kcal + three colored dots with grams; a widget test finds the grams and asserts the three dot colors are the macro colors.
- Ingredient preview: at a wide width more names show than at a narrow width; the `_namesThatFit` helper has direct unit tests (empty → 0, one long name → 1, several short names → all fit, many → some + "+N more").
- kcal renders at `labelMd` size.
- `flutter test --timeout=90s` green (migrate call-site tests that asserted on `P ..g`/`DONE`/`PARTIAL`); `flutter analyze` + `dart format` clean.

**Out of scope:** `_StatusCircle` glyphs/colors, the left status bar colors, `onStatusTap` behavior, `IntakeCard`.
