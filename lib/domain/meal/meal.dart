import 'package:freezed_annotation/freezed_annotation.dart';

import '../shared/enums.dart';
import '../shared/meal_time.dart';
import 'meal_product.dart';

part 'meal.freezed.dart';

/// An instance meal — the scheduling WRAPPER (instance tree): a slot-stable
/// `id` + `time` + detached snapshot content. Notifications and "this meal"
/// references key off `id`; swapping the content (grams edits, product swaps,
/// whole-meal swaps) keeps `id` and `time` — only `sourceMealTemplateId`,
/// `name`, `tags`, `products` change. Status is DERIVED (checked flags + time,
/// S05) and deliberately not a field.
@freezed
abstract class Meal with _$Meal {
  const Meal._();

  const factory Meal({
    required String id,
    required MealTime time,
    String? sourceMealTemplateId,
    required String name,
    @Default(<MealTag>[]) List<MealTag> tags,
    @Default(<MealProduct>[]) List<MealProduct> products,
  }) = _Meal;
}
