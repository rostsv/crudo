import 'package:freezed_annotation/freezed_annotation.dart';

import 'food_snapshot.dart';

part 'meal_item.freezed.dart';

/// Consumption wrapper around a pure [FoodSnapshot] (instance tree).
/// `checkedAt` null = not eaten; set = eaten at that UTC instant. The mark
/// travels with its item — list order is display-only, never identity.
/// NOTE: non-const factory — the @Assert needs DateTime property access,
/// which Dart forbids in const-constructor asserts (same as Day).
@freezed
abstract class MealItem with _$MealItem {
  const MealItem._();

  @Assert('checkedAt == null || checkedAt.isUtc', 'checkedAt must be UTC')
  factory MealItem({DateTime? checkedAt, required FoodSnapshot food}) =
      _MealItem;

  bool get checked => checkedAt != null;
}
