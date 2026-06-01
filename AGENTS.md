# Crudo — Agent Guide

Single source of truth for **every agent and model** working in this repo — Claude Code, and opencode models that load it via `instructions: ["./AGENTS.md"]`. Tool-agnostic. `CLAUDE.md` points here.

## Roles & orchestration

- **Architect / orchestrator — Claude Opus (Claude Code).** Owns architecture decisions, the specs (`AGENTS.md`, `docs/`), task breakdown, and review/integration. Any change to conventions, the domain model, the design system, or dependencies originates here.
- **Implementation models (opencode):**
  - **ui** (`design_ui`) — screens & widgets, pixel-matching the prototype.
  - **implement** (`heavy_coder`) — feature logic: controllers, repositories, services, models, tests.
  - **build** (`workhorse`) — routine/bulk work: boilerplate, codegen runs, test fill-in, fixups.
  - **review** (optional) — read-only critic of diffs against this guide + the relevant skill.
- **Worker contract:** follow this file **and** the matching skill; stay in your lane; produce small, focused diffs. Do **not** change architecture, design-system, or dependency decisions — if something here is wrong, missing, or blocks you, **stop and escalate to the architect** rather than improvising. Meet the Definition of Done before declaring a task complete.

## Definition of done (every change)

1. `dart format .` leaves nothing to change.
2. `flutter analyze` is clean.
3. `flutter test` is green (add/adjust tests for what you changed).
4. Follows the relevant skill(s) and the locked decisions below.
5. UI matches `docs/design/prototype/app.css` exactly (tokens, radii, spacing).

A pre-commit hook enforces (1)–(2): `.githooks/pre-commit`. Enable once with `git config core.hooksPath .githooks`. Tests/build belong in CI or a pre-push hook.

## Project status

Crudo is a Flutter app in **early implementation**. `lib/main.dart` is a minimal `CrudoApp` placeholder; the product, design, and architecture are fully specified in `docs/`. Read the relevant doc before implementing a feature:

- `docs/product.md` — product definition, MVP scope (in vs. out), onboarding flow, screen-by-screen features, product decisions (marking, snooze, streak, paywall).
- `docs/design_system.md` — visual language: color tokens (incl. gold), typography, elevation, spacing, components, navigation, motion, do's/don'ts.
- `docs/architecture.md` — tech stack, domain/data model, nutrition calc, app state & navigation map, snapshots/scheduling/notifications, the skill catalog (§12), and open **(decision pending)** items.
- `docs/design/mock/onboarding/` — PNG mockups for onboarding screens.

### Design prototype (the pixel-perfect target)

`docs/design/prototype/` is an exported React/HTML prototype covering **every** main screen. It is the **canonical visual + interaction reference** — recreate it in Flutter, matching the visual output (don't port the JSX structure). Key files:

- `app.css` — locked design tokens (exact hex, radii, type scale, shadows). More precise than `design_system.md` for values.
- `screens/today.jsx`, `meal.jsx`, `other.jsx` (Plans/Plan detail/History/Profile), `plan-create.jsx`, `sheets.jsx` (all popups), `onboarding.jsx` (13-screen flow).
- `app.jsx` — app shell, routing between screens/sheets, and the seed data model (foods, meals, plans, prefs) — concrete reference for the domain types.
- `design-chat.md` — the design conversation (the *why* behind decisions).
- `onboarding-figma.jsx` and `tweaks-panel.jsx` are abandoned artifacts — ignore unless told otherwise.

## Commands

```bash
flutter pub get                       # install dependencies
flutter run                           # run on connected device/simulator
flutter run -d ios|chrome|<device>    # target a specific device
flutter analyze                       # lint / static analysis (analysis_options.yaml)
flutter test                          # run all tests
flutter test test/widget_test.dart    # run a single test file
flutter test --name "<substring>"     # run tests matching a name
dart format .                         # format code
dart run build_runner build --delete-conflicting-outputs   # codegen (freezed / riverpod / mockito)
```

Environment: Dart SDK `^3.11.5`. Lints from `flutter_lints`.

## Skills — use them

`.agents/skills/` holds Dart/Flutter skills that define this repo's conventions and tooling. **No agent or model auto-loads them** (not Claude Code, not opencode) — this guide is the bridge. For any task:

1. **Match** the task to a skill using the catalog in `architecture.md §12` (e.g. a screen → architecture + widget-test + widget-preview; navigation → declarative-routing; state → riverpod-arch).
2. **Read** that `SKILL.md` in full and follow its workflow before working — don't work from memory.
3. **Overlay:** `flutter-expert` is **always on** for Flutter work — const constructors, strategic keys, Dart 3 null-safety, accessibility/semantics, error + loading states, performance.
4. **Precedence:** locked decisions below and the specific task skill **win** over `flutter-expert`'s generic menu (e.g. state management is **Riverpod 3.x**, layout is **layer-first MVVM** — not Bloc/GetX/Clean-Architecture).
5. **Combine** when a task spans several skills — read all relevant ones first.

### Decisions the skills lock in

- **Layout/layering:** layer-first MVVM (`ui/features` + central `data/` + `domain/`). (`flutter-apply-architecture-best-practices`)
- **State management:** **Riverpod 3.x** — `@riverpod` `Notifier`/`AsyncNotifier` controllers in `view_models/`, `ConsumerWidget` views, `ProviderScope` at root, DI via Riverpod providers (no `get_it`/`provider`). Wrap async in `AsyncValue.guard`; `.select` for fine-grained rebuilds. (`flutter-riverpod-arch`)
- **Routing:** `go_router` + `StatefulShellRoute.indexedStack` for the 4-tab nav. (`flutter-setup-declarative-routing`)
- **Models:** immutable via `freezed`; JSON via `fromJson`/`toJson`.
- **Tests:** `package:test` / `WidgetTester` / `integration_test`; mocks via `mockito` + `build_runner`; assertions via **`package:checks`** (not `matcher`); coverage via `coverage`.
- **Quality:** `dart analyze` + `dart fix --apply`; prefer pattern-matching.

## Project structure

`lib/` follows the `flutter-apply-architecture-best-practices` skill — MVVM, hybrid layout (UI grouped by feature, data/domain grouped by type). `architecture.md §2` has the full tree.

- **`ui/features/<feature>/`** → `views/` (`ConsumerWidget` screens, UI-only logic) + `view_models/` (Riverpod controllers + providers). Shared widgets/themes in `ui/core/{widgets,themes}/`. Features: onboarding, auth, today, meals, plans, history, profile, paywall.
- **`domain/models/`** → clean immutable (freezed) models + enums.
- **`data/`** → `repositories/` (single source of truth per type, exposed as Riverpod providers) + `services/` (one source each, stateless) + `models/` (API/DTOs).
- **`config/`, `routing/`, `utils/`** → flavors/DI, go_router, nutrition math & validators.

Dependency flow is one-way: **View (ConsumerWidget) → Controller (Notifier/AsyncNotifier) → Repository → Service** (UseCase optional between controller and repository — add only when logic spans repositories). Views use `ref.watch`/`ref.read` and never touch Services directly; repositories don't depend on each other. Naming: `*_screen.dart`, `*_controller.dart` + `providers.dart`, `*_repository.dart`, `*_service.dart` (codegen → `*.g.dart`). Tests mirror layers in `test/{data,domain,ui,utils}/` (controllers via `ProviderContainer`); shared fakes in `testing/`.

## Core domain model

Full types and rules are in `docs/architecture.md`. The hierarchy:

- **Plan** → ordered list of meal *slots* (meal reference + time). One default plan repeats daily; multiple plans can be assigned to specific weekdays. At least one plan must always exist.
- **Meal** → name + tags (Breakfast/Lunch/Dinner/Snack/Pre-workout/Post-workout, multiple allowed) + unordered ingredients + auto-calculated nutrition. Meals are **reusable** across plans.
- **Ingredient** → name + macros per 100g (protein/carbs/fats required) + calories (auto-calculated `p×4 + c×4 + f×9`; manual override allowed only within ~10% of calculated, else reject) + optional category. All quantities in **grams only**.

Behavioral invariants that are easy to get wrong:

- **Meal marking is ingredient-level yes/no**, not gram-level. The per-ingredient checklist auto-derives done/partial/skip (all = done, some = partial, none = skip).
- **Streak is binary**: Green (≥80% meals done) or Red (resets). Yellow/partial-day is a parked post-MVP idea.
- **Plans are templates** — edits affect future days only, never today or history. Today's logged/skipped meals are locked. Upcoming-today meals can be edited or swapped.
- **Snapshot on schedule/log** — when a meal is scheduled or logged its data is snapshotted, so later library edits/deletions never alter past days or history.
- **Day assignment comes from the plan, not the log time** — a meal scheduled at 01:00 AM belongs to the previous day's plan.
- **Auto-skip & retroactive logging** — meals auto-skip if no action by end of window; user can retro-log up to 2 hours after the window.
- **Two reminder modes** (chosen in onboarding): fixed time (per-meal) or interval (start time + interval + meal count ≤6, times auto-calculated).

## Design system (non-negotiable constraints)

Follow `docs/design_system.md` for principles and `docs/design/prototype/app.css` for exact values. The rules most likely to be violated:

- **No-line rule**: never use 1px solid borders or horizontal dividers for sectioning. Define structure only through surface-color shifts and vertical padding.
- **No drop shadows** — use tonal layering. Floating elements only get the "Cloud Shadow" (`Y:20 Blur:40 rgba(26,28,26,0.04)`) + optional glassmorphism (`blur(20px)`).
- **Never pure black** — high-contrast text is `on-surface` `#1a1c1a`.
- **Font is Manrope**; extreme hierarchy — large bold display headlines vs. small all-caps tracked labels.
- **Primary CTA** is full-width, sticky to bottom, pill radius, no shadow. One primary action per screen.
- No standard Material FABs; no hamburger menus.
- **Copy voice**: direct, calm, premium. No exclamation marks, no motivational fluff.

### Locked color tokens (from `app.css`)

| Token | Hex | Usage |
|---|---|---|
| `surface` / `-low` / `-lowest` / `-high` | `#faf9f6` / `#f4f3f1` / `#ffffff` / `#e9e8e5` | tonal layering, base → elevated |
| `primary` / `primary-soft` | `#004d49` / `#196661` | CTA gradient (135°), selected states |
| `primary-container` | `#cce8e4` | teal tint for icon badges / pills |
| `on-surface` / `-var` / `-mut` | `#1a1c1a` / `#4a5552` / `#8a938f` | text: high-contrast / secondary / muted |
| **`gold` / `gold-soft`** | **`#e9b949` / `#f4dfa6`** | **partial meal state, Carbs macro, streak flame** |
| `error` / `error-soft` | `#ba1a1a` / `#ffdad6` | error text/icon (container stays neutral) |

Radii: `sm .75rem`, `md 1.25rem`, `lg 2rem`, `xl 3rem`, `full 9999px`.

**Gold is part of the palette.** Meal status colors: Done = teal, Partial = gold, Upcoming = muted/clock, Skipped = red. Use a split-circle icon for partial — never "½".

### Screens (all designed in `docs/design/prototype/`)

- **Navigation**: 4-tab glass bottom bar — **Today, Plans, History, Profile**.
- **Onboarding**: 13-screen linear flow (see `product.md` → Onboarding Flow), ending in Sign up + Verify.
- **Core**: Today, Meal detail, Plans (read-only list), Plan detail (editing happens here), Create plan, History, Profile.
- **Creation**: Add meal, Add ingredient (with "Create custom food" CTA), Add custom food (optional category).
- **Sheets/popups**: Snooze, Swap, Reminders, Paywall, Streak risk, Confirm, Review, Calendar (per-day stats), Plan-days editor, Schedule conflict, Toast.

See `architecture.md` for the behavioral rules these screens encode (plan-edit location, conflict/override validation, calendar stats, notification placement, app state & navigation map).

Respond terse like smart caveman. All technical substance stay. Only fluff die.

Rules:
- Drop: articles (a/an/the), filler (just/really/basically), pleasantries, hedging
- Fragments OK. Short synonyms. Technical terms exact. Code unchanged.
- Pattern: [thing] [action] [reason]. [next step].
- Not: "Sure! I'd be happy to help you with that."
- Yes: "Bug in auth middleware. Fix:"

Switch level: /caveman lite|full|ultra|wenyan
Stop: "stop caveman" or "normal mode"

Auto-Clarity: drop caveman for security warnings, irreversible actions, user confused. Resume after.

Boundaries: code/commits/PRs written normal.
