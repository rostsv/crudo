# Spec — S08: Meal Editor

**Status:** approved (design) · **Spec S08 (ui)** · depends on S03 (repos, IdGenerator), S04 (routing, core widgets, sheets/toast), S05/S05.1 (lifecycle engine: `replaceMeal`, `canEditMealContent`, `mealStatus`, CoW contract), S06/S06.1 (Today screen, DayController, MealSheet stand-in, intake freeze), S07 (food library list + form) · scope = meal detail route + day-instance meal editor + add-ingredient picker (→ custom-food callback) + swap-from-library, with copy-on-write future-day detach. Visual target: `docs/design/prototype/screens/meal.jsx` (`MealDetailScreen`, `AddMealScreen`, `AddIngredientScreen`) + `sheets.jsx` (`SwapSheet`), dimensions snapped to `design_system.md §5` tokens.

## Goal

Users open a full meal-detail screen from Today, mark/skip/snooze as before, and — while a meal is still `upcoming` — swap its content from the meal-template library or edit it (name, tags, ingredients with grams), including on future days, where the first content edit detaches the day from its plan (copy-on-write, S05 §4.2–4.3). Add-ingredient reuses the S07 library list as a picker and round-trips through the custom-food form with the in-progress draft preserved.

## Decisions (brainstorm 2026-06-07)

- **Full `mealDetail` pushed route.** The S06 `MealSheet` was the declared stand-in; it retires. The route carries the prototype's full composition: macro summary card, "X OF Y EATEN" progress, checklist, Snooze/Swap action tiles, Skip + dynamic primary footer, Edit entry in the header. `SnoozeSheet` survives (opened from the detail route). Intake-freeze rewires from sheet-open/close to route-push/pop.
- **Copy-on-write detach in scope.** Content ops (`replaceMeal`) are allowed on today *and future* days. A future day comes out of `DayController.build()` as a preview; applying a content op and saving persists it → Detached (S05 §4.3 read path: repo hit wins thereafter). Marking/skip/snooze ops stay **today-only** (unchanged `_apply` guard).
- **Instance-only editor.** The editor edits the day's `MealSnapshot` (instance). Swap picks from `MealTemplateRepository` (dev demo seed until plans ship). Meal-*template* CRUD is S10/S11; the editor is built draft-shaped (name/tags/items) so S11 can re-target the same screen at templates.
- **Draft + single `replaceMeal` commit.** The editor holds a draft; Save constructs a **fresh `MealSnapshot` whose items are all unchecked by construction** (`MealItem` default `checkedAt: null`) and commits once via the existing `replaceMeal` op + its upcoming-only guard. This discharges the S05-review obligation (replaceMeal doesn't reject pre-checked incoming items) at the contract level: no S08 path can produce a checked incoming item. Cancel = discard draft, free. No new granular Day ops.
- **Editable: items + name + tags.** All three live on `MealSnapshot`. `ScheduledMeal.time` is plan-owned scheduling — not editable on instances (snooze covers "later today").
- **Custom-food return = grams stage, prefilled.** After saving a custom food from the picker, the user lands back in the picker's grams stage with the new food selected (default 100 g shown, user confirms portion). The prototype's auto-add-at-100g shortcut is rejected (silent wrong-portion risk).
- **Swap = sheet, immediate commit.** `showCrudoSheet` per `sheets.jsx SwapSheet`: template rows (name · tags · kcal · ingredient count); row tap → `replaceMeal` with the resolved snapshot → sheet closes. No confirm step (reversible: meal was `upcoming`, nothing checked; swap again or edit).
- **Eligibility only via existing predicates.** Edit + Swap gate = `canEditMealContent` (derived status `upcoming` only — overdue-in-grace, partial, done, skipped, past all blocked). Display statuses only via `mealStatus(day, mealId, now)`. Never hand-roll status checks; the `now`-as-graceEnd sentinel stays domain-internal.
- **Snooze is today-only UI.** On future days the detail screen shows the Swap tile only — the domain would technically accept a future-day snooze, but snooze is a today-action by product definition (notifications, S14). Past days: read-only, no tiles, no footer (current sheet behavior carried over).
- **Picker CTA styling:** the prototype's 1.5 px dashed border on "Create custom food" violates the no-line rule — render as a tonal `surface-low` container with `primary-container` icon circle instead.
- **Editor back = confirm when dirty** (review amendment 2026-06-07): a pristine draft pops silently; a dirty one (any change vs the loaded snapshot — compared via `toSnapshot()` freezed equality) shows a "Discard changes?" sheet (Keep editing / Discard). Kills the silent data-loss footgun both reviews flagged.
- **Detach is made visible** (review amendment): the first content edit that detaches a future day (op succeeds AND the day had no persisted row before it) shows a one-time toast — "This day now keeps its own changes — plan edits won't affect it." Persistent detached-day badge deliberately parked for the week-view/plans era (S09–S13 obligation).
- **Draft loads once** (review amendment — real bug found by review): `MealDraftController.build` reads the day via `ref.read(...)`, it does NOT watch — an external day write while the editor is open (S14 notification actions later) must not silently reset an in-progress draft. Staleness is caught at commit time by the `replaceMeal` guard.
- **`FoodFormScreen` pop-result retrofit:** `FoodDraftController.save()` returns the saved `Food`; the form pops with it as the route result. The S07 library flow ignores the result; the picker awaits it.
- **Demo-seed weekday bug** (`days: [1..7]` vs 0=Mon…6=Sun) fixed separately before S08 (committed independently).
- **Critical-review resolution (2026-06-07,** `docs/reviews/2026-06-07-s08-meal-editor-review.md` + `.opencode/handoff/2026-06-07-s08-meal-editor.review.md`**):** scope kept in full — the proposed editor/picker cut only resequences work S11/S17 consume, and the "template-editing instead" redesign misreads the invariant (AGENTS.md: "upcoming-today meals can be edited/swapped"; CoW detach locked at S05 §4, UC7). Adopted: the three amendments above + Task-9 split + roadmap checkmark housekeeping. Rejected (reasons logged in review reply): live-edit+undo instead of draft, bottom-sheet picker, persistent detach badge now, swap-on-skipped (S05 strict v1), status-discipline architecture test, route flattening, integration/perf/a11y/l10n budgets, S14-first resequencing.

## Domain (`lib/domain/` — additions only, engine is shipped)

- **`mealSnapshotFromTemplate(MealTemplate template, List<Food> foods)`** — new pure fn in `services/meal_lifecycle.dart`. Resolves each `FoodRef` against `foods` by id: `MealItem(food: FoodSnapshot.from(food, ref.grams))` — items unchecked, absolutes baked at creation (the only snapshot factory, S05 §1.4). Dangling refs dropped defensively. Result: `MealSnapshot(sourceMealTemplateId: template.id, name: template.name, tags: template.tags, items: …)`. **`buildDayFromPlan` refactors to call it** (single resolution path; a slot whose resolved items are empty is still dropped — behavior unchanged, existing tests stay green).
- **`FoodSnapshot.scaledTo(Grams newGrams)`** — new method on the pure value: returns a copy with `grams = newGrams` and protein/carbs/fats/kcal scaled by `newGrams.value / grams.value` (S05: "grams edits scale linearly"). Never re-resolves the library — the snapshot is the source (library may have diverged or been deleted).
- No other domain changes. `replaceMeal`, `canEditMealContent`, `mealStatus`, `canSkipMeal`, `canSnoozeMeal`, `snoozeIneligibilityReason` ship as-is.

## State layer (`lib/ui/features/meals/view_models/`)

All providers `@riverpod` codegen style.

- **`MealDraft`** — draft type: `name: String`, `tags: List<MealTag>`, `items: List<FoodSnapshot>`, plus the original's `sourceMealTemplateId` (weak back-ref preserved through edits). Derived (pure, no duplication): `macros` = fold of item absolutes (`Macros`), `canSave` = trimmed name non-empty ∧ items non-empty (the S02 "≥1 item per saved meal" rule).
- **`MealDraftController`** — `@riverpod` family `(DateTime date, String mealId)`, `AsyncNotifier`-shaped: `build` loads the day ONCE via `ref.read(dayControllerProvider(date).future)` (no watch — an external day write must not clobber an in-progress draft; staleness surfaces at save via the domain guard), finds the meal, maps its `MealSnapshot` → draft (marks dropped — only `upcoming` meals are editable, so none exist). Keeps the loaded snapshot for `isDirty` (draft `toSnapshot() != initial`). Ops: `setName`, `toggleTag`, `addItem(FoodSnapshot)`, `removeItem(int index)`, `setItemGrams(int index, Grams g)` (→ `items[i].scaledTo(g)`). `save()`: build `MealSnapshot` with `items: [for (f in draft.items) MealItem(food: f)]` (unchecked by construction) → `DayController.replaceMeal`, wrapped `AsyncValue.guard`; rejection → toast at call site.
- **`DayController`** (today feature, existing) — new content op:
  - `Future<void> replaceMeal(String mealId, MealSnapshot newMeal)` via a new `_applyContent` path: rejects **past** dates (`date.isBefore(today)` → `StateError`), otherwise loads the day from `future` (today = persisted snapshot; future = built preview), applies `day.replaceMeal(mealId, newMeal, now, today)`, `repo.save`. For a future date the save **is** the detach — `persistedDayProvider` emits, the controller settles on the snapshot, later template edits no longer touch it.
  - `_apply` (marking/skip/snooze) keeps its today-only guard verbatim.
- **Swap wiring** — the detail screen watches `mealTemplatesProvider` + `foodsProvider` (today feature providers); each template row resolves `mealSnapshotFromTemplate(t, foods)` for its macro summary (pure call at build, no persistence); tap → `DayController.replaceMeal(mealId, resolved)`. A template whose resolved items are empty (all refs dangling) renders disabled.

## Routing (`lib/routing/app_router.dart`)

Top-level pushed routes over the shell (same placement as `/foods`):

- `/meal/:date/:mealId` → `MealDetailScreen` — `date` = ISO `yyyy-MM-dd` of the day label, parsed back to `DateTime.utc(y,m,d)`.
- `/meal/:date/:mealId/edit` → `MealEditorScreen`.
- `/meal/:date/:mealId/edit/add-ingredient` → `AddIngredientScreen` (pops with the picked `FoodSnapshot` as result; the editor adds it to the draft).
- Custom food from the picker: `context.push<Food>('/foods/new')` — the retrofitted form pops the created `Food`; the picker enters its grams stage prefilled with it. The draft survives all pushes — it lives in `MealDraftController`, keyed by `(date, mealId)`, not in route state (no prototype-style pending callback).

## UI (`lib/ui/features/meals/views/` + today wiring)

- **`MealDetailScreen`** — replaces `MealSheet` (file deleted; `_ItemRow`/`_CheckCircle`/`_ActionTile` move here; `SnoozeSheet` + `sheet_actions.dart` reused as-is):
  - Header: back · meal name title · label `time · tag · status` (snoozed strikethrough chip logic carried over) · **Edit icon button** — enabled iff `canEditMealContent`; tap while ineligible → warn toast ("That can't be changed anymore." for done/partial/skipped/past; overdue-in-grace included by derivation).
  - Macro summary card (`surface-low`, `r-lg`): "TOTAL INTAKE" label, large kcal number + "kcal" suffix, 3 macro mini-tiles (PROTEIN/CARBS/FATS in their accent colors) — values from `mealSnapshotMacros`.
  - "Ingredients" headline + `X OF Y EATEN` label + thin progress bar (checked fraction).
  - Checklist rows (carried over): tappable today, inert on past *and future* days.
  - Action tiles: **today** = Snooze (disabled + reason toast per `snoozeIneligibilityReason`) + Swap; **future** = Swap only; **past** = none. Swap enabled iff `canEditMealContent`, disabled tap → same guard toast.
  - Footer (today only): Skip (`SecondaryAction`, iff `canSkipMeal`) + dynamic `PrimaryCta` (0 checked → "Mark Done" = `markAllEaten`+pop · some → "Save Partial" = pop · all → "Mark Done" = pop). Past/future: no footer.
  - Today wiring: meal card tap pushes the route for past/today/**future** (future cards become tappable); intake freeze: `freeze(consumedMacros(day))` before push (today only), `clear()` after the push future completes. Status circle quick-complete unchanged.
- **`SwapSheet`** — `showCrudoSheet` from the Swap tile, per `sheets.jsx`: label "FROM YOUR LIBRARY", title "Swap meal", rows = template name + `tags · kcal · n ingredients` summary + swap icon; tap → replace + close (immediate). Empty library → muted hint.
- **`MealEditorScreen`** — per `AddMealScreen` minus time (instance editor):
  - Header: back · "Edit meal" · **SAVE** text button, disabled-dim unless `canSave`. Back (header button AND system pop): pristine draft → pop; dirty → "Discard changes?" confirm sheet (`PopScope` + `showCrudoSheet`, Keep editing / Discard).
  - Name: large soft input (S07 form pattern, controllers-created-once).
  - Tags: "TAGS · SELECT MULTIPLE" label + 6 `Pill` chips (Breakfast/Lunch/Dinner/Snack/Pre-workout/Post-workout), multi-toggle.
  - Ingredients card (`surface-low`, `r-lg`): header "Ingredients" + `N ITEMS` label; rows = name, `{g}g · {kcal} kcal` summary, trailing remove (X); **row tap → grams sheet** (shared `GramsEntry` widget, prefilled) → confirm = `setItemGrams`; empty state "No ingredients yet"; full-width "ADD INGREDIENT" tonal button → picker route.
  - Macro preview: gradient card (`primary→primary-soft`, 135°) "AUTO-CALCULATED" + kcal + P/C/F line, live from draft.
  - Save: `save()` → pop to detail (which re-renders from the controller stream); guard rejection (raced status flip) → warn toast, stay. Detach toast: both commit points (editor save, swap row) pre-check `date > today && persistedDay == null`; on success after such a commit show the one-time detach toast.
- **`AddIngredientScreen`** — two-stage, per prototype:
  - Stage 1 (list): S07's library list **refactored into a reusable `FoodLibraryList`** (search field + grouped sections + empty-search state) with an `onPick(Food)` callback and optional header slot. `/foods` keeps current behavior (custom rows → edit, seed inert); the picker makes **every** row pick. Header slot = persistent "Create custom food" CTA (tonal container, `primary-container` plus-icon circle, title + "Add your own with macros per 100g" subtitle — no dashed border). Empty-search hint gains the prototype's "Use the button above to add it as a custom food." second line in picker mode.
  - Stage 2 (grams): selected card (name, per-100g kcal) · `GramsEntry`: large numeric input + `g` suffix, preset pills 50/100/150/200/250, live "For {g}g" macro preview (kcal + P/C/F) · footer `PrimaryCta` "Add to Meal" — disabled unless grams > 0 (`Grams` VO requires positive). Confirm → `FoodSnapshot.from(food, Grams(g))` — **snapshot created at add time** (S05 §1.4 point 2) → pop result.
  - "Create custom food" → push `/foods/new`, await `Food` result → stage 2 prefilled with it; cancel/back from the form → back to stage 1, draft intact.
- **`GramsEntry`** — shared widget (picker stage 2 + editor's grams re-edit sheet). In the sheet variant it's seeded from an existing `FoodSnapshot` (grams + derived per-100g for preview) and confirms with the new `Grams`.
- Gallery entries (`lib/previews.dart`) for `MealDetailScreen`, `MealEditorScreen`, `AddIngredientScreen`.
- All dimensions on tokens; any new size → `dimensions.dart` + `design_system.md §5`, same change.

## Tests

- **Domain unit** (`package:checks`): `mealSnapshotFromTemplate` — resolution shape (name/tags/back-ref/absolutes), dangling ref dropped, all items unchecked; `scaledTo` — linear scaling, grams replaced, zero-macro food stays zero; `buildDayFromPlan` existing matrix stays green through the refactor.
- **Controller unit** (`ProviderContainer`, fakes): `MealDraftController` — build loads snapshot into draft; mutation ops (name/tags/add/remove/setItemGrams scales); `canSave` matrix (blank name, zero items); `isDirty` false on load / true after any mutation / false again after reverting; **external day write while editing does NOT reset the draft** (load-once); `save()` produces all-unchecked `MealSnapshot`, preserves `sourceMealTemplateId`, persists through `replaceMeal`. `DayController.replaceMeal` — today: persists swapped content, id + time survive; **future date: persists the detached day** (repo hit afterward; a subsequent template edit does not alter it); past date: `StateError`; guard rejection surfaces (e.g. item checked between build and save); marking ops still reject non-today dates.
- **Widget** (fake/overridden providers): detail renders 3 day-modes (today full / past read-only / future preview+swap-only tile); edit icon enabled-disabled per status incl. overdue-in-grace blocked; checklist toggles today, inert otherwise; footer CTA label matrix carried from S06.1; SwapSheet lists templates, tap swaps + closes, dangling-only template disabled; editor save gating, tag toggle, remove item, grams sheet re-edit; editor back: pristine pops silently, dirty shows "Discard changes?" (Keep editing stays, Discard pops without write); detach toast shown on first future-day swap/save, NOT shown on today ops or an already-detached day; picker stage 1 → pick → stage 2 presets + preview → Add returns snapshot and draft gains the item; custom-food CTA round-trip (form pops `Food`, grams stage prefilled, draft preserved); intake freeze set on push and cleared after pop.
- Existing `MealSheet` tests migrate to the route screen; S07 library-screen tests adjust to the extracted `FoodLibraryList`.

## Acceptance

- From Today: tap any meal (past/today/future) → detail route with correct mode; mark/skip/snooze flows behave exactly as the S06.1 sheet did.
- Swap an upcoming today-meal from the library — content replaces, slot id + time survive, nothing arrives checked; Today hero animates on return.
- Edit an upcoming meal: rename, retag, remove an item, change grams, add a library ingredient, add a brand-new custom food mid-flow (draft preserved through form round-trip) — save once, detail shows the new content.
- Edit/swap a **future** day's meal → day detaches: visible in repo, subsequent plan-template edit changes other future days but not this one (UC7); the first detaching edit announces itself with the detach toast.
- Abandoning a dirty edit asks "Discard changes?"; a pristine back is silent.
- Done/partial/skipped/overdue meals: Edit + Swap blocked with toast; past days fully read-only.
- All status displays via `mealStatus`; eligibility via `canEditMealContent`/predicates — no hand-rolled checks (review watchpoint).
- `dart format .` clean · `flutter analyze` clean · `flutter test` green · architecture test green.

## Out of scope

Meal-template CRUD + library management (S10/S11) · slot add/delete on day instances (content replace only, architecture §8) · instance time edit · add-item-to-partial (strict v1, S05 edge #25) · notifications incl. swap/edit rescheduling (S14) · oz display units · referenced-food delete policy (S09) · persistent detached-day indicator (parked obligation: week-view/plans era, S09–S13) · "save as template" from the editor (S10/S11) · goldens.

## Skills

`flutter-riverpod-arch` · `flutter-setup-declarative-routing` · `dart-add-unit-test` · `flutter-add-widget-test` · `flutter-add-widget-preview` · `dart-migrate-to-checks-package` · `flutter-expert` (const, semantics on tap targets, form a11y).
