import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../domain/shared/enums.dart';
import '../../../../domain/shared/macros.dart';
import '../../../core/themes/colors.dart';
import '../../../core/themes/typography.dart';
import '../../../core/themes/dimensions.dart';
import '../../../core/widgets/macro_ring.dart';
import '../../../core/widgets/meal_card.dart';

class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(Spacing.md),
        children: [
          const Text('Today', style: CrudoText.headline),
          const SizedBox(height: Spacing.lg),
          MealCard(
            title: 'Protein Bowl',
            timeLabel: '08:00',
            mealTypeLabel: 'Breakfast',
            macros: const Macros(protein: 32, carbs: 45, fats: 12, kcal: 420),
            ingredientNames: const ['Egg, whole', 'Greek Yogurt', 'Oats, dry'],
            status: MealStatus.done,
            onTap: () {},
          ),
          const SizedBox(height: Spacing.md),
          const MealCard(
            title: 'Quinoa Salad',
            timeLabel: '12:30',
            mealTypeLabel: 'Lunch',
            macros: Macros(protein: 48, carbs: 52, fats: 18, kcal: 650),
            ingredientNames: [
              'Quinoa, cooked',
              'Chicken Breast',
              'Spinach',
              'Olive Oil',
            ],
            status: MealStatus.partial,
          ),
          const SizedBox(height: Spacing.md),
          const MealCard(
            title: 'Baked Salmon',
            timeLabel: '19:00',
            mealTypeLabel: 'Dinner',
            macros: Macros(protein: 42, carbs: 30, fats: 24, kcal: 550),
            ingredientNames: ['Salmon', 'Sweet Potato', 'Spinach'],
            status: MealStatus.upcoming,
          ),
          const SizedBox(height: Spacing.lg),
          const Center(
            child: MacroRing(
              value: 0.62,
              center: Icon(
                Icons.local_fire_department_outlined,
                size: IconSizes.lg,
                color: CrudoPalette.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
