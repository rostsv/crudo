# S08 Meal Editor — Critical Review

**Reviewer:** Independent (build agent) · **Date:** 2026-06-07  
**Documents reviewed:** `docs/specs/2026-06-07-s08-meal-editor.md`, `docs/plans/2026-06-07-s08-meal-editor.md`

---

## Verdict

**Reconsider parts of the solution, and cut scope aggressively for MVP.** The architecture is sound — careful layering, clean CoW detour, right predicates — but the feature scope is significantly oversized for a pre-MVP app whose core loop (notification → "Ate it" → streak) isn't even fully operational yet. This spec builds a Ferrari (full ingredient-level editor with grams presets, custom-food round-trip, grams re-edit sheets) when what's needed for the first ship is a Honda (detail screen with marking, swap-from-library, minimal editor). The plan's internal coordination risk is high: it depends on S06 and S07, which the roadmap shows as unfinished; and it introduces a cross-feature DayController dependency that will create friction during S09-S11 rework.

---

## Top 5 Concerns

### 1. Feature scope outstrips product maturity

The product is pre-launch, S06 (Today screen) may not be done, S07 (custom food) may not be done, notifications (S14) are 6 specs away, and the core adherent loop isn't hardened. Yet S08 proposes: grams presets (50/100/150/200/250), a custom-food round-trip that creates a Food mid-flow, grams re-edit sheets, gradient macro preview cards, "X OF Y EATEN" progress bars, snooze ineligibility reason strings, and a three-mode (today/future/past) detail screen. The MVP core loop needs the detail screen and swap. The ingredient *editor* (beyond marking) is a luxury until plans (S09-S11) ship and users are actively managing multiple meals.

**Cut:** grams presets, grams re-edit sheet, custom-food round-trip from picker, editor route entirely — ship in v1.1.

### 2. S06/S07 dependency status is unclear and high-risk

The roadmap shows S06 and S07 with no checkmarks. Yet this plan:

- Modifies S07 files (`food_library_screen.dart`, `food_form_screen.dart`, `food_draft_controller.dart`)
- Deletes and replaces S06's MealSheet
- Modifies S06's `today_screen.dart`
- Relies on S06's `DayController`, `intakeFreezeProvider`, `clockProvider`, `todayProvider`
- Reads from S07's `foodRepositoryProvider`, `foodSearchQueryProvider`, `foodLibraryProvider`

If S06 or S07 is partially implemented or being refactored simultaneously, S08 will land with conflicts, broken imports, or behavioral mismatches. **The plan needs an explicit "S06/S07 must be at commit X" baseline, or S08 must build against interfaces (not controller internals) and stub any missing S06/S07 surface.**

### 3. Cross-feature DayController coupling will cause S09-S11 rework

The plan pragmatically accepts that `meals` feature imports `today/view_models/day_controller.dart`. This is the right call for now, but it means:

- When S09-S11 add plan-level operations (template CRUD, schedule rebuild), the DayController will grow
- Meal editing will need to distinguish "save as instance edit" vs "save as template change" — a distinction this spec deliberately ignores (instance-only)
- The `meals` feature will need to refactor away from DayController when plan logic arrives, or DayController becomes a god controller

**The "instance-only" decision locks out template editing.** A user who edits a future-day meal is detaching a *single day*, not fixing their underlying plan. When they later learn they should have edited the plan template instead, their one-off edit is lost — and S09 won't backfill it because the day is already detached.

### 4. Editor "back = silent discard" will cause data loss frustration

The spec says "v1, prototype parity." But this editor involves multi-step interaction: search ingredients → pick → set grams → optionally repeat → adjust quantities. Losing all this work on a back-swipe (or accidental Android back button) is not parity with a good experience — it's a known pain point that every major nutrition app solves with an auto-save draft or discard confirmation. Post-MVP confirm-discard ceremony doesn't help the first 10,000 users who lose their work.

### 5. Future-day CoW detach is architecturally correct but product-questionable

The CoW behavior: first edit on a future day → day snapshot persisted → template edits no longer reach it. This means:

- User edits Monday's lunch (say, changes chicken to fish) → Monday detaches
- User later updates their "Training Day" plan template to add a pre-workout snack → every future training day gets it EXCEPT Monday (the detached one)
- User wonders: "Why doesn't Monday have my pre-workout snack?"

The spec documents this as correct behavior, but it's confusing without UI indication that the day is "detached." No visual indicator is specced. The meal detail screen shows the same layout regardless of whether the day is detached or preview. **If you ship CoW detach, you must also ship a visual indicator** (e.g., "This day has custom edits" pill or icon).

---

## Top 5 Improvements

### 1. Cut the ingredient-level editor from MVP; ship swap-only

The MVP should ship: MealDetailScreen (marking, status display, swap-from-library). No editor route. No grams presets. No custom-food round-trip. This covers:

- The 90% case: "I want to eat a different meal from my library" → swap
- The marking flow: "Ate it" / partial / skip
- Future-day preview with swap capability

Ingredient-level editing (name, tags, items, grams) ships as a separate S08.1 after S09-S11 land and the plan/instance distinction is clearer. Estimate: cuts ~60% of S08 effort.

### 2. Add a "Discard changes?" confirmation if draft has edits

Minimal change: track `isDirty` on MealDraft (compare initial snapshot to current draft). If dirty and back pressed → show a simple confirmation sheet ("Discard changes?" with "Keep editing" / "Discard"). This is a few lines of state and a sheet call. High trust return for low implementation cost.

### 3. Replace the 3-route nest with 2 pushed routes + a sheet for grams

Current plan: `/meal/:date/:mealId` → `/meal/:date/:mealId/edit` → `/meal/:date/:mealId/edit/add-ingredient`. Three route levels. The grams re-edit is ALSO a sheet (GramsSheet), not a route. Simplify:

- `/meal/:date/:mealId` — detail screen (always)
- `/meal/:date/:mealId/edit` — editor (always)
- Add-ingredient pushed from editor via a simple GoRoute at `/meal/:date/:mealId/add-ingredient` (one level, not nested under edit)
- Grams re-edit: keep as sheet (good call)
- Custom food: `/foods/new` (unchanged)

The nesting serves no purpose except semantic grouping and makes route params longer.

### 4. Remove the custom-food round-trip from the picker (ship in S07 or S08.1)

The spec says "the picker enters its grams stage prefilled with it" after custom food creation. This adds complexity:

- `AddIngredientScreen` needs to handle the transition from stage 2 → `/foods/new` → back to stage 2 with a prefilled food
- `FoodFormScreen.save()` needs to return `Food` (S07 retrofit)
- The draft must survive this navigation chain

Simpler: picker has two modes — "Browse library" (stage 1 → stage 2) and "Create custom food" (push `/foods/new`, returned Food pops back to the *editor*, not the picker). User then adds it via "ADD INGREDIENT" again. Yes, it's one extra tap. No, it doesn't justify the custom-food round-trip complexity in v1.

### 5. Stub the S06/S07 surface if not done

Before Task 1 lands, define a single-file dependency contract that lists every external type/function/provider S08 imports from S06 and S07, with a quick `grep` check that each symbol exists. If any are missing, stub them as `// TODO(S06): implement` throw-NotImplementedError or fallback constants. This prevents the cascade failure mode where S08 breaks because S06 changed.

---

## Alternative Approach

**Ship a swap-only detail screen first, defer the editor.**

```
MVE (Minimum Viable Editor) — S08 scope:
├── MealDetailScreen (pushed route, replaces MealSheet)
│   ├── Header with back + meal name + status
│   ├── Macro summary card (kcal + P/C/F)
│   ├── Ingredient checklist (today marking, future/past inert)
│   ├── Action tile: Swap (opens SwapSheet) — today AND future
│   ├── Action tile: Snooze — today only
│   └── Footer: Skip + Mark Done / Save Partial — today only
├── SwapSheet (from meal templates, immediate commit)
├── DayController.replaceMeal (CoW detach on future)
└── Mechanical relocations (Task 4 as-is)
```

**Deferred to S08.1 (after S09-S11 ship):**

- Full ingredient editor (name, tags, items, grams scaling)
- `MealDraft` + `MealDraftController`
- `AddIngredientScreen` with custom-food round-trip
- `GramsEntry` with presets
- Grams re-edit sheet

**Rationale:** The MVP core loop is notification → mark → streak. Meal *swapping* is needed because plans change. Meal *editing* (renaming, retagging, adjusting individual ingredients) is power-user territory that adds complexity, multiplies test surface, and creates architectural coupling before the plan system is built. Shipping the editor later, when templates also exist, lets you add "Save as template" alongside "Save as instance edit."

---

## Missing Questions

| Question | Why it matters |
|---|---|
| Is S06 (Today screen, DayController, MealSheet) at a stable commit? If not, S08's foundation is sand. | Task 2, 4, 9 all modify S06 code. |
| Is S07 (custom food, food library, food form) at a stable commit? Task 5 retrofits S07 files. | Task 5 will fail if S07 doesn't exist or needs different changes. |
| What is the visual indicator for a CoW-detached day? Users need to know "this day won't update with plan changes." | Without it, CoW behavior is invisible and confusing. |
| What happens to an in-progress MealDraft if the user receives a notification and marks the meal as eaten while the editor is open? | The save guard catches one case but the draft state is stale. |
| Does `GramsEntry` handle keyboard dismissal on mobile? A soft keyboard covering the preview is a common UX failure. | The spec specifies `keyboardType: numberWithOptions(decimal: true)` but no dismissal mechanism. |
| What is the plan for `Ref` parameter type in the test router harness? Task 7 needs a test GoRouter. | The existing test infrastructure may not support GoRouter-based widget tests cleanly. |
| How does the editor handle the case where a meal's `sourceMealTemplateId` is null (e.g., it was created ad-hoc, not from a template)? | `MealDraft.toSnapshot()` preserves null, which is fine, but swap flow returning to the detail screen may not show a template reference. |
| Why are the `_ItemRow`, `_CheckCircle`, `_CheckRingPainter`, `_ActionTile` private widgets moved verbatim instead of being extracted as shared components? | If S09-S11 needs the same patterns, they'll be duplicated or need refactoring again. |

---

## Final Recommendation

**Redesign parts of the solution.**

Cut scope: **Task 3 (MealDraft + MealDraftController), Task 7 (AddIngredientScreen + GramsEntry), Task 8 (MealEditorScreen + GramsSheet)** — defer all three to a post-S09/S11 S08.1.

Keep: Tasks 1 (domain functions), 2 (replaceMeal on DayController), 4 (relocations), 5 (S07 retrofits — needed for library list reuse), 6 (SwapSheet), 9 (MealDetailScreen + routes + Today wiring), 10 (gallery + sweep). This preserves the detail screen, swap, CoW detach, and the architectural foundation, while cutting ~55-60% of the implementation surface.

Add: Dirty-state check + discard confirmation on the detail screen's edit icon (even if the editor is deferred).

---

*If the team is committed to the full editor right now:* proceed with minor changes — add the discard confirmation, stub the S06/S07 dependency contract, add a CoW-detach visual indicator, and split Task 9 into 3 subtasks. But the strongest recommendation is to hold the ingredient-level editor for the next iteration.

---

## Summary of Architectural Value (what to keep)

The following work is valuable regardless of scope decisions and should ship:

| Element | Value |
|---|---|
| `mealSnapshotFromTemplate` | Single resolution path, shared by build and swap. Pure win. |
| `FoodSnapshot.scaledTo` | Correct abstraction for grams edits. Pure win. |
| `DayController.replaceMeal` | Required for swap and future editing. Necessary. |
| CoW detach logic in `_applyContent` | Architecturally correct, future-safe. Keep. |
| `SwapSheet` | Directly serves MVP core loop. Keep. |
| `FoodLibraryList` extraction | Reusable component, good separation. Keep. |
| Mechanical relocations (Task 4) | Clean architecture, no behavior change. Keep. |
| MealDetailScreen | Replaces MealSheet stand-in, adds future-day access. Keep. |
