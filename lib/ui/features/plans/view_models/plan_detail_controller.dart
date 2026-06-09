import 'package:crudo/config/di.dart';
import 'package:crudo/data/services/id_generator.dart';
import 'package:crudo/domain/food/food.dart';
import 'package:crudo/domain/meal/meal_template.dart';
import 'package:crudo/domain/plan/plan_slot.dart';
import 'package:crudo/domain/plan/plan_template.dart';
import 'package:crudo/domain/repositories/plan_template_repository.dart';
import 'package:crudo/domain/services/nutrition.dart';
import 'package:crudo/domain/services/plan_scheduling.dart';
import 'package:crudo/domain/shared/macros.dart';
import 'package:crudo/domain/shared/meal_time.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'plan_draft.dart';

part 'plan_detail_controller.g.dart';

/// Manages the editable draft for one plan detail screen.
/// Watches upstream stream providers so the draft auto-refreshes when the
/// repo changes underneath (e.g. another screen mutates plans).
@riverpod
class PlanDetailController extends _$PlanDetailController {
  PlanTemplate? _original; // null in create mode
  late PlanTemplate _baseline; // dirty-comparison baseline
  late PlanTemplateRepository _repo;
  Map<String, MealTemplate> _templatesById = const {};
  Map<String, Food> _foodsById = const {};

  @override
  Future<PlanDraft> build(String? planId) async {
    _repo = ref.read(planTemplateRepositoryProvider);
    _templatesById = {
      for (final t in await ref.read(mealTemplateRepositoryProvider).getAll())
        t.id: t,
    };
    _foodsById = {
      for (final f in await ref.read(foodRepositoryProvider).getAll()) f.id: f,
    };

    if (planId == null) {
      _original = null;
      _baseline = const PlanTemplate(id: '', name: '');
      return PlanDraft.from(_baseline, const []);
    }

    final plan = await _repo.getById(planId);
    if (plan == null) throw StateError('Plan $planId not found');
    _original = plan;
    _baseline = plan;
    return PlanDraft.from(plan, _resolveSlots(plan.slots));
  }

  List<PlanSlotDraft> _resolveSlots(List<PlanSlot> slots) => [
    for (final s in slots)
      (
        id: s.id,
        mealTemplateId: s.mealTemplateId,
        time: s.time,
        mealName: _templatesById[s.mealTemplateId]?.name ?? 'Unknown meal',
        kcal: _templatesById[s.mealTemplateId] == null
            ? 0
            : mealTemplateMacros(
                _templatesById[s.mealTemplateId]!,
                _foodsById,
              ).kcal.round(),
      ),
  ];

  bool get isDirty {
    final d = state.value;
    return d != null && d.isDirtyFrom(_baseline);
  }

  void setName(String value) {
    final draft = state.value;
    if (draft == null) return;
    state = AsyncValue.data(draft.withName(value));
  }

  void toggleDay(int weekday) {
    final draft = state.value;
    if (draft == null) return;
    state = AsyncValue.data(draft.toggleDay(weekday));
  }

  void setActive(bool value) {
    final draft = state.value;
    if (draft == null) return;
    state = AsyncValue.data(draft.withActive(value));
  }

  void addSlot(String mealTemplateId) {
    final d = state.value;
    final tpl = _templatesById[mealTemplateId];
    if (d == null || tpl == null) return;

    final time = d.slots.isEmpty
        ? const MealTime(480)
        : MealTime(
            (d.slots
                        .map((s) => s.time.minutesOfDay)
                        .reduce((a, b) => a > b ? a : b) +
                    180)
                .clamp(0, 1380),
          );

    state = AsyncData(
      d.addSlot((
        id: ref.read(idGeneratorProvider).newId(),
        mealTemplateId: mealTemplateId,
        time: time,
        mealName: tpl.name,
        kcal: mealTemplateMacros(tpl, _foodsById).kcal.round(),
      )),
    );
  }

  /// T5: Add a slot from a freshly created/cloned template (may not be in cache).
  void addSlotFromTemplate(MealTemplate tpl) {
    _templatesById = {..._templatesById, tpl.id: tpl};
    addSlot(tpl.id);
  }

  /// T5: Summed Macros over all draft slots (for preview card).
  Macros get totalMacros {
    final d = state.value;
    if (d == null) return const Macros();
    var total = const Macros();
    for (final s in d.slots) {
      final tpl = _templatesById[s.mealTemplateId];
      if (tpl != null) {
        total = total + mealTemplateMacros(tpl, _foodsById);
      }
    }
    return total;
  }

  /// T5: Look up a template by id (for duplicate flow).
  MealTemplate? templateById(String id) => _templatesById[id];

  void removeSlot(int i) => _mutate((d) => d.removeSlot(i));
  void setSlotTime(int i, MealTime t) => _mutate((d) => d.setSlotTime(i, t));
  void reorderSlots(int from, int to) =>
      _mutate((d) => d.reorderSlots(from, to));

  /// In-memory duplicate seed (create mode). Replaces the blank draft once.
  void seedFrom(PlanTemplate src) {
    _baseline = src;
    state = AsyncData(PlanDraft.from(src, _resolveSlots(src.slots)));
  }

  /// Attempt to save. First call returns uncommitted when weekday conflicts
  /// exist so the UI can show the override confirm. Calling again with
  /// [override]=true strips conflicting days from other plans and commits.
  Future<SaveOutcome> save({bool override = false}) async {
    final draft = state.value;
    if (draft == null) {
      return (
        committed: false,
        conflicts: const <WeekdayConflict>[],
        uncovered: const <int>[],
      );
    }

    final id = _original?.id ?? ref.read(idGeneratorProvider).newId();
    final allPlans = await _repo.getAll();

    final conflicts = detectConflicts(
      allPlans,
      forPlanId: id,
      proposedDays: draft.claimedDays,
    );

    if (conflicts.isNotEmpty && !override) {
      return (committed: false, conflicts: conflicts, uncovered: const <int>[]);
    }

    // Build the updated plan with slots from the draft.
    final updated = PlanTemplate(
      id: id,
      name: draft.name.trim(),
      days: [...draft.days],
      active: draft.active,
      slots: [
        for (final s in draft.slots)
          PlanSlot(id: s.id, mealTemplateId: s.mealTemplateId, time: s.time),
      ],
    );

    if (override && conflicts.isNotEmpty) {
      // Strip conflicting days from other plans.
      final changed = applyOverride(
        allPlans,
        forPlanId: id,
        proposedDays: draft.claimedDays,
      );
      var savedMain = false;
      for (final p in changed) {
        if (p.id == id) {
          await _repo.save(updated);
          savedMain = true;
        } else {
          await _repo.save(p);
        }
      }
      if (!savedMain) {
        await _repo.save(updated);
      }
    } else {
      await _repo.save(updated);
    }

    // After save, re-fetch to compute uncovered with fresh state.
    final postSave = await _repo.getAll();
    final uncovered = uncoveredWeekdays(postSave);

    // Update baseline so isDirty resets.
    _original = updated;
    _baseline = updated;
    state = AsyncData(PlanDraft.from(updated, _resolveSlots(updated.slots)));

    return (
      committed: true,
      conflicts: const <WeekdayConflict>[],
      uncovered: uncovered,
    );
  }

  /// Returns false (no-op) when this is the last plan — the ≥1-plan invariant
  /// (S09 `canDeletePlan`) lives here, not in the widget. True after deleting.
  /// Only available in edit mode (no-op in create mode).
  Future<bool> delete() async {
    if (_original == null) return false;
    if (!canDeletePlan(await _repo.getAll())) return false;
    await _repo.delete(_original!.id);
    return true;
  }

  void _mutate(PlanDraft Function(PlanDraft) fn) {
    final d = state.value;
    if (d != null) state = AsyncData(fn(d));
  }
}
