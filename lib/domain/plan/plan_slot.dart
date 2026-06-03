import 'package:freezed_annotation/freezed_annotation.dart';

import '../shared/meal_time.dart';

part 'plan_slot.freezed.dart';

/// A slot in a [PlanTemplate]: WHICH meal template at WHAT time. Time lives
/// here (not on the meal) so one template is reusable at different times
/// across plans. Materialization (S05) turns a slot into an instance Meal.
@freezed
abstract class PlanSlot with _$PlanSlot {
  const PlanSlot._();

  const factory PlanSlot({
    required String id,
    required String mealTemplateId,
    required MealTime time,
  }) = _PlanSlot;
}
