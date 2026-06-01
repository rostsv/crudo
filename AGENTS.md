# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project status

Crudo is a Flutter app in the **specification-complete, pre-implementation** stage. `lib/main.dart` is still the default Flutter counter template — no product code exists yet. Everything is defined across **three canonical docs** in `docs/`; read the relevant one before implementing any feature:

- `docs/product.md` — product definition, MVP scope (in vs. out), onboarding flow, screen-by-screen features, and product decisions (marking, snooze, streak, paywall).
- `docs/design_system.md` — visual language: color tokens (incl. gold), typography, elevation, spacing, components, navigation, motion, do's/don'ts.
- `docs/architecture.md` — tech stack, domain/data model, nutrition calc, app state & navigation map, snapshots/scheduling/notifications, and open **(decision pending)** items.
- `docs/design/mock/onboarding/` — PNG mockups for onboarding screens.

### Design prototype (the pixel-perfect target)

`docs/design/prototype/` is an exported React/HTML prototype from Claude Design covering **every** main screen. It is the **canonical visual + interaction reference** — recreate it in Flutter, matching the visual output (don't port the JSX structure). Key files:

- `app.css` — the locked design tokens (exact hex, radii, type scale, shadows). Treat this as the source of truth for styling values; it is more precise than `design_system.md`.
- `screens/today.jsx`, `meal.jsx`, `other.jsx` (Plans/Plan detail/History/Profile), `plan-create.jsx`, `sheets.jsx` (all popups), `onboarding.jsx` (13-screen flow).
- `app.jsx` — app shell, routing between screens/sheets, and the seed data model (foods, meals, plans, prefs) — a concrete reference for the domain types.
- `design-chat.md` — the full design conversation; shows **why** decisions were made and where things landed after teammate review.
- `HANDOFF-README.md` — the original handoff instructions from Claude Design.

`onboarding-figma.jsx` and `tweaks-panel.jsx` are alternate/abandoned artifacts — ignore unless told otherwise.

## Commands

```bash
flutter pub get                       # install dependencies
flutter run                           # run on connected device/simulator
flutter run -d ios|chrome|<device>    # target a specific device
flutter analyze                       # lint / static analysis (uses analysis_options.yaml)
flutter test                          # run all tests
flutter test test/widget_test.dart    # run a single test file
flutter test --name "<substring>"     # run tests matching a name
dart format .                         # format code
```

Environment: Dart SDK `^3.11.5`. Only `cupertino_icons` is a runtime dependency so far; lints come from `flutter_lints`.

## Project skills — use them

`.agents/skills/` holds the Dart/Flutter agent skills that define this repo's conventions and tooling. These are **markdown instruction files, not harness-registered slash commands** — Claude Code does not auto-surface `.agents/skills/` (only `.claude/skills/`), so **this CLAUDE.md is the bridge**: it's loaded every session and lists the catalog, which is how skills stay discoverable.

### How I use skills each session

1. **Match.** At the start of a task, map it to a skill using the catalog in `architecture.md` §12 (e.g. writing a screen → architecture + widget-test + widget-preview; adding navigation → declarative-routing).
2. **Read before doing.** Open that `SKILL.md` in full and follow its workflow/checklist — don't work from memory.
3. **Apply the overlay.** `flutter-expert` is **always on** for Flutter work: const constructors, strategic keys, Dart 3 null-safety, accessibility/semantics, error + loading states, performance. Apply its traits on top of the specific task skill.
4. **Respect precedence.** If `flutter-expert`'s generic options conflict with a locked decision below or a specific task skill, the **project decision / task skill wins** (e.g. state mgmt = **Riverpod 3.x**, layout = layer-first MVVM — not Bloc/GetX/Clean-Architecture, even though `flutter-expert` lists them).
5. **Combine when needed.** Multiple skills can apply to one task — read all relevant ones first.

If you'd rather the harness auto-surface these (so they appear as `/`-invocable skills and in session reminders without relying on CLAUDE.md), I can mirror them into `.claude/skills/` — ask and I'll set it up.

### Decisions the skills lock in

- **Layout/layering:** layer-first MVVM (`ui/features` + central `data/` + `domain/`). (`flutter-apply-architecture-best-practices`)
- **State management:** **Riverpod 3.x** — `@riverpod` `Notifier`/`AsyncNotifier` controllers in `view_models/`, `ConsumerWidget` views, `ProviderScope` at root, DI via Riverpod providers (no `get_it`/`provider`). Wrap async in `AsyncValue.guard`; `.select` for fine-grained rebuilds. (`flutter-riverpod-arch`)
- **Routing:** `go_router` + `StatefulShellRoute.indexedStack` for the 4-tab nav. (`flutter-setup-declarative-routing`)
- **Models:** immutable via `freezed`; JSON via `fromJson`/`toJson`.
- **Tests:** `package:test` / `WidgetTester` / `integration_test`; mocks via `mockito` + `build_runner`; assertions via **`package:checks`** (not `matcher`); coverage via `coverage`.
- **Quality:** `dart analyze` + `dart fix --apply`; prefer pattern-matching.

## Project structure

`lib/` follows the `flutter-apply-architecture-best-practices` skill — MVVM, hybrid layout (UI grouped by feature, data/domain grouped by type). Scaffolded as empty `.gitkeep` placeholders; `architecture.md` §2 has the full tree.

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

- **Meal marking is ingredient-level yes/no**, not gram-level. The per-ingredient checklist auto-derives done/partial/skip (5/5 = done, 1–4/5 = partial, 0/5 = skip).
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
