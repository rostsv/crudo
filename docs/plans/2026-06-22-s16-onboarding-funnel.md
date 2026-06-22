# Plan — S16: Onboarding — value funnel (screens 1–7)

> **Worker note:** Implements `docs/specs/2026-06-22-s16-onboarding-funnel.md`. Each `## Task N:` is self-contained — read `AGENTS.md`, your role file, and any named `.agents/skills/*` before starting. TDD + gates per task, **no commits** (end at "report for review"). Assertions via `package:checks`; **every** `flutter test` carries `--timeout=90s`; wrap `build_runner` in `gtimeout 600` (macOS needs coreutils; on Linux/CI use plain `timeout 600`; if absent, run `dart run build_runner build` directly and watch it). Build top-to-bottom: T1→T7.

**Goal:** Build the front half of onboarding — seven presentational funnel screens (Welcome, two pain screens, a video-demo placeholder, transformation pitch, two single-select surveys) hosted in one button-advanced `PageView` at a dev-reachable `/onboarding` route, with all flow state in an in-memory controller and every not-yet-built destination stubbed to a toast.

**Architecture:** One `OnboardingFlowScreen` owns a `PageController` and mirrors `OnboardingController.pageIndex` (single source of truth = the controller; the `PageView` follows it, never free-swipes). The seven page widgets are **pure** — plain params + callbacks, no provider/controller imports (S04 core-widget convention) — so each is testable in isolation. The host injects controller state and wires Back/Continue; Back on page 0 and Continue past the last page both `Navigator.pop` the route (the S17 setup handoff replaces the terminal pop later). No persistence, no `Prefs`/model change.

**Tech stack:** Flutter, Riverpod 3.x (`@riverpod`), freezed 3.x, go_router, `package:checks`. Reuses `PrimaryCta`, `SelectionCard`, `showCrudoToast`, the theme tokens. No new packages.

## Decisions (from spec brainstorm 2026-06-22)

| Fork | Decision |
|---|---|
| Screen count | 7, per prototype (includes "tried other apps?"). |
| Gating | None this sprint; `/onboarding` dev-reachable, app still boots `/today`. Gate = S18. |
| Navigation | One `PageView`, `NeverScrollableScrollPhysics`, button-driven only. |
| Survey answers | Held in-memory in `OnboardingController` (`source`, `tried`); no persist, no submit (S19+). |
| Visuals | Design tokens, not prototype px; selected option = `primaryContainer` tone (no border). |
| Stubs | "I already have an account" / video play / terminal Continue → toast (+ pop for terminal). |
| Progress dots | Size to current flow (6 post-Welcome); Welcome shows wordmark. |

## File changes (map)

- **Create** `lib/ui/features/onboarding/view_models/onboarding_controller.dart` (+ `.g.dart`, `.freezed.dart`) — `OnboardingState` + `OnboardingController` (T1)
- **Create** `lib/ui/features/onboarding/views/widgets/onboarding_scaffold.dart` — `OnboardingScaffold` (T2)
- **Create** `lib/ui/features/onboarding/views/widgets/onboarding_progress.dart` — `OnboardingProgress` (T2)
- **Create** `lib/ui/features/onboarding/views/pages/welcome_page.dart` — `WelcomePage` (T3)
- **Create** `lib/ui/features/onboarding/views/pages/awareness_page.dart` — `AwarenessPage` (T4)
- **Create** `lib/ui/features/onboarding/views/pages/structure_page.dart` — `StructurePage` (T4)
- **Create** `lib/ui/features/onboarding/views/pages/video_demo_page.dart` — `VideoDemoPage` (T5)
- **Create** `lib/ui/features/onboarding/views/pages/transformation_page.dart` — `TransformationPage` (T5)
- **Create** `lib/ui/features/onboarding/views/pages/heard_about_page.dart` — `HeardAboutPage` + `kHeardAboutOptions` (T6)
- **Create** `lib/ui/features/onboarding/views/pages/tried_apps_page.dart` — `TriedAppsPage` + `kTriedAppsOptions` (T6)
- **Create** `lib/ui/features/onboarding/views/onboarding_flow_screen.dart` — `OnboardingFlowScreen` (T7)
- **Modify** `lib/routing/app_router.dart` — register `/onboarding` (T7)
- **Tests** mirror each under `test/ui/features/onboarding/`

## Shared contract — reused symbols (verbatim)

```dart
// core/widgets/primary_cta.dart
//   PrimaryCta({required String label, required VoidCallback? onPressed, bool enabled = true});
//   onPressed is REQUIRED (pass null when disabled). Gradient primary→primary-soft only.
// core/widgets/selection_card.dart
//   SelectionCard({required String title, String? subtitle, required bool selected,
//                  required VoidCallback onTap, Widget? trailing});
//   Selected = primaryContainer fill, NO border (convention).
// core/widgets/toast.dart
//   void showCrudoToast(BuildContext, String title, {String? body, ToastKind kind, Duration duration});
// core/themes/typography.dart : CrudoText.{display,displaySm,headline,headlineSm,title,body,bodyLg,label,labelMd}
// core/themes/colors.dart     : Theme.of(context).extension<CrudoColors>()!  → .primary/.primarySoft/
//                               .primaryContainer/.surface/.surfaceLow/.surfaceLowest/.onSurface/
//                               .onSurfaceVar/.onSurfaceMut/.gold/.error
// core/themes/dimensions.dart : Spacing.{xs,sm,md,lg,xl,xxl}; Radii.{sm,md,lg,xl,full,all()};
//                               Shadows.{cloud,cloudDeep}; Durations.{fast,base,slow}; Opacities.{muted,disabled}
// core/themes/theme.dart      : crudoTheme  (test harness theme)
```

### Page widget APIs (define in T3–T6, consumed by the host in T7)

```dart
WelcomePage({required VoidCallback onSetUp, required VoidCallback onSignIn});
AwarenessPage({required VoidCallback onContinue, required VoidCallback onBack});
StructurePage({required VoidCallback onContinue, required VoidCallback onBack});
VideoDemoPage({required VoidCallback onPlay, required VoidCallback onContinue, required VoidCallback onBack});
TransformationPage({required VoidCallback onContinue, required VoidCallback onBack});
HeardAboutPage({required String? selected, required ValueChanged<String> onSelect,
                required VoidCallback onContinue, required VoidCallback onBack});
TriedAppsPage({required String? selected, required ValueChanged<String> onSelect,
               required VoidCallback onContinue, required VoidCallback onBack});
```

All non-Welcome pages render inside `OnboardingScaffold(step:, total: 6, onBack:, body:, footer:)`. Survey Continue is enabled iff `selected != null`.

---

## Task 1: OnboardingController + state

**Role:** implement

**Goal:** In-memory flow state — `pageIndex` + two nullable survey ids — behind an `autoDispose` `@riverpod` Notifier with `next`/`back`/`setSource`/`setTried`.

**Files:**
- Create: `lib/ui/features/onboarding/view_models/onboarding_controller.dart` (+ codegen)
- Test: `test/ui/features/onboarding/view_models/onboarding_controller_test.dart`

**Contract:**

```dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'onboarding_controller.freezed.dart';
part 'onboarding_controller.g.dart';

@freezed
abstract class OnboardingState with _$OnboardingState {
  const factory OnboardingState({
    @Default(0) int pageIndex,
    String? source,
    String? tried,
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

- [ ] **Step 1: Write the failing test**

```dart
import 'package:checks/checks.dart';
import 'package:crudo/ui/features/onboarding/view_models/onboarding_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late ProviderContainer container;
  setUp(() {
    container = ProviderContainer();
    // Hold the autoDispose provider alive so state survives between reads —
    // a bare read(.notifier)/mutate/re-read on an unlistened autoDispose
    // provider can dispose and reset to the initial state between reads.
    container.listen(onboardingControllerProvider, (_, __) {});
  });
  tearDown(() => container.dispose());

  OnboardingController ctrl() =>
      container.read(onboardingControllerProvider.notifier);
  OnboardingState state() => container.read(onboardingControllerProvider);

  test('initial state is page 0 with no selections', () {
    check(state().pageIndex).equals(0);
    check(state().source).isNull();
    check(state().tried).isNull();
  });

  test('next / back move pageIndex', () {
    ctrl().next();
    check(state().pageIndex).equals(1);
    ctrl().next();
    ctrl().back();
    check(state().pageIndex).equals(1);
  });

  test('setSource / setTried record ids', () {
    ctrl().setSource('tiktok');
    ctrl().setTried('mfp');
    check(state().source).equals('tiktok');
    check(state().tried).equals('mfp');
  });
}
```

- [ ] **Step 2: Run, verify it fails** — `flutter test test/ui/features/onboarding/view_models/onboarding_controller_test.dart --timeout=90s` → FAIL (target/part files missing).
- [ ] **Step 3: Write `onboarding_controller.dart`** exactly as the Contract above.
- [ ] **Step 4: Codegen** — `gtimeout 600 dart run build_runner build` (generates `.freezed.dart` + `.g.dart`).
- [ ] **Step 5: Run, verify pass** — same command as Step 2 → PASS (3 tests).

**Skills:** `.agents/skills/flutter-riverpod`, `.agents/skills/dart-add-unit-test`, `.agents/skills/dart-migrate-to-checks-package`.

**Acceptance:** controller compiles with generated parts; 3 tests green; no persistence/repo calls.

**Out of scope:** any UI; any repo/`Prefs` read or write; the `keepAlive` flag (default `@riverpod` autoDispose is correct).

---

## Task 2: Shared chrome — OnboardingScaffold + OnboardingProgress

**Role:** ui

**Goal:** The common frame (top bar + flex body + sticky footer) and the animated progress-dot row.

**Files:**
- Create: `lib/ui/features/onboarding/views/widgets/onboarding_progress.dart`
- Create: `lib/ui/features/onboarding/views/widgets/onboarding_scaffold.dart`
- Test: `test/ui/features/onboarding/views/widgets/onboarding_chrome_test.dart`

**Contract:**

```dart
// onboarding_progress.dart
class OnboardingProgress extends StatelessWidget {
  const OnboardingProgress({required this.step, required this.total, super.key});
  final int step;   // 0-based current
  final int total;  // dot count
}

// onboarding_scaffold.dart
class OnboardingScaffold extends StatelessWidget {
  const OnboardingScaffold({
    required this.body,
    required this.footer,
    this.step,        // null on Welcome → wordmark instead of back+dots
    this.total = 6,
    this.onBack,      // null hides the back button
    super.key,
  });
  final Widget body;     // fills the flex region (no built-in scroll)
  final Widget footer;   // sticky bottom region (CTAs)
  final int? step;
  final int total;
  final VoidCallback? onBack;
}
```

`OnboardingProgress` renders a `Row` of `total` dots: current dot width `Spacing.lg`, others `Spacing.sm`, height `3`, `Radii.full`; dots `<= step` use `colors.primary`, the rest `colors.primary.withValues(alpha: 0.15)`; wrap each in `AnimatedContainer(duration: Durations.base)`.

`OnboardingScaffold` is a `Column` on a `colors.surface` background inside a `Scaffold`:
- top bar (height ≥ `Spacing.xxl`, padding `Spacing.lg`): when `step == null` → centered "Crudo" wordmark (`CrudoText.headlineSm`, `colors.primarySoft`); else a `Row` of [back `IconButton(Icons.arrow_back_ios_new)` shown only if `onBack != null`, else `SizedBox(width: Spacing.xl)`] · `OnboardingProgress(step: step!, total: total)` · trailing `SizedBox(width: Spacing.xl)`.
- `Expanded(child: Padding(EdgeInsets.symmetric(horizontal: Spacing.lg), child: body))`.
- footer: `Padding(EdgeInsets.fromLTRB(Spacing.lg, Spacing.md, Spacing.lg, Spacing.xl), child: footer)`.

- [ ] **Step 1: Write the failing test**

```dart
import 'package:checks/checks.dart';
import 'package:crudo/ui/core/themes/theme.dart';
import 'package:crudo/ui/features/onboarding/views/widgets/onboarding_progress.dart';
import 'package:crudo/ui/features/onboarding/views/widgets/onboarding_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pump(WidgetTester t, Widget child) => t.pumpWidget(
        MaterialApp(theme: crudoTheme, home: child),
      );

  testWidgets('progress renders `total` dots', (t) async {
    await pump(t, const Scaffold(body: OnboardingProgress(step: 2, total: 6)));
    check(find.byType(AnimatedContainer).evaluate().length).equals(6);
  });

  testWidgets('scaffold shows wordmark when step is null, no back button', (t) async {
    await pump(t, const OnboardingScaffold(
      step: null, body: SizedBox(), footer: SizedBox(),
    ));
    check(find.text('Crudo').evaluate()).isNotEmpty();
    check(find.byIcon(Icons.arrow_back_ios_new).evaluate()).isEmpty();
  });

  testWidgets('scaffold shows back button + dots when step set and onBack given', (t) async {
    var backed = false;
    await pump(t, OnboardingScaffold(
      step: 1, onBack: () => backed = true,
      body: const SizedBox(), footer: const SizedBox(),
    ));
    check(find.byType(OnboardingProgress).evaluate()).isNotEmpty();
    await t.tap(find.byIcon(Icons.arrow_back_ios_new));
    check(backed).isTrue();
  });
}
```

- [ ] **Step 2: Run, verify fail** — `flutter test test/ui/features/onboarding/views/widgets/onboarding_chrome_test.dart --timeout=90s` → FAIL (missing widgets).
- [ ] **Step 3: Implement** both widgets per Contract.
- [ ] **Step 4: Run, verify pass** → PASS (3 tests).

**Skills:** `.agents/skills/flutter-add-widget-test`, `.agents/skills/flutter-expert`. Design system: AGENTS.md (4px grid, tokens only, no 1px borders, never pure black).

**Acceptance:** 3 tests green; tokens only (no raw px/rgb); wordmark vs back+dots switches on `step == null`.

**Out of scope:** the `PageView`/host (T7); any page content; importing `OnboardingController`.

---

## Task 3: WelcomePage

**Role:** ui

**Goal:** The first screen — wordmark, three decorative hero cards, headline + sub, primary "Set up my plan", secondary "I already have an account". No `OnboardingScaffold` (bespoke wordmark-centered layout).

**Files:**
- Create: `lib/ui/features/onboarding/views/pages/welcome_page.dart`
- Test: `test/ui/features/onboarding/views/pages/welcome_page_test.dart`

**Contract:** `WelcomePage({required VoidCallback onSetUp, required VoidCallback onSignIn})`.

Layout (Column on `colors.surface`): centered "Crudo" wordmark (`CrudoText.display`-ish, use `headline` + `colors.primary`); a fixed-height hero stack of three cards (each `surfaceLowest`, `Radii.lg`, `Shadows.cloud`, a leading accent bar + time label + meal name + a trailing status glyph) — Protein Bowl `08:00 AM` done (primarySoft bar, check glyph), Quinoa Salad `12:30 → 13:15` snoozed (gold bar, gold time strike-through), Baked Salmon `07:00 PM` pending (muted bar, hollow circle); headline "Follow your meal plan without overthinking" (`CrudoText.displaySm`, centered); sub "Build your meals once, get reminded on time, keep your streak alive." (`CrudoText.body`, centered); footer `PrimaryCta(label: 'Set up my plan', onPressed: onSetUp)` + a centered `TextButton('I already have an account', onPressed: onSignIn)` (label `CrudoText.labelMd`, `colors.onSurfaceMut`). Hero cards are decorative — no interaction.

- [ ] **Step 1: Write the failing test**

```dart
import 'package:checks/checks.dart';
import 'package:crudo/ui/core/themes/theme.dart';
import 'package:crudo/ui/core/widgets/primary_cta.dart';
import 'package:crudo/ui/features/onboarding/views/pages/welcome_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders headline and fires both callbacks', (t) async {
    var setUp = false, signIn = false;
    await t.pumpWidget(MaterialApp(
      theme: crudoTheme,
      home: WelcomePage(onSetUp: () => setUp = true, onSignIn: () => signIn = true),
    ));
    check(find.textContaining('Follow your meal plan').evaluate()).isNotEmpty();

    await t.tap(find.widgetWithText(PrimaryCta, 'Set up my plan'));
    check(setUp).isTrue();

    await t.tap(find.text('I already have an account'));
    check(signIn).isTrue();
  });
}
```

- [ ] **Step 2: Run, verify fail** — `flutter test test/ui/features/onboarding/views/pages/welcome_page_test.dart --timeout=90s` → FAIL.
- [ ] **Step 3: Implement** `welcome_page.dart` per Contract.
- [ ] **Step 4: Run, verify pass** → PASS.

**Skills:** `.agents/skills/flutter-add-widget-test`, `.agents/skills/flutter-expert`. Design system: AGENTS.md (4px grid, tokens only, no 1px borders, never pure black).

**Acceptance:** headline + both CTAs render; taps fire callbacks; tokens only; hero cards non-interactive.

**Out of scope:** navigation/host wiring (T7); `OnboardingScaffold` (Welcome is bespoke, no scaffold); any provider import.

---

## Task 4: AwarenessPage + StructurePage (pain screens)

**Role:** ui

**Goal:** Two presentational screens inside `OnboardingScaffold`, each with a Continue (`onContinue`) and Back (`onBack`).

**Files:**
- Create: `lib/ui/features/onboarding/views/pages/awareness_page.dart`
- Create: `lib/ui/features/onboarding/views/pages/structure_page.dart`
- Test: `test/ui/features/onboarding/views/pages/pain_pages_test.dart`

**Contract:**

```dart
AwarenessPage({required VoidCallback onContinue, required VoidCallback onBack});  // step: 0
StructurePage({required VoidCallback onContinue, required VoidCallback onBack});  // step: 1
```

`AwarenessPage` — `OnboardingScaffold(step: 0, total: 6, onBack: onBack, footer: PrimaryCta('Continue', onContinue), body:)`: headline "You already know the plan." (`CrudoText.displaySm`), sub "The struggle isn't information — it's the friction of modern life." (`CrudoText.body`), then a column of three `surfaceLowest`/`Radii.md`/`Shadows.cloud` cards — title (`CrudoText.title`) + body (`CrudoText.body`):
- "Skipped Meals" / "Days fly by — meals get forgotten."
- "Lost Momentum" / "One missed meal cascades into a derailed day."
- "Decision Fatigue" / "\"What should I eat now?\" drains willpower."

`StructurePage` — `OnboardingScaffold(step: 1, ...)`: headline "Structure beats willpower.", sub "Crudo holds the rhythm so you don't have to."; a "WITHOUT STRUCTURE" label (`CrudoText.label`, `colors.error`) over two rows (Skipped breakfast · "Too busy"; Random snacking · "Sugar spike") with an error-tinted leading glyph; a centered "VS" chip; a "WITH CRUDO" label (`colors.primary`) over two rows (High-protein morning · "08:00 AM"; Planned fuel · "01:00 PM") with a primary check glyph. Footer `PrimaryCta('Continue', onContinue)`.

- [ ] **Step 1: Write the failing test**

```dart
import 'package:checks/checks.dart';
import 'package:crudo/ui/core/themes/theme.dart';
import 'package:crudo/ui/core/widgets/primary_cta.dart';
import 'package:crudo/ui/features/onboarding/views/pages/awareness_page.dart';
import 'package:crudo/ui/features/onboarding/views/pages/structure_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pump(WidgetTester t, Widget c) =>
      t.pumpWidget(MaterialApp(theme: crudoTheme, home: c));

  testWidgets('awareness renders copy + continue/back fire', (t) async {
    var cont = false, back = false;
    await pump(t, AwarenessPage(onContinue: () => cont = true, onBack: () => back = true));
    check(find.text('You already know the plan.').evaluate()).isNotEmpty();
    check(find.text('Decision Fatigue').evaluate()).isNotEmpty();
    await t.tap(find.widgetWithText(PrimaryCta, 'Continue'));
    check(cont).isTrue();
    await t.tap(find.byIcon(Icons.arrow_back_ios_new));
    check(back).isTrue();
  });

  testWidgets('structure renders both columns', (t) async {
    await pump(t, StructurePage(onContinue: () {}, onBack: () {}));
    check(find.text('Structure beats willpower.').evaluate()).isNotEmpty();
    check(find.text('WITHOUT STRUCTURE').evaluate()).isNotEmpty();
    check(find.text('WITH CRUDO').evaluate()).isNotEmpty();
  });
}
```

- [ ] **Step 2: Run, verify fail** — `flutter test test/ui/features/onboarding/views/pages/pain_pages_test.dart --timeout=90s` → FAIL.
- [ ] **Step 3: Implement** both pages per Contract.
- [ ] **Step 4: Run, verify pass** → PASS.

**Skills:** `.agents/skills/flutter-add-widget-test`, `.agents/skills/flutter-expert`. Design system: AGENTS.md (4px grid, tokens only, no 1px borders, never pure black).

**Acceptance:** both pages render the verbatim copy; Continue/Back fire; tokens only; both wrap `OnboardingScaffold` with the right `step`.

**Out of scope:** host/`PageView` (T7); other pages; any provider import.

---

## Task 5: VideoDemoPage + TransformationPage

**Role:** ui

**Goal:** The demo placeholder (no asset — play tap is a stub via `onPlay`) and the transformation stats/features screen.

**Files:**
- Create: `lib/ui/features/onboarding/views/pages/video_demo_page.dart`
- Create: `lib/ui/features/onboarding/views/pages/transformation_page.dart`
- Test: `test/ui/features/onboarding/views/pages/value_pages_test.dart`

**Contract:**

```dart
VideoDemoPage({required VoidCallback onPlay, required VoidCallback onContinue, required VoidCallback onBack});  // step: 2
TransformationPage({required VoidCallback onContinue, required VoidCallback onBack});                          // step: 3
```

`VideoDemoPage` — `OnboardingScaffold(step: 2, ...)`: kicker "60 SECOND TOUR" (`CrudoText.label`, `colors.primarySoft`), headline "See how Crudo works", sub "Plans, reminders, snoozing — the daily loop, in under a minute."; a centered 9:16 placeholder (`AspectRatio(9/16)`, `Radii.lg`, primary→primarySoft gradient, `Shadows.cloudDeep`) holding a tappable play disc (`GestureDetector(onTap: onPlay)` → white circle + `Icons.play_arrow`, key `ValueKey('demo-play')`), a "0:58" duration pill, a "DEMO" tag. Footer `PrimaryCta('Watch & Continue', onContinue)`.

`TransformationPage` — `OnboardingScaffold(step: 3, ...)`: headline "Turn your plan into a routine.", sub "Ingredients, gram amounts, reminders, and quick check-ins help you stay on track every day."; a 3-up stat row (`surfaceLowest`/`Radii.md` tiles) — 3× "Consistency"/"vs no system", 87% "Adherence"/"avg week 2", 21d "Habit"/"with reminders" (figure `CrudoText.headline`/`colors.primary`); a feature list (numbered `01/02/03` chips, `primaryContainer` bg) — "Smart reminders"/"Nudges at the right moment, not just a fixed time.", "Structured plans"/"Assign meals to days. Crudo tracks what is next.", "Flexible snoozing"/"Push a meal forward without losing your streak.". Footer `PrimaryCta('Build my plan', onContinue)`.

- [ ] **Step 1: Write the failing test**

```dart
import 'package:checks/checks.dart';
import 'package:crudo/ui/core/themes/theme.dart';
import 'package:crudo/ui/core/widgets/primary_cta.dart';
import 'package:crudo/ui/features/onboarding/views/pages/transformation_page.dart';
import 'package:crudo/ui/features/onboarding/views/pages/video_demo_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pump(WidgetTester t, Widget c) =>
      t.pumpWidget(MaterialApp(theme: crudoTheme, home: c));

  testWidgets('video demo play tap fires onPlay, continue fires', (t) async {
    var played = false, cont = false;
    await pump(t, VideoDemoPage(
      onPlay: () => played = true, onContinue: () => cont = true, onBack: () {},
    ));
    check(find.text('See how Crudo works').evaluate()).isNotEmpty();
    await t.tap(find.byKey(const ValueKey('demo-play')));
    check(played).isTrue();
    await t.tap(find.widgetWithText(PrimaryCta, 'Watch & Continue'));
    check(cont).isTrue();
  });

  testWidgets('transformation renders stats + features', (t) async {
    await pump(t, TransformationPage(onContinue: () {}, onBack: () {}));
    check(find.text('Turn your plan into a routine.').evaluate()).isNotEmpty();
    check(find.text('Smart reminders').evaluate()).isNotEmpty();
    check(find.textContaining('87%').evaluate()).isNotEmpty();
  });
}
```

- [ ] **Step 2: Run, verify fail** — `flutter test test/ui/features/onboarding/views/pages/value_pages_test.dart --timeout=90s` → FAIL.
- [ ] **Step 3: Implement** both pages per Contract.
- [ ] **Step 4: Run, verify pass** → PASS.

**Skills:** `.agents/skills/flutter-add-widget-test`, `.agents/skills/flutter-expert`. Design system: AGENTS.md (4px grid, tokens only, no 1px borders, never pure black).

**Acceptance:** demo play disc keyed + fires `onPlay`; both CTAs fire; transformation copy/stats render; no video asset referenced.

**Out of scope:** real video playback / asset bundling; host/`PageView` (T7); other pages; any provider import.

---

## Task 6: HeardAboutPage + TriedAppsPage (surveys)

**Role:** ui

**Goal:** Two single-select survey screens using `SelectionCard`; Continue disabled until a selection; selection reported via `onSelect`.

**Files:**
- Create: `lib/ui/features/onboarding/views/pages/heard_about_page.dart`
- Create: `lib/ui/features/onboarding/views/pages/tried_apps_page.dart`
- Test: `test/ui/features/onboarding/views/pages/survey_pages_test.dart`

**Contract:**

```dart
const kHeardAboutOptions = <({String id, String label})>[
  (id: 'tiktok', label: 'TikTok'),
  (id: 'instagram', label: 'Instagram'),
  (id: 'youtube', label: 'YouTube'),
  (id: 'reddit', label: 'Reddit'),
  (id: 'friend', label: 'Friend / family'),
  (id: 'search', label: 'App store / search'),
  (id: 'press', label: 'Press / blog'),
  (id: 'other', label: 'Somewhere else'),
];

const kTriedAppsOptions = <({String id, String label, String sub})>[
  (id: 'mfp', label: 'MyFitnessPal', sub: 'Calorie & macro logger'),
  (id: 'noom', label: 'Noom', sub: 'Behavioural coaching'),
  (id: 'lose', label: 'Lose It! / Cronometer', sub: 'Calorie tracking'),
  (id: 'planner', label: 'Mealime / Eat This Much', sub: 'Recipe planners'),
  (id: 'multi', label: 'A few of these', sub: 'And kept switching'),
  (id: 'none', label: 'No, this is my first', sub: 'Fresh start'),
];

HeardAboutPage({required String? selected, required ValueChanged<String> onSelect,
                required VoidCallback onContinue, required VoidCallback onBack});  // step: 4
TriedAppsPage({required String? selected, required ValueChanged<String> onSelect,
               required VoidCallback onContinue, required VoidCallback onBack});   // step: 5
```

`HeardAboutPage` — `OnboardingScaffold(step: 4, ...)`: kicker "QUICK ONE", headline "Where did you hear about Crudo?", sub "Helps us know what's working. Pick one."; a 2-column grid of `SelectionCard`s over `kHeardAboutOptions` (`selected: o.id == selected`, `onTap: () => onSelect(o.id)`). Footer `PrimaryCta('Continue', selected == null ? null : onContinue, enabled: selected != null)`.

`TriedAppsPage` — `OnboardingScaffold(step: 5, ...)`: kicker "ONE MORE", headline "Tried something like this before?", sub "No judgement — most of us have a graveyard of nutrition apps. Pick the closest."; a single-column list of `SelectionCard`s over `kTriedAppsOptions` (`subtitle: o.sub`, trailing radio dot). Footer `PrimaryCta('Continue', selected == null ? null : onContinue, enabled: selected != null)`.

- [ ] **Step 1: Write the failing test**

```dart
import 'package:checks/checks.dart';
import 'package:crudo/ui/core/themes/theme.dart';
import 'package:crudo/ui/core/widgets/primary_cta.dart';
import 'package:crudo/ui/features/onboarding/views/pages/heard_about_page.dart';
import 'package:crudo/ui/features/onboarding/views/pages/tried_apps_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pump(WidgetTester t, Widget c) =>
      t.pumpWidget(MaterialApp(theme: crudoTheme, home: c));

  testWidgets('heard-about: select fires onSelect; continue gated then fires', (t) async {
    String? picked;
    var cont = false;
    // initially unselected → continue disabled (no callback on tap)
    await pump(t, HeardAboutPage(
      selected: null, onSelect: (id) => picked = id,
      onContinue: () => cont = true, onBack: () {},
    ));
    await t.tap(find.widgetWithText(PrimaryCta, 'Continue'));
    check(cont).isFalse();
    await t.tap(find.text('TikTok'));
    check(picked).equals('tiktok');

    // re-pump as if host passed the new selection → continue now enabled
    await pump(t, HeardAboutPage(
      selected: 'tiktok', onSelect: (_) {},
      onContinue: () => cont = true, onBack: () {},
    ));
    await t.tap(find.widgetWithText(PrimaryCta, 'Continue'));
    check(cont).isTrue();
  });

  testWidgets('tried-apps renders options with subs', (t) async {
    String? picked;
    await pump(t, TriedAppsPage(
      selected: null, onSelect: (id) => picked = id, onContinue: () {}, onBack: () {},
    ));
    check(find.text('MyFitnessPal').evaluate()).isNotEmpty();
    check(find.text('Calorie & macro logger').evaluate()).isNotEmpty();
    await t.tap(find.text('Noom'));
    check(picked).equals('noom');
  });
}
```

- [ ] **Step 2: Run, verify fail** — `flutter test test/ui/features/onboarding/views/pages/survey_pages_test.dart --timeout=90s` → FAIL.
- [ ] **Step 3: Implement** both pages + the two const option lists per Contract.
- [ ] **Step 4: Run, verify pass** → PASS.

**Skills:** `.agents/skills/flutter-add-widget-test`, `.agents/skills/flutter-expert`. Design system: AGENTS.md (4px grid, tokens only, no 1px borders, never pure black).

**Acceptance:** both option lists complete & verbatim; selection reports the id; Continue is inert until `selected != null`, then fires; tokens only.

**Out of scope:** holding selection state in the page (host owns it via controller — pages are stateless); host/`PageView` (T7); any provider import; persisting the answer.

---

## Task 7: OnboardingFlowScreen + route + end-to-end test

**Role:** ui

**Goal:** Host the seven pages in a button-driven `PageView` bound to `OnboardingController`; wire Back/Continue and the toast stubs; register `/onboarding`. Verify the whole flow end-to-end.

**Files:**
- Create: `lib/ui/features/onboarding/views/onboarding_flow_screen.dart`
- Modify: `lib/routing/app_router.dart` (add the `/onboarding` `GoRoute`)
- Test: `test/ui/features/onboarding/views/onboarding_flow_screen_test.dart`

**Contract:**

```dart
class OnboardingFlowScreen extends ConsumerStatefulWidget {
  const OnboardingFlowScreen({super.key});
}
```

Behavior:
- Owns a `PageController`. In `build`, `ref.listen(onboardingControllerProvider.select((s) => s.pageIndex), ...)` → `_controller.animateToPage(i, duration: Durations.base, curve: Curves.easeInOut)`. `PageView(controller:, physics: const NeverScrollableScrollPhysics(), children: [...7 pages...])`.
- Read `final st = ref.watch(onboardingControllerProvider); final c = ref.read(onboardingControllerProvider.notifier);`
- Page wiring:
  - `WelcomePage(onSetUp: c.next, onSignIn: () => showCrudoToast(context, 'Sign-in coming soon', body: 'Accounts arrive in a later update.'))`
  - `AwarenessPage(onContinue: c.next, onBack: _back)`
  - `StructurePage(onContinue: c.next, onBack: _back)`
  - `VideoDemoPage(onPlay: () => showCrudoToast(context, 'Demo video coming soon'), onContinue: c.next, onBack: _back)`
  - `TransformationPage(onContinue: c.next, onBack: _back)`
  - `HeardAboutPage(selected: st.source, onSelect: c.setSource, onContinue: c.next, onBack: _back)`
  - `TriedAppsPage(selected: st.tried, onSelect: c.setTried, onContinue: _finish, onBack: _back)`
- `void _back()` → `if (st.pageIndex == 0) Navigator.of(context).pop(); else c.back();` (Welcome's own Back is N/A — Welcome has no back; the first scaffold Back is on Awareness, page 1, so `_back` from page 1 calls `c.back()` → page 0 Welcome. Popping the route only happens if `_back` is ever invoked at index 0, kept as a guard.)
- `void _finish()` → `showCrudoToast(context, 'Plan setup comes next', body: 'Building your first plan is the next step.'); Navigator.of(context).maybePop();`
- Dispose the `PageController`.

`app_router.dart` — add after the `/foods` route (dev-reachable group), no change to `initialLocation`:

```dart
GoRoute(
  path: '/onboarding',
  builder: (context, state) => const OnboardingFlowScreen(),
),
```

- [ ] **Step 1: Write the failing test**

```dart
import 'package:checks/checks.dart';
import 'package:crudo/ui/core/themes/theme.dart';
import 'package:crudo/ui/core/widgets/primary_cta.dart';
import 'package:crudo/ui/features/onboarding/views/onboarding_flow_screen.dart';
import 'package:crudo/ui/features/onboarding/views/pages/awareness_page.dart';
import 'package:crudo/ui/features/onboarding/views/pages/heard_about_page.dart';
import 'package:crudo/ui/features/onboarding/views/pages/structure_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pump(WidgetTester t) => t.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: crudoTheme,
            home: const OnboardingFlowScreen(),
          ),
        ),
      );

  // A `PageView` builds the cached neighbour page too, so several pages render
  // a "Continue" PrimaryCta at once. Scope the tap to the visible page's type,
  // never a bare `find.widgetWithText(PrimaryCta, 'Continue')` (matches >1).
  Finder ctaOn(Type page, String label) => find.descendant(
        of: find.byType(page),
        matching: find.widgetWithText(PrimaryCta, label),
      );

  testWidgets('advances Welcome → … → terminal via CTAs', (t) async {
    await pump(t);
    check(find.textContaining('Follow your meal plan').evaluate()).isNotEmpty();

    await t.tap(find.widgetWithText(PrimaryCta, 'Set up my plan'));
    await t.pumpAndSettle();
    check(find.text('You already know the plan.').evaluate()).isNotEmpty();

    await t.tap(ctaOn(AwarenessPage, 'Continue'));
    await t.pumpAndSettle();
    check(find.text('Structure beats willpower.').evaluate()).isNotEmpty();

    await t.tap(ctaOn(StructurePage, 'Continue'));
    await t.pumpAndSettle();
    check(find.text('See how Crudo works').evaluate()).isNotEmpty();

    await t.tap(find.widgetWithText(PrimaryCta, 'Watch & Continue'));
    await t.pumpAndSettle();
    check(find.text('Turn your plan into a routine.').evaluate()).isNotEmpty();

    await t.tap(find.widgetWithText(PrimaryCta, 'Build my plan'));
    await t.pumpAndSettle();
    check(find.text('Where did you hear about Crudo?').evaluate()).isNotEmpty();

    await t.tap(find.text('TikTok'));
    await t.pumpAndSettle();
    await t.tap(ctaOn(HeardAboutPage, 'Continue'));
    await t.pumpAndSettle();
    check(find.text('Tried something like this before?').evaluate()).isNotEmpty();
  });

  testWidgets('back from Awareness returns to Welcome', (t) async {
    await pump(t);
    await t.tap(find.widgetWithText(PrimaryCta, 'Set up my plan'));
    await t.pumpAndSettle();
    await t.tap(find.byIcon(Icons.arrow_back_ios_new));
    await t.pumpAndSettle();
    check(find.textContaining('Follow your meal plan').evaluate()).isNotEmpty();
  });

  testWidgets('heard-about Continue gated until a selection', (t) async {
    await pump(t);
    await t.tap(find.widgetWithText(PrimaryCta, 'Set up my plan'));
    await t.pumpAndSettle();
    await t.tap(ctaOn(AwarenessPage, 'Continue'));
    await t.pumpAndSettle();
    await t.tap(ctaOn(StructurePage, 'Continue'));
    await t.pumpAndSettle();
    await t.tap(find.widgetWithText(PrimaryCta, 'Watch & Continue'));
    await t.pumpAndSettle();
    await t.tap(find.widgetWithText(PrimaryCta, 'Build my plan'));
    await t.pumpAndSettle();
    // no selection → Continue does nothing
    await t.tap(ctaOn(HeardAboutPage, 'Continue'));
    await t.pumpAndSettle();
    check(find.text('Where did you hear about Crudo?').evaluate()).isNotEmpty(); // still here
    await t.tap(find.text('Reddit'));
    await t.pumpAndSettle();
    await t.tap(ctaOn(HeardAboutPage, 'Continue'));
    await t.pumpAndSettle();
    check(find.text('Tried something like this before?').evaluate()).isNotEmpty();
  });

  testWidgets('stubs fire toasts and do not navigate', (t) async {
    await pump(t);
    // Welcome secondary → sign-in stub toast, still on Welcome.
    await t.tap(find.text('I already have an account'));
    await t.pump(); // toast inserts on the overlay
    check(find.text('Sign-in coming soon').evaluate()).isNotEmpty();
    check(find.textContaining('Follow your meal plan').evaluate()).isNotEmpty();
    // Flush the toast's auto-dismiss timer so the test ends clean (house pattern).
    await t.pump(const Duration(seconds: 5));
  });
}
```

- [ ] **Step 2: Run, verify fail** — `flutter test test/ui/features/onboarding/views/onboarding_flow_screen_test.dart --timeout=90s` → FAIL (host missing).
- [ ] **Step 3: Implement** `onboarding_flow_screen.dart` per Contract; add the `/onboarding` route to `app_router.dart`.
- [ ] **Step 4: Run, verify pass** — flow test → PASS (4 tests: advance, back, gating, stub-fire).
- [ ] **Step 5: Full suite** — `flutter test --timeout=90s` → all green (609 prior + new).

**Skills:** `.agents/skills/flutter-riverpod`, `.agents/skills/flutter-add-widget-test`, `.agents/skills/flutter-setup-declarative-routing`, `.agents/skills/flutter-expert`.

**Acceptance:** flow advances Welcome→TriedApps via CTAs; Back steps back (Awareness→Welcome); survey Continue gated until selection; the sign-in stub shows a toast without navigating; `/onboarding` registered, `initialLocation` unchanged; full suite green.

**Out of scope (do not add):** first-launch redirect/gate, persisted "seen" flag, real video asset, sign-in screen, setup screens 8–11, analytics submission. Stubs stay toasts.

---

## Self-review

- **Spec coverage:** 7 screens → T3 (Welcome), T4 (Awareness/Structure), T5 (VideoDemo/Transformation), T6 (HeardAbout/TriedApps); controller/in-memory state → T1; PageView host + route + stubs + terminal pop → T7; progress dots + scaffold → T2. Tokens-not-px, gating, no-gate, no-persist all asserted in tasks. ✓
- **Type consistency:** `OnboardingState`/`OnboardingController` (T1) used by host (T7); page APIs in the shared contract match each task's Contract and the T7 wiring; `kHeardAboutOptions`/`kTriedAppsOptions` (T6) consumed only inside their pages. `PrimaryCta(onPressed:)` passed `null` when disabled (matches the verbatim contract). ✓
- **Placeholder scan:** none — every step has real code + exact commands. ✓
