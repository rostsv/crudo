import 'package:crudo/config/di.dart';
import 'package:crudo/domain/plan/plan_template.dart';
import 'package:crudo/domain/repositories/plan_template_repository.dart';
import 'package:crudo/domain/services/plan_scheduling.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'plan_activation.g.dart';

/// Pause/resume a plan straight from the Plans list card. Pausing is always
/// safe (it frees the plan's weekdays); resuming can clash with other active
/// plans, so [resumeConflicts] lets the UI show the steal-override confirm
/// before [resume] with `override: true` strips the clashing days from the
/// other plans (mirrors the editor's save flow — the conflict rules stay in
/// [plan_scheduling], not the widget).
@riverpod
class PlanActivation extends _$PlanActivation {
  @override
  void build() {}

  PlanTemplateRepository get _repo => ref.read(planTemplateRepositoryProvider);

  /// Pause [planId]. No-op if unknown or already paused.
  Future<void> pause(String planId) async {
    final plan = await _repo.getById(planId);
    if (plan == null || !plan.active) return;
    await _repo.save(plan.copyWith(active: false));
  }

  /// Weekday conflicts that resuming [planId] would cause against other active
  /// plans. Empty when the resume is safe.
  Future<List<WeekdayConflict>> resumeConflicts(String planId) async {
    final plan = await _repo.getById(planId);
    if (plan == null) return const [];
    return detectConflicts(
      await _repo.getAll(),
      forPlanId: planId,
      proposedDays: plan.days,
    );
  }

  /// Resume [planId]. When [override], strip the clashing weekdays from the
  /// other plans first.
  Future<void> resume(String planId, {bool override = false}) async {
    final plan = await _repo.getById(planId);
    if (plan == null) return;
    await _repo.save(plan.copyWith(active: true));
    if (!override) return;
    final changed = applyOverride(
      await _repo.getAll(),
      forPlanId: planId,
      proposedDays: plan.days,
    );
    for (final p in changed) {
      if (p.id != planId) await _repo.save(p);
    }
  }

  // --- Coverage guard (the week must always stay fully covered) -------------

  List<int> _newlyUncovered(
    List<PlanTemplate> before,
    List<PlanTemplate> after,
  ) {
    final wasUncovered = uncoveredWeekdays(before).toSet();
    return [
      for (final d in uncoveredWeekdays(after))
        if (!wasUncovered.contains(d)) d,
    ];
  }

  /// Weekdays that pausing [planId] would leave uncovered (covered now, bare
  /// after). Empty → pausing is safe.
  Future<List<int>> daysOrphanedByPausing(String planId) async {
    final all = await _repo.getAll();
    return _newlyUncovered(all, [
      for (final p in all)
        if (p.id == planId) p.copyWith(active: false) else p,
    ]);
  }

  /// Weekdays that deleting [planId] would leave uncovered. Empty → safe.
  Future<List<int>> daysOrphanedByDeleting(String planId) async {
    final all = await _repo.getAll();
    return _newlyUncovered(all, [
      for (final p in all)
        if (p.id != planId) p,
    ]);
  }

  /// Other ACTIVE plans that could absorb orphaned days.
  Future<List<PlanTemplate>> otherActivePlans(String planId) async {
    final all = await _repo.getAll();
    return [
      for (final p in all)
        if (p.id != planId && p.active) p,
    ];
  }

  Future<void> _absorb(String toPlanId, List<int> days) async {
    final all = await _repo.getAll();
    final q = all.firstWhere((p) => p.id == toPlanId);
    final merged = {...q.days, ...days}.toList()..sort();
    await _repo.save(q.copyWith(days: merged));
  }

  /// Merge [days] into [toPlanId], then pause [planId] — coverage preserved.
  Future<void> assignDaysAndPause(
    String planId, {
    required String toPlanId,
    required List<int> days,
  }) async {
    await _absorb(toPlanId, days);
    await pause(planId);
  }

  /// Merge [days] into [toPlanId], then delete [planId] — coverage preserved.
  Future<void> assignDaysAndDelete(
    String planId, {
    required String toPlanId,
    required List<int> days,
  }) async {
    await _absorb(toPlanId, days);
    await _repo.delete(planId);
  }

  /// Delete [planId] unconditionally. The caller owns coverage (used by the
  /// "create a plan for these days" resolution, which re-covers them next).
  Future<void> forceDelete(String planId) => _repo.delete(planId);
}
