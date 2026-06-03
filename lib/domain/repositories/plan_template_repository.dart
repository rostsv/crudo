import '../plan/plan_template.dart';

/// Single source of truth for plan templates.
/// Contract notes: [watchAll] emits the current list immediately on listen,
/// then again after every mutation. [delete] removes the plan from all
/// queries; already-materialized day snapshots are unaffected (detached).
/// The ≥1-plan rule is application-level logic (S09), not enforced here.
abstract class PlanTemplateRepository {
  Stream<List<PlanTemplate>> watchAll();
  Future<List<PlanTemplate>> getAll();
  Future<PlanTemplate?> getById(String id);
  Future<void> save(PlanTemplate plan);
  Future<void> delete(String id);
}
