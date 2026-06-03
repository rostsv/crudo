import 'dart:async';

import 'package:crudo/domain/day/day.dart';
import 'package:crudo/domain/repositories/day_repository.dart';

class InMemoryDayRepository implements DayRepository {
  final _store = <DateTime, Day>{};
  final _changes = StreamController<void>.broadcast();

  @override
  Stream<Day?> watchByDate(DateTime date) async* {
    yield _store[date];
    yield* _changes.stream.map((_) => _store[date]);
  }

  @override
  Future<Day?> getByDate(DateTime date) async => _store[date];

  @override
  Future<List<Day>> getRange(DateTime from, DateTime to) async {
    final days =
        _store.entries
            .where((e) => !e.key.isBefore(from) && !e.key.isAfter(to))
            .map((e) => e.value)
            .toList()
          ..sort((a, b) => a.date.compareTo(b.date));
    return List.unmodifiable(days);
  }

  @override
  Future<void> save(Day day) async {
    _store[day.date] = day;
    _changes.add(null);
  }
}
