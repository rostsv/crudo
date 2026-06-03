# Spec — S04: Routing Shell + Core Widgets

**Status:** approved (design) · **Spec S04 (ui)** · depends on S01 (theme, S02 enums for `MealStatus`) · scope = `go_router` 4-tab shell, sheet/toast infra, the shared widget kit per `app.css`, themed showcase placeholders, widget previews + tests. No data wiring, no controllers with logic, no feature screens.

## Goal
The persistent app frame every feature lands in: bottom-nav shell with state-preserving tabs, the sheet/toast plumbing, and the prototype's shared widgets implemented once against locked tokens — so S06/S10/S13/S15 only compose.

## Decisions (brainstorm 2026-06-03)
- **Sheets = helper + widget, not routes.** `showCrudoSheet(context, builder)` wraps `showModalBottomSheet` (rounded top, pill handle, glassmorphism blur(20), Cloud Shadow, no 1px borders); `SheetScaffold` standardizes title/content/CTA layout. Sheets are transient overlays — not URL-addressable in mobile v1.
- **Widget params are plain/primitive.** `ui/core` widgets take strings/numbers/callbacks (+ domain **enums/VOs** like `MealStatus` — allowed; domain **aggregates** like `Meal` — not). Feature views map domain → params. Widgets previewable + testable without domain fixtures.
- **Placeholders = themed skeleton + widget showcase.** Each tab renders its title + the relevant shared widgets with dummy params (Today → `MealCard`×3 + `MacroRing`; Plans → `SelectionCard`+`Pill`s; History → streak-ish row + `Toast` trigger; Profile → `SelectionCard` rows + `PrimaryCta`). Proves tokens + widgets in-app; doubles as the visual review surface.
- **Parallel delivery:** S04 runs on `feat/s04-routing` worktree alongside S03; only S04 touches `lib/app.dart`/`lib/routing/`.

## Routing (`lib/routing/app_router.dart`)
- `GoRouter` + `StatefulShellRoute.indexedStack`; branches `/today`, `/plans`, `/history`, `/profile`; initial `/today`.
- Shell scaffold: custom bottom nav per design system — **no 1px top border** (surface-color shift), Manrope labels, teal active / muted inactive, no Material 3 indicator pill. Dev-flavor marker moves into the shell (top-right, dev only — reads `appConfigProvider`).
- `lib/app.dart`: `CrudoApp` → `MaterialApp.router(routerConfig: ref.watch(appRouterProvider), theme: crudoTheme, ...)`; `_BootPlaceholder` deleted; existing widget tests updated.
- Router exposed as `Provider<GoRouter>` (`appRouterProvider`) in `routing/`.

## Shared widgets (`lib/ui/core/widgets/`) — tokens from `app.css` only
| Widget | API (plain params) | Key styling |
|---|---|---|
| `PrimaryCta` | `label`, `onPressed`, `enabled=true` | full-width, gradient 135° `primary→primary-soft`, pill radius, **no shadow**; disabled = reduced opacity |
| `Pill` | `label`, `selected`, `onTap` | compact chip; selected = teal fill/white text, else surface shift |
| `SelectionCard` | `title`, `subtitle?`, `selected`, `onTap`, `trailing?` | card with surface-shift selection (no border), generous padding |
| `MealCard` | `title`, `timeLabel`, `kcalLabel`, `status: MealStatus`, `onTap?` | status colors: done=teal, partial=gold **split-circle icon (never "½")**, upcoming=muted, skipped=red; no dividers |
| `MacroRing` | `protein`, `carbs`, `fats` (doubles), `centerLabel?` | ring segments: protein=teal, carbs=**gold**, fats=accent per app.css; custom painter |
| `SheetScaffold` | `title`, `child`, `cta?` | pill drag-handle, title row, body, optional sticky `PrimaryCta` |
| Toast | `showCrudoToast(context, message)` | floating overlay, Cloud Shadow `0 20px 40px rgba(26,28,26,0.04)`, glassmorphism, auto-dismiss ~2.5s |

`showCrudoSheet<T>(BuildContext, {required WidgetBuilder builder})` lives with `SheetScaffold` (`sheet.dart`).

## Placeholder screens (`lib/ui/features/<tab>/views/`)
`today_screen.dart`, `plans_screen.dart`, `history_screen.dart`, `profile_screen.dart` — plain `ConsumerWidget` showcases (dummy params; **no repos/controllers**, S06+ replaces content). Each also demonstrates one interaction: Plans opens a `SheetScaffold` demo via `showCrudoSheet`; History triggers `showCrudoToast`.

## Previews (`lib/previews.dart`)
Widget previews for all 7 widgets per `flutter-add-widget-preview` (each status variant of `MealCard`, selected/unselected states, disabled CTA).

## Tests (`test/ui/`, `test/routing/`)
- **Router:** pumping `CrudoApp` shows Today; tapping each nav item switches branch; tab state preserved (indexed stack) — scroll offset or a counter survives tab away/back.
- **Per widget:** renders its params; `MealCard` shows correct status color per `MealStatus` (all 4); `PrimaryCta` disabled blocks `onPressed`; `Pill`/`SelectionCard` selection visuals + tap callbacks; `MacroRing` paints (golden-free smoke + custom-paint presence); `SheetScaffold` via `showCrudoSheet` opens/closes; toast appears and auto-dismisses (fake timers).
- Existing `widget_test.dart`/theme tests updated for router boot (override `appConfigProvider`).

## Acceptance
- App boots into the 4-tab shell on dev flavor; tabs switch + preserve state; dev marker visible only in dev.
- All 7 widgets match `app.css` tokens (radii, colors, spacing) — no 1px borders, no drop shadows (Cloud Shadow only on floating), never pure black, no Material FAB/hamburger.
- `dart format .` + `flutter analyze` clean · `flutter test` green · architecture test green (untouched layers).
- No new deps (go_router already installed).

## Out of scope
Any repository/controller wiring (S03/S06+) · real feature content (S06/S10/S13/S15) · pushed detail routes (`mealDetail`, `createPlan`… — arrive with their features) · onboarding flow/redirects (S16+) · deep linking/web path strategy · golden tests.

## Skills
`flutter-setup-declarative-routing` · `flutter-add-widget-test` · `flutter-add-widget-preview` · `flutter-build-responsive-layout` · `flutter-riverpod-arch` (router provider) · `flutter-expert` (const, a11y/semantics on tap targets).
