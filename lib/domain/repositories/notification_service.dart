import '../services/notification_spec.dart';

/// The kind of action a user takes on a meal notification.
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
