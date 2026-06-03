import '../meal/meal.dart';
import '../meal/meal_product.dart';
import '../meal/meal_template.dart';
import '../product/product.dart';
import '../shared/macros.dart';

/// Nutrition rules (domain service — pure functions). Single source of truth:
/// totals are always recomputed from products, never stored (architecture §6).

/// Atwater factors: protein 4, carbs 4, fats 9 kcal per gram.
double calculatedKcal({
  required double protein,
  required double carbs,
  required double fats,
}) => protein * 4 + carbs * 4 + fats * 9;

/// A manual kcal override is accepted only within ±[tolerance] (default 10%)
/// of the calculated value. Non-positive calculated → only 0 is valid.
bool isKcalOverrideValid({
  required double calculated,
  required double override,
  double tolerance = 0.10,
}) {
  if (calculated <= 0) return override == 0;
  return (override - calculated).abs() <= calculated * tolerance;
}

/// Effective per-100g kcal: a VALID override wins, otherwise calculated.
double effectiveKcalPer100g({
  required double protein,
  required double carbs,
  required double fats,
  double? kcalOverride,
}) {
  final calculated = calculatedKcal(protein: protein, carbs: carbs, fats: fats);
  if (kcalOverride != null &&
      isKcalOverrideValid(calculated: calculated, override: kcalOverride)) {
    return kcalOverride;
  }
  return calculated;
}

/// Macros of one snapshot product = per-100g values × grams / 100.
Macros macrosForProduct(MealProduct product) {
  final factor = product.grams.value / 100.0;
  return Macros(
    protein: product.protein * factor,
    carbs: product.carbs * factor,
    fats: product.fats * factor,
    kcal:
        effectiveKcalPer100g(
          protein: product.protein,
          carbs: product.carbs,
          fats: product.fats,
          kcalOverride: product.kcalOverride,
        ) *
        factor,
  );
}

/// Planned macros of an instance meal = Σ all products (self-contained — the
/// snapshot needs no library lookup).
Macros mealMacros(Meal meal) => meal.products.fold(
  const Macros(),
  (total, p) => total + macrosForProduct(p),
);

/// Consumed macros = Σ checked products only.
Macros consumedMacros(Meal meal) => meal.products
    .where((p) => p.checked)
    .fold(const Macros(), (total, p) => total + macrosForProduct(p));

/// Preview macros of a meal TEMPLATE — needs the product library to resolve
/// refs. An unresolved productId is skipped (libraries are soft-deleted, S19).
Macros mealTemplateMacros(
  MealTemplate template,
  Map<String, Product> productsById,
) {
  var total = const Macros();
  for (final ref in template.products) {
    final product = productsById[ref.productId];
    if (product == null) continue;
    final factor = ref.grams.value / 100.0;
    total =
        total +
        Macros(
          protein: product.protein * factor,
          carbs: product.carbs * factor,
          fats: product.fats * factor,
          kcal:
              effectiveKcalPer100g(
                protein: product.protein,
                carbs: product.carbs,
                fats: product.fats,
                kcalOverride: product.kcalOverride,
              ) *
              factor,
        );
  }
  return total;
}
