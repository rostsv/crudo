# Spec — S11a: Meal-template builder (library create/edit/delete)

**Status:** approved (design) · **Spec S11a (ui)** · **prerequisite of S11** (create-plan flow). Depends on S03 (`MealTemplateRepository`, `PlanTemplateRepository`, `FoodRepository`, `idGeneratorProvider`), S07 (`FoodLibraryList` picker mode, `FoodFormScreen` save→pop precedent, custom-food CTA), S08 (`meal_editor_screen` shape, `GramsEntry`/`GramsSheet`, two-stage ingredient picker), S02 (`MealTemplate`/`FoodRef`, `mealTemplateMacros`), S09 (`PlanSlot`/`PlanTemplate` reference model).

Scope = the **library MealTemplate builder**: a dev-reachable list of meal templates plus a create/edit form (name, tags, ingredients with grams, live macro preview) and a reference-safe delete. This is the reusable recipe-building surface that **S11's create-plan meal-picker** ("Create new meal · saves to library") and **S17 onboarding** consume. It is split out of S11 because it is an independent, reusable subsystem.

## Goal

Let a user build and maintain reusable meal templates in their library. Create a template from scratch (name + tags + ingredients picked from the food library, each with grams), see its macros compute live, edit an existing template (edits flow to every plan that references it via live derivation), and delete a template without ever leaving a plan in a broken state. The builder owns all widgets + Riverpod wiring; it mirrors the S08 instance editor retargeted from `MealSnapshot` to the library `MealTemplate`.

## Decisions (brainstorm 2026-06-09)

- **Story split.** "Mid-flow add meal" from S11's roadmap row is a brand-new `MealTemplate` builder. No such surface exists (S08 only edits day-instance `MealSnapshot`s). It is specced + built **first**, as its own story; S11 create-plan consumes it in a follow-up. Confirmed via brainstorm fork.
- **Mirror S08, retarget.** The builder is the `meal_editor_screen` shape (name field, tag pills, ingredient list, add-ingredient, live gradient macro preview, discard-guarded back) retargeted: edits a library `MealTemplate` (`foods: List<FoodRef>`), not a day `MealSnapshot` (`items: List<FoodSnapshot>`); persists via `MealTemplateRepository.save`, not `DayController.replaceMeal`.
- **Dev-reachable, mirror S07 `/foods`.** A `MealTemplateLibraryScreen` at `/meal-templates` (+ `/new`, `/:id`), **not yet linked from the tab bar** — permanent placement is decided with S11/S15. Same precedent as the S07 food library. This is the surface S11's in-app picker grows from.
- **Ingredient picker yields `FoodRef`, not `FoodSnapshot`.** `FoodSnapshot.sourceFoodId` is a nullable weak back-ref ("don't rely on it"); `FoodRef.foodId` is required non-null. So the builder's picker must produce `FoodRef(foodId: food.id, grams: g)` directly. The two-stage picker (S07 library list in picker mode + `GramsEntry`) is extracted to yield a `(Food, Grams)` pair; each caller wraps it — S08 into `FoodSnapshot.from`, the builder into `FoodRef`. Reuses `FoodLibraryList`, `GramsEntry`, and the custom-food CTA unchanged.
- **Save → pop(entity).** `save()` returns the persisted `MealTemplate` and the screen `context.pop`s it — the exact `FoodFormScreen`/`food_draft_controller.save()` precedent. This is the integration seam S11's picker will await (`context.push<MealTemplate>('/meal-templates/new')`).
- **Edit propagation is automatic (no sync code).** `MealTemplate` is a live reference: `PlanSlot` holds `mealTemplateId`, and plan macros derive on read via `mealTemplateMacros`. Editing a template's name/tags/foods recomputes every referencing plan's macros instantly. **Already-materialized days (today + past) are frozen S05 snapshots and do NOT change** — only future days reflect the edit (architecture §8, "edits affect future days only"). No new code discharges this; it is inherent to the live-ref + snapshot-on-materialize model.
- **Delete = cascade-strip, blocked when it would empty a plan.** A template referenced by `PlanSlot`s cannot be deleted naively (the slot would dangle → "Unknown meal", kcal 0). Behavior:
  - Compute referencing plans up front; show a **`Used in N plans`** usage indicator on the template (library row + builder header) so impact is always visible — **no silent delete**.
  - **No referencing plan** → simple confirm → `repo.delete`.
  - **Referencing plans, all keep ≥1 slot after removal** → warn-confirm listing the affected plans → delete the template **and** strip its slots from those plans (cascade).
  - **Any referencing plan would drop to 0 slots** (the template is its only meal) → **block**: a warn sheet/toast names those plans ("'X' is the only meal in Rest Day — add another meal or delete that plan first"); nothing is deleted.
  - Rationale: no dangling refs (no S05 materialization risk), no nonsense empty plans. 0-slot plans still exist transiently during S11 creation — we refuse only *emptying-by-delete*, never block legitimate transient empties.
- **No model changes.** `MealTemplate`/`FoodRef`/`PlanSlot`/`PlanTemplate` are final; the builder composes existing aggregates + the existing repos. The only new domain code is a pure usage helper.
- **Goal/time absent (correct per model).** `MealTemplate` is deliberately time-free (`PlanSlot.time` owns *when*) and goal is profile-level — neither appears in the builder. The prototype's per-meal `time` field is superseded by the locked S02 model.

## New domain (pure, `lib/domain/services/plan_scheduling.dart` or sibling)

```dart
/// Which plans reference [templateId], and which of those would be left with
/// zero slots if every slot pointing at [templateId] were removed. Pure; the
/// delete controller turns `wouldEmpty.isNotEmpty` into a hard block and
/// `using` into the cascade-strip set. 0=Mon…6=Sun semantics are irrelevant
/// here — this is reference accounting only.
typedef TemplateUsage = ({
  List<PlanTemplate> using,        // plans with ≥1 slot referencing templateId
  List<PlanTemplate> wouldEmpty,   // subset of `using` left with 0 slots after strip
});

TemplateUsage templateUsage(List<PlanTemplate> plans, String templateId);
```

`stripTemplateFromPlan(PlanTemplate p, String templateId)` (pure) returning the plan with matching slots removed — used by the controller for the cascade write (or inline in the controller; the plan picks the cleaner shape, behavior above is the contract).

## Routes (`lib/routing/app_router.dart`)

Mirror the S07 `/foods` subtree (dev-reachable, over the shell, own back nav):

- `/meal-templates` → `MealTemplateLibraryScreen()`.
  - `new` → `MealTemplateBuilderScreen(templateId: null)`.
    - `add-ingredient` → the shared ingredient picker (pops `FoodRef`).
  - `:id` → `MealTemplateBuilderScreen(templateId: state.pathParameters['id']!)`.
    - `add-ingredient` → shared picker.

(The picker is reachable under both `new/` and `:id/` subtrees, matching how S08 nests `add-ingredient` under `edit`.)

## Screen — Template library (`lib/ui/features/meals/views/meal_template_library_screen.dart`, new)

`ConsumerWidget` mirroring `FoodLibraryScreen`. Reads `mealTemplateRowsProvider` — a sync derived-list provider (mirrors `plansList`: reads `.value` of the underlying stream providers, empty until data arrives).

- **Header** — title "Meals" + a "New" CTA → `context.push('/meal-templates/new')`.
- **Row** (tonal card, tap → `context.push('/meal-templates/${vm.id}')`):
  - Template name (primary).
  - Subtitle `"{kcal} kcal · {tags joined}"` (kcal = `mealTemplateMacros` rounded; tags via `mealTagLabels`).
  - **`Used in N plans`** chip/tag (0 → "Unused"; n → "Used in n plan(s)").
- **Empty state** — centered muted message ("No meals yet"). Loading/error via `AsyncValue`.
- No tab-bar entry (S11/S15 decides placement).

## Screen — Builder (`lib/ui/features/meals/views/meal_template_builder_screen.dart`, new)

`ConsumerStatefulWidget` driven by `MealTemplateDraftController(templateId)`. `templateId == null` → create (blank draft, title "New meal"); else edit (seed from `getById`, title = name). Layout mirrors `meal_editor_screen`:

1. **Header** — back arrow (routed through discard guard) · title · `SAVE` text button (gated on `draft.canSave`). On edit, the header also surfaces the `Used in N plans` indicator.
2. **Name** — `TextField` bound to `draft.name` (`softInputDecoration`, `CrudoText.headline`).
3. **Tags** — `Wrap` of `Pill`s over `MealTag.values`, multi-select, bound to `draft.tags`.
4. **Ingredients** — tonal container: header "Ingredients · N ITEMS"; one `_IngredientRow` per resolved food (name · grams · kcal; tap → edit grams via `GramsSheet`; remove); empty placeholder; "ADD INGREDIENT" → push the picker, on return `addFood(foodRef)`.
5. **Macro preview** — gradient card (primary→primarySoft), live `draft.macros` (kcal + P/C/F), keyed for tests.
6. **Delete** (edit-mode only) — `SecondaryAction`, runs the guarded delete flow below.
7. **Back/discard** — `PopScope`: dirty draft → "Discard changes?" sheet (S08 pattern); pristine pops freely.

`SAVE` → `controller.save()` → `context.pop(savedTemplate)`. (No conflict/uncovered flow — that is plan-level, not here.)

### Delete flow (controller `delete()` + screen)

1. `usage = templateUsage(allPlans, templateId)`.
2. `usage.wouldEmpty` non-empty → **block**: warn sheet/toast naming those plans; no write. Controller returns a `blockedByEmpty` outcome; screen renders the message, stays.
3. Else `usage.using` non-empty → screen shows a **warn-confirm** sheet listing the plans that lose this meal → on confirm, controller deletes the template and persists each stripped plan; pop. Cancel → stay.
4. Else (unused) → simple confirm → delete → pop.

(Spans `MealTemplateRepository` + `PlanTemplateRepository`. Pure decision = `templateUsage`/`stripTemplateFromPlan`; the controller orchestrates the writes. If the implementing plan prefers, the orchestration may live in a thin `application/` use-case — AGENTS.md allows a use-case when logic spans ≥2 repos. Behavior above is the contract either way.)

## Controllers & view-models (`lib/ui/features/meals/view_models/`, `@riverpod`)

```dart
/// One library row — display data resolved up front (macros + usage count).
typedef MealTemplateRowVm = ({
  String id,
  String name,
  List<MealTag> tags,
  int kcal,        // mealTemplateMacros over the template, rounded
  int usedInPlans, // templateUsage(plans, id).using.length
});

/// Library feed: plans + templates + foods (+ implicit goal-free).
@riverpod
List<MealTemplateRowVm> mealTemplateRows(Ref ref); // watches mealTemplatesProvider, foodsProvider, planTemplatesProvider

/// Result of a delete attempt — lets the screen choose block vs warn vs plain.
typedef DeleteOutcome = ({
  bool deleted,                  // a delete actually happened
  bool blockedByEmpty,          // refused: would empty ≥1 plan
  List<PlanTemplate> affected,  // plans that lose this meal (cascade) OR are the blockers
});

@riverpod
class MealTemplateDraftController extends _$MealTemplateDraftController {
  @override
  Future<MealTemplateDraft> build(String? templateId); // null = blank create; else getById (throws StateError if missing)

  void setName(String v);
  void toggleTag(MealTag t);
  void addFood(FoodRef ref);          // appends a picked ingredient
  void removeFood(int index);
  void setGrams(int index, Grams g);  // rescale one ingredient

  /// Persists (new id via idGeneratorProvider on create, else keep id) and
  /// returns the saved template for the caller to pop.
  Future<MealTemplate> save();

  /// Runs the guarded cascade/block. Pure decision via templateUsage; only
  /// performs writes when not blocked and (for cascade) after the screen has
  /// confirmed. Signature/handshake (single call with `confirmed:` flag vs
  /// returning the warn set first) is the plan's call; behavior per Delete flow.
  Future<DeleteOutcome> delete({bool confirmed = false});
}
```

`MealTemplateDraft` (plain immutable VM, `view_models/meal_template_draft.dart`, mirrors `meal_draft.dart`):
- Fields: `name`, `tags: List<MealTag>`, `foods: List<FoodRef>`.
- `factory MealTemplateDraft.from(MealTemplate)`; blank default for create.
- `Macros get macros` — `mealTemplateMacros` over a `toTemplate()` projection, using a foods-by-id map passed in (or resolved by the controller and cached on the draft as resolved `_IngredientRowVm`s: `({String name, Grams grams, int kcal})`, so the widget never touches the repo).
- `bool get canSave` — trimmed name non-empty **and** `foods.isNotEmpty` (the S02 "≥1 item per saved meal" rule).
- `bool isDirtyFrom(MealTemplate)` — name/tags/foods differ (set-equality for tags; ordered for foods).
- Copy helpers: `withName`, `toggleTag`, `addFood`, `removeFood`, `setGrams`.

**Food resolution:** the controller resolves foods one-shot via `ref.read(foodRepositoryProvider).getAll()` in `build` (mirrors `plan_detail_controller` — a stream emit mid-edit must not rebuild and discard the draft; reading an autoDispose stream disposes mid-load). Ingredient-row display (name + kcal) is computed from this map at build/mutation time.

## Widgets

Reuse: `FoodLibraryList` (picker mode), `GramsEntry`, `GramsSheet`, `Pill`, `PrimaryCta`, `SecondaryAction`, `softInputDecoration`, `showCrudoSheet`/`SheetScaffold`, `showCrudoToast`, the gradient-preview + `_IngredientRow` patterns from `meal_editor_screen`, the custom-food CTA from `add_ingredient_screen`. New: the library list-row card, the template builder screen, and the extracted shared ingredient picker. **All dimensions snap to `dimensions.dart` tokens; colors/type from `app.css`. No 1px borders, no drop shadows** (cloud shadow / tonal layering only).

**Shared picker extraction:** factor the two-stage `AddIngredientScreen` so its terminal payload is a `(Food, Grams)` pair (or a callback), with S08's route wrapping into `FoodSnapshot.from` and the builder's route wrapping into `FoodRef`. Keep the change minimal and behavior-preserving for the existing S08 path (its widget tests must stay green).

## Out of scope (explicit)

- **Plan create/edit + meal-picker** → S11.
- **`cloneMeal` / `clonePlan` UI** → S11.
- **Tab-bar / permanent nav placement** for the template library → S11/S15.
- **Soft-archive / undo-delete** → post-MVP.
- **`MealTag` editing semantics, custom tags** → not in MVP.
- **JSON / DTOs** → S20.
- **Notifications** for template changes → n/a.
- **Domain/repository contract changes** — only the pure `templateUsage`/`stripTemplateFromPlan` helpers are added; repos unchanged.

## Tests

**Domain (`package:test`, `package:checks`):**
- `templateUsage` — none referencing → empty `using`/`wouldEmpty`; some referencing with other slots → `using` populated, `wouldEmpty` empty; a plan whose only slot is the template → that plan in both `using` and `wouldEmpty`; multiple plans mixed.
- `stripTemplateFromPlan` — removes only matching slots, preserves order + other fields.

**Controller (`ProviderContainer`, in-memory repos):**
- create: blank build → `canSave` false; after `setName` + `addFood` → true; `save()` mints a new id, persists, returns the template.
- edit: build from existing → draft matches; mutate → `isDirty`; `save()` keeps id, persists changes; referencing plans' derived macros change (assert via `mealTemplateMacros` before/after).
- `addFood`/`removeFood`/`setGrams` mutate `foods` correctly; `macros`/row kcal recompute.
- delete unused → `deleted:true`; cascade (referencing plans keep ≥1 slot) → template gone + those plans stripped, only changed plans written; block (template is a plan's only slot) → `blockedByEmpty:true`, nothing written.
- `mealTemplateRows` emits correct kcal, tags, `usedInPlans`; updates on repo mutation.

**Widget (vs overridden providers / fake controller):**
- Builder renders name/tags/ingredients/preview; tag toggle selects; add-ingredient appends a row; remove drops it; grams edit rescales; macro preview updates live (keyed kcal).
- `SAVE` disabled until name + ≥1 ingredient; save pops the template.
- Discard sheet fires on dirty back, not on pristine.
- Delete: unused → confirm → delete; cascade → warn sheet lists plans → confirm strips; block → warn message names the plan, no delete.
- Library: one row per template, correct subtitle + `Used in N plans`; tap pushes `/meal-templates/:id`; "New" pushes `/meal-templates/new`.
- Shared picker still pops the correct payload for **both** the builder (`FoodRef`) and the existing S08 meal editor (`FoodSnapshot`) — S08 path regression-green.

## Acceptance

- `dart format .` clean · `flutter analyze` clean · `flutter test --timeout=90s` green.
- `/meal-templates` lists every template with derived kcal, tags, and usage count; `/meal-templates/new` and `/meal-templates/:id` create/edit a template with live macros and save→pop.
- Editing a template flows new macros to referencing plans on the next read; already-materialized days are unchanged.
- Delete never produces a dangling slot and never empties a plan: unused/cascade deletes succeed, sole-meal-of-a-plan is blocked with a naming message; usage is always shown before delete.
- No file under `lib/domain/` (beyond the two pure helpers + their tests), `lib/data/`, or `lib/application/` changes contract; repos unchanged. The S08 ingredient-picker path stays green through the shared-picker extraction.
- UI matches `app.css` tokens; every dimension on the 4px grid; no 1px borders or drop shadows.
