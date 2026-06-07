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
| S08 | Meal editor | ui | S03,S04,S07 | meal detail route, instance editor (draft → `replaceMeal`), swap-from-library, add-ingredient → custom-food callback, CoW future-day detach. Spec+plan: `2026-06-07-s08-*`. |

## Phase 3 — Plans

| Spec | Title | Kind | Depends on | Notes |
|---|---|---|---|---|
| S09 | Plan logic + scheduling | logic | S02,S03 | snapshot-on-schedule, template-edits-future-only, ≥1-plan rule, weekday-conflict detection. |
| S10 | Plans list + detail | ui | S04,S09 | read-only list, detail edit, weekday assign, conflict modal. |
| S11 | Create-plan flow | ui | S04,S08,S09 | name/goal/weekdays/meal-picker, live macro preview, mid-flow add-meal with preserved draft. |

## Phase 4 — Motivation

| Spec | Title | Kind | Depends on | Notes |
|---|---|---|---|---|
| S12 | Adherence + streak engine | logic | S02,S05 | 3-state day, threshold, +1/hold/reset, personal best, milestones. |
| S13 | History + Calendar | ui | S04,S12 | streak card, weekly bar, per-day breakdown, calendar sheet. |

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
