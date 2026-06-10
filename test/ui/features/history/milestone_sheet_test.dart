import 'package:crudo/ui/core/themes/theme.dart';
import 'package:crudo/ui/features/history/views/milestone_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget testableApp() {
    return MaterialApp(
      theme: crudoTheme,
      home: Builder(
        builder: (context) => ElevatedButton(
          onPressed: () => showMilestoneSheet(context, 7),
          child: const Text('Show milestone'),
        ),
      ),
    );
  }

  group('MilestoneSheet', () {
    testWidgets('renders gold flame, label, headline, body and CTA', (
      tester,
    ) async {
      await tester.pumpWidget(testableApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Show milestone'));
      await tester.pumpAndSettle();

      // Headline
      expect(find.text('7-day streak!'), findsOneWidget);

      // Label
      expect(find.text('STREAK MILESTONE'), findsOneWidget);

      // Flame icon
      expect(find.byIcon(Icons.local_fire_department), findsOneWidget);

      // CTA button
      expect(find.text('Keep going'), findsOneWidget);
    });

    testWidgets('tapping CTA dismisses the dialog', (tester) async {
      await tester.pumpWidget(testableApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Show milestone'));
      await tester.pumpAndSettle();

      expect(find.text('7-day streak!'), findsOneWidget);

      await tester.tap(find.text('Keep going'));
      await tester.pumpAndSettle();

      expect(find.text('7-day streak!'), findsNothing);
    });
  });
}
