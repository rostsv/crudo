import 'package:checks/checks.dart';
import 'package:crudo/domain/shared/enums.dart';
import 'package:crudo/domain/shared/macros.dart';
import 'package:crudo/ui/core/themes/colors.dart';
import 'package:crudo/ui/core/themes/dimensions.dart';
import 'package:crudo/ui/core/themes/theme.dart';
import 'package:crudo/ui/core/themes/typography.dart';
import 'package:crudo/ui/core/widgets/meal_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) => MaterialApp(
  theme: crudoTheme,
  home: Scaffold(body: child),
);

const _macros = Macros(protein: 32.4, carbs: 45.2, fats: 11.8, kcal: 419.6);

MealCard _card({
  MealStatus status = MealStatus.upcoming,
  List<String> ingredientNames = const ['Eggs', 'Yogurt', 'Oats', 'Berries'],
  VoidCallback? onTap,
  VoidCallback? onStatusTap,
}) => MealCard(
  title: 'Protein Bowl',
  timeLabel: '08:00',
  mealTypeLabel: 'Breakfast',
  macros: _macros,
  ingredientNames: ingredientNames,
  status: status,
  onTap: onTap,
  onStatusTap: onStatusTap,
);

void main() {
  group('namesThatFit', () {
    final style = CrudoText.labelMd.copyWith(
      color: CrudoColors.light.onSurfaceMut,
    );
    const scaler = TextScaler.noScaling;

    test('empty list returns 0', () {
      check(MealCard.namesThatFit([], 100, style, scaler)).equals(0);
    });

    test('single long name returns 1 even though it overflows', () {
      check(
        MealCard.namesThatFit(['Averylongingredientname'], 10, style, scaler),
      ).equals(1);
    });

    test('several short names all fit in a wide width', () {
      check(
        MealCard.namesThatFit(['A', 'B', 'C', 'D'], 1000, style, scaler),
      ).equals(4);
    });

    test('many names collapse into "+N more" at a narrow width', () {
      final count = MealCard.namesThatFit(
        ['A', 'B', 'C', 'D', 'E'],
        40,
        style,
        scaler,
      );
      check(count).equals(1);
    });
  });

  testWidgets('shows every field for every status without status text', (
    tester,
  ) async {
    for (final status in MealStatus.values) {
      await tester.pumpWidget(_wrap(_card(status: status)));
      expect(find.text('Protein Bowl'), findsOneWidget);
      expect(find.text('08:00 · Breakfast'), findsOneWidget);
      expect(find.text(status.name.toUpperCase()), findsNothing);
      expect(find.text('420 kcal'), findsOneWidget);
      expect(find.textContaining('½'), findsNothing);
      expect(
        find.byKey(ValueKey('meal-status-${status.name}')),
        findsOneWidget,
      );
    }
  });

  testWidgets('macros row shows colored dots + grams for P/C/F', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(_card()));

    expect(find.text('420 kcal'), findsOneWidget);
    expect(find.text('32g'), findsOneWidget);
    expect(find.text('45g'), findsOneWidget);
    expect(find.text('12g'), findsOneWidget);

    final dotContainers = tester
        .widgetList<Container>(find.byType(Container))
        .where(
          (c) =>
              c.constraints != null &&
              c.constraints!.minWidth == Spacing.xs &&
              c.constraints!.minHeight == Spacing.xs &&
              c.decoration is BoxDecoration &&
              (c.decoration as BoxDecoration).shape == BoxShape.circle,
        )
        .toList();
    check(dotContainers).length.equals(3);

    final dotColors = dotContainers
        .map((c) => (c.decoration as BoxDecoration).color)
        .toList();
    check(dotColors[0]).equals(CrudoColors.light.proteinColor);
    check(dotColors[1]).equals(CrudoColors.light.carbsColor);
    check(dotColors[2]).equals(CrudoColors.light.fatsColor);
  });

  testWidgets('kcal label uses labelMd size', (tester) async {
    await tester.pumpWidget(_wrap(_card()));
    final kcalText = tester.widget<Text>(find.text('420 kcal'));
    check(kcalText.style!.fontSize).equals(12);
  });

  testWidgets('ingredient preview is small and not bold', (tester) async {
    await tester.pumpWidget(_wrap(_card()));
    final preview = tester.widget<Text>(find.textContaining('Eggs'));
    check(preview.style!.fontSize).equals(10);
    check(preview.style!.fontWeight).equals(FontWeight.w500);
  });

  testWidgets('ingredient preview shows more names at wider widths', (
    tester,
  ) async {
    const names = [
      'Chicken',
      'Rice',
      'Avocado',
      'Spinach',
      'Oil',
      'Tomatoes',
      'Feta',
      'Lemon',
    ];
    const narrowWidth = 320.0;
    const wideWidth = 600.0;

    await tester.binding.setSurfaceSize(const Size(narrowWidth, 844));
    await tester.pumpWidget(_wrap(_card(ingredientNames: names)));
    final narrowText = tester.widget<Text>(find.textContaining('+'));
    final narrowMore = RegExp(r'\+(\d+) more').firstMatch(narrowText.data!)!;

    await tester.binding.setSurfaceSize(const Size(wideWidth, 844));
    await tester.pumpWidget(_wrap(_card(ingredientNames: names)));
    final wideText = tester.widget<Text>(find.textContaining('+'));
    final wideMore = RegExp(r'\+(\d+) more').firstMatch(wideText.data!)!;

    check(
      int.parse(wideMore.group(1)!),
    ).isLessThan(int.parse(narrowMore.group(1)!));
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('short ingredient list shows no "+N more" suffix', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(_card(ingredientNames: const ['A', 'B'])));
    expect(find.text('A · B'), findsOneWidget);
    expect(find.textContaining('more'), findsNothing);
  });

  testWidgets('empty ingredient list hides the preview line', (tester) async {
    await tester.pumpWidget(_wrap(_card(ingredientNames: const [])));
    expect(find.text('Protein Bowl'), findsOneWidget);
    // Only the time label contains a separator; no ingredient preview line.
    expect(find.textContaining('·'), findsOneWidget);
  });

  testWidgets('tap fires when provided', (tester) async {
    var taps = 0;
    await tester.pumpWidget(_wrap(_card(onTap: () => taps++)));
    await tester.tap(find.text('Protein Bowl'));
    check(taps).equals(1);
  });

  testWidgets('status circle tap fires onStatusTap, not onTap', (tester) async {
    var cardTaps = 0;
    var statusTaps = 0;
    await tester.pumpWidget(
      _wrap(_card(onTap: () => cardTaps++, onStatusTap: () => statusTaps++)),
    );
    // Tap the status circle — should fire onStatusTap, not onTap.
    await tester.tap(find.byKey(const ValueKey('meal-status-upcoming')));
    check(statusTaps).equals(1);
    check(cardTaps).equals(0);
  });

  testWidgets('null onStatusTap: circle tap falls through to card onTap', (
    tester,
  ) async {
    var cardTaps = 0;
    await tester.pumpWidget(
      _wrap(_card(onTap: () => cardTaps++, onStatusTap: null)),
    );
    await tester.tap(find.byKey(const ValueKey('meal-status-upcoming')));
    check(cardTaps).equals(1);
  });

  testWidgets('semantics label: Mark eaten / Undo', (tester) async {
    await tester.pumpWidget(
      _wrap(_card(status: MealStatus.upcoming, onStatusTap: () {})),
    );
    final upcoming = tester.getSemantics(
      find.byKey(const ValueKey('meal-status-upcoming')),
    );
    check(upcoming.label).equals('Mark Protein Bowl eaten');

    await tester.pumpWidget(
      _wrap(_card(status: MealStatus.done, onStatusTap: () {})),
    );
    final done = tester.getSemantics(
      find.byKey(const ValueKey('meal-status-done')),
    );
    check(done.label).equals('Undo Protein Bowl');
  });

  testWidgets('overdue: clock icon on amber-soft circle; title not muted', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(_card(status: MealStatus.overdue)));
    expect(find.text('OVERDUE'), findsNothing);
    final icon = tester.widget<Icon>(find.byIcon(Icons.schedule));
    check(icon.color).equals(CrudoColors.light.overdue);
    final title = tester.widget<Text>(find.text('Protein Bowl'));
    check(title.style!.color).equals(CrudoColors.light.onSurface);
  });

  testWidgets('overdue keeps struck-through original + snoozed time', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        MealCard(
          title: 'Protein Bowl',
          timeLabel: '14:00',
          snoozedTimeLabel: '14:15',
          mealTypeLabel: 'Lunch',
          macros: _macros,
          status: MealStatus.overdue,
        ),
      ),
    );
    final rich = tester
        .widgetList<RichText>(find.byType(RichText))
        .where(
          (r) =>
              r.text.toPlainText().contains('14:00') &&
              r.text.toPlainText().contains('14:15'),
        );
    check(rich).isNotEmpty();
  });

  testWidgets(
    'snoozedTimeLabel: original time struck-through, new time shown',
    (tester) async {
      await tester.pumpWidget(
        _wrap(
          MealCard(
            title: 'Protein Bowl',
            timeLabel: '14:00',
            snoozedTimeLabel: '14:15',
            mealTypeLabel: 'Lunch',
            macros: _macros,
            status: MealStatus.upcoming,
          ),
        ),
      );
      // Both times appear in the plain text of the RichText.
      final richTexts = tester.widgetList<RichText>(find.byType(RichText));
      RichText? timeRich;
      for (final r in richTexts) {
        if (r.text.toPlainText().contains('14:00') &&
            r.text.toPlainText().contains('14:15')) {
          timeRich = r;
          break;
        }
      }
      check(timeRich).isNotNull();
      // The rich text contains both '14:00' and '14:15' in its flat text.
      final plain = timeRich!.text.toPlainText();
      check(plain).contains('14:00');
      check(plain).contains('14:15');
      // Walk the span tree to find the '14:00' span and check its style.
      TextSpan? found;
      void walk(InlineSpan span) {
        if (found != null) return;
        if (span is TextSpan) {
          if (span.text == '14:00') {
            found = span;
            return;
          }
          for (final child in span.children ?? const <InlineSpan>[]) {
            walk(child);
          }
        }
      }

      walk(timeRich.text);
      check(found).isNotNull();
      check(found!.style).isNotNull();
      check(found!.style!.decoration).equals(TextDecoration.lineThrough);
    },
  );
}
