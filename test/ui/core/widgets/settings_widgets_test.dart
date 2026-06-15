import 'package:checks/checks.dart';
import 'package:crudo/ui/core/themes/theme.dart';
import 'package:crudo/ui/core/widgets/crudo_stepper.dart';
import 'package:crudo/ui/core/widgets/crudo_toggle.dart';
import 'package:crudo/ui/core/widgets/settings_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) => MaterialApp(
  theme: crudoTheme,
  home: Scaffold(body: child),
);

void main() {
  group('SettingsSection', () {
    testWidgets('renders uppercase kicker and children in card', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          SettingsSection(
            title: 'NOTIFICATIONS',
            children: [SettingsRow(label: 'Pre-meal', onTap: () {})],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('NOTIFICATIONS'), findsOneWidget);
      expect(find.text('Pre-meal'), findsOneWidget);
    });
  });

  group('SettingsRow', () {
    testWidgets('tap fires callback and renders label/subtitle', (
      tester,
    ) async {
      var tapped = false;
      await tester.pumpWidget(
        _wrap(
          SettingsRow(
            label: 'Reminders',
            subtitle: 'Turn on meal reminders',
            onTap: () => tapped = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Reminders'), findsOneWidget);
      expect(find.text('Turn on meal reminders'), findsOneWidget);

      // Default chevron when onTap != null
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);

      await tester.tap(find.text('Reminders'));
      check(tapped).isTrue();
    });

    testWidgets('no chevron when onTap is null', (tester) async {
      await tester.pumpWidget(
        _wrap(const SettingsRow(label: 'Static', trailing: Text('value'))),
      );
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.chevron_right), findsNothing);
      expect(find.text('value'), findsOneWidget);
    });
  });

  group('CrudoToggle', () {
    testWidgets('tap calls onChanged(true) when value is false', (
      tester,
    ) async {
      bool? newValue;
      await tester.pumpWidget(
        _wrap(CrudoToggle(value: false, onChanged: (v) => newValue = v)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(CrudoToggle));
      await tester.pumpAndSettle();
      check(newValue).equals(true);
    });

    testWidgets('tap calls onChanged(false) when value is true', (
      tester,
    ) async {
      bool? newValue;
      await tester.pumpWidget(
        _wrap(CrudoToggle(value: true, onChanged: (v) => newValue = v)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(CrudoToggle));
      await tester.pumpAndSettle();
      check(newValue).equals(false);
    });
  });

  group('CrudoStepper', () {
    testWidgets('"+" calls onChanged(35) from 30', (tester) async {
      int? newValue;
      await tester.pumpWidget(
        _wrap(
          CrudoStepper(
            value: 30,
            min: 5,
            max: 60,
            step: 5,
            suffix: 'm',
            onChanged: (v) => newValue = v,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('30m'), findsOneWidget);

      await tester.tap(find.text('+'));
      await tester.pumpAndSettle();
      check(newValue).equals(35);
    });

    testWidgets('at max "+" is a no-op (stays 60)', (tester) async {
      int? newValue;
      await tester.pumpWidget(
        _wrap(
          CrudoStepper(
            value: 60,
            min: 5,
            max: 60,
            step: 5,
            suffix: 'm',
            onChanged: (v) => newValue = v,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('60m'), findsOneWidget);

      await tester.tap(find.text('+'));
      await tester.pumpAndSettle();
      check(newValue).isNull();
    });

    testWidgets('"−" decrements from 30 to 25', (tester) async {
      int? newValue;
      await tester.pumpWidget(
        _wrap(
          CrudoStepper(
            value: 30,
            min: 5,
            max: 60,
            step: 5,
            suffix: 'm',
            onChanged: (v) => newValue = v,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('−'));
      await tester.pumpAndSettle();
      check(newValue).equals(25);
    });

    testWidgets('at min "−" is a no-op (stays 5)', (tester) async {
      int? newValue;
      await tester.pumpWidget(
        _wrap(
          CrudoStepper(
            value: 5,
            min: 5,
            max: 60,
            step: 5,
            suffix: 'm',
            onChanged: (v) => newValue = v,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('−'));
      await tester.pumpAndSettle();
      check(newValue).isNull();
    });

    testWidgets('renders value with suffix', (tester) async {
      await tester.pumpWidget(
        _wrap(
          CrudoStepper(
            value: 30,
            min: 5,
            max: 60,
            step: 5,
            suffix: 'm',
            onChanged: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('30m'), findsOneWidget);
    });
  });
}
