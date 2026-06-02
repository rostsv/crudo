# Crudo — Implementation Roadmap

Build sequence for the v1 MVP. Each row is **one spec** (`docs/specs/`) → **one plan** (`docs/plans/`) → bite-size TDD tasks. Order is a topological sort: every spec's dependencies ship before it.

**Split principle:** pure-logic specs (`[logic]` — freezed + pure functions + controllers, unit-tested, no widgets/backend) are separated from UI specs (`[ui]` — widgets + widget-tests against fake controllers) and ship first, so hard invariants are test-locked before any pixel work.

**Backend:** Supabase, locked (see `architecture.md §1`). Integration deferred — features S05–S18 build against local/in-memory repositories behind a backend-shaped contract; Supabase swaps in at S19–S21.

Status legend: ✅ done · ◻ not started.

## Phase 0 — Foundation

| Spec | Title | Kind | Depends on | Notes |
|---|---|---|---|---|
| ✅ | Design system / theme | ui | — | committed (`8ce6d77`) |
| S01 | App scaffold + config | — | theme | pubspec deps, flavors, `ProviderScope`, `config/` DI, build_runner. Unblocks all. |
| S02 | Domain models + nutrition math | logic | S01 | freezed models + enums; `utils/` calc (`p×4+c×4+f×9`), ±10% validator, day/date helpers. **Also owns codegen setup** (deferred from S01): add `build_runner`/`freezed`/`riverpod_generator`/`json_serializable`, resolve the analyzer/`meta`-pin conflict on Flutter 3.41.9, set the generated-file commit policy. `custom_lint`/`riverpod_lint` stay deferred until they support analyzer ≥10. |
| S03 | Data layer (local repos + seed) | logic | S02 | repos as **async, per-user-scoped** providers; in-memory + bundled seed; `local_food_service`. Backend-shaped contract. |
| S04 | Routing shell + core widgets | ui | S01 | `StatefulShellRoute` 4 tabs, sheet/route infra, shared widgets (PrimaryCta, SelectionCard, Pill, MealCard, MacroRing, SheetScaffold, Toast). |

## Phase 1 — Daily loop

| Spec | Title | Kind | Depends on | Notes |
|---|---|---|---|---|
| S05 | Meal lifecycle engine | logic | S02 | status derivation (all/some/none), partial-kcal, lenient-miss + midnight lock, day-source-of-truth, snooze constraints. |
| S06 | Today screen | ui | S03,S04,S05 | intake card (consumed vs planned), macro bars, streak chip, day-picker, meal list. |

## Phase 2 — Food & meals

| Spec | Title | Kind | Depends on | Notes |
|---|---|---|---|---|
| S07 | Custom food + validation | logic+ui | S02,S03 | ±10% kcal rule, add-custom-food, food library. |
| S08 | Meal editor | ui | S03,S04,S07 | meal detail, add/edit meal, add-ingredient → custom-food callback. |

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
