import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:crudo/ui/core/widgets/app_shell.dart';
import 'package:crudo/ui/core/formatting.dart';
import 'package:crudo/ui/features/foods/views/food_form_screen.dart';
import 'package:crudo/ui/features/foods/views/food_library_screen.dart';
import 'package:crudo/ui/features/history/views/history_screen.dart';
import 'package:crudo/ui/features/meals/views/add_ingredient_screen.dart';
import 'package:crudo/ui/features/meals/views/meal_detail_screen.dart';
import 'package:crudo/ui/features/meals/views/meal_editor_screen.dart';
import 'package:crudo/ui/features/meals/views/meal_template_builder_screen.dart';
import 'package:crudo/ui/features/meals/views/meal_template_library_screen.dart';
import 'package:crudo/domain/meal/meal_template.dart';
import 'package:crudo/domain/plan/plan_template.dart';
import 'package:crudo/ui/features/plans/views/plan_detail_screen.dart';
import 'package:crudo/ui/features/plans/views/plans_screen.dart';
import 'package:crudo/ui/features/profile/views/profile_screen.dart';
import 'package:crudo/ui/features/today/views/today_screen.dart';

/// 4-tab shell. Pushed detail routes (mealDetail, createPlan, ...) are added
/// by their feature specs; sheets are NOT routes (see showCrudoSheet).
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
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
                builder: (context, state) => const TodayScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/plans',
                builder: (context, state) => const PlansScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/history',
                builder: (context, state) => const HistoryScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),

      // S07: dev-reachable, not yet linked from the tab bar (permanent nav
      // placement decided later — S15 candidate). S08's add-ingredient
      // picker reuses the library list.
      GoRoute(
        path: '/foods',
        builder: (context, state) => const FoodLibraryScreen(),
        routes: [
          GoRoute(
            path: 'new',
            builder: (context, state) => const FoodFormScreen(foodId: null),
          ),
          GoRoute(
            path: ':id',
            builder: (context, state) =>
                FoodFormScreen(foodId: state.pathParameters['id']!),
          ),
        ],
      ),

      // S11: plan create — pushed over the shell. [seed] passed via extra.
      GoRoute(
        path: '/plans/new',
        builder: (context, state) =>
            PlanDetailScreen(planId: null, seed: state.extra as PlanTemplate?),
      ),

      // S10: plan detail / editing — pushed over the shell.
      GoRoute(
        path: '/plans/:id',
        builder: (context, state) =>
            PlanDetailScreen(planId: state.pathParameters['id']!),
      ),

      // S08: meal detail / editor / picker — pushed over the shell. :date is
      // the ISO day label (dayParam/parseDayParam).
      GoRoute(
        path: '/meal/:date/:mealId',
        builder: (context, state) => MealDetailScreen(
          date: parseDayParam(state.pathParameters['date']!),
          mealId: state.pathParameters['mealId']!,
        ),
        routes: [
          GoRoute(
            path: 'edit',
            builder: (context, state) => MealEditorScreen(
              date: parseDayParam(state.pathParameters['date']!),
              mealId: state.pathParameters['mealId']!,
            ),
            routes: [
              GoRoute(
                path: 'add-ingredient',
                builder: (context, state) => const AddIngredientScreen(),
              ),
            ],
          ),
        ],
      ),

      // S11a: meal-template library list — pushed over the shell.
      GoRoute(
        path: '/meal-templates',
        builder: (context, state) => const MealTemplateLibraryScreen(),
      ),

      // S11a: meal-template builder (library create/edit) — pushed over the shell.
      // [seed] is an optional in-memory MealTemplate duplicate (via state.extra).
      GoRoute(
        path: '/meal-templates/new',
        builder: (context, state) => MealTemplateBuilderScreen(
          templateId: null,
          seed: state.extra as MealTemplate?,
        ),
        routes: [
          GoRoute(
            path: 'add-ingredient',
            builder: (context, state) => const AddIngredientScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/meal-templates/:id',
        builder: (context, state) =>
            MealTemplateBuilderScreen(templateId: state.pathParameters['id']!),
        routes: [
          GoRoute(
            path: 'add-ingredient',
            builder: (context, state) => const AddIngredientScreen(),
          ),
        ],
      ),
    ],
  );
});
