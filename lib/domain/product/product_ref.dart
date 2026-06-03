import 'package:freezed_annotation/freezed_annotation.dart';

import '../shared/grams.dart';

part 'product_ref.freezed.dart';

/// A product reference + amount inside a [MealTemplate] (template tree).
/// Macros are derived via the nutrition service, never stored.
@freezed
abstract class ProductRef with _$ProductRef {
  const ProductRef._();

  const factory ProductRef({required String productId, required Grams grams}) =
      _ProductRef;
}
