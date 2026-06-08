import 'package:crudo/domain/meal/food_snapshot.dart';
import 'package:crudo/domain/meal/meal_item.dart';
import 'package:crudo/domain/meal/meal_snapshot.dart';
import 'package:crudo/domain/services/nutrition.dart';
import 'package:crudo/domain/shared/enums.dart';
import 'package:crudo/domain/shared/macros.dart';

/// In-progress meal-instance edit (S08). Immutable — the controller swaps
/// whole instances. Items are pure FoodSnapshots: the consumption marks are
/// dropped on load (only `upcoming` meals are editable, so none exist) and
/// [toSnapshot] rebuilds every item UNCHECKED by construction — the S05
/// replaceMeal obligation, discharged at the type level.
class MealDraft {
  const MealDraft({
    this.name = '',
    this.tags = const <MealTag>[],
    this.items = const <FoodSnapshot>[],
    this.sourceMealTemplateId,
  });

  factory MealDraft.fromSnapshot(MealSnapshot meal) => MealDraft(
    name: meal.name,
    tags: meal.tags,
    items: [for (final i in meal.items) i.food],
    sourceMealTemplateId: meal.sourceMealTemplateId,
  );

  final String name;
  final List<MealTag> tags;
  final List<FoodSnapshot> items;

  /// Weak back-ref, preserved through edits (it never implies sync).
  final String? sourceMealTemplateId;

  Macros get macros => mealSnapshotMacros(toSnapshot());

  /// Non-blank name + the S02 "≥1 item per saved meal" rule.
  bool get canSave => name.trim().isNotEmpty && items.isNotEmpty;

  MealSnapshot toSnapshot() => MealSnapshot(
    sourceMealTemplateId: sourceMealTemplateId,
    name: name.trim(),
    tags: tags,
    items: [for (final f in items) MealItem(food: f)],
  );

  MealDraft copyWith({
    String? name,
    List<MealTag>? tags,
    List<FoodSnapshot>? items,
  }) => MealDraft(
    name: name ?? this.name,
    tags: tags ?? this.tags,
    items: items ?? this.items,
    sourceMealTemplateId: sourceMealTemplateId,
  );
}
