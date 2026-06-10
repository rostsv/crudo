import 'package:checks/checks.dart';
import 'package:crudo/domain/shared/enums.dart';
import 'package:crudo/ui/core/themes/colors.dart';
import 'package:crudo/ui/features/history/views/history_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// A MaterialApp wrapped with CrudoColors theme extension for widget tests.
Widget themedApp(Widget child) {
  return MaterialApp(
    theme: ThemeData(
      extensions: const <ThemeExtension<dynamic>>[CrudoColors.light],
    ),
    home: Scaffold(body: child),
  );
}

void main() {
  group('dayStateColor', () {
    test('maps green → success', () {
      check(
        dayStateColor(DayState.green, CrudoColors.light),
      ).equals(CrudoColors.light.success);
    });

    test('maps yellow → gold', () {
      check(
        dayStateColor(DayState.yellow, CrudoColors.light),
      ).equals(CrudoColors.light.gold);
    });

    test('maps red → error', () {
      check(
        dayStateColor(DayState.red, CrudoColors.light),
      ).equals(CrudoColors.light.error);
    });
  });

  group('AdherenceBar', () {
    testWidgets('renders a fill bar with correct proportional width', (
      WidgetTester tester,
    ) async {
      const value = 0.5;
      const color = Colors.teal;

      await tester.pumpWidget(
        themedApp(
          SizedBox(
            width: 200,
            height: 50,
            child: AdherenceBar(value: value, color: color),
          ),
        ),
      );

      // The bar should be present
      expect(find.byType(AdherenceBar), findsOneWidget);

      // Find the FractionallySizedBox that represents the fill
      final fractionallySizedBox = tester.widget<FractionallySizedBox>(
        find.byType(FractionallySizedBox),
      );
      check(fractionallySizedBox.widthFactor).equals(value);
    });

    testWidgets('clamps value to [0, 1]', (WidgetTester tester) async {
      await tester.pumpWidget(
        themedApp(
          SizedBox(
            width: 200,
            height: 50,
            child: AdherenceBar(value: 1.5, color: Colors.teal),
          ),
        ),
      );

      // Should clamp to 1.0
      final fractionallySizedBox = tester.widget<FractionallySizedBox>(
        find.byType(FractionallySizedBox),
      );
      check(fractionallySizedBox.widthFactor).equals(1.0);

      // Negative value clamps to 0
      await tester.pumpWidget(
        themedApp(
          SizedBox(
            width: 200,
            height: 50,
            child: AdherenceBar(value: -0.5, color: Colors.teal),
          ),
        ),
      );

      final fractionallySizedBox2 = tester.widget<FractionallySizedBox>(
        find.byType(FractionallySizedBox),
      );
      check(fractionallySizedBox2.widthFactor).equals(0.0);
    });

    testWidgets('renders with custom height', (WidgetTester tester) async {
      const customHeight = 12.0;

      // Use Align for loose height constraints so the bar can size itself.
      await tester.pumpWidget(
        themedApp(
          Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: 200,
              child: AdherenceBar(
                value: 0.8,
                color: Colors.amber,
                height: customHeight,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(AdherenceBar), findsOneWidget);
      expect(find.byType(FractionallySizedBox), findsOneWidget);
      // Verify the track Container explicitly carries the custom height
      final trackBox = tester.renderObject<RenderBox>(
        find.byKey(const ValueKey('adherence-bar-track')),
      );
      check(trackBox.size.height).equals(customHeight);
    });
  });
}
