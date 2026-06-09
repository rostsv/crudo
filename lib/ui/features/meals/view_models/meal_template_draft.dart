import 'package:crudo/domain/food/food.dart';
import 'package:crudo/domain/food/food_ref.dart';
import 'package:crudo/domain/meal/meal_template.dart';
import 'package:crudo/domain/services/nutrition.dart'; // mealTemplateMacros, macrosForFood
import 'package:crudo/domain/shared/enums.dart'; // MealTag
import 'package:crudo/domain/shared/grams.dart';
import 'package:crudo/domain/shared/macros.dart';

/// Resolved display data for one ingredient row (name + macros) so the widget
/// never resolves foods itself.
typedef IngredientRowVm = ({String name, Grams grams, int kcal});

/// In-progress library-template edit. Immutable; the controller swaps whole
/// drafts. `foods` are live FoodRefs (foodId + grams). Mirrors meal_draft.dart.
class MealTemplateDraft {
  const MealTemplateDraft({
    this.name = '',
    this.tags = const <MealTag>[],
    this.foods = const <FoodRef>[],
  });

  factory MealTemplateDraft.from(MealTemplate t) =>
      MealTemplateDraft(name: t.name, tags: t.tags, foods: t.foods);

  final String name;
  final List<MealTag> tags;
  final List<FoodRef> foods;

  /// Build the persistable template at [id] ('' while editing/previewing).
  MealTemplate toTemplate(String id) =>
      MealTemplate(id: id, name: name.trim(), tags: tags, foods: foods);

  /// Macros over the current foods, resolved against [foodsById].
  Macros macros(Map<String, Food> foodsById) =>
      mealTemplateMacros(toTemplate(''), foodsById);

  /// Resolved ingredient rows for display.
  List<IngredientRowVm> rows(Map<String, Food> foodsById) => [
    for (final r in foods)
      (
        name: foodsById[r.foodId]?.name ?? 'Unknown food',
        grams: r.grams,
        kcal: foodsById[r.foodId] == null
            ? 0
            : macrosForFood(foodsById[r.foodId]!, r.grams.value).kcal.round(),
      ),
  ];

  /// S02 rule: non-blank name + ≥1 ingredient.
  bool get canSave => name.trim().isNotEmpty && foods.isNotEmpty;

  MealTemplateDraft withName(String v) => _copy(name: v);

  MealTemplateDraft toggleTag(MealTag t) => _copy(
    tags: tags.contains(t)
        ? [
            for (final x in tags)
              if (x != t) x,
          ]
        : [...tags, t],
  );

  MealTemplateDraft addFood(FoodRef r) => _copy(foods: [...foods, r]);

  MealTemplateDraft removeFood(int index) => _copy(
    foods: [
      for (final (i, r) in foods.indexed)
        if (i != index) r,
    ],
  );

  MealTemplateDraft setGrams(int index, Grams g) => _copy(
    foods: [
      for (final (i, r) in foods.indexed) i == index ? r.copyWith(grams: g) : r,
    ],
  );

  MealTemplateDraft _copy({
    String? name,
    List<MealTag>? tags,
    List<FoodRef>? foods,
  }) => MealTemplateDraft(
    name: name ?? this.name,
    tags: tags ?? this.tags,
    foods: foods ?? this.foods,
  );
}
