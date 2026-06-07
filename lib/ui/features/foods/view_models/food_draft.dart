import 'package:crudo/domain/food/food.dart';
import 'package:crudo/domain/services/nutrition.dart';
import 'package:crudo/domain/shared/enums.dart';
import 'package:crudo/domain/validation/validation_issue.dart';
import 'package:crudo/domain/validation/validators.dart';

/// In-progress add/edit-food form state (S07). Immutable — the controller
/// swaps whole instances via the withX methods. `explicitKcal == null`
/// means auto (Atwater); a non-null value is the user's override, gated
/// by isExplicitKcalValid before save.
class FoodDraft {
  const FoodDraft({
    this.name = '',
    this.kind = FoodKind.product,
    this.category,
    this.protein = 0,
    this.carbs = 0,
    this.fats = 0,
    this.explicitKcal,
  });

  /// Prefill for edit. A stored kcal exactly equal to the formula renders
  /// as auto; anything else was an accepted override — show it. A stored
  /// category of `custom` renders as "no chip selected" (saving with no
  /// chip writes `custom` back — symmetric).
  factory FoodDraft.fromFood(Food food) {
    final calc = calculatedKcal(
      protein: food.protein,
      carbs: food.carbs,
      fats: food.fats,
    );
    return FoodDraft(
      name: food.name,
      kind: food.kind,
      category: food.category == FoodCategory.custom ? null : food.category,
      protein: food.protein,
      carbs: food.carbs,
      fats: food.fats,
      explicitKcal: food.kcalPer100g == calc ? null : food.kcalPer100g,
    );
  }

  final String name;
  final FoodKind kind;

  /// null = no chip → saved as custom.
  /// For products: the selected chip category (or null for custom).
  /// For dishes: always ignored at save time — `toFood` forces custom regardless.
  final FoodCategory? category;
  final double protein;
  final double carbs;
  final double fats;
  final double? explicitKcal; // null = auto

  double get calculated =>
      calculatedKcal(protein: protein, carbs: carbs, fats: fats);

  double get effectiveKcal => explicitKcal ?? calculated;

  bool get kcalValid =>
      explicitKcal == null ||
      isExplicitKcalValid(calculated: calculated, explicit: explicitKcal!);

  /// Domain save rules (blank name, macro mass ≤ 101) + the S07 form rule
  /// (explicit kcal within ±10 % — ValidationCode.kcalOverrideOutOfRange,
  /// reserved for this since S02).
  List<ValidationIssue> get issues => [
    ...toFood('draft').validate(),
    if (!kcalValid)
      const ValidationIssue(
        field: 'kcalPer100g',
        code: ValidationCode.kcalOverrideOutOfRange,
        message: 'kcal must be within ±10% of the value calculated from macros',
      ),
  ];

  bool get canSave => issues.isEmpty;

  /// The Food this draft saves as. Drafts only ever produce custom foods.
  ///
  /// Category rule:
  /// - kind == product: uses `category ?? FoodCategory.custom` (chip selection).
  /// - kind == dish: always writes `FoodCategory.custom` regardless of the
  ///   in-memory chip selection (product decision — dishes have no category).
  Food toFood(String id) => Food(
    id: id,
    name: name,
    kind: kind,
    category: kind == FoodKind.dish
        ? FoodCategory.custom
        : category ?? FoodCategory.custom,
    protein: protein,
    carbs: carbs,
    fats: fats,
    kcalPer100g: effectiveKcal,
    isCustom: true,
  );

  FoodDraft withName(String v) => FoodDraft(
    name: v,
    kind: kind,
    category: category,
    protein: protein,
    carbs: carbs,
    fats: fats,
    explicitKcal: explicitKcal,
  );
  FoodDraft withKind(FoodKind v) => FoodDraft(
    name: name,
    kind: v,
    category: category,
    protein: protein,
    carbs: carbs,
    fats: fats,
    explicitKcal: explicitKcal,
  );
  FoodDraft withCategory(FoodCategory? v) => FoodDraft(
    name: name,
    kind: kind,
    category: v,
    protein: protein,
    carbs: carbs,
    fats: fats,
    explicitKcal: explicitKcal,
  );
  FoodDraft withProtein(double v) => FoodDraft(
    name: name,
    kind: kind,
    category: category,
    protein: v,
    carbs: carbs,
    fats: fats,
    explicitKcal: explicitKcal,
  );
  FoodDraft withCarbs(double v) => FoodDraft(
    name: name,
    kind: kind,
    category: category,
    protein: protein,
    carbs: v,
    fats: fats,
    explicitKcal: explicitKcal,
  );
  FoodDraft withFats(double v) => FoodDraft(
    name: name,
    kind: kind,
    category: category,
    protein: protein,
    carbs: carbs,
    fats: v,
    explicitKcal: explicitKcal,
  );
  FoodDraft withExplicitKcal(double? v) => FoodDraft(
    name: name,
    kind: kind,
    category: category,
    protein: protein,
    carbs: carbs,
    fats: fats,
    explicitKcal: v,
  );
}
