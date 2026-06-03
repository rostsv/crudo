import 'package:freezed_annotation/freezed_annotation.dart';

import 'plan_slot.dart';

part 'plan_template.freezed.dart';

/// A plan template (factory): ordered meal slots assigned to weekdays.
/// Edits affect future days only (architecture §8). `days` are 0=Mon … 6=Sun;
/// `[]` = unassigned. The display tag ('CUT · 2200 KCAL') is derived — profile
/// goal + computed planned kcal — never stored.
/// NOTE: weekday range validation (0..6) is Tier-2 in validators.dart because
/// Dart const constructors do not support method/property access on List params
/// in asserts.
@freezed
abstract class PlanTemplate with _$PlanTemplate {
  const PlanTemplate._();

  const factory PlanTemplate({
    required String id,
    required String name,
    @Default(<int>[]) List<int> days,
    @Default(true) bool active,
    @Default(<PlanSlot>[]) List<PlanSlot> slots,
  }) = _PlanTemplate;
}
