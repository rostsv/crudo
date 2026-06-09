import 'package:checks/checks.dart';
import 'package:crudo/domain/shared/enums.dart';
import 'package:crudo/ui/core/themes/theme.dart';
import 'package:crudo/ui/features/meals/view_models/meal_template_rows.dart';
import 'package:crudo/ui/features/plans/views/meal_picker_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final row1 = (
    id: 't1',
    name: 'Breakfast',
    tags: <MealTag>[MealTag.breakfast],
    kcal: 500,
    usedInPlans: 2,
  );
  final row2 = (
    id: 't2',
    name: 'Lunch',
    tags: <MealTag>[MealTag.lunch],
    kcal: 700,
    usedInPlans: 1,
  );

  group('MealPickerSheet', () {
    testWidgets('renders title, rows, Create new meal CTA, and Done button', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            mealTemplateRowsProvider.overrideWithValue([row1, row2]),
          ],
          child: MaterialApp(
            theme: crudoTheme,
            home: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showMealPickerSheet(context),
                child: const Text('Open picker'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open picker'));
      await tester.pumpAndSettle();

      expect(find.text('Add meals'), findsOneWidget);
      expect(find.text('Breakfast'), findsOneWidget);
      expect(find.text('Lunch'), findsOneWidget);
      expect(find.byKey(const ValueKey('picker-create-new')), findsOneWidget);
      expect(find.byKey(const ValueKey('picker-done')), findsOneWidget);
      expect(find.byKey(const ValueKey('picker-row-t1')), findsOneWidget);
      expect(find.byKey(const ValueKey('picker-row-t2')), findsOneWidget);
      expect(find.byKey(const ValueKey('picker-dup-t1')), findsOneWidget);
      expect(find.byKey(const ValueKey('picker-dup-t2')), findsOneWidget);
    });

    testWidgets('toggling two rows + Done returns selectedTemplateIds', (
      tester,
    ) async {
      MealPickerResult? captured;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            mealTemplateRowsProvider.overrideWithValue([row1, row2]),
          ],
          child: MaterialApp(
            theme: crudoTheme,
            home: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  captured = await showMealPickerSheet(context);
                },
                child: const Text('Open picker'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open picker'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('picker-row-t1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('picker-row-t2')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('picker-done')));
      await tester.pumpAndSettle();

      check(captured).isNotNull();
      final r = captured!;
      check(r.selectedTemplateIds).isNotNull().deepEquals(['t1', 't2']);
      check(r.createNew).isFalse();
      check(r.duplicateTemplateId).isNull();
    });

    testWidgets('"Create new meal" returns createNew: true', (tester) async {
      MealPickerResult? captured;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            mealTemplateRowsProvider.overrideWithValue([row1]),
          ],
          child: MaterialApp(
            theme: crudoTheme,
            home: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  captured = await showMealPickerSheet(context);
                },
                child: const Text('Open picker'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open picker'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('picker-create-new')));
      await tester.pumpAndSettle();

      check(captured).isNotNull();
      final r = captured!;
      check(r.createNew).isTrue();
      check(r.selectedTemplateIds).isNull();
      check(r.duplicateTemplateId).isNull();
    });

    testWidgets('Duplicate on a row returns its id', (tester) async {
      MealPickerResult? captured;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            mealTemplateRowsProvider.overrideWithValue([row1, row2]),
          ],
          child: MaterialApp(
            theme: crudoTheme,
            home: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  captured = await showMealPickerSheet(context);
                },
                child: const Text('Open picker'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open picker'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('picker-dup-t1')));
      await tester.pumpAndSettle();

      check(captured).isNotNull();
      final r = captured!;
      check(r.duplicateTemplateId).equals('t1');
      check(r.createNew).isFalse();
      check(r.selectedTemplateIds).isNull();
    });
  });
}
