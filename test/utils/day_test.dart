// test/utils/day_test.dart
import 'package:checks/checks.dart';
import 'package:crudo/utils/day.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('dayKey strips time, preserves utc flag', () {
    check(dayKey(DateTime(2026, 6, 3, 13, 45))).equals(DateTime(2026, 6, 3));
    check(
      dayKey(DateTime.utc(2026, 6, 3, 13, 45)),
    ).equals(DateTime.utc(2026, 6, 3));
  });

  test('isSameDay ignores time, distinguishes dates', () {
    check(
      isSameDay(DateTime(2026, 6, 3, 1), DateTime(2026, 6, 3, 23)),
    ).isTrue();
    check(
      isSameDay(DateTime(2026, 6, 3, 23, 59), DateTime(2026, 6, 4, 0, 1)),
    ).isFalse();
  });

  test('weekdayIndex maps Mon..Sun to 0..6', () {
    check(
      weekdayIndex(DateTime(2026, 6, 1)),
    ).equals(0); // 2026-06-01 is a Monday
    check(weekdayIndex(DateTime(2026, 6, 7))).equals(6); // Sunday
  });

  test('addDays normalizes, crosses boundaries, handles negatives', () {
    check(addDays(DateTime(2026, 6, 3, 18), 1)).equals(DateTime(2026, 6, 4));
    check(addDays(DateTime(2026, 6, 30), 1)).equals(DateTime(2026, 7, 1));
    check(addDays(DateTime(2026, 12, 31), 1)).equals(DateTime(2027, 1, 1));
    check(addDays(DateTime(2026, 6, 3), -1)).equals(DateTime(2026, 6, 2));
    check(
      addDays(DateTime.utc(2026, 6, 3), 1),
    ).equals(DateTime.utc(2026, 6, 4));
  });

  test(
    'localDayLabel converts a UTC instant to a UTC-midnight local-date label',
    () {
      final label = localDayLabel(DateTime.utc(2026, 6, 3, 12));
      final expected = DateTime.utc(2026, 6, 3, 12).toLocal();
      check(
        label,
      ).equals(DateTime.utc(expected.year, expected.month, expected.day));
      check(label.isUtc).isTrue();
      check(label.hour).equals(0);
    },
  );
}
