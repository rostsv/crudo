import '../meal/meal_template.dart';
import '../plan/plan_slot.dart';
import '../plan/plan_template.dart';

/// The active plan covering [date]'s weekday (0=Mon…6=Sun). >1 match should
/// be impossible (S09 blocks weekday conflicts) — defensively the lowest id
/// wins, deterministically.
PlanTemplate? selectPlanForDate(List<PlanTemplate> plans, DateTime date) {
  final weekday = date.weekday - 1;
  final matches =
      plans.where((p) => p.active && p.days.contains(weekday)).toList()
        ..sort((a, b) => a.id.compareTo(b.id));
  return matches.isEmpty ? null : matches.first;
}

/// One weekday a proposed assignment would steal from another active plan.
/// A record (not a class): free structural equality for tests, no codegen.
/// weekday is 0=Mon…6=Sun; otherPlanName carries the S10 modal copy.
typedef WeekdayConflict = ({
  int weekday,
  String otherPlanId,
  String otherPlanName,
});

/// Active OTHER plans (id != forPlanId) currently claiming any of [proposedDays].
/// One entry per (weekday, conflicting plan), in plan-then-weekday order.
/// Empty → save freely. Inactive plans never conflict.
List<WeekdayConflict> detectConflicts(
  List<PlanTemplate> plans, {
  required String forPlanId,
  required List<int> proposedDays,
}) {
  final proposed = proposedDays.toSet();
  return [
    for (final p in plans)
      if (p.id != forPlanId && p.active)
        for (final d in p.days)
          if (proposed.contains(d))
            (weekday: d, otherPlanId: p.id, otherPlanName: p.name),
  ];
}

/// STEAL: strip every proposedDay from all OTHER plans; set forPlanId.days =
/// proposedDays. Returns only the plans that CHANGED (incl. forPlanId if its
/// day-set differs). Unchanged plans are absent; input order preserved among
/// the changed. forPlanId not present in [plans] → only the strips returned.
List<PlanTemplate> applyOverride(
  List<PlanTemplate> plans, {
  required String forPlanId,
  required List<int> proposedDays,
}) {
  final proposed = proposedDays.toSet();
  final changed = <PlanTemplate>[];
  for (final p in plans) {
    if (p.id == forPlanId) {
      if (!_sameWeekdays(p.days, proposedDays)) {
        changed.add(p.copyWith(days: [...proposedDays]));
      }
    } else {
      final kept = p.days.where((d) => !proposed.contains(d)).toList();
      if (kept.length != p.days.length) changed.add(p.copyWith(days: kept));
    }
  }
  return changed;
}

bool _sameWeekdays(List<int> a, List<int> b) {
  if (a.length != b.length) return false;
  final sa = a.toSet();
  return b.every(sa.contains) && sa.length == b.toSet().length;
}

/// The ≥1-plan rule: the last plan can never be deleted. Any plan counts
/// (active or inactive). Pure pre-check — the repo stays unaware (S09 owns it).
bool canDeletePlan(List<PlanTemplate> plans) => plans.length > 1;

/// Weekdays 0..6 claimed by NO active plan, ascending and deduped.
/// [] = full coverage. Inactive plans cover nothing.
List<int> uncoveredWeekdays(List<PlanTemplate> plans) {
  final covered = <int>{
    for (final p in plans)
      if (p.active) ...p.days,
  };
  return [
    for (var d = 0; d < 7; d++)
      if (!covered.contains(d)) d,
  ];
}

/// Duplicate a plan as an editable starting point: new id, name "{src} copy",
/// days CLEARED to [] (no instant weekday conflict — the user reassigns),
/// active preserved, every slot re-minted (fresh ids never alias the source).
PlanTemplate clonePlan(PlanTemplate src, {required String Function() newId}) =>
    PlanTemplate(
      id: newId(),
      name: '${src.name} copy',
      days: const [],
      active: src.active,
      slots: [
        for (final s in src.slots)
          PlanSlot(id: newId(), mealTemplateId: s.mealTemplateId, time: s.time),
      ],
    );

/// Duplicate a meal template: new id, name "{src} copy", tags + food refs
/// copied unchanged (a fresh recipe the user can tweak independently).
MealTemplate cloneMeal(MealTemplate src, {required String Function() newId}) =>
    MealTemplate(
      id: newId(),
      name: '${src.name} copy',
      tags: [...src.tags],
      foods: [...src.foods],
    );

/// Reference accounting for a library meal template.
/// [using]      — plans with ≥1 slot whose mealTemplateId == templateId.
/// [wouldEmpty] — subset of [using] left with zero slots after every slot
///                referencing templateId is removed (the template is the
///                plan's only meal). Drives the delete block.
typedef TemplateUsage = ({
  List<PlanTemplate> using,
  List<PlanTemplate> wouldEmpty,
});

TemplateUsage templateUsage(List<PlanTemplate> plans, String templateId) {
  final using = <PlanTemplate>[];
  final wouldEmpty = <PlanTemplate>[];
  for (final p in plans) {
    final refs = p.slots.where((s) => s.mealTemplateId == templateId).length;
    if (refs == 0) continue;
    using.add(p);
    if (refs == p.slots.length) wouldEmpty.add(p);
  }
  return (using: using, wouldEmpty: wouldEmpty);
}

/// The plan with every slot referencing [templateId] removed (order + other
/// fields preserved). Used for the cascade-strip write.
PlanTemplate stripTemplateFromPlan(PlanTemplate p, String templateId) =>
    p.copyWith(
      slots: [
        for (final s in p.slots)
          if (s.mealTemplateId != templateId) s,
      ],
    );
