import 'package:crudo/config/di.dart';
import 'package:crudo/domain/repositories/notification_service.dart';
import 'package:crudo/domain/services/notification_schedule.dart';
import 'package:crudo/domain/services/notification_spec.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'day_controller.dart';
import 'today_providers.dart';

part 'notification_scheduler_controller.g.dart';

/// Session-scoped "Mute today": holds the muted day-label (UTC) or null.
/// Lost on restart (no Prefs field — editing is S15). Set by StreakRiskSheet.
@riverpod
class MutedRiskDay extends _$MutedRiskDay {
  @override
  DateTime? build() => null;

  void set(DateTime? day) => state = day;
}

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
