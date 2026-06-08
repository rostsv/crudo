import 'package:crudo/config/di.dart';
import 'package:crudo/domain/plan/plan_template.dart';
import 'package:crudo/domain/repositories/plan_template_repository.dart';
import 'package:crudo/domain/services/nutrition.dart';
import 'package:crudo/domain/services/plan_scheduling.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'plan_draft.dart';

part 'plan_detail_controller.g.dart';

/// Manages the editable draft for one plan detail screen.
/// Watches upstream stream providers so the draft auto-refreshes when the
/// repo changes underneath (e.g. another screen mutates plans).
@riverpod
class PlanDetailController extends _$PlanDetailController {
  late PlanTemplate _original;
  late PlanTemplateRepository _repo;

  @override
  Future<PlanDraft> build(String planId) async {
    _repo = ref.read(planTemplateRepositoryProvider);
    final plan = await _repo.getById(planId);
    if (plan == null) {
      throw StateError('Plan $planId not found');
    }
    _original = plan;

    // Resolve slot VMs from the repos directly (one-shot getAll) — not the
    // stream providers: a library emit mid-edit must not rebuild and discard
    // the draft, and a read of an autoDispose stream disposes mid-load.
    final templates = {
      for (final t in await ref.read(mealTemplateRepositoryProvider).getAll())
        t.id: t,
    };
    final foods = {
      for (final f in await ref.read(foodRepositoryProvider).getAll()) f.id: f,
    };

    final slots = <SlotVm>[
      for (final s in plan.slots)
        (
          mealName: templates[s.mealTemplateId]?.name ?? 'Unknown meal',
          time: s.time,
          kcal: templates[s.mealTemplateId] == null
              ? 0
              : mealTemplateMacros(
                  templates[s.mealTemplateId]!,
                  foods,
                ).kcal.round(),
        ),
    ];

    return PlanDraft.from(plan, slots);
  }

  bool get isDirty {
    final draft = state.value;
    if (draft == null) return false;
    return draft.isDirtyFrom(_original);
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

    final allPlans = await _repo.getAll();

    final conflicts = detectConflicts(
      allPlans,
      forPlanId: _original.id,
      proposedDays: draft.claimedDays,
    );

    if (conflicts.isNotEmpty && !override) {
      return (committed: false, conflicts: conflicts, uncovered: const <int>[]);
    }

    // Build the updated plan.
    final updated = _original.copyWith(
      name: draft.name.trim(),
      days: [...draft.days],
      active: draft.active,
    );

    if (override && conflicts.isNotEmpty) {
      // Strip conflicting days from other plans.
      final changed = applyOverride(
        allPlans,
        forPlanId: _original.id,
        proposedDays: draft.claimedDays,
      );
      var savedMain = false;
      for (final p in changed) {
        if (p.id == _original.id) {
          // Use fully updated version (name / active may have changed).
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
      // No conflicts — just save this plan.
      await _repo.save(updated);
    }

    // After save, re-fetch to compute uncovered with fresh state.
    final postSave = await _repo.getAll();
    final uncovered = uncoveredWeekdays(postSave);

    // Update original so isDirty resets.
    _original = updated;
    state = AsyncValue.data(PlanDraft.from(updated, draft.slots));

    return (
      committed: true,
      conflicts: const <WeekdayConflict>[],
      uncovered: uncovered,
    );
  }

  /// Returns false (no-op) when this is the last plan — the ≥1-plan invariant
  /// (S09 `canDeletePlan`) lives here, not in the widget. True after deleting.
  Future<bool> delete() async {
    if (!canDeletePlan(await _repo.getAll())) return false;
    await _repo.delete(_original.id);
    return true;
  }
}
