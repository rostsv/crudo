import 'package:freezed_annotation/freezed_annotation.dart';

import '../shared/enums.dart';
import 'meal_item.dart';

part 'meal_snapshot.freezed.dart';

/// The day's content record for one scheduled meal (instance tree): a
/// detached snapshot seeded from a MealTemplate, freely divergent afterwards
/// (swap/edits never touch templates). Holds WHAT is (to be) eaten + the
/// per-item consumption state; WHEN/skip/snooze live on ScheduledMeal.
@freezed
abstract class MealSnapshot with _$MealSnapshot {
  const MealSnapshot._();

  const factory MealSnapshot({
    String? sourceMealTemplateId,
    required String name,
    @Default(<MealTag>[]) List<MealTag> tags,
    @Default(<MealItem>[]) List<MealItem> items,
  }) = _MealSnapshot;

  bool get anyChecked => items.any((i) => i.checked);
  bool get allChecked => items.isNotEmpty && items.every((i) => i.checked);
}
