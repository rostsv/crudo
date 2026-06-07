import 'package:freezed_annotation/freezed_annotation.dart';

import '../meal/meal_snapshot.dart';
import '../shared/enums.dart';
import '../shared/meal_time.dart';
import '../services/meal_status.dart';
import 'scheduled_meal.dart';

part 'day.freezed.dart';

/// A materialized day (instance tree, aggregate root): the user's local
/// calendar date + that day's scheduled meals. Identity = `date` (no domain
/// id; storage may add a surrogate key — S19 concern). ONE type serves
/// today/future/history — "locked" is DERIVED from the date (past = locked,
/// meal_lifecycle.dart). The frozen trio `adherence`/`thresholdUsed`/
/// `lockedAt` is null while the day is open and written exactly once by S12
/// at midnight-lock; storing the threshold USED that day means later settings
/// changes never recolor history (DayState derives: S12).
/// `date` is a date LABEL: the local calendar date encoded DateTime.utc(y,m,d).
@freezed
abstract class Day with _$Day {
  const Day._();

  @Assert('date.isUtc', 'date must be the UTC-encoded local-date label')
  @Assert(
    'date.hour == 0 && date.minute == 0 && date.second == 0 && '
        'date.millisecond == 0 && date.microsecond == 0',
    'date must be midnight-normalized',
  )
  @Assert(
    '(adherence == null) == (thresholdUsed == null) && '
        '(adherence == null) == (lockedAt == null)',
    'adherence, thresholdUsed and lockedAt are frozen together at lock',
  )
  @Assert(
    'adherence == null || (adherence >= 0 && adherence <= 1)',
    'adherence must be within [0,1]',
  )
  @Assert('lockedAt == null || lockedAt.isUtc', 'lockedAt must be UTC')
  factory Day({
    required DateTime date,
    String? sourcePlanId,
    String? planName,
    @Default(<ScheduledMeal>[]) List<ScheduledMeal> meals,
    double? adherence,
    int? thresholdUsed,
    DateTime? lockedAt,
  }) = _Day;

  // ───────────────────────── lifecycle ops (S05) ─────────────────────────
  // Each op returns a NEW Day or throws StateError on a violated guard —
  // views must pre-check with the predicates in meal_lifecycle.dart.
  // `mealId` is always ScheduledMeal.id; `itemIndex` addresses the items
  // list at call time (order is display-only — the index is a selector,
  // never persisted identity). Marking ops never touch skippedAt /
  // snoozedUntil: the stamps persist for analytics; derivation lets
  // checked win regardless.

  bool _locked(DateTime today) => date.isBefore(today);

  void _ensureUnlocked(DateTime today) {
    if (_locked(today)) {
      throw StateError('day $date is locked (today is $today)');
    }
  }

  ScheduledMeal _mealById(String mealId) => meals.firstWhere(
    (m) => m.id == mealId,
    orElse: () => throw StateError('no meal with id $mealId'),
  );

  Day _withMeal(ScheduledMeal updated) => copyWith(
    meals: [
      for (final m in meals)
        if (m.id == updated.id) updated else m,
    ],
  );

  Day _withItemStamp(
    String mealId,
    int itemIndex,
    DateTime? stamp,
    DateTime today,
  ) {
    _ensureUnlocked(today);
    final meal = _mealById(mealId);
    final items = meal.meal.items;
    if (itemIndex < 0 || itemIndex >= items.length) {
      throw StateError('item index $itemIndex out of range for $mealId');
    }
    final updated = [...items];
    updated[itemIndex] = updated[itemIndex].copyWith(checkedAt: stamp);
    return _withMeal(meal.copyWith(meal: meal.meal.copyWith(items: updated)));
  }

  Day checkItem(String mealId, int itemIndex, DateTime now, DateTime today) =>
      _withItemStamp(mealId, itemIndex, now.toUtc(), today);

  Day uncheckItem(String mealId, int itemIndex, DateTime now, DateTime today) =>
      _withItemStamp(mealId, itemIndex, null, today);

  /// "Ate it" one-tap: stamps every UNCHECKED item with now; items already
  /// checked keep their original (earlier) stamp.
  Day markAllEaten(String mealId, DateTime now, DateTime today) {
    _ensureUnlocked(today);
    final meal = _mealById(mealId);
    final stamp = now.toUtc();
    final items = [
      for (final i in meal.meal.items)
        if (i.checked) i else i.copyWith(checkedAt: stamp),
    ];
    return _withMeal(meal.copyWith(meal: meal.meal.copyWith(items: items)));
  }

  /// Undo for the one-tap complete: clears every item's stamp. Leaves
  /// skippedAt / snoozedUntil untouched (marking ops never touch the stamps);
  /// derivation falls back to them, so skipped → done → skipped round-trips.
  Day unmarkAll(String mealId, DateTime today) {
    _ensureUnlocked(today);
    final meal = _mealById(mealId);
    if (!meal.meal.anyChecked) {
      throw StateError('cannot unmark $mealId: nothing is checked');
    }
    final items = [
      for (final i in meal.meal.items) i.copyWith(checkedAt: null),
    ];
    return _withMeal(meal.copyWith(meal: meal.meal.copyWith(items: items)));
  }

  /// Explicit skip. Re-skip overwrites the stamp. Skipping an eaten meal is
  /// meaningless — uncheck first (UI pre-checks with canSkipMeal).
  Day skipMeal(String mealId, DateTime now, DateTime today) {
    _ensureUnlocked(today);
    final meal = _mealById(mealId);
    if (meal.meal.anyChecked) {
      throw StateError('cannot skip $mealId: items are checked');
    }
    return _withMeal(meal.copyWith(skippedAt: now.toUtc()));
  }

  /// Snooze bound: next meal by `time` STRICTLY greater (same-time meals do
  /// not bound each other), else the end-of-day midnight (start of date+1) —
  /// so a MealTime(0) meal can still snooze into its whole day. Returned UTC.
  DateTime maxSnoozeUntilFor(String mealId, DateTime now) {
    final meal = _mealById(mealId);
    MealTime? nextTime;
    for (final m in meals) {
      if (m.time.compareTo(meal.time) > 0 &&
          (nextTime == null || m.time.compareTo(nextTime) < 0)) {
        nextTime = m.time;
      }
    }
    final bound = nextTime == null
        ? endOfDayLocal(date)
        : localInstantAt(date, nextTime);
    return bound.toUtc();
  }

  /// Repeatable (overwrites), allowed post-window ("remind me later anyway").
  Day snoozeMeal(String mealId, DateTime until, DateTime now, DateTime today) {
    _ensureUnlocked(today);
    final meal = _mealById(mealId);
    if (meal.meal.allChecked) {
      throw StateError('cannot snooze $mealId: meal is done');
    }
    if (!until.isAfter(now) ||
        until.toUtc().isAfter(maxSnoozeUntilFor(mealId, now))) {
      throw StateError('snooze target $until violates bound');
    }
    return _withMeal(meal.copyWith(snoozedUntil: until.toUtc()));
  }

  /// Whole-content swap — the slot's id + time survive (notifications keep
  /// their key). Content-edit guard: only while derived status is upcoming
  /// (any checked item, explicit skip, or a passed window locks content).
  Day replaceMeal(
    String mealId,
    MealSnapshot newMeal,
    DateTime now,
    DateTime today,
  ) {
    _ensureUnlocked(today);
    final meal = _mealById(mealId);
    if (deriveMealStatus(meal, date, now, now) != MealStatus.upcoming) {
      throw StateError('cannot edit $mealId: status is not upcoming');
    }
    return _withMeal(meal.copyWith(meal: newMeal));
  }
}
