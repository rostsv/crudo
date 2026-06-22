# Spec — S16: Onboarding — value funnel (screens 1–7)

**Status:** approved (design) · **Spec S16** · Phase 6 (Onboarding). Depends on S04 (`PrimaryCta`, `SelectionCard`, `showCrudoToast`, `CrudoText`/`CrudoColors`/`Spacing`/`Radii`/`Shadows`, go_router shell). First in the 3-sprint onboarding flow (S16 funnel → S17 setup → S18 demo); S17/S18 extend the same flow host and controller.

Scope = the **value-funnel front half** of onboarding: seven presentational screens that demonstrate value and run two single-select surveys, with no data persistence and no account/setup work. Visual target is the prototype `docs/design/prototype/screens/onboarding.jsx` (screens 1–7); the older PNG mocks under `docs/design/mock/onboarding/` are **not** the reference. The flow is reachable at a new pushed route `/onboarding` and is **not yet gated** behind first launch (gate wired in S18 when the flow terminates in paywall/auth).

## Goal

Give a new user the first-run "why Crudo" narrative — welcome, the problem (two pain screens), a demo placeholder, the transformation pitch, then two quick attribution/history surveys — ending where S17's plan-setup will pick up. Everything is in-memory: the two survey answers (`source`, `tried`) live in an onboarding controller and are carried forward (submitted to analytics when the backend lands, S19+); no `Prefs`/repository writes happen in S16. The funnel is one full-screen host driving a button-advanced `PageView`; later sprints append setup screens to the same host.

## Decisions (brainstorm 2026-06-22)

- **7 screens, per prototype.** Welcome → Awareness → Structure → VideoDemo → Transformation → HeardAbout → TriedApps. Includes the prototype's "tried something like this before?" survey (screen 7), which product.md's 6-item list omits — prototype wins. Confirmed via fork.
- **No first-launch gate yet.** `/onboarding` is a top-level pushed route, **dev-reachable** (like `/foods`), not wired into app launch. The app still boots to `/today`. The real first-launch redirect + persisted "seen" flag is S18 work (the flow isn't complete until paywall/auth), so we don't risk trapping users in a half-flow. Confirmed via fork.
- **Single `PageView`, button-driven.** One `OnboardingFlowScreen` hosts a `PageController`; physics = `NeverScrollableScrollPhysics` (no free swipe). Navigation only via Back/Continue, so a validation gate (HeardAbout/TriedApps require a selection) can never desync from the visible page. Confirmed via fork.
- **Survey answers held in-memory.** `source` and `tried` live in `OnboardingController` for the session, carried forward; no `Prefs` field, no local persistence, no submission in S16 (analytics submit = S19+). Confirmed via fork.
- **Design tokens, not prototype px.** The prototype is a sketch (raw `rgb()`/px). Map everything to the design system: titles → `CrudoText.displaySm`/`headline`, sub → `body`, kicker → `label`, selected option = `primaryContainer` tone shift (SelectionCard convention — **no border**, overriding the prototype's 2px ring), cards → `surfaceLowest` + `Shadows.cloud`, all gaps/radii on the 4px grid. Welcome's stacked hero cards + ambient glows are decorative, token-colored.
- **Stubs for not-yet-built destinations.** Welcome's "I already have an account" → `showCrudoToast` (sign-in = S22). VideoDemo player has no asset — it's a static placeholder; tapping play → toast. The terminal Continue (after TriedApps) → pop the `/onboarding` route + toast (the S17 plan-setup handoff replaces this). Confirmed via fork.
- **Progress dots size to the current flow.** The top-bar dots count the post-Welcome screens present now (6); Welcome shows the centered wordmark instead of dots. Later sprints (S17/S18) extend the count as they append screens. (Prototype hardcodes `total=10` for the full eventual 13-screen flow — we don't pre-render dots for unbuilt screens.)

## Route

```dart
// app_router.dart — top-level, pushed over nothing (own full-screen flow), not in the tab shell.
GoRoute(
  path: '/onboarding',
  builder: (context, state) => const OnboardingFlowScreen(),
),
```

Dev-reachable only this sprint. No redirect logic, no change to `initialLocation: '/today'`.

## `OnboardingController` (`view_models/onboarding_controller.dart`)

Holds the only mutable flow state. `autoDispose` (state dies when the flow route pops — re-entering starts fresh).

```dart
@freezed
abstract class OnboardingState with _$OnboardingState {
  const factory OnboardingState({
    @Default(0) int pageIndex,
    String? source, // HeardAbout selection id
    String? tried,  // TriedApps selection id
  }) = _OnboardingState;
}

@riverpod
class OnboardingController extends _$OnboardingController {
  @override
  OnboardingState build() => const OnboardingState();

  void next() => state = state.copyWith(pageIndex: state.pageIndex + 1);
  void back() => state = state.copyWith(pageIndex: state.pageIndex - 1);
  void setSource(String id) => state = state.copyWith(source: id);
  void setTried(String id) => state = state.copyWith(tried: id);
}
```

The host watches `pageIndex` and animates the `PageController` to match (single source of truth = the controller; the `PageView` mirrors it). Back on `pageIndex == 0` (Welcome) pops the route instead.

## Flow host (`views/onboarding_flow_screen.dart`)

`ConsumerStatefulWidget` (owns the `PageController`). Reads `onboardingControllerProvider`; on `pageIndex` change, `animateToPage`. Builds the 7 pages in order inside the `PageView`. Routes Back/Continue intents to the controller; the controller's `next()` past the last page triggers the terminal action (pop + toast).

Pages live in `views/pages/`:

| # | File | Screen | Continue behavior |
|---|------|--------|-------------------|
| 1 | `welcome_page.dart` | Welcome | "Set up my plan" → `next()`; "I already have an account" → toast (S22) |
| 2 | `awareness_page.dart` | Awareness (pain) | Continue → `next()` |
| 3 | `structure_page.dart` | Structure (pain, chaos vs Crudo) | Continue → `next()` |
| 4 | `video_demo_page.dart` | Video demo (placeholder) | "Watch & Continue" → `next()`; play tap → toast |
| 5 | `transformation_page.dart` | Transformation (stats + features) | "Build my plan" → `next()` |
| 6 | `heard_about_page.dart` | Attribution survey | Continue (disabled until `source != null`) → `next()` |
| 7 | `tried_apps_page.dart` | Prior-apps survey | Continue (disabled until `tried != null`) → terminal: pop + toast |

## Shared chrome (`views/widgets/`)

- **`OnboardingScaffold`** — common frame: top bar (Welcome → centered wordmark; others → back button + `OnboardingProgress` dots), scrollable/flex body region, sticky bottom footer holding the CTA(s). Takes `step` (or null for Welcome), `onBack`, body, footer.
- **`OnboardingProgress`** — animated dot row: `total` dots, current dot elongated (`Radii.full`), filled dots `primary`, rest `primary` at low opacity. `Durations.base` transition. `total = 6` this sprint.

Reuse `PrimaryCta` (Continue), a small text button for the Welcome secondary action, `SelectionCard` for the survey options (HeardAbout grid, TriedApps list), `showCrudoToast` for all stubs.

## Screen content (verbatim from prototype `onboarding.jsx`)

1. **Welcome** — wordmark "Crudo"; three decorative hero cards (Protein Bowl 08:00 AM ✓ / Quinoa Salad 12:30→13:15 snoozed / Baked Salmon 07:00 PM, not done); title "Follow your meal plan without overthinking"; sub "Build your meals once, get reminded on time, keep your streak alive."; CTA "Set up my plan"; secondary "I already have an account".
2. **Awareness** — title "You already know the plan."; sub "The struggle isn't information — it's the friction of modern life."; cards: Skipped Meals · "Days fly by — meals get forgotten." / Lost Momentum · "One missed meal cascades into a derailed day." / Decision Fatigue · "\"What should I eat now?\" drains willpower."; CTA "Continue".
3. **Structure** — title "Structure beats willpower."; sub "Crudo holds the rhythm so you don't have to."; WITHOUT STRUCTURE: Skipped breakfast "Too busy" / Random snacking "Sugar spike" — VS — WITH CRUDO: High-protein morning 08:00 AM / Planned fuel 01:00 PM; CTA "Continue".
4. **VideoDemo** — kicker "60 SECOND TOUR"; title "See how Crudo works"; sub "Plans, reminders, snoozing — the daily loop, in under a minute."; player placeholder (9:16 frame, play glyph, 0:58 pill, DEMO tag); CTA "Watch & Continue".
5. **Transformation** — title "Turn your plan into a routine."; sub "Ingredients, gram amounts, reminders, and quick check-ins help you stay on track every day."; stat trio 3× Consistency "vs no system" / 87% Adherence "avg week 2" / 21d Habit "with reminders"; feature list 01 Smart reminders "Nudges at the right moment, not just a fixed time." / 02 Structured plans "Assign meals to days. Crudo tracks what is next." / 03 Flexible snoozing "Push a meal forward without losing your streak."; CTA "Build my plan".
6. **HeardAbout** — kicker "QUICK ONE"; title "Where did you hear about Crudo?"; sub "Helps us know what's working. Pick one."; 2-col grid options: TikTok, Instagram, YouTube, Reddit, Friend / family, App store / search, Press / blog, Somewhere else; CTA "Continue" (gated).
7. **TriedApps** — kicker "ONE MORE"; title "Tried something like this before?"; sub "No judgement — most of us have a graveyard of nutrition apps. Pick the closest."; list options: MyFitnessPal "Calorie & macro logger", Noom "Behavioural coaching", Lose It! / Cronometer "Calorie tracking", Mealime / Eat This Much "Recipe planners", A few of these "And kept switching", No, this is my first "Fresh start"; CTA "Continue" (gated).

## Testing (`test/.../onboarding/`)

Widget + controller tests, run `flutter test --timeout=90s`:

- **Full advance** — from Welcome, tapping each CTA walks Welcome→…→TriedApps; each screen's title renders.
- **Back navigation** — Back returns to the previous page; on Welcome, Back pops the route.
- **Survey gating** — HeardAbout/TriedApps Continue is disabled until an option is selected; selecting enables it and records the id in the controller.
- **Controller** — `setSource`/`setTried` set the ids; `next`/`back` move `pageIndex`; state resets on fresh build.
- **Stubs fire** — "I already have an account", the video play tap, and the terminal Continue each show a toast / pop (no navigation to unbuilt destinations).

## Out of scope (later sprints)

First-launch gate + persisted "seen onboarding" flag (S18) · real demo video asset · sign-in / account creation (S22) · goal / meal-count / timing / reminders setup screens 8–11 (S17) · interactive demo screen (S18) · paywall (S24) · analytics submission of `source`/`tried` (S19+).
