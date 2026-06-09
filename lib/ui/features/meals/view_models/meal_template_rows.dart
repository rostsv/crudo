import 'package:crudo/domain/food/food.dart';
import 'package:crudo/domain/meal/meal_template.dart';
import 'package:crudo/domain/plan/plan_template.dart';
import 'package:crudo/domain/services/nutrition.dart'; // mealTemplateMacros
import 'package:crudo/domain/services/plan_scheduling.dart'; // templateUsage
import 'package:crudo/domain/shared/enums.dart'; // MealTag
import 'package:crudo/ui/features/today/view_models/today_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'meal_template_rows.g.dart';

/// One library row — display data resolved up front.
typedef MealTemplateRowVm = ({
  String id,
  String name,
  List<MealTag> tags,
  int kcal, // mealTemplateMacros, rounded
  int usedInPlans, // templateUsage(plans, id).using.length
});

/// Library feed. Sync derived provider (mirrors plansList): reads .value of
/// the S06 stream providers; empty until data arrives.
@riverpod
List<MealTemplateRowVm> mealTemplateRows(Ref ref) {
  final templates =
      ref.watch(mealTemplatesProvider).value ?? const <MealTemplate>[];
  final Map<String, Food> foods = {
    for (final f in ref.watch(foodsProvider).value ?? const <Food>[]) f.id: f,
  };
  final plans =
      ref.watch(planTemplatesProvider).value ?? const <PlanTemplate>[];
  return [
    for (final t in templates)
      (
        id: t.id,
        name: t.name,
        tags: t.tags,
        kcal: mealTemplateMacros(t, foods).kcal.round(),
        usedInPlans: templateUsage(plans, t.id).using.length,
      ),
  ];
}
