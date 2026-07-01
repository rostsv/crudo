import 'package:crudo/domain/shared/macros.dart';
import 'package:crudo/ui/core/themes/theme.dart';
import 'package:crudo/ui/core/widgets/macro_total_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const macros = Macros(protein: 30, carbs: 45, fats: 12, kcal: 520);

  Future<void> pump(
    WidgetTester tester, {
    required String label,
    bool gradient = false,
    Widget? footer,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        theme: crudoTheme,
        home: Scaffold(
          body: MacroTotalCard(
            macros: macros,
            label: label,
            gradient: gradient,
            footer: footer,
          ),
        ),
      ),
    );
  }

  testWidgets('tonal renders label, kcal, and macro columns', (tester) async {
    await pump(tester, label: 'TOTAL INTAKE');

    expect(find.text('TOTAL INTAKE'), findsOneWidget);
    expect(find.byKey(const ValueKey('detail-kcal')), findsOneWidget);
    expect(find.text('520'), findsOneWidget);
    expect(find.text('Protein'), findsOneWidget);
    expect(find.text('Carbs'), findsOneWidget);
    expect(find.text('Fats'), findsOneWidget);
    expect(find.text('30g'), findsOneWidget);
  });

  testWidgets('gradient variant renders its label', (tester) async {
    await pump(tester, label: 'DAILY TARGET', gradient: true);

    expect(find.text('DAILY TARGET'), findsOneWidget);
    expect(find.text('520'), findsOneWidget);
  });

  testWidgets('footer slot is rendered when provided', (tester) async {
    await pump(
      tester,
      label: 'TOTAL INTAKE',
      footer: const Text('footer-content'),
    );

    expect(find.text('footer-content'), findsOneWidget);
  });

  testWidgets('no footer when omitted', (tester) async {
    await pump(tester, label: 'TOTAL INTAKE');

    expect(find.text('footer-content'), findsNothing);
  });
}
