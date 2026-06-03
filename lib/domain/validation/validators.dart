import '../day/day.dart';
import '../meal/meal.dart';
import '../meal/meal_product.dart';
import '../meal/meal_template.dart';
import '../plan/plan_slot.dart';
import '../plan/plan_template.dart';
import '../product/product.dart';
import '../profile/prefs.dart';
import '../profile/user_profile.dart';
import '../services/nutrition.dart';
import 'validation_issue.dart';

/// Tier-2 (user-facing) validation: called at SAVE boundaries by forms/repos.
/// Returns issues instead of throwing — mid-edit drafts are allowed.
/// Tier-1 impossible states are guarded by @Assert on the types themselves.

const _allowedThresholds = {70, 80, 90, 100};
const _macroMassLimit = 101.0; // 100 g per 100 g + 1 g rounding tolerance

List<ValidationIssue> _macroRules({
  required String name,
  required double protein,
  required double carbs,
  required double fats,
  required double? kcalOverride,
}) {
  final issues = <ValidationIssue>[];
  if (name.trim().isEmpty) {
    issues.add(
      const ValidationIssue(
        field: 'name',
        code: ValidationCode.blankName,
        message: 'Name must not be blank',
      ),
    );
  }
  if (kcalOverride != null) {
    final calculated = calculatedKcal(
      protein: protein,
      carbs: carbs,
      fats: fats,
    );
    final valid =
        kcalOverride >= 0 &&
        isKcalOverrideValid(calculated: calculated, override: kcalOverride);
    if (!valid) {
      issues.add(
        const ValidationIssue(
          field: 'kcalOverride',
          code: ValidationCode.kcalOverrideOutOfRange,
          message: 'kcal override must be within ±10% of the calculated value',
        ),
      );
    }
  }
  if (protein + carbs + fats > _macroMassLimit) {
    issues.add(
      const ValidationIssue(
        field: 'macros',
        code: ValidationCode.macroMassExceeded,
        message: 'protein + carbs + fats cannot exceed 100 g per 100 g',
      ),
    );
  }
  return issues;
}

extension ProductValidation on Product {
  List<ValidationIssue> validate() => _macroRules(
    name: name,
    protein: protein,
    carbs: carbs,
    fats: fats,
    kcalOverride: kcalOverride,
  );
}

extension MealProductValidation on MealProduct {
  List<ValidationIssue> validate() => _macroRules(
    name: name,
    protein: protein,
    carbs: carbs,
    fats: fats,
    kcalOverride: kcalOverride,
  );
}

extension MealTemplateValidation on MealTemplate {
  List<ValidationIssue> validate() => [
    if (name.trim().isEmpty)
      const ValidationIssue(
        field: 'name',
        code: ValidationCode.blankName,
        message: 'Meal name must not be blank',
      ),
    if (products.isEmpty)
      const ValidationIssue(
        field: 'products',
        code: ValidationCode.emptyMeal,
        message: 'A meal must contain at least one product',
      ),
  ];
}

extension MealValidation on Meal {
  List<ValidationIssue> validate() => [
    if (name.trim().isEmpty)
      const ValidationIssue(
        field: 'name',
        code: ValidationCode.blankName,
        message: 'Meal name must not be blank',
      ),
    if (products.isEmpty)
      const ValidationIssue(
        field: 'products',
        code: ValidationCode.emptyMeal,
        message: 'A meal must contain at least one product',
      ),
  ];
}

extension PlanSlotValidation on PlanSlot {
  List<ValidationIssue> validate() => [
    if (mealTemplateId.trim().isEmpty)
      const ValidationIssue(
        field: 'mealTemplateId',
        code: ValidationCode.blankMealTemplateId,
        message: 'A slot must reference a meal template',
      ),
  ];
}

extension PlanTemplateValidation on PlanTemplate {
  List<ValidationIssue> validate() => [
    if (name.trim().isEmpty)
      const ValidationIssue(
        field: 'name',
        code: ValidationCode.blankName,
        message: 'Plan name must not be blank',
      ),
    if (days.toSet().length != days.length)
      const ValidationIssue(
        field: 'days',
        code: ValidationCode.duplicateWeekday,
        message: 'Weekdays must be unique',
      ),
    if (days.any((d) => d < 0 || d > 6))
      const ValidationIssue(
        field: 'days',
        code: ValidationCode.invalidWeekday,
        message: 'Weekdays must be between 0 and 6',
      ),
    if (active && slots.isEmpty)
      const ValidationIssue(
        field: 'slots',
        code: ValidationCode.emptyActivePlan,
        message: 'An active plan must have at least one meal slot',
      ),
  ];
}

extension DayValidation on Day {
  // Date/verdict invariants are Tier-1 @Assert on Day (non-const factory).
  List<ValidationIssue> validate() => [
    if (meals.map((m) => m.id).toSet().length != meals.length)
      const ValidationIssue(
        field: 'meals',
        code: ValidationCode.duplicateMealId,
        message: 'Meal ids within a day must be unique',
      ),
  ];
}

extension PrefsValidation on Prefs {
  List<ValidationIssue> validate() => [
    if (!_allowedThresholds.contains(streakThreshold))
      const ValidationIssue(
        field: 'streakThreshold',
        code: ValidationCode.invalidThreshold,
        message: 'Threshold must be one of 70, 80, 90, 100',
      ),
    if (dailyKcalTarget != null && dailyKcalTarget! <= 0)
      const ValidationIssue(
        field: 'dailyKcalTarget',
        code: ValidationCode.nonPositiveTarget,
        message: 'Daily kcal target must be positive',
      ),
    if (preMin > 240)
      const ValidationIssue(
        field: 'preMin',
        code: ValidationCode.preMinTooLarge,
        message: 'Pre-meal reminder lead cannot exceed 240 minutes',
      ),
  ];
}

extension UserProfileValidation on UserProfile {
  List<ValidationIssue> validate() => [
    if (id.trim().isEmpty)
      const ValidationIssue(
        field: 'id',
        code: ValidationCode.blankId,
        message: 'Profile id must not be blank',
      ),
  ];
}
