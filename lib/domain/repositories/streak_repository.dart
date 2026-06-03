import '../streak/streak.dart';

/// Single source of truth for the calorie-based streak.
/// [watch] emits the current streak immediately on listen, then on every change.
/// [get] defaults to [const Streak()].
abstract class StreakRepository {
  Stream<Streak> watch();
  Future<Streak> get();
  Future<void> save(Streak streak);
}
