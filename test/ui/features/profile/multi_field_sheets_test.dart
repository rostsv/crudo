import 'package:checks/checks.dart';
import 'package:crudo/config/di.dart';
import 'package:crudo/data/repositories/in_memory_profile_repository.dart';
import 'package:crudo/domain/shared/enums.dart';
import 'package:crudo/ui/core/themes/theme.dart';
import 'package:crudo/ui/core/widgets/crudo_stepper.dart';
import 'package:crudo/ui/core/widgets/crudo_toggle.dart';
import 'package:crudo/ui/core/widgets/settings_section.dart';
import 'package:crudo/ui/features/profile/views/display_name_sheet.dart';
import 'package:crudo/ui/features/profile/views/goal_sheet.dart';
import 'package:crudo/ui/features/profile/views/reminders_sheet.dart';
import 'package:crudo/ui/features/today/view_models/today_providers.dart';
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
          body: Consumer(
            builder: (context, ref, child) {
              ref.watch(profileProvider);
              return Builder(
                builder: (context) => Column(
                  children: [
                    TextButton(
                      onPressed: () => showRemindersSheet(context),
                      child: const Text('open reminders'),
                    ),
                    TextButton(
                      onPressed: () => showGoalSheet(context),
                      child: const Text('open goal'),
                    ),
                    TextButton(
                      onPressed: () => showDisplayNameSheet(context),
                      child: const Text('open name'),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> openSheet(WidgetTester tester, String label) async {
    await tester.tap(find.text(label));
    await tester.pumpAndSettle();
  }

  group('RemindersSheet', () {
    testWidgets('toggle Pre-meal off, stepper down 1, save changes prefs', (
      tester,
    ) async {
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();

      await openSheet(tester, 'open reminders');

      expect(find.text('How we ping you'), findsOneWidget);
      expect(find.text('No-action warning'), findsNothing);

      // Toggle "Pre-meal heads up" off
      final preMealRow = find.widgetWithText(SettingsRow, 'Pre-meal heads up');
      expect(preMealRow, findsOneWidget);
      final preToggle = find.descendant(
        of: preMealRow,
        matching: find.byType(CrudoToggle),
      );
      expect(preToggle, findsOneWidget);
      await tester.tap(preToggle);
      await tester.pumpAndSettle();

      // Tap "−" on the Pre-meal lead stepper
      await tester.tap(find.text('−'));
      await tester.pumpAndSettle();

      // Save
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Sheet should be dismissed
      expect(find.text('How we ping you'), findsNothing);

      final profile = await container.read(profileRepositoryProvider).get();
      check(profile.prefs.preOn).isFalse();
      check(profile.prefs.preMin).equals(25);
      check(profile.prefs.atOn).isTrue();
      check(profile.prefs.eodOn).isTrue();
      check(profile.prefs.riskOn).isTrue();
    });

    testWidgets('shows exactly 4 toggles', (tester) async {
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();

      await openSheet(tester, 'open reminders');

      check(find.byType(CrudoToggle).evaluate().length).equals(4);
    });
  });

  group('GoalSheet', () {
    testWidgets('pick Bulk, enable target, set 2200, save', (tester) async {
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();

      await openSheet(tester, 'open goal');

      expect(find.text('Bulk'), findsOneWidget);

      // Select Bulk
      await tester.tap(find.text('Bulk'));
      await tester.pumpAndSettle();

      // Enable "Set a target" toggle
      final targetRow = find.widgetWithText(SettingsRow, 'Set a target');
      expect(targetRow, findsOneWidget);
      final targetToggle = find.descendant(
        of: targetRow,
        matching: find.byType(CrudoToggle),
      );
      await tester.tap(targetToggle);
      await tester.pumpAndSettle();

      // Stepper should now be visible
      expect(find.byType(CrudoStepper), findsOneWidget);

      // Step from 2000 to 2200 (4 taps of +)
      for (var i = 0; i < 4; i++) {
        await tester.tap(find.text('+'));
        await tester.pumpAndSettle();
      }

      // Save
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Sheet should be dismissed
      expect(find.text('Bulk'), findsNothing);

      final profile = await container.read(profileRepositoryProvider).get();
      check(profile.prefs.goal).equals(Goal.bulk);
      check(profile.prefs.dailyKcalTarget).equals(2200);
    });

    testWidgets('target toggle off saves null target', (tester) async {
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();

      await openSheet(tester, 'open goal');

      // Select Cut
      await tester.tap(find.text('Cut'));
      await tester.pumpAndSettle();

      // "Set a target" toggle is off by default, so just save
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      final profile = await container.read(profileRepositoryProvider).get();
      check(profile.prefs.goal).equals(Goal.cut);
      check(profile.prefs.dailyKcalTarget).isNull();
    });
  });

  group('DisplayNameSheet', () {
    testWidgets('enter Mark and save', (tester) async {
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();

      await openSheet(tester, 'open name');

      expect(find.text('Your name'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'Mark');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Sheet should be dismissed
      expect(find.text('Your name'), findsNothing);

      final profile = await container.read(profileRepositoryProvider).get();
      check(profile.displayName).equals('Mark');
    });

    testWidgets('empty text disables save', (tester) async {
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();

      await openSheet(tester, 'open name');

      // TextField is empty by default
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Sheet should still be open
      expect(find.text('Your name'), findsOneWidget);

      final profile = await container.read(profileRepositoryProvider).get();
      check(profile.displayName).isNull();
    });
  });
}
