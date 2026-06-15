import 'package:checks/checks.dart';
import 'package:crudo/config/di.dart';
import 'package:crudo/data/repositories/in_memory_profile_repository.dart';
import 'package:crudo/domain/shared/enums.dart';
import 'package:crudo/ui/core/themes/theme.dart';
import 'package:crudo/ui/core/widgets/selection_card.dart';
import 'package:crudo/ui/features/profile/views/threshold_sheet.dart';
import 'package:crudo/ui/features/profile/views/units_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProviderContainer container;

  Widget app() {
    container = ProviderContainer(
      overrides: [
        profileRepositoryProvider.overrideWithValue(
          InMemoryProfileRepository(),
        ),
      ],
    );
    addTearDown(container.dispose);
    return UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: crudoTheme,
        home: Scaffold(
          body: Builder(
            builder: (context) => Column(
              children: [
                TextButton(
                  onPressed: () => showUnitsSheet(context),
                  child: const Text('open units'),
                ),
                TextButton(
                  onPressed: () => showThresholdSheet(context),
                  child: const Text('open threshold'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  group('UnitsSheet', () {
    testWidgets('tap Ounces changes units to oz and dismisses sheet', (
      tester,
    ) async {
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();

      await tester.tap(find.text('open units'));
      await tester.pumpAndSettle();

      expect(find.text('Units'), findsOneWidget);
      expect(find.text('Grams'), findsOneWidget);
      expect(find.text('Ounces'), findsOneWidget);

      await tester.tap(find.text('Ounces'));
      await tester.pumpAndSettle();

      // Sheet should be dismissed
      expect(find.text('Units'), findsNothing);

      final profile = await container.read(profileRepositoryProvider).get();
      check(profile.prefs.units).equals(Unit.oz);
    });

    testWidgets('current selection shows selected', (tester) async {
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();

      await tester.tap(find.text('open units'));
      await tester.pumpAndSettle();

      // Default is Grams
      final gramsCard = tester.widget<SelectionCard>(
        find.widgetWithText(SelectionCard, 'Grams'),
      );
      check(gramsCard.selected).isTrue();

      final ouncesCard = tester.widget<SelectionCard>(
        find.widgetWithText(SelectionCard, 'Ounces'),
      );
      check(ouncesCard.selected).isFalse();
    });
  });

  group('ThresholdSheet', () {
    testWidgets('tap 90% changes streakThreshold to 90 and dismisses sheet', (
      tester,
    ) async {
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();

      await tester.tap(find.text('open threshold'));
      await tester.pumpAndSettle();

      expect(find.text('Streak threshold'), findsOneWidget);
      expect(find.text('GREEN LINE'), findsOneWidget);

      await tester.tap(find.text('90%'));
      await tester.pumpAndSettle();

      // Sheet should be dismissed
      expect(find.text('Streak threshold'), findsNothing);

      final profile = await container.read(profileRepositoryProvider).get();
      check(profile.prefs.streakThreshold).equals(90);
    });

    testWidgets('current selection shows selected', (tester) async {
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();

      await tester.tap(find.text('open threshold'));
      await tester.pumpAndSettle();

      // Default is 80%
      final card80 = tester.widget<SelectionCard>(
        find.widgetWithText(SelectionCard, '80%'),
      );
      check(card80.selected).isTrue();

      // Verify other cards are not selected
      final card70 = tester.widget<SelectionCard>(
        find.widgetWithText(SelectionCard, '70%'),
      );
      check(card70.selected).isFalse();
    });
  });
}
