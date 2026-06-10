# Crudo — Implementation Roadmap

Build sequence for the v1 MVP. Each row is **one spec** (`docs/specs/`) → **one plan** (`docs/plans/`) → bite-size TDD tasks. Order is a topological sort: every spec's dependencies ship before it.

**Split principle:** pure-logic specs (`[logic]` — freezed + pure functions + controllers, unit-tested, no widgets/backend) are separated from UI specs (`[ui]` — widgets + widget-tests against fake controllers) and ship first, so hard invariants are test-locked before any pixel work.

**Backend:** Supabase, locked (see `architecture.md §1`). Integration deferred — features S05–S18 build against local/in-memory repositories behind a backend-shaped contract; Supabase swaps in at S19–S21.

Status legend: ✅ done · ◻ not started.

## Phase 0 — Foundation

| Spec | Title | Kind | Depends on | Notes |
|---|---|---|---|---|
| ✅ | Design system / theme | ui | — | committed (`8ce6d77`) |
| ✅ | App scaffold + config (S01) | — | theme | flavors, `AppConfig`/`appConfigProvider`, `ProviderScope`, themed boot. Done `a41ae20` (iOS Xcode flavor GUI still pending; codegen deferred to S02). |
| ✅ | Domain models + nutrition math (S02) | logic | S01 | Done `b071912`. Pure DDD domain (aggregate modules, VOs, two-tier validation, nutrition service), serialization-free (DTOs → S20, **no json_serializable**); freezed-only codegen (no `meta` conflict — resolved clean); architecture test enforces the dependency rule. Spec: `2026-06-03-s02-*`. `riverpod_generator` → S05+; `custom_lint`/`riverpod_lint` still deferred (analyzer ≥10). |
| ✅ | Data layer (local repos + seed) (S03) | logic | S02 | Done `3d8e0fc`. Repo interfaces in `domain/repositories/` (Futures + watch streams); reactive in-memory impls; 63-product seed (DTO+mapper, no codegen); uuid-v7 `IdGenerator`; DI in `config/di.dart` (S20 swap point). Spec: `2026-06-03-s03-*`. |
| ✅ | Routing shell + core widgets (S04) | ui | S01 | Done `009009f`. 4-tab `StatefulShellRoute` + custom tonal nav; `showCrudoSheet`/`SheetScaffold`/`showCrudoToast`; 7 core widgets (plain params + enums only); showcase placeholders + widget gallery (`lib/previews.dart`). Spec: `2026-06-03-s04-*`. |

## Phase 1 — Daily loop

| Spec | Title | Kind | Depends on | Notes |
|---|---|---|---|---|
| ✅ | Meal lifecycle engine (S05) | logic | S02 | Done `c441cef`. Product→Food rename (`FoodKind`, `kcalPer100g`, no override); instance ladder `Day→ScheduledMeal→MealSnapshot→MealItem→FoodSnapshot` (absolutes baked); Day frozen trio (`adherence`+`thresholdUsed`+`lockedAt`, `DayState` derived); status chain; Day ops + guards; snooze bounds; CoW materialization fns; day kcal. Spec: `2026-06-04-s05-*`; design: `docs/design/domain/2026-06-03-s05-*`. **S05.1** (overdue 5th status + 15-min snooze grace) done `dd42bf6`, spec `2026-06-06-s05-1-*`. |
| ✅ | Today screen (S06) | ui | S03,S04,S05 | Done `a326bbd`. Intake card (consumed vs planned), macro bars, streak chip, day-picker, meal list + marking sheet. **S06.1** refinements (deferred+animated intake, snooze re-base, meal-sheet design parity, card quick-complete `unmarkAll`) done `56a2442`, spec `2026-06-06-s06-1-*`. |

## Phase 2 — Food & meals

| Spec | Title | Kind | Depends on | Notes |
|---|---|---|---|---|
| ✅ | Custom food + validation (S07) | logic+ui | S02,S03 | Done `23ff1b0`. ±10% kcal rule (input-time, no override field), custom-food form (Product\|Dish toggle, category chips, delete+confirm), food library list at `/foods` (search + grouping; reusable for the S08 picker). Spec: `2026-06-06-s07-*`. |
| ✅ | Meal editor (S08) | ui | S03,S04,S07 | Done `1abeecd`. Meal detail route, instance editor (draft → `replaceMeal`), swap-from-library, add-ingredient → custom-food callback, CoW future-day detach. Spec+plan: `2026-06-07-s08-*`. **Swap-sheet refinements** (tag grouping + sticky search) done `0c5047b`, plan `2026-06-08-s08-swap-sheet-refinements.md`. |

## Phase 3 — Plans

| Spec | Title | Kind | Depends on | Notes |
|---|---|---|---|---|
| ✅ | Plan logic + scheduling (S09) | logic | S02,S03 | Done `a49618c`. Pure-domain `plan_scheduling.dart`: cross-plan weekday-conflict detection + steal-override, ≥1-plan delete guard, uncovered-weekday detection, clone plan & meal; `selectPlanForDate` relocated from `meal_lifecycle` w/ export shim. snapshot-on-schedule + template-edits-future-only already shipped (S05/S06/S08). Spec+plan: `2026-06-08-s09-*`. |
| ✅ | Plans list + detail (S10) | ui | S04,S09 | Done `f6088d6` (verified 412 green). Plans tab (derived target, weekday chips, Today badge, Inactive) + pushed `/plans/:id` editor: rename, weekday assign w/ inline conflict + save-time steal-override modal, active pause/resume (days kept dormant), delete w/ ≥1-plan guard, non-blocking uncovered confirm, discard guard. Slots read-only; creation → S11. Spec+plan: `2026-06-08-s10-*`. Review fixes: `canDeletePlan` guard into controller, repo `getAll` slot-resolution (vs autoDispose stream), +9 controller unit tests. |
| ✅ | Meal-template builder (S11a) | ui | S03,S07,S08 | Done `a63fda0` (440 green). Split out of S11 (a brand-new subsystem — S08 only edits day-instances, not library templates). `/meal-templates` list + `/meal-templates/new\|:id` builder (name/tags/ingredients w/ grams, live macros), mirroring the S08 editor retargeted to `MealTemplate`. Ref-safe delete: usage badge + cascade-strip, blocked when it would empty a plan. Picker extracted to pop `(Food, Grams)`. Dev-reachable like `/foods`; not in tab bar (→ S11/S15). Pure-domain `templateUsage`/`stripTemplateFromPlan`. Spec+plan: `2026-06-09-s11a-*`. |
| ✅ | Create-plan flow (S11) | ui | S04,S08,S09,S11a | Done `d8024f0` (471 green). Extends the S10 editor into the unified create/edit surface: editable slots (add via multi-select meal-picker, retime, drag-reorder w/ sorted time-pool, remove), default times (08:00/+3h/cap-23:00), live macro preview, "New plan" CTA, `/plans/new`. `clonePlan`/`cloneMeal` wired as in-memory seeds — persisted only on Save (no orphan dupes). Goal stays profile-level (per-plan selector superseded). Reuses S10 conflict/steal-override/uncovered save flow. Review fix: Duplicate had passed the original, not the clone. Spec+plan: `2026-06-09-s11-*`. |

## Phase 4 — Motivation

| Spec | Title | Kind | Depends on | Notes |
|---|---|---|---|---|
| ✅ | Adherence + streak engine (S12) | logic | S02,S05 | Done `82e00b8` (518 green). Pure `domain/services/adherence.dart`: `dayAdherence` (consumed÷planned kcal, clamped; never `dailyKcalTarget`), `classifyDayState` (green ≥threshold / red <50 / yellow), `lockDay` freeze of the Day trio (idempotent), `frozenDayState` (re-derives from stored `thresholdUsed` → history never recolors on prefs change). `advanceStreak` fold: green +1 / yellow+planned-0 hold / red reset, personalBest high-water, `lastCountedDay` idempotency guard, one-shot milestone events {7,30,100}. `catchUp`: locks every elapsed day (persisted-open locked in place, unopened back-materialized = red = reset, already-locked folded not re-saved), first-run seeds `lastCountedDay`. Thin `StreakCatchUp` controller fires on Today rollover/open + persists (only non-pure code); trigger-wiring + UI → S13. Review caught a spec bug (lock persisted-open in place, not rebuild) + 7 coverage holes pre-merge. Spec+plan: `2026-06-10-s12-*`. |
| ✅ | History + Calendar (S13) | ui | S04,S12 | Done `3fe6fe4` (539 green). Mounts `streakCatchUpProvider` in `AppShell` (always-alive `indexedStack` host) → catch-up now fires at app-open + every midnight/resume rollover and persists; the S12 engine was inert until this wire. History tab: streak hero (current + personalBest + gold flame), Mon-anchored weekly bar (today hatched), 30-day stat grid (adherence%/meals-done/avg-kcal/skipped), last-5-days list. Month `CalendarSheet` (per-day color, today 2px ring, tap-to-detail, kept/partial/missed summary, legend). Gold-flame milestone dialog on crossing {7,30,100} (patterned on S14's `StreakRiskSheet`), shown in order. Pure read layer `history_providers.dart` over `DayRepository.getRange` + `streakRepository` — NO new adherence/streak math; locked days colored by `frozenDayState`, today by live `classifyDayState` (never advances streak); day color = adherence state, never meal-completion ratio. Today wiring: streak chip → History tab, calendar btn → `CalendarSheet`. Review fixed an off-grid 1.5px today-ring border. Spec+plan: `2026-06-10-s13-*`. |

## Phase 5 — System

| Spec | Title | Kind | Depends on | Notes |
|---|---|---|---|---|
| S14 | Notifications | logic+ui | S05,S09 | local scheduling (pre/at/eod/risk), Ate-it/Snooze/Skip actions. |
| S15 | Profile & settings | ui | S03,S12 | units, goal, threshold, notif toggles, subscription status, sign out. |

## Phase 6 — Onboarding

| Spec | Title | Kind | Depends on | Notes |
|---|---|---|---|---|
| S16 | Onboarding — value funnel | ui | S04 | screens 1–6: welcome, pain, demo video, transformation, attribution. |
| S17 | Onboarding — setup builds first plan | ui | S08,S11 | screens 7–10: goal, meal count, timing, reminders → constructs first Plan. |
| S18 | Onboarding — interactive demo | ui | S05,S06 | screen 11: tap-mark sample meal, streak ticks. (12–13 sign-up/verify → S22.) |

## Phase 7 — Backend

| Spec | Title | Kind | Depends on | Notes |
|---|---|---|---|---|
| S19 | Supabase schema + migrations + RLS | — | S02 | no app code; tables, constraints, row-level security. |
| S20 | Supabase repo wiring | logic | S03,S19 | swap in-memory → Supabase behind unchanged repo contract; sync. |
| S21 | Supabase backend jobs | — | S19 | 90-day retention delete, day-7/25 warning emails (Edge Functions / pg_cron). |

## Phase 8 — Auth & monetization

| Spec | Title | Kind | Depends on | Notes |
|---|---|---|---|---|
| S22 | Auth | logic+ui | S20 | email/pass + Apple + Google + 6-digit verify. |
| S23 | Billing integration | logic | S22 | store billing + manager, 7-day trial, entitlement state. |
| S24 | Paywall UI + lock enforcement | ui | S04,S23 | paywall screen, full-lock-on-expiry, progress-based messaging. |

## Phase 9 — Launch

| Spec | Title | Kind | Depends on | Notes |
|---|---|---|---|---|
| S25 | Launch polish | — | all | app icon + splash, full-flow integration tests, retention hooks. |

---

**Critical path:** S01 → S02 → S03/S04 → feature fan-out (S05–S18) → backend (S19–S21) → auth/monetize (S22–S24) → polish (S25).

**Parallelizable once foundation lands:** the logic engines (S05, S07, S09, S12) are independent and can be specced/built in parallel; their UI counterparts follow each.

---

## Parked — post-MVP (not specced)

Ideas captured but deliberately out of v1 scope. Each needs its own spec when picked up.

- **Temporary date-pinned plan override.** A one-off, auto-reverting exception to the recurring weekday schedule: pin a specific date (or short range) to a chosen plan regardless of its weekday — e.g. "use my Travel plan for this Sat+Sun in Paris," then the schedule reverts by itself. New domain concept beyond S09's weekday model: a `date → planId` override that `selectPlanForDate` consults before the weekday match. Entry point is the **day/calendar view** (S06/S13), not the plans list. Distinct from `PlanTemplate.active` (a global, recurring on/off — not date-scoped).
