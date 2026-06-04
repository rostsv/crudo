import 'package:freezed_annotation/freezed_annotation.dart';

import '../food/food_ref.dart';
import '../shared/enums.dart';

part 'meal_template.freezed.dart';

/// A reusable meal recipe (template tree): food refs + tags, deliberately
/// time-free — WHEN it is eaten belongs to the plan ([PlanSlot.time]).
@freezed
abstract class MealTemplate with _$MealTemplate {
  const MealTemplate._();

  const factory MealTemplate({
    required String id,
    required String name,
    @Default(<MealTag>[]) List<MealTag> tags,
    @Default(<FoodRef>[]) List<FoodRef> foods,
  }) = _MealTemplate;
}
