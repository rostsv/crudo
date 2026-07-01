# Week-assignment coverage model — design

**Date:** 2026-07-01
**Status:** approved-pending
**Supersedes:** the pause/resume-toggle + conflict-override + coverage-resolution
machinery added earlier this session.

## Problem

Coverage of the 7 weekdays by plans was derived from per-plan `active` toggles +
`days`, and every mutation (pause, delete, editor-save) could open a gap or a
weekday clash. Guarding each surface bred a pile of sheets (resume-conflict,
steal-override, uncovered-advisory, multi-split resolution). Too complex.

## Model

Treat the schedule as what it actually is: **a total assignment of each weekday
(Mon..Sun) to exactly one plan.** No gaps, no overlaps — *by construction*.

- Representation stays `PlanTemplate.days` (0=Mon..6=Sun). The invariant is that
  across all plans the day-sets **partition {0..6}** exactly once.
- **Active is derived, not toggled:** `active == days.isNotEmpty`. A plan holding
  ≥1 day is "scheduled"; a plan holding 0 days is "unused / library-only". The
  `active` field is kept (downstream `selectPlanForDate`/streak read it) but is
  always written as `days.isNotEmpty`.
- There is **no independent pause/resume**, no clash, no gap to repair.

## Core operation

`assignWeekdays(List<int> days, {required String toPlanId})`:
- add `days` to `toPlanId` (union), and
- remove those `days` from whatever plan(s) held them, and
- re-sync `active = days.isNotEmpty` on every touched plan, and
- persist all touched plans.

Single-day reassign is the common case (`assignWeekday(d, toPlanId)`).
`reassignAllAndDelete(fromId, toId)`: move every day of `fromId` to `toId`, then
delete `fromId`.

Because a reassign *moves* a day rather than clearing it, coverage stays total
after every operation. Stealing is implicit and always safe.

## UI surfaces

### Plans tab = THIS WEEK card + Library
- **THIS WEEK** card at top: 7 rows, `Mon — {plan name}` … `Sun — {plan name}`.
  Tap a row → **assign sheet**: list every plan (current owner marked) + "Create
  a plan for this day". Pick another → reassign the day. Create → new-plan editor
  seeded with that day.
- **Library** below: a card per plan (name, kcal + macro dots, a read-only
  weekday strip showing what it covers). Unused plans (0 days) show a muted "Not
  scheduled". No toggle. Tap → viewer.

### Plan editor (`plan_detail_screen`)
Name + meals + macro target only. **Removed:** weekday chips (`REPEATS ON`),
active toggle, `detectConflicts` use, override/uncovered/save-as-paused sheets,
`_ConflictChoice`, `PlanDayChip`, `_EditableWeekStrip`. Save validates name + ≥1
meal (inline errors) and writes. Days are managed only from the Week card.
Create seeded-with-days (from an assign "create") writes those days on save
(reassigned from prior owners).

### Plan viewer (`plan_view_screen`)
Recipe + read-only "covers: {days}". `···`: Edit, Duplicate, Delete.
- **Delete** ("Reassign & delete"): if the plan holds days → sheet "Move its days
  to: [pick one plan]" → `reassignAllAndDelete`. If 0 days → plain confirm delete.
  The plan holding *all* 7 days with no other plan → can't delete (no inheritor).

## Removals

- `PlanActivation` pause/resume/resumeConflicts/daysOrphaned*/assignDays*/
  forceDelete → replaced by `assignWeekdays` + `reassignAllAndDelete`.
- `coverage_resolution_sheet.dart`, the card `CrudoToggle`, the resume-conflict
  sheet, the editor conflict/uncovered sheets.
- Domain `detectConflicts` / `applyOverride` / `canDeletePlan` become unused
  (delete-ability is now "holds 0 days OR has an inheritor"); remove them and
  their tests. `uncoveredWeekdays` / `selectPlanForDate` stay.

## Invariant seam

One writer (`PlanScheduling` controller) owns `assignWeekdays` /
`reassignAllAndDelete`; the partition invariant is enforced there. Views never
mutate `days` directly.

## Testing

- Domain: partition helpers if any; `selectPlanForDate` unchanged.
- Controller (`PlanScheduling`): assign moves a day (old owner loses it, new
  gains it, both `active` synced); assign that empties a plan → it goes inactive;
  reassignAllAndDelete moves all + deletes; can't-delete-last (no inheritor).
- Widgets: THIS WEEK renders 7 rows; tap → assign sheet; picking reassigns.
  Editor no longer shows weekday chips; delete reassign-sheet.
- Rewrite/remove the now-obsolete plan-editor conflict tests, plans_screen toggle
  tests, plan_scheduling conflict/canDelete tests.
