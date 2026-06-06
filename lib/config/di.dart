import 'package:crudo/config/app_config.dart';
import 'package:crudo/data/repositories/in_memory_day_repository.dart';
import 'package:crudo/data/repositories/in_memory_food_repository.dart';
import 'package:crudo/data/repositories/in_memory_meal_template_repository.dart';
import 'package:crudo/data/repositories/in_memory_plan_template_repository.dart';
import 'package:crudo/data/repositories/in_memory_profile_repository.dart';
import 'package:crudo/data/repositories/in_memory_streak_repository.dart';
import 'package:crudo/data/services/demo_seed.dart';
import 'package:crudo/domain/food/food.dart';
import 'package:crudo/domain/repositories/day_repository.dart';
import 'package:crudo/domain/repositories/food_repository.dart';
import 'package:crudo/domain/repositories/meal_template_repository.dart';
import 'package:crudo/domain/repositories/plan_template_repository.dart';
import 'package:crudo/domain/repositories/profile_repository.dart';
import 'package:crudo/domain/repositories/streak_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Composition root. Providers are typed as DOMAIN INTERFACES — S20 swaps the
/// in-memory impls for Supabase ones here, and nowhere else.

/// Bundled food seed; loaded in bootstrap() before runApp and overridden.
final seedFoodsProvider = Provider<List<Food>>(
  (ref) => throw UnimplementedError('overridden in bootstrap()'),
);

final foodRepositoryProvider = Provider<FoodRepository>(
  (ref) => InMemoryFoodRepository(seed: ref.watch(seedFoodsProvider)),
);

final mealTemplateRepositoryProvider = Provider<MealTemplateRepository>(
  (ref) => InMemoryMealTemplateRepository(
    seed: ref.watch(appConfigProvider).isDev ? demoMealTemplates : const [],
  ),
);

final planTemplateRepositoryProvider = Provider<PlanTemplateRepository>(
  (ref) => InMemoryPlanTemplateRepository(
    seed: ref.watch(appConfigProvider).isDev
        ? const [demoPlanTemplate]
        : const [],
  ),
);

final dayRepositoryProvider = Provider<DayRepository>(
  (ref) => InMemoryDayRepository(),
);

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => InMemoryProfileRepository(),
);

final streakRepositoryProvider = Provider<StreakRepository>(
  (ref) => InMemoryStreakRepository(),
);
