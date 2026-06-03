import 'package:checks/checks.dart';
import 'package:crudo/domain/shared/macros.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('defaults to zero', () {
    const m = Macros();
    check(m.protein).equals(0);
    check(m.carbs).equals(0);
    check(m.fats).equals(0);
    check(m.kcal).equals(0);
  });

  test('value equality + copyWith', () {
    const m = Macros(protein: 10, carbs: 20, fats: 5, kcal: 165);
    check(m).equals(const Macros(protein: 10, carbs: 20, fats: 5, kcal: 165));
    check(m.copyWith(kcal: 200).protein).equals(10);
  });

  test('operator + sums componentwise', () {
    const a = Macros(protein: 10, carbs: 20, fats: 5, kcal: 165);
    const b = Macros(protein: 1, carbs: 2, fats: 3, kcal: 39);
    check(
      a + b,
    ).equals(const Macros(protein: 11, carbs: 22, fats: 8, kcal: 204));
  });
}
