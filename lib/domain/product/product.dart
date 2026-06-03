import 'package:freezed_annotation/freezed_annotation.dart';

import '../shared/enums.dart';

part 'product.freezed.dart';

/// A product library item (template tree). Macros are per 100 g.
/// `id` is an app-generated uuid v7. Built-in seed products have
/// `isCustom == false`; user-created ones `true` (category is orthogonal).
/// The ±10% kcalOverride rule is user-facing validation (validators.dart).
@freezed
abstract class Product with _$Product {
  const Product._();

  @Assert('protein >= 0', 'protein must be >= 0')
  @Assert('carbs >= 0', 'carbs must be >= 0')
  @Assert('fats >= 0', 'fats must be >= 0')
  const factory Product({
    required String id,
    required String name,
    required ProductCategory category,
    required double protein,
    required double carbs,
    required double fats,
    double? kcalOverride,
    @Default(false) bool isCustom,
  }) = _Product;
}
