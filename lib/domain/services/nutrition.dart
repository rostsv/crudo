import '../food/food.dart';
import '../meal/food_snapshot.dart';
import '../meal/meal_snapshot.dart';
import '../meal/meal_template.dart';
import '../shared/macros.dart';

/// Nutrition rules (domain service — pure functions). Single source of truth:
/// totals are always recomputed, never stored (architecture §6). The Atwater
/// formula lives at INPUT time: it defaults a food's kcalPer100g and bounds
/// an explicit user entry (±10%, S07 form flow).

/// Atwater factors: protein 4, carbs 4, fats 9 kcal per gram.
double calculatedKcal({
  required double protein,
  required double carbs,
  required double fats,
}) => protein * 4 + carbs * 4 + fats * 9;

/// An explicit kcal entry is accepted only within ±[tolerance] (default 10%)
/// of the calculated value. Non-positive calculated → only 0 is valid.
/// Used by the S07 add/edit-food form before storing Food.kcalPer100g.
bool isExplicitKcalValid({
  required double calculated,
  required double explicit,
  double tolerance = 0.10,
}) {
  if (calculated <= 0) return explicit == 0;
  return (explicit - calculated).abs() <= calculated * tolerance;
}

/// Macros of [grams] of a library [Food] = per-100g values × grams / 100.
Macros macrosForFood(Food food, double grams) {
  final factor = grams / 100.0;
  return Macros(
    protein: food.protein * factor,
    carbs: food.carbs * factor,
    fats: food.fats * factor,
    kcal: food.kcalPer100g * factor,
  );
}

/// Preview macros of a meal TEMPLATE — needs the food library to resolve
/// refs. An unresolved foodId is skipped (libraries are soft-deleted, S19).
Macros mealTemplateMacros(MealTemplate template, Map<String, Food> foodsById) {
  var total = const Macros();
  for (final ref in template.foods) {
    final food = foodsById[ref.foodId];
    if (food == null) continue;
    total = total + macrosForFood(food, ref.grams.value);
  }
  return total;
}

/// Macros of one snapshot item — plain unpack, absolutes were baked at
/// creation (FoodSnapshot.from). No multiplication at read time.
Macros macrosOfSnapshot(FoodSnapshot snapshot) => Macros(
  protein: snapshot.protein,
  carbs: snapshot.carbs,
  fats: snapshot.fats,
  kcal: snapshot.kcal,
);

/// Planned macros of an instance meal = Σ all items.
Macros mealSnapshotMacros(MealSnapshot meal) => meal.items.fold(
  const Macros(),
  (total, i) => total + macrosOfSnapshot(i.food),
);

/// Consumed macros = Σ checked items only.
Macros consumedMealMacros(MealSnapshot meal) => meal.items
    .where((i) => i.checked)
    .fold(const Macros(), (total, i) => total + macrosOfSnapshot(i.food));
