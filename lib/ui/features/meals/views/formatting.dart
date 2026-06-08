export 'package:crudo/ui/core/formatting.dart'
    show mealTimeLabel, timeOfDayLabel, gramsText, parseGrams;

import 'package:crudo/domain/shared/enums.dart';

/// Display labels for meal tags (editor chips + meal detail rows).
const mealTagLabels = <MealTag, String>{
  MealTag.breakfast: 'Breakfast',
  MealTag.lunch: 'Lunch',
  MealTag.dinner: 'Dinner',
  MealTag.snack: 'Snack',
  MealTag.preWorkout: 'Pre-workout',
  MealTag.postWorkout: 'Post-workout',
};

/// One-time toast when a content edit detaches a future day (S08 review
/// amendment) — shared by SwapSheet and the editor's save.
const detachToastMessage =
    "This day now keeps its own changes — plan edits won't affect it.";
