import 'package:checks/checks.dart';
import 'package:crudo/domain/shared/grams.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('holds value, equality, compareTo', () {
    check(const Grams(150).value).equals(150);
    check(const Grams(12.5)).equals(const Grams(12.5));
    check(const Grams(50).compareTo(const Grams(100))).isLessThan(0);
  });

  test('asserts > 0', () {
    check(() => Grams(0)).throws<AssertionError>();
    check(() => Grams(-10)).throws<AssertionError>();
  });
}
