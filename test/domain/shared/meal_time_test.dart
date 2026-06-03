import 'package:checks/checks.dart';
import 'package:crudo/domain/shared/meal_time.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('exposes hour and minute', () {
    const t = MealTime(485); // 08:05
    check(t.hour).equals(8);
    check(t.minute).equals(5);
    check(t.minutesOfDay).equals(485);
  });

  test('value equality + compareTo', () {
    check(const MealTime(480)).equals(const MealTime(480));
    check(const MealTime(480).compareTo(const MealTime(720))).isLessThan(0);
  });

  test('asserts 0..1439', () {
    check(() => MealTime(-1)).throws<AssertionError>();
    check(() => MealTime(1440)).throws<AssertionError>();
    check(MealTime(0).minutesOfDay).equals(0);
    check(MealTime(1439).hour).equals(23);
  });
}
