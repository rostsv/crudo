import 'package:checks/checks.dart';
import 'package:crudo/config/app_config.dart';
import 'package:crudo/config/di.dart';
import 'package:crudo/data/repositories/in_memory_day_repository.dart';
import 'package:crudo/data/repositories/in_memory_food_repository.dart';
import 'package:crudo/data/repositories/in_memory_meal_template_repository.dart';
import 'package:crudo/data/repositories/in_memory_plan_template_repository.dart';
import 'package:crudo/data/repositories/in_memory_profile_repository.dart';
import 'package:crudo/data/repositories/in_memory_streak_repository.dart';
import 'package:crudo/data/services/id_generator.dart';
import 'package:crudo/data/services/seed_service.dart';
import 'package:crudo/domain/day/day.dart';
import 'package:crudo/domain/day/scheduled_meal.dart';
import 'package:crudo/domain/food/food.dart';
import 'package:crudo/domain/food/food_ref.dart';
import 'package:crudo/domain/meal/food_snapshot.dart';
import 'package:crudo/domain/meal/meal_item.dart';
import 'package:crudo/domain/meal/meal_snapshot.dart';
import 'package:crudo/domain/meal/meal_template.dart';
import 'package:crudo/domain/plan/plan_slot.dart';
import 'package:crudo/domain/plan/plan_template.dart';
import 'package:crudo/domain/profile/prefs.dart';
import 'package:crudo/domain/profile/user_profile.dart';
import 'package:crudo/domain/shared/enums.dart';
import 'package:crudo/domain/shared/grams.dart';
import 'package:crudo/domain/shared/meal_time.dart';
import 'package:crudo/domain/streak/streak.dart';
import 'package:crudo/ui/core/themes/theme.dart';
import 'package:crudo/ui/core/widgets/app_shell.dart';
import 'package:crudo/ui/features/today/view_models/streak_catchup_controller.dart';
import 'package:crudo/ui/features/today/view_models/today_providers.dart';
import 'package:crudo/ui/features/today/views/today_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// Create a [MealItem] with given kcal (all from protein). If [checkedAt] is
/// non-null, the item is marked eaten (done).
MealItem _mealItem(double kcal, {DateTime? checkedAt}) {
  return MealItem(
    checkedAt: checkedAt,
    food: FoodSnapshot(
      sourceFoodId: 'f1',
      name: 'Eggs',
      kind: FoodKind.product,
      category: FoodCategory.eggs,
      grams: const Grams(100),
      protein: kcal / 4,
      carbs: 0,
      fats: 0,
      kcal: kcal,
    ),
  );
}

/// Build a locked green [Day] for [date].
Day lockedGreenDay(DateTime date) => Day(
  date: date,
  sourcePlanId: 'p1',
  planName: 'Test Plan',
  meals: [
    ScheduledMeal(
      id: 'm-${date.day}',
      time: const MealTime(480),
      meal: MealSnapshot(
        name: 'Omelette',
        items: [
          _mealItem(
            270,
            checkedAt: DateTime.utc(date.year, date.month, date.day, 8),
          ),
        ],
      ),
    ),
  ],
  adherence: 1.0,
  thresholdUsed: 80,
  lockedAt: DateTime.utc(date.year, date.month, date.day, 23, 59),
);

/// Shared food + template + plan seed for catch-up materialization.
const _food = Food(
  id: 'f1',
  name: 'Eggs',
  kind: FoodKind.product,
  category: FoodCategory.eggs,
  protein: 25,
  carbs: 2,
  fats: 18,
  kcalPer100g: 270,
);
final _foodRef = FoodRef(foodId: 'f1', grams: const Grams(100));
final _mealTemplate = MealTemplate(
  id: 'mt1',
  name: 'Omelette',
  foods: [_foodRef],
);
final _planSlot = PlanSlot(
  id: 'ps1',
  mealTemplateId: 'mt1',
  time: const MealTime(480),
);
final _planTemplate = PlanTemplate(
  id: 'p1',
  name: 'Test Plan',
  days: [1, 2, 3, 4, 5, 6, 7],
  slots: [_planSlot],
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final now = DateTime(2026, 6, 10, 9, 30);
  final yesterday = DateTime.utc(2026, 6, 9);
  final twoDaysAgo = DateTime.utc(2026, 6, 8);

  GoRouter appShellRouter() => GoRouter(
    initialLocation: '/today',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/today',
                builder: (_, _) => const SizedBox.shrink(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/plans',
                builder: (_, _) => const SizedBox.shrink(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/history',
                builder: (_, _) => const SizedBox.shrink(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (_, _) => const SizedBox.shrink(),
              ),
            ],
          ),
        ],
      ),
    ],
  );

  Widget appShellTestWidget({
    required Streak initialStreak,
    required List<Day> persistedDays,
  }) {
    final streakRepo = InMemoryStreakRepository();
    streakRepo.save(initialStreak);

    final dayRepo = InMemoryDayRepository();
    for (final d in persistedDays) {
      dayRepo.save(d);
    }

    final profileRepo = InMemoryProfileRepository();
    profileRepo.save(
      const UserProfile(id: 'u1', prefs: Prefs(streakThreshold: 80)),
    );

    final planRepo = InMemoryPlanTemplateRepository(seed: [_planTemplate]);
    final mealRepo = InMemoryMealTemplateRepository(seed: [_mealTemplate]);
    final foodRepo = InMemoryFoodRepository(seed: [_food]);

    return ProviderScope(
      overrides: [
        appConfigProvider.overrideWithValue(AppConfig(flavor: Flavor.dev)),
        clockProvider.overrideWithValue(() => now),
        streakRepositoryProvider.overrideWithValue(streakRepo),
        dayRepositoryProvider.overrideWithValue(dayRepo),
        profileRepositoryProvider.overrideWithValue(profileRepo),
        planTemplateRepositoryProvider.overrideWithValue(planRepo),
        mealTemplateRepositoryProvider.overrideWithValue(mealRepo),
        foodRepositoryProvider.overrideWithValue(foodRepo),
        idGeneratorProvider.overrideWithValue(const IdGenerator()),
      ],
      child: MaterialApp.router(
        theme: crudoTheme,
        routerConfig: appShellRouter(),
      ),
    );
  }

  // Diagnostic: verify catch-up logic works with our seed data.
  test('catch-up returns [7] from seeded data', () async {
    final streakRepo = InMemoryStreakRepository();
    await streakRepo.save(
      Streak(
        current: 6,
        personalBest: 6,
        lastCountedDay: DateTime.utc(2026, 6, 7),
      ),
    );

    final dayRepo = InMemoryDayRepository();
    await dayRepo.save(lockedGreenDay(twoDaysAgo));
    await dayRepo.save(lockedGreenDay(yesterday));

    final profileRepo = InMemoryProfileRepository();
    await profileRepo.save(
      const UserProfile(id: 'u1', prefs: Prefs(streakThreshold: 80)),
    );

    final planRepo = InMemoryPlanTemplateRepository(seed: [_planTemplate]);
    final mealRepo = InMemoryMealTemplateRepository(seed: [_mealTemplate]);
    final foodRepo = InMemoryFoodRepository(seed: [_food]);

    final container = ProviderContainer(
      overrides: [
        appConfigProvider.overrideWithValue(AppConfig(flavor: Flavor.dev)),
        clockProvider.overrideWithValue(() => now),
        streakRepositoryProvider.overrideWithValue(streakRepo),
        dayRepositoryProvider.overrideWithValue(dayRepo),
        profileRepositoryProvider.overrideWithValue(profileRepo),
        planTemplateRepositoryProvider.overrideWithValue(planRepo),
        mealTemplateRepositoryProvider.overrideWithValue(mealRepo),
        foodRepositoryProvider.overrideWithValue(foodRepo),
        idGeneratorProvider.overrideWithValue(const IdGenerator()),
      ],
    );
    addTearDown(container.dispose);

    final milestones = await container.read(streakCatchUpProvider.future);
    check(milestones).deepEquals([7]);
  });

  group('Catch-up trigger wiring', () {
    testWidgets('milestone crossing shows the celebration dialog', (
      tester,
    ) async {
      await tester.pumpWidget(
        appShellTestWidget(
          initialStreak: Streak(
            current: 6,
            personalBest: 6,
            lastCountedDay: DateTime.utc(2026, 6, 7),
          ),
          persistedDays: [
            lockedGreenDay(twoDaysAgo),
            lockedGreenDay(yesterday),
          ],
        ),
      );
      // Pump to let the catch-up run and the post-frame callback fire.
      await tester.pumpAndSettle();

      // Verify milestone dialog appears for crossing 7.
      expect(find.text('7-day streak!'), findsOneWidget);
      expect(find.text('STREAK MILESTONE'), findsOneWidget);
    });

    testWidgets('no milestone crossed does not show dialog', (tester) async {
      await tester.pumpWidget(
        appShellTestWidget(
          initialStreak: Streak(
            current: 1,
            personalBest: 1,
            lastCountedDay: DateTime.utc(2026, 6, 7),
          ),
          persistedDays: [
            lockedGreenDay(twoDaysAgo),
            lockedGreenDay(yesterday),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // No milestone dialog should appear.
      expect(find.textContaining('day streak'), findsNothing);
    });
  });

  group('Today screen calendar and streak chip wiring', () {
    late List<Food> seedFoods;
    setUpAll(() async => seedFoods = await SeedService().loadFoods());

    GoRouter router(ProviderContainer c) => GoRouter(
      initialLocation: '/today',
      routes: [
        GoRoute(
          path: '/today',
          builder: (context, state) => const TodayScreen(),
        ),
        GoRoute(
          path: '/history',
          builder: (context, state) =>
              const Scaffold(body: Center(child: Text('History Tab'))),
        ),
      ],
    );

    Future<ProviderContainer> pumpToday(WidgetTester tester) async {
      final c = ProviderContainer(
        overrides: [
          appConfigProvider.overrideWithValue(AppConfig(flavor: Flavor.dev)),
          seedFoodsProvider.overrideWithValue(seedFoods),
          clockProvider.overrideWithValue(() => now),
          idGeneratorProvider.overrideWithValue(const IdGenerator()),
        ],
      );
      addTearDown(c.dispose);
      tester.view.physicalSize = const Size(800, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: c,
          child: MaterialApp.router(theme: crudoTheme, routerConfig: router(c)),
        ),
      );
      await tester.pumpAndSettle();
      return c;
    }

    testWidgets('calendar button opens the calendar sheet instead of toast', (
      tester,
    ) async {
      await pumpToday(tester);
      await tester.tap(find.byIcon(Icons.calendar_today_outlined));
      await tester.pump();
      // The old toast text should NOT be present.
      expect(find.text('Calendar — coming soon'), findsNothing);
      // Pump more to settle the modal bottom sheet animation.
      await tester.pumpAndSettle();
      expect(find.text('LAST 30 DAYS'), findsOneWidget);
    });

    testWidgets('streak chip navigates to /history on tap', (tester) async {
      await pumpToday(tester);
      await tester.pumpAndSettle();

      // Tap the streak chip (floating pill with "N-day streak").
      expect(find.text('0-day streak'), findsOneWidget);
      await tester.tap(find.text('0-day streak'));
      await tester.pumpAndSettle();

      // Should navigate to /history route.
      expect(find.text('History Tab'), findsOneWidget);
    });
  });
}
