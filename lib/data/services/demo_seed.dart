import 'package:crudo/domain/food/food_ref.dart';
import 'package:crudo/domain/meal/meal_template.dart';
import 'package:crudo/domain/plan/plan_slot.dart';
import 'package:crudo/domain/plan/plan_template.dart';
import 'package:crudo/domain/shared/enums.dart';
import 'package:crudo/domain/shared/grams.dart';
import 'package:crudo/domain/shared/meal_time.dart';

/// Dev-flavor demo data: 4 meal templates + 1 everyday plan so the Today
/// screen is demoable before plan building exists (S09–S11). Wired in
/// di.dart behind `appConfigProvider.isDev`; prod stays unseeded.
const demoMealTemplates = <MealTemplate>[
  MealTemplate(
    id: 'demo-meal-breakfast',
    name: 'Protein Oats Bowl',
    tags: [MealTag.breakfast],
    foods: [
      FoodRef(foodId: 'seed-oats', grams: Grams(80)),
      FoodRef(foodId: 'seed-greek-yogurt', grams: Grams(150)),
      FoodRef(foodId: 'seed-blueberries', grams: Grams(100)),
      FoodRef(foodId: 'seed-peanut-butter', grams: Grams(20)),
    ],
  ),
  MealTemplate(
    id: 'demo-meal-lunch',
    name: 'Chicken Rice Bowl',
    tags: [MealTag.lunch],
    foods: [
      FoodRef(foodId: 'seed-chicken-breast', grams: Grams(180)),
      FoodRef(foodId: 'seed-rice-white', grams: Grams(150)),
      FoodRef(foodId: 'seed-broccoli', grams: Grams(150)),
      FoodRef(foodId: 'seed-olive-oil', grams: Grams(10)),
    ],
  ),
  MealTemplate(
    id: 'demo-meal-snack',
    name: 'Yogurt & Banana',
    tags: [MealTag.snack],
    foods: [
      FoodRef(foodId: 'seed-greek-yogurt', grams: Grams(200)),
      FoodRef(foodId: 'seed-banana', grams: Grams(120)),
      FoodRef(foodId: 'seed-almonds', grams: Grams(20)),
    ],
  ),
  MealTemplate(
    id: 'demo-meal-dinner',
    name: 'Salmon & Sweet Potato',
    tags: [MealTag.dinner],
    foods: [
      FoodRef(foodId: 'seed-salmon', grams: Grams(160)),
      FoodRef(foodId: 'seed-sweet-potato', grams: Grams(200)),
      FoodRef(foodId: 'seed-spinach', grams: Grams(100)),
      FoodRef(foodId: 'seed-olive-oil', grams: Grams(8)),
    ],
  ),
];

const demoPlanTemplate = PlanTemplate(
  id: 'demo-plan-everyday',
  name: 'Everyday Plan',
  days: [0, 1, 2, 3, 4, 5, 6],
  slots: [
    PlanSlot(
      id: 'demo-slot-breakfast',
      mealTemplateId: 'demo-meal-breakfast',
      time: MealTime(8 * 60),
    ),
    PlanSlot(
      id: 'demo-slot-lunch',
      mealTemplateId: 'demo-meal-lunch',
      time: MealTime(12 * 60 + 30),
    ),
    PlanSlot(
      id: 'demo-slot-snack',
      mealTemplateId: 'demo-meal-snack',
      time: MealTime(16 * 60),
    ),
    PlanSlot(
      id: 'demo-slot-dinner',
      mealTemplateId: 'demo-meal-dinner',
      time: MealTime(19 * 60),
    ),
  ],
);
