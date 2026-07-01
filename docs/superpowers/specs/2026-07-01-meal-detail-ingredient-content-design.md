# Meal detail — ingredient content + intake card polish (design)

_Date: 2026-07-01 · Scope: meal detail screen only (`lib/ui/features/meals/views/meal_detail_screen.dart`)_

## Problem
The redesigned ingredient rows feel empty (just check circle · name · `grams·kcal`), and the TOTAL INTAKE card is a flat kcal + three boxed macro tiles. Surface the per-ingredient data already in `FoodSnapshot` and give the intake card a light visual anchor — kept minimal and on-brand (4px grid, tokens, macro colors, no-line rule).

## Data available (no domain change)
`FoodSnapshot` (per ingredient): `name`, `category` (`FoodCategory {meat, fish, eggs, grain, veg, fruit, oil, custom}`), `kind`, `grams`, `protein`, `carbs`, `fats`, `kcal`. Meal-level: `meal.meal.tags` (list of tags, set at meal creation). All display-only; the engine reads none of this.

## Design

### 1. Shared macro-dot widget (extract, DRY)
`_MacroChip` in `meal_card.dart:248` (a colored dot + `Ng` label) is promoted to a public shared widget, e.g. `lib/ui/core/widgets/macro_chip.dart` → `MacroChip({required double grams, required Color color})`. `meal_card.dart` imports it (drops its private copy). Reused by the ingredient rows and the intake card. No behavior change to the meal card.

### 2. Ingredient rows — category icon + macro dots
`_ItemRow` gains a `category` param (loop passes `item.food.category`) and renders **two lines**:
- **Line 1:** `[check circle] · [category icon] · name (Expanded) · '${grams}g · ${kcal} kcal'`.
  - Category icon sits between the check circle and the name, `IconSizes.md`, single accent color `colors.primary` (no per-category palette — decided).
  - Icon → `IconData` via a helper `foodCategoryIcon(FoodCategory)` (Material Icons, app's existing set, no new dep):

    | meat | fish | eggs | grain | veg | fruit | oil | custom |
    |------|------|------|-------|-----|-------|-----|--------|
    | `kebab_dining` | `set_meal` | `egg` | `grain` | `eco` | `nutrition` | `water_drop` | `category` |

- **Line 2** (aligned under the name): a row of three `MacroChip`s — protein/carbs/fats grams in `colors.proteinColor` / `carbsColor` / `fatsColor`.

The existing checked-state treatment (animated strikethrough + muted name) and the draft toggle behavior are unchanged. When checked, the name strikes through as today; the icon + dots stay as-is.

Helper location: `foodCategoryIcon` in `lib/ui/core/formatting.dart` (or a small `food_category_icon.dart`), pure `FoodCategory → IconData`.

### 3. TOTAL INTAKE card (`_MacroSummary`) — split bar + dots + tags
Replace the three boxed macro tiles with:
- **kcal hero** — unchanged (big kcal + `kcal`).
- **Macro split bar** — one thin (height 4, `Radii.full`) horizontal bar split into three segments proportional to each macro's **kcal contribution** (`protein*4`, `carbs*4`, `fats*9`), colored `proteinColor` / `carbsColor` / `fatsColor`. Zero total → `surfaceLow` track. Same visual family as `_EatenProgress` / the intake bars.
- **Macro dot row** — three `MacroChip`s (P/C/F grams), same shared widget.
- **Meal tag chips** — a wrapped pill row at the **bottom** of the card: one small pill per `meal.meal.tags` entry (`tag.name`, `surfaceLow` pill + `CrudoText.label`). No tags → the row is omitted. `_MacroSummary` gains a `tags` param.

The header meta line keeps its current `time · type · status` (tags now live in the card, so the inline first-tag can be dropped from the header — minor, optional).

## Out of scope
- Today list meal cards (no change).
- New color tokens / per-category colors (single accent only).
- The other brainstormed touches (icon badge, MacroRing, macro-segmented fill line) — dropped for minimalism.
- Domain / persistence changes.

## Testing
- `foodCategoryIcon`: a unit test asserting every `FoodCategory` maps to a non-null distinct `IconData`.
- `MacroChip`: widget test (dot color + grams text).
- `_ItemRow`: renders category icon + three macro dots.
- `_MacroSummary`: renders split bar segments in macro colors, dot row, and one pill per tag (none when empty).
- Full suite green (`flutter test --timeout=90s`), analyze + format clean.
