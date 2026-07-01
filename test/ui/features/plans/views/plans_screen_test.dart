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
    protein: 175,
    carbs: 220,
    fats: 70,
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
    protein: 120,
    carbs: 150,
    fats: 60,
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
          path: '/plans/new',
          builder: (context, state) =>
              const Scaffold(body: Text('New Plan Form')),
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
    testWidgets('renders LIBRARY eyebrow + Plans title', (tester) async {
      await pumpScreen(tester, rows: [rowA, rowB]);

      expect(find.text('LIBRARY'), findsOneWidget);
      expect(find.text('Plans'), findsOneWidget);
    });

    testWidgets('renders two PlanListCards with meta lines', (tester) async {
      await pumpScreen(tester, rows: [rowA, rowB]);

      expect(find.byType(PlanListCard), findsNWidgets(2));
      expect(find.text('Plan A'), findsOneWidget);
      expect(find.text('2200 kcal'), findsOneWidget);
      expect(find.text('Plan B'), findsOneWidget);
      expect(find.text('1800 kcal'), findsOneWidget);
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

  group('PlansScreen — add button', () {
    testWidgets('circular add button present with populated list', (
      tester,
    ) async {
      await pumpScreen(tester, rows: [rowA, rowB]);

      expect(find.byKey(const ValueKey('new-plan')), findsOneWidget);
    });

    testWidgets('add button present in empty state', (tester) async {
      await pumpScreen(tester, rows: const []);

      expect(find.text('No plans yet'), findsOneWidget);
      expect(find.byKey(const ValueKey('new-plan')), findsOneWidget);
    });

    testWidgets('tapping add navigates to /plans/new', (tester) async {
      await pumpScreen(tester, rows: [rowA]);

      await tester.tap(find.byKey(const ValueKey('new-plan')));
      await tester.pumpAndSettle();

      expect(find.text('New Plan Form'), findsOneWidget);
    });
  });

  group('PlansScreen — repeats hint', () {
    testWidgets('shows when a single plan covers all 7 days', (tester) async {
      final fullWeek = (
        id: 'F',
        name: 'Everyday',
        goal: Goal.maintain,
        kcal: 2000,
        protein: 150,
        carbs: 200,
        fats: 65,
        mealCount: 3,
        days: [0, 1, 2, 3, 4, 5, 6],
        active: true,
        isToday: true,
      );
      await pumpScreen(tester, rows: [fullWeek]);

      expect(find.text('One plan repeats daily'), findsOneWidget);
    });

    testWidgets('hidden when multiple plans split the week', (tester) async {
      await pumpScreen(tester, rows: [rowA, rowB]);

      expect(find.text('One plan repeats daily'), findsNothing);
    });
  });
}
