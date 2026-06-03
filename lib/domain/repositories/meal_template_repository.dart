import '../meal/meal_template.dart';

/// Single source of truth for meal templates (library recipes).
/// Contract notes: [watchAll] emits the current list immediately on listen,
/// then again after every mutation. [delete] removes the template from all
/// queries; already-materialized day snapshots are unaffected (detached).
abstract class MealTemplateRepository {
  Stream<List<MealTemplate>> watchAll();
  Future<List<MealTemplate>> getAll();
  Future<MealTemplate?> getById(String id);
  Future<void> save(MealTemplate template);
  Future<void> delete(String id);
}
