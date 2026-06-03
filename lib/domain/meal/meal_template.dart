import 'package:freezed_annotation/freezed_annotation.dart';

import '../product/product_ref.dart';
import '../shared/enums.dart';

part 'meal_template.freezed.dart';

/// A reusable meal recipe (template tree): products + tags, deliberately
/// time-free — WHEN it is eaten belongs to the plan ([PlanSlot.time]).
@freezed
abstract class MealTemplate with _$MealTemplate {
  const MealTemplate._();

  const factory MealTemplate({
    required String id,
    required String name,
    @Default(<MealTag>[]) List<MealTag> tags,
    @Default(<ProductRef>[]) List<ProductRef> products,
  }) = _MealTemplate;
}
