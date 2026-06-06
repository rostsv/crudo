import 'dart:async';

import 'package:crudo/domain/streak/streak.dart';
import 'package:crudo/domain/repositories/streak_repository.dart';

class InMemoryStreakRepository implements StreakRepository {
  Streak _streak = const Streak();
  final _changes = StreamController<Streak>.broadcast();

  @override
  Stream<Streak> watch() {
    late StreamController<Streak> controller;
    late StreamSubscription<Streak> sub;
    controller = StreamController<Streak>(
      onListen: () {
        controller.add(_streak);
        sub = _changes.stream.listen(controller.add);
      },
      onCancel: () {
        sub.cancel();
        controller.close();
      },
    );
    return controller.stream;
  }

  @override
  Future<Streak> get() async => _streak;

  @override
  Future<void> save(Streak streak) async {
    _streak = streak;
    _changes.add(streak);
  }
}
