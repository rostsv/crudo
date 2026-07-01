import 'package:crudo/domain/shared/macros.dart';
import 'package:crudo/domain/shared/meal_time.dart';
import 'package:crudo/ui/core/themes/theme.dart';
import 'package:crudo/ui/features/plans/view_models/plan_draft.dart';
import 'package:crudo/ui/features/plans/view_models/plans_list.dart';
import 'package:crudo/ui/features/plans/views/plan_view_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final vm = (
    name: 'Weekday Cut',
    active: true,
    days: [0, 1, 2, 3, 4],
    total: const Macros(protein: 181, carbs: 192, fats: 93, kcal: 2273),
    mealCount: 2,
    slots: [
      (
        time: const MealTime(480),
        mealName: 'Protein Bowl',
        tag: 'Breakfast',
        macros: const Macros(protein: 40, carbs: 30, fats: 20, kcal: 554),
        ingredients: const <PlanIngredientView>[
          (name: 'Oats', grams: 80, kcal: 300),
        ],
      ),
      (
        time: const MealTime(750),
        mealName: 'Quinoa Salad',
        tag: 'Lunch',
        macros: const Macros(protein: 30, carbs: 60, fats: 18, kcal: 594),
        ingredients: const <PlanIngredientView>[],
      ),
    ],
  );

  Future<void> pumpViewer(WidgetTester tester, {required PlanViewVm view}) {
    final router = GoRouter(
      initialLocation: '/plans/A',
      routes: [
        GoRoute(
          path: '/plans/A',
          builder: (context, state) => const PlanViewScreen(planId: 'A'),
        ),
        GoRoute(
          path: '/plans/A/edit',
          builder: (context, state) => const Scaffold(body: Text('Editor A')),
        ),
      ],
    );

    return tester.pumpWidget(
      ProviderScope(
        overrides: [planViewProvider('A').overrideWithValue(view)],
        child: MaterialApp.router(theme: crudoTheme, routerConfig: router),
      ),
    );
  }

  testWidgets('renders eyebrow, name, daily target, slots', (tester) async {
    await pumpViewer(tester, view: vm);
    await tester.pumpAndSettle();

    expect(find.text('PLAN'), findsOneWidget);
    expect(find.text('Weekday Cut'), findsOneWidget);
    expect(find.text('DAILY TARGET'), findsOneWidget);
    expect(find.text('2273'), findsOneWidget);
    expect(find.text('MEAL SLOTS'), findsOneWidget);
    expect(find.text('2 SLOTS'), findsOneWidget);
    expect(find.text('Protein Bowl'), findsOneWidget);
    expect(find.text('Breakfast · 554 kcal'), findsOneWidget);
    expect(find.text('Quinoa Salad'), findsOneWidget);
  });

  testWidgets('··· Edit action navigates to the editor', (tester) async {
    await pumpViewer(tester, view: vm);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('plan-actions')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();

    expect(find.text('Editor A'), findsOneWidget);
  });

  testWidgets('actions sheet has no Cancel button', (tester) async {
    await pumpViewer(tester, view: vm);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('plan-actions')));
    await tester.pumpAndSettle();

    expect(find.text('Edit'), findsOneWidget);
    expect(find.text('Duplicate'), findsOneWidget);
    expect(find.text('Delete plan'), findsOneWidget);
    expect(find.text('Cancel'), findsNothing);
  });

  testWidgets('tapping a slot opens the slot sheet, not the editor', (
    tester,
  ) async {
    await pumpViewer(tester, view: vm);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Protein Bowl'));
    await tester.pumpAndSettle();

    // Recipe-style slot sheet, not the editor.
    expect(find.text('Oats'), findsOneWidget);
    expect(find.text('Total'), findsOneWidget);
    expect(find.text('Editor A'), findsNothing);
  });
}
