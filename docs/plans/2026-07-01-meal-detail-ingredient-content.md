# Meal detail — ingredient content + intake card polish (plan)

Design spec: `docs/superpowers/specs/2026-07-01-meal-detail-ingredient-content-design.md` (read it first).

## Goal
On the meal detail screen only: give ingredient rows a category icon + per-ingredient macro dots, and rework the TOTAL INTAKE card into kcal hero + macro-split bar + macro dots + meal tag chips. Extract the meal-card's dot+grams chip into one shared widget. No domain/persistence change, no Today-card change, no new color tokens.

## Architecture / conventions
Flutter + Riverpod. Design system is **law** (`docs/design_system.md`): 4px grid, named tokens, **no raw `Border`** (use surfaces / painted rings / progress tracks). Type/space/color tokens in `lib/ui/core/themes/`. Macro colors: `colors.proteinColor` / `carbsColor` / `fatsColor`. Match surrounding widget style. Icons come from the app's existing **Material Icons** set (no new package).

Work task-by-task, top to bottom. TDD with real values. Run `flutter test --timeout=90s` after each task (ALWAYS pass the timeout — some tests hang). Keep all tests green; migrate any you break. `flutter analyze` + `dart format` clean. **Do not commit** — leave changes staged for review.

---

## Task 1 — Extract shared `MacroChip` widget
**Files:** new `lib/ui/core/widgets/macro_chip.dart`; `lib/ui/core/widgets/meal_card.dart`; `test/ui/core/widgets/macro_chip_test.dart`, `test/ui/core/widgets/meal_card_test.dart`.
**Contract:**
```dart
// lib/ui/core/widgets/macro_chip.dart
/// A colored dot + '<grams>g' label — the shared macro glyph used on the
/// meal card, ingredient rows, and intake card.
class MacroChip extends StatelessWidget {
  const MacroChip({required this.grams, required this.color, super.key});
  final double grams;
  final Color color;
}
```
- Move the private `_MacroChip` implementation out of `meal_card.dart` into this public widget **verbatim** (same dot size / spacing / `CrudoText` token / muted grams color). Update `meal_card.dart` to import and use `MacroChip`; delete its private copy.
**Acceptance:** meal card renders identically (its existing tests still pass unchanged except the type name if asserted); a `MacroChip` widget test asserts the dot color + `Ng` text. Suite green.

## Task 2 — `foodCategoryIcon` helper
**Files:** `lib/ui/core/formatting.dart` (add function); `test/ui/core/formatting_test.dart` (add/create).
**Contract:**
```dart
IconData foodCategoryIcon(FoodCategory category) => switch (category) {
  FoodCategory.meat  => Icons.kebab_dining,
  FoodCategory.fish  => Icons.set_meal,
  FoodCategory.eggs  => Icons.egg,
  FoodCategory.grain => Icons.grain,
  FoodCategory.veg   => Icons.eco,
  FoodCategory.fruit => Icons.nutrition,
  FoodCategory.oil   => Icons.water_drop,
  FoodCategory.custom => Icons.category,
};
```
Pure, exhaustive switch (no default). **Acceptance:** unit test asserts every `FoodCategory` value maps to a non-null icon and the switch is exhaustive (compile-checked). Suite green.

## Task 3 — Ingredient rows: category icon + macro dots
**Files:** `lib/ui/features/meals/views/meal_detail_screen.dart`; `test/ui/features/meals/views/meal_detail_screen_test.dart`.
**Contract:** extend `_ItemRow` with `final FoodCategory category;` and the per-macro grams (`protein`/`carbs`/`fats`) — pass them from the build loop via `item.food.*`. Render two lines:
- **Line 1:** `check circle` · `Icon(foodCategoryIcon(category), size: IconSizes.md, color: colors.primary)` · `name` (Expanded, keeps the animated strikethrough + muted-on-checked behavior) · `'${grams}g · ${kcal} kcal'` trailing.
- **Line 2** (left-aligned under the name, indented to clear the check circle + icon): `Row` of three `MacroChip`s — protein/carbs/fats in the macro colors, `Spacing.sm` between.
Keep the existing tap-to-toggle-draft, `Semantics`, and check animation untouched. Icon spacing on the 4px grid.
**Acceptance:** a row shows the correct category icon (test one category), three macro dots, and still toggles the draft; checked name still strikes through. Suite green.

## Task 4 — TOTAL INTAKE card: split bar + dots + tags
**Files:** `lib/ui/features/meals/views/meal_detail_screen.dart`; `test/ui/features/meals/views/meal_detail_screen_test.dart`.
**Contract:** rework `_MacroSummary` (add `final List<MealTag> tags;`, passed from the caller as `meal.meal.tags`; `MealTag.name` is the label). Replace the three boxed macro tiles with, top to bottom:
1. kcal hero — unchanged.
2. **Macro split bar** — a thin (`height: 4`, `Radii.full`) horizontal bar of three `Expanded`/flex segments proportional to each macro's kcal contribution (`protein*4`, `carbs*4`, `fats*9`), colored `proteinColor` / `carbsColor` / `fatsColor`. If total kcal-contribution is 0, render a single `surfaceLow` track. Mirror the `_EatenProgress` construction (ClipRRect + flex Row of ColoredBoxes) — no `Border`.
3. **Macro dot row** — three `MacroChip`s (P/C/F grams), `Spacing.md` gaps.
4. **Tag chips** — a `Wrap` (`Spacing.xs` spacing) of small pills, one per tag: `Container` `surfaceLow` + `Radii.full` + `EdgeInsets.symmetric(horizontal: Spacing.sm, vertical: Spacing.xs)`, child `Text(tag.name, style: CrudoText.label)`. Omit the whole row when `tags.isEmpty`.
Optionally drop the now-redundant inline first-tag from the header meta line.
**Acceptance:** card shows a 3-segment bar in the macro colors, the dot row, and one pill per tag (no pill row when empty); kcal hero intact. Suite green; analyze + format clean.

---

## Report back
Files changed, the shared-widget extraction result, tokens used (confirm no raw `Border` / ad-hoc color / off-grid values), and the exact `flutter test` summary line.
