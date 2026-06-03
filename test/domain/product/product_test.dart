// test/domain/product/product_test.dart
import 'package:checks/checks.dart';
import 'package:crudo/domain/product/product.dart';
import 'package:crudo/domain/product/product_ref.dart';
import 'package:crudo/domain/shared/enums.dart';
import 'package:crudo/domain/shared/grams.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const chicken = Product(
    id: '0197-aaaa',
    name: 'Chicken breast',
    category: ProductCategory.meat,
    protein: 31,
    carbs: 0,
    fats: 3.6,
  );

  test('defaults: not custom, no override', () {
    check(chicken.isCustom).isFalse();
    check(chicken.kcalOverride).isNull();
  });

  test('value equality + copyWith', () {
    check(chicken.copyWith(name: 'Chicken thigh').name).equals('Chicken thigh');
    check(chicken.copyWith(name: 'Chicken thigh').protein).equals(31);
  });

  test('asserts non-negative macros', () {
    check(
      () => Product(
        id: 'x',
        name: 'Bad',
        category: ProductCategory.custom,
        protein: -1,
        carbs: 0,
        fats: 0,
      ),
    ).throws<AssertionError>();
  });

  test('product ref holds Grams VO', () {
    const ref = ProductRef(productId: '0197-aaaa', grams: Grams(150));
    check(ref.grams.value).equals(150);
    check(
      ref,
    ).equals(const ProductRef(productId: '0197-aaaa', grams: Grams(150)));
  });
}
