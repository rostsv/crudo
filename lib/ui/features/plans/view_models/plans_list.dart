import 'package:crudo/domain/food/food.dart';
import 'package:crudo/domain/food/food_ref.dart';
import 'package:crudo/domain/meal/meal_template.dart';
import 'package:crudo/domain/plan/plan_template.dart';
import 'package:crudo/domain/services/nutrition.dart'; // mealTemplateMacros
import 'package:crudo/domain/services/plan_scheduling.dart'; // selectPlanForDate
import 'package:crudo/domain/shared/enums.dart';
import 'package:crudo/domain/shared/macros.dart';
import 'package:crudo/ui/features/meals/views/formatting.dart'
    show mealTagLabels;
import 'package:crudo/ui/features/today/view_models/today_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'plan_draft.dart';

part 'plans_list.g.dart';

/// Derived list rows. Watches the S06 stream providers (immediate emit on
/// listen, so loading is transient) + todayProvider. Empty until plans arrive.
@riverpod
List<PlanRowVm> plansList(Ref ref) {
  final plans =
      ref.watch(planTemplatesProvider).value ?? const <PlanTemplate>[];
  final templates = {
    for (final t
        in ref.watch(mealTemplatesProvider).value ?? const <MealTemplate>[])
      t.id: t,
  };
  final Map<String, Food> foods = {
    for (final f in ref.watch(foodsProvider).value ?? const <Food>[]) f.id: f,
  };
  final goal = ref.watch(profileProvider).value?.prefs.goal ?? Goal.maintain;
  final today = ref.watch(todayProvider);
  final todayPlanId = selectPlanForDate(plans, today)?.id;

  Macros macrosOf(PlanTemplate p) {
    var total = const Macros();
    for (final s in p.slots) {
      final mt = templates[s.mealTemplateId];
      if (mt == null) continue;
      total = total + mealTemplateMacros(mt, foods);
    }
    return total;
  }

  return [
    for (final p in plans)
      () {
        final m = macrosOf(p);
        return (
          id: p.id,
          name: p.name,
          days: p.days,
          goal: goal,
          kcal: m.kcal.round(),
          protein: m.protein.round(),
          carbs: m.carbs.round(),
          fats: m.fats.round(),
          mealCount: p.slots.length,
          active: p.active,
          isToday: p.id == todayPlanId,
        );
      }(),
  ];
}

/// Read-only detail data for one plan (the viewer screen). Resolves each slot's
/// meal name, tag label, and kcal; totals feed the daily-target hero. Throws a
/// [StateError] if [planId] is unknown (surfaced as "Plan not found").
@riverpod
PlanViewVm planView(Ref ref, String planId) {
  final plans =
      ref.watch(planTemplatesProvider).value ?? const <PlanTemplate>[];
  final templates = {
    for (final t
        in ref.watch(mealTemplatesProvider).value ?? const <MealTemplate>[])
      t.id: t,
  };
  final Map<String, Food> foods = {
    for (final f in ref.watch(foodsProvider).value ?? const <Food>[]) f.id: f,
  };

  final plan = plans.firstWhere((p) => p.id == planId);

  final slots = [
    for (final s in plan.slots)
      () {
        final mt = templates[s.mealTemplateId];
        final macros = mt == null
            ? const Macros()
            : mealTemplateMacros(mt, foods);
        final tag = mt == null || mt.tags.isEmpty
            ? ''
            : mt.tags.map((t) => mealTagLabels[t]).join(' · ');
        final ingredients = <PlanIngredientView>[
          for (final ref in mt?.foods ?? const <FoodRef>[])
            if (foods[ref.foodId] case final food?)
              (
                name: food.name,
                grams: ref.grams.value,
                kcal: macrosForFood(food, ref.grams.value).kcal,
              ),
        ];
        return (
          time: s.time,
          mealName: mt?.name ?? 'Unknown meal',
          tag: tag,
          macros: macros,
          ingredients: ingredients,
        );
      }(),
  ]..sort((a, b) => a.time.compareTo(b.time));

  var total = const Macros();
  for (final s in plan.slots) {
    final mt = templates[s.mealTemplateId];
    if (mt == null) continue;
    total = total + mealTemplateMacros(mt, foods);
  }

  return (
    name: plan.name,
    active: plan.active,
    days: plan.days,
    total: total,
    mealCount: plan.slots.length,
    slots: slots,
  );
}
