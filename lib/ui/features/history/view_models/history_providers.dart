import 'package:crudo/config/di.dart';
import 'package:crudo/domain/day/day.dart';
import 'package:crudo/domain/services/adherence.dart';
import 'package:crudo/domain/services/meal_lifecycle.dart';
import 'package:crudo/domain/services/meal_status.dart';
import 'package:crudo/domain/shared/enums.dart';
import 'package:crudo/domain/streak/streak.dart';
import 'package:crudo/ui/features/today/view_models/today_providers.dart';
import 'package:crudo/ui/features/today/views/formatting.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'history_providers.g.dart';

/// Open today vs a locked past day vs a future (not-yet) day.
enum DayCellKind { locked, today, future }

typedef WeekCell = ({
  DateTime date,
  double adherence,
  DayState? state,
  DayCellKind kind,
});
typedef HistoryStats = ({
  int adherencePct,
  int mealsDone,
  int avgKcal,
  int skipped,
});
typedef RecentDay = ({
  DateTime date,
  double adherence,
  DayState state,
  int done,
  int total,
});
typedef CalendarCell = ({
  DateTime date,
  DayState? state,
  DayCellKind kind,
  int done,
  int total,
  int kcal,
  int adherencePct,
});

int _threshold(Ref ref) =>
    ref.watch(profileProvider).value?.prefs.streakThreshold ?? 80;

int _done(Day d, DateTime now) => d.meals
    .where((m) => deriveMealStatus(m, d.date, now, now) == MealStatus.done)
    .length;

int _skipped(Day d, DateTime now) => d.meals
    .where((m) => deriveMealStatus(m, d.date, now, now) == MealStatus.skipped)
    .length;

DayCellKind _dayCellKind(DateTime date, DateTime today) {
  if (date.isAfter(today)) return DayCellKind.future;
  if (date == today) return DayCellKind.today;
  return DayCellKind.locked;
}

DayState? _dayStateFor(
  DateTime date,
  Day? day,
  DateTime today,
  int threshold,
  DateTime now,
) {
  if (date.isAfter(today)) return null;
  if (date == today) {
    return classifyDayState(day != null ? dayAdherence(day) : 0.0, threshold);
  }
  // Past date
  if (day != null && day.lockedAt != null) return frozenDayState(day);
  // Past date with open day or no day (shouldn't happen post-catch-up)
  if (day != null) return classifyDayState(dayAdherence(day), threshold);
  return classifyDayState(0.0, threshold);
}

double _adherenceFor(Day? day) =>
    day != null ? (day.adherence ?? dayAdherence(day)) : 0.0;

/// Full streak (current + personalBest).
@riverpod
Stream<Streak> streak(Ref ref) => ref.watch(streakRepositoryProvider).watch();

/// Mon..Sun of weekOf(today). Past locked days use frozenDayState; today uses
/// live classifyDayState; future cells carry null state.
@riverpod
Future<List<WeekCell>> weeklyAdherence(Ref ref) async {
  final today = ref.watch(todayProvider);
  ref.watch(streakProvider); // trigger recompute after lock
  final threshold = _threshold(ref);
  final now = ref.read(clockProvider)();

  final days = weekOf(today);
  final from = days.first;
  final to = days.last;
  final repoDays = await ref.read(dayRepositoryProvider).getRange(from, to);
  final byDate = {for (final d in repoDays) d.date: d};

  return [
    for (final date in days)
      _buildWeekCell(date, byDate[date], today, threshold, now),
  ];
}

WeekCell _buildWeekCell(
  DateTime date,
  Day? day,
  DateTime today,
  int threshold,
  DateTime now,
) {
  return (
    date: date,
    adherence: _adherenceFor(day),
    state: _dayStateFor(date, day, today, threshold, now),
    kind: _dayCellKind(date, today),
  );
}

/// 30-day rollup ending today inclusive (getRange(today-29d, today)).
/// Empty range → all 0.
@riverpod
Future<HistoryStats> historyStats(Ref ref) async {
  final today = ref.watch(todayProvider);
  final now = ref.read(clockProvider)();
  ref.watch(streakProvider);

  final from = today.subtract(const Duration(days: 29));
  final days = await ref.read(dayRepositoryProvider).getRange(from, today);

  if (days.isEmpty) {
    return (adherencePct: 0, mealsDone: 0, avgKcal: 0, skipped: 0);
  }

  var totalAdherence = 0.0;
  var totalDone = 0;
  var totalKcal = 0.0;
  var totalSkipped = 0;

  for (final d in days) {
    final adh = d.adherence ?? dayAdherence(d);
    totalAdherence += adh;
    totalDone += _done(d, now);
    totalKcal += consumedKcal(d);
    totalSkipped += _skipped(d, now);
  }

  final n = days.length;
  return (
    adherencePct: (totalAdherence / n * 100).round(),
    mealsDone: totalDone,
    avgKcal: (totalKcal / n).round(),
    skipped: totalSkipped,
  );
}

/// Last 5 days descending (today first).
@riverpod
Future<List<RecentDay>> recentDays(Ref ref) async {
  final today = ref.watch(todayProvider);
  final threshold = _threshold(ref);
  final now = ref.read(clockProvider)();
  ref.watch(streakProvider);

  final from = today.subtract(const Duration(days: 4));
  final days = await ref.read(dayRepositoryProvider).getRange(from, today);
  final byDate = {for (final d in days) d.date: d};

  return [
    for (var i = 0; i < 5; i++)
      _buildRecentDay(today, i, byDate, today, threshold, now),
  ];
}

RecentDay _buildRecentDay(
  DateTime today,
  int offset,
  Map<DateTime, Day> byDate,
  DateTime todayParam,
  int threshold,
  DateTime now,
) {
  final date = today.subtract(Duration(days: offset));
  final day = byDate[date];
  final state = _dayStateFor(date, day, todayParam, threshold, now);
  return (
    date: date,
    adherence: _adherenceFor(day),
    state: state ?? DayState.red,
    done: day != null ? _done(day, now) : 0,
    total: day?.meals.length ?? 0,
  );
}

/// Cells for [month]'s grid, Mon-first: leading nulls then one cell/day.
/// Days after today have kind=future and null state. Past days use frozen/live.
@riverpod
Future<List<CalendarCell?>> monthGrid(Ref ref, DateTime month) async {
  final today = ref.watch(todayProvider);
  final threshold = _threshold(ref);
  final now = ref.read(clockProvider)();
  ref.watch(streakProvider);

  final firstOfMonth = DateTime.utc(month.year, month.month, 1);
  final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
  final lastOfMonth = DateTime.utc(month.year, month.month, daysInMonth);

  final firstMonday = firstOfMonth.subtract(
    Duration(days: firstOfMonth.weekday - 1),
  );
  final lastSunday = lastOfMonth.add(Duration(days: 7 - lastOfMonth.weekday));

  final repoDays = await ref
      .read(dayRepositoryProvider)
      .getRange(firstMonday, lastSunday);
  final byDate = {for (final d in repoDays) d.date: d};

  final result = <CalendarCell?>[];
  var d = firstMonday;
  while (!d.isAfter(lastSunday)) {
    if (d.month == month.month) {
      final day = byDate[d];
      final kind = _dayCellKind(d, today);
      final state = d.isAfter(today)
          ? null
          : _dayStateFor(d, day, today, threshold, now);
      final adherenceVal = _adherenceFor(day);
      result.add((
        date: d,
        state: state,
        kind: kind,
        done: day != null ? _done(day, now) : 0,
        total: day?.meals.length ?? 0,
        kcal: day != null ? consumedKcal(day).round() : 0,
        adherencePct: (adherenceVal * 100).round(),
      ));
    } else {
      result.add(null);
    }
    d = d.add(const Duration(days: 1));
  }

  return result;
}
