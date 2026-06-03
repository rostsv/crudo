// test/domain/streak/streak_test.dart
import 'package:checks/checks.dart';
import 'package:crudo/domain/streak/streak.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('defaults to zero, no last day', () {
    const s = Streak();
    check(s.current).equals(0);
    check(s.personalBest).equals(0);
    check(s.lastCountedDay).isNull();
  });

  test('asserts non-negative and best >= current', () {
    check(() => Streak(current: -1)).throws<AssertionError>();
    check(() => Streak(current: 5, personalBest: 3)).throws<AssertionError>();
  });

  test('valid streak', () {
    final s = Streak(
      current: 5,
      personalBest: 12,
      lastCountedDay: DateTime.utc(2026, 6, 2),
    );
    check(s.personalBest).equals(12);
  });
}
