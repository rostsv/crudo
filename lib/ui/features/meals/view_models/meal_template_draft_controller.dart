import 'package:crudo/config/di.dart';
import 'package:crudo/data/services/id_generator.dart';
import 'package:crudo/domain/food/food.dart';
import 'package:crudo/domain/food/food_ref.dart';
import 'package:crudo/domain/meal/meal_template.dart';
import 'package:crudo/domain/plan/plan_template.dart';
import 'package:crudo/domain/repositories/meal_template_repository.dart';
import 'package:crudo/domain/services/plan_scheduling.dart'; // templateUsage, stripTemplateFromPlan
import 'package:crudo/domain/shared/enums.dart'; // MealTag
import 'package:crudo/domain/shared/grams.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'meal_template_draft.dart';

part 'meal_template_draft_controller.g.dart';

/// Outcome of a delete attempt — lets the screen pick block vs warn vs done.
/// blockedByEmpty:true  → refused (affected = plans that would be emptied).
/// deleted:false, blockedByEmpty:false, affected non-empty → needs confirm
///   (affected = plans that lose this meal); call delete(confirmed: true).
/// deleted:true → template removed (+ cascade-stripped plans persisted).
typedef DeleteOutcome = ({
  bool deleted,
  bool blockedByEmpty,
  List<PlanTemplate> affected,
});

@riverpod
class MealTemplateDraftController extends _$MealTemplateDraftController {
  late MealTemplate _initial; // blank (id '') on create, loaded on edit
  late MealTemplateRepository _repo;
  Map<String, Food> _foodsById = const {};

  @override
  Future<MealTemplateDraft> build(String? templateId) async {
    _repo = ref.read(mealTemplateRepositoryProvider);
    // One-shot food resolution (NOT a stream watch): a library emit mid-edit
    // must not rebuild and discard the draft (plan_detail_controller pattern).
    _foodsById = {
      for (final f in await ref.read(foodRepositoryProvider).getAll()) f.id: f,
    };
    if (templateId == null) {
      _initial = const MealTemplate(id: '', name: '');
      return const MealTemplateDraft();
    }
    final t = await _repo.getById(templateId);
    if (t == null) throw StateError('no meal template with id $templateId');
    _initial = t;
    return MealTemplateDraft.from(t);
  }

  Map<String, Food> get foodsById => _foodsById;

  bool get isDirty {
    final d = state.value;
    if (d == null) return false;
    return d.toTemplate(_initial.id) != _initial;
  }

  void setName(String v) => _update((d) => d.withName(v));
  void toggleTag(MealTag t) => _update((d) => d.toggleTag(t));
  void addFood(FoodRef r) => _update((d) => d.addFood(r));
  void removeFood(int i) => _update((d) => d.removeFood(i));
  void setGrams(int i, Grams g) => _update((d) => d.setGrams(i, g));

  /// Persist + return the saved template (caller pops it). Create mints an id.
  Future<MealTemplate> save() async {
    final d = state.requireValue;
    if (!d.canSave) throw StateError('draft has validation issues');
    final id = _initial.id.isEmpty
        ? ref.read(idGeneratorProvider).newId()
        : _initial.id;
    final saved = d.toTemplate(id);
    await _repo.save(saved);
    _initial = saved;
    return saved;
  }

  /// Guarded delete. See DeleteOutcome. confirmed:true performs the cascade.
  Future<DeleteOutcome> delete({bool confirmed = false}) async {
    if (_initial.id.isEmpty) {
      return (
        deleted: false,
        blockedByEmpty: false,
        affected: const <PlanTemplate>[],
      );
    }
    final plans = await ref.read(planTemplateRepositoryProvider).getAll();
    final usage = templateUsage(plans, _initial.id);
    if (usage.wouldEmpty.isNotEmpty) {
      return (deleted: false, blockedByEmpty: true, affected: usage.wouldEmpty);
    }
    if (!confirmed) {
      return (deleted: false, blockedByEmpty: false, affected: usage.using);
    }
    final planRepo = ref.read(planTemplateRepositoryProvider);
    for (final p in usage.using) {
      await planRepo.save(stripTemplateFromPlan(p, _initial.id));
    }
    await _repo.delete(_initial.id);
    return (deleted: true, blockedByEmpty: false, affected: usage.using);
  }

  void _update(MealTemplateDraft Function(MealTemplateDraft) fn) {
    final d = state.value;
    if (d != null) state = AsyncData(fn(d));
  }
}
