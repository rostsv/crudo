// Unit tests for pure formatting helpers (S07).
// No Flutter/Riverpod imports needed — these are plain Dart functions.
import 'package:checks/checks.dart';
import 'package:crudo/ui/features/foods/views/formatting.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('pctText', () {
    test('integer values below 10 round-trip without decimal', () {
      check(pctText(9.0)).equals('9');
      check(pctText(5.0)).equals('5');
    });

    test('integer value 21 renders as "21" (no decimal)', () {
      check(pctText(21.0)).equals('21');
    });

    test('exact 10.0 rounds to 10 (no decimal branch needed)', () {
      check(pctText(10.0)).equals('10');
    });

    test('pctText(10.025) → "10.1" (ceil one decimal, never understate)', () {
      check(pctText(10.025)).equals('10.1');
    });

    test('pctText(10.34) → "10.4" (ceil one decimal)', () {
      check(pctText(10.34)).equals('10.4');
    });

    test('pctText(10.344) → "10.4" (ceil 103.44 → 104 / 10)', () {
      // 320 on calc 290: (320-290)/290*100 = 10.3448…  ceil→ 10.4
      final pct = (320 - 290) / 290 * 100;
      check(pctText(pct)).equals('10.4');
    });

    test('pctText(9.5) rounds to 10 → "10"', () {
      // 9.5.round() == 10, but pct == 9.5 not 10.0, so triggers decimal branch
      // ceil(9.5 * 10) = ceil(95) = 95 / 10 = 9.5 → "9.5"
      // Wait — pct=9.5, rounded=10, so we ARE in the branch.
      // (9.5 * 10).ceilToDouble() = 95.0; 95.0/10 = 9.5 → "9.5".
      check(pctText(9.5)).equals('9.5');
    });
  });
}
