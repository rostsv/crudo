import '../day/day.dart';
import '../day/scheduled_meal.dart';
import '../food/food.dart';
import '../meal/food_snapshot.dart';
import '../meal/meal_item.dart';
import '../meal/meal_snapshot.dart';
import '../meal/meal_template.dart';
import '../plan/plan_template.dart';
import '../shared/enums.dart';
import '../shared/macros.dart';
import 'meal_status.dart';
import 'nutrition.dart';

/// Engine façade (S05): UI pre-check predicates. Every throwing Day op has a
/// matching predicate — views consult these and never discover a guard by
/// catching. Materialization + kcal live below (Task 6).

/// Locked = the label date is before today's label. Purely derived — correct
/// even if the app was closed across many midnights (no timer, no write).
bool isDayLocked(Day day, DateTime today) => day.date.isBefore(today);

/// Content edits (replaceMeal now; add/remove/grams at S08) only while the
/// derived status is `upcoming` — blocks edit-after-eating and the
/// "delete what I didn't eat" adherence cheat.
bool canEditMealContent(ScheduledMeal meal, DateTime dayDate, DateTime now) =>
    !dayDate.isBefore(localDateLabel(now)) &&
    deriveMealStatus(meal, dayDate, now) == MealStatus.upcoming;

bool canSkipMeal(Day day, String mealId, DateTime today) {
  if (isDayLocked(day, today)) return false;
  final meal = day.meals.where((m) => m.id == mealId).firstOrNull;
  return meal != null && !meal.meal.anyChecked;
}

bool canSnoozeMeal(Day day, String mealId, DateTime now, DateTime today) {
  if (isDayLocked(day, today)) return false;
  final meal = day.meals.where((m) => m.id == mealId).firstOrNull;
  if (meal == null || meal.meal.allChecked) return false;
  return maxSnoozeUntil(day, mealId, now).isAfter(now);
}

/// min(next meal by time strictly greater, end-of-day midnight) as UTC.
DateTime maxSnoozeUntil(Day day, String mealId, DateTime now) =>
    day.maxSnoozeUntilFor(mealId, now);

/// The active plan covering [date]'s weekday (0=Mon…6=Sun). >1 match should
/// be impossible (S09 blocks weekday conflicts) — defensively the lowest id
/// wins, deterministically.
PlanTemplate? selectPlanForDate(List<PlanTemplate> plans, DateTime date) {
  final weekday = date.weekday - 1;
  final matches =
      plans.where((p) => p.active && p.days.contains(weekday)).toList()
        ..sort((a, b) => a.id.compareTo(b.id));
  return matches.isEmpty ? null : matches.first;
}

/// Materializes a Day from a plan (copy-on-write read path — the S06
/// controller persists the result ONLY for today, or on first edit of a
/// future day; otherwise it's a throwaway preview).
///
/// PURE: no repo access — the caller passes raw repo data; refs are resolved
/// here by id. A dangling food ref drops that item; a dangling template (or a
/// slot whose items all dangle) drops the slot (S07/S09 prevent upstream).
/// [newId] mints slot-stable ScheduledMeal ids (uuid v7 in production —
/// injected as a function so the domain stays uuid-free).
Day buildDayFromPlan(
  PlanTemplate? plan,
  DateTime date,
  String Function() newId,
  List<MealTemplate> mealTemplates,
  List<Food> foods,
) {
  if (plan == null) return Day(date: date);
  final templatesById = {for (final t in mealTemplates) t.id: t};
  final foodsById = {for (final f in foods) f.id: f};

  final slots = [...plan.slots]..sort((a, b) => a.time.compareTo(b.time));
  final meals = <ScheduledMeal>[];
  for (final slot in slots) {
    final template = templatesById[slot.mealTemplateId];
    if (template == null) continue;
    final items = <MealItem>[
      for (final ref in template.foods)
        if (foodsById[ref.foodId] != null)
          MealItem(food: FoodSnapshot.from(foodsById[ref.foodId]!, ref.grams)),
    ];
    if (items.isEmpty) continue;
    meals.add(
      ScheduledMeal(
        id: newId(),
        time: slot.time,
        meal: MealSnapshot(
          sourceMealTemplateId: template.id,
          name: template.name,
          tags: template.tags,
          items: items,
        ),
      ),
    );
  }
  return Day(
    date: date,
    sourcePlanId: plan.id,
    planName: plan.name,
    meals: meals,
  );
}

/// Day totals — plain summation of stored absolutes (no multiplication at
/// read time; the formula ran once at snapshot creation).
Macros plannedMacros(Day day) => day.meals.fold(
  const Macros(),
  (total, m) => total + mealSnapshotMacros(m.meal),
);

Macros consumedMacros(Day day) => day.meals.fold(
  const Macros(),
  (total, m) => total + consumedMealMacros(m.meal),
);

double plannedKcal(Day day) => plannedMacros(day).kcal;
double consumedKcal(Day day) => consumedMacros(day).kcal;
