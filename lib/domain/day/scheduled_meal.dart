import 'package:freezed_annotation/freezed_annotation.dart';

import '../meal/meal_snapshot.dart';
import '../shared/meal_time.dart';

part 'scheduled_meal.freezed.dart';

/// Scheduling wrapper (instance tree, entity inside the Day aggregate):
/// slot-stable `id` (uuid v7 — notifications key off it) + `time` + timing
/// acts. Swapping content replaces `meal` only — `id` and `time` survive.
/// `skippedAt`/`snoozedUntil` persist forever (analytics); derivation ignores
/// them once anything is checked. Status is DERIVED (meal_status.dart),
/// deliberately not a field. Non-const factory: asserts need .isUtc.
@freezed
abstract class ScheduledMeal with _$ScheduledMeal {
  const ScheduledMeal._();

  @Assert('id != ""', 'id must not be empty')
  @Assert('skippedAt == null || skippedAt.isUtc', 'skippedAt must be UTC')
  @Assert(
    'snoozedUntil == null || snoozedUntil.isUtc',
    'snoozedUntil must be UTC',
  )
  factory ScheduledMeal({
    required String id,
    required MealTime time,
    DateTime? skippedAt,
    DateTime? snoozedUntil,
    required MealSnapshot meal,
  }) = _ScheduledMeal;
}
