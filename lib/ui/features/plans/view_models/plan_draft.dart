import 'package:crudo/domain/plan/plan_slot.dart';
import 'package:crudo/domain/plan/plan_template.dart';
import 'package:crudo/domain/services/plan_scheduling.dart'; // WeekdayConflict
import 'package:crudo/domain/shared/enums.dart'; // Goal
import 'package:crudo/domain/shared/meal_time.dart'; // MealTime

/// One editable plan slot. id/mealTemplateId/time persist; mealName/kcal are
/// resolved display data filled by the controller.
typedef PlanSlotDraft = ({
  String id,
  String mealTemplateId,
  MealTime time,
  String mealName,
  int kcal,
});

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
/// slots are editable PlanSlotDraft items with add/remove/retime/reorder.
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
  final List<PlanSlotDraft> slots;

  factory PlanDraft.from(PlanTemplate p, List<PlanSlotDraft> slots) =>
      PlanDraft(
        name: p.name,
        days: [...p.days],
        active: p.active,
        slots: slots,
      );

  /// Weekdays this plan actually claims — none while paused.
  List<int> get claimedDays => active ? days : const [];

  /// Draft can be saved when the name is non-blank AND at least one slot exists.
  bool get canSave => name.trim().isNotEmpty && slots.isNotEmpty;

  /// Dirty vs the persisted plan, including slot comparison.
  bool isDirtyFrom(PlanTemplate p) =>
      name.trim() != p.name ||
      !_sameWeekdays(days, p.days) ||
      active != p.active ||
      !_sameSlots(slots, p.slots);

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

  /// Append [s], then sort slots ascending by time.
  PlanDraft addSlot(PlanSlotDraft s) =>
      _copy(slots: [...slots, s]..sort((a, b) => a.time.compareTo(b.time)));

  /// Remove the slot at [index].
  PlanDraft removeSlot(int index) => _copy(
    slots: [
      for (final (i, s) in slots.indexed)
        if (i != index) s,
    ],
  );

  /// Retime the slot at [index] to [t], then re-sort by time.
  PlanDraft setSlotTime(int index, MealTime t) => _copy(
    slots: [
      for (final (i, s) in slots.indexed)
        if (i == index)
          (
            id: s.id,
            mealTemplateId: s.mealTemplateId,
            time: t,
            mealName: s.mealName,
            kcal: s.kcal,
          )
        else
          s,
    ]..sort((a, b) => a.time.compareTo(b.time)),
  );

  /// Move the slot at [from] to [to], then redistribute the sorted time-pool
  /// onto positions so visual order == time order.
  PlanDraft reorderSlots(int from, int to) {
    final moved = [...slots];
    moved.insert(to, moved.removeAt(from));
    final pool = slots.map((s) => s.time).toList()
      ..sort((a, b) => a.compareTo(b));
    return _copy(
      slots: [
        for (final (i, s) in moved.indexed)
          (
            id: s.id,
            mealTemplateId: s.mealTemplateId,
            time: pool[i],
            mealName: s.mealName,
            kcal: s.kcal,
          ),
      ],
    );
  }

  PlanDraft _copy({
    String? name,
    List<int>? days,
    bool? active,
    List<PlanSlotDraft>? slots,
  }) => PlanDraft(
    name: name ?? this.name,
    days: days ?? this.days,
    active: active ?? this.active,
    slots: slots ?? this.slots,
  );
}

bool _sameWeekdays(List<int> a, List<int> b) {
  if (a.length != b.length) return false;
  final sa = a.toSet();
  return sa.length == b.toSet().length && b.every(sa.contains);
}

bool _sameSlots(List<PlanSlotDraft> a, List<PlanSlot> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i].id != b[i].id ||
        a[i].mealTemplateId != b[i].mealTemplateId ||
        a[i].time != b[i].time) {
      return false;
    }
  }
  return true;
}
