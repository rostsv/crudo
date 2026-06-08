# Crudo — Architecture

How Crudo is built. This is the technical companion to `product.md` (what & why) and `design_system.md` (visual language).

> **Status:** pre-implementation. `lib/main.dart` is still the default Flutter counter template — no product code exists yet. This document defines the intended architecture and the canonical domain model; sections marked **(decision pending)** are not yet locked.

---

## 1. Stack

Conventions and tooling below are **set by the project skills** in `.agents/skills/` (Dart/Flutter agent skills). Follow the matching skill when doing that kind of work.

- **Flutter / Dart** (SDK `^3.11.5`). Mobile-first, target frame 390 × 844.
- **Fonts:** Manrope (bundle as an app font; see `design_system.md`).
- **State management:** **Riverpod 3.x** (annotation-based: `@riverpod`, `Notifier`, `AsyncNotifier`). App wrapped in `ProviderScope` at the root. Controllers hold all business logic; widgets are `ConsumerWidget`s that `ref.watch` state and `ref.read` methods. **DI is via Riverpod providers** (`Provider` for repository instances — no separate `get_it`/`provider`). Deps: `flutter_riverpod`, `riverpod_annotation`, `riverpod_generator`, `riverpod_lint`, `build_runner`. **Phasing (2026-06-02):** S01 installs `flutter_riverpod` only (plain `Provider`); the **codegen toolchain** (`build_runner`, `riverpod_generator`/`riverpod_annotation`, `freezed`, `json_serializable`) is added in **S02** with the first freezed model — on Flutter 3.41.9 it requires resolving an analyzer/`meta`-pin conflict. **`custom_lint`/`riverpod_lint` are deferred** (custom_lint caps `analyzer ^8`, incompatible with the Riverpod-3.x/analyzer-10+ stack); lint = `flutter_lints` + `@review` until custom_lint catches up. (skills: `flutter-riverpod-arch`, `flutter-apply-architecture-best-practices`)
- **Routing:** `go_router` with `StatefulShellRoute.indexedStack` for the persistent 4-tab bottom nav; `usePathUrlStrategy()`. (skill: `flutter-setup-declarative-routing`)
- **Domain models:** immutable `freezed` types, **serialization-free** (no `fromJson`/`toJson` in `domain/` — decision 2026-06-03). Wire shapes live as DTOs + mappers in `data/` from S20 (skill: `flutter-implement-json-serialization` applies to DTOs). Domain imports no Flutter/Riverpod/Supabase.
- **Testing:** unit with `package:test`; widgets with `WidgetTester` (`flutter_test`); flows with `integration_test`; mocks via `package:mockito` + `build_runner`. Assertions use **`package:checks`** (not `package:matcher`). Coverage via the `coverage` package → LCOV. (skills: `dart-add-unit-test`, `flutter-add-widget-test`, `flutter-add-integration-test`, `dart-generate-test-mocks`, `dart-migrate-to-checks-package`, `dart-collect-coverage`)
- **Quality:** `dart analyze` + `dart fix --apply`; prefer switch-expressions/pattern-matching. (skills: `dart-run-static-analysis`, `dart-use-pattern-matching`)
- **UI previews:** `previews.dart` widget-preview system for components. (skill: `flutter-add-widget-preview`)
- **Localization:** `flutter_localizations` + `intl`, `generate: true`, `l10n.yaml` — infrastructure only; in-app language switching is post-MVP. (skill: `flutter-setup-localization`)
- **Networking:** `http` package if the backend is REST. (skill: `flutter-use-http-package`)
- **Backend / auth:** **Supabase (locked).** Chosen over Firebase for the relational fit (foods ← meals ← plans, immutable day snapshots, kcal aggregation for adherence), Row-Level Security per-user isolation, and Edge Functions + pg_cron for the 90-day retention/deletion job and day-7/25 warning emails. `supabase_flutter` SDK. Drives email+password + social auth (Google, Apple), data sync, and backend jobs. The vendor SDK replaces the raw `http` service. **Integration is deferred:** features build against local/in-memory repositories first (steps 3–12 of the roadmap); the backend swaps in behind the unchanged repository contract (all repo methods `async`, per-user scoped, returning domain models). Firebase's standout edges (FCM push, built-in analytics/Crashlytics) don't apply in v1 — Crudo uses **local** notifications.
- **Local notifications:** platform scheduling (e.g. `flutter_local_notifications`) for the meal reminder system — **(decision pending on package)**.
- **Payments:** subscription/paywall via store billing + a manager (e.g. RevenueCat) — **(decision pending)**.
- **App icons & splash:** still the Flutter defaults. **TODO before launch:** replace via `flutter_launcher_icons` + `flutter_native_splash` from a 1024×1024 brand logo (teal `#004d49`); do not hand-delete the default assets.

Build/lint/test commands live in `CLAUDE.md`. The full skill catalog is listed in §12.

---

## 2. Project structure

**"Riverpod MVVM + shared DDD core" (locked 2026-06-03):** hybrid layout — UI grouped by feature, **domain/data shared and grouped by type** — per the Flutter Compass case study, with **Riverpod** as state layer + DI, and **DDD tactical patterns inside the domain** (aggregate modules, value objects, self-validation, domain services, repository interfaces). Single bounded context — the domain is cohesive and shared; no per-feature domain. Dependencies flow one direction only:

```
View (ConsumerWidget) → Controller (Notifier/AsyncNotifier) → Repository (interface) → data Service
ui → application (emergent use-cases) → domain ← data (implements domain's repo interfaces)
domain depends on NOTHING (no Flutter / Riverpod / JSON / Supabase imports)
utils = generic technical helpers only — never business rules
```

Spring mapping (for orientation): Notifier ≈ `@Service` entry point, Repository ≈ `@Repository`, data service ≈ the `EntityManager`/`WebClient`-level client. Rules live on **aggregates** (rich domain), not in fat services.

> **Reconciling the two architecture skills.** They disagree on folders (`flutter-riverpod-arch` wants `lib/features/<f>/{application,presentation,infrastructure}`). We keep the **layer-first** structure (official Flutter guide + the practices skill) because Crudo's repositories are shared across many features, and adopt **Riverpod** for state. Mapping: the riverpod skill's `application/` → our `view_models/`, `presentation/` → our `views/`, `infrastructure/` → our central `data/`. Where the two conflict, **layout follows the practices skill; state-management patterns follow the riverpod skill.**

- **UI layer** (`ui/`) — per-feature `views/` (`ConsumerWidget`s; UI-only logic; `ref.watch` for state, `ref.read` for actions; handle `AsyncValue` loading/error/data) + `view_models/` (Riverpod `Notifier`/`AsyncNotifier` controllers **and** their providers; all business logic lives here). Shared widgets/themes in `ui/core/`. One screen ≈ one View + one controller.
- **Domain layer** (`domain/`) — `models/` are clean immutable domain types (freezed) shared across layers (§4). Add `domain/use_cases/` only when logic spans multiple repositories or is reused — not preemptively.
- **Data layer** (`data/`) — `repositories/` are the single source of truth per data type (caching, offline sync, retries; transform API → domain models), exposed as Riverpod `Provider`s; `services/` are stateless wrappers over one source each (backend SDK/HTTP, local notifications, bundled assets); `models/` holds raw API/DTO shapes (separate from domain models).

Rules (from both skills): Views never call Services or repositories directly — only controllers via `ref`. Controllers read repos with `ref.read`; never put HTTP/Supabase calls in widgets. Wrap async work in `AsyncValue.guard`; use `.select` for fine-grained rebuilds. Repositories never depend on each other. Keep navigation out of providers (use routing helpers / UI callbacks). Don't mix Riverpod with `setState` for the same state; avoid deprecated 2.x `StateNotifierProvider` for new code.

### Folder tree (scaffolded in `lib/`)

```
lib/
├── main.dart                      # + main_development.dart / main_staging.dart per flavor
├── config/                        # env config, flavors, DI wiring, API keys (indirection)
├── routing/                       # go_router: StatefulShellRoute (4 tabs) + pushed routes + sheets (see §5)
├── utils/                         # GENERIC technical helpers only (calendar math) — no business rules
├── domain/                        # PURE Dart: no Flutter/Riverpod/JSON/Supabase (S02 spec is canonical)
│   ├── product/  meal/  plan/     # aggregate modules: entities + (later) behavior methods
│   ├── day/  profile/  streak/    #   templates: Product, ProductRef, MealTemplate, PlanSlot, PlanTemplate
│   │                              #   instances (detached snapshots): Day, Meal, MealProduct
│   ├── shared/                    # value objects (MealTime, Macros, Grams) + enums
│   ├── services/                  # domain services (pure): nutrition; later meal_status (S05), adherence (S12)
│   ├── validation/                # ValidationIssue + validate() extensions (two-tier with @Assert)
│   └── repositories/              # ABSTRACT repo interfaces (defined in S03)
├── application/                   # use-cases — EMERGENT only (logic spanning ≥2 repos); else controllers
├── data/                          # implements domain contracts
│   ├── repositories/              # impls: in-memory (S03) → Supabase (S20), per-user scoped
│   ├── services/                  # one wrapper per external system: seed (S03), database (S20),
│   │                              # notification (S14), auth (S22), billing (S23)
│   ├── dto/                       # wire shapes (seed DTO S03; Supabase DTOs S20)
│   └── mappers/                   # dto ↔ domain
└── ui/
    ├── core/
    │   ├── themes/                # colors, typography, dimensions, shadows from app.css
    │   └── widgets/               # shared: PrimaryCta, SelectionCard, Pill, MealCard,
    │                              # MacroRing, SheetScaffold, Toast, …
    └── features/
        ├── onboarding/{view_models,views}/   # 13-screen flow
        ├── auth/{view_models,views}/         # sign in / sign up / verify
        ├── today/{view_models,views}/        # Today + Calendar sheet
        ├── meals/{view_models,views}/        # meal detail, add/edit meal, add ingredient,
        │                                      # custom food, snooze/swap sheets
        ├── plans/{view_models,views}/        # plans list, plan detail, create plan, conflict
        ├── history/{view_models,views}/
        ├── profile/{view_models,views}/      # settings, reminders sheet
        └── paywall/{view_models,views}/
```

Tests mirror the layers: `test/{data,domain,ui,utils}/`. Shared mocks/fakes live in the `testing/{fakes,models}/` subpackage (not shipped). Controllers are tested with a `ProviderContainer`, overriding repository providers with fakes/mocks; widget tests assert the loading/error/data branches. File naming: `*_screen.dart` (Views/`ConsumerWidget`s), `*_controller.dart` + `providers.dart` (Riverpod, in `view_models/`), `*_repository.dart`, `*_service.dart`; models as plain names (e.g. `meal.dart`). Generated codegen files are `*.g.dart` (from `build_runner`).

> Folders are currently empty placeholders (`.gitkeep`). The prototype's single app-store maps onto these repositories — e.g. its `meals`/`foods`/`plans`/`prefs` collections become `MealRepository` / `FoodRepository` / `PlanRepository` / `ProfileRepository`.

---

## 3. Canonical sources

1. **`docs/design/prototype/`** — exported React/HTML prototype from Claude Design. The **pixel-perfect visual + interaction target**. Recreate it in Flutter; match the visual output, do **not** port the JSX structure.
   - `app.css` — locked design tokens (authoritative styling values).
   - `app.jsx` — app shell, routing, and the **seed data model** (foods/meals/plans/prefs) this document is derived from.
   - `primitives.jsx` — shared widgets + `seedFoods` + the `mealMacros` calculation.
   - `screens/*.jsx` — every screen and sheet.
   - `design-chat.md` — the design conversation (the *why* behind decisions).
2. **`docs/design/mock/onboarding/`** — PNG mockups.

---

## 4. Domain model

> **Canonical type catalog: `docs/specs/2026-06-03-s02-domain-models-nutrition.md`** (redesigned 2026-06-03; supersedes the prototype-seed shapes that used to live here). Diagrams: `docs/design/domain/2026-06-02-s02-domain-diagrams.md`.

Quantities in **grams** (`Grams` VO, displayed g/oz per pref); macros **per 100 g** (double). IDs = app-generated **uuid v7 strings**. Instants stored **UTC**; day key = the user's **local calendar date** encoded `DateTime.utc(y,m,d)`; midnight-lock at local 00:00.

**Two trees:**

- **Template tree (the factory; edits affect future only):**
  `PlanTemplate { name, days[0=Mon…6=Sun], active, slots }` → `PlanSlot { mealTemplateId, time: MealTime }` → `MealTemplate { name, tags, products }` (time-free, reusable) → `ProductRef { productId, grams }` → `Product { name, category, p/c/f per-100g, kcalOverride?, isCustom }`.
- **Instance tree (detached self-contained snapshots — snapshot-on-schedule, §8):**
  `Day { date, sourcePlanId?, planName?, meals, adherence?, state? }` → `Meal { id (slot-stable — notifications key off it), time, sourceMealTemplateId?, name, tags, products }` → `MealProduct { sourceProductId?, name, category, p/c/f, kcalOverride?, grams, checked }`.
  Each day/meal/product is individually editable without touching templates or other days. `source*Id` = weak back-refs only (no integrity dependency). One `Day` type serves today/future/history; `adherence` + `state` (green/yellow/red) are null while open, **frozen at midnight-lock**.

**Derived, never stored:** `MealStatus` (from checked flags + time — S05), all macro totals (`Macros` VO — §6), plan display tag (profile goal + Σ planned kcal).

**Profile:** `UserProfile { id, displayName?, prefs }` · `Prefs { goal, units, dailyKcalTarget? (guidance only — never the adherence denominator), streakThreshold (70/80/90/100, default 80), reminderMode, preOn/atOn/eodOn/riskOn, preMin }` · `Streak { current, personalBest, lastCountedDay? }`.

**Validation is two-tier, in domain:** `@Assert` invariants (impossible states; debug) + `validate() → List<ValidationIssue>` (user-facing save rules, code enum for i18n). Notable rules: kcal override within **±10 %** of calculated; `p+c+f ≤ 100`/100g (±1 g); ≥1 product per saved meal; ≥1 slot per active plan.

---

## 5. App state & navigation map

The prototype keeps everything in one app-level store and routes by three orthogonal pieces of state. Mirror this shape:

- **`tab`** — bottom-nav destination: `Today · Plans · History · Profile`.
- **`view`** — a pushed full-screen route over the current tab: `mealDetail · addMeal · addIngr · customFood · planDetail · createPlan` (null = the tab itself).
- **`sheet`** — a modal/bottom-sheet overlay: `snooze · swap · reminders · paywall · streak · calendar · planDays · conflict · review · confirm · logout · toast`.

Store collections: `meals`, `foods`, `plans`, `prefs`, plus transient editor state (`editingPlan`, `planDraft`, `extraLibrary`, `conflicts`, `toast`, `pendingIngrCb`).

### Key flows
- **Create plan:** dedicated `createPlan` view (name, goal, weekdays, meal picker, live macro preview). "Create new meal" mid-flow pushes `addMeal` then returns to the **preserved** plan draft. Plans list is read-only; editing (incl. weekdays) happens inside `planDetail`.
- **Add ingredient → custom food:** `addIngr` (with a persistent "Create custom food" CTA) → `customFood` → returns the new food to the in-progress meal via a pending callback.
- **Onboarding:** a separate linear flow (13 screens, horizontal slide), ending in sign-up + verify. See `product.md`.

---

## 6. Nutrition calculation

Single source of truth — never store computed totals.

- **Per-ingredient:** `macro = food.macroPer100g × grams / 100` for p, c, f, kcal.
- **Per-meal:** sum over ingredients (`mealMacros` in the prototype).
- **Per-day (Today):** planned = sum over the day's meals. **Consumed** = kcal of ingredients actually eaten — `done` = all of a meal's ingredients, `partial` = only the checked ones, `skipped` = 0. Consumed ≤ planned (only planned items are ever marked).
- **kcal auto-calc:** `kcal = p×4 + c×4 + f×9`. Manual override allowed only within **~10%** of calculated, else reject with an error.

---

## 7. Meal lifecycle & marking

- **One-tap default:** the meal-time notification offers **Ate it ✓ / Snooze / Skip**. "Ate it" marks the **whole meal** `done` (all ingredients) in one tap, no app open — the 90% path.
- **Partial = in-app:** opening the meal shows the ingredient checklist; status auto-derives — all checked = `done`, some = `partial`, none = `skipped`. Consumed kcal = the checked ingredients (§6). Ingredient on/off only; gram-level partial is post-MVP.
- **Lenient missed meals:** when a window passes with no action the meal is *shown* auto-skipped, but it can still be logged **any time that day**; it locks at **midnight** (the day is source of truth). No 2-hour cutoff.
- **Snooze:** short, commitment-style delay; cannot push past the next meal or midnight.

---

## 8. Plans, scheduling & snapshots

- **Plan = template.** Edits affect **future days only** — never today or history.
- **Locked history:** today's logged/skipped meals can't change; upcoming-today meals can be edited or swapped from the library. Slots can't be deleted mid-day (content can be replaced).
- **Snapshot-on-schedule:** when a meal is scheduled or logged, its data is **snapshotted**, so later library edits/deletions never alter past days. This is the core integrity rule — history is immutable.
- **At least one plan must always exist** (last plan can't be deleted).
- **Day assignment is plan-driven:** a meal belongs to the day it was *scheduled*, not logged (a 01:00 AM meal belongs to the previous day's plan).
- **Weekday conflict validation:** assigning a plan to a weekday already covered by another active plan raises a **Conflict modal** (lists conflicts, blocks save, offers **Override**). Inline/validation errors use a **Toast**.

### Reminder mode (set in onboarding)
- **Fixed (v1):** explicit time per meal slot; notifications fire at those times.
- **Interval → v2:** start-time + auto-spacing. Not in MVP.

---

## 9. Notifications

Scheduled locally per the user's plan and `Prefs` toggles:
- **Pre-meal** (`preMin` ahead) · **At meal time** (with **Ate it / Snooze / Skip** actions) · **End-of-day summary** · **Streak-at-risk** mid-day. (No-action warning folds into end-of-day.)
- Settings live in **Profile → Notifications** (not on Today).

---

## 10. Streaks & history

- **Adherence is calorie-based:** `dayAdherence = consumedKcal / plannedKcal` (§6).
- **Three-state day** — threshold = the green line, default **80%**, user-selectable 70/80/90/100; red floor fixed at 50%:
  - **Green** `≥ threshold` → streak **+1**
  - **Yellow** `50% ≤ adherence < threshold` → streak **holds** (survives; no increment, no reset)
  - **Red** `< 50%` → streak **resets to 0**
- **Milestone badges:** 7 / 30 / 100 days; track **personal best**. Weekend-skip → post-MVP.
- **History screen** derives: current streak + personal best, adherence %, weekly bar chart (green/yellow/red), recent per-day breakdown.
- **Calendar sheet** derives per-day color + recent totals.

---

## 11. Subscription & data retention

- **No freemium.** 7-day free trial with **card up front** (App/Play subscription, auto-converts unless cancelled). Monthly + annual, annual highlighted (pricing in `product.md`).
- Full lock on expiry (no read-only). Lock screen uses the user's own progress as messaging.
- **Retention:** data kept 90 days after trial expiry, then deleted; warning emails at day 7 and day 25 (backend job).

---

## 12. Testing patterns & known pitfalls

### 12.1 Widget-test teardown race with Riverpod streams

**Symptom:** Test passes all assertions, then fails at teardown with `Bad state: Cannot close sink while adding stream.` (or `Cannot add event while adding stream`).

**Root cause:** A `ProviderContainer` is disposed via `addTearDown(c.dispose)` while a `StreamController` (inside a Riverpod provider or repository) is still emitting an event from an async operation (e.g., `dayRepository.save()`). The container disposal triggers `ref.onDispose` → `controller.close()`, which races with the controller's own `add()` call.

**Why this happens with `SwapSheet` / future-day swaps:**
1. `replaceMeal()` → `dayRepository.save()` → `_changes.add(null)` → stream listeners fire
2. The widget test's `ProviderSubscription` (from `c.listen(...)`) is still active
3. `addTearDown(c.dispose)` runs automatically at end of test
4. Container disposal closes the `StreamController` while the stream event is mid-flight
5. Also: `showCrudoToast()` creates a 4.5s timer; if the widget tree is disposed before the timer fires, the `FakeTimer` leaks and the test binding complains

**Fix pattern:**

```dart
// ❌ DON'T: addTearDown(c.dispose) in a shared helper
ProviderContainer container() {
  final c = ProviderContainer(...);
  addTearDown(c.dispose);  // Races with in-flight stream events
  return c;
}

// ✅ DO: manual teardown in order: widget tree → subscriptions → container
final sub = c.listen(dayControllerProvider(date), (_, _) {});
// ... test body ...

// 1. Remove widget tree (clears overlays, toasts, timers)
await tester.pumpWidget(Container());
await tester.pumpAndSettle();

// 2. Close provider subscriptions (stops stream listeners)
sub.close();

// 3. Let any microtask-flush settle
await Future<void>.delayed(Duration.zero);

// 4. NOW dispose the container
container.dispose();
```

**For toast timers:** After any tap that triggers `showCrudoToast()`, pump the full duration before teardown:

```dart
await tester.tap(find.byKey(const ValueKey('swap-demo-meal-dinner')));
await tester.pump();
await tester.pump(const Duration(milliseconds: 200));
await tester.pump(const Duration(seconds: 5)); // 4.5s toast + margin
```

**For multi-swap tests:** If a test does one swap via controller (not UI) then pumps the widget tree, the stream broadcast from the first swap may not be fully settled. Add `await tester.pumpAndSettle()` between the controller swap and the widget pump.

### 12.2 `pumpAndSettle()` vs explicit `pump(Duration)` after async taps

**Rule:** After any tap that triggers an async callback doing `Navigator.pop()` + toast, use:

```dart
await tester.tap(find.byKey(...));
await tester.pump();
await tester.pump(const Duration(milliseconds: 200));
```

`pumpAndSettle()` deadlocks when the async future completes mid-pump and the pop corrupts the test binding's stream sink. Explicit `pump(Duration)` is safe because it does not wait for frame settling.

## 13. Project skills (`.agents/skills/`)

These Dart/Flutter agent skills define how to do common tasks in this repo. Read and follow the matching skill before that kind of work; they are the authority for tooling and conventions (§1).

**Kinds of skill, with a precedence rule:**
- **`flutter-expert`** is a broad always-on **quality overlay** — a capability menu + behavioral traits (const constructors, strategic keys, Dart 3 null-safety, accessibility/semantics, error + loading states, Impeller/perf awareness). Apply its *traits* to all Flutter work.
- The other skills are **prescriptive task workflows** for a specific job.
- **Precedence when skills conflict:**
  1. **Layout/layering** follows `flutter-apply-architecture-best-practices` (layer-first; see §2).
  2. **State management** follows `flutter-riverpod-arch` (Riverpod 3.x). This is the project's choice — `flutter-expert`'s broad menu (Bloc, GetX, MobX, Clean Architecture, etc.) does **not** override it.
  3. `flutter-expert` contributes *quality traits only*, never structure or tech choices, when it conflicts with the above.
- Note: `flutter-expert`'s `SKILL.md` references `resources/implementation-playbook.md`, which is **not present** — ignore that link unless the file is added.

| Skill | Use for |
|---|---|
| `flutter-expert` | Always-on quality/behavioral overlay for any Flutter work (see precedence note above) |
| `flutter-apply-architecture-best-practices` | Folder layout + layering — the layer-first MVVM in §2 |
| `flutter-riverpod-arch` | **State**: Riverpod 3.x providers, `Notifier`/`AsyncNotifier`, async flows (§1–2) |
| `flutter-setup-declarative-routing` | `go_router`, `StatefulShellRoute`, deep linking (§5) |
| `flutter-implement-json-serialization` | Model `fromJson`/`toJson` mapping |
| `flutter-add-widget-test` · `flutter-add-integration-test` · `dart-add-unit-test` | Tests at each layer |
| `dart-generate-test-mocks` | Mocks via `mockito` + `build_runner` |
| `dart-migrate-to-checks-package` | Use `package:checks` for assertions |
| `dart-collect-coverage` | LCOV coverage reports |
| `dart-run-static-analysis` | `dart analyze` + `dart fix --apply` |
| `dart-use-pattern-matching` | Switch expressions / pattern matching |
| `flutter-add-widget-preview` | `previews.dart` component previews |
| `flutter-build-responsive-layout` · `flutter-fix-layout-issues` | Responsive layout; fixing overflow/constraint errors |
| `flutter-setup-localization` | `intl` + `flutter_localizations` setup |
| `flutter-use-http-package` | REST calls with `http` |
| `dart-fix-runtime-errors` · `dart-resolve-package-conflicts` | Debugging runtime errors; pub version conflicts |
| `dart-build-cli-app` | CLI utilities (not core to the app) |
