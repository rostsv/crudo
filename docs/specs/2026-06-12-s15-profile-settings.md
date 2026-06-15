# Spec — S15: Profile & settings

**Status:** approved (design) · **Spec S15** · Phase 4 (Motivation). Depends on S03 (`ProfileRepository` watch/get/save, `UserProfile`, `Prefs`), S12 (`Streak` for badges/avatar-badge; `streakThreshold` semantics). Consumes S04 (`showCrudoSheet`/`SheetScaffold`, `showCrudoToast`, `PrimaryCta`, `SelectionCard`, route `/profile` already registered), S14 (the `Prefs` notification toggles this surface finally lets the user edit — `preOn/atOn/eodOn/riskOn`/`preMin`).

Scope = the real **Profile tab**: identity header (avatar + editable display name), a static subscription-status banner, a Settings section whose rows open per-setting bottom sheets (Notifications/Goal/Units/Streak threshold), a read-only Badges row, and Sign out. S15 makes `Prefs` **editable** for the first time — every edit persists through `ProfileRepository.save` and re-emits to the whole app (the S14 scheduler re-arms, History re-classifies). Replaces the placeholder `profile_screen.dart`.

## Goal

Give the user one screen to control the app and see their account. Today `Prefs` is read-only (seeded defaults); S15 adds the editing surface the rest of the app already reads. Tapping a settings row opens a Crudo bottom sheet (consistent with S14's RemindersSheet idiom); choosing an option saves the mutated `UserProfile` via `ProfileRepository`, which streams back to `profileProvider` so notifications reschedule and adherence re-colors with no extra wiring. The screen also surfaces identity (avatar initials + display name), trial/subscription status (static placeholder — real billing is S25), earned streak badges (derived from `personalBest`), and a Sign-out action (local stub — real session teardown is S22).

## Decisions (brainstorm 2026-06-12)

- **Bottom sheet per setting.** Each Settings row (Notifications, Goal, Units, Streak threshold) opens a `showCrudoSheet` modal built on `SheetScaffold`, with the option control + a Save CTA (Reminders) or tap-to-select-and-close (single-choice settings). Mirrors S14's RemindersSheet; reuses the app's sheet idiom (sheets are overlays, never routes — architecture §5). Confirmed via fork. (Alternatives — reuse onboarding full-screen pickers / inline expandable cards — rejected: onboarding screens are S16, not built; inline = long busy screen, non-standard here.)
- **Scope = roadmap core + 3 extras.** Build: Units, Goal (+ kcal target), Streak threshold, Notifications (RemindersSheet) — the roadmap S15 core — **plus** the subscription-status banner, the Badges row, and editable display name. Confirmed via fork.
- **Streak-preference toggles OMITTED.** The prototype's "Count partial as complete" + "Skip weekends" are **not** built: neither is in the `Prefs` model and weekend-skip is explicitly post-MVP (AGENTS.md). No `Prefs` model change in S15. The "Streak preferences" section from the prototype is dropped. Confirmed via fork.
- **Sign-out = stub; subscription = static.** Sign out shows a `LogoutConfirmSheet`; confirming calls a `ProfileController.signOut()` that resets the local profile to defaults (real auth/session teardown is S22). The subscription banner shows static "Free Trial" status copy (no fabricated countdown — real status/billing is S25) and taps into a **display-only** `PaywallSheet` (visual only, no IAP). Confirmed via fork.
- **Editable display name; email deferred.** Avatar shows initials derived from `displayName` (fallback "U"); tapping the name opens an edit sheet (single text field → `setDisplayName`). `UserProfile` has no email (auth = S22) — no email line rendered. Confirmed via fork.
- **Goal carries an optional kcal target.** The Goal sheet edits both the `Goal` enum (cut/maintain/bulk) and the optional `Prefs.dailyKcalTarget` (a stepper/field). The row subtitle reads e.g. "Maintain · 2200 kcal/day" (or just "Maintain" when target is null). `dailyKcalTarget` stays build-time guidance only — never adherence (architecture §10 invariant unchanged).
- **Threshold values are 70/80/90/100.** `Prefs.streakThreshold` selector; default 80. The red floor (50) is fixed, not shown.
- **Every edit persists immediately.** No screen-level "Save". Single-choice sheets save-on-tap-then-pop; the Reminders + Goal + Name sheets (multi-field) have a Save CTA. All go through `ProfileController` → `ProfileRepository.save`. `profileProvider` (existing `Stream<UserProfile>`) re-emits → S14 scheduler + History react automatically.
- **Reminder mode stays `fixed`.** `ReminderMode.interval` is v2 (AGENTS.md); the RemindersSheet does not expose a mode switch.

## Profile screen composition (`profile_screen.dart` — rewrite)

`ConsumerWidget` reading `profileProvider` (`AsyncValue<UserProfile>`) and `streakProvider`/`streakCount`. Top-to-bottom (4px grid, tokens only, no 1px borders, `Shadows.cloud` for the banner):

1. **App bar** — kicker "ACCOUNT" + title "Profile" (`CrudoText.headline`).
2. **Avatar block** — centered: initials circle (from `displayName`) with a small gold streak badge (`streak.current`); display name (`CrudoText.title`); tapping name → `showDisplayNameSheet`.
3. **Subscription banner** — `surfaceLowest` card, `Shadows.cloud`: "FREE TRIAL" kicker + "Upgrade to keep your streak." + gold crown icon; taps → `showPaywallSheet` (display-only).
4. **Settings section** (`SettingsSection` title "Settings") — `SettingsRow`s, each label + subtitle + chevron:
   - "Notifications" — sub "Pre-meal pings, end-of-day summary" → `showRemindersSheet`.
   - "Goal" — sub from goal + kcal target → `showGoalSheet`.
   - "Units" — sub "Grams"/"Ounces" → `showUnitsSheet`.
   - "Streak threshold" — sub "80% of planned calories" → `showThresholdSheet`.
5. **Badges section** — 3 trophy tiles {7,30,100}; earned = `streak.personalBest >= n` (gold) else muted. Read-only.
6. **Sign out** — full-width pill button (`surfaceLow`), → `showLogoutConfirmSheet`.

## `ProfileController` (`view_models/profile_controller.dart`)

**Command controller, no state** — avoids a second source of truth. The screen and sheets read `profileProvider` (the existing `Stream<UserProfile>`) for display; this controller only mutates. Each method reads the current profile from the repo, `copyWith`s the one field, and saves — `ProfileRepository.save` emits through `watch()` → `profileProvider` re-renders. No `invalidateSelf`, no held `UserProfile`.

```dart
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
      _mutate((p) => p.copyWith(
            preOn: pre ?? p.preOn, atOn: at ?? p.atOn,
            eodOn: eod ?? p.eodOn, riskOn: risk ?? p.riskOn,
          ));

  Future<void> setDisplayName(String name) async {
    final repo = ref.read(profileRepositoryProvider);
    await repo.save((await repo.get()).copyWith(displayName: name));
  }

  /// Local stub — real session teardown is S22.
  Future<void> signOut() async =>
      ref.read(profileRepositoryProvider).save(const UserProfile(id: localUserId));
}
```

> `setGoal` with `kcalTarget: null` clears the target (freezed `copyWith` sets it null). `localUserId` from `data/local_user.dart`. The plan pins bodies verbatim.

## Setting sheets (`views/`)

Each is a function `Future<void> show<X>Sheet(BuildContext, WidgetRef)` opening `showCrudoSheet` with a `SheetScaffold`. Reads current value from `profileProvider`, writes via `ProfileController`.

- **`showUnitsSheet`** — two-option single-select (Grams/Ounces) → `setUnits` + pop.
- **`showThresholdSheet`** — four-option single-select (70/80/90/100 %) → `setThreshold` + pop.
- **`showGoalSheet`** — three Goal options (Cut/Maintain/Bulk) + a `CrudoStepper` for kcal target (nullable; "Not set" ↔ a value, e.g. 1200–4000 step 50) + Save CTA → `setGoal(goal, kcalTarget:)`.
- **`showRemindersSheet`** — the S14 hand-off: 4 `CrudoToggle` rows (Pre-meal / At meal time / End-of-day summary / Streak at risk) + a `CrudoStepper` for pre-meal lead (5–60, step 5, default 30) + Save CTA → `setNotifToggle` + `setPreMin`. **4 toggles, not the prototype's 5** (no "No-action warning" — folds into eod, no `warnOn` field). Default lead 30 (model wins over prototype 15).
- **`showDisplayNameSheet`** — single `TextField` + Save → `setDisplayName`.
- **`showLogoutConfirmSheet`** — title "Sign out?" + body + Cancel/Confirm (danger); Confirm → `signOut` + pop + toast.
- **`showPaywallSheet`** — display-only: plan tiles (monthly/annual, annual highlighted, placeholder prices from product.md €6.99/mo · €39.99/yr) + a disabled/placeholder CTA + dismiss. **No IAP** — visual stub; real billing S25.

## New shared widgets (`core/widgets/`)

- **`SettingsSection`** — titled group (uppercase kicker + `surfaceLowest` card wrapping rows). No 1px dividers — row separation by padding.
- **`SettingsRow`** — label + optional subtitle + trailing (chevron / toggle) + `onTap`. Tappable.
- **`CrudoToggle`** — styled switch (gold/primary track), `value` + `onChanged`. Used by RemindersSheet.
- **`CrudoStepper`** — `− value +` with min/max/step + suffix (e.g. "m", "kcal"). Used by Goal + Reminders sheets.

All on the 4px grid, tokens from `core/themes/`, gold for accents, never pure black, no drop shadows beyond `Shadows.cloud`.

## Out of scope (explicit)

- **Real auth / session / sign-in / email** — S22. `signOut` is a local profile reset; no real teardown.
- **Real billing / IAP / subscription status + countdown** — S25. Banner is static copy; PaywallSheet is a visual stub.
- **Onboarding selection screens** — S16 (S15 uses bottom sheets, not those screens).
- **`Prefs` model changes** — none. No `warnOn`, no `partial`/`weekend` fields (post-MVP). Reminder mode stays `fixed`.
- **New streak/adherence/notification math** — owned by S12/S14; S15 only reads `Streak` (badges) and writes `Prefs` (which S14 reschedules off).
- **JSON/DTOs** — S20.

## Testing

- `package:checks`, `flutter test --timeout=90s` always; `gtimeout 600` around `build_runner`.
- **`ProfileController`** (`ProviderContainer` + in-memory repo): each mutator persists the right field and only that field (`setUnits` leaves goal/threshold untouched); `signOut` resets to `UserProfile(id: localUserId)`; `setGoal(g, kcalTarget: n)` writes both; `setGoal(g)` with null clears the target.
- **Setting sheets** (widget tests): `showUnitsSheet` selecting Ounces calls `setUnits(Unit.oz)` and pops; `showThresholdSheet` 90 → `setThreshold(90)`; RemindersSheet toggling Pre-meal off + Save → `setNotifToggle(pre: false)`, and the lead stepper 30→25 → `setPreMin(25)`; `showLogoutConfirmSheet` Confirm → `signOut` + pop.
- **ProfileScreen** widget test: renders display name + avatar initials, the 4 settings rows with correct subtitles from a seeded profile, badges earned/unearned from `personalBest`, and that tapping "Units" opens the units sheet.
- **No** test of real IAP/auth (stubs).
