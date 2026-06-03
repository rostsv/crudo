import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../domain/shared/enums.dart';
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
            title: 'Breakfast',
            timeLabel: '08:00',
            kcalLabel: '420 kcal',
            status: MealStatus.done,
            onTap: () {},
          ),
          const SizedBox(height: Spacing.md),
          const MealCard(
            title: 'Lunch',
            timeLabel: '12:30',
            kcalLabel: '650 kcal',
            status: MealStatus.partial,
          ),
          const SizedBox(height: Spacing.md),
          const MealCard(
            title: 'Dinner',
            timeLabel: '19:00',
            kcalLabel: '550 kcal',
            status: MealStatus.upcoming,
          ),
          const SizedBox(height: Spacing.lg),
          const Center(
            child: MacroRing(
              protein: 120,
              carbs: 200,
              fats: 60,
              centerLabel: '2 040',
            ),
          ),
        ],
      ),
    );
  }
}
