# Spec — S14: Local notifications + streak-at-risk

**Status:** approved (design) · **Spec S14** · Phase 4 (Motivation). Depends on S05 (`meal_status.dart`: `localInstantAt`/`endOfDayLocal`/`localDateLabel`/`deriveMealStatus`; `meal_lifecycle.dart`: `computeGraceEnd`/`mealStatus`/`plannedKcal`/`consumedKcal`; `ScheduledMeal.id` = slot-stable notification key), S09 (plan scheduling → the `Day` whose slots drive timing), S12 (`adherence.dart`: `dayAdherence`/`classifyDayState`/`adherenceRedFloor`; `Streak.current`). Also uses S04 (`AppShell` listener pattern, `Sheet`/dialog helpers), S02 (`Prefs` notification toggles, `ReminderMode`, `DayRepository`, `StreakRepository`, `ProfileRepository`).

Scope = the **whole local-notification subsystem from zero**: the dependency + iOS/Android platform setup, a **pure schedule function** over `(Day, Prefs, now)`, a thin `NotificationService` adapter behind an interface, a scheduler controller with reschedule hooks, notification **actions** (Ate it / Snooze / Skip) routed back into `day_controller`, and the **streak-at-risk** alert — both as a scheduled OS notification and the in-app `StreakRiskSheet`. No new adherence/streak/meal-status math (S05/S12 own it); no Prefs-editing UI (S15 owns it — S14 only **reads** prefs).

## Goal

Make Crudo actually remind you. Today the streak engine runs but nothing ever pings the user. S14 schedules four kinds of local notification off the user's plan — a pre-meal heads-up (`preMin` before), an at-meal-time reminder carrying the **Ate it / Snooze / Skip** actions, an end-of-day summary (~9:30 PM recap + streak status, which also folds in the no-action warning), and a streak-at-risk alert at the computed instant the streak would break if the remaining meals are skipped. The "what fires, when" is a **pure function** so it is fully unit-testable and the domain never imports the plugin; the plugin is a thin adapter behind a `NotificationService` interface registered in `di.dart`, exactly mirroring the repo pattern. A scheduler controller cancels-and-recomputes the full set whenever the day changes (rollover, meal marked/snoozed/skipped/edited, plan change, app-resume). Tapping a notification action routes through a handler into `day_controller` — foreground and background covered, terminated-state best-effort. The streak-at-risk alert also surfaces in-app via an `AppShell` listener showing the gold-flame `StreakRiskSheet`, with a session-scoped "Mute today".

## Decisions (brainstorm 2026-06-11)

- **Pure schedule + thin adapter.** `lib/domain/services/notification_schedule.dart` is a pure function `notificationSchedule(Day day, Prefs prefs, DateTime now) → List<NotificationSpec>` (clock-injected, no Flutter/plugin imports). `NotificationService` is an **interface** (`lib/domain/services/` is pure, so the interface lives in `lib/domain/repositories/notification_service.dart` alongside the repo interfaces) whose only job is `scheduleAll(List<NotificationSpec>)` / `cancelAll()` / permission + init — **no scheduling logic**. The plugin impl lives in `data/services/`. This keeps the schedule 100% unit-testable with no fake plugin and honours the locked domain-purity invariant. Confirmed via fork. (Alternative — logic inside the service — rejected: couples timing math to the plugin, breaks purity, untestable without a device/fake.)
- **Full real platform wiring this sprint.** Add `flutter_local_notifications` + `timezone` to `pubspec.yaml`; iOS `AppDelegate` registration + Android notification channel + action categories + runtime permission request; a real `FlutterLocalNotificationsNotificationService` behind the interface. CI/unit tests cover the pure schedule + a `FakeNotificationService` (records calls); the real impl is verified manually on device (CI has none). Confirmed via fork. (Alternative — stub-only, defer plugin — rejected: context mandates S14 ships the dependency + platform setup from scratch.)
- **Streak-at-risk fires at a computed deadline.** Pure: using S12's adherence math, find the latest instant today at which skipping **all** still-`upcoming` meals would drop the day below `prefs.streakThreshold` — schedule the risk notification there (and, if that instant has already passed at compute time but the day is still savable, fire at `now`). Derived from the same `consumed ÷ planned kcal` rule, no magic clock time. Produces the prototype's copy ("Two meals left to keep 12 days alive… 32 minutes from now"). Confirmed via fork. (Alternatives — fixed 4 PM check / last-upcoming-meal-only — rejected: arbitrary time / warns regardless of actual risk.)
- **Notification actions route foreground + background; terminated best-effort.** The at-meal notification carries three action buttons — **Ate it** → `day_controller.markAllEaten(mealId)`, **Snooze** → `day_controller.snooze(mealId, default preset)`, **Skip** → `day_controller.skipMeal(mealId)`. The `mealId` travels in the notification payload (= `ScheduledMeal.id`). Foreground/background action taps route through a handler immediately. A terminated-state action is captured via `getNotificationAppLaunchDetails` and **replayed on next launch** (best-effort) so the 1-tap promise holds for the common case. Confirmed via fork. (Alternative — foreground-only — rejected: breaks "1-tap, no app open".)
- **Risk delivery = both notification AND in-app sheet.** Mirrors the S13 milestone pattern. When backgrounded the OS notification fires; when foregrounded an `AppShell` `ref.listen` on a `streakAtRiskProvider` shows the `StreakRiskSheet` (gold flame circle, "Streak at risk", "N meals left to keep D days alive.", "<meal> at <time> — M minutes from now.", primary "Got it", secondary "Mute today"). The sheet shows once per risk crossing, like milestones. (Judgment call — not a separate fork; matches S13 precedent.)
- **"Mute today" = session-scoped in-memory flag, keyed by today's date label.** A `mutedRiskDayProvider` (StateProvider holding a `DateTime?` date label) suppresses both the risk notification (the scheduler skips emitting the risk spec) and the in-app sheet for that label. Lost on app restart — acceptable MVP; there is no Prefs field and Prefs editing is S15. (Judgment call.)
- **Reschedule = cancel-all + recompute the full set**, never incremental diff. Triggered on: day rollover (midnight tick / resume re-derive — already wired in `TodayScreen`), today's `Day` mutated (any check/uncheck/markAllEaten/skip/snooze/replaceMeal via `day_controller`), plan change for today, and app-resume. Prefs-change re-arm folds into resume (no in-app Prefs editor until S15). The scheduler watches `todayProvider`/the today `Day` and re-runs on every emission. (Judgment call.)
- **No new domain math, status stays derived, streak advances only at midnight-lock.** S14 reads `deriveMealStatus`/`mealStatus`, `plannedKcal`/`consumedKcal`, `dayAdherence`/`classifyDayState`, `Streak.current`. It never stores status, never advances the streak (S12 owns that), never touches `dailyKcalTarget`.
- **Prefs unchanged.** `docs/product.md:85` — "No-action warning folds into end-of-day" — so the prototype's 5th `warnOn` toggle is **not** added; the warning is a line in the end-of-day summary. The prototype's `preMin` default of 15 is sketch; the model's `30` wins. No Prefs model change in S14.

## `NotificationSpec` (pure value object — `lib/domain/services/notification_spec.dart`)

The pure schedule emits a list of these; the adapter translates each into a plugin `zonedSchedule` call. Freezed, serialization-free, UTC instants.

```dart
enum NotificationKind { pre, at, endOfDay, risk }

/// One scheduled local notification. `id` is a deterministic int derived from
/// (mealId, kind) so a recompute overwrites the same OS slot rather than
/// duplicating. `mealId` is the ScheduledMeal.id payload that action taps and
/// the route handler key off (null for endOfDay, which targets no single meal).
@freezed
abstract class NotificationSpec with _$NotificationSpec {
  const factory NotificationSpec({
    required int id,                 // stable OS notification id
    required NotificationKind kind,
    required DateTime fireAt,        // UTC instant to fire
    required String title,
    required String body,
    String? mealId,                  // ScheduledMeal.id; drives action routing
    @Default(false) bool withActions, // true only for `at` (Ate/Snooze/Skip)
  }) = _NotificationSpec;
}
```

`id` derivation: a small pure helper `notificationId(String? mealId, NotificationKind kind)` (stable hash) — same inputs → same int, so cancel/reschedule is idempotent.

## Pure schedule — `lib/domain/services/notification_schedule.dart`

```dart
/// Pure. Given today's materialized Day, the user's Prefs, and now, produce the
/// full set of notifications that SHOULD be live. The adapter cancels all and
/// re-arms from this list. No plugin/Flutter imports; clock injected as `now`.
///
/// Rules (each gated by its Prefs toggle; all instants UTC, skip if in the past
/// except `risk` which may fire at `now`):
///   pre  (preOn):  for each upcoming meal → localInstantAt(date,time) - preMin
///   at   (atOn):   for each upcoming meal → localInstantAt(date,time), withActions
///   eod  (eodOn):  one spec at the end-of-day summary time (~21:30 local),
///                  body = recap (planned vs consumed, meals done/skipped) +
///                  streak status; folds the no-action warning.
///   risk (riskOn): one spec at the computed risk deadline (see below), unless
///                  today is muted or the streak isn't actually at risk.
List<NotificationSpec> notificationSchedule(Day day, Prefs prefs, DateTime now);
```

- **Upcoming-only:** `pre`/`at` are emitted only for meals whose `deriveMealStatus(... == upcoming)`. A done/partial/skipped/overdue meal gets no future ping. Recompute on each meal mutation drops the ones no longer upcoming.
- **End-of-day time:** a single named constant `endOfDaySummaryLocalTime` (21:30) on the day's date; below `endOfDayLocal(date)` (midnight) by construction. Tunable constant, not a Prefs field.
- **Risk deadline (pure):** helper `streakRiskDeadline(Day day, int threshold, DateTime now) → DateTime?`. Walk the still-`upcoming` meals in time order; the streak is at risk when `consumedKcal(day)` (already-eaten) + the kcal of meals that *would* still fire **after** dropping the rest is projected below `threshold% × plannedKcal(day)`. Concretely: the deadline is the `at`-instant of the **last** upcoming meal whose inclusion is necessary to stay ≥ threshold — i.e. the latest point at which one more skip tips the day red/below-green. Returns `null` when the day is already safe (consumed ≥ threshold) or already unrecoverable (even eating everything left can't reach threshold — don't nag a lost day). The risk `NotificationSpec.body` names that pivotal meal + minutes-from-now.

This file is `package:checks`-tested exhaustively (toggles off → empty; past meals excluded; risk null when safe/lost; risk instant correct for a multi-meal day; muted day → caller drops it).

## `NotificationService` interface + impl

```dart
// lib/domain/repositories/notification_service.dart  (PURE interface)
abstract interface class NotificationService {
  Future<void> init();                                   // channels/categories
  Future<bool> requestPermission();
  Future<void> cancelAll();
  Future<void> scheduleAll(List<NotificationSpec> specs); // cancelAll + re-arm
  /// Stream of action taps: (mealId, action) the controller routes.
  Stream<NotificationAction> get actions;                 // Ate/Snooze/Skip
  /// Terminated-launch action captured at startup, or null.
  Future<NotificationAction?> consumeLaunchAction();
}

enum NotificationActionKind { ateIt, snooze, skip }
typedef NotificationAction = ({String mealId, NotificationActionKind kind});
```

- **Impl:** `data/services/flutter_local_notifications_notification_service.dart` wraps `FlutterLocalNotificationsPlugin` + `timezone`. `scheduleAll` does `cancelAll()` then `zonedSchedule` per spec (converting UTC `fireAt` → `TZDateTime`). Action buttons attached only when `withActions`. Foreground/background action callbacks push onto the `actions` stream; the background isolate entry-point (`@pragma('vm:entry-point')`) records the tap so it replays.
- **Registered in `di.dart`** as the domain interface (`notificationServiceProvider`), in-memory `FakeNotificationService` for tests, real impl for the app — same swap pattern as repos. A `FakeNotificationService` records `scheduleAll` calls and can push synthetic actions.

## Scheduler controller — `lib/ui/features/today/view_models/notification_scheduler_controller.dart`

`@riverpod` `AsyncNotifier` patterned on `StreakCatchUp`:
- `build()` `ref.watch`es the today `Day` (so every mutation/rollover re-runs), reads `profileProvider` (Prefs) and `mutedRiskDayProvider`.
- Computes `notificationSchedule(day, prefs, now)`; if today is muted, strips the `risk` spec.
- Calls `notificationService.scheduleAll(specs)` (cancel-all + re-arm). Idempotent — stable ids overwrite.
- An `actionRouterProvider` listens to `notificationService.actions` and routes each to `dayController(today).markAllEaten/snooze/skipMeal`. On startup it also `consumeLaunchAction()` once and replays it.

## Streak-at-risk in-app — `streakAtRiskProvider` + `StreakRiskSheet`

- `@riverpod` provider derives `StreakRisk?` from the today `Day` + `Streak.current` + threshold + `mutedRiskDayProvider`, using `streakRiskDeadline`. Emits non-null only when at risk and not muted; the value carries `{streakDays, mealsLeft, pivotalMealName, pivotalMealTime, minutesFromNow}`.
- `AppShell` adds a second `ref.listen` (next to the milestone listener) → shows `StreakRiskSheet` once per crossing via the same `_navigatorContext` + post-frame pattern.
- `lib/ui/features/today/views/streak_risk_sheet.dart` — centered `Dialog`, transparent bg, `surfaceLowest` card, `Shadows.cloud`, gold flame in a `gold @ 0.15` circle (size `IconSizes.xl`), label "STREAK AT RISK" in gold, headline "N meals left to keep D days alive.", body "<meal> at <time> — M minutes from now.", `PrimaryCta('Got it')`, secondary text button "Mute today" → sets `mutedRiskDayProvider` to today's label + pops. Tokens only, 4px grid, no 1px borders, no drop shadow beyond cloud. Built to match `docs/design/prototype/screens/sheets.jsx` StreakRiskSheet.

## Platform setup

- **iOS:** request `alert`/`badge`/`sound` permission; register the meal action category (Ate it / Snooze / Skip) in `AppDelegate`/Darwin init; `DarwinNotificationDetails` with `categoryIdentifier`.
- **Android:** one `NotificationChannel` ("Meal reminders"); `AndroidNotificationDetails` with three `AndroidNotificationAction`s; `POST_NOTIFICATIONS` runtime permission (API 33+); exact-alarm consideration documented (use inexact `zonedSchedule` to avoid the exact-alarm permission unless drift proves a problem).
- **timezone:** `tz.initializeTimeZones()` + set local in `init()`; convert UTC `fireAt` → `TZDateTime` at schedule time.
- Permission requested at app-open via the scheduler controller's first run (re-asks gracefully if denied; a denied state just no-ops `scheduleAll`).

## Out of scope (explicit)

- **`RemindersSheet` toggle UI + Prefs editing** — S15 Profile & settings (opened from the Profile tab). S14 only reads Prefs. **S15 hand-off:** the prototype `RemindersSheet` (`sheets.jsx:79`) shows **5** toggles incl. "No-action warning" + a `preMin=15` default — both are sketch. S15 ships **4** toggles (pre/at/eod/risk; warning folds into eod per `product.md:85`, no `warnOn` field) and keeps the model default `preMin=30` (stepper range 5–60 unchanged).
- **Review / app-store prompt** — launch / S25.
- **Remote/push notifications + Supabase** — S20 (local only here).
- **JSON / DTOs** — S20 (domain stays serialization-free; `NotificationSpec` is pure).
- **New adherence / streak / meal-status math** — S05/S12 own it; S14 consumes read-only.
- **Interval reminder mode** — `ReminderMode.interval` is v2; S14 schedules `fixed` only.

## Testing

- `package:checks`, `flutter test --timeout=90s` always.
- **Pure schedule** (`notification_schedule_test.dart`): toggles off → empty per kind; past `pre`/`at` excluded; upcoming-only filtering; eod time correct; risk deadline correct (safe → null, lost → null, multi-meal pivot instant), muted handled by caller; stable id idempotence.
- **Scheduler controller** (`ProviderContainer` + `FakeNotificationService`): recompute on day mutation re-arms; mute strips risk; action stream routes to the right `day_controller` call; launch-action replay fires once.
- **`StreakRiskSheet`** widget test: renders headline/body from a `StreakRisk`; "Mute today" sets the provider + pops; "Got it" pops.
- Real plugin impl is **not** unit-tested (no device in CI) — manual device verification noted in the plan.
