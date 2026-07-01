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
        kcal: 554,
      ),
      (
        time: const MealTime(750),
        mealName: 'Quinoa Salad',
        tag: 'Lunch',
        kcal: 594,
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

  testWidgets('EDIT link navigates to the editor', (tester) async {
    await pumpViewer(tester, view: vm);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('plan-edit-link')));
    await tester.pumpAndSettle();

    expect(find.text('Editor A'), findsOneWidget);
  });
}
