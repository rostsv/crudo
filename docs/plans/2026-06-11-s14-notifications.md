# Plan — S14: Local notifications + streak-at-risk

> **Worker note:** Implements `docs/specs/2026-06-11-s14-notifications.md`. Each `## Task N:` is self-contained — read `AGENTS.md`, your role file, and the named `.agents/skills/*` before starting. TDD + gates per task, **no commits** (end at "report for review"). `package:checks` for assertions; **every** `flutter test` carries `--timeout=90s`; wrap `build_runner` in `gtimeout 600`.

**Goal:** Schedule four kinds of local notification off today's plan (pre / at / end-of-day / streak-at-risk) via a pure schedule function + a thin plugin adapter, route Ate-it/Snooze/Skip actions back into `day_controller`, and surface streak-at-risk in-app via `StreakRiskSheet`.

**Architecture:** Pure `notificationSchedule(Day, Prefs, now) → List<NotificationSpec>` in `domain/services/` (no plugin imports). `NotificationService` is a domain-facing port (`domain/repositories/`) with a `flutter_local_notifications` impl in `data/services/`, registered in `di.dart` like a repo. A `@riverpod` scheduler controller watches today's `Day` and cancels-and-rearms on every change; an action router pipes the plugin's action stream into `dayController`. Streak-at-risk is both an OS notification and an `AppShell`-listened in-app sheet.

**Tech stack:** Dart 3.11, Flutter, Riverpod 3.x (`@riverpod`), freezed, `flutter_local_notifications` + `timezone` (new), `package:checks`, `uuid` (existing).

## Decisions (from spec brainstorm 2026-06-11)

| Fork | Decision |
|---|---|
| Schedule logic | Pure `notificationSchedule` fn in domain; `NotificationService` = thin adapter, no logic. |
| Platform wiring | Full real `flutter_local_notifications` + `timezone`; pure schedule + `FakeNotificationService` carry unit tests; real impl manual-verified (no CI device). |
| Risk trigger | Computed deadline via S12 adherence math (`streakRiskInfo`); null when day safe or already lost. |
| Action routing | Ate-it/Snooze/Skip → `dayController`; foreground+background immediate, terminated replayed on next launch. |
| Risk delivery | OS notification (backgrounded) + in-app `StreakRiskSheet` (foregrounded, `AppShell` listener). |
| Mute today | Session in-memory `mutedRiskDayProvider` (date label); strips risk spec + sheet. |
| Reschedule | Cancel-all + recompute full set on any today-`Day` change / rollover / resume (scheduler `ref.watch`es the Day). |
| Prefs | Unchanged. No `warnOn` (folds into eod). `preMin=30` model default wins over prototype 15. RemindersSheet editing UI = S15. |

## File changes (map)

- **Create** `lib/domain/services/notification_spec.dart` — `NotificationSpec`, `NotificationKind`, `notificationId` (T1)
- **Create** `lib/domain/services/notification_schedule.dart` — `notificationSchedule`, `streakRiskInfo`, `RiskInfo`, time constants (T2)
- **Create** `lib/domain/repositories/notification_service.dart` — `NotificationService`, `NotificationAction`, `NotificationActionKind` (T3)
- **Create** `test/support/fake_notification_service.dart` — `FakeNotificationService` (T3)
- **Create** `lib/data/services/flutter_local_notifications_notification_service.dart` — real impl (T4)
- **Modify** `pubspec.yaml`; `ios/Runner/AppDelegate.swift`; `android/app/src/main/AndroidManifest.xml` — deps + platform setup (T4)
- **Create** `lib/ui/features/today/view_models/notification_scheduler_controller.dart` — `NotificationScheduler`, `notificationActionRouterProvider`, `mutedRiskDayProvider` (T5)
- **Modify** `lib/config/di.dart` — `notificationServiceProvider` (T5)
- **Create** `lib/ui/features/today/view_models/streak_at_risk_provider.dart` — `streakAtRiskProvider`, `StreakRisk` (T6)
- **Create** `lib/ui/features/today/views/streak_risk_sheet.dart` — `showStreakRiskSheet`, `StreakRiskSheet` (T6)
- **Modify** `lib/ui/core/widgets/app_shell.dart` — add risk listener (T6)

---

## Task 1: NotificationSpec value object

**Role:** implement

**Goal:** A pure, freezed `NotificationSpec` the schedule emits and the adapter consumes, plus a deterministic `notificationId` so recompute overwrites the same OS slot.

**Files:**
- Create: `lib/domain/services/notification_spec.dart` (+ codegen `notification_spec.freezed.dart`)
- Test: `test/domain/services/notification_spec_test.dart`

**Contract:**

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'notification_spec.freezed.dart';

enum NotificationKind { pre, at, endOfDay, risk }

/// One scheduled local notification. `id` is deterministic in (mealId, kind)
/// so a recompute reuses the same OS slot. `mealId` is the ScheduledMeal.id
/// payload that action taps key off (null for endOfDay). `withActions` is true
/// only for `at`. `fireAt` is UTC.
@freezed
abstract class NotificationSpec with _$NotificationSpec {
  const NotificationSpec._();

  @Assert('fireAt.isUtc', 'fireAt must be UTC')
  const factory NotificationSpec({
    required int id,
    required NotificationKind kind,
    required DateTime fireAt,
    required String title,
    required String body,
    String? mealId,
    @Default(false) bool withActions,
  }) = _NotificationSpec;
}

/// Stable, collision-resistant int id for (mealId, kind). Same inputs → same
/// id, so cancel/reschedule is idempotent. endOfDay/risk pass mealId = null.
int notificationId(String? mealId, NotificationKind kind) =>
    Object.hash(mealId, kind) & 0x7fffffff;
```

**Steps (TDD):**

- [ ] 1. **Failing test** — `notification_spec_test.dart`: `check(notificationId('m1', NotificationKind.at)).equals(notificationId('m1', NotificationKind.at))` (deterministic); `check(notificationId('m1', NotificationKind.at)).not((i) => i.equals(notificationId('m1', NotificationKind.pre)))` (kind-distinct); `check(notificationId('m1', NotificationKind.at)).isGreaterOrEqual(0)` (non-negative); and constructing a `NotificationSpec` with a non-UTC `fireAt` throws (`check(() => NotificationSpec(id: 1, kind: NotificationKind.at, fireAt: DateTime(2026), title: 't', body: 'b')).throws()`).
- [ ] 2. **Run — red:** `flutter test --timeout=90s test/domain/services/notification_spec_test.dart` → expect "Target of URI hasn't been generated" / undefined `NotificationSpec`.
- [ ] 3. **Implement** the contract; `gtimeout 600 dart run build_runner build`.
- [ ] 4. **Run — green:** `flutter test --timeout=90s test/domain/services/notification_spec_test.dart`.
- [ ] 5. Gates: `dart format .` · `flutter analyze` · `flutter test --timeout=90s`. Report for review.

**Skills:** `.agents/skills/dart-add-unit-test`, `.agents/skills/dart-migrate-to-checks-package`, `.agents/skills/flutter-expert`.

**Out of scope:** the schedule function, any plugin code, Prefs changes.

---

## Task 2: Pure notification schedule + risk math

**Role:** implement

**Goal:** The pure function that turns today's `Day` + `Prefs` + `now` into the full `NotificationSpec` set, plus `streakRiskInfo` (the computed risk deadline via S12 adherence math).

**Files:**
- Create: `lib/domain/services/notification_schedule.dart`
- Test: `test/domain/services/notification_schedule_test.dart`

**Contract:**

```dart
import '../day/day.dart';
import '../profile/prefs.dart';
import '../shared/enums.dart';
import '../shared/meal_time.dart';
import 'meal_lifecycle.dart'; // mealStatus, plannedKcal, consumedKcal
import 'meal_status.dart'; // localInstantAt, MealStatus
import 'notification_spec.dart';
import 'nutrition.dart'; // mealSnapshotMacros (per-meal kcal for risk math)

/// Local time-of-day the end-of-day summary fires (21:30). Tunable constant,
/// not a Prefs field. Below endOfDayLocal(date) by construction.
const endOfDaySummaryMinutes = 21 * 60 + 30; // 1290

/// The pivotal-meal info for a streak at risk, or null when the day is already
/// safe (consumed ≥ threshold) or already unrecoverable (eating everything left
/// still can't reach threshold — don't nag a lost day). `mealsLeft` = count of
/// still-upcoming meals; `deadline` (UTC) = the `at` instant of the pivotal meal
/// (the latest meal whose skip tips the day below threshold).
typedef RiskInfo = ({
  DateTime deadline,
  String pivotalMealId,
  MealTime pivotalMealTime,
  String pivotalMealName,
  int mealsLeft,
});

RiskInfo? streakRiskInfo(Day day, int threshold, DateTime now);

/// Pure. The full set of notifications that SHOULD be live for [day] given
/// [prefs] and [now]. Each kind gated by its Prefs toggle. pre/at/eod skip
/// instants already in the past; risk may fire at `now` if the deadline passed
/// but the day is still recoverable. All `fireAt` UTC. Caller (scheduler) is
/// responsible for dropping the risk spec when today is muted.
List<NotificationSpec> notificationSchedule(Day day, Prefs prefs, DateTime now);
```

**Behavior (implement exactly):**
- `pre` (if `prefs.preOn`): for each meal with `mealStatus(day, m.id, now) == MealStatus.upcoming`, `fireAt = localInstantAt(day.date, m.time).toUtc().subtract(Duration(minutes: prefs.preMin))`; skip if `!fireAt.isAfter(now.toUtc())`. Title `'Coming up'`, body `'${m.meal.name} in ${prefs.preMin} min'`, `mealId: m.id`.
- `at` (if `prefs.atOn`): for each upcoming meal, `fireAt = localInstantAt(day.date, m.time).toUtc()`; skip if past. Title `'Time to eat'`, body `'Time to eat ${m.meal.name}'`, `mealId: m.id`, `withActions: true`.
- `endOfDay` (if `prefs.eodOn`): one spec, `fireAt = DateTime(day.date.year, day.date.month, day.date.day, 21, 30).toUtc()`; skip if past. Title `'Daily recap'`, body `'${consumedKcal(day).round()} of ${plannedKcal(day).round()} kcal · keep your streak alive'`, `mealId: null`.
- `risk` (if `prefs.riskOn`): `final info = streakRiskInfo(day, prefs.streakThreshold, now); if (info != null) → one spec`, `fireAt = info.deadline.isAfter(now.toUtc()) ? info.deadline : now.toUtc()`, title `'Streak at risk'`, body `'${info.mealsLeft} meals left — ${info.pivotalMealName} next'`, `mealId: null`.
- **Known limitation (by design):** `endOfDay`/`risk` bodies bake the kcal/risk numbers at *schedule* time, not fire time (the plugin can't recompute at fire). The scheduler re-arms on every today-`Day` mutation (T5), so each meal marked refreshes the baked body — numbers are current as of the user's last interaction. Acceptable MVP; live fire-time bodies would need a foreground service (out of scope).
- `streakRiskInfo`: `planned = plannedKcal(day)`; if `planned <= 0` return null. `target = planned * threshold / 100`. `consumed = consumedKcal(day)`. Collect upcoming meals (`mealStatus == upcoming`) sorted by `time`. If `consumed >= target` → null (safe). `remainingKcal = sum of upcoming meals' planned kcal (mealSnapshotMacros(m.meal).kcal)`; if `consumed + remainingKcal < target` → null (lost). Otherwise walk upcoming meals accumulating kcal from the **earliest**; the pivotal meal is the **last** one needed so that `consumed + (kcal of meals up to and including it) >= target` — i.e. dropping it drops below target. Return its id/time/name, `deadline = localInstantAt(day.date, pivotal.time).toUtc()`, `mealsLeft = upcoming.length`.

**Steps (TDD):**

- [ ] 1. **Failing test** — `notification_schedule_test.dart`. Build a `Day` with 3 meals (use existing test fixtures / `buildDayFromPlan` or hand-built `ScheduledMeal`s). Assert: all toggles off → `check(notificationSchedule(day, prefsAllOff, now)).isEmpty()`; with `preOn` only → one `pre` spec per future upcoming meal, none for past; `at` specs carry `withActions == true`; `eodOn` → exactly one `endOfDay` spec at 21:30 UTC; risk: a day already ≥ threshold → `check(streakRiskInfo(day, 80, now)).isNull()`; a day where all-remaining-can't-reach → null; a recoverable mid-day → non-null with the correct `pivotalMealId`.
- [ ] 2. **Run — red:** `flutter test --timeout=90s test/domain/services/notification_schedule_test.dart` → undefined `notificationSchedule`.
- [ ] 3. **Implement** the contract + behavior above. (No codegen — pure functions.)
- [ ] 4. **Run — green:** `flutter test --timeout=90s test/domain/services/notification_schedule_test.dart`.
- [ ] 5. Gates: `dart format .` · `flutter analyze` · `flutter test --timeout=90s`. Report for review.

**Skills:** `.agents/skills/dart-add-unit-test`, `.agents/skills/dart-migrate-to-checks-package`, `.agents/skills/flutter-expert`.

**Out of scope:** anything that imports Flutter/plugin/Riverpod (this file stays pure). Mute handling (caller's job). Prefs changes.

---

## Task 3: NotificationService port + fake

**Role:** implement

**Goal:** The domain-facing port the controller depends on, the action value type, and an in-memory `FakeNotificationService` for tests.

**Files:**
- Create: `lib/domain/repositories/notification_service.dart`
- Create: `test/support/fake_notification_service.dart`
- Test: `test/support/fake_notification_service_test.dart`

**Contract:**

```dart
// lib/domain/repositories/notification_service.dart
import '../services/notification_spec.dart';

enum NotificationActionKind { ateIt, snooze, skip }

/// An action tap routed back to the day controller. `mealId` == ScheduledMeal.id.
typedef NotificationAction = ({String mealId, NotificationActionKind kind});

/// Domain-facing port (S14). Pure interface — the plugin impl lives in data/.
abstract interface class NotificationService {
  Future<void> init();
  Future<bool> requestPermission();
  Future<void> cancelAll();

  /// Cancel everything, then arm [specs]. Idempotent in spec ids.
  Future<void> scheduleAll(List<NotificationSpec> specs);

  /// Foreground/background action taps.
  Stream<NotificationAction> get actions;

  /// Terminated-launch action captured at startup (consumed once), or null.
  Future<NotificationAction?> consumeLaunchAction();
}
```

```dart
// test/support/fake_notification_service.dart
import 'dart:async';
import 'package:crudo/domain/repositories/notification_service.dart';
import 'package:crudo/domain/services/notification_spec.dart';

/// Records scheduleAll/cancelAll calls; lets tests push synthetic actions and
/// preload a launch action. No real plugin.
class FakeNotificationService implements NotificationService {
  final List<List<NotificationSpec>> scheduled = [];
  int cancelAllCount = 0;
  bool permissionGranted = true;
  NotificationAction? launchAction;
  final _actions = StreamController<NotificationAction>.broadcast();

  void emitAction(NotificationAction a) => _actions.add(a);

  @override
  Future<void> init() async {}
  @override
  Future<bool> requestPermission() async => permissionGranted;
  @override
  Future<void> cancelAll() async => cancelAllCount++;
  @override
  Future<void> scheduleAll(List<NotificationSpec> specs) async {
    cancelAllCount++;
    scheduled.add(specs);
  }
  @override
  Stream<NotificationAction> get actions => _actions.stream;
  @override
  Future<NotificationAction?> consumeLaunchAction() async {
    final a = launchAction;
    launchAction = null;
    return a;
  }
  void dispose() => _actions.close();
}
```

**Steps (TDD):**

- [ ] 1. **Failing test** — `fake_notification_service_test.dart`: `scheduleAll` records specs + bumps `cancelAllCount`; `emitAction` is received on `actions`; `consumeLaunchAction()` returns the preset once then null. Use `package:checks`.
- [ ] 2. **Run — red:** `flutter test --timeout=90s test/support/fake_notification_service_test.dart` → undefined `NotificationService`/`FakeNotificationService`.
- [ ] 3. **Implement** the port + fake (no codegen).
- [ ] 4. **Run — green:** `flutter test --timeout=90s test/support/fake_notification_service_test.dart`.
- [ ] 5. Gates: `dart format .` · `flutter analyze` · `flutter test --timeout=90s`. Report for review.

**Skills:** `.agents/skills/dart-add-unit-test`, `.agents/skills/dart-migrate-to-checks-package`, `.agents/skills/flutter-apply-architecture-best-practices`.

**Out of scope:** the real plugin impl (T4), di wiring (T5).

---

## Task 4: flutter_local_notifications adapter + platform setup

**Role:** build

**Goal:** Add the plugin + timezone deps, the iOS/Android platform setup, and the real `NotificationService` impl behind the T3 port. Not unit-tested (no CI device) — gates are format/analyze + a construction smoke test; behavior is manual-verified.

**Files:**
- Modify: `pubspec.yaml` (add `flutter_local_notifications`, `timezone`)
- Create: `lib/data/services/flutter_local_notifications_notification_service.dart`
- Modify: `ios/Runner/AppDelegate.swift` (Darwin init + action category)
- Modify: `android/app/src/main/AndroidManifest.xml` (POST_NOTIFICATIONS + receiver)
- Test: `test/data/services/flutter_local_notifications_notification_service_test.dart` (construction smoke only)

**Contract:**

```dart
import 'package:crudo/domain/repositories/notification_service.dart';
import 'package:crudo/domain/services/notification_spec.dart';

/// Real adapter over FlutterLocalNotificationsPlugin + timezone. Translates
/// each NotificationSpec into a zonedSchedule call; `at` specs attach the three
/// action buttons (Ate it / Snooze / Skip) keyed by mealId payload. No
/// scheduling LOGIC here — the pure schedule decides what/when.
class FlutterLocalNotificationsNotificationService
    implements NotificationService {
  FlutterLocalNotificationsNotificationService();
  // init(): tz.initializeTimeZones() + setLocalLocation; plugin.initialize with
  //   Darwin + Android settings; register meal action category/buttons; wire
  //   onDidReceiveNotificationResponse → parse payload(mealId)+actionId → push
  //   NotificationAction onto the actions stream.
  // scheduleAll(): cancelAll(); for each spec → zonedSchedule(spec.id, title,
  //   body, TZDateTime.from(spec.fireAt.toLocal-equivalent), details, payload:
  //   spec.mealId, matchDateTimeComponents: null). withActions → Android/Darwin
  //   action lists. Use inexact scheduling (no exact-alarm permission).
  // consumeLaunchAction(): getNotificationAppLaunchDetails → if launched by an
  //   action, return its NotificationAction once.
  // ...implements every NotificationService member.
}
```

Action ids: `'ate_it'` → `NotificationActionKind.ateIt`, `'snooze'` → `.snooze`, `'skip'` → `.skip`. Android channel id `'meal_reminders'`, name `'Meal reminders'`. iOS category id `'meal'`.

**Steps:**

- [ ] 1. Add deps: `gtimeout 600 flutter pub add flutter_local_notifications timezone`. Verify `pubspec.yaml` lists both; `flutter pub get` clean.
- [ ] 2. **Failing test** — `..._service_test.dart`: `check(FlutterLocalNotificationsNotificationService()).isA<NotificationService>()` (compile/construct smoke — proves the class satisfies the port). Do NOT call `init`/`scheduleAll` in tests (no platform binding).
- [ ] 3. **Run — red:** `flutter test --timeout=90s test/data/services/flutter_local_notifications_notification_service_test.dart` → undefined class.
- [ ] 4. **Implement** the adapter (every member), the iOS `AppDelegate` Darwin init + action category, and the Android manifest `POST_NOTIFICATIONS` permission + `flutter_local_notifications` receiver/boot entries per the plugin README.
- [ ] 5. **Run — green:** `flutter test --timeout=90s test/data/services/flutter_local_notifications_notification_service_test.dart`.
- [ ] 6. Gates: `dart format .` · `flutter analyze` · `flutter test --timeout=90s`. Report for review. **Note in the report:** real fire/permission/action behavior needs manual device verification (CI has none) — list the manual steps you would run.

**Skills:** `.agents/skills/flutter-expert`. Consult the `flutter_local_notifications` + `timezone` package READMEs (context7) for current iOS/Android setup — do not copy stale snippets.

**Out of scope:** the pure schedule (T2), controller/di (T5), UI (T6). No business logic in this file.

---

## Task 5: Scheduler controller + action router + di wiring

**Role:** implement

**Goal:** Register the service in `di.dart`, add the session mute provider, and the `@riverpod` controller that recomputes+rearms on every today-`Day` change and the router that pipes actions into `dayController`.

**Files:**
- Modify: `lib/config/di.dart` (add `notificationServiceProvider`)
- Create: `lib/ui/features/today/view_models/notification_scheduler_controller.dart` (+ codegen `.g.dart`)
- Test: `test/ui/features/today/notification_scheduler_controller_test.dart`

**Contract:**

```dart
// di.dart — add (typed as the domain port; real impl in app, fake in tests):
final notificationServiceProvider = Provider<NotificationService>(
  (ref) => throw UnimplementedError('overridden in bootstrap()/tests'),
);
```

```dart
// notification_scheduler_controller.dart
import 'package:crudo/config/di.dart';
import 'package:crudo/domain/repositories/notification_service.dart';
import 'package:crudo/domain/services/notification_schedule.dart';
import 'package:crudo/domain/services/notification_spec.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'day_controller.dart';
import 'today_providers.dart';

part 'notification_scheduler_controller.g.dart';

/// Session-scoped "Mute today": holds the muted day-label (UTC) or null.
/// Lost on restart (no Prefs field — editing is S15). Set by StreakRiskSheet.
final mutedRiskDayProvider = StateProvider<DateTime?>((ref) => null);

/// Default snooze applied by the notification Snooze action.
const notificationSnoozePreset = Duration(minutes: 15);

/// Watches today's Day; on every change recomputes notificationSchedule and
/// cancel-all-rearms via NotificationService. Strips the risk spec when today
/// is muted. Mirrors StreakCatchUp's watch-today shape.
@riverpod
class NotificationScheduler extends _$NotificationScheduler {
  @override
  Future<void> build() async {
    final today = ref.watch(todayProvider);
    final day = await ref.watch(dayControllerProvider(today).future);
    final profile = await ref.read(profileRepositoryProvider).watch().first;
    final muted = ref.watch(mutedRiskDayProvider) == today;
    final now = ref.read(clockProvider)();

    var specs = notificationSchedule(day, profile.prefs, now);
    if (muted) {
      specs = specs
          .where((s) => s.kind != NotificationKind.risk)
          .toList(growable: false);
    }
    await ref.read(notificationServiceProvider).scheduleAll(specs);
  }
}

/// Pipes NotificationService.actions (and the one terminated-launch action)
/// into dayController for today. Activated by AppShell.
@riverpod
class NotificationActionRouter extends _$NotificationActionRouter {
  @override
  Future<void> build() async {
    final service = ref.read(notificationServiceProvider);
    final launch = await service.consumeLaunchAction();
    if (launch != null) await _route(launch);
    final sub = service.actions.listen(_route);
    ref.onDispose(sub.cancel);
  }

  /// Stale actions are NORMAL for notifications (the meal may already be done,
  /// the day rolled, the snooze bound passed) and the Day ops throw StateError
  /// on every violated guard (see lib/domain/day/day.dart). A stale tap is a
  /// no-op, never a crash — swallow StateError; let anything else surface.
  Future<void> _route(NotificationAction a) async {
    final today = ref.read(todayProvider);
    final ctrl = ref.read(dayControllerProvider(today).notifier);
    try {
      switch (a.kind) {
        case NotificationActionKind.ateIt:
          await ctrl.markAllEaten(a.mealId);
        case NotificationActionKind.snooze:
          final until = ref
              .read(clockProvider)()
              .toUtc()
              .add(notificationSnoozePreset);
          await ctrl.snooze(a.mealId, until);
        case NotificationActionKind.skip:
          await ctrl.skipMeal(a.mealId);
      }
    } on StateError {
      // Stale/ineligible action (meal already actioned, day locked, snooze
      // bound exceeded) — silently ignore.
    }
  }
}
```

**Steps (TDD):**

- [ ] 1. **Failing test** — `notification_scheduler_controller_test.dart` with a `ProviderContainer` overriding `notificationServiceProvider` with a `FakeNotificationService`, `clockProvider`, and seeded repos (follow `streak_catchup_controller_test.dart` for container setup). Assert: building `NotificationScheduler` calls `fake.scheduleAll` once with a non-empty spec list for a seeded today; setting `mutedRiskDayProvider` to today and rebuilding yields specs with **no** `NotificationKind.risk`; `NotificationActionRouter` — `fake.emitAction((mealId: <id>, kind: ateIt))` results in that meal's items all checked (read `dayControllerProvider(today)`); a preset `fake.launchAction` is routed once on build; **a stale action** (`kind: skip` on a meal whose items are already checked, which makes `skipMeal` throw `StateError`) is swallowed — `check(() async => router stays in AsyncData, no thrown error)` and the meal stays done (no-op).
- [ ] 2. **Run — red:** `flutter test --timeout=90s test/ui/features/today/notification_scheduler_controller_test.dart` → undefined providers.
- [ ] 3. **Implement** the contract; `gtimeout 600 dart run build_runner build`.
- [ ] 4. **Run — green:** `flutter test --timeout=90s test/ui/features/today/notification_scheduler_controller_test.dart`.
- [ ] 5. Gates: `dart format .` · `flutter analyze` · `flutter test --timeout=90s`. Report for review.

**Skills:** `.agents/skills/flutter-riverpod-arch`, `.agents/skills/dart-add-unit-test`, `.agents/skills/dart-migrate-to-checks-package`.

**Out of scope:** the sheet/AppShell wiring (T6), the real impl internals (T4), bootstrap override of `notificationServiceProvider` to the real impl (note it for review — bootstrap lives outside task scope; flag if `bootstrap()` needs the override added).

---

## Task 6: Streak-at-risk provider + sheet + AppShell listener

**Role:** ui

**Goal:** Surface streak-at-risk in-app: a provider deriving `StreakRisk?` (null unless at risk & unmuted), the gold-flame `StreakRiskSheet` matching the prototype, and the `AppShell` listener that shows it once per crossing.

**Files:**
- Create: `lib/ui/features/today/view_models/streak_at_risk_provider.dart` (+ codegen `.g.dart`)
- Create: `lib/ui/features/today/views/streak_risk_sheet.dart`
- Modify: `lib/ui/core/widgets/app_shell.dart` (add listener)
- Test: `test/ui/features/today/streak_risk_sheet_test.dart`

**Contract:**

```dart
// streak_at_risk_provider.dart
import 'package:crudo/config/di.dart';
import 'package:crudo/domain/services/notification_schedule.dart';
import 'package:crudo/domain/shared/meal_time.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'day_controller.dart';
import 'notification_scheduler_controller.dart';
import 'today_providers.dart';

part 'streak_at_risk_provider.g.dart';

/// In-app streak-at-risk banner data, or null when safe / lost / muted.
typedef StreakRisk = ({
  int streakDays,
  int mealsLeft,
  String pivotalMealName,
  MealTime pivotalMealTime,
  int minutesFromNow,
});

@riverpod
Future<StreakRisk?> streakAtRisk(Ref ref) async {
  final today = ref.watch(todayProvider);
  if (ref.watch(mutedRiskDayProvider) == today) return null;
  final day = await ref.watch(dayControllerProvider(today).future);
  final profile = await ref.read(profileRepositoryProvider).watch().first;
  final streak = await ref.read(streakRepositoryProvider).get();
  final now = ref.read(clockProvider)();
  final info = streakRiskInfo(day, profile.prefs.streakThreshold, now);
  if (info == null) return null;
  final mins = info.deadline.difference(now.toUtc()).inMinutes;
  return (
    streakDays: streak.current,
    mealsLeft: info.mealsLeft,
    pivotalMealName: info.pivotalMealName,
    pivotalMealTime: info.pivotalMealTime,
    minutesFromNow: mins < 0 ? 0 : mins,
  );
}
```

```dart
// streak_risk_sheet.dart — centered dialog, mirrors milestone_sheet.dart + prototype.
Future<void> showStreakRiskSheet(BuildContext context, StreakRisk risk);
// StreakRiskSheet (private dialog): surfaceLowest card, Shadows.cloud, Radii.lg;
// gold flame (Icons.local_fire_department, IconSizes.xl) in gold@0.15 circle;
// 'STREAK AT RISK' label (CrudoText.labelMd, colors.gold);
// headline (CrudoText.headline): '${risk.mealsLeft} meals left to keep ${risk.streakDays} days alive.';
// body (CrudoText.body): '${risk.pivotalMealName} at ${_fmt(risk.pivotalMealTime)} — ${risk.minutesFromNow} minutes from now.';
// PrimaryCta('Got it') → Navigator.pop;
// secondary text button 'Mute today' →
//   ref.read(mutedRiskDayProvider.notifier).state = ref.read(todayProvider);
//   then Navigator.pop. (Muting also makes streakAtRiskProvider re-emit null
//   and the scheduler strip the risk spec — both keyed on the same label.)
// _fmt(MealTime t) → 12-hour 'h:mm a' style ('4:00 PM'), hand-rolled from
//   t.hour/t.minute (no intl dependency). Sheet is a ConsumerWidget (needs ref).
```

```dart
// app_shell.dart — _AppShellState gains a once-per-day guard field:
//   DateTime? _riskShownForDay;
// streakAtRiskProvider re-emits the SAME StreakRisk on every today-Day
// mutation, so fire-on-every-emit would re-pop the sheet each time a meal is
// marked. Show at most once per calendar day: guard on the day label.
ref.listen<AsyncValue<StreakRisk?>>(streakAtRiskProvider, (prev, next) {
  final risk = next.asData?.value;
  if (risk == null) return;
  final today = ref.read(todayProvider);
  if (_riskShownForDay == today) return; // already shown today
  _riskShownForDay = today;
  WidgetsBinding.instance.addPostFrameCallback((_) {
    final ctx = _navigatorContext;
    if (ctx == null || !ctx.mounted) return;
    showStreakRiskSheet(ctx, risk);
  });
});
// Also activate the scheduler + router so they run while the shell is mounted:
ref.watch(notificationSchedulerProvider);
ref.watch(notificationActionRouterProvider);
```

**Steps (TDD):**

- [ ] 1. **Failing test** — `streak_risk_sheet_test.dart`: pump `StreakRiskSheet` with a fixed `StreakRisk` (streakDays: 12, mealsLeft: 2, pivotalMealName: 'Pre-Workout', pivotalMealTime: MealTime(16*60), minutesFromNow: 32) in a `ProviderScope`; assert the headline text `'2 meals left to keep 12 days alive.'` and body containing `'Pre-Workout at 4:00 PM — 32 minutes from now.'` render; tapping 'Mute today' sets `mutedRiskDayProvider` to today's label (read the container) and pops.
- [ ] 2. **Run — red:** `flutter test --timeout=90s test/ui/features/today/streak_risk_sheet_test.dart` → undefined `StreakRiskSheet`/`StreakRisk`.
- [ ] 3. **Implement** provider + sheet + AppShell listener; `gtimeout 600 dart run build_runner build`.
- [ ] 4. **Run — green:** `flutter test --timeout=90s test/ui/features/today/streak_risk_sheet_test.dart`.
- [ ] 5. Gates: `dart format .` · `flutter analyze` · `flutter test --timeout=90s`. Report for review.

**Skills:** `.agents/skills/flutter-riverpod-arch`, `.agents/skills/flutter-add-widget-test`, `.agents/skills/flutter-expert`. Tokens from `lib/ui/core/themes/` only — 4px grid, gold flame, `Shadows.cloud`, no 1px borders, never pure black (AGENTS.md design system).

**Out of scope:** scheduling logic (T2), the OS notification path (T4/T5 own it), Prefs editing (S15).

**Acceptance:** History/Today render unaffected; risk sheet appears in-app only when the day is recoverable-but-at-risk and not muted; "Mute today" suppresses it for the session; `flutter test --timeout=90s` green.
