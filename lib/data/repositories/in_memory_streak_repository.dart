import 'dart:async';

import 'package:crudo/domain/streak/streak.dart';
import 'package:crudo/domain/repositories/streak_repository.dart';

class InMemoryStreakRepository implements StreakRepository {
  Streak _streak = const Streak();
  final _changes = StreamController<Streak>.broadcast();

  @override
  Stream<Streak> watch() async* {
    yield _streak;
    yield* _changes.stream;
  }

  @override
  Future<Streak> get() async => _streak;

  @override
  Future<void> save(Streak streak) async {
    _streak = streak;
    _changes.add(streak);
  }
}
