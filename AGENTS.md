# Crudo -- Agent Guide

Single source of truth for every agent working in this repo. Loaded via `instructions: ["./AGENTS.md"]` in `opencode.json`. Tool-agnostic. `CLAUDE.md` points here.

## Project status

Flutter app, early implementation. `lib/main.dart` is still a placeholder (no product code yet). Read these before touching anything:

- `docs/product.md` -- what to build, MVP scope, onboarding flow
- `docs/design_system.md` -- visual principles
- `docs/architecture.md` -- stack, domain model, folder layout, conventions
- `docs/design/prototype/app.css` -- **locked color + type tokens (authoritative)**
- `docs/design/prototype/screens/*.jsx` -- visual *sketch*: composition + fields to show; dimensions always snap to the design system (`design_system.md §5`)
- `docs/workflow.md` -- the brainstorm→plan→delegate→review→integrate loop

**Resume protocol:** `git log` / `git status` → newest plan in `docs/plans/` → first unchecked task → its spec → skills → implement.

## Commands

```bash
flutter pub get                                          # install deps (run first)
# Flavored run (dev + prod coexist on device):
flutter run --flavor dev  -t lib/main_development.dart --dart-define-from-file=config/dev.json
flutter run --flavor prod -t lib/main.dart            --dart-define-from-file=config/prod.json
dart format .                                           # format (pre-commit checks this)
flutter analyze                                         # lint + static analysis
flutter test --timeout=90s                              # run all tests — ALWAYS pass --timeout
flutter test test/widget_test.dart --timeout=90s        # single test file
flutter test --name "<substring>" --timeout=90s         # tests matching name
dart run build_runner build                               # codegen: freezed (build_runner 2.15: no --delete-conflicting-outputs flag)
```

**Test timeouts are mandatory.** A widget test with an infinite animation (`pumpAndSettle` on a repeating animation), an unclosed stream, or a never-settling provider hangs forever and stalls the whole run. **Always run `flutter test` with `--timeout=90s`** (per-test cap; cross-platform via the test package). For a deadlock the per-test cap can't catch (`build_runner`, `flutter pub get`, a hung process), add a wall-clock backstop: `gtimeout 600 <cmd>` (macOS: `brew install coreutils`; CI/Linux: plain `timeout 600 <cmd>`). When a test legitimately needs longer, mark that one test `@Timeout(Duration(minutes: 2))` — never raise the global cap to hide a hang.
> `config/dev.json` / `config/prod.json` are gitignored — copy `config/example.json` and fill locally. The freezed codegen toolchain is installed (S02); run `dart run build_runner build` after touching any `@freezed` model. JSON codegen is deliberately absent — the domain is serialization-free; DTOs arrive in `data/` at S20.

Environment: Dart SDK `^3.11.5`. Enable pre-commit hook once: `git config core.hooksPath .githooks`.

**Required command order:** format → analyze → test. The pre-commit hook enforces this automatically.

**Commit messages: human-only authorship.** Never add `Co-Authored-By: Claude/Anthropic`, "Generated with Claude Code", or any AI-attribution trailer — applies to every agent/model (Opus, opencode workers). The `commit-msg` hook strips them mechanically as a backstop, but don't write them.

## Project structure

```
lib/
├── main.dart                     # placeholder; wrapped in ProviderScope when wired
├── config/                       # flavors, DI wiring, env config
├── routing/                       # go_router with StatefulShellRoute (4 tabs)
├── utils/                         # GENERIC technical helpers only (calendar math) — never business rules
├── domain/                        # PURE Dart — no Flutter/Riverpod/JSON/Supabase imports, ever
│   ├── product/ meal/ plan/ day/ profile/ streak/   # aggregate modules (freezed entities)
│   ├── shared/                    # value objects (MealTime, Macros, Grams) + enums
│   ├── services/                  # pure domain services (nutrition; meal_status S05; adherence S12)
│   ├── validation/                # ValidationIssue + validate() extensions (@Assert = tier 1)
│   └── repositories/              # ABSTRACT repository interfaces (from S03)
├── application/                   # use-cases — only when logic spans ≥2 repos; else controllers handle it
├── data/
│   ├── repositories/              # impls of domain interfaces: in-memory (S03) → Supabase (S20)
│   ├── services/                  # one stateless wrapper per external system (seed, db, notifications…)
│   ├── dto/                       # wire shapes (never leak past data/)
│   └── mappers/                   # dto ↔ domain
└── ui/
    ├── core/{widgets,themes}/     # shared components, tokens from app.css
    └── features/<feature>/
        ├── views/                # ConsumerWidget screens (UI-only logic)
        └── view_models/          # Riverpod Notifier/AsyncNotifier controllers + providers
```

**Dependency rule (one-way, the anti-spaghetti guarantee):** View → Controller (Notifier/AsyncNotifier) → Repository (domain interface) → data Service. `ui → application → domain ← data`; **domain depends on nothing**. Views `ref.watch`/`ref.read` controllers; never call Services directly. Repositories never depend on each other. Business rules live on **aggregates/domain services** — not in controllers, not in widgets. A domain file importing `package:flutter`, Riverpod, or Supabase = instant review reject.

## Core domain invariants (easy to get wrong)

Quantities stored in **grams** (displayed g/oz per user pref). Calories auto-calculated `p×4 + c×4 + f×9`; manual override only if within **±10%**, else reject.

- **Meal marking is ingredient-level yes/no** -- not gram-level. Per-ingredient checklist auto-derives: all checked = done, some = partial, none = skipped.
- **Streak is calorie-based, 3-state** -- day adherence = consumed ÷ planned kcal. Green `≥ threshold` (default 80%, selectable 70/80/90/100) → +1; Yellow `50–<threshold` → holds; Red `<50%` → resets. Weekend-skip is post-MVP.
- **Plans are templates** -- edits affect future days only. Today's logged/skipped meals are locked; upcoming-today meals can be edited/swapped.
- **Snapshot on schedule/log** -- data is snapshotted when scheduled or logged; later library edits/deletions never alter past days or history.
- **Day assignment comes from the plan** -- a meal at 01:00 AM belongs to the previous day's plan.
- **Lenient missed meals** -- a passed window shows auto-skipped, but the meal can still be logged **any time that day**; locks at **midnight** (no 2-hour cutoff).
- **At least one plan must always exist** -- last plan cannot be deleted.
- **Reminder mode:** fixed time per meal (v1). Interval mode → v2.

## Design system (non-negotiable)

`docs/design/prototype/app.css` is the **authoritative source for colors and type** -- where it differs from `design_system.md`, trust `app.css`. For **dimensions** the roles flip: `design_system.md §5` is law, the prototype is only a sketch.

- **Dimensional system (strict):** every dimension sits on the 4px grid. Paddings/gaps only from `Spacing`, icons only from `IconSizes`, radii only from `Radii` (`lib/ui/core/themes/dimensions.dart`). Component-intrinsic sizes = named widget constants on the grid, recorded in `design_system.md §5`. **Never copy raw px from the prototype — snap to the nearest token** (18→16, 3→4, 22→24). New size = new token in `dimensions.dart` + doc entry, same change. Only painted stroke widths (1–3px) may live off-grid.
- **No-line rule:** no 1px borders, no horizontal dividers. Use surface-color shifts + vertical padding.
- **No drop shadows:** tonal layering only. Floating elements get Cloud Shadow `0 20px 40px rgba(26,28,26,0.04)` + optional glassmorphism `blur(20px)`.
- **Never pure black** -- high-contrast text is `#1a1c1a`.
- **Font:** Manrope (bundled). Extreme type hierarchy.
- **Primary CTA:** full-width, sticky bottom, gradient `primary→primary-soft` (135°), pill radius, no shadow.
- **No** standard Material FABs, hamburger menus, 1px borders, or decorative shadows.
- **Meal status colors:** Done = teal, Partial = gold (split-circle icon, never "½"), Upcoming = muted, Skipped = red.
- **Gold is part of the palette** -- partial meal state, Carbs macro, streak flame.

## Tech stack decisions (locked -- don't override)

- **State:** Riverpod 3.x (`@riverpod` `Notifier`/`AsyncNotifier` in `view_models/`). No `get_it`/`provider`. Wrap async in `AsyncValue.guard`; use `.select` for fine-grained rebuilds.
- **Routing:** `go_router` + `StatefulShellRoute.indexedStack` for 4-tab nav.
- **Models:** `freezed` immutable, **serialization-free domain** (no `fromJson`/`toJson` in `lib/domain/` — wire shapes are DTOs in `data/dto/` from S20). Canonical domain catalog: `docs/specs/2026-06-03-s02-domain-models-nutrition.md`.
- **Tests:** `package:test`, `WidgetTester`, `integration_test`; mocks via `mockito` + `build_runner`; assertions via **`package:checks`** (not `matcher`); coverage via `coverage`. Controllers tested with `ProviderContainer`.
- **Codegen output:** `*.g.dart` (from `build_runner`).

## Skills -- use them

`.agents/skills/` defines repo conventions + tooling. **Skills do not auto-load** -- read the relevant skill before that kind of work.

Skill catalog (see `docs/architecture.md §12` for full table):

| Skill | Use for |
|---|---|
| `flutter-expert` | Always-on quality overlay (const, null-safety, accessibility) |
| `flutter-apply-architecture-best-practices` | Layer-first MVVM folder layout |
| `flutter-riverpod-arch` | State: Riverpod 3.x, Notifier/AsyncNotifier |
| `flutter-setup-declarative-routing` | `go_router`, StatefulShellRoute |
| `flutter-implement-json-serialization` | `fromJson`/`toJson` mapping |
| `flutter-add-widget-test` + `flutter-add-widget-preview` | Widget tests + `previews.dart` |
| `dart-add-unit-test` | Unit tests for controllers/services |
| `dart-generate-test-mocks` | `mockito` + `build_runner` |
| `dart-migrate-to-checks-package` | Use `package:checks` for assertions |

**Skill precedence:** skill catalog + locked decisions win over `flutter-expert`'s generic menu. E.g., state management = Riverpod 3.x (not Bloc/GetX/Clean-Architecture).

## Onboarding (13 screens, supersedes prototype)

The 13-screen onboarding flow in `product.md` is canonical. The prototype's `screens/onboarding.jsx` is visual reference only -- the actual flow has steps (7) Baseline goal, (8) Daily structure (meal count), (9) Meal timing (fixed), (10) Reminders, (11) Interactive demo, (12) Sign up, (13) Paywall.

## Definition of done (every change)

1. `dart format .` leaves nothing to change.
2. `flutter analyze` is clean.
3. `flutter test` is green (add/adjust tests for what you changed).
4. Follows the relevant skill(s) and locked decisions above.
5. UI matches `docs/design/prototype/app.css` exactly (tokens, radii, spacing).