import 'package:freezed_annotation/freezed_annotation.dart';

import '../shared/enums.dart';

part 'food.freezed.dart';

/// A food library item (template tree). Macros + kcal are per 100 g.
/// `kcalPer100g` is a plain stored value: defaulted to the Atwater formula at
/// input time, or user-entered and validated within ±10% (S07 owns that flow).
/// There is no override field — the accepted value simply IS the kcal.
/// `kind` is display/filter only; `id` is an app-generated uuid v7
/// (seed ids are readable strings). Seed foods have `isCustom == false`.
@freezed
abstract class Food with _$Food {
  const Food._();

  @Assert('protein >= 0', 'protein must be >= 0')
  @Assert('carbs >= 0', 'carbs must be >= 0')
  @Assert('fats >= 0', 'fats must be >= 0')
  @Assert('kcalPer100g >= 0', 'kcalPer100g must be >= 0')
  const factory Food({
    required String id,
    required String name,
    @Default(FoodKind.product) FoodKind kind,
    required FoodCategory category,
    required double protein,
    required double carbs,
    required double fats,
    required double kcalPer100g,
    @Default(false) bool isCustom,
  }) = _Food;
}
