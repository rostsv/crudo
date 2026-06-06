# Spec — S07: Custom Food + Validation, Food Library

**Status:** approved (design) · **Spec S07 (logic+ui)** · depends on S02 (Food model, validation framework, nutrition service), S03 (FoodRepository + seed, IdGenerator), S04 (routing, core widgets, sheets/toast), S06 (riverpod codegen conventions) · scope = food library list screen + custom-food form (full CRUD; seed read-only). Visual target: `docs/design/prototype/screens/meal.jsx` (`AddCustomFoodScreen`, plus `AddIngredientScreen`'s list portion for grouping/search), dimensions snapped to `design_system.md §5` tokens.

## Goal

Users create, edit, and delete their own foods (macros per 100 g, kcal auto-calc with ±10 % override check) and browse the full library (seed + custom). The library list ships as a reusable view that S08's add-ingredient picker wraps later — S08 then only adds the pick/grams flow and the "Create custom food" CTA wiring.

## Decisions (brainstorm 2026-06-06)

- **Scope = form + library list.** S07 ships the custom-food form screen and the reusable library list (search + category grouping). S08 reuses the list as the add-ingredient picker.
- **Full CRUD** on custom foods. Seed foods (`isCustom == false`) read-only — no edit entry, no delete.
- **Deletion rule locked: block-while-referenced.** When meal templates exist (S09), deleting a food referenced by any template `FoodRef` is blocked. Until then no reference is possible, so S07 delete is unconditional. Instances (`FoodSnapshot`) are frozen copies — never affected by library edits/deletes.
- **Entry point: route + gallery.** Real go_router route (`/foods`) registered but not linked from tab nav; library + form get entries in the widget gallery (`lib/previews.dart`). Permanent nav placement decided later (S15 candidate).
- **Explicit kcal out of ±10 % → hard block.** Inline mismatch error + save disabled until within range or cleared (clearing reverts to auto-calc). Stored kcal therefore always passed the input-time check — matches the S02/S05 lock ("the accepted value simply IS the kcal", no override field).
- **All-zero macros allowed** (water, black coffee, diet soda). Then calculated kcal = 0 and `isExplicitKcalValid` requires explicit kcal = 0 — form shows the rule when violated; empty override saves kcal 0.
- **Duplicate names allowed.** No uniqueness rule anywhere in the domain; users may want "Chicken breast" with their label's macros.
- **Delete affordance: edit screen only.** Delete button on the edit-food screen → confirm via `showCrudoSheet` → repo delete. No swipe-to-delete on list rows.
- **Product|Dish toggle in the form** (S05 design-doc mandate; default `product`). The prototype predates this decision and lacks it — toggle is added per S05, prototype is sketch.
- **No new domain code.** `Food`, `isExplicitKcalValid`, `calculatedKcal`, `FoodValidation.validate()`, `ValidationCode.kcalOverrideOutOfRange`, `FoodRepository` all shipped in S02/S03/S05. S07 finally consumes `kcalOverrideOutOfRange` (form-level).

## State layer (`lib/ui/features/foods/view_models/`)

All providers `@riverpod` codegen style (S06 conventions).

- **`foodLibraryProvider`** — watches `FoodRepository.watchAll()`, exposes a filtered/grouped view model:
  - search query (own small `Notifier<String>` or family arg): case-insensitive name `contains`, trimmed.
  - grouping: `kind == dish` → "Dishes" group, placed last (S05: library "Dishes" group); rest grouped by `FoodCategory` (7 labeled categories + `custom`), groups sorted in enum order, foods alphabetical within group. Empty groups omitted.
  - exposes per-food `isCustom` so rows can mark editability.
- **`FoodDraftController`** — `@riverpod` controller, family by `foodId?` (null = create; id = edit, `build` loads the food from the repo — async, so `AsyncNotifier`-shaped like S06 controllers). Draft record: `name`, `kind` (default `FoodKind.product`), `category?` (null → saved as `FoodCategory.custom`), `protein`/`carbs`/`fats` (default 0), `explicitKcal?` (null = auto).
  - Derived (pure domain fns, no duplication): `calculatedKcal(p, c, f)` · effective kcal = explicit ?? calculated · issue list = `Food.validate()` rules on the draft (blank name, macro mass ≤ 101) **plus** form-level `kcalOverrideOutOfRange` when `explicitKcal != null && !isExplicitKcalValid(...)` · `canSave` = issues empty.
  - `save()`: create → `Food(id: idGenerator.newId(), isCustom: true, kind, category ?? custom, p, c, f, kcalPer100g: effective)`; edit → `copyWith` keeping `id`/`isCustom`. Stored kcal = unrounded double (display rounds). `repo.save`, wrapped `AsyncValue.guard`; rejection → `showCrudoToast`.
  - `delete()` (edit mode, custom only): `repo.delete(id)`.
  - Edit mode `build` loads the existing food into the draft; guards against seed foods (assert/return — UI never routes there).

## Screens (`lib/ui/features/foods/views/`)

- **`FoodLibraryScreen`** — route `/foods` (registered, unlinked):
  - Appbar "Food library"; trailing add (`IconBtn` +) → form (create).
  - Search field (soft input per design system) at top.
  - Grouped list: section label per group (CAT_LABELS from prototype: Meat, Fish, Eggs & Dairy, Grains, Vegetables, Fruits, Oils & Fats, plus Custom and Dishes); rows show name + per-100g kcal summary (`{kcal} kcal · P{p} C{c} F{f}`).
  - Custom rows: marker (small "custom" pill or icon) + tap → form (edit). Seed rows inert in S07 (S08 picker adds pick behavior).
  - Empty search → muted "No foods match" hint (prototype copy adapted; CTA wording arrives with S08).
- **`FoodFormScreen`** — push route from library (create/edit), per prototype `AddCustomFoodScreen`:
  - Header: title "Custom food" / "Edit food" · back · **SAVE** text button (tertiary), disabled (dimmed) unless `canSave`.
  - Name input (large soft input, placeholder "e.g. My protein blend").
  - **Product|Dish toggle** (segmented/choice chips; default Product).
  - Category chips (7 categories, icon + label, tap selects / tap again clears, "OPTIONAL" label). Skipped → saved as `custom`.
  - Macros per 100 g: Protein / Carbs / Fats numeric inputs with color bar accents (primary / gold / bronze) + "g" suffix. All required (blank treated as 0).
  - Kcal card (`surface-low` container): "Calculated kcal" big number (rounded) left · "Override (optional)" numeric input right (placeholder "auto"). Mismatch (explicit set + out of ±10 %) → inline error banner "Override differs by {n}% from macros. Max allowed is 10%." + save blocked. All-zero macros + nonzero explicit → same banner pattern with zero-rule copy.
  - Edit mode extra: **Delete food** destructive button at bottom → confirm sheet (`showCrudoSheet`: title, body, destructive CTA + cancel) → delete, pop to library, toast.
- All dimensions on tokens; new sizes → `dimensions.dart` + `design_system.md §5`.

## Tests

- **Controller unit** (`ProviderContainer` + in-memory repo): validation matrix — blank name · macro mass > 101 blocked, 100.9 ok · explicit kcal in/out of ±10 % · all-zero macros + explicit 0/empty ok, nonzero blocked · valid draft → `canSave`; save shape — uuid id minted once, `isCustom: true`, kind/category defaults, kcal = calculated when auto / explicit when set, unrounded; edit roundtrip — load, mutate, save keeps id; delete removes from repo; library provider — search filtering, dish group, category grouping/order, custom flag.
- **Widget** (fake/overridden providers): library renders groups + rows; search narrows; custom row tap → edit form prefilled; seed row inert; add button → empty form; form save gating across validation matrix; mismatch banner appears/disappears; override clear reverts to auto; toggle + category chip select/clear; delete flow incl. confirm sheet; empty-search state.
- Gallery entries for both screens in `lib/previews.dart`.

## Acceptance

- From `/foods` (dev route): browse seeded library grouped + searchable; create a custom food end-to-end (auto kcal and valid override variants); see it appear live in the list (watch stream); edit it; delete it with confirmation.
- ±10 % rule enforced exactly via `isExplicitKcalValid` — no reimplementation; stored `kcalPer100g` always input-validated.
- Seed foods untouchable (no edit entry, no delete path).
- Visuals match `meal.jsx` `AddCustomFoodScreen` composition + design-chat refinements (category chips), all dimensions on tokens.
- `dart format .` clean · `flutter analyze` clean · `flutter test` green · architecture test green.

## Out of scope

Add-ingredient picker, grams entry, pick callback + "Create custom food" CTA (S08) · meal editor (S08) · referenced-food delete enforcement + template `FoodRef`s (S09) · permanent nav placement (S15 candidate) · oz units (foods always per 100 g; unit display is a later display concern) · seed-food editing · name uniqueness · goldens.

## Skills

`flutter-riverpod-arch` · `dart-add-unit-test` · `flutter-add-widget-test` · `flutter-add-widget-preview` · `flutter-expert` (const, semantics on tap targets, form a11y).
