// test/domain/day/day_test.dart
import 'package:checks/checks.dart';
import 'package:crudo/domain/day/day.dart';
import 'package:crudo/domain/shared/enums.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('open day: no verdict, defaults empty', () {
    final d = Day(date: DateTime.utc(2026, 6, 3));
    check(d.adherence).isNull();
    check(d.state).isNull();
    check(d.meals).isEmpty();
    check(d.sourcePlanId).isNull();
  });

  test('locked day carries frozen verdict', () {
    final d = Day(
      date: DateTime.utc(2026, 6, 2),
      adherence: 0.85,
      state: DayState.green,
    );
    check(d.adherence).equals(0.85);
    check(d.state).equals(DayState.green);
  });

  test('asserts date is a UTC-midnight label', () {
    check(() => Day(date: DateTime(2026, 6, 3))).throws<AssertionError>();
    check(
      () => Day(date: DateTime.utc(2026, 6, 3, 14)),
    ).throws<AssertionError>();
  });

  test('asserts adherence and state freeze together, adherence in [0,1]', () {
    check(
      () => Day(date: DateTime.utc(2026, 6, 2), adherence: 0.5),
    ).throws<AssertionError>();
    check(
      () => Day(date: DateTime.utc(2026, 6, 2), state: DayState.red),
    ).throws<AssertionError>();
    check(
      () => Day(
        date: DateTime.utc(2026, 6, 2),
        adherence: 1.2,
        state: DayState.green,
      ),
    ).throws<AssertionError>();
  });
}
