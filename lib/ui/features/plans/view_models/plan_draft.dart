import 'package:crudo/domain/plan/plan_template.dart';
import 'package:crudo/domain/services/plan_scheduling.dart'; // WeekdayConflict
import 'package:crudo/domain/shared/enums.dart'; // Goal
import 'package:crudo/domain/shared/meal_time.dart'; // MealTime

/// Read-only display data for one plan slot. S10 shows slots, never edits them.
typedef SlotVm = ({String mealName, MealTime time, int kcal});

/// One row of the plans list — all display data resolved up front.
/// days/goal/kcal/mealCount drive the subtitle + weekday chips; isToday is
/// `this == selectPlanForDate(plans, today)`.
typedef PlanRowVm = ({
  String id,
  String name,
  List<int>
  days, // 0=Mon…6=Sun, dormant-inclusive (a paused plan keeps its days)
  Goal goal,
  int kcal,
  int mealCount,
  bool active,
  bool isToday,
});

/// Result of PlanDetailController.save(). committed:false carries the pending
/// conflicts (no write happened); committed:true carries the post-save
/// uncovered weekdays for the advisory confirm.
typedef SaveOutcome = ({
  bool committed,
  List<WeekdayConflict> conflicts,
  List<int> uncovered,
});

/// Editable detail draft. name/days/active are mutable via copy helpers;
/// slots are resolved once and shown read-only.
class PlanDraft {
  const PlanDraft({
    required this.name,
    required this.days,
    required this.active,
    required this.slots,
  });

  final String name;
  final List<int> days; // 0=Mon…6=Sun
  final bool active;
  final List<SlotVm> slots;

  factory PlanDraft.from(PlanTemplate p, List<SlotVm> slots) => PlanDraft(
    name: p.name,
    days: [...p.days],
    active: p.active,
    slots: slots,
  );

  /// Weekdays this plan actually claims — none while paused.
  List<int> get claimedDays => active ? days : const [];

  bool get canSave => name.trim().isNotEmpty;

  /// Dirty vs the persisted plan (slots can't change, so they're not compared).
  bool isDirtyFrom(PlanTemplate p) =>
      name.trim() != p.name ||
      !_sameWeekdays(days, p.days) ||
      active != p.active;

  PlanDraft withName(String v) => _copy(name: v);
  PlanDraft withActive(bool v) => _copy(active: v);

  /// Add the weekday if absent, else remove it. Result kept ascending.
  PlanDraft toggleDay(int weekday) {
    final next = days.contains(weekday)
        ? [
            for (final d in days)
              if (d != weekday) d,
          ]
        : ([...days, weekday]..sort());
    return _copy(days: next);
  }

  PlanDraft _copy({String? name, List<int>? days, bool? active}) => PlanDraft(
    name: name ?? this.name,
    days: days ?? this.days,
    active: active ?? this.active,
    slots: slots,
  );
}

bool _sameWeekdays(List<int> a, List<int> b) {
  if (a.length != b.length) return false;
  final sa = a.toSet();
  return sa.length == b.toSet().length && b.every(sa.contains);
}
