import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:crudo/ui/core/widgets/app_shell.dart';
import 'package:crudo/ui/features/history/views/history_screen.dart';
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
    ],
  );
});
