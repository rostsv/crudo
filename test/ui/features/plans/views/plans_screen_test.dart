import 'package:crudo/domain/shared/enums.dart';
import 'package:crudo/ui/features/plans/view_models/plan_draft.dart';
import 'package:crudo/ui/features/plans/view_models/plans_list.dart';
import 'package:crudo/ui/features/plans/views/plan_list_card.dart';
import 'package:crudo/ui/core/themes/theme.dart';
import 'package:crudo/ui/features/plans/views/plans_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final rowA = (
    id: 'A',
    name: 'Plan A',
    goal: Goal.cut,
    kcal: 2200,
    mealCount: 5,
    days: [0, 2, 4],
    active: true,
    isToday: true,
  );
  final rowB = (
    id: 'B',
    name: 'Plan B',
    goal: Goal.maintain,
    kcal: 1800,
    mealCount: 1,
    days: [5, 6],
    active: false,
    isToday: false,
  );

  /// Pump [PlansScreen] inside a [GoRouter] harness with [plansListProvider]
  /// overridden to [rows].
  Future<void> pumpScreen(
    WidgetTester tester, {
    required List<PlanRowVm> rows,
  }) async {
    final router = GoRouter(
      initialLocation: '/plans',
      routes: [
        GoRoute(
          path: '/plans',
          builder: (context, state) => const PlansScreen(),
        ),
        GoRoute(
          path: '/plans/:id',
          builder: (context, state) =>
              Scaffold(body: Text('Detail ${state.pathParameters['id']}')),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [plansListProvider.overrideWithValue(rows)],
        child: MaterialApp.router(theme: crudoTheme, routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('PlansScreen', () {
    testWidgets('renders two PlanListCards with correct content', (
      tester,
    ) async {
      await pumpScreen(tester, rows: [rowA, rowB]);

      expect(find.byType(PlanListCard), findsNWidgets(2));

      // Row A
      expect(find.text('Plan A'), findsOneWidget);
      expect(find.text('CUT · 2200 KCAL · 5 meals'), findsOneWidget);
      expect(find.text('Today'), findsOneWidget);

      // Row B
      expect(find.text('Plan B'), findsOneWidget);
      expect(find.text('MAINTAIN · 1800 KCAL · 1 meal'), findsOneWidget);
      expect(find.text('Inactive'), findsOneWidget);

      // Only A has Today badge
      expect(find.text('Today'), findsOneWidget);
    });

    testWidgets('tapping a card pushes to /plans/:id', (tester) async {
      await pumpScreen(tester, rows: [rowA, rowB]);

      await tester.tap(find.text('Plan A'));
      await tester.pumpAndSettle();

      expect(find.text('Detail A'), findsOneWidget);
    });

    testWidgets('empty list shows "No plans yet"', (tester) async {
      await pumpScreen(tester, rows: const []);

      expect(find.text('No plans yet'), findsOneWidget);
      expect(find.byType(PlanListCard), findsNothing);
    });
  });
}
