import '../day/day.dart';
import '../profile/prefs.dart';
import '../shared/enums.dart';
import '../shared/meal_time.dart';
import 'meal_lifecycle.dart';
import 'meal_status.dart';
import 'notification_spec.dart';
import 'nutrition.dart';

/// Local time-of-day the end-of-day summary fires (21:30). Tunable constant,
/// not a Prefs field. Below endOfDayLocal(date) by construction.
const int endOfDaySummaryMinutes = 21 * 60 + 30; // 1290

/// The pivotal-meal info for a streak at risk, or null when the day is already
/// safe (consumed >= threshold) or already unrecoverable (eating everything left
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

/// Computes the streak risk info for a day, or null if the day is already safe
/// or already lost (unrecoverable).
///
/// `threshold` is the user's streak threshold in percent (e.g. 80).
/// `now` is the current local wall-clock time.
RiskInfo? streakRiskInfo(Day day, int threshold, DateTime now) {
  final planned = plannedKcal(day);
  if (planned <= 0) return null;

  final target = planned * threshold / 100.0;
  final consumed = consumedKcal(day);
  if (consumed >= target) return null;

  // Collect upcoming meals sorted by time.
  final upcoming =
      <
        ({
          DateTime deadline,
          String id,
          MealTime time,
          String name,
          double kcal,
        })
      >[];
  for (final m in day.meals) {
    final status = mealStatus(day, m.id, now);
    if (status == MealStatus.upcoming) {
      upcoming.add((
        deadline: localInstantAt(day.date, m.time).toUtc(),
        id: m.id,
        time: m.time,
        name: m.meal.name,
        kcal: mealSnapshotMacros(m.meal).kcal,
      ));
    }
  }
  upcoming.sort((a, b) => a.time.compareTo(b.time));

  final remainingKcal = upcoming.fold(0.0, (sum, m) => sum + m.kcal);
  if (consumed + remainingKcal < target) return null;

  // Walk meals from earliest; find the critical one.
  double acc = consumed;
  ({String id, MealTime time, String name})? pivotal;
  for (final m in upcoming) {
    acc += m.kcal;
    if (acc >= target) {
      pivotal = (id: m.id, time: m.time, name: m.name);
      break;
    }
  }

  if (pivotal == null) return null;

  return (
    deadline: localInstantAt(day.date, pivotal.time).toUtc(),
    pivotalMealId: pivotal.id,
    pivotalMealTime: pivotal.time,
    pivotalMealName: pivotal.name,
    mealsLeft: upcoming.length,
  );
}

/// Pure. The full set of notifications that SHOULD be live for [day] given
/// [prefs] and [now]. Each kind gated by its Prefs toggle. pre/at/eod skip
/// instants already in the past; risk may fire at `now` if the deadline passed
/// but the day is still recoverable. All `fireAt` UTC. Caller (scheduler) is
/// responsible for dropping the risk spec when today is muted.
List<NotificationSpec> notificationSchedule(
  Day day,
  Prefs prefs,
  DateTime now,
) {
  final specs = <NotificationSpec>[];
  final nowUtc = now.toUtc();

  for (final m in day.meals) {
    final status = mealStatus(day, m.id, now);
    if (status != MealStatus.upcoming) continue;

    // Pre-meal reminder.
    if (prefs.preOn) {
      final fireAt = localInstantAt(
        day.date,
        m.time,
      ).toUtc().subtract(Duration(minutes: prefs.preMin));
      if (fireAt.isAfter(nowUtc)) {
        specs.add(
          NotificationSpec(
            id: notificationId(m.id, NotificationKind.pre),
            kind: NotificationKind.pre,
            fireAt: fireAt,
            title: 'Coming up',
            body: '${m.meal.name} in ${prefs.preMin} min',
            mealId: m.id,
          ),
        );
      }
    }

    // Meal-time alert.
    if (prefs.atOn) {
      final fireAt = localInstantAt(day.date, m.time).toUtc();
      if (fireAt.isAfter(nowUtc)) {
        specs.add(
          NotificationSpec(
            id: notificationId(m.id, NotificationKind.at),
            kind: NotificationKind.at,
            fireAt: fireAt,
            title: 'Time to eat',
            body: 'Time to eat ${m.meal.name}',
            mealId: m.id,
            withActions: true,
          ),
        );
      }
    }
  }

  // End-of-day summary.
  if (prefs.eodOn) {
    final fireAt = DateTime(
      day.date.year,
      day.date.month,
      day.date.day,
      endOfDaySummaryMinutes ~/ 60,
      endOfDaySummaryMinutes % 60,
    ).toUtc();
    if (fireAt.isAfter(nowUtc)) {
      specs.add(
        NotificationSpec(
          id: notificationId(null, NotificationKind.endOfDay),
          kind: NotificationKind.endOfDay,
          fireAt: fireAt,
          title: 'Daily recap',
          body:
              '${consumedKcal(day).round()} of ${plannedKcal(day).round()} kcal · keep your streak alive',
        ),
      );
    }
  }

  // Streak-at-risk warning.
  if (prefs.riskOn) {
    final info = streakRiskInfo(day, prefs.streakThreshold, now);
    if (info != null) {
      final fireAt = info.deadline.isAfter(nowUtc) ? info.deadline : nowUtc;
      specs.add(
        NotificationSpec(
          id: notificationId(null, NotificationKind.risk),
          kind: NotificationKind.risk,
          fireAt: fireAt,
          title: 'Streak at risk',
          body: '${info.mealsLeft} meals left — ${info.pivotalMealName} next',
        ),
      );
    }
  }

  return specs;
}
