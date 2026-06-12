import 'package:freezed_annotation/freezed_annotation.dart';

part 'notification_spec.freezed.dart';

/// The kind of notification: pre-meal reminder, meal-time alert, end-of-day
/// summary, or streak-at-risk warning.
enum NotificationKind { pre, at, endOfDay, risk }

/// One scheduled local notification. `id` is deterministic in (mealId, kind)
/// so a recompute reuses the same OS slot. `mealId` is the ScheduledMeal.id
/// payload that action taps key off (null for endOfDay). `withActions` is true
/// only for `at`. `fireAt` is UTC.
@freezed
abstract class NotificationSpec with _$NotificationSpec {
  const NotificationSpec._();

  @Assert('fireAt.isUtc', 'fireAt must be UTC')
  factory NotificationSpec({
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
