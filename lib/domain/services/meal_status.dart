import '../day/scheduled_meal.dart';
import '../shared/enums.dart';
import '../shared/meal_time.dart';

/// Status derivation (S05). Status is NEVER stored — recomputed per read from
/// (checked marks, skippedAt, snoozedUntil, time, dayDate, now). This file
/// deliberately does not import Day, so Day's ops can import it cycle-free.

/// The user's local calendar date at [now], UTC-encoded (Day.date convention).
DateTime localDateLabel(DateTime now) {
  final local = now.toLocal();
  return DateTime.utc(local.year, local.month, local.day);
}

/// The local wall-clock instant of [time] on the labeled date.
DateTime localInstantAt(DateTime dayDate, MealTime time) =>
    DateTime(dayDate.year, dayDate.month, dayDate.day, time.hour, time.minute);

/// Start of the next local day — the midnight that ends [dayDate].
DateTime endOfDayLocal(DateTime dayDate) =>
    DateTime(dayDate.year, dayDate.month, dayDate.day + 1);

/// Priority chain (spec §Status derivation):
///   1 any item checked → done/partial   (clock + stamps irrelevant)
///   2 past day         → skipped        (history freezes unchecked)
///   3 future day       → upcoming       (preview)
///   4 skippedAt set    → skipped        (explicit skip, shown pre-window too)
///   5 snooze pending   → upcoming       (UI chips off the field)
///   6 meal time passed → skipped        (auto-skip, exact time, no grace)
///   7 otherwise        → upcoming
MealStatus deriveMealStatus(
  ScheduledMeal meal,
  DateTime dayDate,
  DateTime now,
) {
  final items = meal.meal.items;
  final checked = items.where((i) => i.checked).length;
  if (checked > 0) {
    return checked == items.length ? MealStatus.done : MealStatus.partial;
  }
  final today = localDateLabel(now);
  if (dayDate.isBefore(today)) return MealStatus.skipped;
  if (dayDate.isAfter(today)) return MealStatus.upcoming;
  if (meal.skippedAt != null) return MealStatus.skipped;
  final snoozedUntil = meal.snoozedUntil;
  if (snoozedUntil != null && snoozedUntil.isAfter(now)) {
    return MealStatus.upcoming;
  }
  if (!now.toLocal().isBefore(localInstantAt(dayDate, meal.time))) {
    return MealStatus.skipped;
  }
  return MealStatus.upcoming;
}
