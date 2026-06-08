import 'package:crudo/domain/food/food.dart';
import 'package:crudo/domain/meal/meal_template.dart';
import 'package:crudo/domain/plan/plan_template.dart';
import 'package:crudo/domain/services/nutrition.dart'; // mealTemplateMacros
import 'package:crudo/domain/services/plan_scheduling.dart'; // selectPlanForDate
import 'package:crudo/domain/shared/enums.dart';
import 'package:crudo/domain/shared/macros.dart';
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

  int kcalOf(PlanTemplate p) {
    var total = const Macros();
    for (final s in p.slots) {
      final mt = templates[s.mealTemplateId];
      if (mt == null) continue;
      total = total + mealTemplateMacros(mt, foods);
    }
    return total.kcal.round();
  }

  return [
    for (final p in plans)
      (
        id: p.id,
        name: p.name,
        days: p.days,
        goal: goal,
        kcal: kcalOf(p),
        mealCount: p.slots.length,
        active: p.active,
        isToday: p.id == todayPlanId,
      ),
  ];
}
