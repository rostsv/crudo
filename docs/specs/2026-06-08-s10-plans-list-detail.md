# Spec — S10: Plans list + detail

**Status:** approved (design) · **Spec S10 (ui)** · depends on S04 (shell, `showCrudoSheet`/`SheetScaffold`, core widgets, `todayProvider`), S09 (`detectConflicts`/`applyOverride`/`canDeletePlan`/`uncoveredWeekdays`/`selectPlanForDate` in `plan_scheduling.dart`), S03 (`PlanTemplateRepository`, `MealTemplateRepository`, `FoodRepository`, `ProfileRepository`), S02 (`PlanTemplate`/`PlanSlot`, `mealTemplateMacros`). Scope = the `/plans` tab (browse) + a pushed plan **detail/edit** screen (name, weekday assignment with steal-override, active pause/resume, delete). **All meal-slot editing and all plan creation are deferred to S11.**

## Goal

Make the recurring weekday schedule visible and editable. The user can see every plan, which weekdays each claims, which one runs today, and its derived target; open a plan to rename it, reassign its weekdays (resolving cross-plan conflicts by stealing), pause/resume it, or delete it (never the last one). This is the read-and-tune surface over the S09 integrity rules — S10 owns all widgets + Riverpod wiring and must not be able to violate a single S09 invariant.

## Decisions (brainstorm 2026-06-08)

- **S10 = recurring-weekday management only.** Browse + edit-existing + delete. No creation path (neither blank-create nor `clonePlan`) — both belong to S11's create flow. The `/plans` tab has **no "New plan" CTA in S10**; it appears with S11.
- **Meal slots are read-only.** Detail shows the plan's slots (time · meal name · kcal) but offers no add/remove/retime/reorder. Slot composition is S11's reusable create/edit flow. No "Edit meals" affordance is rendered in S10 (it would be a dead route until S11).
- **Conflict UX = inline highlight + save-time steal modal** (matches `plan-create.jsx`). Weekday chips that collide with another active plan get a live error outline as the user toggles, with an inline warning banner naming the overlaps. On **Save**, if conflicts remain, a confirm modal lists exactly what each other plan loses → **Override** (steal) or **Cancel**. Override is S09's `applyOverride` (strip the stolen weekdays from the other active plans).
- **`active` = pause/resume a plan.** Inactive = dormant: claims no weekday (`selectPlanForDate` already gates on `p.active`), so its weekdays materialize empty days unless another active plan covers them; still listed (muted + "Inactive" tag); still counts toward `canDeletePlan`. S09's `detectConflicts`/`applyOverride`/`uncoveredWeekdays` already ignore inactive plans.
- **Deactivate keeps `days` dormant.** Toggling `active` off retains the weekday set; reactivating restores the schedule. The unifying rule: a plan claims `claimedDays = active ? days : const []`. Both the inline conflict highlight and the save-time `detectConflicts`/`applyOverride` operate on `claimedDays` — so reactivating into a weekday another plan grabbed while it was paused fires the same steal-override modal. The invariant "≤1 active plan per weekday" stays airtight.
- **Uncovered-weekday warning is non-blocking, on save.** After a save (or override) that leaves any weekday with no active plan, show a confirm — `uncoveredWeekdays` supplies the list ("Mon, Thu have no plan — save anyway?", Save/Cancel). Never a hard block (gaps are allowed — they materialize empty days). Deactivating a plan that covered days naturally triggers this.
- **Discard guard on unsaved edits.** Leaving detail with a dirty draft (name/days/active differ from the persisted plan) shows the same discard confirm as S08's meal editor (`PopScope`).
- **Delete guarded by `canDeletePlan`.** The destructive action is disabled (with an explanatory toast on tap) when only one plan exists; otherwise a confirm dialog → `repo.delete` → pop.
- **Derived target tag, never stored.** Each list row shows `"{GOAL} · {kcal} KCAL · {n} meals"`: goal from `Prefs.goal` (profile-level — the prototype's per-plan goal selector is **superseded** by the locked S02 model), kcal = Σ `mealTemplateMacros(template, foodsById)` over the plan's slots, n = slot count.
- **Today marker.** The plan returned by `selectPlanForDate(plans, today)` (today via `todayProvider`) gets a "Today" badge in the list. `null` (uncovered weekday) → no badge on any row.
- **Temporary date-pinned override is OUT.** The "use a different plan for this weekend, auto-revert" use case is parked post-MVP (`roadmap.md` → Parked). It is a distinct date-scoped concept that does not touch S10.

## Routes (`lib/routing/app_router.dart`)

- `/plans` tab branch — replace the placeholder `PlansScreen` body with the real list.
- New pushed route `/plans/:id` → `PlanDetailScreen(planId: state.pathParameters['id']!)`, a sibling of the existing `/meal/...` pushed routes (over the shell, own back nav). No nested child routes in S10.

## Screen — Plans list (`lib/ui/features/plans/views/plans_screen.dart`, rewrite)

`ConsumerWidget` reading `plansListProvider` (`AsyncValue<List<PlanRowVm>>`).

- **Row** (one tonal card per plan, `SelectionCard`-style, full-width, tap → `context.push('/plans/${vm.id}')`):
  - Plan name (primary).
  - Derived subtitle `"{GOAL} · {kcal} KCAL · {n} meals"` (uppercase goal label; `n meal`/`n meals`).
  - Weekday chip row M T W T F S S — claimed weekdays filled, others muted (reuse `Pill` or a compact chip; **0=Mon … 6=Sun**).
  - "Today" badge when `vm.isToday`.
  - Inactive plan: muted styling + "Inactive" tag; weekday chips reflect its retained (dormant) `days`.
- **No "New plan" CTA** (S11).
- **Empty state** (defensive — post-onboarding there is always ≥1 plan; dev seeds plans): a centered muted message. Loading/error via `AsyncValue` (spinner / error text).

## Screen — Plan detail / edit (`lib/ui/features/plans/views/plan_detail_screen.dart`, new)

`ConsumerWidget` driven by `PlanDetailController(planId)`. Holds a local **draft** of the editable fields only (`name`, `days`, `active`); slots are immutable and shown read-only.

Layout (hand-rolled back-header matching `meal_detail_screen.dart` — back arrow + title; no shared `ScreenHeader` widget exists):

1. **Header** — back arrow (`context.pop`, routed through the discard guard) + title.
2. **Name** — text field bound to `draft.name`.
3. **Repeats on** — 7 weekday toggle chips bound to `draft.days`. A chip is flagged (error outline) when its weekday is in `detectConflicts(otherPlans, forPlanId: id, proposedDays: claimedDays)` where `claimedDays = draft.active ? draft.days : const []`. Inline warning banner (error-soft) lists overlaps ("Wed overlaps Rest Day"). When `draft.active == false`, no chip is flagged (claims nothing) though the days remain visible/toggleable.
4. **Active** — toggle switch bound to `draft.active` ("Active" / "Paused").
5. **Meals** — read-only slot list: each row time · meal-template name · derived kcal/first tag. No edit affordance.
6. **Save** — sticky `PrimaryCta` (gated: non-blank trimmed name + valid days per existing per-plan validators). Runs the save flow below.
7. **Delete** — destructive action (tonal/secondary), guarded by `canDeletePlan`.

### Save flow (controller `save()`)

Let `claimedDays = draft.active ? draft.days : const []`, `others = allPlans where id != planId`.

1. `conflicts = detectConflicts(allPlans, forPlanId: planId, proposedDays: claimedDays)`.
2. If `conflicts` non-empty → caller shows the **Override modal** (lists, per other plan, the weekdays it loses). **Cancel** → abort (stay, draft intact). **Override** → continue with stealing.
3. Build `updatedSelf = current.copyWith(name: draft.name.trim(), days: draft.days, active: draft.active)` — note **self keeps `draft.days` verbatim** (dormant days preserved even when inactive); `applyOverride` is used only to compute the **other** plans to strip.
4. `strippedOthers = applyOverride(allPlans, forPlanId: planId, proposedDays: claimedDays)` then drop any entry whose id == planId. Persist each `strippedOthers` via `repo.save`, then persist `updatedSelf`.
5. Compute `uncoveredWeekdays(plansAfterSave)`; if non-empty → caller shows the **non-blocking uncovered confirm** before popping (Save anyway / Cancel-stay). On confirm → pop; the writes already landed (the warning is advisory only).

### Delete flow (controller `delete()`)

`canDeletePlan(allPlans)` false → no-op + warn toast ("Can't delete your only plan"). True → confirm dialog → `repo.delete(planId)` → pop. (Already-materialized day snapshots are detached — repo contract.)

### Discard guard

`PopScope`: if `draft` differs from the persisted plan, intercept back/pop with a discard confirm (Leave / Stay) — S08 pattern. Clean draft pops freely.

## Controllers & view-models (`lib/ui/features/plans/view_models/`, `@riverpod`)

```dart
/// One row of the plans list — all display data resolved up front.
typedef PlanRowVm = ({
  String id,
  String name,
  List<int> days,   // 0=Mon…6=Sun, the plan's (dormant-inclusive) weekdays
  int kcal,         // Σ mealTemplateMacros over slots, rounded
  int mealCount,    // slot count
  bool active,
  bool isToday,     // this == selectPlanForDate(plans, today)
});

/// List feed: combines plans + meal templates + foods + profile goal + today.
/// Rebuilds on any of those streams.
@riverpod
class PlansList extends _$PlansList {
  @override
  Stream<List<PlanRowVm>> build();   // watches planTemplateRepository.watchAll() (+ templates, foods, profile, todayProvider)
}

/// Detail/edit controller. Seeds a PlanDraft from repo.getById(planId).
@riverpod
class PlanDetailController extends _$PlanDetailController {
  @override
  Future<PlanDraft> build(String planId);   // throws StateError if no such plan

  void setName(String v);
  void toggleDay(int weekday);   // 0..6, add/remove from draft.days
  void setActive(bool v);

  /// claimedDays = draft.active ? draft.days : const [].
  List<WeekdayConflict> currentConflicts(List<PlanTemplate> allPlans);

  /// Persists self (+ stolen others when [override]). Returns the post-save
  /// uncovered weekdays so the view can show the advisory confirm.
  /// Throws ConflictsPending (with the conflict list) when conflicts exist and
  /// [override] is false — the view then shows the Override modal and retries
  /// with override: true.
  Future<List<int>> save({bool override = false});

  Future<void> delete();   // no-op (caller toasts) when !canDeletePlan
}
```

`PlanDraft` (plain immutable view-model class, `view_models/plan_draft.dart`): `name`, `days`, `active`, plus the read-only resolved `slots` display data (time + meal name + kcal); `isDirty(PlanTemplate persisted)`; `canSave` (trimmed name non-empty). Mirrors the `food_draft.dart` / `meal_draft.dart` precedent. Conflict surfacing between view and controller may be done by passing `allPlans` into `currentConflicts`/`save` (read from the list provider) rather than a sentinel exception — the implementing plan picks the cleaner shape; behavior above is the contract.

## Widgets

Reuse: `SelectionCard`, `Pill`, `PrimaryCta`, `SecondaryAction`, `showCrudoSheet`/`SheetScaffold`, `showCrudoToast`. New (in `lib/ui/features/plans/views/` or `core/widgets/` if reused): a plan list-row card and a weekday-chip row. **All dimensions snap to `dimensions.dart` tokens — never copy raw px from `plan-create.jsx`** (design-system rule). Colors/type from `app.css` tokens. No 1px borders, no drop shadows.

## Out of scope (explicit)

- **Any plan creation** — blank-create and `clonePlan`/`cloneMeal` UI → S11.
- **Any meal-slot editing** (add/remove/retime/reorder) → S11's create/edit flow.
- **Temporary date-pinned plan override** → parked post-MVP (`roadmap.md`).
- **Notifications** for plan changes → S14.
- **Per-plan goal** — goal is profile-level (`Prefs.goal`); no goal field on `PlanTemplate`.
- **Domain / repository changes** — S09 functions and repo contracts are final; S10 only composes them.
- New routing for slot editing or creation.

## Tests

**Controller (`ProviderContainer`, fake/in-memory repos):**
- `PlansList` emits rows with correct kcal (Σ `mealTemplateMacros`), mealCount, goal-derived data, and `isToday` exactly on `selectPlanForDate(plans, today)`; updates on repo mutation.
- `PlanDetailController.save` with no conflict → persists only self with new name/days/active.
- `save` with conflict and `override: false` → does not persist, signals pending conflicts (exception or returned conflict list).
- `save` with `override: true` → stolen weekdays stripped from the other active plan(s); self persisted with name/days/active; only changed plans written.
- Inactive draft (`active: false`) → `claimedDays == []` → no conflicts even when `days` overlap another active plan; self persisted keeping `days` dormant.
- Reactivate (draft.active false→true) into an overlapping weekday → conflict surfaces.
- `save` returns the post-save uncovered weekdays (non-empty when a gap results).
- `delete` no-op when `canDeletePlan` false (single plan); deletes when >1.

**Widget (vs fake controller / overridden providers):**
- List renders one row per plan; correct subtitle, weekday chips, "Today" badge on the covering plan; inactive plan muted + "Inactive" tag.
- Tapping a row pushes `/plans/:id`.
- Detail: toggling a conflicting weekday shows the inline error outline + warning banner; toggling `active` off clears the inline highlight while keeping chips set.
- Save with conflict opens the Override modal; confirming triggers the stealing save; cancelling leaves state unchanged.
- Post-save gap → uncovered confirm shown.
- Delete disabled + warn toast when only one plan; confirm dialog otherwise.
- Discard confirm fires when leaving a dirty draft; not when clean.

## Acceptance

- `dart format .` clean · `flutter analyze` clean · `flutter test --timeout=90s` green.
- `/plans` lists every plan with derived target, weekday chips, and the today marker; `/plans/:id` edits name + weekdays + active and deletes, all guarded by the S09 functions.
- Steal-override, ≥1-plan delete guard, and non-blocking uncovered warning all behave per the flows above; the "≤1 active plan per weekday" invariant cannot be violated through the UI.
- No file under `lib/domain/`, `lib/data/`, or `lib/application/` is modified (UI + routing only).
- UI matches `app.css` tokens; every dimension on the 4px grid.
