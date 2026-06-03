import '../day/day.dart';

/// Materialized days, keyed by [Day.date] (UTC-midnight local-date label).
/// [watchByDate] emits the current snapshot immediately on listen, then on
/// every change. [getRange] is inclusive and sorted by date.
abstract class DayRepository {
  Stream<Day?> watchByDate(DateTime date);
  Future<Day?> getByDate(DateTime date);
  Future<List<Day>> getRange(DateTime from, DateTime to);
  Future<void> save(Day day);
}
