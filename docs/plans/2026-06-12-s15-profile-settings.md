# Plan — S15: Profile & settings

> **Worker note:** Implements `docs/specs/2026-06-12-s15-profile-settings.md`. Each `## Task N:` is self-contained — read `AGENTS.md`, your role file, and the named `.agents/skills/*` before starting. TDD + gates per task, **no commits** (end at "report for review"). `package:checks` for assertions; **every** `flutter test` carries `--timeout=90s`; wrap `build_runner` in `gtimeout 600` (or plain `timeout 600` on Linux/CI; macOS needs coreutils — if absent, run `dart run build_runner build` directly and watch it).

**Goal:** Build the real Profile tab: a command `ProfileController` that edits `Prefs`/`displayName` through `ProfileRepository`, per-setting bottom sheets (Notifications/Goal/Units/Threshold), an editable-name avatar header, a static subscription banner + display-only paywall, read-only badges, and a stubbed Sign out — replacing the placeholder `profile_screen.dart`.

**Architecture:** `ProfileController` is a **stateless command Notifier** — methods mutate via the repo; `ProfileRepository.save` re-emits through `watch()` → the existing `profileProvider` (`Stream<UserProfile>`) → the screen and open sheets re-render. No second source of truth, no screen-level Save. Settings rows open `showCrudoSheet` modals built on `SheetScaffold`. Editing `Prefs` re-colors S12 History (it already `ref.watch`es `profileProvider`) — **but S14's scheduler + risk providers read profile non-reactively (`.watch().first`), so Task 7 switches them to watch `profileProvider`** so a prefs edit actually re-arms notifications. Without Task 7 the RemindersSheet is cosmetic until the next day-change.

**Tech stack:** Flutter, Riverpod 3.x (`@riverpod`), freezed 3.x (`copyWith`), `package:checks`. No new packages. No `Prefs`/model changes.

## Decisions (from spec brainstorm 2026-06-12)

| Fork | Decision |
|---|---|
| Editing UX | Bottom sheet per setting (`showCrudoSheet` + `SheetScaffold`). |
| Scope extras | Subscription banner + Badges + editable display name (on top of roadmap core). |
| Streak-pref toggles | OMITTED (partial/weekend not modeled; weekend-skip post-MVP). No `Prefs` change. |
| Sign-out / subscription | `signOut` = local profile reset (real auth S22); subscription static + display-only `PaywallSheet` (real billing S25). |
| Display name | Editable via sheet; email deferred to S22. |
| Goal | Edits `Goal` enum + optional `dailyKcalTarget`. |
| Threshold | 70/80/90/100, default 80. |
| Persistence | Command controller; every edit saves immediately; `profileProvider` re-emits. |

## File changes (map)

- **Create** `lib/ui/features/profile/view_models/profile_controller.dart` (+ `.g.dart`) — `ProfileController` (T1)
- **Create** `lib/ui/core/widgets/settings_section.dart` — `SettingsSection`, `SettingsRow` (T2)
- **Create** `lib/ui/core/widgets/crudo_toggle.dart` — `CrudoToggle` (T2)
- **Create** `lib/ui/core/widgets/crudo_stepper.dart` — `CrudoStepper` (T2)
- **Create** `lib/ui/features/profile/views/units_sheet.dart`, `threshold_sheet.dart` — single-choice sheets (T3)
- **Create** `lib/ui/features/profile/views/reminders_sheet.dart`, `goal_sheet.dart`, `display_name_sheet.dart` — multi-field sheets (T4)
- **Create** `lib/ui/features/profile/views/logout_confirm_sheet.dart`, `paywall_sheet.dart` — stubs (T5)
- **Rewrite** `lib/ui/features/profile/views/profile_screen.dart` — the screen (T6)
- **Modify** `lib/ui/features/today/view_models/notification_scheduler_controller.dart` + `streak_at_risk_provider.dart` — make profile reactive (T7)
- **Tests** mirror each under `test/ui/features/profile/` and `test/ui/core/widgets/`

## Shared contract — reused symbols (verbatim)

```dart
// domain/shared/enums.dart
enum Goal { cut, maintain, bulk }
enum Unit { g, oz }
// domain/profile/prefs.dart — Prefs fields touched:
//   Goal goal, Unit units, int? dailyKcalTarget, int streakThreshold,
//   bool preOn/atOn/eodOn/riskOn, int preMin
// domain/profile/user_profile.dart: UserProfile({required String id, String? displayName, Prefs prefs})
// data/local_user.dart: const localUserId  (the seeded id)
// core/widgets/sheet.dart: Future<T?> showCrudoSheet<T>(BuildContext, {required WidgetBuilder builder});
//   class SheetScaffold({required String title, required Widget body, String? label, Widget? cta});
// core/widgets/toast.dart: void showCrudoToast(BuildContext, String title, {String? body});
// core/widgets/primary_cta.dart: PrimaryCta({required String label, required VoidCallback? onPressed, bool enabled = true});
//   NOTE: onPressed is REQUIRED (pass null when disabled). No `danger`/color param —
//   gradient is primary→primary-soft only. A destructive CTA = a custom button (error tone), built inline.
// today_providers.dart: Stream<UserProfile> profileProvider
// history_providers.dart: Stream<Streak> streakProvider   (reused for badges)
```

---

## Task 1: ProfileController (command controller)

**Role:** implement

**Goal:** A stateless `@riverpod` Notifier whose methods mutate `Prefs`/`displayName` via `ProfileRepository`; the repo's `watch()` propagates the change. No held state.

**Files:**
- Create: `lib/ui/features/profile/view_models/profile_controller.dart` (+ codegen `.g.dart`)
- Test: `test/ui/features/profile/profile_controller_test.dart`

**Contract:**

```dart
import 'package:crudo/config/di.dart';
import 'package:crudo/data/local_user.dart';
import 'package:crudo/domain/profile/prefs.dart';
import 'package:crudo/domain/profile/user_profile.dart';
import 'package:crudo/domain/shared/enums.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'profile_controller.g.dart';

/// Stateless command controller (S15). The screen reads profileProvider for
/// display; this only mutates. Each method reads the current profile, copyWith
/// one field, saves — ProfileRepository.save re-emits through watch().
@riverpod
class ProfileController extends _$ProfileController {
  @override
  void build() {}

  Future<void> _mutate(Prefs Function(Prefs) f) async {
    final repo = ref.read(profileRepositoryProvider);
    final p = await repo.get();
    await repo.save(p.copyWith(prefs: f(p.prefs)));
  }

  Future<void> setUnits(Unit units) => _mutate((p) => p.copyWith(units: units));

  Future<void> setGoal(Goal goal, {int? kcalTarget}) =>
      _mutate((p) => p.copyWith(goal: goal, dailyKcalTarget: kcalTarget));

  Future<void> setThreshold(int threshold) =>
      _mutate((p) => p.copyWith(streakThreshold: threshold));

  Future<void> setPreMin(int minutes) =>
      _mutate((p) => p.copyWith(preMin: minutes));

  Future<void> setNotifToggle({bool? pre, bool? at, bool? eod, bool? risk}) =>
      _mutate(
        (p) => p.copyWith(
          preOn: pre ?? p.preOn,
          atOn: at ?? p.atOn,
          eodOn: eod ?? p.eodOn,
          riskOn: risk ?? p.riskOn,
        ),
      );

  Future<void> setDisplayName(String name) async {
    final repo = ref.read(profileRepositoryProvider);
    await repo.save((await repo.get()).copyWith(displayName: name));
  }

  /// Local stub — real session teardown is S22.
  Future<void> signOut() => ref
      .read(profileRepositoryProvider)
      .save(const UserProfile(id: localUserId));
}
```

**Steps (TDD):**

- [ ] 1. **Failing test** — `profile_controller_test.dart` with `ProviderContainer` (override `profileRepositoryProvider` with a real `InMemoryProfileRepository`, or the default). Read `profileController.notifier`, call mutators, then assert via `profileRepositoryProvider.get()`: `setUnits(Unit.oz)` → `prefs.units == Unit.oz` and goal/threshold unchanged; `setThreshold(90)` → `90`; `setGoal(Goal.bulk, kcalTarget: 2200)` → goal+target both set; `setGoal(Goal.cut)` → `dailyKcalTarget == null` (cleared); `setNotifToggle(pre: false)` → `preOn == false`, others true; `setPreMin(25)` → `25`; `setDisplayName('Mark')` → `displayName == 'Mark'`; `signOut()` → profile equals `UserProfile(id: localUserId)` (prefs back to default).
- [ ] 2. **Run — red:** `flutter test --timeout=90s test/ui/features/profile/profile_controller_test.dart` → undefined `profileControllerProvider`.
- [ ] 3. **Implement** the contract; `gtimeout 600 dart run build_runner build`.
- [ ] 4. **Run — green:** same command.
- [ ] 5. Gates: `dart format .` · `flutter analyze` · `flutter test --timeout=90s`. Report for review.

**Skills:** `.agents/skills/flutter-riverpod-arch`, `.agents/skills/dart-add-unit-test`, `.agents/skills/dart-migrate-to-checks-package`.

**Out of scope:** any widget/sheet (T2–T6), `Prefs` model changes, real auth.

---

## Task 2: Shared settings widgets

**Role:** ui

**Goal:** The reusable building blocks the sheets + screen need: a titled section, a tappable row, a styled toggle, a stepper. Tokens only, 4px grid, no 1px borders.

**Files:**
- Create: `lib/ui/core/widgets/settings_section.dart` (`SettingsSection`, `SettingsRow`)
- Create: `lib/ui/core/widgets/crudo_toggle.dart` (`CrudoToggle`)
- Create: `lib/ui/core/widgets/crudo_stepper.dart` (`CrudoStepper`)
- Test: `test/ui/core/widgets/settings_widgets_test.dart`

**Contract:**

```dart
// settings_section.dart
class SettingsSection extends StatelessWidget {
  const SettingsSection({required this.title, required this.children, super.key});
  final String title;            // uppercase kicker
  final List<Widget> children;   // SettingsRows, wrapped in a surfaceLowest card
}

class SettingsRow extends StatelessWidget {
  const SettingsRow({
    required this.label,
    this.subtitle,
    this.trailing,               // chevron / CrudoToggle; default = chevron when onTap != null
    this.onTap,
    super.key,
  });
  final String label;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
}

// crudo_toggle.dart — styled Switch (primary/gold active track), no Material default.
class CrudoToggle extends StatelessWidget {
  const CrudoToggle({required this.value, required this.onChanged, super.key});
  final bool value;
  final ValueChanged<bool> onChanged;
}

// crudo_stepper.dart — "− value suffix +", clamps to [min,max] by step.
class CrudoStepper extends StatelessWidget {
  const CrudoStepper({
    required this.value,
    required this.onChanged,
    required this.min,
    required this.max,
    this.step = 1,
    this.suffix = '',
    super.key,
  });
  final int value;
  final ValueChanged<int> onChanged;
  final int min;
  final int max;
  final int step;
  final String suffix;
}
```

**Steps (TDD):**

- [ ] 1. **Failing test** — `settings_widgets_test.dart`: pump each widget in a themed `MaterialApp`. `SettingsRow` with `onTap` → tap fires the callback + renders label/subtitle; `CrudoToggle(value: false)` → tap calls `onChanged(true)`; `CrudoStepper(value: 30, min: 5, max: 60, step: 5)` → "+" calls `onChanged(35)`, at `max` "+" is a no-op (stays 60), "−" → 25; renders "30m" with `suffix: 'm'`.
- [ ] 2. **Run — red:** `flutter test --timeout=90s test/ui/core/widgets/settings_widgets_test.dart` → undefined widgets.
- [ ] 3. **Implement** the three files (no codegen). Use `CrudoColors`/`CrudoText`/`Spacing`/`Radii`/`IconSizes` from `core/themes/`. Section card = `surfaceLowest` + `Radii.lg`; rows separated by vertical padding (no dividers). Active toggle track = `colors.primary` (or gold per design); chevron = `Icons.chevron_right` at `IconSizes`.
- [ ] 4. **Run — green:** same command.
- [ ] 5. Gates: `dart format .` · `flutter analyze` · `flutter test --timeout=90s`. Report for review.

**Skills:** `.agents/skills/flutter-add-widget-test`, `.agents/skills/flutter-expert`. Design system: AGENTS.md (4px grid, tokens, no 1px borders, never pure black).

**Out of scope:** the sheets/screen that consume these (T3–T6); `ProfileController` (T1).

---

## Task 3: Single-choice setting sheets (Units, Threshold)

**Role:** ui

**Goal:** Two save-on-tap bottom sheets. Reads current value from `profileProvider`, writes via `ProfileController`, pops.

**Files:**
- Create: `lib/ui/features/profile/views/units_sheet.dart` (`showUnitsSheet`)
- Create: `lib/ui/features/profile/views/threshold_sheet.dart` (`showThresholdSheet`)
- Test: `test/ui/features/profile/units_threshold_sheet_test.dart`

**Contract:**

```dart
// units_sheet.dart
Future<void> showUnitsSheet(BuildContext context) => showCrudoSheet<void>(
  context,
  builder: (_) => const _UnitsSheet(),
);
// _UnitsSheet (ConsumerWidget): SheetScaffold(title: 'Units', body: two SelectionCards
//   'Grams'(Unit.g) / 'Ounces'(Unit.oz), current = profileProvider.prefs.units).
//   onTap → ref.read(profileControllerProvider.notifier).setUnits(u); Navigator.pop.

// threshold_sheet.dart
Future<void> showThresholdSheet(BuildContext context) => showCrudoSheet<void>(
  context,
  builder: (_) => const _ThresholdSheet(),
);
// _ThresholdSheet: SheetScaffold(title: 'Streak threshold', label: 'GREEN LINE',
//   body: four SelectionCards 70/80/90/100 ('% of planned calories'),
//   current = prefs.streakThreshold). onTap → setThreshold(v); pop.
```

**Steps (TDD):**

- [ ] 1. **Failing test** — `units_threshold_sheet_test.dart`: pump a screen that opens each sheet (a button calling `showUnitsSheet`), seed `profileProvider` via an overridden in-memory repo. Tap "Ounces" → `profileProvider.prefs.units == Unit.oz` after pump + sheet dismissed. Tap "90%" → `streakThreshold == 90`. Current value shows selected.
- [ ] 2. **Run — red:** `flutter test --timeout=90s test/ui/features/profile/units_threshold_sheet_test.dart` → undefined `showUnitsSheet`.
- [ ] 3. **Implement** both sheets. Reuse `SelectionCard` (title/subtitle/selected/onTap). `await` the controller call before `Navigator.pop` so the test sees the write.
- [ ] 4. **Run — green:** same command.
- [ ] 5. Gates: `dart format .` · `flutter analyze` · `flutter test --timeout=90s`. Report for review.

**Skills:** `.agents/skills/flutter-riverpod-arch`, `.agents/skills/flutter-add-widget-test`, `.agents/skills/flutter-expert`.

**Out of scope:** Reminders/Goal/Name sheets (T4), screen (T6).

---

## Task 4: Multi-field sheets (Reminders, Goal, Display name)

**Role:** ui

**Goal:** Three sheets with multiple controls + a Save CTA. RemindersSheet is the S14 hand-off (4 toggles + lead stepper).

**Files:**
- Create: `lib/ui/features/profile/views/reminders_sheet.dart` (`showRemindersSheet`)
- Create: `lib/ui/features/profile/views/goal_sheet.dart` (`showGoalSheet`)
- Create: `lib/ui/features/profile/views/display_name_sheet.dart` (`showDisplayNameSheet`)
- Test: `test/ui/features/profile/multi_field_sheets_test.dart`

**Contract:**

```dart
// reminders_sheet.dart — 4 toggles + pre-meal lead stepper + Save.
Future<void> showRemindersSheet(BuildContext context) => showCrudoSheet<void>(
  context, builder: (_) => const _RemindersSheet());
// _RemindersSheet (ConsumerStatefulWidget — local draft of the 4 bools + preMin
//   seeded in initState from ref.read(profileProvider).requireValue.prefs —
//   safe: the screen only opens this row after profile has data):
//   SheetScaffold(label: 'NOTIFICATIONS',
//   title: 'How we ping you', body: 4 SettingsRows each trailing a CrudoToggle —
//   'Pre-meal heads up' (preOn) / 'At meal time' (atOn) /
//   'End of day summary' (eodOn) / 'Streak at risk' (riskOn) — plus a
//   'Pre-meal lead' row with a CrudoStepper(min:5,max:60,step:5,suffix:'m'),
//   cta: PrimaryCta('Save')). EXACTLY 4 toggles — NO 'No-action warning'
//   (folds into eod, no warnOn field). Lead default 30. Save →
//   setNotifToggle(pre:,at:,eod:,risk:) + setPreMin(lead); pop.

// goal_sheet.dart — Goal radio + kcal target stepper + Save.
Future<void> showGoalSheet(BuildContext context) => showCrudoSheet<void>(
  context, builder: (_) => const _GoalSheet());
// _GoalSheet (ConsumerStatefulWidget, draft Goal + int? target seeded in initState
//   from ref.read(profileProvider).requireValue.prefs):
//   3 SelectionCards Cut/Maintain/Bulk + a 'Daily target' row: a CrudoToggle
//   'Set a target' gating a CrudoStepper(min:1200,max:4000,step:50,suffix:' kcal');
//   enabling from a null target seeds the stepper to (dailyKcalTarget ?? 2000);
//   off → target null. cta Save → setGoal(goal, kcalTarget: enabled ? value : null); pop.

// display_name_sheet.dart — single TextField + Save.
Future<void> showDisplayNameSheet(BuildContext context) => showCrudoSheet<void>(
  context, builder: (_) => const _DisplayNameSheet());
// _DisplayNameSheet (ConsumerStatefulWidget, TextEditingController seeded from
//   displayName): SheetScaffold(title: 'Your name', body: TextField,
//   cta: PrimaryCta(label: 'Save', enabled: text.trim().isNotEmpty,
//     onPressed: text.trim().isEmpty ? null
//       : () async { await setDisplayName(text.trim()); pop; })).
```

**Steps (TDD):**

- [ ] 1. **Failing test** — `multi_field_sheets_test.dart` (seed via overridden in-memory repo): RemindersSheet — toggle "Pre-meal heads up" off, stepper "−" once (30→25), tap Save → `prefs.preOn == false` && `preMin == 25` && other toggles still true. Assert the sheet shows **4** toggles (no "No-action warning" — `find.text('No-action warning')` is `findsNothing`). GoalSheet — pick "Bulk", enable target, set 2200, Save → `goal == Goal.bulk` && `dailyKcalTarget == 2200`; with target toggle off → `dailyKcalTarget == null`. DisplayNameSheet — enter "Mark", Save → `displayName == 'Mark'`; empty → Save disabled.
- [ ] 2. **Run — red:** `flutter test --timeout=90s test/ui/features/profile/multi_field_sheets_test.dart` → undefined `showRemindersSheet`.
- [ ] 3. **Implement** the three sheets (local draft state → commit on Save). Use `CrudoToggle`/`CrudoStepper`/`SettingsRow`/`SelectionCard`.
- [ ] 4. **Run — green:** same command.
- [ ] 5. Gates: `dart format .` · `flutter analyze` · `flutter test --timeout=90s`. Report for review.

**Skills:** `.agents/skills/flutter-riverpod-arch`, `.agents/skills/flutter-add-widget-test`, `.agents/skills/flutter-expert`.

**Out of scope:** single-choice sheets (T3), stubs (T5), screen (T6).

---

## Task 5: Stub sheets (Logout confirm, Paywall)

**Role:** ui

**Goal:** The two no-backend sheets: a destructive logout confirm, and a display-only paywall.

**Files:**
- Create: `lib/ui/features/profile/views/logout_confirm_sheet.dart` (`showLogoutConfirmSheet`)
- Create: `lib/ui/features/profile/views/paywall_sheet.dart` (`showPaywallSheet`)
- Test: `test/ui/features/profile/stub_sheets_test.dart`

**Contract:**

```dart
// logout_confirm_sheet.dart
Future<void> showLogoutConfirmSheet(BuildContext context) => showCrudoSheet<void>(
  context, builder: (_) => const _LogoutConfirmSheet());
// _LogoutConfirmSheet (ConsumerWidget): SheetScaffold(title: 'Sign out?',
//   body: 'You can sign back in anytime. Your local data stays on this device.',
//   cta: a Row of a secondary 'Cancel' (pop) + a destructive 'Sign out' button —
//   built inline with an error-tone background (PrimaryCta has no danger variant),
//   pill radius, no shadow, per AGENTS.md error tone).
//   Sign out → await ref.read(profileControllerProvider.notifier).signOut();
//   Navigator.pop(context); showCrudoToast(context, 'Signed out').

// paywall_sheet.dart — DISPLAY ONLY, no IAP (real billing S25).
Future<void> showPaywallSheet(BuildContext context) => showCrudoSheet<void>(
  context, builder: (_) => const _PaywallSheet());
// _PaywallSheet: SheetScaffold(label: 'CRUDO PREMIUM', title: 'Keep your streak alive',
//   body: two plan tiles — Monthly '€6.99/mo' and Annual '€39.99/yr · €3.33/mo'
//   (annual highlighted, gold 'BEST VALUE' badge) — + a note '7-day free trial',
//   cta: PrimaryCta('Start free trial', onPressed: () => Navigator.pop(context))).
//   No purchase logic — placeholder prices from product.md.
```

**Steps (TDD):**

- [ ] 1. **Failing test** — `stub_sheets_test.dart`: LogoutConfirm — tap "Sign out" → `signOut` ran (profile == `UserProfile(id: localUserId)`), sheet popped, toast shown; "Cancel" → pops, no change. Paywall — renders both plan tiles + prices + "Start free trial"; CTA pops; no crash.
- [ ] 2. **Run — red:** `flutter test --timeout=90s test/ui/features/profile/stub_sheets_test.dart` → undefined `showLogoutConfirmSheet`.
- [ ] 3. **Implement** both. Danger CTA gradient per AGENTS.md error tone; annual tile gold-highlighted.
- [ ] 4. **Run — green:** same command.
- [ ] 5. Gates: `dart format .` · `flutter analyze` · `flutter test --timeout=90s`. Report for review.

**Skills:** `.agents/skills/flutter-add-widget-test`, `.agents/skills/flutter-expert`.

**Out of scope:** real auth/IAP (S22/S25), the screen (T6).

---

## Task 6: ProfileScreen (rewrite + wiring)

**Role:** ui

**Goal:** Replace the placeholder with the full screen: avatar+name header, subscription banner, Settings rows opening the sheets, Badges, Sign out.

**Files:**
- Rewrite: `lib/ui/features/profile/views/profile_screen.dart`
- Test: `test/ui/features/profile/profile_screen_test.dart`

**Contract:**

```dart
// ProfileScreen (ConsumerWidget) — reads:
//   final profile = ref.watch(profileProvider);   // AsyncValue<UserProfile>
//   final streak  = ref.watch(streakProvider);     // AsyncValue<Streak> (history_providers)
// Layout (SafeArea > ListView, Spacing.md, paddingBottom for nav):
//  1. Header: kicker 'ACCOUNT' + 'Profile' (CrudoText.headline).
//  2. Avatar block (centered): initials circle from displayName (_initials, fallback 'U')
//     with a small gold streak badge (streak.current); name (CrudoText.title or .headline-sm)
//     tappable → showDisplayNameSheet(context); (no email line — S22).
//  3. Subscription banner: surfaceLowest card + Shadows.cloud, 'FREE TRIAL' kicker +
//     'Upgrade to keep your streak.' + gold crown (Icons.workspace_premium / star),
//     onTap → showPaywallSheet(context).
//  4. SettingsSection('Settings'):
//     SettingsRow('Notifications', 'Pre-meal pings, end-of-day summary', → showRemindersSheet)
//     SettingsRow('Goal', _goalSubtitle(prefs), → showGoalSheet)
//     SettingsRow('Units', prefs.units == Unit.g ? 'Grams' : 'Ounces', → showUnitsSheet)
//     SettingsRow('Streak threshold', '${prefs.streakThreshold}% of planned calories', → showThresholdSheet)
//  5. SettingsSection('Badges'): a Row of 3 tiles {7,30,100}; earned = streak.personalBest >= n
//     (gold tile + gold trophy) else muted (surfaceLow). Read-only.
//  6. Sign out: full-width pill (surfaceLow) → showLogoutConfirmSheet(context).
// Helpers: String _initials(String? name) (first letters of up to 2 words, fallback 'U');
//   String _goalSubtitle(Prefs p) → 'Maintain' or 'Maintain · 2200 kcal/day'.
// profile.when/maybeWhen: loading → centered spinner; error → simple message.
// streak is a SEPARATE AsyncValue — guard it too: avatar streak-badge + the
// Badges section read streak.value; while streak is loading/absent, show badge
// count 0 / unearned tiles (never crash on null). Header + Settings need only
// profile; render them as soon as profile has data.
```

**Steps (TDD):**

- [ ] 1. **Failing test** — `profile_screen_test.dart`: pump `ProfileScreen` in a themed `MaterialApp` + `ProviderScope` with an in-memory repo seeded `UserProfile(id, displayName: 'Mark Kovac', prefs: Prefs(units: oz, streakThreshold: 90, goal: maintain, dailyKcalTarget: 2200))` and a `Streak(current: 7, personalBest: 30)`. Assert: 'Mark Kovac' renders; avatar shows 'MK'; rows show 'Ounces', 'Maintain · 2200 kcal/day', '90% of planned calories'; badges 7 + 30 earned, 100 not; tapping 'Units' opens the units sheet (`find.text('Grams')` appears). Sign out button present.
- [ ] 2. **Run — red:** `flutter test --timeout=90s test/ui/features/profile/profile_screen_test.dart` → fails on the placeholder layout.
- [ ] 3. **Implement** the rewrite wiring T1–T5. Tokens only; gold for streak badge + earned badges + crown.
- [ ] 4. **Run — green:** same command.
- [ ] 5. Gates: `dart format .` · `flutter analyze` · `flutter test --timeout=90s`. Report for review.

**Skills:** `.agents/skills/flutter-riverpod-arch`, `.agents/skills/flutter-add-widget-test`, `.agents/skills/flutter-expert`. Design system: AGENTS.md.

**Out of scope:** real auth/billing; `Prefs` model changes; the sheets' internals (T3–T5 own them).

**Acceptance:** Profile tab renders all sections from a seeded profile; editing any setting persists and the row subtitle updates (via `profileProvider` re-emit); S12 History recolors on a threshold change; S14 notifications re-arm on a prefs change **once Task 7 lands** (it makes the scheduler watch profile); `flutter test --timeout=90s` green.

---

## Task 7: Make S14 notifications react to prefs edits

**Role:** implement

**Goal:** S14's scheduler + streak-risk providers read profile non-reactively (`.watch().first`), so the S15 RemindersSheet/threshold edits don't re-arm anything until the next day-change. Switch both to watch `profileProvider` so a prefs save immediately recomputes the schedule + risk. **This is the wire that makes S15's settings actually do something.**

**Files:**
- Modify: `lib/ui/features/today/view_models/notification_scheduler_controller.dart:34`
- Modify: `lib/ui/features/today/view_models/streak_at_risk_provider.dart:26`
- Test: `test/ui/features/today/notification_scheduler_controller_test.dart` (add a case)

**Contract:**

```dart
// notification_scheduler_controller.dart — NotificationScheduler.build():
// BEFORE: final profile = await ref.read(profileRepositoryProvider).watch().first;
// AFTER:  final profile = await ref.watch(profileProvider.future);
//   (profileProvider is the Stream<UserProfile> from today_providers, already
//    imported; .future subscribes + re-runs build on every profile emission.)

// streak_at_risk_provider.dart — streakAtRisk():
// BEFORE: final profile = await ref.read(profileRepositoryProvider).watch().first;
// AFTER:  final profile = await ref.watch(profileProvider.future);
```

> Both files already import `today_providers.dart` (for `todayProvider`/`clockProvider`), so `profileProvider` is in scope. No other change — `notificationSchedule`/`streakRiskInfo` calls stay identical.

**Steps (TDD):**

- [ ] 1. **Failing test** — extend `notification_scheduler_controller_test.dart`: with the scheduler built and a `FakeNotificationService`, change a pref via `ProfileController` (or `profileRepositoryProvider.save` directly — e.g. flip `preOn` to false), pump, and assert `fake.scheduled.last` reflects the new prefs (no `pre` specs) **without** any Day mutation. With the old `.watch().first` this fails (stale schedule).
- [ ] 2. **Run — red:** `flutter test --timeout=90s test/ui/features/today/notification_scheduler_controller_test.dart` → the new case fails (scheduler didn't re-run on prefs change).
- [ ] 3. **Implement** the two one-line swaps.
- [ ] 4. **Run — green:** same command; confirm the existing scheduler/router/risk tests still pass.
- [ ] 5. Gates: `dart format .` · `flutter analyze` · `flutter test --timeout=90s`. Report for review.

**Skills:** `.agents/skills/flutter-riverpod-arch`, `.agents/skills/dart-add-unit-test`.

**Out of scope:** changing the schedule math, the risk math, or any S15 UI. Two reactive-dependency swaps + one test, nothing else.
