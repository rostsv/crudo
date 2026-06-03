import 'package:freezed_annotation/freezed_annotation.dart';

import '../shared/enums.dart';
import '../shared/grams.dart';

part 'meal_product.freezed.dart';

/// A snapshotted product inside an instance [Meal] (instance tree). Carries its
/// own name + per-100g macros so later library edits/deletes never alter this
/// day (architecture §8). `sourceProductId` is a weak back-ref only — nothing
/// about display or calculation depends on it.
@freezed
abstract class MealProduct with _$MealProduct {
  const MealProduct._();

  @Assert('protein >= 0', 'protein must be >= 0')
  @Assert('carbs >= 0', 'carbs must be >= 0')
  @Assert('fats >= 0', 'fats must be >= 0')
  const factory MealProduct({
    String? sourceProductId,
    required String name,
    required ProductCategory category,
    required double protein,
    required double carbs,
    required double fats,
    double? kcalOverride,
    required Grams grams,
    @Default(false) bool checked,
  }) = _MealProduct;
}
