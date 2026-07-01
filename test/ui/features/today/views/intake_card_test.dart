import 'package:checks/checks.dart';
import 'package:crudo/domain/shared/macros.dart';
import 'package:crudo/ui/core/themes/colors.dart';
import 'package:crudo/ui/core/themes/dimensions.dart';
import 'package:crudo/ui/core/themes/theme.dart';
import 'package:crudo/ui/features/today/views/intake_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) => MaterialApp(
  theme: crudoTheme,
  home: Scaffold(body: child),
);

void main() {
  testWidgets('IntakeCard shows consumed/planned kcal + macro bars', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        const IntakeCard(
          consumed: Macros(protein: 30, carbs: 40, fats: 10, kcal: 370),
          planned: Macros(protein: 120, carbs: 200, fats: 60, kcal: 1820),
        ),
      ),
    );
    expect(find.text('370'), findsOneWidget);
    expect(find.text('/1820 kcal'), findsOneWidget);

    // Each macro label renders in full.
    for (final label in ['Protein', 'Carbs', 'Fats']) {
      expect(find.text(label), findsOneWidget);
    }

    // Each macro value is a RichText with two spans.
    final valueTexts = tester.widgetList<RichText>(find.byType(RichText));
    for (final expected in ['30/120g', '40/200g', '10/60g']) {
      check(valueTexts.any((r) => r.text.toPlainText() == expected)).isTrue();
    }
  });

  testWidgets('macro bar labels render fully at 390px width', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    await tester.pumpWidget(
      _wrap(
        const Padding(
          padding: EdgeInsets.all(Spacing.md),
          child: IntakeCard(
            consumed: Macros(protein: 82, carbs: 140, fats: 38, kcal: 1240),
            planned: Macros(protein: 140, carbs: 220, fats: 70, kcal: 2080),
          ),
        ),
      ),
    );

    for (final label in ['Protein', 'Carbs', 'Fats']) {
      expect(find.text(label), findsOneWidget);
    }
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('consumed value is bold; /planned is muted and lighter', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        const IntakeCard(
          consumed: Macros(protein: 30, carbs: 40, fats: 10, kcal: 370),
          planned: Macros(protein: 120, carbs: 200, fats: 60, kcal: 1820),
        ),
      ),
    );

    RichText? valueRichText;
    for (final rich in tester.widgetList<RichText>(find.byType(RichText))) {
      final plain = rich.text.toPlainText();
      if (plain == '30/120g') {
        valueRichText = rich;
        break;
      }
    }
    check(valueRichText).isNotNull();

    final spans = <TextSpan>[];
    void collect(InlineSpan span) {
      if (span is TextSpan) {
        spans.add(span);
        for (final child in span.children ?? const <InlineSpan>[]) {
          collect(child);
        }
      }
    }

    collect(valueRichText!.text);
    final consumedSpan = spans.firstWhere((s) => s.text == '30');
    final plannedSpan = spans.firstWhere((s) => s.text == '/120g');

    check(consumedSpan.style!.fontWeight).equals(FontWeight.w700);
    check(consumedSpan.style!.color).equals(CrudoColors.light.onSurface);
    check(plannedSpan.style!.fontWeight).equals(FontWeight.w500);
    check(plannedSpan.style!.color).equals(CrudoColors.light.onSurfaceMut);
  });

  testWidgets('IntakeCard fits narrow phone widths without overflow', (
    tester,
  ) async {
    // Regression: the macro-bar label row overflowed by ~2px at 390 width
    // (stacked layout now uses vertical space instead of overflowing).
    for (final width in [320.0, 360.0, 390.0]) {
      await tester.binding.setSurfaceSize(Size(width, 844));
      await tester.pumpWidget(
        _wrap(
          const Padding(
            padding: EdgeInsets.all(Spacing.md),
            child: IntakeCard(
              consumed: Macros(protein: 82, carbs: 140, fats: 38, kcal: 1240),
              planned: Macros(protein: 140, carbs: 220, fats: 70, kcal: 2080),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull, reason: 'overflow at $width');
    }
    await tester.binding.setSurfaceSize(null);
  });
}
