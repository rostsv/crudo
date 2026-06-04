import 'package:freezed_annotation/freezed_annotation.dart';

import '../shared/grams.dart';

part 'food_ref.freezed.dart';

/// A food reference + amount inside a [MealTemplate] (template tree).
/// Macros are derived via the nutrition service, never stored.
@freezed
abstract class FoodRef with _$FoodRef {
  const FoodRef._();

  const factory FoodRef({required String foodId, required Grams grams}) =
      _FoodRef;
}
