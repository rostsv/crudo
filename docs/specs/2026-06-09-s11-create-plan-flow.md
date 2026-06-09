# Spec — S11: Create-plan flow (unified create/edit + meal composition)

**Status:** approved (design) · **Spec S11 (ui)** · depends on **S11a** (`MealTemplateBuilderScreen`/`MealTemplateDraftController`, `mealTemplateRows`, builder `save→pop(MealTemplate)`, picker `({Food food, Grams grams})`), **S10** (`PlanDetailController`/`PlanDraft`/`plan_detail_screen` editor, `PlansScreen` list, `plan_scheduling` conflict/override/uncovered flow), S09 (`clonePlan`/`cloneMeal`, `detectConflicts`/`applyOverride`/`uncoveredWeekdays`/`canDeletePlan`/`selectPlanForDate`), S02 (`PlanTemplate`/`PlanSlot`/`MealTime`, `mealTemplateMacros`).

Scope = the **create-plan flow** plus the convergence S10 deferred: the S10 plan editor becomes the **unified create/edit surface** whose slot section is now editable (add via meal-picker, retime, drag-reorder, remove), with a live macro preview, `clonePlan`/`cloneMeal` duplication, and a "New plan" entry on the `/plans` tab. The existing S10 save flow (conflict → steal-override → uncovered confirm) is reused verbatim and now also persists slots.

## Goal

Let the user build a plan from scratch and fully edit an existing one's meals. From `/plans`, "New plan" opens a blank editor; the user names it, assigns weekdays, and composes its day by adding meal templates from a multi-select picker (or creating/duplicating one inline), each landing as a timed slot. Slots can be retimed and drag-reordered (order and time always agree), with a live daily-target preview. Save runs the same S09-backed integrity flow as S10. Duplicating a plan or a meal seeds a fresh editor in memory — nothing persists until Save, so a cancelled duplicate leaves no orphan.

## Decisions (brainstorm 2026-06-09)

- **Unified create/edit editor (no parallel screen).** `PlanDetailScreen` + `PlanDetailController` + `PlanDraft` become the create *and* edit surface. `build` takes `String? planId` — null = create (blank draft), non-null = edit (today's S10 behavior). This fulfills S10's deferred "reusable create/edit flow".
- **Editable slots.** `PlanDraft`'s read-only `SlotVm` (name/time/kcal) is replaced by an editable `PlanSlotDraft` carrying `{id, mealTemplateId, time}` + resolved display (`mealName`, `kcal`). The plan editor's slot section gains add / retime / drag-reorder / remove. (S10 rendered slots read-only.)
- **Meal-picker = bottom-sheet, multi-select.** `showCrudoSheet` listing library templates (via `mealTemplateRows`) with checkmarks; "Done · N selected" adds each as a slot. A top "Create new meal" CTA pushes the S11a builder; a per-row "Duplicate" runs `cloneMeal`. (Matches `plan-create.jsx`.)
- **Slot time: default on add, adjust in the list, drag = sorted-pool reassignment.** A newly added slot gets a default time — first slot 08:00, each subsequent +3h, capped at 23:00 — assigned sequentially after the current latest slot. Each slot row is tappable to retime. **Drag-reorder keeps the set of times and redistributes them ascending across positions**, so visual order always equals time order (position 1 = earliest). No contradictory order/time state is representable.
- **Live macro preview.** Gradient daily-target card: Σ `mealTemplateMacros` over the draft's slots (kcal + P/C/F), with the uppercase profile-goal label (`Prefs.goal` — never per-plan; the prototype's per-plan goal selector stays superseded).
- **`canSave` = trimmed name non-empty AND ≥1 slot.** A plan can't be Saved empty. (0-slot plans still exist transiently — e.g. an S11a cascade-strip — but Save requires ≥1.)
- **Duplicate = in-memory seed, persisted only on Save (no orphan dupes).** Both editors accept an optional **seed** passed via go_router `extra`; create-mode initializes its draft from the seed when present, else blank. `clonePlan`/`cloneMeal` mint ids up front, but those ids reach the repo only if Save runs. Cancel → nothing written.
  - **clonePlan:** a "Duplicate" secondary action in the editor (edit-mode only, beside Delete) → `clonePlan(current, newId)` in memory → push `/plans/new` seeded with the copy (weekdays cleared by `clonePlan`) → Save persists.
  - **cloneMeal:** a per-row "Duplicate" in the meal-picker → `cloneMeal(template, newId)` in memory → push the S11a builder seeded with the copy → user tweaks → Save persists once and returns it → added as a slot.
- **Save flow unchanged from S10.** `save()` builds `PlanTemplate(slots: [PlanSlot…])` from the draft (create mints plan id + slot ids; edit keeps ids), then runs the existing `detectConflicts` → override-modal → `applyOverride` → `uncoveredWeekdays`-confirm sequence. Only the template construction changes; the conflict/uncovered handshake (`SaveOutcome`) is reused as-is.
- **Edit-propagation is automatic (no code).** Slot edits are `PlanTemplate` edits → future-day materialization reflects them; already-materialized days (today/past) are frozen S05 snapshots (architecture §8). No sync code.
- **Time picker = Material `showTimePicker` (MVP).** Convert `TimeOfDay`↔`MealTime` (`minutesOfDay = hour*60 + minute`). A bespoke design-system time sheet is a post-MVP follow-up (no existing picker to reuse).
- **Builder seed extension (S11a, ours).** `MealTemplateBuilderScreen`/`MealTemplateDraftController` gain an optional in-memory seed (create-mode) so cloneMeal needs no pre-persist. Bounded change to S11a code.

## Routes (`lib/routing/app_router.dart`)

- New `/plans/new` → `PlanDetailScreen(planId: null, seed: state.extra as PlanTemplate?)`.
- Existing `/plans/:id` → `PlanDetailScreen(planId: state.pathParameters['id']!)` (seed null).
- Existing `/meal-templates/new` → also reads `seed: state.extra as MealTemplate?` (cloneMeal path); blank when absent.
- (No new nested routes; the picker is a sheet, not a route. The builder is reached by its existing route, now seedable.)

## List entry (`lib/ui/features/plans/views/plans_screen.dart`)

Add a "New plan" CTA (sticky `PrimaryCta` at the bottom, or a header action — `PrimaryCta` per the design-system "primary CTA = full-width sticky bottom" rule) → `context.push('/plans/new')`. The empty-state gets the same CTA so a user with zero plans can create one. Existing list rows/today-badge/inactive styling unchanged.

## Editor (`lib/ui/features/plans/views/plan_detail_screen.dart`, extend)

`planId` becomes `String?`; an optional `PlanTemplate? seed`. Title: edit → plan name; create → "New plan". On create with a non-null seed, the screen calls `controller.seedFrom(seed)` once (in `initState`).

Sections (S10 layout retained; **slot section now editable**):
1. Header — back (discard-guarded `PopScope`) + title.
2. Name field (`draft.name`).
3. Weekday chips + inline conflict highlight + banner (S10, unchanged — operates on `draft.claimedDays`).
4. Active toggle (S10, unchanged) — **edit-mode only** (a not-yet-created plan is implicitly active; hide the toggle on create, default `active: true`).
5. **Meals (editable):**
   - One row per `draft.slots` (already sorted by time): tappable time chip (→ `showTimePicker` → `setSlotTime`), meal name + derived kcal, drag handle, trailing remove (`removeSlot`). Use a reorderable list; `onReorder` → `reorderSlots(from, to)`.
   - "ADD MEAL" → opens the **meal-picker sheet**.
6. **Macro preview** — gradient card, Σ slot macros + goal label.
7. Save — sticky `PrimaryCta`, gated on `draft.canSave`; runs the S10 save handshake (override modal + uncovered confirm).
8. **Duplicate** (edit-mode only) — `SecondaryAction` beside Delete → `clonePlan` in memory → `context.push('/plans/new', extra: cloned)`.
9. Delete (edit-mode only) — S10 `canDeletePlan`-guarded flow, unchanged.

### Meal-picker sheet (`lib/ui/features/plans/views/meal_picker_sheet.dart`, new)

`showCrudoSheet<MealPickerResult>` where the editor acts on the result.
- Header: "Create new meal" CTA (tonal, mirrors S08's custom-food CTA) → on tap, pop the sheet with a `createNew` intent; the editor then pushes `/meal-templates/new`, awaits the returned `MealTemplate`, and `addSlot`s it.
- List: each `mealTemplateRows` entry as a toggle row (checkmark) showing name · kcal · tags; a per-row "Duplicate" affordance → pop with a `duplicate(templateId)` intent; the editor runs `cloneMeal` in memory and pushes the seeded builder, awaiting the result to `addSlot`.
- Footer: "Done · N selected" → pop with `selected(List<String> templateIds)`; the editor `addSlot`s each.

```dart
/// What the picker sheet returns to the editor (the editor owns navigation,
/// the sheet stays pure). Exactly one variant is non-null.
typedef MealPickerResult = ({
  List<String>? selectedTemplateIds, // "Done" with N checked
  bool createNew,                    // "Create new meal" tapped
  String? duplicateTemplateId,       // a row's "Duplicate" tapped
});
```

## Controllers & view-models (`lib/ui/features/plans/view_models/`)

```dart
// plan_draft.dart — replace SlotVm with an editable slot.
/// One editable plan slot. Display fields (mealName/kcal) are resolved by the
/// controller from the template + food maps; id/mealTemplateId/time persist.
typedef PlanSlotDraft = ({
  String id,
  String mealTemplateId,
  MealTime time,
  String mealName,
  int kcal,
});

class PlanDraft {
  // name, days, active unchanged; slots is now List<PlanSlotDraft>.
  List<int> get claimedDays;           // unchanged
  bool get canSave;                    // name.trim().isNotEmpty && slots.isNotEmpty
  bool isDirtyFrom(PlanTemplate p);    // + slots: compare [id, mealTemplateId, time] in order
  // copy helpers: withName, withActive, toggleDay (unchanged) + slot ops below
  PlanDraft addSlot(PlanSlotDraft s);  // append, then re-sort by time
  PlanDraft removeSlot(int i);
  PlanDraft setSlotTime(int i, MealTime t);   // then re-sort by time
  PlanDraft reorderSlots(int from, int to);   // move, then reassign sorted time-pool to positions
}
```

```dart
// plan_detail_controller.dart
@riverpod
class PlanDetailController extends _$PlanDetailController {
  @override
  Future<PlanDraft> build(String? planId);   // null = blank create; else load (throws if missing)

  // Existing edit ops: setName, toggleDay, setActive.
  // New slot ops (delegate to PlanDraft + resolve display from the template/food maps):
  void addSlot(String mealTemplateId);   // default time: first 08:00, else (latest + 3h) capped 23:00
  void removeSlot(int i);
  void setSlotTime(int i, MealTime t);
  void reorderSlots(int from, int to);

  /// Create-mode seed (in-memory duplicate). Replaces the blank draft once.
  void seedFrom(PlanTemplate src);

  /// Builds PlanTemplate from the draft (create mints plan id + slot ids; edit
  /// keeps ids), then the UNCHANGED S10 conflict/override/uncovered flow.
  Future<SaveOutcome> save({bool override = false});

  Future<bool> delete();   // S10, edit-mode only
}
```

`addSlot` default-time rule: `slots.isEmpty ? MealTime(480) : MealTime(min(latestMinutes + 180, 1380))`. When adding several via "Done", apply sequentially so each lands after the previous. `reorderSlots`: take `slots.map((s)=>s.time)` sorted ascending as a pool; after moving the dragged entry to its new index, zip the pool onto positions in order.

## S11a builder seed (`lib/ui/features/meals/`)

- `MealTemplateBuilderScreen` gains `MealTemplate? seed` (from `/meal-templates/new` `extra`).
- `MealTemplateDraftController` gains `void seedFrom(MealTemplate src)` (create-mode), or `build` initializes from a seed — implementing plan picks the cleaner shape; behavior: create-mode draft initialized from the seed's name/tags/foods; **id minted on Save** as today (cloned ids never pre-persist).

## Widgets

Reuse: S10 `PlanDayChip` + conflict banner + override/uncovered/discard sheets (verbatim), `PrimaryCta`, `SecondaryAction`, `Pill`, `showCrudoSheet`/`SheetScaffold`, `showCrudoToast`, `mealTemplateRows`, the gradient macro-preview pattern (from `meal_template_builder_screen`/S08), `mealTimeLabel`. New: the editable slot row (with drag handle + time chip), the meal-picker sheet. **Dimensions snap to `dimensions.dart`; colors/type from `app.css`; no 1px borders / drop shadows.**

## Out of scope (explicit)

- **Date-pinned temporary plan override** — parked post-MVP (`roadmap.md`).
- **Per-plan goal** — profile-level only.
- **Bespoke design-system time picker** — Material `showTimePicker` for MVP; custom is a follow-up.
- **Tab-bar placement of `/meal-templates`** — S15 candidate (still dev-reachable).
- **Domain/repository changes** — S09 functions + repo contracts are final; S11 composes them. (`clonePlan`/`cloneMeal` now wired.)
- **Notifications** for plan changes → S14.
- **JSON/DTOs** → S20.

## Tests

**View-model / controller (`ProviderContainer`, in-memory repos):**
- `PlanDraft.addSlot` appends + re-sorts by time; default time = 08:00 then +3h capped 23:00; `removeSlot`; `setSlotTime` re-sorts; `reorderSlots` redistributes the sorted time-pool so position order == time order.
- `canSave` false when name blank OR zero slots; true otherwise. `isDirtyFrom` flips on a slot add/remove/retime/reorder.
- `build(null)` → blank draft; `seedFrom(plan)` → draft mirrors the plan (slots resolved). `build(id)` → loads (S10).
- `save()` create → persists a new plan with minted plan id + slot ids, correct slots; no-conflict path writes only self.
- `save()` reuses S10 conflict/override/uncovered exactly (regression: the existing S10 controller tests stay green).
- clonePlan seed: `seedFrom(clonePlan(src))` → name "X copy", days `[]`, slots copied with fresh ids; not persisted until `save()`.

**S11a builder seed:**
- builder seeded with a cloned template → draft shows copied name/tags/foods; Save mints a new id + persists once; cancel persists nothing.

**Widget (overridden providers / fake controller):**
- `/plans` shows "New plan" CTA (incl. empty state) → pushes `/plans/new`.
- Create: blank editor; add meals via picker (multi-select Done) → slot rows appear with default times, sorted; retime a slot → re-sorts; drag-reorder → times reassigned ascending; remove a slot; Save disabled until name + ≥1 slot; Save persists + pops.
- Picker sheet: multi-select + Done returns ids; "Create new meal" routes to builder and the returned template lands as a slot; per-row Duplicate routes to the seeded builder and its result lands as a slot.
- Duplicate plan (edit mode) → opens `/plans/new` seeded; cancelling writes nothing.
- Conflict on Save opens the S10 override modal; uncovered confirm fires (regression of S10 behavior through the unified screen).
- Macro preview reflects Σ slot macros + goal label.
- Discard guard fires on dirty back (incl. slot edits), not when clean.

## Acceptance

- `dart format .` clean · `flutter analyze` clean · `flutter test --timeout=90s` green.
- `/plans` has a working "New plan" CTA; `/plans/new` creates a plan with name + weekdays + composed timed slots; `/plans/:id` edits all of those incl. slot add/retime/reorder/remove.
- Slot order and time never disagree (sorted-pool reassignment); default times follow the 08:00/+3h/cap-23:00 rule.
- `clonePlan` and `cloneMeal` duplicate via in-memory seed; a cancelled duplicate leaves no orphan in any repo.
- Save runs the S09-backed conflict/steal-override + uncovered-confirm flow unchanged; the "≤1 active plan per weekday" invariant cannot be violated via the UI; `canSave` blocks empty/nameless plans.
- No file under `lib/domain/`, `lib/data/`, or `lib/application/` changes contract (UI + routing only; S11a builder seed is UI).
- UI matches `app.css` tokens; every dimension on the 4px grid; no 1px borders / drop shadows.
